"""Read-only capture of the main dashboard and its shared saved definitions.

Run inside the existing Superset container with dashboard_import on PYTHONPATH.
No reporting queries, imports, or changes to saved definitions are performed.
"""
import argparse
import datetime
import hashlib
import io
import json
from pathlib import Path
import zipfile

from dashboard_import import connection
from superset.app import create_app


def inventory(slug, standalone):
    from superset import db
    from superset.models.dashboard import Dashboard
    from superset.models.slice import Slice
    from superset.connectors.sqla.models import SqlaTable

    db.session.remove()
    dashboard = db.session.query(Dashboard).filter_by(slug=slug).one()
    charts = {chart.id: chart for chart in dashboard.slices}
    linked = []
    for uuid in standalone:
        chart = db.session.query(Slice).filter_by(uuid=uuid).one()
        charts[chart.id] = chart
        linked.append(chart.id)
    dataset_ids = {chart.datasource_id for chart in charts.values()}
    metadata = json.loads(dashboard.json_metadata or '{}')
    for control in metadata.get('native_filter_configuration', []):
        dataset_ids.update(target['datasetId'] for target in control.get('targets', [])
                           if target.get('datasetId') is not None)
    datasets = [db.session.get(SqlaTable, id) for id in sorted(dataset_ids)]
    assert all(datasets), 'A referenced dataset is missing'

    def item(obj, name):
        definition = obj.export_to_dict(recursive=False, include_defaults=True)
        if isinstance(obj, SqlaTable):
            definition['columns'] = [column.export_to_dict(recursive=False, include_defaults=True)
                                     for column in sorted(obj.columns, key=lambda column: column.column_name)]
            definition['metrics'] = [metric.export_to_dict(recursive=False, include_defaults=True)
                                     for metric in sorted(obj.metrics, key=lambda metric: metric.metric_name)]
        return {'id': obj.id, 'uuid': str(obj.uuid), 'name': name,
                'changedOn': str(obj.changed_on), 'definition': definition}

    result = {'dashboard': item(dashboard, dashboard.dashboard_title),
              'charts': [item(chart, chart.slice_name) for chart in sorted(charts.values(), key=lambda c: c.id)],
              'datasets': [item(dataset, dataset.table_name) for dataset in datasets],
              'dashboardChartIds': sorted(chart.id for chart in dashboard.slices),
              'standaloneChartIds': sorted(linked),
              'databaseIds': sorted({dataset.database_id for dataset in datasets})}
    # Materialize while the model objects are attached; drop the read transaction.
    result = json.loads(json.dumps(result, default=str))
    db.session.remove()
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--slug', required=True)
    parser.add_argument('--standalone-uuid', action='append', default=[])
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--source-revision', required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    app = create_app()
    with app.app_context():
        before = inventory(args.slug, args.standalone_uuid)
        base, session = connection()
        exports = {}
        for kind, ids in [('dashboard', [before['dashboard']['id']]),
                          ('chart', [item['id'] for item in before['charts']]),
                          ('dataset', [item['id'] for item in before['datasets']])]:
            response = session.get(f'{base}/api/v1/{kind}/export/',
                                   params={'q': json.dumps(ids)}, timeout=120,
                                   allow_redirects=False)
            response.raise_for_status()
            assert response.status_code == 200, f'{kind}: HTTP {response.status_code}'
            with zipfile.ZipFile(io.BytesIO(response.content)) as bundle:
                assert bundle.testzip() is None
                names = bundle.namelist()
                files = [name for name in names if f'/{kind}s/' in name and name.endswith('.yaml')]
                assert len(files) == len(ids), (kind, len(files), len(ids))
                assert all(not Path(name).is_absolute() and '..' not in Path(name).parts for name in names)
                bundle.extractall(args.output / 'unpacked' / kind)
            (args.output / f'{kind}s.zip').write_bytes(response.content)
            exports[kind] = {'objects': len(ids), 'file': f'{kind}s.zip',
                             'sha256': hashlib.sha256(response.content).hexdigest()}
        after = inventory(args.slug, args.standalone_uuid)
    (args.output / 'inventory.json').write_text(json.dumps(before, indent=2, sort_keys=True) + '\n')
    manifest = {'capturedAt': started, 'completedAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                'slug': args.slug, 'sourceAssetsRevision': args.source_revision,
                'consistentDuringExport': before == after,
                'status': 'saved review snapshot; not a final accepted release',
                'reportingRowsIncluded': False, 'exports': exports}
    (args.output / 'capture.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print('CSIM_CAPTURE=' + json.dumps({'directory': str(args.output), **manifest}))
    assert before == after, 'Saved objects changed during capture. Preserve this snapshot and capture again.'


if __name__ == '__main__':
    main()
