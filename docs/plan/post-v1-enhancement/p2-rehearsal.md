---
title: P2 rehearsal — synthetic group keys
description: Option A rehearsal on scored synthetic extract; cardinality and AR concentration by candidate group keys. Not a freeze.
version: "1.0.0"
status: current
audience:
  - analysts
  - developers
  - ai-agents
doc_type: plan
related:
  - ./README.md
  - ./ooo.md
  - ../../WORKBOARD.md
  - ../../research/2026-08-12-worklist-grouping-and-industry-metrics.md
  - ../cluster-3-analysis.md
last_updated: "2026-08-12"
---

# P2 rehearsal — synthetic group keys

**Board phase:** P2 (`done` when this note ships with the workboard).  
**Method:** existing `score` + `export-csv` only. **No** new product verbs. Regenerable files under `output\` are **not** tracked.

**Document version:** 1.0.0

---

## Summary

On the tracked synthetic file (250 rows), **`payer` (9)** and **`code_category` (12)** are usable worklist keys. Combined **`payer` + `code_category` (90 groups, 20 singletons)** matches the straw man but is finer than a daily list. **`location` (9)** is as usable as payer. **`patient` / `account` are 1:1** on this fixture — they cannot validate multi-claim patient calls. **`billing_provider` is too granular** here (196 groups, 172 singletons).

Excel export succeeded (`output\p2_rehearsal_scored.xlsx`, sheet `Data`, 100 columns). Option A (PivotTable) is possible on that workbook; numbers below are the same file as CSV.

This is **not** a Cluster 3 freeze.

---

## Contents

1. [Summary](#summary)
2. [How it was run](#how-it-was-run)
3. [Run facts](#run-facts)
4. [Cardinality](#cardinality)
5. [Top groups by outstanding AR](#top-groups-by-outstanding-ar)
6. [Implications for P1](#implications-for-p1)
7. [How to repeat](#how-to-repeat)
8. [Document history](#document-history)

---

## How it was run

```bat
cd kpi-analytics
kpi-analytics.cmd score --csv ..\import\wq_synthetic_data.csv --output ..\output\p2_rehearsal_scored.csv --json --quiet
cd ..\excel-toolkit
excel-toolkit.cmd export-csv -CsvPath ..\output\p2_rehearsal_scored.csv -OutputPath ..\output\p2_rehearsal_scored.xlsx -Json
```

Stdlib aggregation over the scored CSV (same columns a PivotTable would use). Privacy left **on** (default). No `--profile` (POI `default`).

---

## Run facts

| Item | Value |
|------|--------|
| Rows / columns | 250 / 100 |
| Queue mode | `chaos` |
| POI | `default` |
| Rank completeness | `full` |
| Total AR (`out_ins_amt`) | **284,235.94** |
| Days in AR | 55.50 (ADC estimated) |
| Unique patients (tokens) | **250** (mask `prefix_token`) |
| Excel | Success; sheet **Data**; gate `cached` |

Do not commit `output\p2_rehearsal_*`.

---

## Cardinality

| Key | Unique | Blank | Singletons | Worklist fit on this file |
|-----|-------:|------:|-----------:|---------------------------|
| `payer` | 9 | 0 | 0 | **Good** — 21–34 claims each |
| `code_category` | 12 | 0 | 0 | **Good** — 3–29 claims |
| `payer` + `code_category` | 90 | 0 | 20 | **Usable** — many small groups; one pair is 10% of AR |
| `location` | 9 | 0 | 0 | **Good** |
| `department` | 20 | 0 | — | Medium |
| `plan` | 69 | 0 | 13 | Fine grain; some 1-claim plans |
| `denial_status` | 6 | 0 | 0 | Better as a **filter** than a worklist |
| `remittance_code` | 15 | 0 | — | Medium (long text labels) |
| `reason_code_list` (raw) | 75 | 0 | 17 | Split families (`CO-109, N290` ≠ `CO-109`) |
| `reason_code_list` (exploded) | 29 tokens | — | — | Confirms freeze must pick raw vs first vs explode |
| `billing_provider` | 196 | 0 | 172 | **Poor** on this synthetic |
| `svc_provider` | 232 | 0 | — | Worse |
| `patient` / `account` | 250 | 0 | 250 | **Cannot test** multi-claim calls here |

Exploded reason tokens (count of claims containing token): `PR-96` 27, `CO-50` 26, `CO-4` 25, `CO-29` 25.

---

## Top groups by outstanding AR

### `payer`

| n | AR | Share | Max `v1_priority` | Min appeal days | Payer |
|--:|---:|------:|------------------:|----------------:|-------|
| 24 | 58,642 | 20.6% | 0.595 | 0 | WORKERS COMP |
| 23 | 45,408 | 16.0% | 0.631 | 0 | MEDICAID |
| 34 | 38,414 | 13.5% | 0.535 | 0 | TRICARE |
| 29 | 30,949 | 10.9% | 0.619 | 0 | UHC |
| 25 | 28,335 | 10.0% | 0.614 | 0 | BCBS |

Highest **max priority** among payers was HUMANA (0.686) with only 8.9% of AR — average priority would **mis-rank** vs dollars.

### `code_category`

| n | AR | Share | Category |
|--:|---:|------:|----------|
| 26 | 59,771 | 21.0% | Coding |
| 23 | 43,234 | 15.2% | Authorization |
| 28 | 39,215 | 13.8% | Non-Covered |
| 27 | 39,160 | 13.8% | Timely Filing |
| 22 | 30,846 | 10.9% | Modifier |

Authorization has a **higher** min appeal floor (18) than Coding (0) — POI `protect_writeoffs` would not sort these the same as cash.

### `payer` + `code_category` (top)

| n | AR | Share | Group |
|--:|---:|------:|-------|
| 1 | 29,538 | **10.4%** | MEDICAID \| Coding |
| 3 | 27,591 | 9.7% | WORKERS COMP \| Modifier |
| 4 | 26,764 | 9.4% | WORKERS COMP \| Timely Filing |
| 6 | 24,998 | 8.8% | TRICARE \| Non-Covered |

Concentration: a **single claim** is a tenth of batch AR. Group lists must still expose **member detail** (option D).

### `location` (top)

URGENT CARE WEST 23.1% AR (n=28); OUTPATIENT CENTER 18.5%; TELEHEALTH VIRTUAL 17.0%. Site worklists work on this file.

---

## Implications for P1

| Straw man | Rehearsal result |
|-----------|------------------|
| Default `payer` + `code_category` | Works, but 90 groups / 20 singles; consider **`payer` first**, then category inside the payer |
| Rank by sum `$` / `kpi_q_*` not avg priority | Confirmed: HUMANA max-pri vs WORKERS COMP dollars |
| Patient tokens | Tokens present (`DOE0178,JOH0178`); **no multi-claim patients** in synthetic — do not freeze patient grouping on this file alone |
| Provider groups | Weak on synthetic (almost unique names) |
| Raw `reason_code_list` | 75 keys; explode to 29 tokens — freeze must choose |
| Option A Excel | **Viable** — one Data sheet, 100 columns; operator can Pivot |

To rehearse **patient** groups later: need a fixture with several claims per account (do not invent PHI). Out of P2 scope.

---

## How to repeat

Same commands as [How it was run](#how-it-was-run). In Excel: Insert → PivotTable on `Data`; rows = `payer` then `code_category`; values = Count, Sum of `out_ins_amt`, Max of `v1_priority_score`, Min of `days_until_appeal_deadline`.

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | Score + export + cardinality on `import\wq_synthetic_data.csv` |
