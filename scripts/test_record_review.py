"""Check record lineage against source rows and the unchanged aggregate query."""
import collections, datetime, decimal, hashlib, json, math, os
from pathlib import Path
import psycopg2
from psycopg2.extras import RealDictCursor
from superset.app import create_app
from superset.jinja_context import get_template_processor

ROOT=Path(os.environ.get('CSIM_PROJECT_ROOT','/repro'))
SQL=(ROOT/'review/record-review.sql').read_text()
def rows(cur,sql,args=None):
    cur.execute(sql,args);return [dict(r) for r in cur.fetchall()]
def norm(x):
    if isinstance(x,(datetime.date,datetime.datetime)):return x.isoformat()
    if isinstance(x,decimal.Decimal):return float(x)
    return x
def main():
    app=create_app()
    with app.app_context(),app.test_request_context():
        from superset import db
        from superset.connectors.sqla.models import SqlaTable
        table=db.session.query(SqlaTable).filter_by(uuid='12cf6aed-4a67-5829-88b4-2636ee62a97f').one()
        with psycopg2.connect(host='db',user='csim',password=os.environ['CSIM_DB_PASSWORD'],dbname='csim_demo') as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                review=rows(cur,SQL)
                source=rows(cur,"SELECT 'Current' AS source,record_id,redcap_repeat_instance FROM v1.\"UTI Individual Current\" UNION ALL SELECT 'Historical',record_id,NULL FROM v1.\"UTI Individual Historical\"")
                assert collections.Counter((r['source'],r['record_ID'],r['redcap_repeat_instance']) for r in review)==collections.Counter((r['source'],r['record_id'],r['redcap_repeat_instance']) for r in source)
                assert all(r['redcap_repeat_instance'] is None for r in review if r['source']=='Historical')
                verified=0
                for grain,width in [('P1M',1),('P3M',3),('P1Y',12)]:
                    for start,end in [(None,None),('2026-02-01','2026-04-01')]:
                        processor=get_template_processor(database=table.database,table=table,time_grain=grain,from_dttm=start,to_dttm=end)
                        result=rows(cur,processor.process_template(table.sql))
                        expected=collections.defaultdict(list)
                        for r in review:
                            if r['reporting_status']!='Included':continue
                            day=r['reporting_month']
                            if start and day<datetime.date.fromisoformat(start):continue
                            if end and day>=datetime.date.fromisoformat(end):continue
                            period=datetime.date(day.year,1+(day.month-1)//width*width,1)
                            expected[(r['hospital_code'],period,0)].append(r)
                            expected[(r['hospital_code'],period,r['location_code'])].append(r)
                        observed={}
                        for r in result:
                            if r['hosp_num'] is None or r['ucsub'] is None:continue
                            key=(r['hosp_num'],r['month_date'],r['location_code']);observed[key]=r
                            group=expected[key];assert r['ucsub']==len(group),(key,r['ucsub'],len(group))
                            txpos=sum(x['ucx_positive']==1 and x['tx___1']==0 for x in group)
                            asb=sum(x['ucx_positive']==1 and x['tx___1']==0 and x['sign_symp']==0 for x in group)
                            ua=sum(x['urinalysis']==1 for x in group)
                            assert r['txpos']==txpos and r['asbtreated']==asb and r['pos_ua']==ua,key
                            rate=asb/txpos if txpos else None
                            assert (r['inappdx'] is None and rate is None) or (rate is not None and math.isclose(r['inappdx'],rate)),key
                            verified+=1
                        assert set(observed)==set(expected),'Record membership and aggregate groups differ'
                all53=sum(r['reporting_status']=='Included' and r['hospital_code']==53 for r in review)
                excluded=collections.Counter(str(r['hospital_code']) for r in review if r['reporting_status']=='Excluded')
        # Repeats, same ID across sources, incomplete and unmatched rows: transaction
        # is rolled back in the isolated fixture, leaving the supplied demo untouched.
        with psycopg2.connect(host='db',user='csim',password=os.environ['CSIM_DB_PASSWORD'],dbname='csim_fixture') as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                marker=-2026091701
                cur.execute('INSERT INTO v1."UTI Individual Current" (record_id,redcap_repeat_instance,hosp_name,month,year,qi_asb_complete) VALUES (%s,1,91,1,2026,2),(%s,2,91,1,2026,2),(%s,3,91,1,2026,0)',(marker,marker,marker))
                cur.execute('INSERT INTO v1."UTI Individual Historical" (record_id,hosp_name,month,year) VALUES (%s,91,1,2026),(%s,999,1,2026),(%s,91,NULL,2026)',(marker,marker-1,marker-2))
                special=rows(cur,'SELECT * FROM ('+SQL+') r WHERE "record_ID" BETWEEN %s AND %s',(marker-2,marker))
                assert len(special)==6
                assert sum(r['reporting_status']=='Included' for r in special)==3
                assert {r['redcap_repeat_instance'] for r in special if r['source']=='Current'}=={1,2,3}
                assert any(r['review_note']=='Hospital missing from lookup' for r in special)
                assert any(r['review_note']=='Missing reporting month or year' for r in special)
                assert any(r['review_note']=='Current record is not complete' for r in special)
                conn.rollback()
        output=Path('/tmp/csim-record-review-oracle.json')
        output.write_text(json.dumps({'rows':review,'columns':list(review[0]),'rowCount':len(review),'aggregateGroupsVerified':verified,'hospital53Records':all53,'excludedByHospital':dict(excluded),'fixtureChecksPassed':True,'aggregateSqlSha256':hashlib.sha256(table.sql.encode()).hexdigest()},default=norm))
        print(json.dumps({'rows':len(review),'aggregateGroupsVerified':verified,'hospital53Records':all53,'excludedByHospital':dict(excluded),'fixtureChecksPassed':True,'oracle':str(output)}))

if __name__=='__main__':main()
