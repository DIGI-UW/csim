"""Register the three existing demo upload tables without editing report assets.

These are Superset physical-dataset registrations, not table creation or data
uploads. Existing registrations are reused by database/schema/table name.
"""
import argparse
import json
import sqlite3
import uuid

from dashboard_import import connection
from superset.app import create_app

NAMES = ('CSiM Hospitals and States', 'UTI Individual Historical', 'UTI Individual Current')
REPORT_UUID = '12cf6aed-4a67-5829-88b4-2636ee62a97f'


def metadata(path):
    with sqlite3.connect(f'file:{path}?mode=ro', uri=True) as conn:
        conn.row_factory = sqlite3.Row
        return {name: {row['id']: dict(row) for row in conn.execute(f'SELECT * FROM {name}')}
                for name in ('dashboards', 'slices', 'tables')}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    app = create_app()
    with app.app_context():
        from superset import db
        from superset.connectors.sqla.models import SqlaTable
        anchor = db.session.query(SqlaTable).filter_by(uuid=REPORT_UUID).one()
        assert anchor.database.database_name == 'CSiM demo PostgreSQL', 'Use only the official demo connection'
        assert anchor.schema == 'v1'
        assert db.engine.url.drivername == 'sqlite'
        path = db.engine.url.database
        database_id = anchor.database_id
        found = {}
        for name in NAMES:
            rows = db.session.query(SqlaTable).filter_by(database_id=database_id, schema='v1', table_name=name).all()
            assert len(rows) <= 1, f'Duplicate existing source registrations: {name}'
            if rows:
                assert not rows[0].sql, f'{name} must be a physical dataset'
                found[name] = rows[0].id
        before = metadata(path)
        db.session.remove()
        created = []
        if args.apply:
            base, session = connection()
            for name in NAMES:
                if name in found:
                    continue
                for cookie in session.cookies:
                    cookie.secure = False
                response = session.post(base + '/api/v1/dataset/', json={
                    'database': database_id, 'schema': 'v1', 'table_name': name,
                    'uuid': str(uuid.uuid5(uuid.NAMESPACE_URL, 'https://csim.uwdigi.org/demo-source/v1/' + name)),
                }, timeout=60, allow_redirects=False)
                assert response.status_code == 201, f'{name}: HTTP {response.status_code} {response.text[:400]}'
                created.append(name)
        after = metadata(path)
        for kind, entries in before.items():
            assert {key: after[kind][key] for key in entries} == entries, f'An existing {kind} definition changed'
        result = []
        for name in NAMES:
            db.session.remove()
            table = db.session.query(SqlaTable).filter_by(database_id=database_id, schema='v1', table_name=name).one_or_none()
            if not args.apply and table is None:
                result.append({'name': name, 'registered': False})
                continue
            assert table is not None and not table.sql
            columns = {c.column_name for c in table.columns}
            if name.startswith('UTI Individual'):
                assert 'record_id' in columns
            if name == 'UTI Individual Current':
                assert 'redcap_repeat_instance' in columns
            result.append({'name': name, 'id': table.id, 'uuid': str(table.uuid),
                           'registered': True, 'type': 'physical', 'columns': sorted(columns)})
        print('CSIM_SOURCE_REGISTRATIONS=' + json.dumps({'applied': args.apply, 'created': created,
              'existingDefinitionsUnchanged': True, 'sources': result}))


if __name__ == '__main__':
    main()
