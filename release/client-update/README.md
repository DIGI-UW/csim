# CSiM main dashboard client update

This directory contains the tested update for the client's existing **CSiM
UTI/ASB Dashboard [Individual Data]** on official Superset 6.1.0.

## Files

- `manual/` — three ordered ZIP files for installation through the official
  Superset 6.1.0 Datasets, Charts, and Dashboards import screens. This is the
  primary path for a one-time client handoff.
- `csim-client-update-dashboard.zip` — a sparse Superset asset bundle with the
  main dashboard, 21 charts and six reporting datasets. It deliberately omits
  the PostgreSQL database object.
- `SHA256SUMS` — checksum for the exact ZIP that was rehearsed.
- `rehearsal.json` — machine-readable result from the clean import rehearsal.
- `baseline-comparison.json` — object-level comparison of the newly supplied
  September ZIP with the preserved production baseline.

The ZIP contains definitions only. It contains no Current, Historical, hospital,
or other reporting rows, database connection definition, or credential. It does
not restore or replace the client's PostgreSQL database.

## What is preserved

The package retains the September production export's dashboard UUID, all six
dataset UUIDs, database UUID reference and client table names. The helper uses
Superset's sparse asset-import mode so the existing database object supplies that
UUID mapping without being imported or overwritten. The reviewed dashboard
changes are applied on top of those identities.

The supplied `dashboard_export_20260910T185547 (2).zip` and the repository's
preserved September production export have different archive hashes but
identical definitions: one dashboard, 20 charts, six datasets, and one database,
with no object-level changes.

## Rehearsed result

The update was tested in a clean, isolated official Superset 6.1.0 instance:

1. Import the client baseline.
2. Import this update over it.
3. Import the same update a second time.

All three imports passed. The second update created no duplicates. Before the
updates, the rehearsal replaced the baseline's connection with a distinct,
working destination connection. The update omitted the database object, retained
those connection settings and credentials, and queried the same source table
successfully before and after both updates. The dashboard identity and six
dataset identities also stayed unchanged.
The verifier compared SQL, calculated columns, measures, chart settings, color
metadata, layout, filter defaults and scopes, cached filter references, and all
nine Table of Contents links.

This is technical import evidence. It is not evidence that the package has
already been installed in the client's Superset or accepted by the client.

## Installation sequence

For a manual installation, follow [`manual/README.md`](manual/README.md). Import
the dataset, chart, and dashboard ZIPs in that order, then open and save each
dashboard filter once so Superset records its scope using the destination's
numeric chart identifiers.

For a repeatable administrator installation:

1. In the destination's existing `superset_config.py`, enable the built-in SQL
   templates used by the date queries. Add `"ENABLE_TEMPLATE_PROCESSING": True`
   to the existing `FEATURE_FLAGS` dictionary without removing its other
   entries. On the dedicated CSiM instance, also copy the tested
   `TIME_GRAIN_DENYLIST` from [`superset_config.py`](../../superset_config.py) to
   keep the Time Unit menu to Month, Quarter and Year. The denylist affects the
   whole Superset instance; the template-processing flag is required for the
   delivered `get_time_filter`, `filter_values`, and `time_grain` logic. Restart
   the Superset processes that load the configuration after changing it.
2. Export and retain a fresh backup from the destination instance. If the
   destination definitions were edited after the September export, compare that
   backup before continuing.
3. Confirm that the destination dashboard, database, and six reporting datasets
   have the UUIDs recorded in `dashboard/client-update/manifest.json`.
4. Run the repository importer for the client update inside the destination's
   configured Superset Python environment. Set `CSIM_PROJECT_ROOT`,
   `CSIM_SUPERSET_URL`, `CSIM_SUPERSET_USERNAME`, and `CSIM_ADMIN_PASSWORD` for
   that environment. The helper uses Superset's sparse asset importer without a
   database definition, then repairs numeric chart references and cached filter
   scopes that official Superset 6.1.0 can otherwise retain from the source
   instance:

   ```sh
   python scripts/dashboard_import.py import --profile client-update
   python scripts/verify_import.py --profile client-update
   ```

5. Open the dashboard and check the agreed Month, Quarter, Year, date-range,
   colors, seven date-scope panels, section 4.1 wording, and Table of Contents
   workflows before making it the accepted client release.
6. Roll back with the fresh destination backup if any destination-specific
   difference is unexpected.

Do not upload the single `csim-client-update-dashboard.zip` through Superset's
manual import screen; use the three files in `manual/` instead. Do not
restore the demo database, change the destination connection, or import the
example dashboards as part of this update.

The separate **Data & records** supporting dashboard and record-review table are
not inside this main-dashboard ZIP. They remain a separately reviewed supporting
view so their addition cannot change the familiar main dashboard during import.
