# CSiM client delivery

The client receives an update to its familiar Individual Data dashboard on
official Superset 6.1.0. Beth's accepted wording, layout and chart edits belong
in that update, alongside the date, filtering and presentation corrections.
The separate examples and custom/development comparisons are not part of the
client installation.

**Current state — September 17:** Beth finished and shared her saved edits. Her
original ZIP and a fresh live backup are preserved, with identical object
definitions: 21 charts and six reporting datasets. See the [changes and Winter
handoff](reports/beth-final-export-and-winter-handoff-2026-09-17.md). The
[client-specific main-dashboard release](release/client-update/README.md) is now
assembled and has passed a baseline, update, and repeated-update rehearsal on an
isolated official Superset 6.1.0 instance. It has not been installed or accepted
on the client's instance. The ZIP published on the overview reproduces the demo
and is not the client upgrade package.

The supplied September production ZIP was also compared with the preserved
production export. Their archive hashes differ, but their dashboard, 20 chart,
six dataset, and database definitions are identical. It is a sound identity
baseline unless the client saved later definition edits. Take and compare a fresh
destination backup before installation.

Beth's latest requests: the saved Yao palette and six reporting dataset names
match their sources. The demo now also registers the three physical upload
sources under their production names. The client package includes a separate
record-review table and Data & records dashboard, which are live on the
official review instance with numerical and viewer checks; see the [request
checklist](reports/beth-three-requests-2026-09-16.md). A separate aggregate
download table is deferred until after the meeting.

## Preserve and reconcile Beth's edits

1. Use Beth's [September 17 export](sources/exports/beth-september-17-2026/README.md) as the source of her saved edits. Keep the **Latest Urine Culture Submission** card as reporting coverage, not an upload-date indicator, and retain the corrected section 4.1 explanation. Preserve this source unchanged; do not regenerate the older demo over it. For later reviews, save chart and dataset edits separately from the dashboard.
2. Export the dashboard, its charts and its datasets separately. Include the
   agreed record-review view and Data & records dashboard. Keep the original
   exports unchanged, alongside readable definitions. The separate aggregate
   download table is not part of this handoff until the post-meeting decision.
3. Compare the saved objects with the last deployed revision and the intended
   client objects. Match persistent identities rather than names or local
   numeric IDs. Separate deliberate edits, import-generated differences and
   defects; do not automatically choose either the live or repository version
   for every conflict.
4. Bring the accepted edits into the repository definitions and their
   generation inputs. Regenerating the package must preserve those edits.
   Review any changed measure, SQL query, filter scope or color assignment
   against the corresponding reporting requirement.
5. Build and test the client update in an isolated installation, then ask Beth
   to review that same version. Record technical checks and her acceptance
   separately.

During this review, the deployment hold prevents the updated review-deployment
command from importing assets or activating the official instance. It does not
stop Beth using Superset. An administrator can still bypass that command, so
direct imports and old deployment scripts must also be avoided.

## What the package contains

| Part | Contents |
| --- | --- |
| Dashboard | One accepted Individual Data dashboard, with Beth's saved edits, its Table of Contents, filters, layout and colors. |
| Charts | The charts used by that dashboard. Beth's final export has 21 charts; she removed the reporting-period summary. Final counts follow the agreed supporting views. |
| Reporting datasets | Updates to the existing six familiar reporting datasets, including saved SQL, calculated columns and measures. Preserve their client identities and connection. |
| Record verification and dependencies | One extra virtual dataset, one standalone record/CSV table and a separate Data & records dashboard with two summary charts. IDs, source, repeat instance and exclusion reasons remain visible. Keep this as a separately reviewed supporting package so it cannot change the familiar main dashboard during import. |
| Aggregate download table | A separate Table chart using the existing UTI Aggregate ALL DATA dataset. It would download the already-aggregated dataset rows, not original submission records. Defer this view until after the meeting. |
| Instructions | A short start page, an editor guide, administrator import/restore instructions, and a list of changes and known limitations. |
| Review evidence | The acceptance checklist, numerical examples, screenshots and dashboard workflow recordings from the accepted release. |

The tested main release is one complete Superset dashboard ZIP containing its
dashboard, charts, datasets and masked connection definition. Keep the readable
files, reference-repair helper and verification tooling in GitHub. A client
editor can use Superset and a shared release folder without running the
repository; an administrator uses the repository helper for the 6.1.0 import.

The client's three physical source datasets and eight archived datasets stay
in place. The update does not replace their database connection, restore a demo
database, add the example datasets, or import retired experimental charts.
With Beth's period-summary removal, the main dashboard uses the six reporting datasets and the client retains its three physical sources: nine active datasets, seventeen including the eight existing archives. The agreed record-verification view adds one active dataset: ten active, eighteen including archives. Confirm this against a fresh destination export. Beth's single-dashboard ZIP omits the standalone record-review view, the Data & records dashboard and the aggregate-download chart; package the first two explicitly and defer the last.

## Issues to close against the accepted version

| Issue | What is established | What the final review must establish |
| --- | --- | --- |
| Date range and grouping | The official review uses the left sidebar and native Custom start/end dates. The end is exclusive. Month/Quarter/Year groups the selected observations. | Beth's wording makes the boundary clear. Changing dates and grouping in either order gives the same results; partial quarters exclude observations outside the range. |
| Date labels and gaps | Official charts use year-first month/quarter labels and calendar rows. Existing evidence covers all eleven date axes. | Repeat screenshots after the edits: correct order, readable labels, visible missing periods and valid zeros. Exact `Jan 2025` / `Q1 2025` wording remains a separate customization comparison. |
| Seven-panel date coverage and 4.1 explanation | The review dashboard retains Beth’s September 17 version, with truthful all-dates/latest-month labels and matching filter scope. Section 4.1 describes the existing positive-urinalysis formula. Calculations are unchanged. | Confirm the same scope after transfer; see the [published evidence](https://design.csim.uwdigi.org/evidence/panel-coverage/). |
| Clear all and reselect | A stale selection was reproduced on the official build. | Keep this listed as a known limitation unless a native repair passes the same-page test. Reloading is a workaround, not successful recovery. |
| Time Unit menu | The official installation uses an instance-wide Month/Quarter/Year restriction. | Include the administrator configuration requirement. Per-dashboard saved unit menus are a separate upstream comparison, not part of the official package. |
| Yao's palette | The original assignments and hospital/comparison legend mappings are saved in the dashboard. Rendered-color checks passed before this editing round. | Check Beth's final legends, hospital choices and categories against the same palette. New legend names need corresponding assignments. |
| Hospital 53 totals | The full observed monthly range sums to 980. The saved shorter range sums to 269; the all-time card remains 980. | Preserve the different scopes and make them understandable. The latest team notes mark the count concern resolved; the older 500 note is not an outstanding requirement. |
| Latest Urine Culture Submission | It shows the latest observation month within the chosen range, not when a file was uploaded. The title already distinguishes this reporting-coverage meaning from upload status. | Keep the title and filter scope clear. An upload-completion timestamp is a separate feature. |
| Contents links | Current links stay within the dashboard and retain selections. | Recheck all nine links after layout edits and after transfer to the destination. |
| Transfer and repeated updates | The client update preserves the production dashboard, database and six dataset identities. A clean 6.1.0 rehearsal imported the baseline, then the update twice without duplicates or connection changes. SQL, calculated columns, measures, chart settings, palette metadata, layout, filter defaults/scopes, cached scopes and nine Table of Contents links matched. | Take a fresh destination backup, confirm no later client edits, then run the same checks on the destination. The official 6.1.0 import still requires the versioned reference-repair helper. |
| Record verification | Both demo source tables contain `record_id`; Current also contains `redcap_repeat_instance`. ALL DATA rows summarize multiple source records. | The separate view preserves all uploaded records, IDs and eligibility reasons; the local CSV matches every source row, and 1,058 hospital-group checks pass locally and on the public demo. The public viewer export returns all 3,453 rows. Confirm the review workflow with Beth, test the client role and imported version, and retain existing cohort weighting. There is no automatic chart-point drill-through. |
| Uploads, downloads and hospital changes | Record review is included. The separate aggregate-download table is deferred until after the meeting. | With the client's intended role, replace Current using the established procedure and verify a new hospital's lookup, menu and colors. Decide separately whether the aggregate download is needed and, if so, test its refresh and complete CSV contents. |
| Historical/Current overlap and embedded access | The latest team notes mark the overlap question resolved; no transition schedule is required. WordPress identity/access has separate owners. | Do not add a transition rule. Embedded access remains outside this dashboard update. |

The final issue list should link each item to Beth's notes, the relevant team
documentation, its agreed disposition and evidence. Earlier reports describing
custom builds or horizontal month selectors explain earlier alternatives;
they do not define this delivery.

## Instructions the client should receive

**Start page:** open the dashboard; choose the population and dates; choose
Month, Quarter or Year; explain the separate lower comparison selectors and
all-time totals. Include one concrete date example: February 1 to April 1
includes February and March. Link the known Clear all limitation.

**Editor guide:** edit and save wording, layout, charts and filters; preserve
Yao's color mappings; check shared dataset dependencies before editing SQL;
export the complete accepted revision to a new shared folder. Keep the prior
release. Routine UI editing does not require a custom Superset build or Git.

**Administrator instructions:** verify official 6.1.0, PostgreSQL driver,
template-processing configuration, time-unit restriction, connection and
roles. Back up the current definitions and application metadata. Import the
client-specific datasets, then charts, then dashboard, following the tested
sequence. Check and, where necessary, repair references on the destination.
Do not supply demo connection settings or run a data restore as part of an
update. Restore all changed dependencies when rolling back.

**Release checklist:** reproduce the agreed date, filter, color, contents-link,
empty/populated-cohort and numerical examples; inspect actual chart screenshots;
import the release twice; then have a client editor edit, export and restore a
small change. Attach remaining limitations and the reviewer decision.

The client release rehearsal certifies repeat import of the main package in an
isolated official 6.1.0 instance. It does not establish installation or client
acceptance on the destination. The versioned administrator helper remains
required to repair numeric chart references and cached filter scopes after the
native importer; this delivery is therefore not a wholly UI-managed update.

## Current supporting files

- [Beth's final saved export](sources/exports/beth-september-17-2026/README.md)
- [Matching live backup](sources/live-review/2026-09-17T163028Z/README.md)
- [September 17 handoff and open decisions](reports/beth-final-export-and-winter-handoff-2026-09-17.md)
- [Production and demo dataset inventory](reports/client-dataset-inventory.md)
- [Hospital 53 numerical reconciliation](reports/hospital-53-date-reconciliation.md)
- [Editor guide](CLIENT-HANDOVER.md)
- [Existing UI export/restore test result](reports/editor-restore-verification.json)
- [Team documentation map](reports/confluence-source-map.md)
- [Earlier issue-by-issue source audit](reports/client-update-audit-2026-09-11.md)
- [Tested main-dashboard release and installation sequence](release/client-update/README.md)
- [Repeat-import rehearsal receipt](release/client-update/rehearsal.json)

For import behavior, consult the [official documentation](https://superset.apache.org/admin-docs/6.1.0/configuration/importing-exporting-datasources/)
alongside the [6.1.0 importer source](https://github.com/apache/superset/blob/c83fb2bb1dcfac41ac51bcebd82471f4a7180d18/superset/commands/dashboard/importers/v1/__init__.py) and the actual restore rehearsal. The
current documentation's overwrite description differs from the dependency
behavior observed in the pinned 6.1.0 build; the release instructions must
follow the tested behavior.
