"""Add/update only the separate CSiM Data & records assets; preserve report edits."""
import argparse, hashlib, json, os, sqlite3, uuid
from pathlib import Path
import psycopg2
from superset.app import create_app
from dashboard_import import connection

ROOT = Path(os.environ.get('CSIM_PROJECT_ROOT', '/repro'))
NAMESPACE = 'https://csim.uwdigi.org/data-review/'
ANCHOR = '12cf6aed-4a67-5829-88b4-2636ee62a97f'
DATASET = 'UTI Individual — Record review'
DETAIL = 'Individual records — Review and download'
SLUG = 'csim-data-records'

def identity(name): return str(uuid.uuid5(uuid.NAMESPACE_URL, NAMESPACE + name))

def snapshot(path):
    with sqlite3.connect(f'file:{path}?mode=ro', uri=True) as c:
        c.row_factory = sqlite3.Row
        return {t: {r['id']: dict(r) for r in c.execute('SELECT * FROM '+t)} for t in ('dashboards','slices','tables')}

def node(kind, name, parents, children=None, **meta):
    return {'id':name,'type':kind,'parents':parents,'children':children or [],'meta':meta}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply',action='store_true')
    parser.add_argument('--output',default='/tmp/csim-data-review.json')
    args=parser.parse_args()
    app=create_app()
    with app.app_context():
        from superset import db,security_manager as sm
        from superset.connectors.sqla.models import SqlaTable
        from superset.models.slice import Slice
        from superset.models.dashboard import Dashboard
        anchor=db.session.query(SqlaTable).filter_by(uuid=ANCHOR).one()
        assert anchor.database.database_name=='CSiM demo PostgreSQL', 'This installer targets the supplied demo only'
        database_id=anchor.database_id
        sql=(ROOT/'review/record-review.sql').read_text()
        with psycopg2.connect(host='db', user='csim',password=os.environ['CSIM_DB_PASSWORD'],dbname='csim_demo') as conn:
            with conn.cursor() as cur:
                cur.execute('SELECT hosp_code FROM v1."CSiM Hospitals and States" GROUP BY hosp_code HAVING count(*)>1')
                assert not cur.fetchall(), 'Duplicate hospital lookup codes would multiply records; resolve the lookup first'
                cur.execute('SELECT count(*) FROM ('+sql+') r')
                count=cur.fetchone()[0]
                assert count<100000, 'Increase and verify the complete CSV limit before installing'
        path=db.engine.url.database
        assert db.engine.url.drivername=='sqlite'
        before=snapshot(path)
        owned={'tables':{identity('records')},'slices':{identity(k) for k in ('detail','source-counts','hospital-counts')},'dashboards':{identity('dashboard')}}
        if not args.apply:
            print(json.dumps({'plannedDataset':DATASET,'rows':count,'standaloneChart':DETAIL,'dashboard':SLUG}));return
        base,session=connection()
        def request(method,url,**kwargs):
            # HTTPS responses can renew the cookie. This CLI talks only to the
            # app's own HTTP loopback listener; browser cookie policy is unchanged.
            for cookie in session.cookies:
                cookie.secure=False
            return session.request(method,url,**kwargs)
        def write(resource,payload,obj=None):
            response=request('PUT' if obj else 'POST',base+'/api/v1/'+resource+'/'+(str(obj.id) if obj else ''),json=payload,timeout=90,allow_redirects=False)
            assert response.status_code in (200,201), f'{resource}: {response.status_code} {response.text[:1200]}'
            return obj.id if obj else response.json()['id']
        table=db.session.query(SqlaTable).filter_by(uuid=identity('records')).one_or_none()
        dataset_id=write('dataset',{'table_name':DATASET,'schema':'v1','sql':sql,'uuid':identity('records'),('database_id' if table else 'database'):database_id},table)
        # Refresh metadata from the saved query; required for later SQL edits too.
        response=request('PUT',base+f'/api/v1/dataset/{dataset_id}/refresh',timeout=90)
        assert response.status_code==200,response.text[:800]
        db.session.expire_all()
        table=db.session.query(SqlaTable).filter_by(id=dataset_id).one()
        write('dataset',{'main_dttm_col':'reporting_month','cache_timeout':-1,'description':'One row per uploaded Current or Historical submission. Included means eligible before dashboard filters. Excluded rows remain visible with a reason. Historical repeat identifiers are blank; IDs are not assumed globally unique.'},table)
        dashboard=db.session.query(Dashboard).filter_by(uuid=identity('dashboard')).one_or_none()
        dashboard_id=write('dashboard',{'dashboard_title':'CSiM — Data & records','slug':SLUG,'published':True,'uuid':identity('dashboard')},dashboard)
        cols=[c.column_name for c in table.columns]
        first=['source','record_ID','redcap_repeat_instance','hospital_code','hospital_name','state','reporting_month','location_name','reporting_status','review_note']
        raw={'query_mode':'raw','all_columns':first+[c for c in cols if c not in first],'metrics':[],'groupby':[],
             'order_by_cols':[json.dumps(['source',True]),json.dumps(['record_ID',True]),json.dumps(['redcap_repeat_instance',True])]}
        count_metric={'expressionType':'SQL','sqlExpression':'COUNT(*)','label':'Records','optionName':'metric_records','hasCustomLabel':True}
        charts={}
        configs=[('detail',DETAIL,raw,[]),
                 ('source-counts','Uploaded records by source',{'query_mode':'aggregate','all_columns':[],'groupby':['source','reporting_status'],'metrics':[count_metric]},[dashboard_id]),
                 ('hospital-counts','Hospital coverage',{'query_mode':'aggregate','all_columns':[],'groupby':['hospital_code','hospital_name','state','reporting_status','review_note'],'metrics':[count_metric]},[dashboard_id])]
        for key,title,query,dashboards in configs:
            params={'datasource':f'{dataset_id}__table','viz_type':'table','adhoc_filters':[],'time_range':'No filter',
                    'row_limit':100000,'server_pagination':False,'page_length':20,'include_search':True,
                    'show_totals':False,'show_cell_bars':False,'extra_form_data':{},'dashboards':dashboards,'table_timestamp_format':'%Y-%m',
                    'column_config':{'Records':{'d3NumberFormat':',d'},'review_note':{'columnWidth':420},'hospital_name':{'columnWidth':180},'reporting_month':{'d3TimeFormat':'%Y-%m'}},**query}
            chart=db.session.query(Slice).filter_by(uuid=identity(key)).one_or_none()
            chart_id=write('chart',{'slice_name':title,'uuid':identity(key),'viz_type':'table','datasource_id':dataset_id,'datasource_type':'table','params':json.dumps(params),'dashboards':dashboards,'cache_timeout':-1,
                      'description':'All uploaded months. Refresh after an upload. Search helps find rows; use Filters to narrow the CSV. The complete export limit is 100,000 rows.'},chart)
            params['slice_id']=chart_id
            db.session.expire_all();chart=db.session.query(Slice).get(chart_id)
            write('chart',{'params':json.dumps(params)},chart)
            charts[key]={'id':chart_id,'uuid':identity(key),'title':title}
        # Keep the detailed table standalone, outside both dashboard filter scopes.
        positions={'DASHBOARD_VERSION_KEY':'v2','ROOT_ID':node('ROOT','ROOT_ID',[],['GRID_ID']),'GRID_ID':node('GRID','GRID_ID',['ROOT_ID'],['ROW-INTRO','ROW-SUMMARY','ROW-GUIDE'])}
        positions['ROW-INTRO']=node('ROW','ROW-INTRO',['ROOT_ID','GRID_ID'],['MARKDOWN-INTRO'],background='BACKGROUND_TRANSPARENT')
        intro=(ROOT/'review/intro.md').read_text().replace('{{record_chart}}',str(charts['detail']['id']))
        positions['MARKDOWN-INTRO']=node('MARKDOWN','MARKDOWN-INTRO',['ROOT_ID','GRID_ID','ROW-INTRO'],width=12,height=36,code=intro)
        positions['ROW-SUMMARY']=node('ROW','ROW-SUMMARY',['ROOT_ID','GRID_ID'],['CHART-SOURCES','CHART-HOSPITALS'],background='BACKGROUND_TRANSPARENT')
        for key,name,width in [('source-counts','CHART-SOURCES',4),('hospital-counts','CHART-HOSPITALS',8)]:
            chart=charts[key];positions[name]=node('CHART',name,['ROOT_ID','GRID_ID','ROW-SUMMARY'],chartId=chart['id'],uuid=chart['uuid'],sliceName=chart['title'],width=width,height=80)
        positions['ROW-GUIDE']=node('ROW','ROW-GUIDE',['ROOT_ID','GRID_ID'],['MARKDOWN-GUIDE'],background='BACKGROUND_TRANSPARENT')
        guide=(ROOT/'review/guide.md').read_text().replace('{{record_chart}}',str(charts['detail']['id']))
        positions['MARKDOWN-GUIDE']=node('MARKDOWN','MARKDOWN-GUIDE',['ROOT_ID','GRID_ID','ROW-GUIDE'],width=12,height=44,code=guide)
        db.session.expire_all();dashboard=db.session.query(Dashboard).get(dashboard_id)
        write('dashboard',{'position_json':json.dumps(positions),'json_metadata':json.dumps({'native_filter_configuration':[],'color_scheme':'supersetColors','label_colors':{},'refresh_frequency':0})},dashboard)
        # The reviewer is already authorized for all three supplied demo sources.
        # This derived view exposes a subset of those fields to the same role.
        db.session.expire_all();table=db.session.query(SqlaTable).get(dataset_id)
        role=sm.find_role('CSiM demo datasets')
        if role:
            permission=sm.find_permission_view_menu('datasource_access',table.get_perm())
            assert permission is not None
            sm.add_permission_role(role,permission);db.session.commit()
        after=snapshot(path)
        for kind,rows in before.items():
            for id_,row in rows.items():
                raw_uuid=row.get('uuid')
                saved_uuid=str(uuid.UUID(bytes=raw_uuid)) if isinstance(raw_uuid,bytes) else str(raw_uuid)
                if saved_uuid not in owned[kind]:
                    assert after[kind][id_]==row,f'Existing {kind} {id_} changed'
        result={'datasetId':dataset_id,'dashboardId':dashboard_id,'slug':SLUG,'charts':charts,'recordCount':count,
                'sqlSha256':hashlib.sha256(sql.encode()).hexdigest(),'existingReportingDefinitionsUnchanged':True}
        Path(args.output).write_text(json.dumps(result,indent=2)+'\n');print('CSIM_DATA_REVIEW='+json.dumps(result))

if __name__=='__main__':main()
