# CSiM dates and filter behavior

## Two different dates

| Display | Where its value comes from | What changes it |
| --- | --- | --- |
| Upload note: March 30, 2026 | Literal text in a dashboard Markdown panel | An editor changes and saves that text |
| Latest reporting month in selected period | Latest observation month with submissions, within the selected hospital/state, location and Time Period | Source observations and those filters |

Uploading July observations in September does not make their reporting month September. The reporting data supplies a month and year, not a precise observation day. The aggregate query represents that month as its first day. A date format cannot recover an upload day from it.

Current has a `qi_asb_timestamp` source field; Historical does not. Neither the aggregate query nor the latest-month card uses it. Its presence does not establish when a file was uploaded to Superset. No automatic successful-upload timestamp feeds this dashboard.

A manually maintained **Last data upload: [date]** label is an ordinary dashboard text edit. Automating it would require a reliable record of successful uploads. The existing March 30 note has not been verified as the date of this demo's most recent upload; it should not be relabelled as a newly confirmed fact.

## Six controls in the main dashboard

| Control | Saved opening selection | Purpose |
| --- | --- | --- |
| Hospital and state | Cohort | Upper population selector; can contain multiple hospitals/states/Cohort |
| Location of Urine Culture Collection | All locations | Collection setting; one choice |
| Time Period | Sep 1, 2025 to Sep 1, 2026 | Start included, end excluded; therefore Sep 2025 through Aug 2026 |
| Time Unit | Month | Month, Quarter or Year grouping |
| Your hospital | No selection | One hospital for the lower hospital panels and all-time hospital total |
| Cohort/State | Cohort | One comparison population for the lower paired charts |

## All 22 panels and their actual coverage

“Upper” below means **Hospital and state**. “Lower pair” means **Your hospital** for the left chart and **Cohort/State** for the right chart. “Selected period” means the Time Period selection is used by the query. “All time” means all eligible dates in the supplied source, not all uploaded rows regardless of eligibility.

| Section / panel | Hospital choice | Date coverage | Time Unit used? | Location filter used? |
| --- | --- | --- | --- | --- |
| Top: Reporting period | None | Displays the selected boundaries | Displays choice | No |
| Top: Latest reporting month | Upper | Latest month within selected period | No; always month | Yes |
| 1: Inappropriate UTI diagnosis trend | Upper | Selected period | Yes | Yes |
| 1: Overall inappropriate UTI diagnosis | Upper | **All time** | **No** | Yes |
| 1: Latest-month diagnosis comparison table | One upper hospital | **Latest available month**, independent of period | **No** | No; all locations |
| 2: Inappropriate UTI+ASPN diagnosis trend | Upper | Selected period | Yes | Yes |
| 2: Overall inappropriate UTI+ASPN diagnosis | Upper | **All time** | **No** | Yes |
| 3: Overall ASB prevalence | Upper | **All time** | **No** | Yes |
| 3: Overall ASB treatment rate | Upper | **All time** | **No** | Yes |
| 4.1: Positive UA trend | Upper | Selected period | Yes | Yes |
| 4.1: Overall positive UA proportion | Upper | **All time** | **No** | Yes |
| 4.2: Therapy duration trend | Upper | Selected period | Yes | Yes |
| 4.2: Latest-month therapy comparison table | One upper hospital | **Latest available month**, independent of period | **No** | No; all locations |
| 4.2: Duration-category pair — two charts | Lower pair | Selected period | Yes | Yes |
| 4.3: Antibiotic pair — two charts | Lower pair | Selected period | Yes | Yes |
| 4.4: Collection-location pair — two charts | Lower pair | Selected period | Yes | No; shows each location as a category |
| 5: UC submissions trend | Upper | Selected period | Yes | Yes |
| 5: Hospital total | Your hospital | All time | No | Yes |
| 5: Cohort total | Fixed full Cohort | All time | No | Yes |

There are five main trends, five overall charts, two latest-month tables, six paired comparison charts, two all-time totals, one latest-month card and one period-summary table. The manual upload note is text, not a 23rd data panel.

The standalone aggregate download and individual record-review table are separate from this main dashboard. The separate Data & records dashboard has source and hospital summaries; main dashboard filters do not control those pages.

## Inconsistencies and issues

| Item | What is established | Classification |
| --- | --- | --- |
| Date-filter indicators on seven panels | Five overall charts and two latest-month tables receive Time Period/Time Unit but their queries do not use them. | Confirmed misleading filter assignment/indicator; whether the underlying all-time/latest meaning should change is undecided. |
| Two hospital selectors | Upper selection does not update the lower selection. Within 4.2, the trend/table and paired charts use different selectors. | Existing behavior with insufficient guidance; not proof of broken filtering. |
| Section 5 comparisons | The trend is selected-period and upper-hospital; the hospital total is all-time and lower-hospital; the cohort total is fixed full Cohort. | Different reporting questions; easy to compare unlike results. The earlier hospital 53 count report is resolved. |
| Initial empty hospital panels | Cohort opens the main charts, while hospital-specific latest tables require one upper numeric hospital and lower hospital panels require Your hospital. | Selection-dependent empty states, not missing source records by themselves. |
| Location exceptions | Latest tables and 4.4 ignore Location; the former cover all locations and the latter display the location breakdown. | Explicit saved exceptions; not automatically defects. |
| Clear all | Official 6.1.0 has a separately reproduced stale-selection/reselect defect in the left sidebar. | Confirmed limitation, not explained or repaired by chart scope. |
| Specific-day date entry | Source reporting dates have month/year precision and are represented as the first of the month; the native end boundary is exclusive. | Usability/precision mismatch: mid-month selections can exclude a whole reporting month. No actual daily precision should be implied. |
| Upload date | Literal manually maintained text; latest reporting month is derived from observations. | Ambiguous wording; no automatic upload timestamp is established. |

The reporting-period summary describes the selected controls, not the coverage of every panel. It does not make the all-time or latest-available panels respect those dates.

### Evidence for the seven-panel date mismatch

The latest-month therapy table lists Time Period and Time Unit as applied filters, although its dataset exposes no temporal column and its query independently picks each hospital's latest month. With hospital 53 selected:

- Sep 2025 through Aug 2026: table shows Mar 2026, 7.7 hospital days, 8.1 cohort days, 7.7 state days.
- Jan through Dec 2024: the trend changes to 2024; the table still shows that same Mar 2026 row.
- The table's filter indicator nevertheless lists the 2024 date range as applied.

[Public browser screenshot](../design/evidence/beth-review/therapy-filter-mismatch.png).

The other latest-month table and all five overall charts were also checked through Superset’s live query endpoint. With hospital 53, changing from calendar 2024 / Month to Sep 2025–Aug 2026 / Year returned identical results on all seven panels. Their SQL has no date-range hooks and exposes no temporal column. The screenshot check covers the therapy table; this is not a fresh browser acceptance run of every panel. [Query evidence](filter-scope-query-evidence-2026-09-17.json).

**No behavior decision has been made.** The inventory distinguishes misleading filter indicators from the separate question of whether each all-time/latest panel should retain its existing meaning or follow the selected period. No filter assignments or calculation rules have changed.

## Separate from Clear all

Filter scope defines which chart receives a control. Clear all concerns whether prior selections are actually removed. This table mismatch happens on a fresh dashboard without Clear all. Fixing the table's scope will not repair Superset 6.1.0's separately reproduced stale-selection behavior in the left sidebar.

No new native Clear all fix is established by this audit. Upstream changes addressing horizontal controls or required-default behavior are not proof of a left-sidebar fix.

## Ordinary Superset features for editors

- **Add/Edit Filters → Scoping → specific panels** controls which charts receive each filter. Match the selection to the chart's question, then test the result.
- **Add filters and dividers → Divider** adds visible headings and descriptions. This provides hospital-selection guidance without application changes.
- Each chart's filter icon shows which controls Superset routes to it. Hovering a filter can highlight affected charts. For a SQL-defined dataset, also confirm that the query actually uses those controls; an indicator alone is insufficient evidence.
- A same-page Table of Contents link starts with `#` and names the destination heading. It should not contain a test-server URL or saved filter key.

Sources: [filter management](https://docs.preset.io/docs/managing-filters), [filter scoping](https://docs.preset.io/docs/scoping-a-filter), [Superset 6.1 SQL templating](https://superset.apache.org/admin-docs/6.1.0/configuration/sql-templating/), and the [team's upload/dashboard guide](https://docs.google.com/document/d/1ZJXriNttqVWN3w_vXwYR7HH6DcrqbcIb/edit). Preset documents the Superset-based interface; installed 6.1.0 behavior was checked separately.

## Published presentation changes

- The sidebar begins with SELECT YOUR HOSPITAL FIRST, followed by guidance for Hospital and state.
- HOSPITAL COMPARISONS introduces the two lower selectors.
- Section 4.2 explicitly distinguishes the upper-controlled trend/table from the lower-controlled paired charts.
- Table of Contents entries 4.1–4.4 are nested under section 4; all nine existing same-page destinations remain intact.

Published from revision `9661a7f1223e526a4c8b28effaa51e2cdf62e1c0` on September 16 Pacific (September 17 UTC). The [shareable catalogue](https://design.csim.uwdigi.org/filter-guide.html), overview and Beth review page are live. All eight website checks passed against the public site; desktop/mobile screenshots and the public dashboard guidance were inspected. The deployment comparison verified that all 22 panels, filter values, defaults, requiredness, scopes, colors, chart definitions and dataset SQL remain unchanged. The date note remains unchanged pending confirmation of its intended manual value. [Publication receipt](navigation-guide-publication-2026-09-17.json). This update does not establish new numerical acceptance or resolve the documented filter limitations.

## Current issue status

The [team issue document](https://docs.google.com/document/d/1yGa9_3Rxjp4sMTApiklo7Nu3eRHzX0ybGZjC8FIHKPw/edit), updated September 16 Pacific, marks hospital 53's count and Historical/Current overlap questions resolved. There is no remaining request for a transition schedule or an unexplained total of 500. Combining the two filter groups is marked out of scope. Beth could not save edits because of the connection, as confirmed by Piotr; no missing edits are assumed.
