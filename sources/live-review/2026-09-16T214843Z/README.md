# Official dashboard review checkpoint

Saved September 16, 2026 at 21:48:43 UTC (2:48pm Pacific) from
[the official review dashboard](https://standard.csim.uwdigi.org/superset/dashboard/csim-individual-standard-month-selectors/).
Beth is still editing. This is a saved checkpoint, not her final submission or
an accepted client release. Unsaved browser edits are not included.

- One dashboard with 22 charts: 21 reporting panels and the period summary.
- One separate aggregate-download chart, included in `charts.zip`.
- Seven virtual dataset definitions: the familiar six and the period helper.
- Native Superset dashboard, chart and dataset exports; one readable set of
  their definitions under `definitions/`.
- `capture.json` records provenance and export consistency.
- `inventory.json` records object identities, saved timestamps and definitions.

No dashboard definitions or reporting records were changed by this capture.
The before/after saved-object inventory matched throughout the exports. The
database definitions in these exports belong to the demo installation; they
are not destination connection instructions.

## Comparison with the deployed source

The deployed asset source is `44b73acd3e297c39894f59870b9c49744dcd0c07`.
At this checkpoint, the dashboard and charts still have the deployment's
21:19 UTC modification timestamps, as do all seven datasets.

After matching object identities and translating local chart IDs:

- Titles, text, layout, colors, SQL, calculated expressions, measures, chart
  bindings and saved filter selections match the repository definitions.
- Superset exports add empty annotation lists and active-column defaults and
  omit the unused empty `default_filters` value.
- Native filter exclusions no longer contain source-only chart IDs outside
  the dashboard; in-dashboard exclusions and active scopes agree by identity.
- Per-chart cross-filter scope lists retain source numeric IDs, even though
  the chart-configuration keys are remapped. Cross-filtering is disabled on
  this dashboard. Record this as an import/package reconciliation item; it is
  not evidence of a new edit by Beth or a demonstrated failure of her filters.

There are therefore no newly saved wording, layout, SQL or chart-setting edits
to attribute to Beth in this checkpoint. Keep this capture and export again
after she finishes saving. Do not deploy the source over her ongoing work.

## Capture again

`scripts/capture_live_review.py` runs in the existing Superset container with
the repository scripts directory on `PYTHONPATH`. Supply the dashboard slug,
the standalone chart UUID, a new output directory and the deployed source
revision. It uses native export endpoints, checks the saved inventory before
and after exporting, and rejects a capture if the objects changed mid-export.
It never imports assets or queries reporting records.

Keep the three original ZIPs. Copy the successful capture into a new timestamped
folder; do not overwrite this checkpoint. Reconcile the later definitions into
the repository and their generation inputs before any deployment.
