# CSiM dashboard: standard, development and custom Superset

Source review: September 11, 2026.

## Build definitions

| Comparison | Superset code | Dashboard content |
|---|---|---|
| Standard 6.1.0 | Official release, no CSiM patches | The familiar 21-chart dashboard, prepared datasets and standard chart/filter settings |
| Upstream development | Pinned Apache source, no CSiM patches | The same dashboard and records, using available upstream features |
| CSiM custom | An explicitly identified base plus listed CSiM patches | The same dashboard, showing the additional behavior each patch supplies |

“Standard” permits a PostgreSQL driver, documented configuration, SQL datasets and saved chart settings. It does not permit patched frontend assets or an unmerged source change. External import automation is a separate dependency and must be disclosed even when Superset itself is unmodified.

The public [comparison and matching logins](https://design.csim.uwdigi.org/comparison.html) link two full September dashboards: [custom month controls](https://dashboard.csim.uwdigi.org/superset/dashboard/csim-individual-reconciled-months/) and [official native month selectors](https://standard.csim.uwdigi.org/superset/dashboard/csim-individual-standard-month-selectors/). Both contain 21 charts and six datasets. The separate preview hostname remains a patched development comparison. The official stable server has unmodified Apache frontend assets; its PostgreSQL driver, configuration and external import helper are disclosed separately.

## Current decision

Whole-month From/Through selection **does not itself require custom Superset code**. The official option uses two native Select filters and prepared SQL to apply inclusive month boundaries before grouping. Its public known-record workflow verifies February–March grouped as Quarter produces 10 submissions, excluding January.

The custom option remains the candidate for the exact client presentation: `Jan 2025`, `Q1 2025`, `2025`; the familiar vertical controls; rolling default months; validation of reversed dates; and partial-period guidance. The tested official alternative uses `2025-01 (Jan)`, `2025 Q1`, `2025`, horizontal controls and fixed saved default months. These are observable differences, not a conclusion that every possible native configuration has been exhausted.

Recommend the custom option for those exact requirements only after its remaining acceptance checks pass. Accepting the official option requires an explicit decision on the label and interaction differences. Native concurrent-run chart waits remain unresolved; isolated passing reruns do not prove a repair. [Release acceptance](../RELEASE-ACCEPTANCE.md) is authoritative for current validation and deployment, while the source findings below explain each feature.

The official released version is **6.1.0**, not 6.10. The [release page](https://github.com/apache/superset/releases/tag/6.1.0) identifies source c83fb2bb1dcfac41ac51bcebd82471f4a7180d18. The existing development pin is e22ce197866ded732e4990063ae74697d89d383a.

## Findings by issue

### Date wording, spacing and hover details

**Public solutions.** Release 6.1.0 already includes adaptive-date handling, rotated-label fixes and duplicate-label suppression: [#38017](https://github.com/apache/superset/pull/38017), [#37755](https://github.com/apache/superset/pull/37755) and [#38733](https://github.com/apache/superset/pull/38733). These appear in its [changelog](https://github.com/apache/superset/blob/6.1.0/CHANGELOG/6.1.0.md).

Development adds [grain-aware tooltips, #41350](https://github.com/apache/superset/pull/41350), and [label-spacing changes, #43669](https://github.com/apache/superset/pull/43669). Native development tooltips can show Jan 2025, 2025 Q1 and 2025 when their explicit format is unset.

**Important distinction.** The native axis and tooltip do not use the same formatting path. In both inspected source revisions, the axis uses getSmartDateFormatter, which normalizes quarter dates and delegates to the smart-date formatter. Development tooltips instead use the granularity format map. Finding quarter formats in that map is not proof that the axis uses them.

**Recommendation.** First test native adaptive formatting, rotation, margins, categorical/temporal axis settings and supported label intervals on all eleven charts. Judge correct period meaning and readability separately from the order of the year and quarter. Present native “2025 Q1” as a formatting alternative for owner review before justifying custom code solely to obtain “Q1 2025”; do not silently change the agreed label requirement.

Fixed monthly/quarterly/annual chart views are another standard-settings option. They add maintenance work and require a deliberate user workflow. A text-label approach must still prove chronological order across multiple series and preserve calendar gaps.

**Custom necessity:** distinguish the formatter from the spacing changes. The inspected native temporal-axis formatter has no quarter-label branch: it normalizes dates and selects calendar-based formats. It does not supply the agreed Jan 2025 / Q1 2025 / 2025 wording on a single switchable chart. The CSiM formatter addresses that concrete gap. Whether a supported alternative can meet the requirement without a source patch still needs the visual comparison above. Both the custom and native sortable candidates retain all 13 monthly labels across the eleven date axes at the three review widths. Custom public screenshots have been inspected, and native local screenshots have been inspected. Linux reproduction identifies a remaining custom spacing failure: some gaps are 7.82 pixels against the unchanged 8-pixel criterion. A scoped spacing correction is under validation. Completeness and spacing are separate checks; development's native tooltip improvement is also distinct from its axis.

### Time Period and grouping

The supplied query correction uses documented virtual-dataset templating to filter observations before grouping them. [Superset’s 6.1.0 SQL-templating documentation](https://superset.apache.org/admin-docs/6.1.0/configuration/sql-templating/) describes the supported feature. Enabling template processing is administration, not a fork of Superset.

**Recommendation.** Share the same prepared datasets across all three builds. Demonstrate February–March grouped as Quarter with January excluded. Preserve the different documented coverage of summary cards and latest-submission tables.

**Custom necessity:** no Superset source modification is inherently required for this query behavior. The result still needs to be checked on each build.

### Missing periods and valid zero

Calendar rows and joins belong in the data query. This can be maintained in a virtual dataset or database view while retaining normal Superset charting. Filling every missing metric with zero would change the meaning.

**Recommendation.** Use the same missing-month, zero-value and unavailable-denominator examples in all builds.

**Custom necessity:** no Superset source patch required.

### Clear, reselect and Apply

A public [6.1.0 report](https://github.com/apache/superset/discussions/43165) describes filters becoming unresponsive after clearing. Its automated reply is only a lead; the relevant changes were checked directly:

- [#39778](https://github.com/apache/superset/pull/39778): cleared selections are staged until Apply.
- [#40470](https://github.com/apache/superset/pull/40470): required/default filter state and disabled Apply behavior.
- [#42111](https://github.com/apache/superset/pull/42111): explicit empty values for defaulted selects and range filters.

These changes are present in later upstream development, not the inspected 6.1.0 source.

**Important distinction.** The CSiM patch forwards reset signals into the vertical sidebar. The inspected upstream vertical component does not forward those signals; the horizontal component does. The public fixes above address related paths, not proof that the exact vertical same-hospital reselection case is resolved. Horizontal orientation is a configuration candidate, but 6.1.0 has separate default-reset behavior to check there.

**Recommendation.** Run vertical and horizontal variants unmodified. Include required/default filters, clear-one versus Clear all, reselecting the same hospital, Apply state and resulting query values. Keep the familiar vertical workflow as the principal comparison; show horizontal orientation as an explicit alternative.

**Existing regression evidence.** In the recorded main-build test before the reset repair, clearing and reselecting the same hospital returned extra hospital/cohort series. Expected monthly submission values were 4, 8, 12, missing, 10 and 5 for the selected hospital; additional series appeared in the response. The same workflow passed after the repair. The test also checks that the page was not reloaded. The [repair and strengthened regression](https://github.com/DIGI-UW/csim/commit/34d426f5534ccdbe4c531a65239280040423bbfd) isolate this change from the existing formatter. Local run records are `output/clear-proof-corrected.log` and `output/clear-fixed-corrected.log`; these are recorded runs, not a new unmodified-build comparison.

**Custom necessity:** a repair is justified for the demonstrated vertical-sidebar workflow on the main build. Calling that necessity wholly unresolved would discard the before/after evidence. The official horizontal configuration passes isolated same-page recovery with the full September content. It is a demonstrated alternative to the patched vertical sidebar, with a different layout. Concurrent public runs still sometimes leave chart requests without an observed result; their cause is open. A related upstream change or an isolated rerun alone does not close that reliability question.

### Independent Time Unit menus

The supported upstream work is [#38922](https://github.com/apache/superset/pull/38922), native-filter pre-filtering, plus [#40000](https://github.com/apache/superset/pull/40000), support for display controls. Their implementation is in the pinned development source and absent from the inspected release source. A merge date before the release announcement is not proof of inclusion in that release.

The separate [dashboard-wide proposal #42849](https://github.com/apache/superset/pull/42849) is still open and is not the feature used for the independently configured menus.

**Recommendation.** Standard 6.1.0 can retain the documented installation-wide Month/Quarter/Year restriction. Unmodified development should demonstrate CSiM and hourly dashboards with independently saved lists.

**Custom necessity:** no CSiM patch is needed for the upstream development feature. Backporting it into 6.1.0 would create a custom build and must be labelled accordingly.

### Dashboard transfer and later updates

[Issue #26338](https://github.com/apache/superset/issues/26338) describes filter-scope references surviving import with old chart identifiers. Merged fixes [#40140](https://github.com/apache/superset/pull/40140) and [#38171](https://github.com/apache/superset/pull/38171) remap native and cross-filter references. They are later than the 6.1.0 source and are in the development code.

CSiM currently uses complete-assets import plus a separate reference-repair helper on main. That helper is external deployment code; it must not be counted as a native importer success.

**Recommendation.** Test native import and helper-assisted import separately. Use a destination with different chart IDs and a subsequent update to existing definitions. Compare SQL, calculated columns, chart settings, bindings, scopes and layout.

**Custom necessity:** upstream already addresses the principal reference defect. Standard-release operation may need the disclosed deployment workaround; a future official release containing the fixes is preferable to maintaining a source fork for this alone.

### Contents links, hospital guidance, percentages and freshness

Same-page section links, chart formatting, default selections and filter scope are standard settings. Calendar/data-selection rules can be supported datasets. None inherently requires custom Superset code.

An automatic successful-upload timestamp needs a record of successful data loading. That is a data-loading capability, not a chart-rendering extension. Current reporting-month cards cannot substitute for it.

The hospital-total guard and cohort-first empty-state guidance remain dashboard work to apply consistently across all builds.

### Inclusive From month / Through month controls

The full custom dashboard provides dedicated month fields, validates that From is not after Through, explains partial quarters/years, and computes rolling defaults. Those controls are CSiM application code.

The full official dashboard now demonstrates **native From month and Through month dropdowns** with a separate Time Unit. Its two calculated columns supply month choices; supported virtual-dataset SQL consumes those selections and converts the inclusive ending month to an exclusive first day of the following month. Filtering occurs before grouping. Clearing either endpoint removes that date bound. The saved opening window is explicit; it does not automatically advance each month.

The public native workflow checks missing periods, valid zero and February–March grouped into Q1 using known records. Its reviewed video is on the [current evidence page](https://design.csim.uwdigi.org/evidence/current/). Friendly handling of a reversed native range remains unverified. The older native Custom/Advanced date editor is retained as a separate comparison, not the only official option.

**Custom necessity:** no application patch is needed merely to offer inclusive whole-month choices. The custom controls add validated date ordering, rolling defaults and partial-period guidance in the vertical layout. Those specific benefits, along with the exact date wording, are the remaining build-selection tradeoffs.

## Upstream direction

The public [release discussion](https://github.com/apache/superset/discussions/43715) points toward 7.0.0, but it is not a delivery commitment. The official release page still lists 6.1.0. A merged fix, a development image and an official release are different availability states.

Prefer standard settings and dataset preparation; then an official release containing the required fix; then a pinned upstream build for comparison. A backport still counts as custom. Keep a CSiM-specific patch only when a stated acceptance case fails through the supported alternatives and the custom build demonstrates the missing behavior.

## Showcase acceptance

1. Keep the same 21-chart presentation, measure definitions, input records and explicit date windows across builds. Record necessary chart-setting differences.
2. Give each build its own unmistakable label, dashboard link and matching login.
3. Remove csim_period and custom month-control settings from unmodified-build packages. Merely running patched definitions on a stock server is not a fair standard-feature demonstration.
4. Show each issue in the three builds with matching screenshot crops and query checks. Identify working behavior, a configuration alternative, or a remaining gap.
5. Include all eleven date axes, Month/Quarter/Year, 12–13 monthly labels at supported widths, missing/zero cases, partial quarters, both filter orders, clear/reselect, same-page navigation and fresh defaults.
6. Keep native import evidence separate from helper-assisted deployment evidence.
7. An unmodified build must serve unmodified upstream frontend assets. Use isolated metadata stores and explicit image/source pins.
8. Existing custom-build screenshots cannot stand in for standard or unmodified-development acceptance.

This review combines source findings with the two published stable options. The complete cross-build acceptance suite, public concurrency diagnosis and client editor handover rehearsal remain open; the comparison is not production signoff.
