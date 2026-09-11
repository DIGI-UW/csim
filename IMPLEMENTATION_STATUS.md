# CSiM delivery and verification

The separately identified [September version](RECONCILIATION.md) incorporates Beth’s current test presentation and latest-data card while preserving the established 20-chart dashboard. It has 21 charts and six independent dataset definitions; the snapshot examples remain unchanged.

The acceptance contract is in [PLAN.md](PLAN.md). This records delivery status; the public explanation is [CSiM dashboard issues and solutions](https://design.csim.uwdigi.org/).

## Running versions

| Component | Address | Source revision |
| --- | --- | --- |
| Main full dashboard | [Released build](https://dashboard.csim.uwdigi.org/superset/dashboard/csim-individual-corrected/) | `34d426f5534ccdbe4c531a65239280040423bbfd` |
| Original snapshot controls | [Snapshot dashboard](https://preview.csim.uwdigi.org/dashboard/csim-individual-preview/) | `34d426f5534ccdbe4c531a65239280040423bbfd` |
| Inclusive month controls | [Second full dashboard](https://preview.csim.uwdigi.org/dashboard/csim-individual-simple/) | Same snapshot build |
| Overview and eight workflow recordings | [Overview, logins and evidence](https://design.csim.uwdigi.org/) | [Published release identity](https://design.csim.uwdigi.org/release.json) |

Main uses Superset 6.1.0 with the opt-in CSiM formatter and vertical-sidebar clear fix. The snapshot is pinned to upstream `e22ce197866ded732e4990063ae74697d89d383a`, with the formatter, inclusive month controls and vertical-sidebar clear fix. [Release details](https://design.csim.uwdigi.org/release.json) identify the actual running image IDs. The screenshot gallery and workflow recordings identify the tested source revision separately from documentation-only changes.

All four hostnames use HTTPS. `csim.uwdigi.org` redirects to main; the old Catalyst paths redirect to the corresponding new instances, preserving the checked dashboard and login return destinations. The preceding images, metadata/configuration backups and overview release remain available for rollback.

The new version offers From month, Through month (inclusive) and Group by Month/Quarter/Year. It retains the full 20-chart layout and six shared dataset definitions. The initial range is November 2025–April 2026. The familiar-control dashboards retain Last year and Month. All three full-dashboard views start with hospital 53; the known-record examples start with hospital 91. The unchanged baseline retains Cohort.

## Reproduction and definitions

- Private DIGI-UW/csim contains the standalone implementation and attribution to harness PR 111 at `fa86f2d1a1c1883ee516887779111b3106d3dd4e` (Piotr Mankowski).
- Original April, September test and September production exports are preserved with checksums and a UUID-based comparison. April is the selected 20-chart/six-dataset technical baseline. September test's extra card is excluded.
- The supplied demo dump restores in isolated PostgreSQL 14.24. The unchanged baseline, corrected dashboard, generated numerical fixture and snapshot run locally. Normal updates do not reseed.
- Import checks compare SQL, calculated columns, metrics, chart settings, layout, defaults, bindings and cached filter scopes. Updates to existing definitions and restoration pass without duplicate objects. Main uses a deterministic reference-repair helper; the snapshot remaps the checked references natively.
- The public snapshot's familiar-control and simpler-control dashboards, including their known-record copies, each match 20 charts, six datasets and six filters; all imported filter scopes match destination chart IDs.
- Application-level read-only checks of `34.223.100.228:8088` identified Superset 6.1.0 and enabled template processing; see `sources/test-instance-configuration.json`. Host-level configuration is not established by that application check.

## Validation

Public browser checks on September 11, 2026 UTC, against deployed source `34d426f5534ccdbe4c531a65239280040423bbfd`:

| Dashboard and data | Passed | Not applicable |
| --- | ---: | ---: |
| Main, supplied demo | 7 | 4 |
| Main, known records | 10 | 1 |
| Familiar snapshot, supplied demo | 7 | 4 |
| Familiar snapshot, known records | 10 | 1 |
| Simpler controls, supplied demo | 5 | 2 |
| Simpler controls, known records | 7 | 0 |

The public suite captures every opening panel and all eleven date axes at 1024, 1280 and 1600 pixels. It measures real painted text, including both endpoint labels and the spacing between labels. The six stacked chart legends sit above the plots. All twenty supplied-data panels contain useful content with hospital 53 selected; missing observations remain gaps.

Date/filter checks cover Month, Quarter and Year axes and hover details, chronological multiple series, missing versus zero values, partial quarters, both selection orders, clearing/reselecting on the same page, and saved defaults. Filter recovery compares all five trend results before and after clearing. Hospital 91 must retain exactly **4, 8, 12, missing, 10 and 5** monthly submissions. February–March grouped as Quarter or Year contains **10** submissions; January contributes none. Invalid or incomplete month ranges cannot be applied.

The main build passes **64** formatter/transformation/sidebar tests. The snapshot passes **170** formatter/transformation tests plus **10** month-control/sidebar tests. Both server import and changed-definition update checks pass with all twenty destination chart identifiers different from the source, no duplicate objects and all cached filter scopes correct.

The [screenshot gallery](https://design.csim.uwdigi.org/evidence/screenshots/) groups the public chart captures by concern. All eight workflow recordings were refreshed from the same runtime source and visually reviewed. Their 63 encoded checkpoints match the asserted screenshots. Recordings use introduction/section screens, persistent captions and deliberate reading holds; website navigation is not published as video.

GitHub CI and Beth's usability acceptance remain separate from these completed manual/public checks. Consult [Actions](https://github.com/DIGI-UW/csim/actions) for the current CI state.

## Remaining acceptance and scope

- Beth's acceptance is pending. Use the [review checklist](https://design.csim.uwdigi.org/#review): compare Month/Quarter/Year labels, select February–March, check partial-period wording, clear/reselect the same hospital, and review the preserved layout and measures.
- Exact historical production identity for the April export remains unconfirmed.
- The source table-of-contents permalinks and historical intermittent authoring/navigation reports are not fixed by the date-control work. Their disposition is in [REPORT-COVERAGE.md](REPORT-COVERAGE.md).
- Main's Time Unit restriction remains instance-wide. Independent saved menus are demonstrated on the pinned development snapshot; the new month fields are a versioned customization.
- Production changes and WordPress integration remain outside this deployment.
