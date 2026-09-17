"""Rehearse the client baseline import and two update imports in isolation."""
import json
from pathlib import Path

import dashboard_import as importer
import verify_import as verifier
import yaml
from superset.app import create_app


ROOT = importer.ROOT


def saved(path):
    return yaml.safe_load(path.read_text())


def package_uuids(profile):
    root = importer.package(profile)
    return {
        'dashboard': saved(next((root / 'dashboards').glob('*.yaml')))['uuid'],
        'charts': {saved(path)['uuid'] for path in (root / 'charts').glob('*.yaml')},
        'datasets': {saved(path)['uuid'] for path in (root / 'datasets').rglob('*.yaml')},
    }


def inventory(expected):
    from superset import db
    from superset.connectors.sqla.models import SqlaTable
    from superset.models.core import Database
    from superset.models.dashboard import Dashboard
    from superset.models.slice import Slice

    database_uuid = saved(next((importer.package('client-update') / 'databases').glob('*.yaml')))['uuid']
    database = db.session.query(Database).filter_by(uuid=database_uuid).one()
    dashboard = db.session.query(Dashboard).filter_by(uuid=expected['dashboard']).one()
    chart_counts = {
        uuid: db.session.query(Slice).filter_by(uuid=uuid).count()
        for uuid in expected['charts']
    }
    dataset_counts = {
        uuid: db.session.query(SqlaTable).filter_by(uuid=uuid).count()
        for uuid in expected['datasets']
    }
    result = {
        'database': {
            'id': database.id,
            'uuid': str(database.uuid),
            'name': database.database_name,
            'sqlalchemyUriStored': database.sqlalchemy_uri,
            'extra': database.extra,
            'allowFileUpload': database.allow_file_upload,
            'exposeInSqlLab': database.expose_in_sqllab,
        },
        'dashboard': {'id': dashboard.id, 'uuid': str(dashboard.uuid), 'slug': dashboard.slug},
        'chartUuids': sorted(str(chart.uuid) for chart in dashboard.slices),
        'datasetUuids': sorted(str(item.uuid) for item in db.session.query(SqlaTable).filter(SqlaTable.uuid.in_(expected['datasets'])).all()),
        'uniqueCharts': all(count == 1 for count in chart_counts.values()),
        'uniqueDatasets': all(count == 1 for count in dataset_counts.values()),
    }
    db.session.remove()
    return result


def main():
    baseline = package_uuids('client-baseline')
    update = package_uuids('client-update')
    assert baseline['dashboard'] == update['dashboard']
    assert baseline['datasets'] == update['datasets']
    assert baseline['charts'] < update['charts']
    assert len(update['charts'] - baseline['charts']) == 1

    app = create_app()
    with app.app_context():
        importer.import_dashboard('client-baseline')
        verifier.verify('client-baseline')
        baseline_state = inventory(baseline)

        importer.import_dashboard('client-update')
        verifier.verify('client-update')
        first = inventory(update)

        importer.import_dashboard('client-update')
        verifier.verify('client-update')
        second = inventory(update)

    assert baseline_state['database'] == first['database'] == second['database']
    assert baseline_state['dashboard'] == first['dashboard'] == second['dashboard']
    assert first == second
    assert first['uniqueCharts'] and first['uniqueDatasets']
    assert len(first['chartUuids']) == 21
    assert len(first['datasetUuids']) == 6

    dashboard = saved(next((importer.package('client-update') / 'dashboards').glob('*.yaml')))
    toc = dashboard['position']['MARKDOWN-kbpKudPZL01ntlPcgzEYI']['meta']['code']
    assert toc.count('](#HEADER-') == 9

    receipt = {
        'baselineImport': 'passed',
        'firstUpdateImport': 'passed',
        'secondUpdateImport': 'passed',
        'noDuplicateObjects': True,
        'databaseConnectionUnchanged': True,
        'dashboardIdentityUnchanged': True,
        'datasetIdentitiesUnchanged': True,
        'charts': 21,
        'datasets': 6,
        'tableOfContentsLinks': 9,
        'definitionVerification': [
            'SQL', 'calculated columns', 'measures', 'chart settings', 'palette metadata',
            'layout', 'filter defaults', 'filter scopes', 'cached scope references'
        ],
        'reportingRowsIncludedInPackage': False,
        'state': second,
    }
    destination = Path('/tmp/csim-client-update-rehearsal.json')
    destination.write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps({key: value for key, value in receipt.items() if key != 'state'}))


if __name__ == '__main__':
    main()
