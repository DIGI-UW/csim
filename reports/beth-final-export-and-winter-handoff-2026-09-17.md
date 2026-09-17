# Beth's dashboard changes and the Winter handoff

17 September 2026. Status: Beth's saved revision is preserved and compared; the client installation package still needs preparation and a transfer test.

## What happens today

**Today is the technical installation with Winter, the client's IT lead. Tomorrow is the review with the people who use the dashboard.**

- **Thursday, September 17, 12:50–1:50 p.m. Pacific:** “CSiM Dashboard production Upload,” organized by Beth. Piotr, Winter and Herbert are to update the dashboard on the client's existing Superset site.
- **Friday, September 18, 11 a.m.–noon Pacific:** “CSiM Dashboard review (proposed).” Beth says Maria, Natalia and Winter will review it after their production data is uploaded. Confirm that upload is complete before using counts as acceptance evidence.
- Beth says she can join by phone or WhatsApp if an explanation or decision is needed. This does not establish that she will attend both meetings in full.

The installation target is [the client's Superset](https://superset.uwcsim.org/). [Our review dashboard](https://standard.csim.uwdigi.org/superset/dashboard/csim-individual-standard-month-selectors/) is the reference to copy from. The client keeps its own Current, Historical and Hospitals and States data. The delivery targets official Superset 6.1.0; verify the client's installed version with Winter rather than assuming an application upgrade is required.

## What Beth shared

At 9:06 a.m. Pacific, Beth posted her finished dashboard export and a [report for the CSiM team](https://docs.google.com/document/d/1AFFwNV4VrhE7_EZkmmJRSRgN2dNYfzOnoqruwnkDi8Q/edit). At 9:21 she clarified today's production installation and tomorrow's user review.

Her export is `dashboard_export_20260917T160253.zip`. It contains **one dashboard, 21 charts and six reporting datasets**. A fresh 9:30 a.m. export from our running instance has identical dashboard, chart, dataset and connection definitions. This is the saved dashboard Beth shared, not just an unsaved browser view.

The original ZIP, readable definitions and report text are [preserved together](../sources/exports/beth-september-17-2026/README.md). A [separate live backup](../sources/live-review/2026-09-17T163028Z/README.md) includes dashboard, chart and dataset exports. These archives contain configuration and SQL, not the client's reporting records. The report text copy does not include the Google document's screenshots; the linked original remains the source for those.

## What changed

Compared with the previous saved checkpoint, with the intervening navigation publication accounted for:

| Area | Beth's saved version | Effect |
| --- | --- | --- |
| Latest-month card | Renamed to **Latest Urine Culture Submission** and formatted with a day as well as month/year | Display change only; it still calculates the latest reporting month. See the correction below. |
| Old upload note | Removed the manually entered March 30 note | The stale note is gone. There is no replacement upload timestamp. |
| Reporting-period summary | Removed the extra summary panel and its helper dataset dependency | Main dashboard is now 21 charts and six datasets, down from 22 and seven. |
| Filter guidance | Uses **SELECT YOUR HOSPITAL FIRST** and **COMPARISON FILTERS**; adds guidance in sections 4.2–4.4 | Helps distinguish the upper hospital selection from the separate lower comparison selections. |
| Comparison charts | Moves the six comparison legends to the left; retains population names in legend entries | Presentation change. Their saved chart settings also changed, so Month/Quarter/Year needs a fresh check. |
| Hospital total | Says it is based on **Your Hospital** | Makes the separate lower hospital selector more explicit. It remains an all-time total. |
| Section 4.1 | Replaces the displayed positive-urinalysis formula with the inappropriate-diagnosis formula | The explanation no longer matches the calculation; correct it before client handoff. |
| Dataset SQL and measures | All six dataset definitions are identical; all 21 retained chart measure definitions are unchanged | No evidence of changed reporting calculations in this editing round. |
| Filter behavior and colors | The six real controls, saved choices, intended chart exclusions and explicit series-color assignments are retained | The known filter issues are not solved by these wording/layout edits. Some automatic color metadata was refreshed; final rendered colors still need checking. |

The Time Period and Time Unit help descriptions were cleared, including the explanation that the end date is excluded. The saved dates and Month choice remain unchanged. Restore a short date-boundary example in the agreed guidance. Superset also rewrote cached chart scopes and removed empty Time Period target metadata; these serialization changes alone do not establish a filtering defect.

The nested Table of Contents and first-step hospital guidance were already published before Beth's final export. Her export retains the nine same-page Table of Contents destinations. Do not count those as newly created by her editing round.

## Three corrections or clarifications before installation

### 1. Reporting month is not upload date

**Example:** Uploading July data in September should show July as the latest reporting month. It does not tell us when the upload happened.

The saved card uses `MAX(CASE WHEN ucsub > 0 THEN month_date END)`. The data represents each reporting month by its first day. The current screen therefore shows values such as **Aug 01 2026**, even though no precise submission or upload day was calculated. Beth's report describes it as the last manual upload date, which is not what it measures.

**Recommendation to confirm with Beth:** label it **Latest reporting month**, display **Aug 2026**, and describe it as the latest month with data within the selected filters. If the team also needs **Last data upload**, keep that separate: either a clearly manual note, or a later feature based on a reliable successful-upload timestamp.

### 2. The section 4.1 explanation describes the wrong measure

The **Positive urinalysis** charts still use the positive-urinalysis rate. Their data query counts records with positive urinalysis and divides by the submission count. The text above them now describes treated asymptomatic patients with positive cultures divided by all treated patients with positive cultures—the explanation used in section 1.

**Recommendation to confirm with Beth:** restore the positive-urinalysis explanation. This is a wording correction; do not change the measure to fit the misplaced text.

### 3. Record verification is available as a separate view

The report says adding the two IDs to the aggregate dataset is “not possible.” A summary row can represent many submissions, so it cannot have one unambiguous submission ID. That does not prevent record review.

The demo already has a [separate individual-record review table](https://standard.csim.uwdigi.org/explore/?slice_id=131), with `record_ID`, Current's `redcap_repeat_instance`, source and eligibility information. It preserves the summary calculations. Beth previously requested this separate chart for the client.

**Recommendation:** demonstrate that existing view, include it explicitly in the agreed package, and describe it as the way to check individual records. Beth's one-dashboard ZIP does **not** include this standalone chart or its dataset. It also omits the standalone aggregate CSV download and the separate Data & records dashboard. Agree which supporting views to install; do not assume the attached ZIP includes everything visible on the demo server.

## Installation work still required

**Beth's export is the reference for the dashboard's appearance and settings. It is not yet a tested update package for the client's existing objects.**

Against the supplied September production export, it shares **zero dashboard identities, zero chart identities and zero dataset identities**. Matching names do not make these the same Superset objects. The database identity is shared, but the export contains the demo connection (`CSiM demo PostgreSQL`, database `csim_demo`). A direct import must not be assumed to update the existing client dashboard or preserve its connection correctly.

Before installation:

1. **Obtain fresh destination definitions and confirm access.** Winter/Herbert export the current production dashboard and dependencies, confirm Superset version, connection, relevant settings and the target dashboard. This does not require downloading production records.
2. **Build the update from Beth's preserved version.** Keep the client's existing dashboard/chart/dataset identities and connection. Keep its source-table names. Add only agreed new supporting views. Do not rerun the old demo generator over Beth's saved changes.
3. **Test the package in a separate installation.** Import into a copy with destination identities, then import it again. Confirm no duplicate objects, no replaced connection, retained SQL/measures/colors/layout and correctly mapped filter references. Prior import tests do not certify this newly edited package.
4. **Back up before changing production.** Preserve the current dashboard definitions and application metadata, with a clear way to restore them. Keep the client's reporting database intact.
5. **Install and verify as the client user.** Check the normal dashboard URL, permissions, dates, hospital choices, comparisons, Table of Contents and agreed download views. Check any existing website link/embed still reaches the intended dashboard; changing the website integration itself is outside this dashboard delivery.

If the package has not passed the transfer test by the meeting, use the meeting to establish access, backup and destination details, then schedule the tested import. The meeting's calendar title does not make an untested ZIP ready to install.

## What is still open, and what is not

| Item | Current position | What to do today |
| --- | --- | --- |
| Date labels and date filtering | Existing official 6.1.0 approach is retained; no custom application patch is required for this delivery. Year-first month/quarter labels remain the supported format. | Recheck the final edited charts, including the six lower comparisons, after transfer. Do not equate matching SQL with completed browser acceptance. |
| Clear all | A stale-selection problem was previously reproduced on official 6.1.0. Today's export does not change the application. | Keep the limitation and tested workaround explicit. Do not promise it is fixed. |
| Misleading applied-date indicators | Five overall charts and two latest-month tables still receive date controls their queries do not use. All six dataset definitions and retained filter exclusions are unchanged. | Show the [filter catalogue](https://design.csim.uwdigi.org/filter-guide.html). Confirm whether these panels should retain all-time/latest-available meaning or follow the selected period. Correcting indicators and changing reporting meaning are separate decisions. |
| Two hospital selectors | Upper selection controls trends/latest tables; lower **Your hospital** controls lower comparison charts and the hospital all-time total. | Walk through one hospital using both selections. The new heading mentions 4.2–4.4 but should also explain section 5's hospital total. |
| New hospitals | Beth explicitly asks to retest adding the hospital to **CSiM Hospitals and States** as well as uploading records. | Include lookup registration, appearance in menus and visible data in the upload checklist. A successful upload alone does not prove the lookup is complete. |
| Reported all-time total mismatch | Beth's latest report marks it not reproduced; prior numerical reconciliation distinguished all-time and selected-period totals. | Have Maria compare the same hospital, population and full reporting range. Do not count unlike selections as a new calculation defect. |
| Historical/Current transition | Beth says Hospital 12's form change does not need a hard-coded transition rule. | Do not add one. |
| Client acceptance | Beth's finished layout is not the same as Maria/Natalia verifying the imported dashboard with their data. | Reserve reporting-data acceptance for tomorrow's review after upload. |

The published filter catalogue still describes the removed reporting-period summary and the old upload note. It remains useful for chart/filter mappings, but must be updated to match the accepted 21-panel version before it is the final client guide. The public overview and downloads are not a substitute for a client-specific installation package.

## Suggested meeting checklist

**Piotr — dashboard package and explanation**

- Bring Beth's preserved export and the three clarification points above.
- State which views are included: main dashboard, individual-record review, and any agreed download/support page.
- Explain the upper/lower hospital selectors and the all-time/latest exceptions with one concrete example.
- Present the actual transfer-test result; identify anything still untested.

**Winter and Herbert — client installation**

- Confirm destination, version, access, backup and restore procedure.
- Preserve the client data connection and physical upload sources.
- Apply the tested package and verify that the normal user entry point works.

**Maria and Natalia — reporting review, principally tomorrow**

- Confirm that Current and Historical uploads, and the hospital lookup, are ready.
- Select one known hospital and reporting window; reconcile submission counts and review five known records in the separate table.
- Try Month → Quarter → Year, change the date range, use the lower comparisons and navigate the Table of Contents.
- Record any remaining issue with the exact hospital, dates, chart and expected result.

**Success today:** the agreed dashboard configuration is installed without duplicate assets or connection changes, opens through the client entry point, and passes the transfer/smoke checklist. **Success tomorrow:** the intended users can verify their uploaded records, interpret the filters and accept the reporting results. These are separate checks.

## Evidence and reproducibility

- [Beth's finished-export message](https://digi-team-uw.slack.com/archives/C09PMAC93PV/p1789661175456259)
- [Beth's today/tomorrow clarification](https://digi-team-uw.slack.com/archives/C09PMAC93PV/p1789662093012739)
- [Beth's report](https://docs.google.com/document/d/1AFFwNV4VrhE7_EZkmmJRSRgN2dNYfzOnoqruwnkDi8Q/edit)
- Outlook calendar checked September 17: “CSiM Dashboard production Upload” and “CSiM Dashboard review (proposed).” Times above are Pacific.
- [Original export, hashes and comparison](../sources/exports/beth-september-17-2026/README.md)
- [Live backup](../sources/live-review/2026-09-17T163028Z/README.md)
- [Prior navigation publication](navigation-guide-publication-2026-09-17.json), used to distinguish our earlier edits from Beth's changes.
- [Earlier detailed filter audit](dates-and-filter-scope-2026-09-17.md), a point-in-time 22-panel inventory; the new export removes only its period-summary panel.

Browser inspection confirmed the live latest card's day-level display, section 4.1's mismatched explanation, the updated sidebar guidance, and the same-page Table of Contents link retaining the current filter key. This was a focused visual inspection, not a new full regression run. No production dashboard or reporting data was changed for this audit.
