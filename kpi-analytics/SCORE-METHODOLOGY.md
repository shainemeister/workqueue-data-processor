---
title: KPI Analytics Score Methodology
description: Priority Matrix V1 formulas, RCM kpi_q implementation, validation, and summary output.
version: "1.8.0"
status: current
audience:
  - users
  - developers
  - analysts
doc_type: methodology
related:
  - README.md
  - CLI-GUIDE.md
  - RCM_KPI_Claim_Impact_Methodology.md
  - ENTERPRISE-SECURITY.md
last_updated: "2026-07-22"
---

# KPI Analytics — Score Methodology & Validation

How `kpi-analytics` turns Work Queue rows into:

1. An explainable **priority score** (`v1_*`)  
2. **RCM portfolio KPIs** and **claim-level impacts** (`kpi_q_*`)  
3. A **vertical summary CSV** for audit and communication  
4. **PHI field masking** on score output (`patient` / `dob` when configured)  

**Toolkit version:** 1.8.0  
**Package:** `kpi_modules`  
**Default config:** `kpi_modules\config_default.json`  
**Fixtures:** `fixtures\v1_handcalc_*`, `fixtures\rcm_impact_*`

**Related docs:** [README.md](./README.md) · [CLI-GUIDE.md](./CLI-GUIDE.md) · [RCM_KPI_Claim_Impact_Methodology.md](./RCM_KPI_Claim_Impact_Methodology.md) · root `WQ_Priority_Matrix_Concept.md`

---

## Summary

This document is the **implementation-level methodology** for KPI Analytics scoring. It covers two independent output families written on every `score` run:

1. **Priority Matrix V1 (`v1_*`)** — batch-normalized, weighted metrics produce an explainable `v1_priority_score` in **[0, 1]** for work-queue ranking, with full audit columns (`raw` / `norm` / `weight` / `contrib`).  
2. **RCM claim impact (`kpi_q_*`)** — portfolio KPIs (Total AR, Days in AR, aging %) plus per-claim **static** share/contribution and **exact** resolution deltas (including negative aging impacts for young claims), following the dual-attribution model in the RCM methodology document.  

It also describes the **vertical summary CSV** (metrics as rows with formulas and explanations), validation procedures (`validate-score` and fixtures), and common misreads (single-row norms, ADC estimates, delta sums vs static %). Use this doc to recompute or audit a run; use [RCM_KPI_Claim_Impact_Methodology.md](./RCM_KPI_Claim_Impact_Methodology.md) for pure RCM theory.

---

## Contents

1. [Summary](#summary)
2. [Purpose and scope](#1-purpose-and-scope)
3. [Pipeline overview](#2-pipeline-overview)
4. [Priority raw metrics](#3-priority-raw-metrics)
5. [Queue mode (healthy vs chaos)](#4-queue-mode-healthy-vs-chaos)
6. [Weights](#5-weights)
7. [Normalization](#6-normalization)
8. [Priority contributions and final score](#7-priority-contributions-and-final-score)
9. [Priority audit columns](#8-priority-audit-columns)
10. [Priority worked example](#9-priority-worked-example)
11. [RCM KPI quantifiers (kpi_q_*)](#10-rcm-kpi-quantifiers-kpi_q_)
12. [Vertical summary CSV](#11-vertical-summary-csv)
13. [PHI field masking (privacy)](#12-phi-field-masking-privacy)
14. [How to validate](#13-how-to-validate)
15. [Common false alarms](#14-common-false-alarms)
16. [Out of scope](#15-out-of-scope)
17. [Document history](#16-document-history)

---

## 1. Purpose and scope

| Item | Detail |
|------|--------|
| **Priority goal** | Rank WQ denial / follow-up work with an explainable score in **[0, 1]** |
| **RCM goal** | Portfolio Days in AR and aging % plus per-claim static and resolution impacts |
| **Inputs** | Data CSV + optional config JSON |
| **Outputs** | Detail scored CSV + vertical summary CSV |
| **Priority version** | **V1** foundation metrics |

Priority scores are **relative within the batch** under minmax/percentile normalization. Changing which rows are in the file can change norms and scores even if one claim is unchanged.

RCM `kpi_q_*` columns are **independent** of priority ranking.

---

## 2. Pipeline overview

```text
Data CSV
    │
    ├─► [Priority V1]
    │       raw metrics → chaos mode → weights → normalize → contrib → v1_priority_score
    │
    ├─► [RCM KPI Q]
    │       T, N_T, ADC → static share/contrib → exact Δ (Days in AR; aging pp)
    │
    ├─► [Privacy] (score output only; default on)
    │       patient → prefix+token; dob → omit/passthrough
    │
    └─► [Outputs]
            detail CSV (source fields with optional PHI mask + v1_* + kpi_q_*)
            summary CSV (vertical: section, metric, value, formula, explanation)
            CLI JSON (KpiTotals, Privacy*, scores, paths)
```

```bat
cd kpi-analytics
kpi-analytics.cmd score --csv ..\import\wq_synthetic_data.csv --output ..\output\wq_scored.csv --json
kpi-analytics.cmd validate-score
```

---

## 3. Priority raw metrics

Computed in `metrics.py` using config `fields`.

| Metric key | Formula / source | Unit | Direction after normalize |
|------------|------------------|------|---------------------------|
| `ar_days` | `as_of_date − service_date` | days | **higher** = more priority |
| `ar_disparity` | `ar_days − ar_day_target` | days | **higher** |
| `out_ins_amt` | CSV outstanding insurance | currency | **higher** |
| `billed_amount` | CSV billed | currency | **higher** |
| `appeal_urgency` | `days_until_appeal_deadline` | days left | **lower** raw = more priority |
| `wq_age` | `days_on_wq_tab` | days | **higher** |

**Defaults:** `ar_day_target = 45`. `as_of_date` is today unless set (fixtures use `2026-07-22`).

Missing parseable values → normalization uses `missing_norm_value` (default **0.0**).

---

## 4. Queue mode (healthy vs chaos)

Uses batch AR days (parseable service dates only). Chaos if **any** default rule fires:

| Condition | Default |
|-----------|---------|
| mean AR days > `ar_day_target × mean_ar_days_factor` | 45 × 1.5 = **67.5** |
| share AR ≥ 60 | ≥ **40%** |
| share AR ≥ 90 | ≥ **25%** |
| share AR ≥ 120 | ≥ **15%** |

Written as `v1_queue_mode` and CLI `QueueMode` / `Chaos.reasons`.  
Chaos changes **priority weights only**, not RCM `kpi_q_*` formulas.

---

## 5. Weights

### Base weights (default)

| Metric | Base |
|--------|-----:|
| ar_days | 0.20 |
| ar_disparity | 0.20 |
| out_ins_amt | 0.25 |
| billed_amount | 0.10 |
| appeal_urgency | 0.15 |
| wq_age | 0.10 |
| **Sum** | **1.00** |

### Effective weight

```text
raw_w_i = base_i × poi_multiplier_i × (chaos_multiplier_i if chaos else 1)
w_i     = raw_w_i / sum(raw_w_j)
```

Default chaos multipliers: `ar_disparity` × **1.4**, `appeal_urgency` × **1.5**.  
POI multipliers default to 1.0.  
Audit: `v1_weight_*` (constant across rows in a batch).

---

## 6. Normalization

`normalization`: `minmax` (default) or `percentile`.

**Min-max (higher direction):** `(raw − min) / (max − min)`  
**Min-max (lower direction):** `1 − that`  
**All equal / single row:** norm **0.5** for present values  
**Missing:** `missing_norm_value` (default 0)

Percentile: average-rank scaled to [0, 1]; direction invert as above.

---

## 7. Priority contributions and final score

```text
contrib_i = w_i × norm_i
v1_priority_score = clamp(sum(contrib_i), 0, 1)
```

**Identity (within rounding):**

```text
v1_priority_score ≈ sum(v1_contrib_*)
```

---

## 8. Priority audit columns

| Column | Meaning |
|--------|---------|
| `v1_as_of_date` | AR age anchor |
| `v1_queue_mode` | `healthy` / `chaos` |
| `v1_poi_name` | Focus profile |
| `v1_normalization` | `minmax` / `percentile` |
| `v1_raw_*` | Raw metric |
| `v1_norm_*` | Normalized 0–1 |
| `v1_weight_*` | Effective weight |
| `v1_contrib_*` | Weight × norm |
| `v1_priority_score` | Final priority |

Original business columns are preserved; audit fields are appended.

---

## 9. Priority worked example

Fixtures with fixed `as_of_date = 2026-07-22`:

| File | Role |
|------|------|
| `fixtures\v1_handcalc_input.csv` | Five deliberate rows |
| `fixtures\v1_handcalc_config.json` | Locked config |
| `fixtures\v1_handcalc_expected.json` | Golden values |

| Patient | AR days | Out. ins. | Appeal days | Score (approx) |
|---------|--------:|----------:|------------:|---------------:|
| Doe,John1 | 730 | 5000 | 5 | **~0.995** (highest) |
| Doe,Jane4 | 456 | 800 | 0 | ~0.549 |
| Doe,John3 | 181 | 1200 | 45 | ~0.342 |
| Doe,John5 | 30 | 300 | 90 | ~0.129 |
| Doe,Jane2 | 7 | 50 | 180 | **0.0** (lowest) |

John1 sits at batch extremes for high-dollar / high-age / short appeal → high norms under chaos weights. Jane2 sits at the opposite extremes → zero norms.

---

## 10. RCM KPI quantifiers (`kpi_q_*`)

**Theory:** [RCM_KPI_Claim_Impact_Methodology.md](./RCM_KPI_Claim_Impact_Methodology.md) (proof of concept).  
**Implementation:** `kpi_modules\kpi_quantifiers.py` using **`kpi_q_*`** names.

### Dual attribution (do not conflate)

| Family | Question | Sums to portfolio KPI? |
|--------|----------|-------------------------|
| **Static** share / aged contrib | How much of the problem is this claim *now*? | **Yes** (dollar-weighted) |
| **Exact Δ** | If balance → 0 today, how much does the KPI move? | **Days in AR: yes.** Aging **% Δ: no** |

### Portfolio KPIs (`KpiTotals` in CLI JSON)

| Key | Formula |
|-----|---------|
| `kpi_total_ar` (\(T\)) | Sum of claim balances (default `out_ins_amt`) |
| `kpi_days_in_ar` | \(T / \mathrm{ADC}\) |
| `kpi_ar_over_{T}_pct` | \(N_T / T \times 100\) |
| `adc` / `adc_source` | Config ADC or `estimate_billed_90` |

### Per-claim columns

| Column | Formula | Notes |
|--------|---------|--------|
| `kpi_q_share_total_ar_pct` | \(x_i/T \times 100\) | Sum ≈ 100% |
| `kpi_q_aged{T}_contrib_pct` | \(d_i \cdot x_i/T \times 100\) | Sum = AR over T % |
| `kpi_q_days_in_ar_pos` / `_neg` | \(x_i/\mathrm{ADC}\) | Sum = Days in AR |
| `kpi_q_aged{T}_delta_pp_pos` / `_neg` | \(\dfrac{x_i(d_i T - N_T)}{T(T-x_i)}\times 100\) | Exact pp change; young claims can be **negative** |

\(d_i = 1\) if claim AR days ≥ threshold \(T\), else 0.  
Default thresholds: **30, 60, 90, 120**.

### RCM worked example (methodology §6)

Fixtures: `fixtures\rcm_impact_*` with ADC = 2000, as_of = 2026-07-22.

| Claim | Balance | Age | Share | Contrib >90 | Δ>90 (pp) | Δ Days |
|-------|--------:|----:|------:|------------:|----------:|-------:|
| A | 10000 | 120 | 20% | 20% | **+12.5** | 5 |
| B | 5000 | 45 | 10% | 0% | **≈ −5.56** | 2.5 |

Portfolio: \(T = 50000\), AR>90% = **50%**, Days in AR = **25**.

### Config (`kpi_quantifiers`)

| Key | Default | Meaning |
|-----|---------|---------|
| `aged_day_breaks` | `[30,60,90,120]` | Aging thresholds |
| `adc` | null | If null → estimate billed / 90 |
| `adc_lookback_days` | 90 | Lookback for estimate |
| `credit_policy` | `exclude_from_T` | Or `include` |
| `emit_static_share` | true | Static family |
| `emit_exact_delta` | true | Exact Δ family |
| `dual_sign_columns` | true | pos/neg split for signed values |

---

## 11. Vertical summary CSV

Written next to the detail file unless `--no-summary`:

```text
<output_stem>_summary.csv
```

| Column | Role |
|--------|------|
| `section` | Grouping (Run, Portfolio KPI, Portfolio KPI Q checksum, …) |
| `metric` | Metric name |
| `value` | Value for this run |
| `unit` | Unit when applicable |
| `formula` | Short formula |
| `explanation` | Plain-language description |

**Portfolio KPI Q checksum** rows re-sum claim-level `kpi_q_*` fields to prove they rebuild portfolio KPIs (share ≈ 100%, days sum = Days in AR, aged contrib = AR-over-T %).

Run section also records `privacy_enabled`, and when enabled: `privacy_patient_mode`, `privacy_dob_mode`, `privacy_unique_patients`.

---

## 12. PHI field masking (privacy)

Applied **after** priority and KPI Q, **only on the scored output rows**. The input CSV is never modified. Implementation: `kpi_modules\privacy.py`.

**Important:** This is **operational PHI field masking / risk reduction**. It is **not** a claim of HIPAA Safe Harbor or Expert Determination de-identification. Other columns (`account`, `sub_id`, free-text comments, etc.) may still identify individuals.

### Config (`privacy`)

Default in `config_default.json`: **enabled**.

| Key | Default | Meaning |
|-----|---------|---------|
| `enabled` | `true` | Master switch for score-output masking |
| `patient_field` | `patient` | Column name to mask |
| `dob_field` | `dob` | Column name to mask |
| `patient.mode` | `prefix_token` | `prefix_token` · `omit` · `passthrough` |
| `patient.name_order` | `last_first` | Parse order of comma-separated name (`first_last` supported) |
| `patient.prefix_len` | `3` | Letter prefix length per name part |
| `patient.token_digits` | `3` | Zero-padded ordinal width (max 999 uniques) |
| `patient.token_mode` | `alpha_order` | Unique names sorted A→Z → `001`…`N` |
| `patient.uppercase` | `true` | Uppercase prefixes and sort keys |
| `patient.pad_char` | `X` | Right-pad short letter prefixes |
| `patient.empty_policy` | `leave_empty` | Or `placeholder` → `UNK000,UNK000` |
| `dob.mode` | `omit` | `omit` (blank) or `passthrough` |

Golden fixtures set `"privacy": { "enabled": false }` so handcalc patient labels stay stable.

### Patient transform (`prefix_token`)

1. Parse name using `name_order` (default **LAST,FIRST**).  
2. Normalize key: collapse spaces, optional uppercasing → `LAST,FIRST`.  
3. Collect **unique** keys in the batch; sort A→Z; assign `001`…`N`.  
4. Emit:

```text
{LAST_PREFIX}{TOKEN},{FIRST_PREFIX}{TOKEN}
DOE,JOHN  →  DOE001,JOH001
```

- Prefixes use **letters only** (e.g. `O'BRIEN` → `OBR`).  
- Same person on multiple claim rows shares one token within the run.  
- Tokens are **batch-relative**: a different extract can renumber the same person.

### DOB

| Mode | Output |
|------|--------|
| `omit` | Empty cell (default) |
| `passthrough` | Unchanged input value |

Priority and KPI math **do not** use `patient` or `dob`.

### CLI JSON fields

When scoring: `PrivacyEnabled`, `PrivacyPatientMode`, `PrivacyDobMode`, `PrivacyUniquePatients`, `PrivacyCliOverride`.

### CLI overrides

| Flag | Effect |
|------|--------|
| `--privacy` | Force `privacy.enabled = true` for this run (overrides JSON) |
| `--no-privacy` | Force `privacy.enabled = false` for this run (overrides JSON) |
| *(omit both)* | Use `privacy.enabled` from config (package default: **true**) |

Flags are mutually exclusive. They toggle only the master switch; `patient.mode`, `dob.mode`, and other privacy keys still come from config.

---

## 13. How to validate

### Automated

```bat
cd kpi-analytics
kpi-analytics.cmd validate-score --json

kpi-analytics.cmd validate-score --csv fixtures\rcm_impact_example.csv ^
  --config fixtures\rcm_impact_config.json ^
  --expected fixtures\rcm_impact_expected.json --json
```

Checks include:

- Priority: score ≈ sum(contrib)  
- KPI Q: share sum, Days in AR sum, aged contrib vs portfolio %  
- Optional golden expected JSON  

### Manual checklist

| # | Check |
|---|--------|
| 1 | `sum(v1_contrib_*) ≈ v1_priority_score` |
| 2 | Raw AR days match calendar math for `v1_as_of_date` |
| 3 | `sum(kpi_q_share_total_ar_pct) ≈ 100` |
| 4 | `sum(kpi_q_days_in_ar_*) = kpi_days_in_ar` |
| 5 | `sum(kpi_q_aged90_contrib_pct) = kpi_ar_over_90_pct` |
| 6 | Young claim can have **negative** `kpi_q_aged90_delta_pp_neg` |
| 7 | Same CSV + fixed `as_of_date` + ADC → deterministic outputs |

---

## 14. Common false alarms

| Observation | Explanation |
|-------------|-------------|
| All priority scores ≈ 0.5 | Single-row or flat metrics under minmax |
| Priority scores change overnight | Default `as_of_date` is today |
| Same claim different priority in two files | Batch-relative normalization |
| Days in AR looks high/low | Check `adc` and `adc_source` (estimate vs true practice ADC) |
| Sum of aging **deltas** ≠ aging % | Expected — deltas are resolution impacts, not static shares |
| Summary/detail write fails | File open in Excel (permission denied) |
| Same person different `DOE00n` across two score runs | Batch-relative privacy tokens (different unique sets) |
| Patient looks “backwards” | Check `privacy.patient.name_order` (`last_first` vs `first_last`) |

---

## 15. Out of scope

- Priority Matrix V2/V3  
- Excel COM automation  
- Third-party Python packages  
- Automatic true ADC from practice systems (supply via config)  
- Full HIPAA Safe Harbor / Expert Determination de-identification  
- Masking of other identifier columns (`account`, `sub_id`, comments) — future config extension  

---

## 16. Document history

| Version | Notes |
|---------|--------|
| 1.2.0 | Initial methodology + validate-score + handcalc fixtures |
| 1.3.0–1.4.0 | Early portfolio `kpi_q_*` experiments |
| 1.5.0 | Align `kpi_q_*` with RCM dual-attribution methodology |
| 1.5.1 | Vertical summary CSV; documentation refresh |
| 1.6.0 | Toolkit version align; enterprise diagnostics gate (no formula change) |
| 1.7.0 | Score-output PHI masking (`privacy`); patient prefix+token; DOB omit; `--privacy` / `--no-privacy` CLI |
| 1.8.0 | Default score/generate paths use tracked `import\wq_synthetic_data.csv` (no formula change) |
