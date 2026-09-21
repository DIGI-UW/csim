"""Apply the approved panel coverage labels/scopes and 4.1 explanation.

Resolve charts by UUID. Preserve Beth's current dashboard as the base. Refuse
concurrent edits; save rollback fields before writes. No import, SQL, metric,
palette, source data, default selection or Superset application changes.
"""
import argparse
import copy
import datetime
import json
from pathlib import Path


def proposed(before, plan):
    assert before['dashboard']['uuid'] == plan['dashboardUuid']
    assert len(plan['panels']) == 7
    position = json.loads(before['dashboard']['definition']['position_json'])
    metadata = json.loads(before['dashboard']['definition']['json_metadata'])
    chart_by_uuid = {chart['uuid']: chart for chart in before['charts']}
    updates = {}
    for panel in plan['panels']:
        chart = chart_by_uuid[panel['uuid']]
        nodes = [node for node in position.values() if isinstance(node, dict)
                 and node.get('type') == 'CHART' and node['meta'].get('uuid') == panel['uuid']]
        assert len(nodes) == 1
        assert nodes[0]['meta']['chartId'] == chart['id']
        nodes[0]['meta']['sliceNameOverride'] = panel['title']
        updates[chart['id']] = {'description': panel['description']}
    assert set(plan['filters']).issubset({f['id'] for f in metadata['native_filter_configuration']})
    for control in metadata['native_filter_configuration']:
        if control['id'] not in plan['filters']:
            continue
        assert control['filterType'] in ('filter_time','filter_timegrain')
        control['scope']['excluded'] = sorted(set(control['scope']['excluded']) | set(updates))
        control['chartsInScope'] = [id for id in control['chartsInScope'] if id not in updates]
    position[plan['formulaNode']]['meta']['code'] = plan['formula']
    return {'json_metadata': json.dumps(metadata), 'position_json': json.dumps(position)}, updates


def normalize(definition):
    result = copy.deepcopy(definition)
    for key in ('json_metadata', 'position_json'):
        if key in result:
            result[key] = json.loads(result[key])
    return result


def verify(before, after, payload, charts):
    assert normalize(after['dashboard']['definition']) == normalize({**before['dashboard']['definition'], **payload})
    for old, new in zip(before['charts'], after['charts'], strict=True):
        assert (old['id'], old['uuid'], old['name']) == (new['id'], new['uuid'], new['name'])
        assert new['definition'] == {**old['definition'], **charts.get(old['id'], {})}, f"Unexpected chart change: {old['id']}"
    for key in ('datasets','dashboardChartIds','standaloneChartIds','databaseIds'):
        assert before[key] == after[key], f'Unexpected {key} change'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--plan', type=Path, required=True)
    parser.add_argument('--expected-inventory', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    assert not args.output.exists(), 'Use a new receipt path.'
    plan = json.loads(args.plan.read_text())
    expected = json.loads(args.expected_inventory.read_text())
    from superset.app import create_app
    from capture_live_review import inventory
    from dashboard_import import connection
    app = create_app()
    with app.app_context():
        before = inventory(plan['slug'], [])
        assert before == expected, 'Live edits differ from the reviewed backup; capture and review them first.'
        payload, charts = proposed(before, plan)
        receipt = {'startedAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                   'slug': plan['slug'], 'dashboardId': before['dashboard']['id'],
                   'requested': {'dashboard': payload, 'charts': charts},
                   'rollback': {'dashboard': {k: before['dashboard']['definition'][k] for k in payload},
                                'charts': {c['id']: {'description': c['definition'].get('description')} for c in before['charts'] if c['id'] in charts}},
                   'applied': False, 'operationsCompleted': []}
        args.output.parent.mkdir(parents=True, exist_ok=True)
        def save():
            args.output.write_text(json.dumps(receipt, indent=2)+'\n')
        save()
        if args.apply:
            base, session = connection()
            assert inventory(plan['slug'], []) == before, 'Dashboard changed during preparation.'
            operations = [('dashboard', before['dashboard']['id'], payload)] + [('chart', id, value) for id, value in charts.items()]
            try:
                for kind, id, fields in operations:
                    for cookie in session.cookies:
                        cookie.secure = False  # local loopback CLI only
                    response = session.put(f'{base}/api/v1/{kind}/{id}', json=fields, timeout=30)
                    response.raise_for_status()
                    receipt['operationsCompleted'].append({'kind':kind,'id':id})
                    save()
                after = inventory(plan['slug'], [])
                verify(before, after, payload, charts)
                receipt.update(applied=True, verified=True, chartCount=len(after['charts']),
                               calculationsUnchanged=True, datasetsUnchanged=True,
                               otherDashboardSettingsUnchanged=True)
            except Exception as error:
                receipt['error'] = str(error)
                save()
                raise
            save()
        print(json.dumps({k:v for k,v in receipt.items() if k not in ('requested','rollback')}))


if __name__ == '__main__':
    main()
