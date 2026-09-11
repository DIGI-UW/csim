# CSiM dashboard versions

The [September reconciliation](../RECONCILIATION.md) also preserves the live test export in `exports/test-current-20260911`. Its 21 chart definitions, six datasets, layout and text match the supplied September test export; the live copy requires selections for collection location and Your hospital.

The April export is the selected technical baseline: 20 charts and six virtual
datasets for the Individual Data dashboard. Its exact historical deployment
still requires the team's confirmation. The three archives share dashboard UUID
`57a603fc-a061-443f-8270-287a975d1bfc` and the same six dataset UUIDs.

| Definition | April baseline | September test | September production |
| --- | --- | --- | --- |
| Charts | 20 | Same 20, plus **Date of most recent data** | Same 20 |
| Dataset SQL | Original definitions | All six SQL definitions match April | All six change the historical source table to **UTI Individual Historical 2024-2025** |
| Date calculation | `month_date` | Adds `time_aggregate` to the aggregate dataset; the five saved trends still use `month_date` | No `time_aggregate` column |
| Date display | Smart date defaults | Five trends use fixed Month–Year labels; saved chart grains include Month, Quarter and Year | Four trends use Month–Year; submission volume retains smart dates |
| Comparison charts and text | Original settings and instructions | Changes comparison conditions, headings and help text; adds the latest-data card to the layout | Includes later comparison conditions and selected presentation changes |
| Database records | None in dashboard archive | None in dashboard archive | None in dashboard archive |

These differences do not establish that the dataset SQL was damaged during
chart editing. The test SQL matches April. A calculated column can exist in a
dataset without being selected as a chart axis.

The corrected package starts from April. The test-only card is excluded. The
September files remain available for comparison and future explicitly selected
changes. Baseline connections are adapted to the isolated demo database;
reporting definitions are retained in `dashboard/baseline`.

- `exports/*/dashboard.zip`: unchanged source archives.
- `exports/*/unpacked`: unchanged exported definitions.
- `baseline-manifest.json`: fixed chart and dataset identities.
- `comparison/definitions.json`: UUID-matched field-level differences, with
  numeric chart/dataset IDs and modification timestamps excluded from chart
  setting comparisons. Original reference lists remain visible in the source files.
- `sql/*/<dataset-uuid>.sql`: readable SQL for each version.
- `../data/v1_schema_dump.sql`: separately supplied demo database records and schema.

Run `ruby scripts/verify_sources.rb` to verify the inputs and
`ruby scripts/compare_exports.rb` to regenerate the comparison and manifest.

The sources correspond to the team's [April export](https://drive.google.com/file/d/1mrTliQUVNyj79QrVghMVfpcne_3I84Ej/view),
[test export](https://drive.google.com/file/d/12Ga4em9USj6uaoogy4hOqvzOBD4Qsc-V/view), and
[production export](https://drive.google.com/file/d/11xsY-6Q_xLtFJ6MwZ98iBfNk03ilBkHh/view).

The original development tools were transferred from
`pmanko/clinical-ai-validation-harness`, directory `tools/csim-superset`, revision
`fa86f2d1a1c1883ee516887779111b3106d3dd4e` (harness pull request 111).
Their Git attribution is Piotr Mankowski. Superset modifications retain the
Apache license headers and are stored as source patches against pinned upstream
revisions.
