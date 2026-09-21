# Maintaining the CSiM dashboard in Superset

For the current package contents, ongoing editor review and remaining release checks, see [Client delivery](https://github.com/DIGI-UW/csim/blob/codex/csim-native-usability/CLIENT-DELIVERY.md). This guide describes maintenance; it is not acceptance of the final client update.

Dashboard editors can use Superset directly and keep release files in a shared Drive folder. They do not need a GitHub checkout for ordinary edits. The server administrator remains responsible for the installed Superset version, backups, database connections and the required instance configuration.

Export, editing and restoration have been exercised through the official Superset 6.1.0 interface using an Alpha editor and an independent 21-chart copy. The restored export matches the original dashboard, charts and dataset definitions. Client-account acceptance and transfer to the client installation remain separate checks.

## What the client can maintain

| Work | Where to do it | Responsibility |
| --- | --- | --- |
| Headings, explanations, logo and arrangement | Edit dashboard | Dashboard editor |
| Chart titles, number formats, measures and ordinary chart settings | Open the chart, edit and save | Dashboard editor with chart access |
| Filter labels, defaults and which charts they control | Dashboard filter configuration | Dashboard editor |
| Saved dataset SQL, calculated columns and metrics | Dataset editor / SQL Lab | A designated SQL-capable editor; changes can affect several charts |
| Reporting data and new-hospital lookup entries | Existing upload procedure and database connection | Data owner; verify processed results after each upload |
| Official Superset upgrades, PostgreSQL driver, SQL template processing and the instance-wide Time Unit list | Server configuration | Server administrator |
| WordPress identity and access rules | Embedding integration | Integration owner |

## Reporting data and dashboard definitions are separate

| Item | What it contains | How it is maintained |
| --- | --- | --- |
| Reporting database | Actual submitted records and reporting tables in PostgreSQL | The data owner manages uploads, access, backups and restoration separately. |
| Superset dataset definition | Saved SQL or a table reference, calculated columns, measures and connection reference | Export and version it with the charts that depend on it. It contains no reporting records. |
| Dashboard and chart definitions | Layout, wording, filters, bindings and chart settings | Export and version them as the dashboard release. |

A normal dashboard update or rollback changes definitions only. It must not restore, replace or reseed the reporting database. The saved SQL must remain compatible with the destination database's tables and columns. Initial environment setup and any later reporting-data restore are separate administrator operations.

A dashboard ZIP carries definitions, including its saved dataset queries. It does not carry the reporting database rows or install the custom application code. A Superset metadata backup also belongs to application recovery, separately from the PostgreSQL reporting-data backup. Saving a dashboard copy does not guarantee that its underlying charts and datasets are independent.

## A release folder instead of Git

Create a new folder for each accepted revision, for example `CSiM / Dashboard releases / 2026-09-15-r01`. Keep:

- The complete dashboard definition ZIP exported through Superset's Dashboards list.
- Separate dataset and chart exports for any changed shared objects, particularly for the tested 6.1.0 build.
- A short release note: author, date, dashboard URL, Superset version/build, changed items, test results and reviewer.
- Screenshots of the opening view, Month/Quarter/Year, hospital results and clear/reselect.
- The previous accepted release, retained unchanged.

Use a new folder and filename for each release. Downloaded chart CSV files and screenshots are useful evidence, but do not replace the dashboard definition export. A server backup is also separate from this folder.

## Edit and review

### Preserve Yao's colors

The April dashboard and the supplied September settings contain the same 109
explicit color assignments. Keep these when editing. Superset matches colors
to the complete legend text: `Ceftriaxone` and `53, Ceftriaxone` are different
names to the color system. The current main dashboard also assigns Yao's
category colors to the hospital/state comparison labels.

In the dashboard's **JSON metadata**, `label_colors`
stores these assignments. If adding a hospital code or renaming a category,
add the corresponding full legend names with the existing category colors.
Duration legends use the metric first, such as `>7 days, 53`; antibiotic and
location legends use the hospital first, such as `53, Ceftriaxone`. Export the
dashboard after saving. Check both hospital and cohort/state charts after
changing selections; changing dates or grouping should not change category
colors. Do not replace this mapping by choosing a generic palette.

The generator carries the mappings into the saved dashboard files. The browser
regression compares painted chart colors against the unchanged April source.
Preserving these assignments is separate from a complete accessibility or
black-and-white print review.

### Review a change

1. Open the designated test installation. Export the current dashboard before editing.
2. Make a small, named change. If changing a chart or dataset, check where else that object is used. Use a separate test installation for isolated trials; renaming a dashboard alone is insufficient isolation.
3. Save each changed chart or dataset, then save the dashboard. Keep Table of Contents links local to the same dashboard.
4. Review the 21-chart dashboard with the checklist below. Record a specific hospital and explicit dates so another editor can repeat it.
5. Export the reviewed definitions into the new release folder. Mark them accepted only after the reviewer has checked them.

## Move or restore a release

Import/export behavior depends on the actual Superset build. Do not treat a successful dashboard import as proof that all existing objects were updated.

| Build | Practical consequence |
| --- | --- |
| Tested Superset 6.1.0 base | Its dashboard importer passes `overwrite=False` for related databases, datasets and charts. An existing dashboard can therefore receive a new layout while related definitions stay old. Our deployment command uses the full assets importer to update dependencies, followed by a helper that repairs filter references. Through the interface, import the saved dataset definitions and charts separately before importing the dashboard. This sequence restores the edited SQL, chart title and dashboard title in the isolated editor test; its final export matches all 21 original charts and six dataset definitions. Check filter scopes and results again on a different destination. |
| Pinned development build | Includes upstream import repairs. Fresh imports and updates still require verification using this exact build and export, rather than assuming every development revision behaves alike. |

For an existing dashboard on the tested official 6.1.0 installation:

1. Retain an export of the current dashboard and any chart or dataset definition you will change.
2. In **Datasets**, import the saved dataset-definition ZIP and confirm overwrite for the intended objects.
3. In **Charts**, import the saved chart ZIP and confirm overwrite.
4. In **Dashboards**, import the saved dashboard ZIP and confirm overwrite.
5. Verify the definitions and repeat the dashboard review checklist. Export again to compare with the intended release.

These imports restore Superset definitions, not database records. In the editor test, importing only the dashboard restored its title but retained the newer chart title and SQL; the separate imports restored those too.

The receiving server must have the correct database connection, reporting data, compatible software and the required instance configuration. The official dashboard does not require CSiM application patches. An administrator should retain a metadata backup before promotion. Import the chosen release, then run the same review checklist on the destination. If restoring an earlier release, restore its dependent chart and dataset definitions too.

After client handover, the accepted test dashboard and exported release folder can become the client team's editing source. Repository deployment must not silently overwrite subsequent client edits. Before any later scripted update, export and reconcile those changes or agree that the target is still managed from the repository.

## Version history inside Superset

The inspected 6.1.0 source does not include the newer version-history interface. Use exports and administrator backups for that build.

The pinned development source contains **View version history** for dashboards and charts, with capture and the interface enabled by default. It offers saved revisions, preview and restore. This is an upstream development capability, not a CSiM patch or a confirmed stable-release feature.

A dashboard's history restores its own state. Related chart and dataset changes require separate attention, and historical preview can show current chart definitions. Treat version history as an editing aid, not a complete release backup. Runtime behavior and restore with the client role remain to be validated before recommending it for handover.

## Review checklist

Use the same hospital, location and dates before and after the change or import.

- Opening shows Cohort and clear instructions for hospital-only panels. The lower hospital total does not sum all hospitals when unset.
- Month, Quarter and Year show the intended grouping and date labels on all eleven date charts. Check narrow and wide screens.
- February through March grouped into Quarter excludes January. Missing periods remain gaps; a measured zero remains zero.
- Changing the dates and grouping in either order gives the same results. Test Clear all and reselect on the same page, without a reload. This remains a known failure on the official review build; keep it identified as a limitation until that exact workflow passes.
- All nine contents links stay on this dashboard and retain selections.
- Hospital and cohort/state menus contain the intended choices and control the intended charts.
- All reporting panels show results or specific selection guidance; the separate period summary reflects the chosen range. Number formatting changes do not change calculations.
- Dataset SQL, chart bindings, saved defaults, wording and layout match the accepted release.

Hospital 53's disputed 500-versus-980 total, hospital-specific transition dates, complete processed-data downloads and hospital onboarding each need their own agreed examples. Do not use these open questions as pass/fail expectations until the relevant source or rule is established.

## Handover acceptance

The handover is complete when a client editor can make a wording change, export a release, make a chart change, restore the previous accepted state and repeat the checks without a repository checkout. An administrator must also demonstrate the documented transfer/repair and backup recovery path. Keep this acceptance separate from the dashboard's rendering tests.

Sources: [Superset import/export documentation](https://superset.apache.org/admin-docs/6.1.0/configuration/importing-exporting-datasources/), [the exact 6.1.0 importer](https://github.com/apache/superset/blob/c83fb2bb1dcfac41ac51bcebd82471f4a7180d18/superset/commands/dashboard/importers/v1/__init__.py), [development version-history documentation](https://superset.apache.org/user-docs/using-superset/version-history/), and the versioned CSiM definitions and local import tests. Where current documentation differs from the inspected release implementation, the implementation and runtime test govern the handover claim.
