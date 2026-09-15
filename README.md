# CSiM Individual Data dashboard

The separately identified [September version](RECONCILIATION.md) incorporates Beth’s current test presentation and latest-data card while preserving the established 20-chart dashboard. It has 21 charts and six independent dataset definitions; the snapshot examples remain unchanged.

Versioned CSiM dashboard definitions, demo data, deployment tooling, and browser
evidence for date labels and Time Period filtering.

The selected baseline contains 20 charts and six datasets from the April 2026
export. September test and production definitions are preserved alongside it.
See [the source comparison](sources/README.md) and [implementation plan](PLAN.md).

Public links: [recommended official Superset dashboard](https://standard.csim.uwdigi.org/superset/dashboard/csim-individual-standard-month-selectors/), [custom alternative](https://dashboard.csim.uwdigi.org/), [custom snapshot alternative](https://preview.csim.uwdigi.org/), and [overview and matching logins](https://design.csim.uwdigi.org/).

The main recommendation uses the official Superset 6.1.0 application, native
horizontal month selectors and saved dataset queries. The 21 September reporting
charts remain intact; one ordinary table chart summarizes the selected range.
The opening dates follow the last twelve complete months. A reversed range shows
an explanation after Apply and can be corrected on the same page. Year-first date
wording remains a visible difference from the custom alternative.
See [native month controls](NATIVE_CONTROLS.md) and
[current acceptance](RELEASE-ACCEPTANCE.md) for tested and deployed behavior.

The snapshot also supports a [second dashboard with inclusive month controls](MONTH_CONTROLS.md). It retains the full report and original snapshot dashboard.

The corrected full dashboards start with hospital 53, which supplies useful
content in all twenty panels. Worked examples start with hospital 91. Cohort is
still available, but hospital-specific comparisons and totals require an
individual hospital. Saved filter links restore their saved selections.

The pending September update instead opens with Cohort and leaves the lower
hospital selection unset. Query guards prevent unset hospital panels from
combining hospitals. This does not change the established 20-chart comparison.

The separate full September month-control candidates retain 21 charts and six
datasets. Their default is the last 12 complete months, recalculated on each fresh
load. From month and Through month include whole months; changing Month, Quarter
or Year never widens that window. The known-record version keeps a fixed window.
These candidates are local until the acceptance record identifies a public release.

See [screenshot checks](https://design.csim.uwdigi.org/evidence/screenshots/) for
opening panels, label spacing, grouping, filter recovery and numerical examples.

## Local commands

Docker Compose, Ruby, Python 3, and Node.js are required.

```sh
ruby scripts/verify_sources.rb
ruby scripts/prepare_dashboard.rb
bash csim.sh baseline init
bash csim.sh corrected init
bash csim.sh fixture init
bash csim.sh preview init
bash csim.sh preview hourly
bash csim.sh preview-fixture init
```

Initialization restores the supplied demo database, or creates the separate
edge-case database for `fixture`. It is explicit and refuses an existing schema.
Normal `update` and `import` commands do not reseed data.

```sh
bash csim.sh corrected update
bash csim.sh corrected verify-import
cd e2e
npm ci
npx playwright test -c acceptance.config.mjs
CSIM_PROFILE=fixture npm test
CSIM_PROFILE=preview npm test
CSIM_PROFILE=preview-fixture npm test
```

The local baseline uses port 18190, corrected demo 18189, and edge-case fixture
18191; the snapshot uses 18192 and its separate fixture 18193. Each has separate metadata, reporting data, and generated local credentials
in its ignored `.env.PROFILE` file. The login is `demo`.

### Unmodified application comparisons

`standard` uses official Superset 6.1.0 on port 18194; `development` uses the pinned
Apache development image on port 18195. Both add only the PostgreSQL driver and
supported configuration. Each has its own metadata and demo database. The official application is also deployed at `standard.csim.uwdigi.org`.
The separate unmodified development comparison remains local.

```sh
ruby scripts/prepare_dashboard.rb
ruby scripts/test_standard.rb
bash csim.sh standard init
bash csim.sh standard examples-init
bash csim.sh standard candidates
python3 scripts/verify_standard_assets.py standard
```

Use `development` in the same commands for the upstream comparison. Initialization
refuses an existing demo schema. Later use `update`, `examples-update` and
`candidates`; none restores data. `verify_standard_assets.py` compares every
running frontend asset with the digest-pinned Apache image.

The standard application contains a native smart-date/vertical-filter comparison
at `/superset/dashboard/csim-individual-standard/` and a sortable-SQL-label,
horizontal-filter candidate at `/superset/dashboard/csim-individual-standard-sortable/`.
Development uses the corresponding `development` slugs. Both retain all 21 charts.
The sortable wording is a proposed tradeoff, not a pass of the original exact-label
requirement. Vertical clear/reselect currently fails on both unmodified builds;
the horizontal candidate passes the tested recovery workflow.

```sh
cd e2e
CSIM_PROFILE=standard CSIM_DASHBOARD_SLUG=csim-individual-standard-sortable \
  npx playwright test -c acceptance.config.mjs filter-recovery.spec.mjs --grep '04 Time'
CSIM_PROFILE=standard CSIM_DASHBOARD_SLUG=csim-standard-sortable-examples \
  CSIM_DATA_PROFILE=edge-cases npx playwright test -c acceptance.config.mjs fixture.spec.mjs
```

Native observation reports retain their individual gaps. Successful screenshot
capture is not acceptance of the labels shown. No comparison videos are published
automatically by these commands.

### Native From / Through month comparison

The `standard-month-selectors` packages retain all 21 reporting charts and six
reporting datasets on official Superset 6.1.0. They add one native summary chart
and its dataset, for 22 charts/seven datasets in the complete package. Two native dropdowns supply inclusive month bounds to
the existing dataset queries, before aggregation. The option lists include whole
calendar years covering the reporting data, including months without observations.
No reporting tables or Superset application files are changed.

```sh
ruby scripts/prepare_native_months.rb
ruby scripts/test_native_months.rb
bash csim.sh standard native-months
cd e2e
CSIM_PROFILE=standard CSIM_NATIVE_MONTHS=1 CSIM_DATA_PROFILE=edge-cases \
  CSIM_DASHBOARD_SLUG=csim-standard-month-selectors-examples \
  npx playwright test -c acceptance.config.mjs --grep '03 Known|04 Time Period|Opening afresh'
```

This imports definitions into the already initialized instance; it does not reseed.
The supplied-data dashboard is `/superset/dashboard/csim-individual-standard-month-selectors/`.
Its saved presets resolve to the last twelve complete months; named months fix
the window. The reporting summary displays the actual dates and range guidance.
The known-record version saves November 2025–April 2026. Clearing an endpoint removes
that bound. The horizontal bar avoids the reproduced native vertical-sidebar reset
defect. Year-first chart labels remain an explicit wording tradeoff. These packages
are a comparison candidate until their full acceptance and public verification are recorded.

The corrected build adds an opt-in `csim_period` formatter to Superset 6.1.0.
The source patch, exact upstream source revision, runtime driver, and build tests
are versioned here. All chart axes retain real dates. Dashboard SQL consumes the
time filter before grouping observations and adding calendar rows.

### Full September month controls

Both custom builds use `Dockerfile.month-controls`. The main build applies
`superset-6.1.0-month-controls.patch`; the snapshot applies its separately pinned
patch through `CSIM_MONTH_PATCH`. Existing local environment files keep their
selected image until explicitly updated. After initializing the demo and example
databases, normal dashboard updates are:

```sh
bash csim.sh corrected september-months
bash csim.sh preview september-months
cd e2e
CSIM_PROFILE=preview CSIM_SIMPLE_CONTROLS=1 \
  CSIM_DASHBOARD_SLUG=csim-individual-reconciled-months \
  npx playwright test -c acceptance.config.mjs month-controls.spec.mjs presentation.spec.mjs
```

Use `corrected` for the released-base build and
`CSIM_DATA_PROFILE=edge-cases CSIM_DASHBOARD_SLUG=csim-reconciled-months-examples`
for its separate known-record dashboard. These commands do not reseed data.

Imports use Superset's native complete-assets importer so updates include SQL,
calculated columns, and chart settings. A deterministic deployment helper repairs
cached chart references left behind by the released importer. The unchanged
baseline omits that repair to preserve a comparison.

The implementation is under active acceptance testing. Local test results,
public deployment status, and Beth's review are distinct; no published release
is established merely by creating this repository.

## Linked worked examples

The main dashboard uses the supplied demo dump. A second full dashboard can be
created alongside it, using a separate `csim_fixture` database with known
missing-period and zero-value cases:

```sh
bash csim.sh corrected examples-init
bash csim.sh preview examples-init
bash csim.sh corrected viewer
bash csim.sh preview viewer
```

These explicit initialization commands refuse an existing fixture database.
Use `examples-update` thereafter; it changes definitions only. Both instances
serve `/superset/dashboard/csim-filter-examples/`. The main dashboard remains
`csim-individual-corrected` and the snapshot remains `csim-individual-preview`.
The viewer can read the supplied and example dashboards; its generated login
is in ignored `output/PROFILE-viewer.json` for publication beside the instance.

To validate a worked example through an existing instance, use
`CSIM_DASHBOARD_SLUG=csim-filter-examples CSIM_DATA_PROFILE=edge-cases`
with the corresponding `CSIM_PROFILE`. `CSIM_BASE_URL`, `CSIM_USERNAME` and
`CSIM_PASSWORD` support the same checks against a deployed viewer session.

For an explicitly authorized review update that changes only saved dashboard
definitions, use `bash deploy/review-release.sh assets FULL_REMOTE_REVISION corrected`
(and `standard` for the official comparison). This keeps the running image and
reporting data, saves a metadata rollback copy, imports the named packages and
verifies their definitions. The receipt records the assets revision separately
from the unchanged image; complete public browser checks before marking it verified.
