# CSiM Individual Data dashboard

The separately identified [September version](RECONCILIATION.md) incorporates Beth’s current test presentation and latest-data card while preserving the established 20-chart dashboard. It has 21 charts and six independent dataset definitions; the snapshot examples remain unchanged.

Versioned CSiM dashboard definitions, demo data, deployment tooling, and browser
evidence for date labels and Time Period filtering.

The selected baseline contains 20 charts and six datasets from the April 2026
export. September test and production definitions are preserved alongside it.
See [the source comparison](sources/README.md) and [implementation plan](PLAN.md).

Public links: [main dashboard](https://dashboard.csim.uwdigi.org/), [snapshot](https://preview.csim.uwdigi.org/), and [overview and logins](https://design.csim.uwdigi.org/).

The snapshot also supports a [second dashboard with inclusive month controls](MONTH_CONTROLS.md). It retains the full report and original snapshot dashboard.

The corrected full dashboards start with hospital 53, which supplies useful
content in all twenty panels. Worked examples start with hospital 91. Cohort is
still available, but hospital-specific comparisons and totals require an
individual hospital. Saved filter links restore their saved selections.

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

The corrected build adds an opt-in `csim_period` formatter to Superset 6.1.0.
The source patch, exact upstream source revision, runtime driver, and build tests
are versioned here. All chart axes retain real dates. Dashboard SQL consumes the
time filter before grouping observations and adding calendar rows.

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
