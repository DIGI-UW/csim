# Install the individual-record review table

This optional saved table combines Current and Historical submissions, keeping
record_ID from both sources and redcap_repeat_instance from Current (blank for
Historical). It does not change UTI Aggregate ALL DATA or its calculations.

The SQL is built from review/record-review.sql using the client source names in
dashboard/client-update/manifest.json. It contains a SELECT query only, no database
connection or import definition. Run scripts/prepare_record_review.py to rebuild.

## One-time setup by a Superset editor

1. Open Datasets → UTI Aggregate ALL DATA → Edit → SQL. Check which physical
   Current and Historical tables its FROM clauses read. The supplied production
   export uses v1."UTI Individual Current" and
   v1."UTI Individual Historical 2024-2025". The review SQL uses those same names.
   If the live query reads a different table, confirm that table's columns before
   changing the review SQL. Do not change the existing aggregate query.
2. Open SQL → SQL Lab. Select the existing PostgreSQL connection and schema v1.
   Paste csim-record-review.sql and run it. Do not create or edit a connection.
   If a required column is missing, resolve the source schema before continuing;
   do not remove the identifiers or substitute invented values.
3. Save the result as a new virtual dataset named UTI Individual — Record review
   using the results panel's Explore / Save dataset action. A saved SQL query
   alone is not a dataset. Keep the complete SQL, without adding a LIMIT clause.
4. Create a Table chart from that dataset. Choose Raw records, all 20 columns,
   Time range = No filter, and no other filters. Set Row limit = 100000 and
   disable server pagination. Page length 20 is only the display size.
5. Save the chart as Individual records — Review and download, without adding it
   to the main dashboard. Bookmark its URL. In the dataset's Advanced settings,
   set Cache timeout to -1 (disable caching). Give the intended reviewers access
   to this new dataset through their existing role.
6. Before the first full export, run SELECT COUNT(*) FROM (<the supplied query>)
   AS records in SQL Lab. Confirm the exported CSV has that many data rows
   (excluding the header). Check that Current and Historical are both present,
   with their source identifiers. If the result exceeds 100000 or the server
   applies a lower limit, an administrator must adjust the limit or provide
   separate exports; do not treat a truncated file as complete.

## After each upload

Open the saved chart → Update chart → ⋯ → Data Export Options → Export All Data
→ Export to .CSV. Do not use Export in the Datasets list: that exports the
dataset definition as YAML, not its records.

This reads the latest contents of the same physical tables after refresh.
Uploading into a new table name does not redirect existing saved queries.
The file has individual review records and selected fields, not monthly totals
or every field from the REDCap export. Source plus record_ID plus repeat instance
provides context for checking records; no uniqueness or deduplication is assumed.

Online instructions: https://design.csim.uwdigi.org/install.html#record-review
Demonstration: https://design.csim.uwdigi.org/record-export.html
