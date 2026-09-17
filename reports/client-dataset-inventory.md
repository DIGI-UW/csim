# Client dataset inventory and delivery boundary

September 16, 2026. Production counts below come from the dataset list supplied
by Piotr; demo counts come from the running official 6.1.0 instance's saved
object relationships. No production reporting records were accessed.

## Production list: 17 entries

- Six active virtual reporting datasets: UTI Aggregate ALL DATA; UTI Aggregate
  Overall Performance Bar Charts; UTI Inappropriate UTI Dx Comparison Table -
  Ind; UTI Abx duration comparison - Ind; UTI Top Abx - Ind; UTI Location - Ind.
- Three physical source datasets: UTI Individual Current; UTI Individual
  Historical; CSiM Hospitals and States.
- Eight explicitly archived datasets. These are existing client history, not
  obsolete demo experiments, and are outside demo cleanup.

## Official demo before source registration: 26 entries

| Group | Dataset count | Current use |
| --- | ---: | --- |
| Familiar six reporting datasets | 6 | Main dashboard, dataset IDs 13–18 |
| Reporting-period summary | 1 | Main dashboard, ID 25 |
| Known-record test example | 7 | Separate example dashboard, IDs 19–24 and 26 |
| Earlier September experiments | 12 | No current dashboard; IDs 1–12 still support 84 saved charts from retired dashboards |

All 26 entries are virtual datasets. Thirteen connect to CSiM demo PostgreSQL
and thirteen to CSiM edge-case PostgreSQL. The three required source tables
exist in the supplied demo database but are not registered as physical
datasets in this Superset list. A saved SQL dataset can query an underlying
table without that table also appearing as its own Superset dataset.

The main dashboard uses 22 charts: 21 reporting charts plus the period
summary. Its standalone aggregate-download chart uses the existing ALL DATA
dataset; it creates no extra dataset or database table. The example has an
equivalent isolated set. Including legacy charts, this instance has 130 saved
charts: 44 on current dashboards, two standalone downloads, and 84 from old
experiments. Removing the old dashboard entries preserved these charts and
their datasets; that is why gallery cleanup did not clean the dataset list.

## Current official demo list: 29 entries

The three existing upload tables are now registered as physical datasets with
the same names as production. They are dataset IDs 27–29 on the public demo.
The original 26 virtual datasets, their definitions and chart bindings remain
unchanged. Registration adds metadata, not copies of the reporting tables.

The main dashboard still uses its six reporting datasets and one period helper.
The extra example and retired datasets remain separate from the client package;
matching the production names does not by itself clean the whole demo gallery.
See the [current request checklist](beth-three-requests-2026-09-16.md).

## Published bundle versus a client update

The published official bundle contains one dashboard, 23 charts (22 on the
dashboard plus the standalone download), seven datasets and one connection
definition. It does not include the other 19 demo datasets.

However, the six main demo datasets have different persistent identities from
the corresponding datasets in the supplied production export. The connection
definition retains the production export's connection identity but contains
demo connection settings. The package is suitable for reproducing this demo;
it has not passed an update rehearsal over the client's existing objects.
It must not be presented as a ready-to-import production upgrade.

## Expected clean client delivery

1. One familiar main dashboard and its agreed charts, filter defaults, colors
   and definitions.
2. Updates to the client's existing six reporting datasets, preserving their
   identities and intended database binding. No second set with the same names.
3. The existing three physical source-table registrations and upload workflow.
4. One clearly named reporting-period helper, if retaining the current summary
   chart. It describes selections and does not hold submitted records.
5. Existing archived client datasets preserved. Demo fixtures and retired
   experimental charts/datasets excluded.
6. An update rehearsal on an isolated copy of the client definitions: first
   import, second import, unchanged source connection and tables, no duplicate
   active objects, correct filter/chart bindings, and the existing numerical
   and screenshot checks.

With the current period-summary design, that is ten active dataset entries
(six reporting, three physical sources, one helper), or eighteen including the
client's eight existing archives. Reducing the number to nine active entries
would require removing the extra period-summary chart, not changing the six
reporting datasets.

These delivery checks are still required. Working chart calculations and a
cleanly scoped demo ZIP do not by themselves establish a clean client upgrade.
