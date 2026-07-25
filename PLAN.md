---
title: Work Queue Data Processor – Development Plan
description: Living plan for dynamic column mapping, improved aging terminology and metrics, adaptive KPI generation, and simplified end-user workflow.
version: "0.3.0"
status: current
audience:
  - developers
  - analysts
doc_type: other
related:
  - README.md
  - RULES.md
  - FILE-CATALOG.md
  - WQ_Priority_Matrix_Concept.md
  - kpi-analytics/SCORE-METHODOLOGY.md
  - kpi-analytics/RCM_KPI_Claim_Impact_Methodology.md
last_updated: "2026-07-25"
---

# Work Queue Data Processor – Development Plan

Living plan that captures current pain points, proposed solutions, phased delivery, and design decisions for the next evolution of the Work Queue scoring and export tools.

**Document version:** 0.3.0  
**Status:** current  
**Related:** [README.md](./README.md) · [RULES.md](./RULES.md) · [FILE-CATALOG.md](./FILE-CATALOG.md) · [WQ_Priority_Matrix_Concept.md](./WQ_Priority_Matrix_Concept.md) · [kpi-analytics/SCORE-METHODOLOGY.md](./kpi-analytics/SCORE-METHODOLOGY.md)

---

## Summary

This plan addresses four concrete product gaps while preserving the repository’s non-negotiable constraints (runtime separation of Python and PowerShell toolkits, stdlib-only KPI code, full explainability, offline/enterprise posture, and no real PHI).

The work is organized into four related tracks, delivered in **three efficiency-focused releases** (not a product overhaul):

1. **Dynamic column identification and mapping** – remove rigid header expectations; optional mapping profiles; availability-aware metrics.  
2. **Aging terminology and Balance-Weighted Days Outstanding** – rename claim-level age to `claim_age_days`; adopt BWDO as a first-class priority metric.  
3. **Additional high-value metrics** for AR follow-up prioritization (batched with terminology in one breaking metric contract).  
4. **Simplified CLI / menu flow** – streamline Import → Validate/Map → Score → Export.

**No complete overhaul:** the dual `v1_*` / `kpi_q_*` pipeline, stdlib runtime, diagnostics gates, and schema-as-vocabulary remain. Changes are adapters, vocabulary, metric coverage, and menu UX.

---

## Contents

1. [Summary](#summary)
2. [Current state and pain points](#1-current-state-and-pain-points)
3. [Guiding principles](#2-guiding-principles)
4. [Track 1 – Dynamic column identification and mapping](#3-track-1--dynamic-column-identification-and-mapping)
5. [Track 2 – Aging terminology and Balance-Weighted Days Outstanding](#4-track-2--aging-terminology-and-balance-weighted-days-outstanding)
6. [Track 3 – Additional key metrics for AR follow-up](#5-track-3--additional-key-metrics-for-ar-follow-up)
7. [Track 4 – CLI and menu simplification](#6-track-4--cli-and-menu-simplification)
8. [Phased delivery (efficiency releases)](#7-phased-delivery-efficiency-releases)
9. [Success criteria and verification](#8-success-criteria-and-verification)
10. [Risks and non-goals](#9-risks-and-non-goals)
11. [Immediate next actions](#10-immediate-next-actions)
12. [Document history](#11-document-history)

---

## 1. Current state and pain points

### 1.1 Rigid column contract

- Scoring depends on a fixed field map in `kpi-analytics/kpi_modules/config_default.json` (`service_date`, `out_ins_amt`, `billed_amount`, `days_until_appeal_deadline`, `days_on_wq_tab`).
- **R1 (kpi 1.9.0):** role resolution + optional `--mapping` profile + alias auto-detect; metrics with missing roles are skipped and weights re-normalized.
- Mapping never mutates `wq_schema.json`.

### 1.2 Misleading “AR Days” terminology

- Per-claim age is currently computed and labeled as `ar_days` = `as_of_date − service_date`.
- Portfolio “Days in AR” (Total AR ÷ ADC) is a different concept.
- **Locked for R2:** rename claim-level key to **`claim_age_days`** (and `ar_disparity` → `claim_age_disparity`).

### 1.3 Limited aging and prioritization signals

- Schema fields such as `denial_count`, `last_worked_date`, `days_until_replacement_deadline` are unused by priority V1.
- **Locked for R2:** Balance-Weighted Days Outstanding as a full weighted priority metric with audit columns.

### 1.4 Menu and CLI cognitive load

- `Start-ExcelMenu.ps1` currently presents eight top-level options plus schema and diagnostics sub-menus.
- Primary pipeline is already option 1; R3 simplifies further.

---

## 2. Guiding principles

These constraints come directly from [RULES.md](./RULES.md) and the existing architecture and must not be violated:

| Principle | Implication for this plan |
|-----------|---------------------------|
| Runtime separation | Python scores; PowerShell/Excel only formats and presents. No COM from Python, no scoring math in PowerShell. |
| Stdlib-only product code | All new KPI logic stays in pure Python 3.13 standard library. |
| Full explainability | Every new metric ships with raw / norm / weight / contrib (or equivalent) audit columns. |
| Offline / enterprise | No network, no elevation, no permanent policy changes, diagnostics gates remain. |
| No real PHI | Mapping UI and synthetic data stay de-identified; privacy masking continues. |
| Schema is canonical | `wq_schema.json` remains the vocabulary; mapping is a runtime adapter. |
| Breaking changes are explicit | Field renames, new scored columns, and CLI contract changes require version bump, methodology update, fixture refresh, and CHANGELOG entry in the same change set. |
| Unique outputs by default | Existing files are never clobbered without an explicit force flag. |

---

## 3. Track 1 – Dynamic column identification and mapping

### Goal

Make the tools tolerant of real-world WQ extracts whose headers do not exactly match the schema `field_name` values, while still producing correct, explainable scores.

### Design (implemented in R1 / kpi-analytics 1.9.0)

1. **Role-based fields** — semantic roles equal config `fields` keys (`service_date`, `out_ins_amt`, …).  
2. **Header inspection on every `score` run** — case-insensitive, whitespace-tolerant; alias synonyms; optional mapping profile override.  
3. **Mapping profile JSON** — `roles: { role: "Source Column" }`; CLI `--mapping PATH`.  
4. **Availability-aware priority** — missing roles disable dependent metrics; weights re-normalized over active metrics; summary + CLI JSON list active/skipped.  
5. **Schema untouched** — mapping never mutates `wq_schema.json`.

Interactive console mapping menu remains optional for a later menu polish (R3 or follow-up); automation uses auto-detect and/or an explicit profile.

---

## 4. Track 2 – Aging terminology and Balance-Weighted Days Outstanding

### 4.1 Terminology (locked for R2)

| Current label | Problem | Locked label |
|---------------|---------|--------------|
| `ar_days` (per claim) | Confusable with portfolio “Days in AR” | **`claim_age_days`** |
| `ar_disparity` | Same root confusion | **`claim_age_disparity`** |
| Portfolio Days in AR | Correct (T / ADC) | Keep **Days in AR** |

### 4.2 Balance-Weighted Days Outstanding (locked for R2)

| Scope | Metric | Formula |
|-------|--------|---------|
| Per claim | `balance_weighted_days_outstanding` | `(out_ins_amt / billed_amount) × claim_age_days` (guard zero/negative billed) |
| Work-queue aggregate | Summary / chaos inputs | `Σ(out_ins_amt × claim_age_days) / Σ(out_ins_amt)` |

- Always label **Balance-Weighted Days Outstanding** (never “AR Days”).  
- Full weight + audit columns; **additional** signal alongside claim age, not a silent replacement.  
- Configurable enable/disable and weight like other priority metrics.

---

## 5. Track 3 – Additional key metrics for AR follow-up

**Initial R2 scope (High items only):**

| Priority | Metric | Required roles / fields |
|----------|--------|--------------------------|
| High | Repeat-denial signal | `denial_count` |
| High | Days since last worked | `last_worked_date` + as_of |
| High | Dual-deadline urgency | appeal + replacement deadline days |
| High | Balance-Weighted Days Outstanding | balance + billed + service_date |

Medium/Lower items (category concentration, payer concentration) stay later.

All new metrics: availability-aware, vertical summary rows, `priority_score ≈ sum(contrib_*)`.

---

## 6. Track 4 – CLI and menu simplification

### Target user flow

```text
Select / place data (import\ or path)
        ↓
Validate headers → mapping profile if needed
        ↓
Score (priority + KPI Q + new metrics)
        ↓
Export scored + summary to Excel (unique paths)
```

### Proposed menu shape (R3)

1. **Run full pipeline**  
2. **Score only**  
3. **Export existing CSV to Excel**  
4. Open folders / Diagnostics / Advanced tools  
0. Exit  

Automation contracts (`kpi-analytics.cmd`, `excel-toolkit.cmd`) stay stable.

---

## 7. Phased delivery (efficiency releases)

| Release | Focus | Versions | Status |
|---------|-------|----------|--------|
| **R1** | Mapping foundation: roles, aliases, `--mapping`, availability renorm, summary/CLI reporting | repo **1.1.0**, kpi-analytics **1.9.0** | **Shipped** |
| **R2** | Single breaking metric contract: `claim_age_days` + High metrics + BWDO + docs/fixtures | repo **1.2.0**, kpi-analytics **2.0.0** | **Shipped** |
| **R3** | Menu simplification | repo **1.3.0**, excel-toolkit **1.5.0** | Planned |

**Why this order:** R1 unblocks real extracts without rewriting golden scored columns. R2 batches all `METRIC_KEYS` / fixture / methodology churn into one major. R3 is pure UX after the pipeline is resilient.

**Why not overhaul:** architecture, dual attribution, diagnostics, and privacy already meet enterprise constraints; pain points are adapter/vocabulary/coverage/menu.

Each release ends with: canonical docs, FILE-CATALOG if needed, CHANGELOG, RULES verification (pylint, validate-score, diagnostics as applicable).

---

## 8. Success criteria and verification

| Track | Success looks like | Minimum verification |
|-------|--------------------|----------------------|
| Mapping (R1) | Non-schema headers score via auto-detect or one mapping profile; skipped metrics reported | Unit resolve + e2e misnamed headers; validate-score green |
| Terminology (R2) | No claim-level “AR Days” for simple age; keys are `claim_age_days` | Methodology + summary + CLI JSON |
| New metrics (R2) | Four High items with audit columns + vertical summary | validate-score + fixtures |
| Menu (R3) | Primary pipeline first; advanced one level deeper | Manual walkthrough + diagnostics |
| Overall | RULES constraints hold | Contributor checklist |

---

## 9. Risks and non-goals

**Risks**

- Interactive mapping UI complexity → keep console/profile first (R1).  
- Weight redistribution → document and keep deterministic (R1).  
- Breaking renames → single R2 major with migration notes.

**Non-goals**

- Automatic true ADC from practice systems.  
- Full HIPAA Safe Harbor beyond existing privacy masking.  
- Merging Python and PowerShell runtimes.  
- Adding pip packages or network calls.  
- Replacing the schema with free-form column names.

---

## 10. Immediate next actions

1. ~~Lock `claim_age_days` and full BWDO.~~ **Done.**  
2. ~~Ship R1 mapping foundation (kpi 1.9.0).~~ **Done.**  
3. ~~Design-note dual-deadline + default 2.0 weights; implement R2.~~ **Done (kpi 2.0.0).**  
4. R3 menu simplification (next).

---

## 11. Document history

| Version | Notes |
|---------|--------|
| 0.1.0 | Initial draft. Four tracks; BWDO evaluation; P0–P3 phases. |
| 0.2.0 | Efficiency releases R1–R3; lock `claim_age_days` + full BWDO; reject overhaul; R1 mapping foundation shipping with kpi-analytics 1.9.0. |
| 0.3.0 | R2 shipped: metric contract 2.0 (claim_age_days, BWDO, High metrics); next is R3 menu. |
