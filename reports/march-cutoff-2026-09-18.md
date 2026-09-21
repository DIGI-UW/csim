# Reported March 2026 cutoff

Maria reports that hospital data stops at March 2026, including hospital 53,
although newer data has been uploaded. The exact affected URL and selected date
range have been requested. No client reporting rows have been read or modified.

## Confirmed from saved definitions

- All six client-package queries preserve the September 10 production Historical
  relation: `v1."UTI Individual Historical 2024-2025"`.
- April/test and our supplied demo use `v1."UTI Individual Historical"`.
- The original production query explicitly comments that the unqualified
  Historical schema did not align. Do not switch source names without checking
  the actual source columns and intended upload table.
- No hardcoded March 2026 cutoff or hospital-53-specific condition exists in the
  six client SQL definitions. The calendar uses selected date bounds or actual
  minimum/maximum reporting dates.
- The client's saved main date window is September 1, 2025 up to September 1,
  2026 (exclusive). This includes April–August; it does not include September
  2026 until the viewer extends the range.
- Current rows require `qi_asb_complete = 2`, hospital code, month and year.
  Records must also match Hospitals and States. These are existing source rules.

## Confirmed only in the supplied local demo

Read-only monthly counts show hospital 53 has 980 Historical records, latest
reporting month March 2026, and zero Current records. Its March endpoint is
therefore consistent with this demo source. This does not establish anything
about Maria's newly uploaded client data.

## Next checks on the affected instance

1. Identify the exact dashboard URL and active date window; extend the window to
   include a known newer reporting month, then force-refresh affected charts.
2. Compare the Historical table named in the saved aggregate query with the exact
   table targeted by the latest upload. If different, inspect schemas and dates
   before choosing the correction. This is a concrete possibility, not a proven
   cause of the report.
3. Compare monthly counts for hospital 53 in both actual source tables with the
   aggregate results. Separate Current complete/incomplete counts. Only summary
   counts and latest reporting dates are needed; no patient-level export.
4. If eligible newer source rows exist but the aggregate omits them, trace the
   lookup join and selected date bounds; if the aggregate includes them but the
   chart does not, inspect chart filters, saved filter state and cache.

Sources: `dashboard/client-update/manifest.json`, client aggregate YAML,
`sources/sql/production-september-2026/7be87e2d-0a35-4f60-97fd-a114550bb170.sql`,
`scripts/prepare_client_update.rb`. The public data guide now distinguishes the
two Historical source names in its pending source revision.
