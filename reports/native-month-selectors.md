# Native month selectors: implementation and evidence

The full September dashboard can use ordinary Superset Select controls for **From
month** and **Through month**, alongside the existing Month/Quarter/Year control.
The local comparison runs on the unchanged official 6.1.0 application.

The three datasets with a date axis consume the selected values through Superset's
standard SQL templating. The start is the first day of From month; the exclusive
end is the first day after Through month, including December-to-January rollover.
The existing queries then filter observations before aggregation. Their measures,
cohort weighting, calendar gaps, all-time cards and latest-month definitions stay
unchanged. Six datasets and 21 charts remain in the package.

Dropdown option queries provide all months within the calendar years covered by
the dataset. This lets a range begin in January even when observations begin later
that year. This calendar is used for the choices, not to fabricate observations.

## Verified locally

- Native vertical controls correctly calculate missing periods, true zero and a
  February–March partial quarter. They fail same-hospital reselection after Clear
  all. `output/native-months-calendar/results.json` preserves that failure.
- The same definitions with a horizontal native filter bar pass both selection
  orders, same-page clearing/reselection, saved defaults and all independent
  numerical cases in `output/native-months-horizontal/results.json` (three tests).
- Native import/update verifies 21 charts, six datasets and all seven filter scopes.
  `scripts/test_native_months.rb` verifies that every chart setting and measure is
  preserved relative to the official sortable-label candidate (150 assertions).

The source of the vertical reset limitation is documented in
[the Superset comparison](superset-options-review.md). It must not be inferred
that custom month input fields themselves are required to calculate inclusive
month ranges. The native implementation still has these differences:

| Requirement | Native month candidate |
| --- | --- |
| Inclusive month range | Native dropdowns and prepared dataset SQL |
| Familiar vertical sidebar with reliable Clear all | Fails in unmodified 6.1.0; horizontal configuration used for this candidate |
| Rolling last 12 complete months on fresh open | Not implemented; these are explicitly saved month values |
| `Jan 2025` / `Q1 2025` / `2025` labels | Year-first sortable labels retained; exact wording still a gap |
| Friendly rejection of an inverted range | Still to validate; no passing claim |

The supplied-data candidate passes 14 local checks in
`output/native-months-supplied/results.json`: all 21 panels, the independently
verified hospital total of 980 and clear/reselect, saved defaults, both selection
orders, all nine antibiotic legend cases, and capture of the 99-axis comparison.
The comparison records year-first wording as a gap. All 99 captures were visually inspected through 18 contact sheets; complete ticks and legend controls are visible. Year-first wording remains an explicit gap. Review hashes are in `output/native-months-supplied/visual-review/review.json`.

Definitions `623acb3` are deployed at [the native month dashboard](https://standard.csim.uwdigi.org/superset/dashboard/csim-individual-standard-month-selectors/), with its own known-record copy. Runtime `9f7d15d` is unchanged; its application assets remain official 6.1.0. The public inclusive-month demonstration passes. Isolated recovery and partial-quarter checks also pass (`output/public-native-serial-623/results.json`). Earlier parallel runs timed out while charts waited for results; the cause remains under diagnosis. A passing rerun is not treated as a repair.
