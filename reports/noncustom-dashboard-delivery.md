# CSiM delivery: client workflow with and without a custom build

User clarification, September 11, 2026: deliver the full dashboard using the client's refined workflow, including month-range controls, and still provide options with and without a custom Superset build. Establish whether customization is needed through evidence. Neither the client workflow nor the build comparison becomes secondary; the overview describes what each running option actually supports.

## Delivery priority

The unmodified comparison and custom option are part of the same delivery against the client's requirements. Preserve useful work already implemented, but divide ordinary dashboard/data changes from Superset source changes. Do not substitute an easier workflow for the client target, and do not assume the target requires a custom build before testing supported alternatives.

Use unmodified stable Superset 6.1.0 as the starting point for the without-custom comparison. Compare a pinned unmodified development build separately because it is unreleased. Demonstrate the custom option's extra behavior and maintenance requirements against the same client workflow. Select the recommended option from the evidence; do not silently substitute development or a patched image for the standard release.

## What each demonstration contains

| Demonstration | Software boundary | Dashboard and evidence |
| --- | --- | --- |
| Without custom code: standard 6.1.0 | Official Superset application and frontend assets. Database drivers, supported configuration, saved queries and chart settings are allowed. No CSiM source patches. | Full September dashboard: 21 charts, six datasets and Beth's content. Test supported ways to provide the client's month-range workflow and record any remaining interaction or formatting gaps. |
| Development alternative | A pinned Apache development revision with no CSiM patches. | The same September content and input data. Demonstrate independently saved Time Unit menus, improved transfers and date presentation only where verified. |
| Custom alternative | An identified base version and explicit list of CSiM source changes. | The same full September content with the client-requested month-range workflow. Show the extra behavior supplied by each retained change and the corresponding gap, if any, in the unmodified option. |

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
| Client month-range controls | From month / Through month on the full 21-chart dashboard, inclusive month boundaries and separate Month/Quarter/Year grouping. Demonstrate the actual supported interaction without a custom build and the explicit custom implementation against the same requirements. |
| Clearing and selecting | Both selection orders; clear and reselect the same hospital on the same page; verify selected controls and actual returned values. Try supported configurations, including orientation where relevant. |
| Opening and empty panels | Cohort context remains usable before selecting a lower hospital. Hospital-only panels explain the required choice and never silently sum all hospitals. |
| Missing versus zero | Calendar gaps stay visible and distinct from valid zero or unavailable rates. |
| Navigation | Every contents link stays on the current dashboard, preserves selections/results and reveals its heading. |
| Time Unit choices | Distinguish the standard installation-wide list from independently saved development lists. |
| Transfer | Fresh import with different chart identifiers, then an update without duplicates or lost definitions. Report native versus helper-assisted results separately. |

A native limitation may be shown as a gap. It is not a passed acceptance case. A formatting alternative must still communicate the reporting period clearly; a material workflow or wording change is presented for owner review. A known incorrect numerical result is not an acceptable presentation compromise and prevents recommending the affected workflow as supported.

## Links and promotion

- Keep `dashboard.csim.uwdigi.org` working while both options are validated. Recommend an option based on the client-workflow evidence; neither software category is preselected for promotion. Preserve the existing dashboard at a working destination before any switch.
- Keep `preview.csim.uwdigi.org` associated with an unreleased comparison. Its current image is customized; do not label it unmodified until the replacement is verified.
- Give custom alternatives their own unmistakable destination and label. Preserve existing deep links or provide a tested redirect to the matching dashboard; do not send old custom-feature links silently into an incompatible standard dashboard.
- Give each installation a matching login. Dashboard inventory entries identify both software category and content variant.
- Update the overview, recommended dashboard link and evidence together only when their destinations exist. The published page continues to describe the currently deployed custom installations until promotion occurs.

## Coordination

This is one delivery goal covering application images, dashboard definitions, numerical/browser validation, routing, the overview and evidence. A separate task is not required to complete it. Preserve any concurrent edits, but do not make a handoff the destination or leave the overview outside release acceptance.

Before promotion, record the source/image identifiers, dashboard definitions, actual URLs, retained old-link behavior, per-issue results and screenshot/recording locations. The guide uses those results to identify standard behavior, development improvements, custom additions and remaining gaps. Local implementation is not presented as delivered until public verification passes.
