# Client update built on the September 10 test export

This is a second update package, built the same way as `dashboard/client-update`
but keeping the identities, database connection and source tables of the test
export instead of the production export. It sits beside the production package
and does not replace it.

**Status: structurally verified, not import-rehearsed, no release ZIP or checksums.**

| Target | Package |
|---|---|
| Demo or test instance | `dashboard/client-update-test` (this note) |
| Client production instance | `dashboard/client-update` (release bundle in `release/client-update`) |

Both carry the same September 17 review content. Importing this package into
production would switch its Historical relation (see Cautions).

## Inputs

| Input | Location |
|---|---|
| Client baseline | `sources/exports/test-september-2026` (exported 2026-09-10 18:20 UTC, 21 charts, 6 datasets). The copy in `Downloads/dashboard_export_20260910T182010` is byte-identical. |
| Reviewed content | `sources/live-review/2026-09-17T163028Z` with `dashboard/overlays/beth-panel-coverage.json`, the same content as the production package |
| Output | `dashboard/client-update-test` and `dashboard/client-baseline-test` |

Regenerate and test (Ruby 2.6 is enough):

```sh
CSIM_CLIENT_BASELINE=test-september-2026 CSIM_UPDATE_PROFILE=client-update-test ruby scripts/prepare_client_update.rb
ruby scripts/test_client_update_test_export.rb
CSIM_PROJECT_ROOT=$PWD python3 scripts/dashboard_import.py pack --profile client-update-test
```

With no environment variables the builder produces the production package exactly as before.
`pack` writes `/tmp/csim-client-update-test-dashboard.zip`, which has no database definition.

## Differences from the production package

Compared by content, matched on UUID and name:

- **Database connection:** the export's host is `172.18.0.11`, production's is `postgres`. Neither is shipped in the update archive.
- **Historical relation:** all five datasets that read it use `UTI Individual Historical`. Production uses `UTI Individual Historical 2024-2025`.
- **Latest-data card:** the export already has `Date of most recent data` (`33866218-9d48-480a-94c9-75860633d428`). The reviewed card `Latest Urine Culture Submission` is mapped onto that UUID so an import replaces it in place. Production has no such card, so it is added there as a new object. This mapping is `RENAMED_CLIENT_CHARTS` in `scripts/prepare_client_update.rb`.
- **Everything else is identical:** six datasets (after the relation rename), the other 20 charts, dashboard metadata and all layout nodes except the card's own. Chart file names differ because they carry export-local ids.

## What an import changes on the test instance

Measured against the test export:

- All 21 charts change (`params` and `query_context`), and 15 also change `description`. This is the September 17 review.
- `UTI Aggregate ALL DATA` loses the `time_aggregate` column and gains `period_label`. Nothing in the new package references `time_aggregate`, and in the export only the dataset declared it.
- `UTI Top Abx - Ind` and `UTI Location - Ind` gain `period_label`. The SQL of these three datasets changes. The other three are identical.
- The filter `Hospital and state` is renamed `Hospital and State`.

## Verified

- `scripts/test_client_update_test_export.rb`: 5 runs, 98 assertions, 0 failures.
- `scripts/test_client_update.rb` (production): 4 runs, 92 assertions, 0 failures, and the regenerated production package leaves the working tree unchanged.
- Control: the production archive built by the changed importer is identical, entry for entry, to `release/client-update/csim-client-update-dashboard.zip`.
- Database, dashboard, six dataset and 21 chart identities all equal the test export. There are no duplicate chart UUIDs and no `csim_demo` reference.
- A UUID-set comparison finds 2 UUIDs in the package that the export lacks and 4 in the export that the package lacks. All six are dataset column ids inside chart `query_context` blobs. They come from the reviewed chart definitions replacing the export's, and the production package shows the same pattern.

## Cautions

- Known issue, unchanged in this version: Historical data does not show newer uploads on the client instance (`reports/march-cutoff-2026-09-18.md`). Neither package changes how Historical is read, so this version neither fixes nor worsens it. The cause is not confirmed.
- The March 2026 cutoff note warns against switching the Historical source name without checking the source columns and the upload target. This package uses the unsuffixed name, so it is only correct for an instance whose Historical table has that name.
- `scripts/dashboard_import.py` now treats `client-update-*` profiles like `client-update` (no database definition, sparse import). The `import` and `receipt` paths were not run because they need a Superset instance.

## Not done

- No import rehearsal. `scripts/rehearse_client_update.py` names the production profiles directly and needs a running Superset stack, and no Superset image is available locally.
- No release ZIP, checksums or installer wiring for this profile.
- Neither client-update test runs in CI, and CI is currently blocked by the GitHub Actions budget.
