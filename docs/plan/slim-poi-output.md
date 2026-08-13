---
title: Slim multi-POI score output — design freeze
description: Opt-in detail CSV with WQ columns plus one V1 score per shipped POI preset.
version: "1.0.0"
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
last_updated: "2026-08-12"
---

# Slim multi-POI score output

**Document version:** 1.0.0  
**Status:** **shipped** (kpi 2.10.0 / excel 1.13.0).  
**Board:** [WORKBOARD](../WORKBOARD.md) P15–P19.  
**Signed:** 2026-08-12.

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

JSON: `OutputMode`, `SlimScoreColumns` (slim only).

## Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | P15 freeze |
