# Beth's September 17 saved dashboard

The original Slack attachment and unpacked YAML are preserved unchanged. The report is a text-only copy of the linked Google document; its screenshots remain in that document.

- [Handoff and change summary](../../../reports/beth-final-export-and-winter-handoff-2026-09-17.md)
- [Original ZIP](dashboard_export_20260917T160253.zip)
- [Report text](beth-report.txt)
- [Source manifest](manifest.json) and [checksums](SHA256SUMS)
- [Definition comparison with prior checkpoint](comparison.json)
- [Definition comparison with live 9:30 a.m. backup](live-comparison.json): all objects identical

This export uses demo object identities and a demo connection. Preserve it as the source of Beth's edits; prepare and test the client update separately.

From the repository root, reproduce the comparison:

```sh
ruby scripts/compare_dashboard_bundles.rb \
  sources/live-review/2026-09-17T040444Z/unpacked/dashboard/dashboard_export_20260917T040449 \
  sources/exports/beth-september-17-2026/unpacked/dashboard_export_20260917T160253
```

The checkpoint precedes the separately recorded navigation publication. Read the handoff report to distinguish those earlier changes from Beth's editing round. Do not infer authorship from the raw diff alone.
