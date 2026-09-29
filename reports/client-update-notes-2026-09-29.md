# CSiM dashboard update notes, September 29

Two ready-to-import versions of the September 17 review dashboard, one for each
environment. Both contain the September 17 edits (latest urine culture submission
card, the panel descriptions and the saved layout and filters).

| Where it goes | Package | Reads Historical from |
|---|---|---|
| Demo or test instance | `dashboard/client-update-test` (new) | `UTI Individual Historical` |
| Client production instance | `dashboard/client-update` (unchanged) | `UTI Individual Historical 2024-2025` |

Each package keeps its own instance's database connection and table names. Neither
one carries a database connection, so importing does not change which database the
dashboard reads. No reporting data is touched.

## What importing does on the demo or test instance

- All 21 charts take the September 17 definitions.
- The earlier "Date of most recent data" card is replaced in place by "Latest Urine
  Culture Submission". It stays in the same spot and no duplicate is added.
- `UTI Aggregate ALL DATA` drops the `time_aggregate` column and gains
  `period_label`. Nothing in the update uses `time_aggregate`.
- `UTI Top Abx - Ind` and `UTI Location - Ind` also gain `period_label`.
- The filter label "Hospital and state" becomes "Hospital and State".

## Known issue, not fixed in this version

Historical data does not show newer uploads (the report that data stops at March
2026). This update does not change how Historical is read, so it neither fixes nor
worsens the problem. The cause is not confirmed. The main lead is that the table the
dashboard reads for Historical is not the table the latest upload went to.

What would settle it, using summary counts only and no patient-level rows:

1. The exact dashboard URL and date range where the data stops.
2. The name of the table the latest Historical upload created.
3. Hospital 53 monthly counts from each Historical table.

## Not yet checked

- This version has not been imported into a running Superset. The production package
  was rehearsed on a local Superset earlier (`release/client-update/rehearsal.json`).
- After importing on the demo instance, please check that all 21 panels load, the
  latest submission card shows a date, and clearing then reselecting a hospital
  filter recovers.

## Checksums

- Test package archive: `5a14c15e21c6901c5e46ec7396e8efe71ae1008f2db6b0b4d91d872fbeb8c928`
- Production release archive: `7555fbc7930b49ada3a48e5bb6c48068d3c724ca8e798484ce9f5d09f2056b60`
