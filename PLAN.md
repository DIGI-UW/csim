# CSiM dashboard: current delivery plan

This is the execution roadmap for one CSiM release goal. [RELEASE-ACCEPTANCE.md](RELEASE-ACCEPTANCE.md) records implemented, validated, deployed and client-accepted states separately. The build comparison is part of this delivery, governed by [the comparison requirements](reports/noncustom-dashboard-delivery.md); it is not a separate goal or a prerequisite handoff to another task.

Planning checkpoint: September 11, 2026. The owner has requested immediate publication of the tested custom release and official Superset comparison as review candidates, followed by further iterations. This does not mark remaining client acceptance complete. Publish exact committed revisions with rollback artifacts; CI and final production acceptance remain separately reported.

## Goal and primary deliverable

Implement, validate and publicly publish the full September CSiM Individual Data dashboard using the client's refined workflow, with reliable inclusive From month / Through month filtering, separate Month / Quarter / Year grouping, readable date labels and correct hospital results. Deliver demonstrable options with and without a custom Superset build, establish which custom changes are necessary, and recommend the option that meets the client acceptance criteria. Keep the overview, logins, screenshots and workflow recordings synchronized with the tested release. Follow the roadmap below through repeated implementation, validation, review and public-verification cycles until the technical completion criteria are met; record Beth's acceptance separately.

Both options use the same content, demo records, reporting rules and acceptance cases. Prefer supported configuration where it satisfies the requirement. Keep unmodified stable 6.1.0, unmodified pinned development and custom software clearly distinguished. Native limitations remain failed or incomplete acceptance cases; do not silently relax exact labels, complete monthly ticks or correct filter results. A comparison is complete when it demonstrates the actual behavior and justified tradeoffs; the recommended dashboard is complete only when it passes the client requirements or an explicitly approved alternative. Merely documenting a defect does not complete its remediation.

The dashboard content remains **September: 21 charts and six datasets**. The current simpler-controls demonstration has only 20 charts and does not fulfill this target. Bring the refined month-range workflow to the full September content and compare its closest supported implementation without a custom build against the custom implementation. Preserve the April sources and established 20-chart dashboard. Upload automation and its timestamp remain a separate deliverable unless explicitly added to this release.

Client schedule: test dashboard ready Tuesday September 15 morning; client demonstration Tuesday at 2pm; production ready for showcase Friday September 18; hospital conference Monday September 21. The demonstration timezone and the exact client test destination need confirmation. The current execution updates our CSiM deployment; client production changes and WordPress integration remain separate coordination and acceptance tasks.

## Execution roadmap and iteration loop

Use the existing implementation and evidence as the starting point. Do not restart completed work or wait for a separate documentation task. The sections below retain implementation detail; this table defines the order and completion checks.

| Stage | Work | Completion check |
| --- | --- | --- |
| 1. Confirm the client target | Reconcile the current 21-chart September definitions with Beth's latest wording and issue list. Link every in-scope concern to a test, expected result and evidence. Resolve the disputed total and hospital transition rules from source evidence and specific client input where necessary. | All 21 charts and 11 date axes are accounted for. Each issue is a required fix, a named dependency, or an explicitly separate deliverable. Unknown business rules remain open; they are not guessed. Independent implementation continues. |
| 2. Complete the full workflow in both options | Bring the refined month-range interaction to the full dashboard, with shared query, selection, navigation and presentation corrections. Test supported unmodified configurations and the custom implementation against the same requirements. | The two options are runnable and comparable. From/Through boundaries, grouping, defaults and clear/reselect behavior have concrete results. Every proposed patch has a demonstrated purpose; every native gap is visible. The old 20-chart preview is not a substitute. |
| 3. Iterate on correctness and presentation | Run numerical checks, browser workflows and renderer screenshot inspection; fix failures and rerun affected checks. Complete import/update and applicable snapshot regressions. | The recommended release satisfies all required workflows. All 11 axes are inspected at 1024/1280/1600, including monthly labels, quarter/year labels and hover details. Whole-dashboard opening, selection guidance and all nine section links pass. Any alternative's limitations remain explicit. |
| 4. Publish and verify the complete release | Review and commit the implementation, run the required automated suite, deploy without reseeding, and update overview, option links, matching copyable logins and dashboard-only evidence. Preserve rollback artifacts and existing links. | The public dashboard and options match the tested source/image revisions. Public workflows, sessions, downloads, links and evidence are verified. Every fixed claim links to current evidence; build customizations and release status are clear. |
| 5. Close the review loop | Give Beth a short review path and checklist. Turn new feedback into a reproduced case and repeat the relevant stages. Provide the production integration handoff without changing client production. | Technical completion is evidenced and remaining external dependencies are named. Beth's feedback and acceptance are recorded separately. A draft, a local pass or an audit report alone does not complete the goal. |

For each iteration: **reproduce → implement → assert results → inspect screenshots → correct failures → review → deploy the validated increment → verify publicly**. Run only the relevant checks during development, then the required complete suite for the release. Do not publish a knowingly failing increment as a completed fix. Keep independent work moving while a specific reporting rule or external integration is unresolved.

After every iteration, update the issue register and acceptance record with the exact change, tests actually run, screenshot/recording locations, deployed revision and remaining failures. Fresh client feedback updates the issue list; it does not silently replace the goal or weaken acceptance. Publish workflow videos with readable captions and inspect representative frames; run website/navigation tests without published video.

### Technical completion

- The full September dashboard is reproducible from reviewed `DIGI-UW/csim` files and the supplied demo data; normal updates do not reseed.
- A recommended public release meets the agreed month-range, grouping, date-label, hospital-selection, numerical and navigation criteria, with no unexplained empty panels or known incorrect supported results.
- Public options with and without custom Superset code use the same dashboard content and have a per-issue evidence comparison. Custom changes are justified; native gaps and any external helpers are disclosed. Unreleased upstream code is labelled independently of customization.
- All required regression checks and screenshot reviews are complete for the recommended release. Alternative gaps are documented as gaps, never counted as passing requirements. Time Unit menus and transfer behavior have accurate dispositions.
- The overview, matching copyable logins, screenshots and dashboard workflow recordings identify the same tested deployment. Existing routes and rollback artifacts are verified.
- Beth has a concise review checklist. Her acceptance and the client production/WordPress rollout remain separately recorded decisions; this goal does not claim them from technical tests.

## 0. Public-solution review and three-build comparison

The [Superset options review](reports/superset-options-review.md) records verified public changes, standard configuration alternatives and unresolved custom-code necessity. This step precedes expanding or recommending CSiM patches.

| Comparison | Required boundary |
|---|---|
| Standard Superset 6.1.0 | Official code/assets with supported configuration, database driver and prepared datasets; no CSiM source patches. |
| Upstream development | Pinned Apache source/assets with no CSiM patches. Merged upstream behavior is distinct from a released capability. |
| CSiM custom | Named base plus an explicit patch list. Demonstrate the additional behavior and remaining gaps. |

The main and preview installations contain patches; the separate official stable comparison is published. Retain isolated unmodified comparisons with the same 21-chart presentation, measures, demo records and explicit windows. Adapt unsupported chart options to their native equivalents and record each difference. External import repair is a separately disclosed dependency, even on an unmodified server.

Test native formatting, rotation and margins before extending the formatter; compare upstream tooltip/spacing changes; reproduce clear/reselect in both orientations; demonstrate per-control Time Unit lists and native import repairs where available. Compare native date entry with the custom month fields. Present native wording such as “2025 Q1” for owner review before justifying a patch solely for the “Q1 2025” order.

**Accept when:** each original issue has a concise example, public solution references, and separate standard/development/custom results supported by actual screenshots and applicable numerical checks. A patch is recommended only for a remaining agreed requirement that supported alternatives do not satisfy. The overview gives each build a clear label, link and matching login. Current custom screenshots do not establish unmodified behavior.

## Public review checkpoint — September 11

| Area | Implemented, validated and deployed | Remaining |
| --- | --- | --- |
| Source and deployment | PR #13; runtime/definitions `9f7d15dbc736bd859a6a3308b81d263f162319ae`. Custom full September and official stable comparison are public, each with 21 charts and six datasets. | Review/merge and complete CI. |
| Custom workflow | [Full month-controls dashboard](https://dashboard.csim.uwdigi.org/superset/dashboard/csim-individual-reconciled-months/). Three public checks passed: inclusive month boundaries/order/clear-reselect; cohort opening across 21 panels; all eleven Month/Quarter/Year axes and hover formats. | Public supplied-data suite, all nine section links and all 12 applicable fixture checks pass. |
| Official comparison | [Official 6.1.0 dashboard](https://standard.csim.uwdigi.org/superset/dashboard/csim-individual-standard-sortable/). Public all-21-chart, hospital guidance/980 total/clear-reselect and filter-order checks passed. Server assets match the pinned official image. | Native controls use the ordinary Time Period editor, horizontal layout and year-first labels. Dedicated month fields and exact client wording remain gaps. Unmodified development remains local. |
| Overview and evidence | [Comparison and matching copyable logins](https://design.csim.uwdigi.org/comparison.html), overview revision `dd35db71a56cfb85bca6295ee2ed4965110e836f`. Six public website checks passed. Two current chart screenshots inspected. | Six reviewed workflow films and 99 inspected date-axis screenshots are published at evidence/current/. Public playback, seeking and layout checks pass. Older films remain separately labelled. |
| Broader local validation | Custom 99-case matrices pass on both bases. Stable supplied suite: 10 applicable passes. Stable and snapshot fixtures: 12 applicable passes each. | Finish release-wide regression and public verification. |
| CI | Run `34647263047` failed: two native dropdown interactions, one development hospital result, and the new September matrix running against the preserved April comparison. | Correct and rerun; local results do not establish CI success. |
| Preservation | No existing database was reseeded. Previous image/environment/metadata and routes retained. Main rollback: `/home/ubuntu/csim/backups/corrected-20260911T202231`; Caddy backup: `/home/ubuntu/csim/backups/Caddyfile-before-review-565f36e`. | Validate the remaining legacy links and handover restoration. |
| Client ownership | No-Git editing/export guidance is published. The supplied demo independently supports hospital 53's 980 total. | GUI edit/export/restore rehearsal; source of the requested 500 and approved transition schedule; Beth's separate acceptance. |

Public results: `output/public-custom-release/results.json`, `output/public-official-release/results.json` and `output/site-public-review-release.log`. A first custom opening attempt encountered an asset-load failure during route publication. After publication, the exact chunks returned 200 and the three-check rerun passed. The month workflow separately proves clear/reselect on the same page.

## Issue register

| Concern | Iteration | Required test and evidence | Status |
| --- | --- | --- | --- |
| Recommended dashboard and matching login are hard to find | 1 | Desktop/mobile opening screenshots and link assertions | Published; local/public website checks passed |
| Table of Contents URLs can point to another instance or restore saved filters | 1 | Click all nine links; assert same origin, path, query, filters and chart result; inspect nine screenshots | Local nine-link check passed; spacing update deployed; all nine public links pass without selection/result changes |
| Cohort-first opening conflicts with preselected hospital 53 | 2 | Fresh-opening screenshot and assertions for Cohort, Last year, Month and All locations | Custom cohort opening passed publicly; official full-dashboard opening passed publicly |
| Unset lower hospital can produce broad/misleading results | 2 | Empty-selection, selected-hospital and clear/reselect numerical checks | Custom guards and prompts pass; official guidance and hospital total/clear-reselect pass publicly |
| Monthly labels are omitted or squeezed at chart edges | 3 | Exact Month/Quarter/Year label lists and collision bounds on all 11 axes at 1024, 1280 and 1600 pixels | All 99 cases pass on both custom bases locally; public all-eleven hover checks pass. Public 99-case matrix and all 99 screenshot reviews complete; narrow antibiotic-count y-axis title spacing remains |
| Percentage table still shows decimal percentages | 3 | Screenshot and value checks for axes, table and hover details | Whole-percentage presentation deployed; retain numerical and screenshot checks |
| Reporting month can be confused with upload time | 3 | Card-title/subtitle and overview-copy assertions | Accurate latest-reporting-month wording deployed; this is not upload time |
| Dashboard definitions can break during transfer | 4 | Fresh import and subsequent update with changed numeric IDs; no duplicates or lost SQL/scopes/layout | Existing deterministic repair passes; retain in release regression |
| Time Unit list is global on the released build | 4 | Main/snapshot menu checks and accurate overview disposition | Main workaround and snapshot behavior already demonstrated; retain in release regression |
| Client requests From month / Through month on the full dashboard | 0, 2 | Same 21-chart content and data in the with/without-custom-build options; inclusive boundaries, grouping and recovery verified | Full 21-chart candidates pass the local month workflow on both bases, including rolling last-12-complete-month defaults and clear/reselect. Native comparison retains ordinary date controls and explicit wording differences |
| Hospital total is disputed: current 980 versus requested 500 | 2 | Hospital 53 identified from the issue screenshot; reconcile 500 with the documented all-time rule and supplied source counts | Demo source audit finds 980 distinct historical rows and no current rows. The source/calculation behind 500 remains unexplained; hospital and general counting rule are already documented |
| Hospitals transition from historical to individual data on different dates | Audit / reporting rule | Use the documented Maria-managed transition workflow; validate supplied dates, boundary, overlap and no-transition cases | The notes explicitly say Maria will supply dates. No approved schedule found in reviewed sources; do not infer it from observed record dates or ask the user to restate the existing requirement |
| Processed-data downloads and missing rows | Audit / data quality | Compare downloaded processed rows with the defined query and exclusions, with the intended user role | Latest notes require explicit validation; not covered by current screenshots |

## Review destinations

| Destination | Role |
| --- | --- |
| [September month-controls dashboard](https://dashboard.csim.uwdigi.org/superset/dashboard/csim-individual-reconciled-months/) | Recommended full workflow for review |
| [Overview](https://design.csim.uwdigi.org/) and [logins](https://design.csim.uwdigi.org/#demo-access) | Problems, solutions, matching access and evidence |
| [September evidence](https://design.csim.uwdigi.org/evidence/september/) | Dashboard walkthrough and screenshots |
| [Established dashboard](https://dashboard.csim.uwdigi.org/superset/dashboard/csim-individual-corrected/) | Preserved 20-chart comparison |
| [Simpler preview](https://preview.csim.uwdigi.org/dashboard/csim-individual-simple/) | Separate From month / Through month / grouping proposal; still the older 20-chart presentation |

The current Preview installation is a pinned development base with CSiM patches. Its independently saved Time Unit menus are upstream functionality; the formatter, reset repair and simpler month controls are custom. It must be labelled custom until a separate unmodified development comparison is available.

Keep the current main and preview routes working while preparing clearly labelled destinations for both options. Select the recommended entry from the client-workflow results; do not presume that the unmodified or custom option wins before comparison. Preserve old dashboard paths and saved-filter destinations with tested redirects if a route changes. The official stable hostname is verified publicly; additional hostnames remain proposals until verified.

## 1. Finish the review entry and section-navigation package

Keep the local overview change small: make September the first prominent action, link to its matching login, and leave the established/preview versions secondary. Inspect the nine section-navigation screenshots. Review and publish this package, then verify its public links.

**Accept when:** the starting choice is obvious on desktop/mobile; login returns to the recommended dashboard; all nine section links stay on the current dashboard and retain hospital, location, dates and grouping. No link contains a test-server hostname or restores a saved filter selection. Website/navigation tests run without published video.

This verifies our September dashboard, not changes to source production.

## 2. Correct the remaining familiar-dashboard behavior

| Change | Implementation direction | Acceptance |
| --- | --- | --- |
| Cohort-first opening | Replace hospital-53 demonstration defaults with the intended cohort-first journey. Preserve existing main/lower filter groups and explain their scopes. Hospital-only panels show a selection prompt until a hospital is selected. | Fresh page shows cohort context and useful instructions. Selecting a hospital returns its results; clearing/reselecting works without reload. No unexplained blank panels or chart errors. |
| Hospital submission total | Keep the hospital menu numeric and explicitly require a hospital in the query. Replace the fixed named-group exclusion with a numeric guard. Retain and label the documented all-time scope of the cards. | An unset selection never sums multiple hospitals/state summaries. Known-row examples verify totals. Do not claim the exact historical 8.44k cause is proven. |
| Every monthly label | Show every bucket in the agreed 12–13-month review windows on all eleven date axes; use rotation and sufficient bottom space. Preserve dynamic quarter/year formatting and real-date order. Longer windows need an explicit readable layout. | Complete expected monthly label lists at 1024, 1280 and 1600 pixels, without clipping/overlap. Quarter/year and hover labels remain correct. Checking only endpoints is insufficient. |
| Whole percentages | Complete table and other percentage displays, including hover details where applicable. Round presentation only. | Screenshots show consistent whole percentages; calculations remain unchanged. |
| Reporting month versus upload time | Accurately label the current latest-data card as latest reporting month. Do not present the inherited manual date as an automated upload timestamp. | Card and documentation meanings match. Real upload time remains a separately tracked maintenance item. |
| Wording and SQL explanation | Retain Beth's wording, logo and layout. Explain that time_aggregate belongs to the archived experiment and is absent from corrected datasets. | Source comparison and screenshots agree; original SQL and intentional calendar/filter corrections remain identifiable. |

An intentional “Select your hospital” state is useful content and passes acceptance. It replaces the earlier requirement to prepopulate every panel with hospital 53; it does not permit broken or unexplained empty panels.

## 3. Validate and publish the dashboard with matching evidence

Update assertions to match the clarified requirements and retain the existing date/filter tests.

| Workflow | Required result |
| --- | --- |
| Fresh opening; hospital selection; clear/reselect | Cohort-first guidance and correct hospital-only results, without reload |
| Month → Quarter → Year | Correct grouping, axes and hover labels on all eleven date charts |
| Monthly window at three widths | Every expected monthly label visible and readable, including edges |
| Multiple series crossing a year boundary | Chronological order for each series |
| Missing month and valid zero | Missing period remains a gap; true zero remains a value |
| February–March grouped by Quarter | January contributes no observations |
| Date range and grouping changed in either order | Equivalent selections give equivalent results and retain both choices |
| Nine section links | Same dashboard, selections and results after navigation |
| Percentage displays | Whole-percentage presentation without changing numerical calculations |
| Import and subsequent update | Intended SQL, bindings, layout and scopes; no duplicates/lost definitions |

Use supplied demo data and generated fixtures where applicable. Check representative numerical results independently and inspect real renderer screenshots. Run the same applicable September acceptance cases on the with- and without-custom options and retain shared main/snapshot regressions. An alternative's unsupported interaction is an explicit gap, not an exemption that changes the client target.

Publish only dashboard workflow recordings, with persistent small captions, major section breaks and deliberate pacing. Inspect representative frames from every published recording. Run CI regression and website/navigation checks without video.

Deploy reviewed revisions without reseeding and preserve the previous deployment for rollback. Keep a manifest linking runtime, dashboard definitions and evidence revisions. Verify public charts, overview, matching logins, downloads, existing routes/redirects and evidence links.

**Accept when:** each fixed claim has matching numerical or screenshot evidence and public behavior matches the tested release. The overview separates demonstrated solutions from remaining gaps. Beth's short checklist covers opening/selection, grouping, date changes, missing periods, section navigation and familiar content; her acceptance remains separate from automated validation.

## 4. Establish the upload routine and real upload timestamp

This is a separate maintenance deliverable. It does not block the presentation/date release when card labels are accurate.

Start from Yao's existing schema/table/CSV guidance. Establish whether inputs are full replacement extracts or incremental records before choosing Replace or append. Add an incremental path only if it is actually needed.

Rehearse the chosen routine on a copy of the supplied demo database: validate columns, stable keys, dates and hospital lookup matches; compare totals and coverage; preserve prior data for rollback. Record successful publication of an upload separately from the most recent observation date, then use that record for the last-upload display.

**Accept when:** reloading the same extract does not duplicate records; failed loads do not advance upload time; backdated observations uploaded today advance upload time without changing the meaning of the reporting period. Verify submission totals, a dated trend and a lower comparison chart. Document the verified routine and rollback steps.

## Continuing boundaries and issue dispositions

- Preserve original exports/checksums. April is the technical baseline; exact historical production identity remains unconfirmed.
- Keep source definitions and changes in Git. Normal updates never reseed. Retain PostgreSQL 14.24 restore compatibility and separate data-profile manifests.
- Main's Month/Quarter/Year menu remains an instance-wide workaround. Snapshot evidence distinguishes independently saved menus from this restriction.
- Import evidence distinguishes native Superset behavior from deterministic reference repair. Deployment success is not a native-importer fix.
- Retain explicit dispositions for all of Ian's export, Time Unit and labeling concerns. Do not equate a narrower passing workflow with resolving every issue.
- Production changes, WordPress, alternative dashboard tools and Catalyst Workbench redesign remain outside this delivery.
- The client's refined month controls now belong to the full September target. Both with- and without-custom-build options remain required; do not treat either the client workflow or the comparison as secondary.

## Sources

- [Beth's current notes](https://docs.google.com/document/d/1yGa9_3Rxjp4sMTApiklo7Nu3eRHzX0ybGZjC8FIHKPw/edit)
- [Client wording](https://docs.google.com/document/d/1if-23wJsfXA8E6C_M4AMMRXGFX4asBn1/edit)
- [Yao's tutorial](https://docs.google.com/document/d/1ZJXriNttqVWN3w_vXwYR7HH6DcrqbcIb/edit)
- [September source reconciliation](RECONCILIATION.md)

The original implementation plan remains in Git history. This is the current execution roadmap; reports provide evidence rather than silently changing acceptance criteria.

## Immediate publication and client ownership

Publish the custom stable 21-chart month dashboard and the official stable sortable-label candidate first, retaining existing routes. The comparison must distinguish tested native configurations from a claim that no other native solution is possible. The full release goal remains open through public verification, refreshed evidence and client acceptance.

[Client handover](CLIENT-HANDOVER.md) describes direct Superset editing with dated exports in Drive, dependency-aware restore, administrator responsibilities and preventing later repository deployment from overwriting client edits. Rehearse that procedure with an editor account; current documentation is not operational acceptance.

## Evidence publication checkpoint — September 11, 21:05 UTC

Published overview/evidence revision `dd35db71a56cfb85bca6295ee2ed4965110e836f`;
runtime and definitions remain `9f7d15dbc736bd859a6a3308b81d263f162319ae`.
[Current workflows and 99 screenshots](https://design.csim.uwdigi.org/evidence/current/)
are linked from the overview and build comparison. Public six-video playback/seek,
desktop/mobile layout, six website checks and exact HTTPS file hashes pass.
Previous overview revision `565f36e` is retained for rollback.

CI run `34647263047` is active at this checkpoint, including custom stable/snapshot
and official stable/development comparisons. Keep it running while preparing the
next corrections; do not confuse public workflow passes with complete CI.
Next: narrow antibiotic-count title spacing, remaining public fixture and native
comparison coverage, and client-editor export/edit/restore rehearsal. Continue
resolving the disputed total and transition schedule from evidence. Beth's
acceptance remains unrecorded.

## Spacing and regression iteration

- Public custom fixture: all 12 applicable tests pass, with one supplied-data-only skip (`output/public-custom-fixture-complete/results.json`). This includes missing/zero, partial quarters, multiple series, both filter orders, clear/reselect, 21 panels and all eleven date formats.
- Implemented: increase only the two antibiotic comparison panel heights, preserving their wording, layout positions and measures. The spacing assertion detects the published overlap at 1024/1280; updated local custom and official packages pass. Source preservation remains 636 passing assertions; import/update preserves SQL, bindings, scopes and identities on both stable options.
- The 99-case complete-label matrix belongs to the September release. The preserved April comparison has older lower-chart settings and is not promoted by that matrix; its existing functional tests continue. CI must execute the strict matrix on the full September packages.
- Native browser checks now verify a selected option and wait for Apply to enable. More filters closes on document scroll in the upstream source, so browser positioning must finish before opening it. CI failures remain unresolved until the revised checks run successfully; no product recovery fix is inferred solely from harness changes.
- A definition-only review deployment path retains the current runtime and database, backs up Superset metadata, imports the versioned packages and verifies each package. It does not rebuild or reseed.
- Deployed state remains runtime/definitions `9f7d15d` and overview/evidence `dd35db7` until the spacing increment is published and verified. Remaining: complete CI, native comparison gaps, client editor rehearsal, reviewed source and the final Beth checklist.

- Latest local checks: the custom September 99-case matrix and title spacing pass; official stable matrix/recovery/hospital checks pass; unmodified development recovery/hospital checks pass with its actual Ant Design 6 markup. The new option-state assertion is retained across both versions. CI still needs a fresh run.
- Redirect validation now uses a Docker-assigned port and checks its own readiness response. All eight routes pass; a preceding local failure contacted the separate video-preview server on the former fixed port, not Caddy.
