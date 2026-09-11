# Execution status

The acceptance contract is in PLAN.md. This file records implementation and verification; it is not the public problem explanation.

## Implementation and local validation

- Sources preserved, hashed and compared: April 20 charts/6 datasets, September test 21/6, September production 20/6. April is the selected technical baseline; its exact historical production identity is unconfirmed.
- The standalone project is in private DIGI-UW/csim, with attribution to harness PR 111 at fa86f2d1a1c1883ee516887779111b3106d3dd4e (Piotr Mankowski).
- Supplied demo data restores in isolated PostgreSQL 14.24. The unchanged baseline, corrected dashboard, independent numerical fixture and pinned snapshot run locally. Normal updates do not reseed.
- The opt-in formatter covers all eleven date axes and hover labels. Main unit suites passed 62 tests; snapshot suites passed 28. Browser checks cover Month/Quarter/Year, multiple series, partial quarters, missing versus zero values, both filter selection orders and same-page recovery.
- Exact import checks cover 20 charts, six datasets, SQL, calculated columns, metrics, settings, layout, defaults and scope caches with different destination chart IDs. Changed-definition updates and restoration passed on both builds. Main uses a deterministic cached-reference helper; the snapshot remaps those references natively.
- Seven dashboard recordings passed their workflow assertions. Every recording has captions, major section screens, encoded-frame checks and visually reviewed contact sheets. Website tests run without published video.
- The assembled overview, matching logins, evidence, downloads and mobile layout passed local browser checks. The final GitHub matrix runs both builds with supplied data and the numerical fixture, without video.
- Read-only access to 34.223.100.228:8088 confirms runtime 6.1.0 and enabled template processing. See sources/test-instance-configuration.json. The local AWS session is expired, so host-level configuration is not confirmed by this check.

## Public release and inclusive month version

- Release 149e281 is deployed at dashboard.csim.uwdigi.org and preview.csim.uwdigi.org; design.csim.uwdigi.org serves the overview, matching viewer logins, seven reviewed recordings and definition download. All four certificates are issued. PR 1 is merged; its main-branch regression run 34556580482 passed.
- Main public supplied and fixture acceptance passed. Snapshot query/date tests passed, but screenshot inspection exposed its migrated table renderer being disabled; query success alone was insufficient. The follow-up enables the snapshot renderer and adds visible-error/table assertions.
- The second snapshot dashboard uses From month, Through month inclusive and Group by, with partial-period notes. It preserves the existing dashboard and six shared dataset definitions. MONTH_CONTROLS.md records its commands and acceptance.
- Nine month-control component tests and 169 snapshot formatter/transformation tests pass. Local browser checks cover the control, invalid input, same-page Clear all recovery, the one-quarter axis extent, and all 20 charts. Full data-profile checks, public rollout and the eighth recording are being completed.
- Metadata initialization now runs before web workers start, addressing the observed first-start SQLite WAL lock. Normal updates do not restore reporting data.

Remaining: finish the new variant's public checks and reviewed recording; publish the revised overview/evidence; activate and check old-path redirects. Beth's acceptance remains separate. April's historical production identity remains unconfirmed; inherited source permalinks are not corrected by the date-control work.
