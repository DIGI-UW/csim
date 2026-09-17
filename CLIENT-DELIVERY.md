# CSiM client delivery

The client receives an update to its familiar Individual Data dashboard on
official Superset 6.1.0. Beth's accepted wording, layout and chart edits belong
in that update, alongside the date, filtering and presentation corrections.
The separate examples and custom/development comparisons are not part of the
client installation.

**Current state:** Beth is still editing the [official review dashboard](https://standard.csim.uwdigi.org/superset/dashboard/csim-individual-standard-month-selectors/).
A saved checkpoint exists; the final client release is not yet assembled or
accepted. The ZIP currently published on the overview reproduces the demo and
is not the client upgrade package.

Beth's latest requests: the saved Yao palette and six reporting dataset names
match their sources. The demo now also registers the three physical upload
sources under their production names. Record-level verification is still to be
built; see the [request checklist](reports/beth-three-requests-2026-09-16.md).

## Preserve and reconcile Beth's edits

1. Let Beth finish and save her chart, dataset and dashboard changes. Saving
   the dashboard alone does not save edits still open in a chart editor.
2. Export the dashboard, its charts and its datasets separately. Include the
   standalone aggregate-download chart if it is part of the accepted handoff.
   Keep the original exports unchanged, alongside readable definitions.
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
| Charts | The charts used by that dashboard. The current review has 21 reporting charts and one reporting-period summary. Final counts follow the accepted edits. |
| Reporting datasets | Updates to the existing six familiar reporting datasets, including saved SQL, calculated columns and measures. Preserve their client identities and connection. |
| Period summary | One additional helper dataset if the summary panel is retained. Explain its purpose in the editor guide. |
| Proposed record verification | A separate record-level dataset and saved table, linking contributing Current/Historical submissions to the summary they support. Preserve source, record ID and Current repeat instance. Test record-to-summary reconciliation before including it. |
| Optional administrator download | A separate Table chart using the existing UTI Aggregate ALL DATA dataset. Include only after checking refresh after upload, complete CSV contents and the intended user's access. |
| Instructions | A short start page, an editor guide, administrator import/restore instructions, and a list of changes and known limitations. |
| Review evidence | The acceptance checklist, numerical examples, screenshots and dashboard workflow recordings from the accepted release. |

Provide separate dataset, chart and dashboard ZIPs for the tested 6.1.0 import
sequence. Keep readable files and test tooling in GitHub. A client editor can
use Superset and a shared release folder without running the repository.

The client's three physical source datasets and eight archived datasets stay
in place. The update does not replace their database connection, restore a demo
database, add the example datasets, or import retired experimental charts.
With the current summary panel, the expected client list is ten active
datasets: six reporting, three physical sources and one helper; eighteen with
the eight existing archives. Confirm this against a fresh destination export
before applying the update. A separate record-verification dataset would add one
active entry; it is not yet implemented.

## Issues to close against the accepted version

| Issue | What is established | What the final review must establish |
| --- | --- | --- |
| Date range and grouping | The official review uses the left sidebar and native Custom start/end dates. The end is exclusive. Month/Quarter/Year groups the selected observations. | Beth's wording makes the boundary clear. Changing dates and grouping in either order gives the same results; partial quarters exclude observations outside the range. |
| Date labels and gaps | Official charts use year-first month/quarter labels and calendar rows. Existing evidence covers all eleven date axes. | Repeat screenshots after the edits: correct order, readable labels, visible missing periods and valid zeros. Exact `Jan 2025` / `Q1 2025` wording remains a separate customization comparison. |
| Clear all and reselect | A stale selection was reproduced on the official build. | Keep this listed as a known limitation unless a native repair passes the same-page test. Reloading is a workaround, not successful recovery. |
| Time Unit menu | The official installation uses an instance-wide Month/Quarter/Year restriction. | Include the administrator configuration requirement. Per-dashboard saved unit menus are a separate upstream comparison, not part of the official package. |
| Yao's palette | The original assignments and hospital/comparison legend mappings are saved in the dashboard. Rendered-color checks passed before this editing round. | Check Beth's final legends, hospital choices and categories against the same palette. New legend names need corresponding assignments. |
| Hospital 53 totals | The full observed monthly range sums to 980. The saved shorter range sums to 269; the all-time card remains 980. | Preserve the different scopes and make them understandable. The earlier request for 500 is a separate source question unless Beth withdraws it or supplies its derivation. |
| Latest reporting month | It shows the latest observation month within the chosen range, not when a file was uploaded. | Keep the wording and filter scope clear. An upload-completion timestamp is a separate feature. |
| Contents links | Current links stay within the dashboard and retain selections. | Recheck all nine links after layout edits and after transfer to the destination. |
| Transfer and repeated updates | The demo package uses different dataset identities from the client and demo connection settings. | Build an update for the client's existing identities. Import twice without duplicates, unchanged target connection/data, and verify SQL, measures, bindings, layout and every filter scope. |
| Record verification | Both demo source tables contain `record_id`; Current also contains `redcap_repeat_instance`. ALL DATA rows summarize multiple source records. | Provide contributing records with source and identifiers, exact population/date/location rules, and measure inclusion. Reconcile counts and rates without changing the summary grouping or cohort weighting. Validate any chart-to-record link in official 6.1.0. |
| Uploads, downloads and hospital changes | The saved download chart exists. Full operational acceptance is still separate. | With the client's intended role, replace Current using the established procedure, refresh, verify the complete processed CSV, and verify a new hospital's lookup, menu and colors. |
| Hospital transition rules and embedded access | Hospital-specific transition dates need the approved schedule; WordPress identity/access has separate owners. | Assign these explicitly in the issue list. Do not imply that the dashboard package implements unprovided transition rules or embedded access restrictions. |

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

The existing editor rehearsal supports separate imports for 6.1.0. It does not
yet certify this final client package or cross-instance filter repair. Any
administrator helper still required after rehearsal must be included and
explained; successful import must not be described as wholly UI-managed if a
helper is necessary.

## Current supporting files

- [Saved review checkpoint](sources/live-review/2026-09-16T214843Z/README.md)
- [Production and demo dataset inventory](reports/client-dataset-inventory.md)
- [Hospital 53 numerical reconciliation](reports/hospital-53-date-reconciliation.md)
- [Editor guide](CLIENT-HANDOVER.md)
- [Existing UI export/restore test result](reports/editor-restore-verification.json)
- [Team documentation map](reports/confluence-source-map.md)
- [Earlier issue-by-issue source audit](reports/client-update-audit-2026-09-11.md)

For import behavior, consult the [official documentation](https://superset.apache.org/admin-docs/6.1.0/configuration/importing-exporting-datasources/)
alongside the [6.1.0 importer source](https://github.com/apache/superset/blob/c83fb2bb1dcfac41ac51bcebd82471f4a7180d18/superset/commands/dashboard/importers/v1/__init__.py) and the actual restore rehearsal. The
current documentation's overwrite description differs from the dependency
behavior observed in the pinned 6.1.0 build; the release instructions must
follow the tested behavior.
