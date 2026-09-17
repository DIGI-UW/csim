# Data & records

A separate Superset dashboard explains the three uploaded tables, the reporting
queries and hospital lookup. Two summary charts show included/excluded records by
source and hospital. The detailed record table is a separate saved chart; it does
not belong to the reporting dashboard or inherit its filters.

## Contents

- **UTI Individual — Record review**: one virtual dataset reading Current,
  Historical and the hospital lookup. All uploaded rows remain visible, including
  incomplete records and hospitals missing from the lookup. No physical table is
  added and existing reporting queries are unchanged.
- **Individual records — Review and download**: raw-record Table chart containing
  `record_ID`, source, Current repeat identifiers, hospital/month/location,
  inclusion status, exclusion reason and inputs used by the aggregate measures.
- **CSiM — Data & records**: source flow, live summary tables and a link to the
  detailed chart. There is no implicit date restriction.

Record IDs are not assumed unique across files or repeats. `UNION ALL` retains
all rows. Historical repeat identifiers are NULL. A duplicate hospital lookup
code fails installation rather than multiplying records without warning.

Included means eligible before dashboard filters; a date window, location or
population selection can further narrow the reporting result. The review dataset
does not expand records into additional state/cohort or All locations rows.
Those aggregate views can refer to the same submissions. Hospital-level counts
and rate inputs can be reconciled directly; cohort rates retain the existing
weighting and must not be recomputed as a different pooled rate.

## Reproduce

```sh
bash csim.sh standard data-review
docker exec csim-standard-superset-1 python /repro/scripts/test_record_review.py
cd e2e
CSIM_PROFILE=standard CSIM_NATIVE_DATES=1 \
  CSIM_DASHBOARD_SLUG=csim-individual-standard-month-selectors \
  npx playwright test -c acceptance.config.mjs record-review.spec.mjs
```

The installer only targets the supplied demo connection. It creates or updates
its own dataset, three charts and dashboard using stable identifiers. Every other
dashboard/chart/dataset definition is compared before and after and must be
unchanged. It gives the existing demo role access to this projection of the
three demo sources it can already read. No source data is written.

Numerical tests reconcile record membership and hospital totals/rate inputs with
the saved aggregate SQL for Month, Quarter and Year, including February–March
boundaries. Repeat IDs, missing lookup, missing dates and incomplete submissions
are tested in a rolled-back transaction in the separate fixture database.
Browser checks verify the complete CSV, standalone chart, dependency dashboard
and the location of the saved aggregate SQL. CI records no video.

## Maria's query guide

In Superset, open **Datasets**, find **UTI Aggregate ALL DATA**, choose **Edit**,
then open **Source**. The opening query combines Current and Historical with
`UNION ALL`. Current requires `qi_asb_complete = 2`; both require hospital, month
and year. Later the hospital lookup is joined and totals/rates are calculated.
See the actual [query location](../design/evidence/beth-review/aggregate-query-source.png)
and [Current/Historical combination](../design/evidence/beth-review/aggregate-query-union.png)
screenshots. They were captured locally; the saved query hash exactly matches
the public instance. An editor account is needed to view this editor. Do not save a change just to
read the SQL.

The supplied demo currently has 290 Historical records for hospital codes 58–61
without matching lookup entries, plus one incomplete Current record. The review
makes these exclusions visible. It does not invent hospital names/state mappings
or change the reporting population. Hospital-specific source transition dates
are a separate request in the earlier issue notes, not a prerequisite to uploading
and showing valid records under the current SQL.

The client package needs this extra dataset and its charts if Beth accepts the
review workflow. Destination permissions must follow the client's intended data
reviewers. Demo connection settings and demo source records are excluded from
that package.
