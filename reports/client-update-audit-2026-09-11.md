# CSiM client update: scope and release readiness

Checkpoint: September 12, 2026. This is a release-readiness audit, not a client acceptance statement.

## Joint delivery requirements

Deliver the full September dashboard with the client's refined workflow, including inclusive From month / Through month controls and separate Month / Quarter / Year grouping. Provide demonstrable options with and without a custom Superset build. Both use the same 21 charts, six datasets, demo records and acceptance cases. Explain exactly which requirements need custom code, which supported alternatives work, and what maintenance each option requires. Neither requirement is secondary. Released and unreleased software are identified separately from whether the software is customized.

The existing simpler preview has 20 charts. It is useful interaction evidence but is not the full September deliverable. Configuration, SQL and dashboard definitions are not themselves a custom Superset build. Any external import repair or external control interface must still be disclosed.

## Sources and dates

- [Beth's client notes](https://docs.google.com/document/d/1yGa9_3Rxjp4sMTApiklo7Nu3eRHzX0ybGZjC8FIHKPw/edit?tab=t.0), titled “2026-09-11 - Updates / Notes for Piotr”, last modified September 11 at 18:29:35 UTC when read. The table contains 22 substantive rows; the final nine are unnumbered.
- [Beth's September 11 team update](https://digi-team-uw.slack.com/archives/C09PMAC93PV/p1789152082735299): test ready Tuesday September 15 morning; client demonstration at 2pm that afternoon; production ready Friday September 18; hospital conference Monday September 21. Demonstration timezone is not stated.
- [Ian's September 2 diagnosis](https://digi-team-uw.slack.com/archives/C09PMAC93PV/p1788383988447469): exported filter definitions retain chart IDs that do not match the destination instance. This directly supports the transfer/scope regression; it does not prove the exact deployed repair is still present in WordPress production.
- [August 5 integration discussion](https://digi-team-uw.slack.com/archives/C09PMAC93PV/p1785968531754959): embedded hospital access, chart-edit links, source tables and manual uploads were already discussed by the team. These are established integration concerns, not evidence of absent issue tracking. This historical discussion does not establish today's production configuration.

The linked wording document, upload manual, master data dictionary, original aggregate SQL, August 31 and September 4 issue documents, and technical handover have now been read. The screenshot beside the disputed total has been inspected. The September 11 document has no comment threads at this check. Public channel searches for historical data, transition, dates and 500 add context but do not supply a hospital transition schedule or a calculation yielding 500. Winter's latest email was not reviewed. Gmail is not an information source for this task. The user will clarify Maria's data-deletion note with Beth; no deletion or reclassification of the supplied demo dump is authorized by that ambiguous note.

## Readiness

The [public overview and logins](https://design.csim.uwdigi.org/) now lead with the full September dashboard and link two directly comparable options:

- [Customized Superset 6.1.0](https://dashboard.csim.uwdigi.org/superset/dashboard/csim-individual-reconciled-months/), the recommended client candidate. It uses inclusive From month / Through month controls, separate grouping, the requested date wording and the familiar vertical filter area.
- [Official Superset 6.1.0](https://standard.csim.uwdigi.org/superset/dashboard/csim-individual-standard-month-selectors/), with no CSiM application patches. It uses inclusive native month selectors and the same 21 charts, six datasets and demo records. It retains year-first labels, saved fixed-month defaults, horizontal controls and no warning for a reversed month range.

The custom month-input code is therefore not required merely to select inclusive months. The date-label formatter is required for the exact `Jan 2025`, `Q1 2025` and `2025` wording. The vertical-filter reset repair is required for the familiar sidebar workflow; the official horizontal layout passes the same-page recovery case without it. These are maintenance choices, not claims that the official application cannot display the dashboard.

Public validation covers all 11 date axes at 1024, 1280 and 1600 pixels, the 21-panel opening, all nine contents links, missing versus zero, partial-quarter boundaries, both selection orders and same-page clear/reselect. The overview, matching passwords, dashboard-only recordings and screenshots are public. An isolated official 6.1.0 editor rehearsal restored the complete dataset, chart and dashboard definition set after interface edits while leaving reporting records untouched.

[PR 13](https://github.com/DIGI-UW/csim/pull/13) contains the reproducible source. The development-preview job in run 34675787469 exposed a global page-idle timeout after its dashboard workflows passed. The readiness correction retains the result assertions and passes against the public preview and recommended dashboard. A complete replacement CI pass is not claimed until the new run finishes. GitHub review and Beth's acceptance remain separate.

## Client-note dispositions

Row numbers below are table positions; only rows 1–13 are numbered in the source document. Requests in the notes are requirements or questions, not proof of their cause or completion.

| Row | Concern | Disposition and acceptance |
| --- | --- | --- |
| 1 | Which dashboard to show; release timing | Recommend the customized full September dashboard for the client review because it meets the agreed label and interaction criteria. The official option is available beside it for the maintenance comparison. Do not invent a 6.2 release date. |
| 2 | Stable versus unreleased software | Both public candidates use stable 6.1.0. One is explicitly customized and one uses the official application unchanged. The pinned development installation remains a separate upstream-capability demonstration and is not the recommended client build. |
| 3 | Preserve client wording | The full September copy, 21 panels, instructions, headings and logo are retained. The 21-panel browser opening and current public screenshots pass. |
| 4 | Whole percentages | Every percentage axis and comparison-table format in the recommended dashboard uses whole percentages. Numerical assertions independently retain the underlying calculation precision. |
| 5 | Numeric hospital menu; cohort/state menu; 8.44k | The September definitions keep numeric hospitals and cohort/state values in their respective menus and guard hospital-only totals until a numeric hospital is selected. The historical 8.44k result is not independently explained and is not used as acceptance evidence. |
| 6 | Cohort-first opening; blank hospital total until selection | The public dashboard opens with Cohort, All locations, a rolling reporting window and Month. Your hospital is unset; Cohort/State is Cohort. Hospital-only panels give selection guidance instead of presenting an all-hospital total. Clearing and reselecting succeeds without reload. |
| 7 | All months labelled; vertical labels and spacing | The custom dashboard uses the requested wording and retains every month. All 11 axes pass at 1024, 1280 and 1600 pixels; 99 screenshots were inspected. The official comparison retains every month with year-first wording. |
| 8 | Logo proportions | The logo uses width-only sizing and appears in the inspected full-dashboard opening. |
| 9 | Contents links stay local and retain filters | All nine links are same-page anchors. They preserve selections and leave the linked headings visible at all three tested widths. |
| 10 | time_aggregate experiment and original SQL | `time_aggregate` is absent from the recommended and official full-dashboard definitions. The retained SQL uses real dates plus the intentional calendar and date-window corrections; the archived test experiment remains only in the preserved source export. |
| 11 | Actual upload timestamp | The card is accurately described as the latest reporting month, not an upload timestamp. Automatic upload completion tracking remains the next deliverable and is not claimed fixed here. |
| 12 | Future-upload instructions | The manual specifies replacing the existing current/historical tables under their existing names and updating the hospital lookup for new hospitals. Validate this workflow and dashboard continuity against the packaged deployment. The manual has been read; operational acceptance and upload automation are not complete. |
| 13 | Missing dates in lower charts | All 11 date axes are included in the public matrix. Calendar rows preserve missing periods as gaps, while known-record checks distinguish a missing result from a valid zero. |
| 14 | Missing processed rows and quality checks | Establish expected inclusion/exclusion rules and compare processed rows, not only counts. Provide a tested download path with the intended user role. |
| 15 | Ambiguous current-data deletion note | User will check with Beth. No identified source, deletion, or change to the supplied demo-data classification. |
| 16 | Client chooses month-range controls | Required on the full 21-chart dashboard. Compare supported native interaction with the explicit custom fields; preserve inclusive month boundaries and independent grouping. |
| 17 | Winter's dataset email | Latest email unavailable in this audit. Use the document and Slack evidence; do not infer the email's content. |
| 18 | Different historical-to-individual transitions per hospital | Intent is documented: hospital-specific dates, Maria-maintained changes and a quality-check view. The note explicitly says Maria will supply dates. No schedule is present in the reviewed definitions, dictionary, issue documents or Slack results; record dates remain observations, not approved switch dates. Boundary-month and overlap examples remain to be settled. Do not ask the user to restate the documented requirement. |
| 19 | All-time total should be 500 instead of 980 | Screenshot identifies hospital 53, All locations, Last year and Month; the disputed card is the hospital total. The manual/dictionary define all-time counting. The demo contains 980 distinct historical rows and no current rows for 53. No reviewed source explains 500. Preserve the discrepancy as a source/expected-result reconciliation, not evidence that the all-time rule is undefined or that the client is wrong. |
| 20 | Hospital defaults from login; limit comparisons | Coordinate with Winter/Herbert on embedded user identity and row access. A preselected filter alone cannot demonstrate access restriction. Keep direct-dashboard and embedded acceptance separate. |
| 21 | Add/delete hospitals | Test lookup refresh and resulting datasets/filter choices with explicit fixtures. Current hospital-selection checks do not cover this lifecycle. |
| 22 | Download processed UTI aggregate data | Verify the actual processed dataset, selected filters, columns and row completeness with Maria's role. Separate a capped chart export from a complete dataset download. |

The notes therefore extend beyond rendering: transition rules, disputed totals, processed-data access and embedding behavior require separate evidence. Positive client feedback supports improved usability; it is not acceptance of these additional cases.

## Source-rule findings

The [upload and dashboard manual](https://docs.google.com/document/d/1ZJXriNttqVWN3w_vXwYR7HH6DcrqbcIb/edit) and [master data dictionary](https://docs.google.com/spreadsheets/d/1JODAbjzgA0MSU87_CVfK4QSzzyhVyU4WBrlszjS6FyM/edit) already define the inclusion rule: combine historical records and completed current records (`qi_asb_complete = 2`), and count submissions. The dictionary defines the volume measure as a record count; the all-time aggregate sums submissions across months. These sources do not instruct deduplication to a presumed 500 or selection of an arbitrary historical cutoff.

The [original aggregate SQL](https://docs.google.com/document/d/1wBSzLHmfFndduEL8sTDivOvd4uJK43Ews-Ptcx7AZiU/edit) and versioned corrected query combine current and historical rows with `UNION ALL`. The corrected query applies the selected date window before grouping. Neither inspected source-selection block has a hospital-specific transition date. The supplied hospital lookup contains state, hospital name and hospital code, not an approved transition schedule. The new notes explicitly say Maria will supply dates. First and last observed months can support a quality check, but cannot establish the intended transition policy by themselves.

The inspected row-19 screenshot shows hospital **53**, **All locations**, **Last year** and **Month**. Its hospital card reads 980; its cohort card reads 3,142. The screenshot does not give the derivation of 500. The read-only [source audit](../scripts/audit_hospital_53.sql), executed against the supplied demo database, finds:

| Hospital 53 source | Result |
| --- | --- |
| Historical rows / distinct record IDs / distinct full rows | 980 / 980 / 980 |
| Historical range | September 2023–March 2026 |
| Historical totals by year | 2023: 72; 2024: 247; 2025: 568; 2026: 93 |
| Current rows, including incomplete records | 0 |
| Alternate historical table named `2024-2025` | 980 rows and 980 distinct IDs |

Receipt: `output/hospital-53-source-audit.json`. Screenshot inspected: `output/beth-500-source.png`. This rules out exact-row duplicates, repeated record IDs and historical/current overlap as explanations of the supplied hospital-53 count. It does not establish that these demo records match the client's intended source population. The [September 4 issue document](https://docs.google.com/document/d/1YPqHSzG93kqgNCySb3QfcsUwUgAITtGAERFqGdFlZqo/edit) already asks the team to confirm which historical file is loaded and whether it is complete. Source-version reconciliation is therefore an existing reported concern, not a new invented problem.

The specific unresolved items are the source or calculation behind **500** and the promised per-hospital transition schedule. The general all-time rule, screenshot hospital and desired transition-management workflow are already documented. This distinction replaces the earlier overly broad request for those requirements.

The historical-data folder was inspected for file metadata only; it contains historical inputs and lookup files but no separately named transition schedule. No additional historical record files were downloaded or used by this audit.

## Next execution checkpoints

1. Finish exact-head CI and correct any concrete regression without weakening the acceptance cases.
2. Complete GitHub review and have a client editor follow the published export/restore handover. Keep reporting records separate.
3. Review the public checklist with Beth. Record her acceptance or specific feedback separately from automated validation.
4. Reconcile the requested 500 total and hospital transition dates when the source owners provide the expected records and schedule. Herbert/Winter separately verify embedding before production signoff.

The public Tuesday review candidate is available and technically validated. It is not yet client-accepted, and no production or WordPress change is included.

## Overview alignment

This delivery owns the runtime, definitions, tests, deployment, issue guide and evidence presentation together. Present the full 21-chart month-range workflow and the validated options with and without custom Superset code. Keep the known total discrepancy and the unavailable transition dates precise; do not describe already documented requirements as missing. Technical details remain expandable, and every public claim stays tied to the deployed revision.
