# September 18 CSiM follow-up

The two supplied Zoom VTT files are byte-identical (SHA-256
`c6b62a6b50a49d7680f4f923d18cac253569e563d87ed7fef307575b2d7c688b`).
Times below are elapsed meeting times. Statements from the meeting are separated
from checks against the repository and demo.

| Topic | Meeting evidence | Follow-up |
|---|---|---|
| Missing hospital | 11:27–12:49: hospital 58 is missing from Hospitals and States; Maria will upload an updated complete lookup file. | Verify the hospital appears after that upload and refresh. This is a separate source-table maintenance step; no new automatic registration requirement was agreed. |
| Data download | 14:00–17:01: Maria wants SQL-processed Historical data, then refers to Beth's combined Current and Historical result. Dataset Export yields YAML; CSV or Excel is wanted. | Use a saved Table chart for data downloads. Confirm example output: individual records, monthly summaries, or both. Dataset-definition export is not the data path. |
| Identifiers | 20:14–20:22: record ID from both sources; Current also needs REDCap Repeat Instance. | Keep these on individual rows; adding them as grouping keys would change summary calculations. Prior discussion with Beth accepted a separate review chart. |
| Embedded contents links | 04:21–06:15: links work standalone but not in the website iframe. | Add direct, iframe and kiosk iframe regression on official 6.1.0. Check actual client embed URL and attributes before attributing its failure. |
| Legacy dashboard | 04:01–04:21: Historical Aggregate dashboard is unused and outside the Individual dashboard update. | Leave it unchanged. Historical source records remain in scope for the active Individual dashboard and export. |
| Extra survey question | 13:02–13:20: unused new REDCap column may be uploaded. | Existing reporting SQL selects named columns, so an added unused field needs no chart change. Confirm upload preserves required existing columns and types. Meeting contains no completed upload test. |

## Verified download path

Demo: <https://standard.csim.uwdigi.org/explore/?slice_id=131>

**Update chart → ⋯ → Data Export Options → Export All Data → Export to .CSV**.
This exact menu was inspected on the public official 6.1.0 demo. The saved chart
and its dataset have cache timeout -1; a fresh chart query reads uploaded tables.
This does not require SQL Lab or exporting a dataset definition.

The local browser regression `record-review.spec.mjs` passed on September 18:
3,453 rows, 20 columns, every value matched the independent review-query result,
and duplicates were preserved. This verifies the existing demo result, not the
client's newly uploaded files. Export remains bounded by the saved query row limit
(100,000); “All Data” does not mean an unlimited database export.

The record review combines Current and Historical, retains identifiers and
excluded rows with reasons, and selects 20 fields. It is not all source columns
or the output of the hospital/month aggregate query. Its definitions are absent
from the main client dashboard ZIP and the three manual update ZIPs. Packaging
this supporting view for the client is still outstanding.

Sources:
- [Superset 6.1.0 dataset export implementation](https://github.com/apache/superset/blob/6.1.0/superset/datasets/api.py#L513)
- [Table chart raw-record mode](https://docs.preset.io/docs/table-chart)
- [Exporting chart data and row limits](https://docs.preset.io/docs/interacting-with-dashboards)
