# Unmodified Superset candidates: local validation

Checkpoint: September 11, 2026. These results describe local, uncommitted candidate definitions. They are not a public release or Beth's acceptance.

Client clarification: the delivery must include the full 21-chart month-range workflow and options with and without custom Superset code. The existing comparisons below still use native Time Period controls; they do not yet establish the requested From month / Through month interaction. The latest notes also dispute the 980 total and request hospital-specific historical/individual transition rules. The 980 checks below verify the current query on the supplied records, not acceptance of that reporting rule.

## Candidates and limits

Both candidates contain the same September 21 charts, six datasets and supplied demo records. Their frontend assets match the pinned official images exactly. A PostgreSQL driver and Superset configuration are added; no application source patches are applied.

| Candidate | Local dashboard | Result |
| --- | --- | --- |
| Stable 6.1.0, standard time axis and vertical controls | `http://127.0.0.1:18194/superset/dashboard/csim-individual-standard/` | Exact labels fail in 99/99 observations. Clear/reselect returned additional hospitals despite the selected hospital; this workflow is not recommended. |
| Pinned development, standard time axis and vertical controls | `http://127.0.0.1:18195/superset/dashboard/csim-individual-development/` | Exact labels fail in 66/99 observations; annual labels pass. Clear/reselect lost the hospital selection. |
| Stable 6.1.0, sortable labels and horizontal controls | `http://127.0.0.1:18194/superset/dashboard/csim-individual-standard-sortable/` | Numerical date/filter checks pass. All eleven axes show the complete monthly sequence at all three widths. Month and quarter wording differs from the agreed format. |
| Pinned development, sortable labels and horizontal controls | `http://127.0.0.1:18195/superset/dashboard/csim-individual-development-sortable/` | The same date/filter and complete-month results pass, with the same wording tradeoff. Native legend layout also differs from stable. |

The sortable candidates use `2025-09`, `2025 Q3`, `2025`. Original acceptance remains `Sep 2025`, `Q3 2025`, `2025`. Horizontal controls place Time Period and Time Unit first so the date editor is outside the nested More filters popup. These are concrete alternatives for owner review; they do not establish the original vertical workflow as fixed.

The original requirement for every monthly tick is checked against all eleven axes at widths 1024, 1280 and 1600. The categorical candidates have 13/13 monthly labels throughout the September 2025–September 2026 window. All 198 captured cases retain explicit exact-format dispositions: 66 wording gaps per build, 33 annual passes. Measured inter-label spacing is at least 19 pixels. All 66 monthly screenshots were inspected through contact sheets; representative quarter/year screenshots were inspected. Full hover and all-panel review remain open.

## Numerical and interaction checks

- Known-record workflow: missing February remains null, March's zero remains zero, and February–March grouped into Q1 contains 10 submissions without January. Both builds pass.
- Selection order and same-page recovery: changing date range/grouping in either order gives equivalent results; clearing and reselecting retains the hospital and restores the expected results. Both horizontal candidates pass on supplied and known-record data.
- Hospital-only panels: an unset lower hospital returns no numeric total, hospital 53 returns exactly 980 all-time submissions, and clearing/reselecting works without reload. Both candidates pass. Native empty states have permanent selection instructions; they do not contain the custom inline prompts.
- Calendar preservation: the antibiotic and collection-location datasets retain their original queries inside a calendar join. Eight read-only cases compare every non-null output row, including original counts and antibiotic ranks, with the original queries across both databases and two windows. All pass; new rows contain null measures.
- Package imports: both candidates retain 21 charts, six dataset SQL definitions, calculated columns, settings, layout and all cached filter scopes. Stable uses the deterministic external ID-repair helper. Development's upstream importer preserves scopes without that helper. A new update-existing-objects regression remains required for these candidates.

## Evidence and reproduction

| Evidence | Local location |
| --- | --- |
| Official frontend asset identity | `output/standard-asset-verification.json`, `output/development-asset-verification.json` |
| Original native label/recovery observations | `output/native-standard/`, `output/native-development/` |
| Horizontal recovery with supplied data | `output/native-standard-horizontal-4/`, `output/native-development-horizontal-4/` |
| Known-record date/filter checks | `output/native-standard-calendar-fixture/`, `output/native-development-calendar-fixture/` |
| Complete label captures and per-case gaps | `output/native-standard-calendar-labels/`, `output/native-development-calendar-labels/` |
| Inspected monthly contact sheets | `output/native-review/` |
| Hospital selection and totals | `output/native-standard-hospital/`, `output/native-development-hospital/` |
| Calendar row comparison | `output/calendar-breakdown-verification.json` |

Regenerate definitions with `ruby scripts/prepare_dashboard.rb`. For already initialized native instances, `bash csim.sh standard candidates` and `bash csim.sh development candidates` import definitions without reseeding. The same commands verify those imports.

Run the numerical calendar comparison inside either initialized native container:

```sh
docker compose -p csim-standard --env-file .env.standard exec -T superset \
  python /repro/scripts/test_calendar_breakdowns.py
```

Run the native label observation and hospital workflow from `e2e/`, selecting the existing candidate:

```sh
CSIM_PROFILE=standard \
CSIM_DASHBOARD_SLUG=csim-individual-standard-sortable \
CSIM_OUTPUT=../output/native-standard-review \
npx playwright test -c acceptance.config.mjs native-comparison.spec.mjs native-hospital.spec.mjs
```

Use `development` in both profile and slug for its equivalent. The observation test passing means all screenshots and discrepancies were captured, not that the exact-label requirement passed. No videos from these candidates are published.

## Remaining before promotion

1. Compare supported month-range interactions with the custom From month / Through month fields on the full 21-chart dashboard. Present horizontal layout and year-first wording as explicit tradeoffs, not replacements for the client requirements.
2. Finish hover, opening-panel, section-link and update-existing-object validation on the selected native configuration; retain the explicit custom alternative.
3. Review and commit the implementation, run CI, deploy without reseeding, verify public routes/logins, and publish matching evidence.

The live overview already includes password copy icons. The live dashboard runtime remains the earlier custom release; no native candidate or calendar change in this checkpoint has been deployed.
