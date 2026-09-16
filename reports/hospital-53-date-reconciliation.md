# Hospital 53: monthly graph versus all-time total

Checked September 16, 2026 on the public official Superset dashboard, assets
`44b73acd3e297c39894f59870b9c49744dcd0c07`, with the supplied demo database.
No dashboard definitions or reporting data were changed for this check.

| Time Period (start included, end excluded) | Sum of monthly graph values | All-time hospital card |
| --- | ---: | ---: |
| September 1, 2025 to September 1, 2026 — saved opening range | 269 | 980 |
| September 1, 2023 to April 1, 2026 — covers all recorded months | 980 | 980 |
| February 1, 2026 to April 1, 2026 | 56 | 980 |

Hospital 53 was selected in both **Hospital and state** (the trend) and
**Your hospital** (the all-time card), with **All locations** and **Month**.
The selectors have different scopes; choosing only the lower selector does
not change the main trend's population.

Independent read-only counts from `v1."UTI Individual Historical"` give 980
rows for hospital 53, across September 2023–March 2026. The current source has
zero rows for hospital 53. Every monthly chart value matched these source
counts, including null gaps. In the saved range the nonempty months are
44 + 52 + 43 + 37 + 37 + 38 + 18 = 269.

The browser regression is `e2e/acceptance/submission-totals.spec.mjs`. The
public run passed all three date windows; its graph and card screenshots
were visually inspected. This does not reconstruct Beth's exact unsaved
selection, but the reported discrepancy is explained when a restricted
monthly graph is compared with the all-time card. It is separate from the
earlier requested total of 500, whose source remains unresolved.
