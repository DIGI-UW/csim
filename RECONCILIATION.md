# September version with familiar controls

The September version combines Beth’s test dashboard presentation with the existing date and filter corrections. It is a separate dashboard: its 21 charts and six datasets have independent persistent identifiers. The established 20-chart main dashboard remains available for direct comparison.

| Version | Address | Scope |
|---|---|---|
| September version | https://dashboard.csim.uwdigi.org/superset/dashboard/csim-individual-reconciled/ | Beth’s presentation and latest-data card, with date/filter corrections |
| Established version | https://dashboard.csim.uwdigi.org/superset/dashboard/csim-individual-corrected/ | Existing 20-chart April-based corrected dashboard |
| September known records | https://dashboard.csim.uwdigi.org/superset/dashboard/csim-reconciled-examples/ | Same 21-chart version, with deliberate numerical edge cases |

All three use the main installation’s login. Snapshot dashboards are unchanged.

## Source and disposition

The source is dashboard 13 from `34.223.100.228:8088`, exported September 11, 2026. Its archive, checksum and unpacked definitions are in `sources/exports/test-current-20260911`. Its 21 chart definitions, six dataset definitions, layout and text exactly match the supplied September test export. The live copy additionally requires a selection for collection location and Your hospital. The six dataset SQL definitions still match April exactly.

| Test dashboard feature | September version |
|---|---|
| Latest-data card | Included. Displays the latest month with actual submissions for the selected hospital/state and collection location. Time Period, Time Unit and lower comparison selectors do not affect it. Empty calendar rows cannot advance it. |
| Introduction, logo, nine section headings | Included. |
| Formula explanations, goal callout, lower-filter reminders | Included. Original measure expressions are preserved. |
| Taller first pair of charts and revised layout | Included. One negative reminder height is normalized to a usable height. |
| Whole-percentage presentation on eight charts | Included; no measure definition or weighting change. |
| Hospital versus named-group menus | Included with PostgreSQL-compatible conditions, including state names with spaces. The six stacked comparison charts use the same classification instead of fixed state-code lists; the known-record test demonstrates that a named state produces results. |
| Section navigation | Same-page anchors replace links to another server’s saved filter state. |
| Fixed Month Year format, vertical labels, mixed grain defaults | Replaced by the established dynamic formatter, horizontal labels and Month fallback. |
| Experimental time_aggregate column | Not needed: the corrected datasets retain real dates for filtering and sorting. |
| Frozen September 9 reporting window | Not copied. Saved defaults remain Last year and Month, with hospital 53 for a populated opening view. Known-record copies open at hospital 91. |

The inherited manual-import date describes the source’s documented upload. The latest-data card describes reporting observations; it is not a deployment timestamp.

## Reproduction and validation

After the existing main instance and both demo databases are initialized:

```sh
ruby scripts/prepare_dashboard.rb
ruby scripts/test_reconciliation.rb
bash csim.sh corrected reconciled
cd e2e
CSIM_DASHBOARD_SLUG=csim-individual-reconciled npm test
CSIM_DATA_PROFILE=edge-cases CSIM_DASHBOARD_SLUG=csim-reconciled-examples npm test
```

`reconciled` imports definitions and grants the existing viewer access. It does not start containers or restore reporting data. Its verification compares existing dashboard layouts, metadata, charts, dataset SQL, calculated columns and metrics before and after import. Both new packages are checked against their 21-chart/six-dataset manifests.

The browser suite checks all opening panels, all eleven date axes at three widths, Month/Quarter/Year labels and hover values, both filter orders, clear/reselect recovery, missing versus zero, partial quarters and multiple series. The September-specific workflow checks the latest-data card, section navigation and lower comparison selections. Screenshots, numerical assertions and Beth’s review remain separate evidence.

For an assets-only public deployment from a merged revision:

```sh
bash deploy/reconcile.sh FULL_GIT_REVISION
```

This preserves the runtime image and existing dashboard, backs up Superset metadata, and records the new assets revision separately. It neither rebuilds the snapshot nor reseeds either database. A full `deploy/server.sh update` also installs the September versions.

## Beth’s review

1. Open the September version and confirm the introduction, headings, explanations and latest-data card match the intended dashboard.
2. Compare the established version using the same explicit dates, hospital and location.
3. Switch Month → Quarter → Year. Check labels and hover details, including the lower comparison charts.
4. Change and clear the date filters; reselect without reloading. Jump to another section and check that selections remain.
5. Choose Your hospital and Cohort/State independently. Confirm that the latest-data card continues to describe available observations.

The historical authoring reports about a dataset changing or a calculated column disappearing remain unconfirmed causes. This reconciliation does not imply those intermittent problems were diagnosed or fixed.
