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

## Remaining delivery checks

- Finish the full GitHub matrix and merge the tested implementation.
- Initialize the new main and snapshot server instances; preserve existing stacks for rollback.
- Publish the overview and seven recordings with the deployed viewer logins and release identity.
- Validate the four new HTTPS hostnames, both deployed dashboard/data profiles, generated links, downloads and independent sessions. Enable and check legacy redirects afterward.
- Record final delivery evidence and provide Beth's review checklist. Beth's acceptance remains separate from implementation and automated validation.

The new public release is not yet deployed. The existing public dashboard and overview remain in place until the deployment checks above pass.
