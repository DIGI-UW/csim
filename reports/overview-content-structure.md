# CSiM overview: content organization

## Reader and purpose

Beth and other dashboard users should be able to identify a problem, understand the available solution and its limits, and learn how to maintain the dashboard through Superset. Technical maintenance details should be available beside the relevant issue.

## Organize around issues

Use one section per issue. Keep its problem, solution, limitation and maintenance guidance together. Avoid three separate collections of problems, solutions and remaining work: that structure makes readers find the same issue several times.

The version comparison distinguishes **Standard Superset 6.1.0**, **Superset development**, and **CSiM custom**. Each issue explains the applicable standard features, development improvements and custom additions without repeating the full table. Each describes behavior, configuration needed and any gap. Both standard and upstream-development comparisons must use unmodified Superset code. The existing public preview contains CSiM patches and belongs in the custom category.

Use public community reports and verified upstream changes to explain the available solutions. A patch is an option to justify against a missing capability, not the starting assumption. Keep the detailed review in [Superset options](superset-options-review.md).

Each issue starts with:

1. **A descriptive heading.** For example, “Date labels do not identify the reporting period.”
2. **A short illustrated example.** “Select Quarter. A point still reads Jan 2025, so it looks like one month rather than Q1.”
3. **The current behavior and limitation.** “Labels now follow the grouping. Some monthly labels are still omitted on narrow charts.”

Follow with short explanations under **Why it happens**, **Current solution**, and **Maintaining it in Superset**. Put the corresponding screenshot or recording next to that issue. Label illustrations as examples; use actual dashboard screenshots to demonstrate current behavior.

Keep the maintenance dependency visible in plain language: a chart setting, a dataset change, a Superset code change, or an import workaround. Put source files, build versions and detailed checks behind an expandable “Technical details” link. These describe different maintenance requirements; they should not be combined into a generic “fixed” badge.

## Example section

**Date labels do not clearly identify the reporting period**

Selecting Quarter can leave a point labelled Jan 2025. The label looks monthly even though the value represents a quarter.

| Selected grouping | Required label |
|---|---|
| Month | Jan 2025 |
| Quarter | Q1 2025 |
| Year | 2025 |

The CSiM formatter changes the label with the grouping. It requires the custom Superset build. On narrow charts, displaying every monthly label remains an open improvement.

The actual page should pair this explanation with a chart crop and an optional Month → Quarter → Year recording.

## Existing website: retain, consolidate and move

| Existing section | Content change |
|---|---|
| Start here | Keep the recommended main dashboard, a one-sentence description, and its matching login together. |
| Dashboard inventory | Move alternative versions below the recommended dashboard, under “Compare versions.” Keep the simpler controls clearly identified as a preview. |
| Reporting need | Use a short introduction. Put the detailed range-versus-grouping explanation in its issue section. |
| Original issues / Demonstrated solutions / Remaining issues | Consolidate into the issue sections. Show each limitation directly beside the solution it qualifies. |
| What the solutions require | Distribute by issue. Name the maintenance requirement explicitly; expand code details only on request. |
| Screenshot and recording collections | Keep the full evidence gallery and add direct links from each issue. Avoid requiring a separate gallery search to understand a claim. |
| Instance links and logins | Keep the existing address and place each login beside the instance it opens. |
| Export comparison and version details | Keep as expandable maintenance references under dashboard transfer. |
| Review checklist | Keep a short practical checklist at the end of the guide. |
| Supporting dashboards and hourly example | Keep under “Examples”; link directly from the issue each demonstrates. |

## Information that needs correction

- References to twenty charts must identify the older comparison version. The recommended main dashboard has twenty-one.
- Label formatting and label density are separate: correct Quarter/Year wording does not mean every month is labelled.
- Hospital 53 is the current demonstration default. A cohort-first opening with clear hospital-selection guidance remains a proposed change.
- Clear-filter recovery includes a Superset code correction, as well as dataset and filter configuration.
- The latest-data card describes reporting coverage. It does not provide an automatic upload timestamp.
- Same-page contents links apply to the September dashboard. The older comparison version retains inherited links.
- Independent Time Unit menus are demonstrated in the development preview; the main installation uses the shared restriction.
- Importing a dashboard ZIP alone does not install the custom formatter, reset repair or deployment helper.

## Navigation and page boundaries

The landing page links to the full September dashboard and shows both current logins. Both installations are labelled as customized. The version comparison shows that separate unmodified demonstrations are not available yet; it does not substitute custom-installation links for them. The guide is titled **CSiM dashboard: issues and solutions** and uses a vertical list of descriptive issue links, with the current section highlighted. On small screens, use a compact contents list. One version comparison and issue-specific maintenance notes replace repeated build tabs.

The guide follows the revised report. It should not repeat the full dashboard inventory, release history or source comparison. Each issue should remain understandable without opening its technical details.

## Content acceptance

- Each issue has a concise example before its explanation.
- Current behavior, open limitations and maintenance dependencies are explicit.
- A reader can locate all information about one issue in one section.
- No evaluation such as “proper fix,” “the right design” or “sound correction” substitutes for explaining the mechanism and tradeoff.
- No investigation history, self-assessment or implementation timeline appears in the reader-facing copy.
- Every demonstrated behavior links to relevant dashboard evidence; proposed behavior is labelled as proposed.
- The recommended dashboard and its login are accessible from the guide.
- Current custom installations have matching links and logins. The standard and development comparison states their missing demonstration availability explicitly. No patch-dependent behavior is attributed to vanilla Superset.
- Native configuration and public upstream alternatives are considered before a custom-code recommendation.
