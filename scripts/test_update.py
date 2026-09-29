"""Exercise changed definitions and restore them using native assets import."""
import argparse
import copy
import json
from pathlib import Path
import shutil
import tempfile
import yaml

import dashboard_import as importer
import verify_import as verifier


def check_update(profile):
    original = importer.package(profile)
    with tempfile.TemporaryDirectory(prefix='csim-update-') as temporary:
        root = Path(temporary)
        changed = root / 'dashboard' / profile
        shutil.copytree(original, changed)
        dataset_file = next((changed / 'datasets').rglob('*.yaml'))
        dataset = yaml.safe_load(dataset_file.read_text())
        dataset['sql'] += '\n-- CSiM update regression: same dataset identity.\n'
        dataset['columns'][0]['expression'] = 'NULL'
        dataset['metrics'][0]['expression'] = 'COUNT(*) /* CSiM update regression */'
        dataset_file.write_text(yaml.safe_dump(dataset, sort_keys=False))
        chart_file = next((changed / 'charts').glob('*.yaml'))
        chart = yaml.safe_load(chart_file.read_text())
        chart['params']['x_axis_title'] = 'Updated through the versioned package'
        chart_file.write_text(yaml.safe_dump(chart, sort_keys=False))
        dashboard_file = next((changed / 'dashboards').glob('*.yaml'))
        dashboard = yaml.safe_load(dashboard_file.read_text())
        note = next(node for node in dashboard['position'].values() if isinstance(node, dict) and node.get('type') == 'MARKDOWN')
        note['meta']['code'] += '\n\nUpdate regression marker.'
        dashboard_file.write_text(yaml.safe_dump(dashboard, sort_keys=False))
        source_root = importer.ROOT
        try:
            importer.ROOT = verifier.ROOT = root
            importer.import_dashboard(profile)
            verifier.verify(profile)
        finally:
            importer.ROOT = verifier.ROOT = source_root
            importer.import_dashboard(profile)
        verifier.verify(profile)
        print(json.dumps({'profile': profile, 'update_existing_definitions': 'passed',
            'restored_original_definitions': 'passed',
            'checked': ['SQL', 'calculated column expression', 'metric expression', 'chart setting', 'layout text', 'stable UUIDs and no duplicate matches']}))

if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--profile', choices=['corrected','preview','reconciled','reconciled-examples',*importer.STANDARD_PROFILES,*importer.MONTH_PROFILES,*importer.CLIENT_PROFILES],default='corrected')
    check_update(parser.parse_args().profile)
