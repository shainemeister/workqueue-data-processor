---
title: Slim multi-POI score output — design freeze
description: Opt-in detail CSV with WQ columns plus one V1 score per shipped POI preset.
version: "1.5.0"
status: current
audience:
  - developers
  - analysts
doc_type: plan
related:
  - ../../PLAN.md
  - ../PLAN.md
  - ../WORKBOARD.md
  - ../../kpi-analytics/SCORE-METHODOLOGY.md
  - ../../kpi-analytics/CLI-GUIDE.md
  - ./post-v1-enhancement/ooo.md
last_updated: "2026-08-13"
---

# Slim multi-POI score output

**Document version:** 1.5.0  
**Status:** **shipped** — `patient` after `invoice_num`; menu deletes generated CSVs after Excel (excel 1.18.0).  
**Board:** [WORKBOARD](../WORKBOARD.md) P15–P36.  
**Signed:** 2026-08-12 (slim CSV); Express addenda 2026-08-13.

---

## Summary

Operators can write a **slim** scored detail file: original WQ columns plus **one V1 score per shipped POI preset**, without the `v1_raw/norm/weight/contrib` audit trail and without `kpi_q_*` on that file. **Full** output remains the default.

One minmax/percentile pass. Extra scores reuse those norms with each POI weight vector. No new metrics.

---

## Frozen columns (`--output-mode slim`)

| Keep | Drop from detail |
|------|------------------|
| Source WQ columns (privacy as in full) | `v1_raw_*`, `v1_norm_*`, `v1_weight_*`, `v1_contrib_*` |
| `v1_as_of_date`, `v1_queue_mode`, `v1_normalization` | `v1_poi_name` |
| `v1_priority_score` (balanced / package default) | All `kpi_q_*` |
| `v1_score_protect_writeoffs` | |
| `v1_score_maximize_cash` | |
| `v1_score_suppress_aging` | |

Shipped presets = `kpi-analytics/profiles/poi_*.json` only. Summary CSV is still written (full vertical report).

## Flag / menu freeze

| Combo | Behavior |
|-------|----------|
| omitted / `full` | Today |
| `slim` | Columns above; base = package default config |
| `slim` + `--profile` or `--config` | Error |
| `slim` + `--sort` / `--group-by` | Allowed; group max priority uses balanced `v1_priority_score` |
| Menu | Full (default, profile pick) or Slim (no profile pick; `--output-mode slim`) |
| **Express [5]** | Score `--output-mode slim`; Excel workbook is **only** sheet `POI_Scores`. No profile / password / Full-Slim pick. After a **successful** Excel write, the menu **deletes** generated `output\` CSVs for that run (scored / summary). Score-only keeps CSVs. Never delete `import\` inputs. |

JSON: `OutputMode`, `SlimScoreColumns` (slim only). Excel: `PoiScoreSheet`, `PoiScoreSheetOnly`, `PoiScoreRowCount`.

## Frozen Express `POI_Scores` columns

Excel copies values only (no scoring math). Include a header **when present** on the slim CSV, in this **column** order (not a row sort). The four score columns are **required**. Do **not** copy `v1_raw_*` / `v1_norm_*` / `kpi_q_*`.

1. `invoice_num`  
2. `patient`  
3. `service_date`  
4. `last_worked_date`  
5. `out_ins_amt`  
6. `billed_amount`  
7. `payer`  
8. `plan`  
9. `reason_code_list`  
10. `remittance_code`  
11. `cpt_codes`  
12. `modifiers`  
13. `diagnosis_codes`  
14. `days_until_appeal_deadline`  
15. `days_until_replacement_deadline`  
16. `days_on_wq_tab`  
17. `denial_count`  
18. `billing_provider`  
19. `department`  
20. `billing_provider_tax_id`  
21. `billing_provider_npi`  
22. `follow_up_record_id`  
23. `account`  
24. `v1_priority_score`  
25. `v1_score_protect_writeoffs`  
26. `v1_score_maximize_cash`  
27. `v1_score_suppress_aging`

Workbook has **one** sheet (`POI_Scores` unless `-PoiScoreSheetName` is set). Not combined with Groups / Worklist / Totals. `-PoiScoreSheetOnly` on a full-detail CSV fails (missing `v1_score_*`).

## Document history

| Version | Notes |
|---------|--------|
| 1.5.0 | P34: `patient` after `invoice_num`; menu deletes generated CSVs after Excel |
| 1.4.0 | P31 Express: operator column order (copy if present) |
| 1.3.0 | P28 Express: context source columns (`cpt_codes`, plan, codes, billing) |
| 1.2.0 | P25 Express: copy score-input source columns (not `v1_*` audit) |
| 1.1.0 | P20 Express: one POI_Scores Excel sheet; skip extra prompts |
| 1.0.0 | P15 freeze |
