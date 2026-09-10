# CSiM reported issues and solution coverage

The dashboard is based on the April Individual Data export: 20 charts and six datasets. The original source files and September comparisons are in [sources](sources/README.md). Automated results, deployed release identity and Beth's acceptance are separate records.

## Ian's three issues and Beth's priority

| Reported problem | Solution in this project | Remaining limitation |
| --- | --- | --- |
| Transfers contain internal IDs and do not reliably preserve relationships | Native complete-assets imports update SQL, calculated columns, charts and dashboards together. Verification uses changed chart IDs and tests a subsequent changed-definition update. The 6.1.0 deployment helper repairs cached references by UUID. | The main helper is a workaround for native import behavior. The pinned snapshot remaps the checked caches natively. Production migration is separate. |
| Time Unit choices are instance-wide | Main retains the Month/Quarter/Year restriction. Snapshot saves those choices for CSiM and Hour/Day/Week for an hourly example on the same instance. | Independent choices are not a native feature of released 6.1.0. The snapshot is pinned development code, not a preview release. |
| Labels do not follow Month/Quarter/Year | Opt-in renderer patch displays Jan 2025, Q1 2025 and 2025 while retaining real dates. Main also reads the native dashboard grain override. The same formatter is applied to all eleven date axes, including the five priority trends. Axis and hover behavior are tested where results are present. | This is a versioned CSiM customization; it is not a claim that stock 6.1.0 provides these exact labels automatically. |
| Beth's text-date path loses missing months | Calendar rows keep missing periods, separately from valid zero and unavailable denominators. | An entirely empty population/window legitimately has no result. |
| Time Period and Time Unit interact inconsistently | Tests apply equivalent selections in both orders, clear/reselect on the same page, open saved defaults, and recover from an empty window. SQL filters observations before grouping. | These tests do not establish the cause of every historical intermittent permalink or authoring failure. |
| Wrong dataset, missing calculated column or lost customizations during editing | File-based verification checks chart bindings and calculated-column expressions, with changed-definition import regression. | The saved test export still has time_aggregate and the April SQL. It does not establish an automatic dataset switch or deletion. A reproducible authoring case remains needed. |

The available workflows are linked from the [overview](https://design.csim.uwdigi.org/) and its [evidence page](https://design.csim.uwdigi.org/evidence/). Each published release must identify the tested revision and data profile.

## What changed in the date solution

The five trend charts retain `month_date` as a real date. Formatting affects its displayed text, not ordering. `show_empty_columns` retains NULL periods through Superset's pivot step. A calendar supplies the selected months, quarters or years, and the reporting window is consumed inside the virtual dataset before grouping. The existing hospital and submission-weighted cohort measure definitions are retained.

Clearing Time Unit on the released instance exposed six saved Day settings, while the instance-wide restriction disabled Day. Those chart fallbacks now use Month, matching the monthly source dates. The same-page regression catches backend failures as well as checking the recovered results. This establishes a reproducible configuration interaction in this deployment; it does not establish the cause of every historical report.

The fixture provides independent arithmetic: hospital 91 has 4, 8, 12, no, 10 and 5 submissions from November through April. March has a valid 0% inappropriate-diagnosis rate; April has no eligible denominator. Q4 is 4/12; Q1 is 9/22. Selecting February–March gives 0/10, excluding January. These are supporting checks for the requested date/filter behavior, not a proposal to change cohort weighting.

## Other reports from team artifacts

| Report | Disposition |
| --- | --- |
| Cohort-only view sometimes displays all hospitals | Historical intermittent case remains unconfirmed; preserve the exact saved link and filter state for reproduction. The selected baseline opens with Cohort. |
| Hospital-only and cohort/state-only comparison menus | Already specified and marked fixed in team responses. Preserve baseline definitions; do not describe inherited behavior as a new fix. |
| Which selector controls the hospital submission card | Baseline retains its separate Your hospital selector. Aligning it with the main selector is a separate reporting decision. |
| Entire-cohort submission total and date exceptions | Baseline definition and deliberate date exclusion retained and checked during import. |
| Latest data indication | September test-only card excluded from this baseline. An observation date, import time and dashboard update time are different requirements. |
| Table-of-contents links and embedded navigation | Source links require target-specific checks. New standalone hostname and return links are checked for this deployment; WordPress remains separate. |
| Several dashboards / shared training charts | This project represents Individual Data only. The training dashboard shares source charts, which matters for a future source-server update. |
| Historical records / hospital 57 provenance | The exports identify different historical source tables. Demo tests do not establish production data completeness. |
| Titles, introductory text, equations and percent formatting | Existing team edits and baseline definitions retained. No unrelated editorial or measure redesign is included. |
| WordPress login, blank guest links and image restrictions | Outside this standalone CSiM deployment. |
| Peer-hospital visibility | No new access restriction or reporting policy is introduced. |
| Service-worker error | No claim of a fix; a console message alone does not establish a calculation failure. |
| Printing, accessibility and automated REDCap refresh | Separate project requirements; screenshots do not establish completion. |

## Why this required several changes

A fixed date format does not choose the reporting grain. A text label does not create a missing month and can sort alphabetically. Grouping monthly percentages with MAX does not calculate the selected quarter's rate. Native filter overrides, import caches and per-control choice lists also depend on the Superset version.

The team had requirements, issue responses, saved SQL, dated exports, a tutorial and a handover. The addition here is a reproducible connection between a dashboard revision, pinned runtime, known records and automated destination checks. The source evidence does not justify claiming that the team had no change tracking or that the issues were inherently unsolvable.

## Supporting sources

- Ian's three-point overview and Beth's September 10 meeting transcript supplied in this task.
- [September 2 filter-reference repair](https://digi-team-uw.slack.com/archives/C09PMAC93PV/p1788384231145719).
- [September 9 date-filter report](https://digi-team-uw.slack.com/archives/C09PMAC93PV/p1788993442778049) and [alphabetical ordering](https://digi-team-uw.slack.com/archives/C09PMAC93PV/p1788977311945449).
- [September client responses](https://docs.google.com/document/d/1YPqHSzG93kqgNCySb3QfcsUwUgAITtGAERFqGdFlZqo/edit), [August issue document](https://docs.google.com/document/d/1sLIu0s-JQdtSy6bEyM6cSaQk3K7yOuHZ/edit), [May edits](https://docs.google.com/document/d/1if-23wJsfXA8E6C_M4AMMRXGFX4asBn1/edit).
- [Reporting requirements](https://uwdigi.atlassian.net/wiki/spaces/CSiM/pages/929890354/CSiM+Dashboard+Requirements), [tutorial](https://docs.google.com/document/d/1ZJXriNttqVWN3w_vXwYR7HH6DcrqbcIb/edit), [handover](https://docs.google.com/document/d/1xRwl4IQwoJ_N17mfwurtP-W5tWQmDEPyMubUABNqDHM/edit).
- [Upstream time choices](https://github.com/apache/superset/pull/38922), [follow-up](https://github.com/apache/superset/pull/40000), [cached-reference repair](https://github.com/apache/superset/pull/40140), [additional remapping](https://github.com/apache/superset/pull/38171).

Source suggestions and historical status labels are context, not authorization to change production or proof of current acceptance. The linked live requirements database has not been reconciled item by item; unavailable Slack binary screenshots and the September 8 Pastebin log are not used as verified root-cause evidence.
