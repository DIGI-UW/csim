"""Import a saved CSiM dashboard package through Superset's native API.

The package contains SQL and the database connection template, never a database
password. It can be imported repeatedly without restoring the reporting database.
"""
import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import zipfile

import requests
import yaml

ROOT = Path(os.environ.get('CSIM_PROJECT_ROOT', '/repro'))
STANDARD_PROFILES = ('standard', 'standard-examples', 'development', 'development-examples', 'standard-sortable', 'development-sortable', 'standard-sortable-examples', 'development-sortable-examples')
STANDARD_PROFILES += ('standard-month-selectors', 'standard-month-selectors-examples')
MONTH_PROFILES = ('reconciled-months', 'reconciled-months-examples')


def package(profile: str) -> Path:
    directory = ROOT / 'dashboard' / profile
    if not (directory / 'metadata.yaml').is_file():
        raise ValueError(f'Unknown dashboard profile: {profile}')
    return directory


def connection():
    base = 'http://localhost:8088'
    session = requests.Session()
    login = session.post(
        f'{base}/api/v1/security/login',
        json={'username': 'demo', 'password': os.environ['CSIM_ADMIN_PASSWORD'], 'provider': 'db'},
        timeout=30,
    )
    login.raise_for_status()
    session.headers['Authorization'] = f"Bearer {login.json()['access_token']}"
    csrf = session.get(f'{base}/api/v1/security/csrf_token/', timeout=30)
    csrf.raise_for_status()
    session.headers['X-CSRFToken'] = csrf.json()['result']
    session.headers['Referer'] = f'{base}/'
    # This CLI connects only to the service's own loopback HTTP listener.
    # Keep its CSRF session cookie on that connection when public browser
    # cookies are HTTPS-only. The server's browser cookie policy is unchanged.
    for cookie in session.cookies:
        cookie.secure = False
    return base, session


def archive(directory: Path) -> bytes:
    payload = io.BytesIO()
    with zipfile.ZipFile(payload, 'w', zipfile.ZIP_DEFLATED) as target:
        for file in sorted(directory.rglob('*.yaml')):
            entry = zipfile.ZipInfo(
                f'csim/{file.relative_to(directory).as_posix()}', date_time=(1980, 1, 1, 0, 0, 0)
            )
            entry.compress_type = zipfile.ZIP_DEFLATED
            contents = file.read_bytes()
            if file.relative_to(directory).as_posix() == 'metadata.yaml':
                metadata = yaml.safe_load(contents)
                metadata['type'] = 'assets'
                contents = yaml.safe_dump(metadata, sort_keys=True).encode()
            target.writestr(entry, contents)
    return payload.getvalue()


def dashboard_definition(directory: Path):
    dashboards = list((directory / 'dashboards').glob('*.yaml'))
    if len(dashboards) != 1:
        raise ValueError('Expected one dashboard definition')
    return yaml.safe_load(dashboards[0].read_text())


def import_dashboard(profile: str):
    directory = package(profile)
    base, session = connection()
    passwords = {
        file.relative_to(directory).as_posix(): os.environ['CSIM_DB_PASSWORD']
        for file in (directory / 'databases').glob('*.yaml')
    }
    response = session.post(
        f'{base}/api/v1/assets/import/',
        files={'bundle': ('csim-dashboard.zip', archive(directory), 'application/zip')},
        data={'passwords': json.dumps(passwords), 'overwrite': 'true'},
        timeout=120,
        allow_redirects=False,
    )
    if response.status_code != 200:
        raise ValueError(f'Native assets import failed ({response.status_code}): {response.text[:2000]}')
    if response.json().get('message') != 'OK':
        raise ValueError(f'Unexpected native import response: {response.text[:1000]}')
    if profile in ('corrected','examples','reconciled','reconciled-examples', *STANDARD_PROFILES, *MONTH_PROFILES) and os.environ.get('CSIM_SNAPSHOT') != '1':
        repair_numeric_references(directory)
    return directory


def linked_chart_definitions(directory):
    manifest = directory / 'manifest.json'
    return json.loads(manifest.read_text()).get('standaloneCharts', []) if manifest.exists() else []


def resolve_chart_links(position, mapping):
    # The source package uses its own chart ids. Resolve only explicit linked
    # chart URLs, once, so replacement ids cannot cascade into other links.
    import re
    for node in position.values():
        code = node.get('meta', {}).get('code') if isinstance(node, dict) else None
        if isinstance(code, str):
            node['meta']['code'] = re.sub(
                r'/explore/\?slice_id=(\d+)(?=[)#&\s]|$)',
                lambda match: '/explore/?slice_id=' + str(mapping.get(int(match[1]), int(match[1]))), code)
    return position


def repair_numeric_references(directory: Path):
    """Repair numeric references that Superset 6.1 leaves behind on import.

    Import uses UUIDs to create the charts successfully, but 6.1 retains source
    chart ids in cached filter scopes and in each chart's serialized form data.
    Those values are not authoritative definitions, but stale ids make a
    transferred dashboard fragile.  This repair derives every replacement from
    the package UUIDs and the destination objects; it never relies on a source
    instance's numeric ids.
    """
    definition = dashboard_definition(directory)
    source_nodes = {
        node['meta']['chartId']: node['meta']['uuid']
        for node in definition['position'].values()
        if isinstance(node, dict) and node.get('type') == 'CHART'
    }
    from superset.app import create_app

    app = create_app()
    with app.app_context():
        from superset import db
        from superset.models.dashboard import Dashboard
        from superset.models.slice import Slice

        dashboard = db.session.query(Dashboard).filter_by(uuid=definition['uuid']).one()
        actual_by_uuid = {str(chart.uuid): chart for chart in dashboard.slices}
        remap = {
            source: actual_by_uuid[uuid].id
            for source, uuid in source_nodes.items()
            if uuid in actual_by_uuid
        }
        if len(remap) != len(source_nodes):
            raise ValueError('Cannot repair dashboard references: a chart is missing')

        metadata = json.loads(dashboard.json_metadata)
        source_filters = {
            item['id']: item
            for item in definition['metadata'].get('native_filter_configuration', [])
            if item.get('type') == 'NATIVE_FILTER'
        }
        repaired_caches = 0
        for native_filter in metadata.get('native_filter_configuration', []):
            if native_filter.get('type') != 'NATIVE_FILTER':
                continue
            source_cache = source_filters[native_filter['id']].get('chartsInScope', [])
            destination_cache = [remap[source] for source in source_cache if source in remap]
            if native_filter.get('chartsInScope', []) != destination_cache:
                native_filter['chartsInScope'] = destination_cache
                repaired_caches += 1
        global_config = metadata.get('global_chart_configuration')
        if isinstance(global_config, dict):
            source_cache = definition['metadata'].get('global_chart_configuration', {}).get('chartsInScope', [])
            destination_cache = [remap[source] for source in source_cache if source in remap]
            if global_config.get('chartsInScope', []) != destination_cache:
                global_config['chartsInScope'] = destination_cache
                repaired_caches += 1
        dashboard.json_metadata = json.dumps(metadata)
        linked_map = {}
        for linked in linked_chart_definitions(directory):
            chart = db.session.query(Slice).filter_by(uuid=linked['uuid']).one()
            if chart.dashboards:
                raise ValueError('The download chart must remain outside dashboard filter scopes')
            params = json.loads(chart.params)
            params['slice_id'] = chart.id
            params['dashboards'] = []
            chart.params = json.dumps(params)
            linked_map[linked['sourceId']] = chart.id
        if linked_map:
            # Use the package's unresolved markdown, not the previously saved
            # destination, to keep updates independent of local identifier values.
            position = json.loads(dashboard.position_json)
            for key, node in definition['position'].items():
                if isinstance(node, dict) and 'code' in node.get('meta', {}):
                    position[key]['meta']['code'] = node['meta']['code']
            dashboard.position_json = json.dumps(resolve_chart_links(position, linked_map))

        for chart in actual_by_uuid.values():
            params = json.loads(chart.params)
            params['slice_id'] = chart.id
            params['dashboards'] = [dashboard.id]
            chart.params = json.dumps(params)
        db.session.commit()
        print(json.dumps({
            'numeric_reference_repair': 'OK',
            'destination_dashboard_id': dashboard.id,
            'remapped_charts': len(remap),
            'repaired_cached_scopes': repaired_caches,
        }))


def receipt(profile: str):
    directory = package(profile)
    definition = dashboard_definition(directory)
    from superset.app import create_app

    app = create_app()
    with app.app_context():
        from superset import db
        from superset.models.dashboard import Dashboard
        from superset.models.slice import Slice

        dashboard = db.session.query(Dashboard).filter_by(uuid=definition['uuid']).one()
        expected = {
            node['meta']['uuid']
            for node in definition['position'].values()
            if isinstance(node, dict) and node.get('type') == 'CHART'
        }
        charts = {
            str(chart.uuid): chart.id
            for chart in db.session.query(Slice).filter(Slice.uuid.in_(expected)).all()
        }
        if set(charts) != expected:
            raise ValueError('Imported dashboard is missing a saved chart definition')
        result = {
            'profile': profile,
            'dashboard_id': dashboard.id,
            'dashboard_uuid': str(dashboard.uuid),
            'charts': charts,
            'package_sha256': hashlib.sha256(archive(directory)).hexdigest(),
        }
        destination = Path(f'/tmp/csim-{profile}-receipt.json')
        destination.write_text(json.dumps(result, indent=2))
        print(json.dumps(result))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=('import', 'receipt', 'pack'))
    parser.add_argument('--profile', choices=('baseline', 'corrected', 'preview', 'hourly', 'examples', 'simple', 'simple-examples', 'reconciled', 'reconciled-examples', *STANDARD_PROFILES, *MONTH_PROFILES), default='corrected')
    args = parser.parse_args()
    if args.action == 'import':
        import_dashboard(args.profile)
        print(json.dumps({'profile': args.profile, 'native_import_status': 'OK'}))
    elif args.action == 'receipt':
        receipt(args.profile)
    else:
        output = Path(f'/tmp/csim-{args.profile}-dashboard.zip')
        output.write_bytes(archive(package(args.profile)))
        print(output)
