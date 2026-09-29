## Check a hospital's records

1. Open **[Individual records — Review and download](/explore/?slice_id={{record_chart}})**.
2. Use **Filters** to choose the hospital and reporting months. Included rows contribute before the reporting dashboard's date, location and population selections. Excluded rows show the reason.
3. Review **record_ID**, **source** and **redcap_repeat_instance**. The repeat instance is blank for Historical. IDs can repeat across sources or repeat instances.
4. Use **⋯ → Data Export Options → Export All Data → Export to .CSV**. The saved table allows up to 100,000 rows. Filters narrow the export; the table's search box is only for finding displayed rows.

## See how the data is combined

In **Datasets**, find **UTI Aggregate ALL DATA**, choose **Edit**, then open **Source** to see its saved SQL (an editor account is required). The first source section reads Current, applies the completion rule, then uses **UNION ALL** to append Historical. Later sections match the hospital lookup and calculate totals and rates by hospital, location and month.

The six saved reporting datasets are **UTI Aggregate ALL DATA**, **UTI Aggregate Overall Performance Bar Charts**, **UTI Inappropriate UTI Dx Comparison Table - Ind**, **UTI Abx duration comparison - Ind**, **UTI Top Abx - Ind**, and **UTI Location - Ind**. They read the uploaded tables; the new review table does not feed or change their calculations.
