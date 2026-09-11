# CSiM dashboard remediation and reproducible deployment

## Goal

Deliver the full CSiM Individual Data dashboard from this repository and the supplied demo database, with clear Month/Quarter/Year labels and reliable Time Period filtering. Update the running dashboard, overview and workflow evidence together.

## Fixed decisions

- Use private `DIGI-UW/csim`; preserve the source revisions and attribution of the implementation transferred from harness pull request 111.
- Select April as the technical baseline: 20 charts, six datasets, original layout and measure definitions. Preserve September test and production for comparison. Exclude the test-only latest-data card. Exact historical production identity remains an independent confirmation.
- Preserve the baseline’s Cohort, Month and Last year defaults. The corrected full dashboards open with demo hospital 53 so all twenty panels are useful; known-record examples open with hospital 91. Familiar controls retain Month and Last year. Use explicit dates in reproducible evidence.
- Restore the supplied demo database with PostgreSQL 14.24. Retain a separate generated fixture with known missing and zero cases. Normal updates never reseed.
- Keep released Superset 6.1.0 and a separately pinned upstream development snapshot. Any customization has versioned source, tests and a reproducible image.
- Production changes, WordPress, other dashboard tools and Catalyst Workbench redesign are outside this execution.

## 1. Preserve and compare sources

Keep the three original archives, checksums and unpacked definitions. Match charts and datasets by persistent UUID, comparing SQL, calculated columns, settings, filter scopes and layout. Record the test server's runtime version/configuration separately from the age of its deployment repository.

**Accept when:** every source is identifiable, the differences are explicit, and the baseline inventory remains 20 charts. Missing historical confirmation or host access does not block reproduction from the supplied files.

## 2. Independent reproduction

Provide initialization, dashboard update, import verification, regression and evidence commands that work from this checkout without the Catalyst harness or a live source database. Restore the supplied dump into an isolated PostgreSQL 14.24 database before deployment. Keep separate data manifests; do not apply fixture hospital identifiers to the supplied database.

**Accept when:** a clean checkout builds the baseline without manual Superset edits; required tables, bindings and representative results are verified. Empty results are distinguished from query failures. Updating definitions preserves reporting records.

## 3. Date and filtering corrections

Keep an unchanged baseline alongside the corrected copy. Retain real dates for filtering and sorting; display Jan 2025, Q1 2025 and 2025 according to the selected grain. Test native behavior first and use a small opt-in renderer change when necessary. Cover all five shared time-series charts and any other date axes in the inventory.

Add calendar rows for missing periods, keeping NULL distinct from zero. Filter observations before quarter/year grouping. Preserve existing measures and cohort weighting; explain necessary aggregation changes with independent numerical examples. Exercise both filter selection orders and clearing/reselecting on the same page.

**Accept when:** labels, hover details, ordering, gaps and selected observations match the required results. Both date endpoints are visible with readable spacing at 1024, 1280 and 1600 pixels. The six stacked-bar legends sit above their plots to preserve date-axis space. Every opening panel contains useful content. Reloading is not a substitute for filter recovery.

## 4. Time Unit menus and transfer

Document the main instance's Month/Quarter/Year restriction as an instance-wide workaround. Demonstrate CSiM's saved Month/Quarter/Year choices and an hourly dashboard's Hour/Day/Week choices on the same snapshot instance.

Import into a destination with different numeric chart IDs. Verify layout, chart bindings, SQL, calculated columns, settings and all filter references, including caches. Update existing definitions and verify no duplicates or lost settings. Distinguish native importer behavior from deterministic deployment repairs.

**Accept when:** main and snapshot have explicit results for both issues; a tooling-assisted success is not described as a native fix.

## Regression acceptance

| Workflow | Required result |
| --- | --- |
| Month → Quarter → Year | All affected axes and hover details use the agreed formats and grouping. |
| Multiple series across a year boundary | Chronological order stays correct for every series. |
| Missing month and valid zero | Missing periods stay visible; zero remains a value. |
| February–March grouped by Quarter | January contributes no observations. |
| Time Period and Time Unit in either order | Equivalent selections produce equivalent results and preserve both choices. |
| Clear and reselect | Results recover on the same page, including populated and empty selections. |
| Fresh opening | The saved hospital, Last year and Month defaults apply; all twenty opening panels have useful content. |
| Fresh import and changed update | Definitions, bindings, scopes and layout match the files; no duplicates. |
| Main and snapshot menus | The global workaround and independently saved menus are shown accurately. |

Run applicable checks on both builds and both data profiles. Assert numerical examples independently of SQL implementation. Inspect screenshots of the real renderer. GitHub regression and website checks run without video. Publish only dashboard workflow recordings, with persistent small captions, major section screens and deliberate pacing; inspect representative frames from each recording.

## 5. Deployment, overview and evidence

| Hostname | Purpose |
| --- | --- |
| dashboard.csim.uwdigi.org | Main Superset |
| csim.uwdigi.org | Redirect to main Superset |
| preview.csim.uwdigi.org | Independent upstream snapshot |
| design.csim.uwdigi.org | Overview, matching instance links/logins, evidence |

Deploy tested repository revisions through review and preserve the preceding deployment for rollback. Migrate hostnames separately from dashboard definitions. Verify HTTPS, sessions, chart requests, downloads and generated links before old Catalyst redirects; preserve deep links and login return destinations.

Keep the existing overview's useful sections, organized as original issues/reporting needs, demonstrated solutions, and remaining issues/proposals. Hide implementation detail behind expandable sections. Explain the actual configuration, rendering and import constraints. Acknowledge the team's existing issue tracking and exports; do not speculate about why prior work did not solve an issue.

**Accept when:** dashboard, overview and evidence identify the same tested release; every fixed claim has evidence; every login is beside the corresponding instance link.

## Completion and handoff

Implementation, automated validation and Beth's acceptance are separate. Completion requires this reproducible project, passing priority cases locally and publicly, a disposition/evidence link for each reported issue, working routes and redirects, accurate recordings, and a short checklist for Beth. A test demonstrating a defect is not a fix; an intermittent historical problem is not declared solved just because it did not reproduce.
