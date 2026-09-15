# CSiM date controls on official Superset 6.1.0

The main official dashboard uses the left filter panel and Superset's built-in
Time Period editor. It opens in Custom with Specific Date/Time for both endpoints.
The existing URL and object identities are retained. The URL still contains
`standard-month-selectors` so shared links continue to work.

- Main saved range: September 1, 2025 to September 1, 2026.
- Known-record example: November 1, 2025 to May 1, 2026.
- Start is inclusive; end is exclusive. February–March means February 1 to April 1.
- Explicit defaults stay fixed. Saving a relative range changes the editor's opening view.
- Records have monthly precision. Queries represent each month by its first day.
- Time Unit groups the selected observations; it does not expand the date range.
- All 21 September reporting charts and six reporting datasets remain. The native
  reporting-period summary makes the full package 22 charts and seven datasets.
- Year-first labels remain `2025-01`, `2025 Q1`, `2025`.

The left sidebar retains the known native Clear all/reselect defect. Horizontal
controls passed recovery checks; the custom build repairs the sidebar. This
layout change does not claim to repair that defect or install application code.

## Maintain and reproduce

A dashboard editor can save a Custom default with two Specific Date/Time values
through the filter settings. Keep Time Period scopes and dataset definitions
when transferring the dashboard. Superset 6.1.0 still uses the separate import
reference repair helper. Dataset editors maintain the saved SQL; administrators
enable template processing. The official application image is unchanged.

```sh
ruby scripts/prepare_native_dates.rb
ruby scripts/test_native_dates.rb
bash csim.sh standard native-dates
cd e2e
CSIM_PROFILE=standard CSIM_NATIVE_DATES=1 \
  CSIM_DASHBOARD_SLUG=csim-individual-standard-month-selectors \
  npx playwright test -c acceptance.config.mjs native-dates.spec.mjs
```

The old month-selector generator and its tests remain available for the earlier
comparison. The complete package generator now finishes with the date-entry
configuration. Earlier horizontal-control recordings are historical evidence,
not acceptance evidence for the new sidebar layout.

The dedicated server keeps its four web workers and existing data. Normal asset
updates import definitions only; they do not reseed databases or rebuild Superset.

The dashboard also links to **Aggregate ALL DATA — Download**, a standalone raw-record Table chart. See [the download workflow](AGGREGATE_DOWNLOAD.md). It is packaged with the dashboard but is not one of the 22 panels and receives no dashboard filters.

## Current entry links and retired comparisons

Link directly to the dashboard, including beside the login details. Superset's
login page sends an already authenticated user to the site root instead of
honoring `next`; the standard host root must therefore point at the same current
dashboard. Direct dashboard links still request login when needed.

The four earlier official comparison dashboards can be removed with
`scripts/retire_standard_dashboards.py --apply` inside the standard container.
It first saves a native dashboard export and a metadata backup, then verifies
that the two current dashboards, all charts and all dataset definitions remain.
Reporting records are untouched. Run without `--apply` for the inventory.
Old comparison slugs redirect to the current main or known-record dashboard.
Their old saved-filter keys are discarded because they belong to retired controls.
Keep the old source packages for historical comparison; do not run the earlier
`candidates` import on the public instance unless intentionally restoring them.
