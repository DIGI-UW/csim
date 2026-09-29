"""Compare a native import with every saved definition in its package."""
import argparse
import copy
import json
import os
from pathlib import Path

import yaml
from superset.app import create_app
from dashboard_import import STANDARD_PROFILES, MONTH_PROFILES, CLIENT_PROFILES, linked_chart_definitions, resolve_chart_links

ROOT = Path(os.environ.get('CSIM_PROJECT_ROOT', '/repro'))


def read_yaml(path):
    return yaml.safe_load(path.read_text())


def verify(profile: str):
    root = ROOT / 'dashboard' / profile
    definition = read_yaml(next((root / 'dashboards').glob('*.yaml')))
    expected_nodes = {
        node['meta']['chartId']: node['meta']['uuid']
        for node in definition['position'].values()
        if isinstance(node, dict) and node.get('type') == 'CHART'
    }
    app = create_app()
    with app.app_context():
        from superset import db
        from superset.connectors.sqla.models import SqlaTable
        from superset.models.dashboard import Dashboard
        from superset.models.slice import Slice

        dashboard = db.session.query(Dashboard).filter_by(uuid=definition['uuid']).one()
        charts = {str(chart.uuid): chart for chart in dashboard.slices}
        assert set(charts) == set(expected_nodes.values())
        inventory = json.loads((root / 'manifest.json').read_text()) if (root / 'manifest.json').exists() else {'charts': 20, 'datasets': 6}
        assert len(charts) == inventory['charts']
        assert len(list((root / 'datasets').glob('**/*.yaml'))) == inventory['datasets']
        linked = {item['uuid']: db.session.query(Slice).filter_by(uuid=item['uuid']).one() for item in linked_chart_definitions(root)}
        assert all(not chart.dashboards for chart in linked.values())
        remap = {source: charts[uuid].id for source, uuid in expected_nodes.items()}
        assert any(source != target for source, target in remap.items())

        for dataset_file in (root / 'datasets').glob('**/*.yaml'):
            expected = read_yaml(dataset_file)
            actual = db.session.query(SqlaTable).filter_by(uuid=expected['uuid']).one()
            assert actual.sql == expected.get('sql'), expected['table_name']
            assert actual.main_dttm_col == expected.get('main_dttm_col'), expected['table_name']
            assert actual.catalog == expected.get('catalog'), expected['table_name']
            expected_columns = {column['column_name'] for column in expected.get('columns', [])}
            assert expected_columns == {column.column_name for column in actual.columns}, expected['table_name']
            actual_columns = {column.column_name: column for column in actual.columns}
            for column in expected.get('columns', []):
                for key in ('expression', 'type', 'is_dttm', 'groupby', 'filterable', 'python_date_format'):
                    if key in column:
                        assert getattr(actual_columns[column['column_name']], key) == column[key], (expected['table_name'], column['column_name'], key)
            actual_metrics = {metric.metric_name: metric for metric in actual.metrics}
            assert set(actual_metrics) == {metric['metric_name'] for metric in expected.get('metrics', [])}
            for metric in expected.get('metrics', []):
                for key in ('expression', 'metric_type', 'd3format'):
                    assert getattr(actual_metrics[metric['metric_name']], key) == metric.get(key), (expected['table_name'], metric['metric_name'], key)

        for chart_file in (root / 'charts').glob('*.yaml'):
            expected = read_yaml(chart_file)
            actual = (charts | linked)[expected['uuid']]
            actual_params = json.loads(actual.params)
            # A native import creates a new numeric dataset id and rewrites the
            # serialized datasource reference.  The stable dataset UUID is
            # checked immediately below; every other saved chart setting must
            # survive exactly.
            expected_params = dict(expected['params'])
            expected_params['datasource'] = actual_params['datasource']
            # Superset serializes an omitted empty annotation layer as an empty
            # list on import.  Both forms mean that the chart has no layers.
            if expected_params.get('annotation_layers') is None and actual_params.get('annotation_layers') == []:
                expected_params['annotation_layers'] = []
            if os.environ.get('CSIM_SNAPSHOT') == '1' and expected_params.get('viz_type') == 'table':
                expected_params['viz_type'] = 'ag-grid-table'
            if profile in ('corrected', 'examples', 'reconciled', 'reconciled-examples', *STANDARD_PROFILES, *MONTH_PROFILES, *CLIENT_PROFILES) and os.environ.get('CSIM_SNAPSHOT') != '1':
                expected_params['slice_id'] = actual.id
                expected_params['dashboards'] = [] if expected['uuid'] in linked else [dashboard.id]
            assert actual_params == expected_params, (expected['slice_name'], {key: {'expected': expected_params.get(key), 'actual': actual_params.get(key)} for key in set(expected_params) | set(actual_params) if expected_params.get(key) != actual_params.get(key)})
            dataset = db.session.get(SqlaTable, actual.datasource_id)
            assert str(dataset.uuid) == expected['dataset_uuid'], expected['slice_name']

        actual_position = json.loads(dashboard.position_json)
        expected_position = copy.deepcopy(definition['position'])
        for node in expected_position.values():
            if isinstance(node, dict) and node.get('type') == 'CHART':
                node['meta']['chartId'] = remap[node['meta']['chartId']]
        expected_position = resolve_chart_links(expected_position, {item['sourceId']: linked[item['uuid']].id for item in linked_chart_definitions(root)})
        assert actual_position == expected_position, 'Layout and chart placement must match the package'
        assert dashboard.css == definition.get('css'), 'Dashboard CSS'
        actual_metadata = json.loads(dashboard.json_metadata)
        actual_filters = {
            item['id']: item
            for item in actual_metadata['native_filter_configuration']
            if item.get('type') == 'NATIVE_FILTER'
        }
        expected_filters = [
            item for item in definition['metadata']['native_filter_configuration']
            if item.get('type') == 'NATIVE_FILTER'
        ]
        assert len(actual_filters) == len(expected_filters) == inventory.get('filters', 6)
        caches = []
        for expected in expected_filters:
            actual = actual_filters[expected['id']]
            assert actual.get('defaultDataMask') == expected.get('defaultDataMask'), expected['name']
            for key in ('filterType', 'controlValues', 'cascadeParentIds', 'time_grains', 'adhoc_filters', 'description'):
                assert actual.get(key) == expected.get(key), (expected['name'], key)
            for expected_target, actual_target in zip(expected.get('targets', []), actual.get('targets', []), strict=True):
                assert actual_target.get('column') == expected_target.get('column')
                if expected_target.get('datasetUuid'):
                    dataset = db.session.get(SqlaTable, actual_target['datasetId'])
                    assert str(dataset.uuid) == expected_target['datasetUuid'], expected['name']
            assert set(actual['scope']['excluded']) == {
                remap[chart] for chart in expected['scope'].get('excluded', []) if chart in remap
            }, expected['name']
            expected_cache = {remap[chart] for chart in expected.get('chartsInScope', []) if chart in remap}
            actual_cache = set(actual.get('chartsInScope', []))
            caches.append({
                'filter': expected['name'], 'matches': expected_cache == actual_cache,
                'expected': sorted(expected_cache), 'actual': sorted(actual_cache),
            })
        expected_global = {
            remap[chart]
            for chart in definition['metadata'].get('global_chart_configuration', {}).get('chartsInScope', [])
            if chart in remap
        }
        actual_global = set(actual_metadata.get('global_chart_configuration', {}).get('chartsInScope', []))
        report = {
            'profile': profile, 'charts': len(charts), 'datasets': inventory['datasets'], 'filters': len(actual_filters), 'standalone_charts': len(linked),
            'changed_chart_identifiers': sum(source != target for source, target in remap.items()),
            'cached_scope_references': {
                'all_match': all(item['matches'] for item in caches) and actual_global == expected_global,
                'filters': caches,
                'global_matches': actual_global == expected_global,
            },
        }
        Path(f'/tmp/csim-{profile}-import-verification.json').write_text(json.dumps(report, indent=2))
        print(json.dumps(report))
        if profile in ('corrected', 'preview', 'simple', 'simple-examples', 'examples', 'reconciled', 'reconciled-examples', *STANDARD_PROFILES, *MONTH_PROFILES, *CLIENT_PROFILES):
            assert report['cached_scope_references']['all_match'], 'Imported filter scope caches must match the intended chart references'


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--profile', choices=('baseline', 'corrected', 'preview', 'simple', 'simple-examples', 'examples', 'reconciled', 'reconciled-examples', *STANDARD_PROFILES, *MONTH_PROFILES, *CLIENT_PROFILES), default='corrected')
    verify(parser.parse_args().profile)
