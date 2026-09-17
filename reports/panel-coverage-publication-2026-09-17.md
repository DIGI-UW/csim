# Panel coverage and section 4.1 update

Dashboard: `csim-individual-standard-month-selectors` on the official Superset 6.1.0 review instance.

## Published dashboard change

- Five overall charts are labelled **all reporting dates**. They receive Hospital and State and Location of Urine Culture Collection, but not Time Period or Time Unit.
- The inappropriate-diagnosis and therapy-duration comparison tables are labelled **latest available month**. They receive Hospital and State only; the tables display the selected hospital's latest available reporting month.
- Section 4.1 explains the existing positive-urinalysis calculation as submissions with a positive urinalysis divided by urine culture submissions.

The patch changed seven title overrides, seven chart descriptions, two native-filter scopes and one explanatory Markdown panel. It did not change chart measures, dataset SQL, chart parameters, saved defaults, palette settings, data records or other dashboard layout.

## Verification

- The saved definition backup immediately before the update matched Beth's September 17 export.
- The update receipt verified all 21 charts and six datasets after publication.
- Browser checks used hospital 53 with calendar 2024 grouped by Month and September 2025 through August 2026 grouped by Year. The seven panels retained the same results across the two choices and no longer listed Time Period or Time Unit as applied filters.
- The therapy trend retained Time Period and Time Unit and changed between the two choices.
- The published screenshots and structured result check are at https://design.csim.uwdigi.org/evidence/panel-coverage/.

Clear all remains an official Superset 6.1.0 limitation. This scope correction does not change that behavior.
