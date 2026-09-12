"""Prove separate September copies survive alternating native imports unchanged."""
import json

import dashboard_import as importer
import verify_import as verifier
from reconcile import established_definitions, fingerprint
from superset.app import create_app


def main():
    profiles = ('reconciled', 'reconciled-months', 'reconciled-examples', 'reconciled-months-examples')
    app = create_app()
    with app.app_context():
        before = established_definitions(exclude_slugs=())
    for profile in profiles:
        verifier.verify(profile)
    for profile in reversed(profiles):
        importer.import_dashboard(profile)
        # A UUID-only check misses Superset's fallback name match. Compare all
        # persisted definitions after each import, including the other copies.
        with app.app_context():
            after = established_definitions(exclude_slugs=())
        assert after == before, f'{profile} import changed an existing dashboard or dataset'
        for other in profiles:
            verifier.verify(other)
    print(json.dumps({'alternatingImports': list(reversed(profiles)),
        'existingDashboardsUnchanged': len(before),
        'beforeSha256': fingerprint(before), 'afterSha256': fingerprint(after),
        'datasetIdentityIsolation': 'passed'}))


if __name__ == '__main__':
    main()
