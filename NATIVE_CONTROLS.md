# CSiM month controls on official Superset 6.1.0

The recommended dashboard uses the official application. It retains the 21
September reporting charts and six reporting datasets and adds one native table
chart with a separate dataset for the reporting-period summary (22 charts and
seven datasets in the complete package).

## Supported behavior

- **From month / Through month:** include both complete endpoint months.
- **Opening window:** `12 months ago` through `Last complete month`, resolved
  when queried. Choosing explicit months creates a fixed window. The worked
  examples keep their fixed November 2025–April 2026 defaults.
- **Time Unit:** Month, Quarter or Year groups only the selected observations.
  February–March does not pull January into Q1. The summary explains this.
- **Reversed dates:** the Through menu omits months before From. Superset may
  retain a previously selected Through value when From changes. After Apply,
  the summary says which ending month to choose. Correcting it restores the
  charts on the same page. This is guidance, not a disabled Apply button.
- **Clear/reselect:** native horizontal filters pass recovery checks. Keep this
  orientation; the tested native vertical sidebar has a separate reset defect.
- **Presentation:** year-first text labels preserve chronological ordering:
  `2025-01`, `2025 Q1`, `2025`. They differ from the requested `Jan 2025` and
  `Q1 2025` wording demonstrated by the custom alternative.

The Month/Quarter/Year list is configured for this dedicated CSiM installation.
Other installations have independent configuration. A menu saved per dashboard
within one installation remains a development-version capability.

## Maintenance through Superset

Dashboard editors can change the saved month defaults, filter scope and layout
through the interface. Dataset editors maintain the calendar, filtering and
relative-date expressions in the saved SQL. Template processing must be enabled
by the administrator. These are supported Superset facilities; no application
patch or custom chart plugin is installed.

The reporting summary is a normal Table chart. Keep it in scope for From month,
Through month and Time Unit, and exclude it from hospital/location filters. Its
column widths keep the complete correction message visible at 1024, 1280 and
1600 pixels. It reads selected controls only, not reporting observations.

Current-month boundaries come from Superset's relative time resolver, rounded to
the first day of the month. The resolved boundary is also included in the query
cache key. Thus a cached September window cannot be reused as October's rolling
window. The database server's clock does not independently choose the window.

Exports preserve these SQL and chart definitions. Restore dependencies as well
as the dashboard; the existing 6.1.0 import-reference repair helper still applies.
It runs outside Superset and is a deployment workaround, not an importer fix.

## Web-server capacity

The dedicated public CSiM instance uses four Gunicorn web workers. One worker
became saturated during concurrent dashboard requests while PostgreSQL queries
remained short; the public runs captured loading delays and cancelled requests.
Four workers passed the repeated date/filter checks. This uses Superset's normal
`SERVER_WORKER_AMOUNT` setting, with no image or application-source change.

`CSIM_WEB_WORKERS=4` is saved for new standard installations. On an existing
installation, `CSIM_SERVER=1 bash csim.sh standard workers 4` recreates only the
web application with the selected worker count, its existing image and volumes.
It does not restore data, bootstrap metadata or import dashboard definitions.
Keep the previous environment file and image identity when applying this change.

## Reproduce and verify

With the separate standard demo and example databases already initialized:

```sh
ruby scripts/prepare_native_months.rb
ruby scripts/test_native_months.rb
bash csim.sh standard native-months
docker exec csim-standard-superset-1 python /repro/scripts/test_native_month_queries.py
cd e2e
CSIM_PROFILE=standard CSIM_NATIVE_MONTHS=1 \
  CSIM_DASHBOARD_SLUG=csim-individual-standard-month-selectors \
  npx playwright test -c acceptance.config.mjs native-usability.spec.mjs filter-recovery.spec.mjs
CSIM_PROFILE=standard CSIM_NATIVE_MONTHS=1 CSIM_DATA_PROFILE=edge-cases \
  CSIM_DASHBOARD_SLUG=csim-standard-month-selectors-examples \
  npx playwright test -c acceptance.config.mjs native-usability.spec.mjs fixture.spec.mjs multiple-series.spec.mjs native-months-workflow.spec.mjs
```

The month-boundary tests exercise January rollover, leap years, future rolling
windows, December–January, a single month, no bounds, partial quarters/years and
reversed dates through Superset's template processor and PostgreSQL. Browser
checks assert the independent known totals and inspect actual rendered labels.
Normal tests disable video. `record_evidence.py official-months` produces only
the dashboard workflows, including correction of a reversed range.

Sources: [Superset SQL templating](https://superset.apache.org/docs/configuration/sql-templating/)
and [official 6.1.0 table configuration](https://github.com/apache/superset/blob/6.1.0/superset-frontend/plugins/plugin-chart-table/src/controlPanel.tsx).
