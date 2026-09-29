"""Install the September copies while proving existing dashboard definitions stay intact."""
import hashlib
import json
from pathlib import Path

import dashboard_import as importer
import verify_import as verifier
from superset.app import create_app


def established_definitions(exclude_slugs=('csim-individual-reconciled', 'csim-reconciled-examples')):
    from superset import db
    from superset.models.dashboard import Dashboard
    from superset.connectors.sqla.models import SqlaTable

    result = {}
    for dashboard in db.session.query(Dashboard).all():
        if dashboard.slug in exclude_slugs:
            continue
        charts = []
        datasets = {}
        for chart in dashboard.slices:
            charts.append({'uuid': str(chart.uuid), 'name': chart.slice_name,
                           'params': json.loads(chart.params), 'datasetId': chart.datasource_id})
            dataset = db.session.get(SqlaTable, chart.datasource_id)
            datasets[str(dataset.uuid)] = {
                'sql': dataset.sql, 'databaseId': dataset.database_id,
                'columns': sorted([(c.column_name, c.expression, c.type, c.is_dttm) for c in dataset.columns]),
                'metrics': sorted([(m.metric_name, m.expression, m.d3format) for m in dataset.metrics]),
            }
        result[str(dashboard.uuid)] = {'title': dashboard.dashboard_title, 'slug': dashboard.slug,
            'position': json.loads(dashboard.position_json), 'metadata': json.loads(dashboard.json_metadata),
            'css': dashboard.css, 'charts': sorted(charts, key=lambda c: c['uuid']), 'datasets': datasets}
    return result


def fingerprint(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()


def main():
    app = create_app()
    with app.app_context():
        before = established_definitions()
    assert before, 'Expected an established dashboard before adding comparison versions'
    for profile in ('reconciled', 'reconciled-examples'):
        importer.import_dashboard(profile)
        verifier.verify(profile)
        importer.receipt(profile)
        Path(f'/tmp/csim-{profile}-dashboard.zip').write_bytes(importer.archive(importer.package(profile)))
    with app.app_context():
        after = established_definitions()
    assert after == before, 'An established dashboard, chart or dataset definition changed'
    result = {'existingDashboardsUnchanged': len(before), 'beforeSha256': fingerprint(before),
              'afterSha256': fingerprint(after), 'addedProfiles': ['reconciled', 'reconciled-examples']}
    Path('/tmp/csim-reconciliation-verification.json').write_text(json.dumps(result, indent=2))
    print(json.dumps(result))


if __name__ == '__main__':
    main()
