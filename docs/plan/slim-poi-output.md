---
title: Slim multi-POI score output — design freeze
description: Opt-in detail CSV with WQ columns plus one V1 score per shipped POI preset.
version: "1.4.0"
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

**Document version:** 1.4.0  
**Status:** **shipped** — Express `POI_Scores` frozen column order (excel 1.17.0).  
**Board:** [WORKBOARD](../WORKBOARD.md) P15–P33.  
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
| **Express [5]** | Score `--output-mode slim`; Excel workbook is **only** sheet `POI_Scores` (identity + score-input + context source + four scores). No profile / password / Full-Slim pick. Summary **CSV** still written; no summary **xlsx**. |

JSON: `OutputMode`, `SlimScoreColumns` (slim only). Excel: `PoiScoreSheet`, `PoiScoreSheetOnly`, `PoiScoreRowCount`.

## Frozen Express `POI_Scores` columns

Excel copies values only (no scoring math). Include a header **when present** on the slim CSV, in this **column** order (not a row sort). The four score columns are **required**. Do **not** copy `v1_raw_*` / `v1_norm_*` / `kpi_q_*`.

1. `invoice_num`  
2. `service_date`  
3. `last_worked_date`  
4. `out_ins_amt`  
5. `billed_amount`  
6. `payer`  
7. `plan`  
8. `reason_code_list`  
9. `remittance_code`  
10. `cpt_codes`  
11. `modifiers`  
12. `diagnosis_codes`  
13. `days_until_appeal_deadline`  
14. `days_until_replacement_deadline`  
15. `days_on_wq_tab`  
16. `denial_count`  
17. `billing_provider`  
18. `department`  
19. `billing_provider_tax_id`  
20. `billing_provider_npi`  
21. `follow_up_record_id`  
22. `account`  
23. `patient`  
24. `v1_priority_score`  
25. `v1_score_protect_writeoffs`  
26. `v1_score_maximize_cash`  
27. `v1_score_suppress_aging`

Workbook has **one** sheet (`POI_Scores` unless `-PoiScoreSheetName` is set). Not combined with Groups / Worklist / Totals. `-PoiScoreSheetOnly` on a full-detail CSV fails (missing `v1_score_*`).

## Document history

| Version | Notes |
|---------|--------|
| 1.4.0 | P31 Express: operator column order (copy if present) |
| 1.3.0 | P28 Express: context source columns (`cpt_codes`, plan, codes, billing) |
| 1.2.0 | P25 Express: copy score-input source columns (not `v1_*` audit) |
| 1.1.0 | P20 Express: one POI_Scores Excel sheet; skip extra prompts |
| 1.0.0 | P15 freeze |
