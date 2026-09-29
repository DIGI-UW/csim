"""Independent aggregate rows and a reversible CSV append in the demo fixture."""
import argparse,io,json,os
from pathlib import Path
import psycopg2,yaml
from superset.app import create_app
from superset.jinja_context import get_template_processor

ROOT=Path(os.environ.get('CSIM_PROJECT_ROOT','/repro'))
MARKER=-2026091591
UPLOAD='record_id,hosp_name,location,sign_symp,month,year,ucx_positive,urinalysis,tx___1,duration,qi_asb_complete\n'+f'{MARKER},91,3,1,5,2026,1,1,0,6,2\n'

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--fixture',action='store_true')
    parser.add_argument('--upload-fixture',action='store_true')
    parser.add_argument('--cleanup-fixture',action='store_true')
    parser.add_argument('--output',required=True)
    args=parser.parse_args()
    if args.upload_fixture or args.cleanup_fixture:
        assert args.fixture, 'Mutation is allowed only in the isolated generated fixture'
        assert not (args.upload_fixture and args.cleanup_fixture)
    profile='standard-month-selectors'+('-examples' if args.fixture else '')
    definition=yaml.safe_load((ROOT/'dashboard'/profile/'datasets/PostgreSQL/UTI_Aggregate_ALL_DATA_40.yaml').read_text())
    app=create_app()
    with app.app_context(),app.test_request_context():
        from superset import db
        from superset.connectors.sqla.models import SqlaTable
        table=db.session.query(SqlaTable).filter_by(uuid=definition['uuid']).one()
        with psycopg2.connect(host='db',user='csim',password=os.environ['CSIM_DB_PASSWORD'],dbname='csim_fixture' if args.fixture else 'csim_demo') as conn:
            with conn.cursor() as cur:
                if args.upload_fixture:
                    cur.execute('SELECT COUNT(*) FROM v1."UTI Individual Current" WHERE record_id=%s',(MARKER,))
                    assert cur.fetchone()[0]==0, 'Test row already present; inspect/clean up before repeating'
                    cur.copy_expert('COPY v1."UTI Individual Current" (record_id,hosp_name,location,sign_symp,month,year,ucx_positive,urinalysis,tx___1,duration,qi_asb_complete) FROM STDIN WITH CSV HEADER',io.StringIO(UPLOAD))
                    conn.commit()
                if args.cleanup_fixture:
                    cur.execute('DELETE FROM v1."UTI Individual Current" WHERE record_id=%s',(MARKER,))
                    assert cur.rowcount==1, 'Expected exactly the test upload row'
                    conn.commit()
                cur.execute('SELECT COUNT(*),md5(string_agg(row_to_json(t)::text,\'\' ORDER BY record_id)) FROM v1."UTI Individual Current" t')
                source_count,source_hash=cur.fetchone()
                processor=get_template_processor(database=table.database,table=table,time_grain='P1M',from_dttm=None,to_dttm=None)
                query=processor.process_template(table.sql)
                cur.execute("SELECT raw.*,to_char(month_date,'YYYY-MM') AS period_label FROM ("+query+") raw")
                columns=[column.name for column in cur.description]
                rows=[dict(zip(columns,row)) for row in cur.fetchall()]
        assert len(rows)<100000, 'Complete aggregate output exceeds the saved table limit'
        result={'datasetUuid':str(table.uuid),'rows':rows,'columns':columns,'rowCount':len(rows),'sourceCount':source_count,'sourceHash':source_hash,'fixture':args.fixture,'uploadedFixtureRow':args.upload_fixture,'cleanedFixtureRow':args.cleanup_fixture}
        Path(args.output).write_text(json.dumps(result,default=lambda x:x.isoformat() if hasattr(x,'isoformat') else str(x)))
        print(json.dumps({key:value for key,value in result.items() if key not in ['rows','columns']}))

if __name__=='__main__':main()
