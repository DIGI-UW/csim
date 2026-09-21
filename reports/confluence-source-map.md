# CSiM documentation sources

Read on September 16, 2026. These sources describe the existing project; the
current remediation scope remains the user-approved plan in `PLAN.md`.

| Source | Relevant guidance | Version read |
| --- | --- | --- |
| [CSiM Dashboard Requirements](https://uwdigi.atlassian.net/wiki/spaces/CSiM/pages/929890354/CSiM+Dashboard+Requirements) | Simple interfaces for hospital teams; cohort-only opening view; hospital codes instead of names; hospital/state comparisons; accessibility and black-and-white print needs. Links to the current requirements checklist. | 24, February 23, 2026 |
| [CSiM Project Closeout Report](https://uwdigi.atlassian.net/wiki/spaces/CSiM/pages/1631322153/CSiM+Project+Closeout+Report) | Identifies Yao's palette work, the color-compliance workflow, technical handover, written/video tutorials, restore artifacts and client issue tracker. It documents existing handover and change records. | 2, September 8, 2026 |
| [September 15 meeting notes](https://uwdigi.atlassian.net/wiki/spaces/CSiM/pages/1652621313/2026-09-15+Meeting+notes) | Official Superset is the main delivery route; custom and development builds are alternatives. Its month-dropdown, rolling-default and horizontal-filter comparison describes an earlier demo, not the current native-date sidebar. | 2, September 15, 2026 |

The linked requirements database and color-compliance workflow have not yet
been reviewed in this check. The closeout's accessibility statement is a source
claim, not a new accessibility certification of the current dashboard.

## Palette reference

The supplied `Untitled` JSON settings contain 109 `label_colors` entries. Every
key and value matches the preserved April export. The six comparison charts
acquired hospital/state context in their legend labels; the full names require
matching saved color entries in Superset. Preserve the original category
colors when extending those names. No Superset application patch is needed.

## Follow-through

- Compare the current requirements checklist with the issue/evidence inventory
  before declaring the broader project complete.
- Use the handover and training documents for editor instructions.
- Keep the old meeting notes as historical records; use the current dashboard
  guide for the deployed date controls.
- Keep palette preservation, automated regression and owner acceptance separate.
