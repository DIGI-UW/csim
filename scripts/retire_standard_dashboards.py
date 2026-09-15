"""Back up four obsolete official comparisons, then delete only their dashboards."""
import argparse
import datetime
import io
import json
import sqlite3
from pathlib import Path
import zipfile
from superset.app import create_app
from dashboard_import import connection

RETIRED = {'csim-individual-standard','csim-standard-examples','csim-individual-standard-sortable','csim-standard-sortable-examples'}
KEEP = {'csim-individual-standard-month-selectors','csim-standard-month-selectors-examples'}

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--apply',action='store_true')
    args=parser.parse_args()
    app=create_app()
    with app.app_context():
        from superset import db
        from superset.models.dashboard import Dashboard
        from superset.models.slice import Slice
        from superset.connectors.sqla.models import SqlaTable
        dashboards=db.session.query(Dashboard).all()
        by_slug={d.slug:d for d in dashboards}
        assert KEEP <= by_slug.keys(), 'Current dashboard and known-record example must exist first'
        retired=[d for d in dashboards if d.slug in RETIRED]
        current={s:by_slug[s].export_to_dict(recursive=False,include_defaults=True) for s in KEEP}
        counts=(db.session.query(Slice).count(),db.session.query(SqlaTable).count())
        report={'retired':[{'id':d.id,'slug':d.slug,'title':d.dashboard_title} for d in retired],'kept':sorted(KEEP),'chartCount':counts[0],'datasetCount':counts[1]}
        if args.apply and retired:
            assert db.engine.url.drivername=='sqlite', 'Expected the dedicated official demo metadata store'
            stamp=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
            backup=Path(db.engine.url.database).parent/'backups'/('retired-standard-'+stamp)
            backup.mkdir(parents=True,exist_ok=False)
            # Release the inventory transaction before another web worker writes metadata.
            db.session.remove()
            with sqlite3.connect(db.engine.url.database) as source,sqlite3.connect(backup/'metadata.db') as target:
                source.backup(target)
            base,session=connection()
            ids=[d.id for d in retired]
            response=session.get(base+'/api/v1/dashboard/export/',params={'q':json.dumps(ids)},timeout=60)
            response.raise_for_status()
            with zipfile.ZipFile(io.BytesIO(response.content)) as archive:
                files=[n for n in archive.namelist() if '/dashboards/' in n and n.endswith('.yaml')]
                assert len(files)==len(ids), 'Backup must contain every retired dashboard'
                assert archive.testzip() is None
            (backup/'dashboards.zip').write_bytes(response.content)
            (backup/'inventory.json').write_text(json.dumps(report,indent=2)+'\n')
            response=session.delete(base+'/api/v1/dashboard/',params={'q':json.dumps(ids)},timeout=60)
            response.raise_for_status()
            assert response.json().get('message') == f'Deleted {len(ids)} dashboards'
            db.session.remove()
            after={d.slug:d for d in db.session.query(Dashboard).all()}
            assert not (RETIRED & after.keys())
            assert (db.session.query(Slice).count(),db.session.query(SqlaTable).count())==counts
            assert {s:after[s].export_to_dict(recursive=False,include_defaults=True) for s in KEEP}==current
            report.update(backupDirectory=str(backup),applied=True,remainingDashboards=sorted(after),currentDefinitionsUnchanged=True)
            (backup/'result.json').write_text(json.dumps(report,indent=2,default=str)+'\n')
        else:report['applied']=False
        print(json.dumps(report,indent=2,default=str))

if __name__=='__main__':main()
