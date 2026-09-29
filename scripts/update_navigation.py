"""Apply only approved headings, hospital guidance and ToC nesting.

Uses the live definitions as the starting point. Never imports charts/datasets,
changes filters, or restarts Superset. The receipt includes a rollback payload.
"""
import argparse, copy, datetime, json
from pathlib import Path
import yaml
from superset.app import create_app
from capture_live_review import inventory
from dashboard_import import connection

TEXT_IDS = ('MARKDOWN-kbpKudPZL01ntlPcgzEYI', 'MARKDOWN-WIofdf7GkSmIbs0pSuT-6', 'MARKDOWN-4LE_6MIsEUYEjgMUcvAyM')
DIVIDER_IDS = ('NATIVE_FILTER_DIVIDER-csim-main', 'NATIVE_FILTER_DIVIDER-csim-comparisons')


def proposed(definition, desired):
    metadata = json.loads(definition['json_metadata'])
    position = json.loads(definition['position_json'])
    original_filters = copy.deepcopy(metadata['native_filter_configuration'])
    # Preserve any unrelated native divider. Replace only our two own headings.
    controls = [f for f in original_filters if f['id'] not in DIVIDER_IDS]
    dividers = {f['id']: f for f in desired['metadata']['native_filter_configuration'] if f['id'] in DIVIDER_IDS}
    controls.insert(next(i for i, f in enumerate(controls) if f.get('name') == 'Hospital and state'), dividers[DIVIDER_IDS[0]])
    controls.insert(next(i for i, f in enumerate(controls) if f.get('name') == 'Your hospital'), dividers[DIVIDER_IDS[1]])
    metadata['native_filter_configuration'] = controls
    assert [f for f in controls if f.get('type') != 'DIVIDER'] == [f for f in original_filters if f.get('type') != 'DIVIDER']
    for id in TEXT_IDS:
        assert position[id]['type'] == 'MARKDOWN'
        position[id]['meta']['code'] = desired['position'][id]['meta']['code']
    return {'json_metadata': json.dumps(metadata), 'position_json': json.dumps(position)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--definition', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    assert not args.output.exists(), 'Use a new receipt path to preserve prior backup.'
    desired = yaml.safe_load(args.definition.read_text())
    app = create_app()
    with app.app_context():
        before = inventory(desired['slug'], [])
        assert before['dashboard']['uuid'] == desired['uuid']
        definition = before['dashboard']['definition']
        payload = proposed(definition, desired)
        rollback = {key: definition[key] for key in payload}
        receipt = {'startedAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                   'dashboardId': before['dashboard']['id'], 'slug': desired['slug'],
                   'rollback': rollback, 'requested': payload, 'applied': False}
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(receipt, indent=2) + '\n')
        if args.apply:
            assert inventory(desired['slug'], []) == before, 'Dashboard changed during preparation.'
            base, session = connection()
            response = session.put(f"{base}/api/v1/dashboard/{before['dashboard']['id']}", json=payload, timeout=30)
            response.raise_for_status()
            after = inventory(desired['slug'], [])
            expected = {**definition, **payload}
            actual = after['dashboard']['definition']
            # Ignore serialization whitespace; compare all persisted values.
            for key in ('json_metadata', 'position_json'):
                expected[key] = json.loads(expected[key])
                actual[key] = json.loads(actual[key])
            assert actual == expected, 'An unexpected dashboard field changed.'
            for key in ('charts', 'datasets', 'dashboardChartIds', 'databaseIds'):
                assert before[key] == after[key], f'{key} changed unexpectedly.'
            receipt.update(applied=True, verified=True, reportingDefinitionsUnchanged=True,
                           actualFiltersUnchanged=True, chartCount=len(after['charts']))
            args.output.write_text(json.dumps(receipt, indent=2) + '\n')
        print(json.dumps({k:v for k,v in receipt.items() if k not in ('rollback','requested')}))


if __name__ == '__main__':
    main()
