# Execution status

The acceptance contract is in PLAN.md. This file records implementation and verification; it is not a public problem explanation.

- Source inputs preserved, hashed and compared: April 20 charts/6 datasets, September test 21/6, September production 20/6.
- Private DIGI-UW/csim initialized; implementation branch codex/csim-dashboard-remediation.
- Supplied demo restored into isolated PostgreSQL 14.24. Unchanged baseline, corrected full dashboard, generated fixture, and upstream snapshot run locally.
- Main opt-in formatter patch uses the dashboard Time Unit override for axes and hover. Main unit suites: 62 passed. Actual five-axis Month/Quarter/Year workflow passed on both builds. The 6.1.0 renderer also needed an opt-in boundary-label correction for two-series charts; its browser test passed.
- Calendar join keeps missing periods; raw dates constrained before aggregation. Independent count/rate and same-page recovery tests passed on both builds.
- Main definition verification passed for all 20 charts and 6 datasets, exact SQL/calculated columns/metrics/layout/filter bindings. Native snapshot cached references pass with changed IDs; released build uses the deterministic helper.
- Changed-definition update and restore passed on both builds. CI runs the same standalone commands with both data profiles.
- New hostname configuration is not deployed. Old public dashboard/overview/evidence remain in place.
- New recordings, public deployment verification, final issue coverage and Beth acceptance checklist remain pending.

Source code attribution: harness tools/csim-superset at fa86f2d1a1c1883ee516887779111b3106d3dd4e, Piotr Mankowski, PR 111.
