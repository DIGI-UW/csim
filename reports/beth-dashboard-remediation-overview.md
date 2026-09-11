# CSiM dashboard: issues and solutions

CSiM users need to compare hospital and cohort results over a chosen date range. The charts should make the selected months, quarters or years easy to read, preserve gaps where data is missing, and keep selections consistent while users move through the dashboard.

This guide compares **standard Superset 6.1.0**, an **unmodified upstream development build**, and a **CSiM custom build**. Each issue explains standard settings, upstream improvements and any remaining need for custom code. The [public-solutions review](superset-options-review.md) records the sources and comparison requirements.

[Open the current custom dashboard](https://dashboard.csim.uwdigi.org/superset/dashboard/csim-individual-reconciled/) · [Logins](https://design.csim.uwdigi.org/#demo-access) · [Current custom-build evidence](https://design.csim.uwdigi.org/evidence/september/)

The comparison uses the familiar 21-chart dashboard with Beth’s September content. Both current public installations include CSiM patches; neither is an unmodified comparison. Separate standard and development demonstrations are still needed.

## 1. Date labels do not clearly identify the reporting period

*Example: after changing Month to Quarter, a point still reads “Jan 2025.” A reader cannot tell whether it represents January or the whole first quarter.*

**Why it happens.** A fixed Month–Year format stays the same when the grouping changes. Converting dates to text can improve the wording but introduce alphabetical ordering. Chart width creates a separate problem: labels may overlap or be omitted.

**Current solution.** The main dashboard keeps real dates for ordering and filtering. A custom display formatter changes the axis and hover labels with the selected grouping:

| Month | Quarter | Year |
|---|---|---|
| Jan 2025 | Q1 2025 | 2025 |

This applies to all eleven date charts. Narrow charts still omit some intermediate labels, so Beth’s request to show every month remains open. Vertical monthly labels with more space below the plot are the proposed adjustment.

**Standard and upstream alternatives.** Superset 6.1.0 already includes fixes for [adaptive dates](https://github.com/apache/superset/pull/38017), [rotated labels](https://github.com/apache/superset/pull/37755) and [duplicate labels](https://github.com/apache/superset/pull/38733). Development adds [grouping-aware hover labels](https://github.com/apache/superset/pull/41350), including 2025 Q1, and further spacing improvements. Axis labels need a separate visual check; a tooltip improvement does not establish an axis fix.

**Maintaining it in Superset.** Try native formatting, rotation and spacing first. Separate monthly, quarterly and annual views offer fixed formats, with more charts to maintain. Native development hover labels offer 2025 Q1; the axis needs a separate check. The current native date axis does not supply all three agreed formats on one switchable chart. The CSiM formatter supplies that behavior, but supported alternatives have not yet been ruled out. It requires a custom build and upgrade checks; importing the dashboard ZIP does not install it. Custom spacing has not been established as necessary.

[View label screenshots](https://design.csim.uwdigi.org/evidence/screenshots/#axis-spacing)

## 2. Date selection and grouping are easy to confuse

*Example: selecting February–March and grouping by Quarter should show Q1 using February and March only. It should not add January.*

**Why it happens.** Two controls refer to time but perform different jobs:

| Control | Meaning |
|---|---|
| Time Period | Which observations to include |
| Time Unit | Whether to group those observations by Month, Quarter or Year |

The familiar date editor also uses units to describe a look-back period. Those choices describe the window, not the chart’s grouping. Separately, a sidebar reset defect could leave a cleared control holding an old selection.

**Current solution.** The date window is applied before grouping the observations. A Superset code correction resets the sidebar controls so clearing and reselecting can work on the same page. Before this repair, a test returned additional hospitals' results after the same hospital was reselected; afterward, the selected hospital's expected results passed. This is a demonstrated filtering defect and repair. The supported workflows cover both selection orders.

The preview also offers inclusive **From month** and **To month** fields, with a separate grouping selector. February through March means those two whole months. These simpler controls are a customization available in the preview.

**Standard and upstream alternatives.** Filtering before grouping uses [supported dataset queries](https://superset.apache.org/admin-docs/6.1.0/configuration/sql-templating/) and needs no Superset patch. Development includes [default/Apply fixes](https://github.com/apache/superset/pull/40470) and [Clear all fixes](https://github.com/apache/superset/pull/42111) for related problems. Whether they or a different configuration can replace the demonstrated vertical-sidebar repair needs an unmodified comparison. The inclusive month fields are an optional CSiM interface enhancement; accurate date filtering does not require those new fields.

**Maintaining it in Superset.** Dashboard editors can set defaults and choose which charts each filter affects. Dataset changes are maintained separately from Superset code. To check a change, select an explicit date window, change the grouping, then clear and reselect without reloading.

The eleven date charts follow the window. Overall summaries, latest-submission tables and submission-total cards retain their separate coverage; they do not all change with Time Period. That distinction needs to appear beside those results.

[See date filtering](https://design.csim.uwdigi.org/evidence/#date-range) · [See clearing and reselecting](https://design.csim.uwdigi.org/evidence/#clear-filters)

## 3. Missing months disappear or look like zero

*Example: January and March have submissions, but February has none. Joining January straight to March hides the missing month; plotting February at zero suggests a measured zero.*

**Why it happens.** A chart built only from submitted records has no February row to display. Formatting the date cannot supply that row.

**Current solution.** A calendar supplies the reporting periods, including those without observations. Missing observations remain gaps; valid zero values remain plotted values. A rate without a usable denominator remains unavailable.

**Maintaining it in Superset.** This is data preparation in the saved dataset query, available to all three builds without a Superset patch. Dashboard editors can use the prepared dataset through the interface. When replacing or editing that dataset, preserve the calendar logic and avoid settings that replace missing values with zero.

[See missing data and zero](https://design.csim.uwdigi.org/evidence/#missing-periods)

## 4. Hospital selection and empty panels are unclear

*Example: a user selects Cohort and sees a blank hospital-only panel. It is unclear whether they need to choose a hospital or whether the chart has failed.*

**Why it happens.** The dashboard has different populations and filter scopes: an overall hospital/cohort selection and separate lower hospital and cohort/state comparisons. Some panels require an individual hospital; others summarize a group.

**Current solution.** The lower menus separate hospital numbers from named cohorts and states, and the six date comparison charts follow the same classification. The main dashboard currently opens with hospital 53 to populate its panels.

The intended cohort-first opening and a clear “Select your hospital” state are still needed. An empty hospital selection must not silently become a total across hospitals. That behavior needs a dedicated check for the hospital-total card.

**Maintaining it in Superset.** Set defaults and filter scopes deliberately. Place the selection instruction beside the affected panels. Keep three states distinct: a hospital has not been selected; the selection has no data; the chart encountered an error. Requiring a selection can help, but the hospital-only query must also behave correctly when a selection is absent.

## 5. Time Unit offers irrelevant choices

*Example: a monthly reporting dashboard offers seconds and minutes. Removing them also removes them from another dashboard that needs hourly reporting.*

**Why it happens.** The main Superset 6.1.0 installation restricts the list through a setting shared across the installation.

**Current solution.** Main offers Month, Quarter and Year everywhere. This is an installation-wide workaround: suitable for an installation dedicated to CSiM, restrictive when different reporting needs share it.

The development source includes independently saved choices: Month/Quarter/Year for CSiM and Hour/Day/Week for an hourly dashboard. This is upstream functionality from merged changes for [native filters](https://github.com/apache/superset/pull/38922) and [display controls](https://github.com/apache/superset/pull/40000). It needs no CSiM patch on development. Adding it to 6.1.0 would be a custom backport. The existing preview demonstrates it but also contains unrelated CSiM patches.

**Maintaining it in Superset.** On the main build, a dashboard editor cannot set an independent list through the interface; an administrator manages the shared setting. A build containing the per-control feature allows separate saved lists. Changing this menu alone does not correct date labels or filtering.

[Compare the two menus](https://design.csim.uwdigi.org/evidence/#dashboard-time-units)

## 6. Table of Contents links open the wrong dashboard or change filters

*Example: a contents link on production opens the test server, or restores an older hospital and date selection.*

**Why it happens.** A copied dashboard link can include the server address and a saved filter selection.

**Current solution.** The September dashboard uses links to sections of the page already open. Clicking a section keeps the current dashboard and selections. The older 20-chart comparison version still contains inherited links.

**Maintaining it in Superset.** Use a local section link beginning with # and the section’s identifier, rather than a full dashboard URL or saved-filter link. If sections are recreated, check their destinations. After an import, click every contents item with a hospital and date window selected: the server, dashboard and selections should stay the same.

This uses ordinary section links in all three builds; it does not require a custom chart renderer.

[See September navigation evidence](https://design.csim.uwdigi.org/evidence/september/)

## 7. Moving or updating a dashboard can leave inconsistent definitions

*Example: a dashboard imports and its charts appear, but a filter no longer controls the intended charts, or an existing dataset retains an older definition.*

**Why it happens.** A dashboard package includes charts, datasets, layout and filter relationships. Some references use identifiers that change between installations. An import can also retain existing shared objects rather than replace every definition.

**Current solution.** The CSiM deployment updates the definitions together. For 6.1.0, a separate deployment helper repairs references left unchanged by the importer. Development includes upstream repairs for [native-filter references](https://github.com/apache/superset/pull/40140) and [global/cross-filter references](https://github.com/apache/superset/pull/38171).

The helper is external deployment automation, not a native import fix. It can assist an unmodified server but must be identified separately in the demonstration. Versioned files preserve the intended configuration and allow it to be compared with the destination.

**Maintaining it in Superset.** Keep dated exports and short change notes. Import first into a test destination and verify dataset definitions, chart settings and filter scopes before replacing the user-facing version.

Renaming a dashboard does not create independent copies of its shared charts and datasets. A separate test installation provides stronger isolation. If an import leaves incorrect references, an administrator may still be needed; successful upload of a ZIP is not enough to establish that all relationships are correct.

Reports of a dataset changing or a calculated column disappearing during editing have no confirmed cause. Before-and-after exports help identify such changes if they recur.

[See transfer checks](https://design.csim.uwdigi.org/evidence/#native-import)

## 8. “Latest data” can mean two different dates

*Example: a file uploaded in September contains observations through March. “Latest reporting month” is March; “last upload” is September.*

**Why it happens.** Observation dates describe the records. They do not record when a file was successfully loaded.

**Current solution.** The latest-data card shows the most recent reporting month with submissions for the selected population and location. It is independent of the viewing window. An automatic “Last successful upload” timestamp is not implemented.

**Maintaining it in Superset.** Label reporting coverage and upload time separately. An editor can maintain an upload note manually. An automatic timestamp requires the data-loading process to record successful uploads.

For each data file, establish whether it replaces the complete dataset or contains only new records. Appending a complete extract duplicates records; replacing the table with an incremental file removes history.

[View the latest-data card](https://design.csim.uwdigi.org/evidence/september/)

## 9. Percentage formatting is inconsistent

*Example: an axis shows 40%, while a comparison table shows 40.0%.*

**Why it happens.** Number formatting is configured separately for each chart and table.

**Current solution.** Eight percentage charts use whole-percentage presentation. A comparison table still uses decimal percentages.

**Maintaining it in Superset.** Set the display format on each affected visual. This is an ordinary chart-setting change; calculations should retain their precision.

## A short routine for dashboard updates

1. Edit a test version, with shared charts and datasets accounted for.
2. Check Month, Quarter and Year with the same explicit dates and hospital.
3. Clear and reselect filters; check a missing month, a zero and a hospital-only panel.
4. Follow every contents link and confirm selections remain.
5. Export the complete dashboard and keep a dated copy.
6. Repeat those checks after import at the destination, including filter scopes and dataset definitions.

The interface can manage presentation, defaults and scopes. Prepared datasets can use standard Superset features. Keep custom Superset code only for agreed requirements that supported alternatives cannot satisfy. The comparison must demonstrate the benefit of each retained patch.
