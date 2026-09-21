# Download the aggregate dataset

Open **Aggregate ALL DATA — Download** from the administrator's Charts list or
saved bookmark. It is intentionally absent from the hospital-facing dashboard. It is a standalone
Table chart using the existing UTI Aggregate ALL DATA virtual dataset. It is not
another database table, and dashboard selections are not carried into it.

After uploading Current, open this table and click **Update chart** to refresh its results.
Open **⋯ → Data Export Options → Export All Data → Export to .CSV**.
No SQL Lab query is needed. Raw records means the rows produced by the aggregate
dataset's saved SQL, including its existing cohort, state and hospital rows. The
chart adds no new aggregation, date restriction, hospital restriction or location
restriction. It includes all 25 dataset columns, including the calculated period
label. The dataset's own source inclusion rules still apply.

The saved chart has a 100,000-row limit, compared with the instance default of
5,000. The supplied demonstration database currently produces 9,801 aggregate
rows without date restrictions. Verify the CSV row count against the full query
when refreshing a substantially larger source; a finite row limit is not an
unlimited export promise.

The download chart is included in the dashboard asset package but is deliberately
absent from its layout and filter scopes. Importing an update must preserve that
separation. The known-record example has its own download
chart against the separate fixture database.
