# September dashboard release acceptance

This checklist implements the client-refined familiar-dashboard release: 21 charts, six datasets, supplied demo data and From month / Through month controls. Providing and validating options with and without a custom Superset build is equally required. The comparison determines where customization is necessary; neither deliverable is secondary. Preserve existing custom deep links during promotion. Upload automation remains separate; adapting the refined month controls to the full 21-chart dashboard is now in scope.

Follow the execution roadmap in `PLAN.md`: confirm target → complete both full-dashboard options → iterate on correctness and screenshots → publish and verify → close Beth's review loop. The sections below preserve detailed acceptance history; they do not define a separate sequence or require work to move to another task. The recommended release must meet the client criteria; a comparison option may demonstrate a named gap, but that gap is never counted as a fix. Record implementation, local validation, public verification and Beth's acceptance independently.

## Linux renderer validation — current increment

- **Implemented:** the opt-in date formatter removes the inherited right gutter for vertical labels, while retaining 8 pixels for bars, 16 pixels for lines, and space for a right-side legend. Definitions, measures and data are unchanged by this renderer correction. Browser selectors now wait for their visible option to stop moving before using a normal pointer click.
- **Validated locally:** stable and snapshot each pass all 99 date-axis cases in Linux Chromium. All 198 screenshots were inspected through 36 contact sheets; complete Month/Quarter/Year x-axis labels pass at 1024/1280/1600. Minimum adjacent-label gaps are 8.7565 and 8.3551 pixels respectively. Stable build component tests: 94 passed; snapshot: 205 passed. The official native month-selector matrix also completes on Linux after the interaction synchronization correction.
- **Separate visual finding:** the snapshot's two antibiotic y-axis titles are truncated in Month. This does not fail x-axis acceptance, but whole-chart presentation remains incomplete and is under correction. The stable screenshots retain the complete titles.
- **Native comparison gap:** From March 2026 / Through February 2026 can be applied and returns empty charts without a range-order warning. Reviewed screenshot and observation: `design/evidence/native-reversed-range.png` and `.json`. The diagnostic records required validation as false; it is not counted as a fix.
- **Deployed:** unchanged by these local validations. Main definitions remain `623acb3`, official definitions `818478a`, both runtimes `9f7d15d`, overview `7c27875`. The committed custom section-heading correction and the renderer update await publication and public verification.
- **Remaining:** complete functional checks and CI, publish the stable correction and refreshed evidence, correct the snapshot title finding, diagnose concurrent native chart waits and the CI opening timeout, and complete the client-editor rehearsal. Reporting-rule inputs and Beth's acceptance remain separate.

The checkpoints below record earlier iterations.

## Current correction and validation iteration

- **Deployed:** official stable definitions `818478a4acd460ee2f40abb8c714ed9a9c342ee8`; main remains `623acb3c586103809c3b06b1a9013a28758ec402`. Both runtimes remain `9f7d15d`. Official rollback metadata is `/home/ubuntu/csim/backups/standard-assets-20260911T235451.db`. No data was reseeded.
- **Public evidence:** official section-link checks pass at all three widths. The earlier 27 screenshots were inspected; the stronger check now inspects the whole heading rather than its inline anchor. The custom 1024px screenshot exposes clipped two-line headings; the stronger check reproduces that defect on the public site (`output/public-custom-real-heading-repro`). This supersedes earlier assertions that every custom heading was visible.
- **Implemented locally:** increase custom anchor clearance for two-line headings; preserve the official horizontal-bar clearance. All 786 source assertions pass and the custom import verifies 21 charts, six datasets and preserved filter references. All 27 local custom screenshots and all 27 public official screenshots were inspected; the stronger navigation checks pass at all three widths (`output/custom-heading140` and `output/public-native-real-heading-818`). The custom definition correction is not yet public.
- **Renderer evidence:** Linux reproduces the CI gap of 7.822 pixels on the six lower monthly axes at 1024px (`output/linux-custom-labels-stationary`). The first gutter adjustment had no effect because upstream already supplied 20 pixels. The correction now removes that inherited time-axis gutter for vertical labels while retaining at least 8 pixels and preserving right-side legend space. Both base images are being tested; no public renderer update is claimed.
- **Test interaction:** wait for option bounds to stop moving before clicking. Use the same unobstructed pointer interaction for Time Unit as for other native selectors. The original Linux selection failure is recorded; selected-state, Apply and result assertions remain unchanged.
- **Native reliability:** a two-worker public run produces two passes and two chart-wait failures (`output/public-native-concurrent-818`). Failure traces include chart requests with no observed response; recent server chart responses are successful. The cause is not yet established. Passing isolated reruns do not close this gap.
- **Documentation:** the options review now describes the published native From/Through selectors and their actual differences from custom controls. Website/evidence remains publication `7c27875` until the next reviewed update.
- **Remaining:** finish both Linux matrices, inspect corrected screenshots, complete CI, deploy validated corrections and synchronize public evidence. Native concurrency diagnosis, client editor rehearsal, unresolved reporting-rule inputs and Beth's review remain open.

The checkpoints below describe earlier revisions; this current checkpoint takes precedence.

## Native month option publication — current iteration

- Deployed: saved definitions `623acb3c586103809c3b06b1a9013a28758ec402` on both public stable instances. Runtime images and reporting data unchanged. The official instance now also serves `csim-individual-standard-month-selectors` and its known-record copy. Main September identities are preserved.
- Rollback metadata: `standard-assets-20260911T231729.db` and `corrected-assets-20260911T231856.db` under `/home/ubuntu/csim/backups`.
- Validated locally: 786 source assertions, deterministic regeneration with no dashboard differences, six website checks including exact login destinations and password copy. Inspected all 99 native screenshots; year-first wording remains a gap.
- Public custom validation: 13 checks pass, including all 99 date-axis cases and 21-panel opening; all 99 screenshots inspected. All nine custom contents links pass visual inspection. Native links preserve filters, but screenshot inspection shows some headings beneath the fixed horizontal filter bar; this is a remaining visual navigation defect. Native fixture recovery and partial-quarter checks pass on an isolated rerun, and the new inclusive-month demonstration passes. Initial parallel native runs had chart-wait timeouts; their cause remains open.
- Implemented next source correction: include both native-month packages in the top-level generator. CI had deleted them during regeneration because this call was omitted. No definitions changed in this repair.
- Prepared: comparison links, new downloadable package and reviewed chart thumbnails. Published overview/evidence `7c27875893e3968c478c72360a881c95c1b3332d` at 23:42 UTC, retaining the prior site. All 57 public file hashes match; seven videos play and seek over HTTPS; six public website checks pass. Native workflow film has eight inspected encoded frames. Current definitions remain `623acb3` and runtime `9f7d15d`.
- Implemented and validated locally: standard dashboard CSS places native section headings below both fixed toolbar rows. All nine links pass at 1024/1280/1600; all 27 screenshots inspected. Stronger hit-testing reproduces the old public failure and passes the custom dashboard. Local imports preserve 21 charts/six datasets/seven filters; 786 source assertions pass. Public deployment of this CSS correction is pending.
- CI website correction: include both reviewed comparison thumbnails in the repository. The six website checks pass from tracked files only; the missing images caused the 7c27875 website failures.
- Remaining: publish the native heading correction, diagnose parallel native chart-wait timeouts, complete CI including known narrow-label geometry and selection failures, then client editor rehearsal and Beth checklist. The historical checkpoints below remain evidence of earlier revisions.

## Public review checkpoint — September 11

| Area | Implemented, validated and deployed | Remaining |
| --- | --- | --- |
| Source and deployment | PR #13. Both public options run runtime `9f7d15dbc736bd859a6a3308b81d263f162319ae` with dashboard definitions `d66d09e4c89de167869b99b55cd748bcfb705a8d`: 21 charts and six datasets each. Definition-only imports preserved data and runtime images. | Source review/merge and complete CI. |
| Custom workflow | Full supplied-data suite: 10 applicable passes. Known-record fixture: 12 applicable passes. Public nine-section navigation passes. After the spacing update, three width checks, the 99-case axis matrix and 21-panel opening pass. | The screenshot review identifies clipped All/Inv legend controls on some antibiotic charts. Correct and recheck these independently of the passing date axes. |
| Official comparison | Public three-width title spacing, all-21-chart opening and hospital selection/980/clear-reselect pass. The final control-surface synchronization check passes both filter orders and same-page recovery. Official application assets remain unmodified. | Native date editor and year-first wording are comparison gaps. Native month-selector configuration still needs implementation/validation before concluding whether custom controls are necessary. Unmodified development remains local. |
| Overview and evidence | Matching logins with copy icons are public. Six reviewed dashboard films remain valid for the unchanged controls and calculations. All 99 screenshots of definitions `d66d09e` have been inspected; the new artifact passes video playback/seeking and six website checks locally. | Published and publicly verified at `d9c7f0ae0a4bd937af2c4a79e8a7be1414c2d7fd`; previous site `dd35db7` retained. All 50 file hashes, six website checks, six-video playback/seeking and both 21-chart downloads pass. |
| CI | Run `34650001762`: native jobs failed on menu timing and a development legend assertion that inspected canvas instead of its DOM renderer. The snapshot job also failed when an already-selected Ant 6 single-select value was misread; the exact linked-example rerun now passes. The remaining stable job was cancelled by the new source push. Replacement run `34652162752` is active at `d9c7f0a`; no complete CI pass is claimed. | Finish the actual running jobs; rerun corrected native assertions. Local passes do not establish CI success. |
| Preservation | No existing database reseeded. Definition backups: `corrected-assets-20260911T213524.db` and `standard-assets-20260911T213621.db` under `/home/ubuntu/csim/backups/`. Existing routes retained; eight local redirects pass. | Client editor export/restore rehearsal and final public legacy-route verification. |
| Client ownership | No-Git editing/export guidance is published. Demo records independently support hospital 53's 980 total. | Source of the requested 500, approved hospital transition schedule, editor rehearsal and Beth's acceptance. |

Current evidence: `output/public-spacing-custom/results.json`, `output/public-official-settled/results.json` (five passes; its search-input-width assertion failed before the recovery workflow), and the corrected recovery check `output/public-official-surface/results.json`. The menu assertion now waits for the visible Select surface to finish its animation. It does not change Superset or bypass the numerical assertions. The screenshot record is `output/public-spacing-screenshot-review/review.json`.

The detailed checkpoints below retain earlier observations; this checkpoint takes precedence for current deployment and acceptance state.

## Build selection — before main promotion

- Implemented: shared calendar/query corrections and custom alternatives remain versioned locally. The comparison contract is `reports/noncustom-dashboard-delivery.md`.
- Implemented locally: unmodified stable/development packages, plus categorical-label candidates. All preserve 21 charts and six datasets and exclude `csim_period`, custom hospital prompts and custom month controls. Every frontend asset matches the pinned official image; receipts are in `output/standard-asset-verification.json` and `output/development-asset-verification.json`.
- Validated locally: native smart-date screenshots still have exact-format gaps (99/99 stable cases; 66/99 development cases). The vertical-filter recovery workflow fails on both. Horizontal controls with Time Period and Time Unit first pass the same-page recovery and known-record tests on both builds. These alternatives remain candidates, not a replacement for the current public dashboard.
- Validated locally: sortable candidates show all 13 monthly labels on all 11 axes at 1024, 1280 and 1600 pixels, with at least 19 pixels between labels. All 66 monthly screenshots were inspected; representative quarter/year screenshots were inspected. Both builds pass hospital 53's 980 total and empty/clear/reselect checks. See [the native validation checkpoint](NATIVE-VALIDATION.md).
- Remaining: finish hover and full opening-panel review, fresh instruction screenshots and import-update tests. Year-first labels and horizontal filters require owner review before promotion; original exact wording remains a recorded gap.
- Require the same 21-chart content, six datasets, input records, date windows and numerical assertions. Native empty-state instructions may replace custom prompts only when the panel and adjacent guidance are clear. Test vertical and horizontal filter recovery explicitly.
- Exact `Jan 2025` / `Q1 2025` / `2025` labels and complete monthly ticks remain acceptance criteria. A different native wording is a proposed tradeoff for owner review, not a passing result. Wrong results after clearing/reselecting prevent recommending that workflow.
- Refined controls: test the client's From month / Through month workflow on the full September content in both options. An unmodified option must expose its actual supported interaction and any gap; the custom option must identify the source change that closes it. Do not use the old 20-chart simpler preview as acceptance evidence for the full dashboard.
- Deployed: official stable comparison is public; original main and preview remain custom. Unmodified development remains local.

## Full September month-controls implementation and local validation

- Implemented: isolated full 21-chart / six-dataset month-control packages on both custom bases. Supplied data defaults to the last 12 complete calendar months; fixture uses explicit November–April dates. Changing grouping does not widen either window.
- Validated: source preservation passes 4 tests / 138 assertions, month-package checks 1 / 32, native-package checks 1 / 466. Supplied month-package import/update preserves definitions and identities without duplicates.
- Validated stable candidate: `6.1.0-csim-september4`; all 10 applicable supplied-data browser tests pass (`output/corrected-september-full-final/results.json`). This includes all 99 width/grouping/axis cases, 21-panel opening, all eleven hover formats, cohort selection, filter order and clear/reselect. The reset repair stages cleared values before Apply, matching the upstream behavior.
- Validated snapshot candidate: `e22ce197-csim-september6`; the 99-case presentation matrix and 21-panel opening pass, and the supplied month and hover workflows pass. The full known-record suite passes all 12 applicable checks (`output/preview-september-fixture-final/results.json`), including missing/zero, partial quarters and multiple series.
- Screenshot review: narrow monthly and quarterly hospital charts and wider quarterly layouts were inspected directly; labels are complete, retain edge margins and do not collide. Other recorded screenshots remain available in the test folders. Do not describe all new screenshots as manually inspected.
- Deployed: stable full September month controls are public; the updated custom development build remains local. Remaining regressions and refreshed films are required.
- Client ownership: `CLIENT-HANDOVER.md` adds the no-Git editing/versioning procedure. UI export/edit/restore rehearsal and client-role validation remain open.

## Iteration 1 — Entry and navigation

- Implemented: the overview recommends September and places its login beside the link. Both visible passwords have copy icons.
- Validated: five overview browser checks; desktop and mobile login screenshots inspected.
- Deployed: overview revision `c66ba15d39ceb8541a4afca38f1efe2da375b834`; dashboard/runtime unchanged by that publication. Documentation PR #12 remains open at this checkpoint.
- Validated locally: all nine section links preserve the page, filters and results; all nine destination screenshots were inspected. The scoped scroll margin keeps headings below the fixed toolbar. Two instructional blocks were clipped; their height has been increased locally and needs a fresh screenshot check.
- Remaining: publish and verify the scroll-margin and instruction-spacing changes with the selected dashboard release.

## Iteration 2 — Hospital selection and totals

- Implemented locally: Cohort / Month / Last year / All locations; empty lower Your hospital; explicit prompts in four lower hospital panels and two latest-month comparison tables; one numeric hospital required by each affected query.
- Validated locally: opening, selection, clear and reselect without reload; hospital 53's total is 980, independently counted from eligible current and historical records. Existing dashboard definitions remain unchanged by import.
- Reporting-rule acceptance reopened: the screenshot identifies hospital 53, and the manual/dictionary define all-time counting. A read-only source audit finds 980 distinct historical rows and no current rows for 53. The derivation/source behind the requested 500 is still unknown. Hospital-specific transition management is documented; the notes say Maria will supply dates, and no approved schedule was found in reviewed sources. See [the source audit](reports/client-update-audit-2026-09-11.md#source-rule-findings). Existing tests establish the supplied-data result only.
- Deployed: main review candidate at `9f7d15d`; public evidence and remaining checks are listed above.
- Remaining: retain these cases in the full regression and verify publicly. The filter's `enableEmptyFilter` setting must remain false: true makes it required and disables the entire Apply button while empty. Query guards enforce the panel requirement without blocking cohort date changes.

## Iteration 3 — Labels and presentation

- Implemented locally: all monthly ticks, vertical labels, dynamic quarter/year labels, whole-percentage table presentation, latest reporting month wording and labelled all-time cards.
- Validated: custom source tests and reproducible image builds. All 99 date-axis geometry and complete-label cases now pass at 1024/1280/1600 on both custom bases. Lower comparison datasets omitted calendar rows: the two count datasets now retain missing periods, and all date charts retain empty columns. Eight read-only numerical cases compare every observed count and antibiotic rank against the original queries in both demo databases; all pass after correcting a duplicate-calendar defect found by that test. This SQL change is local and still needs fresh renderer validation.
- Deployed: main review candidate at `9f7d15d`; public evidence and remaining checks are listed above.
- Remaining: inspect every affected axis at 1024, 1280 and 1600 pixels, including all monthly ticks, chart-edge bounds, hover labels and multiple series. Validate the same shared renderer changes on the snapshot.

## Iteration 4 — Regression, evidence and public release

- Remaining: complete numerical and interaction tests; import/update checks; reviewed repository revision; no-reseed deployment with previous images and metadata retained; public route/login checks; refreshed dashboard-only films and inspected frames; overview claims tied to that tested release.
- Retain explicit checks for missing versus zero, February–March excluding January when grouped into Q1, both filter-selection orders, clearing/reselecting on the same page and saved defaults.
- Main Time Unit choices remain an instance-wide workaround; the pinned snapshot's independent menus are native upstream behavior. Import-helper success remains distinct from native importer behavior.
- Beth's review is separate from implementation and automated acceptance. Do not mark it accepted until she reviews it.

## Evidence map

| Concern | Automated check | Screenshot/recording source |
| --- | --- | --- |
| Entry, matching logins, password copy | `e2e/site/overview.spec.mjs` | Local/public overview screenshots; no published website video |
| Local section links | `e2e/navigation/toc.spec.mjs` | Nine destination screenshots |
| Cohort-first opening and guarded hospital total | `e2e/acceptance/cohort-first.spec.mjs` | Workflow 09 |
| All 21 panels at opening | `e2e/acceptance/presentation.spec.mjs` | Opening panel gallery |
| Complete readable date axes | `presentation.spec.mjs`, `workflows.spec.mjs` | Three widths × three grains × eleven axes; workflow 02 |
| Missing values, partial quarters, multiple series | `fixture.spec.mjs`, `multiple-series.spec.mjs` | Workflows 03 and 06 |
| Lower comparison calendar rows preserve counts and ranking | `scripts/test_calendar_breakdowns.py` | `output/calendar-breakdown-verification.json`; lower-axis screenshots |
| Unmodified build comparison | `native-comparison.spec.mjs`, `scripts/verify_standard_assets.py` | Actual labels and explicit gaps in `output/native-*/`; capture success is not exact-format acceptance |
| Date/unit order and same-page recovery | `filter-recovery.spec.mjs` | Workflow 04 |
| September additions and reporting month | `reconciliation.spec.mjs` | Workflow 08 |
| Transfer and preserved definitions | `scripts/verify_import.py`, `scripts/test_update.py`, `scripts/reconcile.py` | Import receipts and definition fingerprints |

Update implemented, validated and deployed statuses separately after each iteration. Passing a reproduction of a defect is not a fix.

## Public screenshot and evidence iteration

- Public custom full supplied-data suite: 10 applicable tests passed, 3 fixture/other-profile skips (`output/public-custom-complete/results.json`). All 99 width/grouping/axis cases pass; opening, all eleven hover formats, hospital guards, both selection orders, same-page clear/reselect, September additions and Time Unit menu pass.
- The screenshot review confirms complete x-axis labels. It also identifies a separate presentation defect: the long antibiotic-count y-axis title approaches/overlaps its legend in narrow monthly charts. Record and correct its spacing before calling every chart's presentation complete.
- Official fixture checks pass for missing/zero and partial-quarter results (10 submissions), plus both hospital series across the year boundary. The new official demonstration verifies its native date editor and actual year-first labels.
- Evidence tooling now targets the full custom and official September dashboards, records runtime and test revisions separately, and supports each matching viewer account. Films require assertion success, encoded-frame validation and visual inspection before publication.
- CI adds stable/development official comparison jobs. The preceding custom run has passed source, website and redirect checks and is building the runtimes. New job execution and final results remain pending.

### Current evidence package prepared

- All 99 public axis screenshots were inspected through 18 contact sheets, with individual images checked where needed. The narrow antibiotic-count title finding remains recorded; complete x-axis labels pass. Review hashes: `output/public-custom-screenshot-review/review.json`.
- All nine public contents links pass with unchanged document, selections and chart results (`output/public-september-toc/results.json`).
- Six public workflow films passed their assertions and encoded-image checks: custom labels/month controls/hospital totals; official missing-versus-zero/filter recovery/native-control comparison. All seven contact sheets and representative full-size frames were inspected. The films have 50 checked frames in total.
- The generated evidence page passes six-video browser playback and desktop/mobile layout checks. Overview/comparison navigation still passes all six tests. The new artifact is ready for evidence-only publication; it does not change dashboard definitions or data.

### Published and verified

- Evidence-only publication `dd35db71a56cfb85bca6295ee2ed4965110e836f` completed at 21:05 UTC. Main and official runtime/definitions remain `9f7d15d`. The previous site is retained unchanged.
- `output/evidence-smoke-public/playback.json`: all six videos decode, play and seek over HTTPS; 1280/390 layouts fit. `output/site-current-evidence-public.log`: six website checks pass.
- Public index, comparison, evidence index and evidence manifest match the publication's SHA-256 hashes. Video byte-range request returns HTTP 206 with the exact requested 32 bytes.
- The initial local seek failure was specific to Python's basic preview server returning 200 rather than range responses. Identical assertions pass on a range-capable local server and public Caddy. No film or dashboard data was changed to make that check pass.
- CI run `34647263047` remains active. Source is in PR #13. Narrow antibiotic title spacing, complete remaining coverage and client editor handover remain open; technical/client completion is not declared.

## Spacing and regression iteration

- Public custom fixture: all 12 applicable tests pass, with one supplied-data-only skip (`output/public-custom-fixture-complete/results.json`). This includes missing/zero, partial quarters, multiple series, both filter orders, clear/reselect, 21 panels and all eleven date formats.
- Implemented: increase only the two antibiotic comparison panel heights, preserving their wording, layout positions and measures. The spacing assertion detects the published overlap at 1024/1280; updated local custom and official packages pass. Source preservation remains 636 passing assertions; import/update preserves SQL, bindings, scopes and identities on both stable options.
- The 99-case complete-label matrix belongs to the September release. The preserved April comparison has older lower-chart settings and is not promoted by that matrix; its existing functional tests continue. CI must execute the strict matrix on the full September packages.
- Native browser checks now verify a selected option and wait for Apply to enable. More filters closes on document scroll in the upstream source, so browser positioning must finish before opening it. CI failures remain unresolved until the revised checks run successfully; no product recovery fix is inferred solely from harness changes.
- A definition-only review deployment path retains the current runtime and database, backs up Superset metadata, imports the versioned packages and verifies each package. It does not rebuild or reseed.
- Deployed state remains runtime/definitions `9f7d15d` and overview/evidence `dd35db7` until the spacing increment is published and verified. Remaining: complete CI, native comparison gaps, client editor rehearsal, reviewed source and the final Beth checklist.

- Latest local checks: the custom September 99-case matrix and title spacing pass; official stable matrix/recovery/hospital checks pass; unmodified development recovery/hospital checks pass with its actual Ant Design 6 markup. The new option-state assertion is retained across both versions. CI still needs a fresh run.
- Redirect validation now uses a Docker-assigned port and checks its own readiness response. All eight routes pass; a preceding local failure contacted the separate video-preview server on the former fixed port, not Caddy.

## Public spacing update and evidence review

- Deployed: definitions `d66d09e` to main and official public instances; runtime `9f7d15d` unchanged. Four packages per instance imported and verified, with separate metadata backups.
- Validated: public custom title spacing at three widths, all 99 date-axis cases and the 21-panel opening (five tests). All 18 contact sheets were inspected, plus the original 1280px hospital chart. X-axis labels and title spacing pass. Some All/Inv legend controls clip at 1280/1600 and remain open.
- Official public title spacing passes at all three widths; hospital guards/980/clear-reselect and all-21-chart opening pass. Recovery passes after measuring the visible Select surface rather than its variable-width search input. A zero-scale opening animation had allowed an early click to scroll and close the overflow menu. These are assertion synchronization changes, not a Superset filter repair.
- Prepared: refreshed screenshot artifact and existing six reviewed films; runtime and definition revisions recorded separately. Local six-video playback/seeking and six website tests pass.
- Remaining: publish/verify evidence, complete CI, legend controls, development renderer spacing, native month-selector alternative and client editor rehearsal.

- Native development now passes all three title-spacing cases plus hospital and filter recovery (five tests, `output/native-surface-development/results.json`). Its legend is rendered in HTML, so the assertion measures HTML legend bounds and canvas title bounds in the same chart coordinates. The six new public official and six local development chart captures were inspected.

- The exact linked-snapshot date-axis workflow now passes (`output/linked-preview-selection/results.json`). Ant 6 single-select stores its value on the content element; selecting that same value makes no change, so Apply correctly remains disabled. The helper reads the saved value before deciding whether an update is required.
- Both downloadable packages contain 21 charts, six datasets, one dashboard and one connection template. They are produced by the same deterministic asset packer as deployment and contain definitions rather than records.

## Published evidence and navigation checkpoint

- Public overview/evidence revision: `d9c7f0ae0a4bd937af2c4a79e8a7be1414c2d7fd`, published September 11 at 22:02 UTC. Runtime remains `9f7d15d`; definitions remain `d66d09e`. The prior immutable overview remains available for rollback.
- All 50 published artifact hashes match. Both downloadable ZIPs have 21 charts/six datasets; byte-range playback returns HTTP 206. Receipt: `output/publication-spacing-verification.json`.
- Public six-video playback/seeking and desktop/mobile checks pass (`output/evidence-spacing-public/playback.json`); all six website checks pass (`output/site-spacing-public.log`).
- All nine contents links pass again after the chart-height change with unchanged page, filter selections and chart results (`output/public-spacing-toc/results.json`).
- CI run `34652162752` tests the new source revision. Its predecessor had three failed jobs and one still-running stable job cancelled by the new push. The targeted fixes have local/public evidence above; a complete CI pass remains required.
- Next corrections: the stable-build antibiotic legend controls; explicit native month-selectors feasibility; client editor export/restore rehearsal; remaining reporting-source questions and Beth review.

- The nine new section-destination screenshots were inspected through three contact sheets; headings are visible, and empty hospital panels carry selection guidance. Review: `output/public-spacing-toc/review.json`.

## Native selectors and legend iteration — September 11

- Implemented locally: use Superset's scrolling legend for the two antibiotic charts. The previous 1600px assertion reproduces clipped All/Inv controls; all nine custom Month/Quarter/Year × width checks now pass. Official monthly checks pass at all three widths. Reviewed 24 chart screenshots (`output/legend-scroll-review.json`). No runtime or measure change.
- Implemented locally: separate official `standard-month-selectors` packages, with 21 charts, six datasets and seven filters. Inclusive native From/Through dropdowns feed the existing pre-aggregation SQL. Complete-year option calendars avoid excluding January when observations start later in the year. Source preservation: 150 additional assertions. Import/update and cached scopes match.
- Validated: native horizontal fixture passes selection order, same-page clear/reselect, saved defaults, missing/zero and partial-quarter examples (three tests, `output/native-months-horizontal/results.json`). Native vertical same-hospital recovery fails and is explicitly retained as a gap. The supplied-data native candidate also passes 14 checks: all 21 panels, hospital 53 total 980 and clear/reselect, saved defaults, both selection orders, nine legend cases, and the 99-axis observation matrix. The 99 native captures still need visual inspection before publication as reviewed evidence.
- CI `34652162752` is terminal with all four jobs failing. Stable custom failures include a disabled Apply assertion during hospital reselection and a 7.82px date-label gap against the 8px minimum. Snapshot adds legend/title spacing and similar tight labels. Native jobs include pointer/overflow-menu interaction failures. Downloaded artifacts remain under `output/ci-d9-*-artifact`; none is counted as acceptance.
- Current pointer checks hit-test the visible option without automatic scrolling, retain selected-state assertions, and avoid toggling a value already selected after the popup opens. Required numerical checks are unchanged. The exact custom recovery failure is now diagnosed: required From/Through fields are blank after Clear all, so Apply must remain disabled while staging the hospital selection. Staging that selection and then restoring both months passes the original numerical and same-page assertions (`output/custom-required-month-recovery/results.json`). No application behavior or numerical acceptance was weakened.
- Deployed: no new public changes in this iteration yet. Public runtime remains `9f7d15d`, definitions `d66d09e`, overview/evidence `d9c7f0a`. Native month selectors and scrolling legends require reviewed publication and matching evidence after validation.
- Remaining: complete this iteration's browser checks and publish; fix CI spacing/recovery failures; establish native default/inverted-range behavior; run the client-editor handover rehearsal and finish Beth's review checklist. No production or reporting-data changes.
