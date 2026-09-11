# CSiM delivery: standard dashboard first

User direction, September 11, 2026: make the main target dashboard the best version available without custom Superset software. Demonstrate the other approaches as alternatives, with the overview describing what each running dashboard actually supports.

## Delivery priority

The unmodified comparison is now part of selecting the main dashboard, not a separate follow-up to promoting the patched release. Preserve useful work already implemented, but divide ordinary dashboard/data changes from Superset source changes.

Start with unmodified stable Superset 6.1.0 for the main candidate. Keep unmodified Superset development as an alternative because it is unreleased. Keep CSiM custom software as an explicit alternative whose extra behavior and maintenance requirements are demonstrated. Do not silently substitute development or a patched image for the standard release.

## What each demonstration contains

| Demonstration | Software boundary | Dashboard and evidence |
| --- | --- | --- |
| Main candidate: standard 6.1.0 | Official Superset application and frontend assets. Database drivers, supported configuration, saved queries and chart settings are allowed. No CSiM source patches. | Full September dashboard: 21 charts, six datasets, Beth's content and familiar controls. Use the best standard configuration, with any remaining limitations stated next to the relevant workflow. |
| Development alternative | A pinned Apache development revision with no CSiM patches. | The same September content and input data. Demonstrate independently saved Time Unit menus, improved transfers and date presentation only where verified. |
| Custom alternative | An identified base version and explicit list of CSiM source changes. | The same full September content. Show the extra behavior supplied by each retained change. Simpler month fields remain an optional interaction, not a prerequisite for correct date filtering. |

An external import-reference helper does not make Superset itself custom, but its use must be disclosed. A helper-assisted transfer does not count as a successful native import.

## Preserve shared improvements

Apply the calendar and pre-grouping date filters, hospital-selection guards, explanatory text, percentage settings, latest-reporting-month wording, and same-page contents links across the variants where supported. Preserve the original measure definitions and intentional filter scopes. Use the supplied demo records and the separate edge-case fixture consistently.

Keep custom label formatting, custom tick placement, the vertical-filter reset repair and custom From/Through month controls out of standard-build packages. Remove unsupported custom setting values rather than importing the patched dashboard unchanged and calling the resulting server vanilla.

## Compare the actual workflows

| Concern | Required comparison |
| --- | --- |
| Date labels | All eleven date axes and hover details, Month/Quarter/Year, multiple series and a year boundary. Try standard formatting, rotation and margins before custom changes. Record native wording and screenshots; do not claim the exact agreed format passes if it differs. |
| Complete monthly labels | The agreed 12–13-month windows at 1024, 1280 and 1600 pixels. Check every label, both edges and overlap, not just endpoints. |
| Range and grouping | February–March grouped as Quarter must exclude January. Numerical checks use expected results independent of the rendering implementation. |
| Clearing and selecting | Both selection orders; clear and reselect the same hospital on the same page; verify selected controls and actual returned values. Try supported configurations, including orientation where relevant. |
| Opening and empty panels | Cohort context remains usable before selecting a lower hospital. Hospital-only panels explain the required choice and never silently sum all hospitals. |
| Missing versus zero | Calendar gaps stay visible and distinct from valid zero or unavailable rates. |
| Navigation | Every contents link stays on the current dashboard, preserves selections/results and reveals its heading. |
| Time Unit choices | Distinguish the standard installation-wide list from independently saved development lists. |
| Transfer | Fresh import with different chart identifiers, then an update without duplicates or lost definitions. Report native versus helper-assisted results separately. |

A native limitation may be shown as a gap. It is not a passed acceptance case. A formatting alternative must still communicate the reporting period clearly; a material workflow or wording change is presented for owner review. A known incorrect numerical result is not an acceptable presentation compromise and prevents recommending the affected workflow as supported.

## Links and promotion

- Keep `dashboard.csim.uwdigi.org` as the intended entry for the selected standard main dashboard. Switch it only after validating the candidate and preserving the current custom version at an explicit alternative destination.
- Keep `preview.csim.uwdigi.org` associated with an unreleased comparison. Its current image is customized; do not label it unmodified until the replacement is verified.
- Give custom alternatives their own unmistakable destination and label. Preserve existing deep links or provide a tested redirect to the matching dashboard; do not send old custom-feature links silently into an incompatible standard dashboard.
- Give each installation a matching login. Dashboard inventory entries identify both software category and content variant.
- Update the overview, recommended dashboard link and evidence together only when their destinations exist. The published page continues to describe the currently deployed custom installations until promotion occurs.

## Coordination

The **Superset Remediation** thread owns application images, dashboard definitions, configuration, numerical/browser regressions, runtime routing, and the corresponding updates to `PLAN.md` and `RELEASE-ACCEPTANCE.md`. The overview thread owns the issue guide, version inventory, matching access links and explanation of the comparison results.

Before promotion, the runtime handoff supplies the source/image identifiers, dashboard definitions, actual URLs, retained old-link behavior, per-issue results and screenshot/recording locations. The guide uses those results to identify standard behavior, development improvements, custom additions and remaining gaps. Neither thread declares another thread's unpublished implementation delivered.
