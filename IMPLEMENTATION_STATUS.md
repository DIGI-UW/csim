# CSiM delivery and verification

The acceptance contract is in [PLAN.md](PLAN.md). This records delivery status; the public explanation is [CSiM dashboard issues and solutions](https://design.csim.uwdigi.org/).

## Running versions

| Component | Address | Source revision |
| --- | --- | --- |
| Main full dashboard | [Released build](https://dashboard.csim.uwdigi.org/superset/dashboard/csim-individual-corrected/) | `149e281fedecefc1c443cd4f676eec98b6222992` |
| Original snapshot controls | [Snapshot dashboard](https://preview.csim.uwdigi.org/dashboard/csim-individual-preview/) | `ca55d4b1f8808ad7863965dd13bb171b3d441452` |
| Inclusive month controls | [Second full dashboard](https://preview.csim.uwdigi.org/dashboard/csim-individual-simple/) | Same snapshot build |
| Overview and eight workflow recordings | [Overview, logins and evidence](https://design.csim.uwdigi.org/) | `07df08175bc5cabd317673bd42ea9a18b555cc9a` |

Main uses Superset 6.1.0 with the opt-in CSiM formatter. The snapshot is pinned to upstream `e22ce197866ded732e4990063ae74697d89d383a`, with the formatter, inclusive month controls and vertical-sidebar clear fix. [Release details](https://design.csim.uwdigi.org/release.json) identify the actual running image IDs. Test and deployment-script improvements after the snapshot build do not change its dashboard or runtime files.

All four hostnames use HTTPS. `csim.uwdigi.org` redirects to main; the old Catalyst paths redirect to the corresponding new instances, preserving the checked dashboard and login return destinations. The preceding images, metadata/configuration backups and overview release remain available for rollback.

The new version offers From month, Through month (inclusive) and Group by Month/Quarter/Year. It retains the full 20-chart layout and six shared dataset definitions. The initial range is November 2025–April 2026. The familiar-control dashboards retain Last year and Month. Both full versions start with hospital 53; the known-record examples start with hospital 91. The unchanged baseline retains Cohort.

## Reproduction and definitions

- Private DIGI-UW/csim contains the standalone implementation and attribution to harness PR 111 at `fa86f2d1a1c1883ee516887779111b3106d3dd4e` (Piotr Mankowski).
- Original April, September test and September production exports are preserved with checksums and a UUID-based comparison. April is the selected 20-chart/six-dataset technical baseline. September test's extra card is excluded.
- The supplied demo dump restores in isolated PostgreSQL 14.24. The unchanged baseline, corrected dashboard, generated numerical fixture and snapshot run locally. Normal updates do not reseed.
- Import checks compare SQL, calculated columns, metrics, chart settings, layout, defaults, bindings and cached filter scopes. Updates to existing definitions and restoration pass without duplicate objects. Main uses a deterministic reference-repair helper; the snapshot remaps the checked references natively.
- The public snapshot's original and both new dashboards each match 20 charts, six datasets and six filters; all imported filter scopes match destination chart IDs.
- Application-level read-only checks of `34.223.100.228:8088` identified Superset 6.1.0 and enabled template processing; see `sources/test-instance-configuration.json`. Host-level configuration is not established by that application check.

## Validation

Public browser checks on September 11, 2026 UTC:

| Dashboard and data | Passed | Not applicable |
| --- | ---: | ---: |
| Main, supplied demo | 5 | 3 |
| Main, known-record fixture | 7 | 1 |
| Original snapshot, supplied demo | 5 | 4 |
| Original snapshot, known-record fixture | 7 | 2 |
| Month controls, supplied demo | 3 | 2 |
| Month controls, known-record fixture | 5 | 0 |

The main results are from the unchanged main deployment's earlier public run. Both original snapshot profiles and both month-control profiles were checked after the new snapshot deployment. All applicable public cases passed. These cover the twenty chart renderers, eleven date axes and hover labels, chronological multi-series data, missing versus zero values, partial periods, both selection orders, clear/reselect and defaults.

The new clear/reselect test asserts that hospital 91 remains selected and that monthly submissions are exactly **4, 8, 12, missing, 10, 5**. February–March grouped as Quarter or Year contains **10** submissions; January contributes none. The Year recording waits for the drawn 2026 label and the result before capture. Invalid or incomplete month ranges cannot be applied.

The snapshot build passes 10 month-control/sidebar tests plus 169 formatter/transformation tests. The public overview passes navigation and phone-layout tests; all eight recordings have captions, section screens, paced holds, encoded-frame checks and inspected contact sheets. Only dashboard workflows are published as videos. Main/snapshot logins, independent cookies, forty generated chart links, the month-control login return and the exported-bundle checksum pass public checks.

Two transient checks are retained in local diagnostics: one fixture tooltip did not open during a local run, and one public post-login chart-load check timed out. Both passed on unchanged rechecks; neither is evidence of a repaired historical intermittent defect. The latest GitHub matrix is separate from the completed manual/public validation; consult [Actions](https://github.com/DIGI-UW/csim/actions).

## Remaining acceptance and scope

- Beth's acceptance is pending. Use the [review checklist](https://design.csim.uwdigi.org/#review): compare Month/Quarter/Year labels, select February–March, check partial-period wording, clear/reselect the same hospital, and review the preserved layout and measures.
- Exact historical production identity for the April export remains unconfirmed.
- The source table-of-contents permalinks and historical intermittent authoring/navigation reports are not fixed by the date-control work. Their disposition is in [REPORT-COVERAGE.md](REPORT-COVERAGE.md).
- Main's Time Unit restriction remains instance-wide. Independent saved menus are demonstrated on the pinned development snapshot; the new month fields are a versioned customization.
- Production changes and WordPress integration remain outside this deployment.

## Presentation update acceptance

The current source adds measured label spacing at three browser widths, top
legends for the six stacked date charts, and an opening selection with useful
content in every panel. Supplied-data dashboards start with hospital 53;
known-record dashboards start with hospital 91. An unavailable comparison in a
populated table is distinct from an empty panel.

The formatter builds pass 63 main tests and 170 snapshot tests, plus 10 snapshot
month-control/sidebar tests. Both import/update checks preserve all twenty
charts and six datasets. The stricter screenshot suite and refreshed public
recordings are undergoing validation before publication.
