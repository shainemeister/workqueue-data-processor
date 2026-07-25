---
title: Work Queue Data Processor – Development Plan
description: Living plan for dynamic column mapping, improved aging terminology and metrics, adaptive KPI generation, and simplified end-user workflow.
version: "0.1.0"
status: draft
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

**Document version:** 0.1.0  
**Status:** draft  
**Related:** [README.md](./README.md) · [RULES.md](./RULES.md) · [FILE-CATALOG.md](./FILE-CATALOG.md) · [WQ_Priority_Matrix_Concept.md](./WQ_Priority_Matrix_Concept.md) · [kpi-analytics/SCORE-METHODOLOGY.md](./kpi-analytics/SCORE-METHODOLOGY.md)

---

## Summary

This plan addresses four concrete product gaps while preserving the repository’s non-negotiable constraints (runtime separation of Python and PowerShell toolkits, stdlib-only KPI code, full explainability, offline/enterprise posture, and no real PHI).

The work is organized into four related tracks:

1. **Dynamic column identification and mapping** – remove rigid header/order expectations and add an interactive correction path when required fields are missing or misnamed.
2. **Aging terminology and metrics** – stop calling simple claim age “AR Days”; adopt clearer labels and introduce a practical **Balance-Weighted Days Outstanding** proxy.
3. **Additional high-value metrics** for AR follow-up prioritization.
4. **Simplified CLI / menu flow** – streamline the primary path to Import → Validate/Map → Score → Export and reduce the number of competing entry points.

The plan also evaluates and recommends incorporation of the Balance-Weighted Days Outstanding concept as a core improvement to the aging family of metrics.

---

## Contents

1. [Summary](#summary)
2. [Current state and pain points](#1-current-state-and-pain-points)
3. [Guiding principles](#2-guiding-principles)
4. [Track 1 – Dynamic column identification and mapping](#3-track-1--dynamic-column-identification-and-mapping)
5. [Track 2 – Aging terminology and Balance-Weighted Days Outstanding](#4-track-2--aging-terminology-and-balance-weighted-days-outstanding)
6. [Track 3 – Additional key metrics for AR follow-up](#5-track-3--additional-key-metrics-for-ar-follow-up)
7. [Track 4 – CLI and menu simplification](#6-track-4--cli-and-menu-simplification)
8. [Phased delivery](#7-phased-delivery)
9. [Success criteria and verification](#8-success-criteria-and-verification)
10. [Risks and non-goals](#9-risks-and-non-goals)
11. [Immediate next actions](#10-immediate-next-actions)
12. [Document history](#11-document-history)

---

## 1. Current state and pain points

### 1.1 Rigid column contract

- Scoring depends on a fixed field map in `kpi-analytics/kpi_modules/config_default.json` (`service_date`, `out_ins_amt`, `billed_amount`, `days_until_appeal_deadline`, `days_on_wq_tab`).
- Headers must match `field_name` values exactly; order is not enforced but naming is.
- Missing or differently named columns cause silent degradation (missing norms default to 0) or hard failures depending on the path.
- There is no interactive way for a user to map an arbitrary WQ extract to the required semantic roles.

### 1.2 Misleading “AR Days” terminology

- Per-claim age is currently computed and labeled as `ar_days` = `as_of_date − service_date`.
- Portfolio “Days in AR” (Total AR ÷ ADC) is a different concept.
- Calling the claim-level figure “AR Days” creates confusion with the industry standard portfolio metric and with true net-revenue AR Days.

### 1.3 Limited aging and prioritization signals

- Current priority metrics are solid for V1 but under-use several already-available schema fields (`denial_count`, `last_worked_date`, `days_until_replacement_deadline`, `code_category`, etc.).
- No balance-weighted aging proxy exists.

### 1.4 Menu and CLI cognitive load

- `Start-ExcelMenu.ps1` currently presents eight top-level options plus schema and diagnostics sub-menus.
- Multiple export variants and a separate import path compete with the primary “Score CSV → Excel” pipeline.
- Users who simply want “import data → score → Excel” face more choices than necessary.

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

### Design direction

1. **Role-based required fields**  
   Define a small set of semantic *roles* that scoring needs (examples):

   | Role | Purpose | Typical source columns |
   |------|---------|------------------------|
   | `service_date` | Claim age / DOS | Service Date, DOS, Bill Date |
   | `balance` | Outstanding insurance amount | Out. Ins. Amt., Balance, Remaining |
   | `billed_amount` | Gross charges (for weighting) | Billed Amount, Charges |
   | `appeal_deadline_days` | Appeal urgency | Days Until Appeal Deadline |
   | `wq_age_days` | Days on current WQ tab | Days on WQ Tab |
   | `last_worked_date` | Staleness | Last Worked Date |
   | `denial_count` | Repeat-denial signal | Denial Count |

2. **Header inspection on every score / pipeline run**  
   - Detect present columns (case-insensitive, whitespace-tolerant matching where safe).  
   - Report missing roles and any ambiguous matches.

3. **Interactive mapping menu** (triggered only when validation fails or the user requests it)  
   - Show detected headers and the list of required/optional roles.  
   - Allow the user to manually join a source column to a role.  
   - Support saving a mapping profile (JSON) for reuse with the same extract type.  
   - Mapping lives outside the core scoring engine; the engine continues to receive a clean, role-resolved view.

4. **Availability-aware KPI / priority generation**  
   - If a metric’s required roles are absent after mapping, that metric is disabled for the run.  
   - Weights are re-normalized over the remaining active metrics.  
   - Summary report and CLI JSON clearly list which metrics ran and which were skipped (with reason).

5. **Schema remains the source of truth**  
   - Mapping never mutates `wq_schema.json`.  
   - Display labels still come from schema when present.

### Implementation notes

- Prefer a pure-Python mapping helper inside `kpi_modules` for the scoring path.  
- The Excel menu can host a simple console mapping UI that writes a temporary or named mapping file consumed by `kpi-analytics.cmd score`.  
- Keep the interactive path optional; automation users continue to supply correctly named CSVs or an explicit mapping file.

---

## 4. Track 2 – Aging terminology and Balance-Weighted Days Outstanding

### 4.1 Terminology change

| Current label | Problem | Proposed label |
|---------------|---------|----------------|
| `ar_days` (per claim) | Confusable with portfolio “Days in AR” and industry AR Days | **`claim_age_days`** (or `days_outstanding`) |
| Portfolio Days in AR | Correct concept (T / ADC) | Keep **Days in AR** |

All user-facing text, column names (`v1_raw_claim_age_days`, etc.), methodology, fixtures, and config keys will be updated in a coordinated breaking change.

### 4.2 Evaluation of Balance-Weighted Days Outstanding

The attached concept document is evaluated as follows.

**Strengths**

- Uses only fields already present in the schema and default config (`out_ins_amt`, `billed_amount`, `service_date`).
- Produces a practical, balance-sensitive aging signal when true net-revenue AR Days cannot be calculated at claim or work-queue level.
- Explicitly recommends clear labeling and avoids the “AR Days” name — perfect alignment with Track 2.
- Formula is simple and fully explainable (raw components can be emitted as audit columns).
- Aggregate form (Σ(balance × days) / Σ balance) is a natural addition to the vertical summary and to chaos-mode detection.

**Limitations (already acknowledged in the source document)**

- Relies on gross charges, not net revenue or contractual adjustments.
- Is a claim- or queue-level proxy only; must never be presented as industry-comparable AR Days.
- Does not incorporate payment history or denial adjustments.

**Recommendation**

Adopt **Balance-Weighted Days Outstanding** as a first-class metric family:

| Scope | Proposed column / metric | Formula |
|-------|--------------------------|---------|
| Per claim | `balance_weighted_days_outstanding` | `(out_ins_amt / billed_amount) × claim_age_days` (guard against zero/negative billed) |
| Work-queue aggregate | Reported in summary CSV and chaos logic | `Σ(out_ins_amt × claim_age_days) / Σ(out_ins_amt)` |

Implementation rules:

- Always label it **Balance-Weighted Days Outstanding** (never “AR Days”).
- Emit intermediate components (`claim_age_days`, balance ratio) as audit columns when the metric is active.
- Make it configurable (enable/disable, weight) like other priority metrics.
- Prefer it as an additional or alternative aging signal rather than a silent replacement of simple claim age, so both remain visible for audit.

This metric directly improves prioritization value for insurance follow-up while solving the terminology problem.

---

## 5. Track 3 – Additional key metrics for AR follow-up

Building on the existing schema and the V2 ideas already sketched in [WQ_Priority_Matrix_Concept.md](./WQ_Priority_Matrix_Concept.md), the following candidates are ranked by expected operational value versus implementation cost.

| Priority | Metric | Required roles / fields | Value |
|----------|--------|--------------------------|-------|
| High | Repeat-denial signal | `denial_count` | Surfaces chronic / harder claims |
| High | Days since last worked | `last_worked_date` + as_of | Surfaces stale items that need attention |
| High | Dual-deadline urgency | appeal + replacement deadline days | Protects against permanent loss on both fronts |
| High | Balance-Weighted Days Outstanding | balance + billed + service_date | See Track 2 |
| Medium | Category / reason-code concentration | `code_category` or `reason_code_list` + balance | Identifies high-volume or high-dollar denial themes |
| Medium | High-balance tier flag | `out_ins_amt` thresholds | Simple operational focus filter |
| Lower (later) | Payer / plan concentration | `payer`, `plan` | Requires frequency aggregation; better as V2 |

**Initial scope for the first metrics expansion:** implement the four High items with full audit columns and weight support. Medium and Lower items move to a subsequent phase once the mapping layer is stable.

All new metrics must:

- Be availability-aware (disabled cleanly when inputs are missing).
- Appear in the vertical summary with formula and explanation.
- Preserve the identity `priority_score ≈ sum(contrib_*)`.

---

## 6. Track 4 – CLI and menu simplification

### Target user flow

```text
Select / place data (import\ or path)
        ↓
Validate headers → interactive mapping menu if needed
        ↓
Score (priority + KPI Q + new metrics)
        ↓
Export scored + summary to Excel (unique paths)
```

### Proposed menu shape (illustrative)

**Main menu**

1. **Run full pipeline** (select CSV → map if needed → score → Excel)  
2. **Score only** (CSV → scored + summary CSV)  
3. **Export existing CSV to Excel**  
4. Open folders / Diagnostics / Advanced tools  
0. Exit

**Advanced / Tools submenu** (schema management, pure import from Excel, environment info, pure diagnostics, etc.)

### Design rules

- The happy path should be reachable in one or two choices.
- Existing automation contracts (`kpi-analytics.cmd`, `excel-toolkit.cmd`) remain stable; simplification is primarily in the interactive menu and documentation.
- Schema management moves behind Advanced; it is no longer a top-level distraction.
- Multi-select and unique-path behavior already present in the pipeline are retained.

---

## 7. Phased delivery

| Phase | Focus | Key deliverables | Notes |
|-------|-------|------------------|-------|
| **P0 – Foundation** | Planning & decisions | This `PLAN.md`; finalize role list; lock terminology (`claim_age_days` + Balance-Weighted Days Outstanding); update FILE-CATALOG | Current phase |
| **P1 – Mapping & resilience** | Dynamic columns | Role detection, validation report, interactive mapping UI/menu, mapping file format, availability-aware scoring, docs + fixtures | Breaking only if scored column names change |
| **P2 – Menu & CLI simplification** | Workflow | Restructured `Start-ExcelMenu.ps1`, clearer primary path, Advanced submenu, updated root README quick-start and use-case table | Mostly UX; keep CLI verbs stable |
| **P3 – Metrics expansion** | Value | Implement High-priority metrics (repeat denial, days-since-last-worked, dual-deadline, Balance-Weighted Days Outstanding) with full audit columns and weight support | Coordinated version bump + methodology + fixtures + CHANGELOG |
| **Later** | V2 concepts | Category volume/velocity, richer concentration metrics, recovery-probability sketches | Builds on stable mapping layer |

Each phase ends with:

- Updated canonical docs (methodology, CLI guides, README as needed).
- FILE-CATALOG update for any new intentional files.
- CHANGELOG entry when behavior or contracts change.
- Verification from the RULES table (pylint, validate-score, diagnostics, etc.).

---

## 8. Success criteria and verification

| Track | Success looks like | Minimum verification |
|-------|--------------------|----------------------|
| Mapping | Real-world extracts with non-schema headers can be scored after one interactive mapping session; mapping can be saved and reused | Unit-style tests on role resolution; end-to-end score with deliberately misnamed headers |
| Terminology | No user-facing “AR Days” for the simple claim-age metric; Balance-Weighted Days Outstanding is clearly labeled | Methodology + summary report + CLI JSON review |
| New metrics | At least the four High items ship with audit columns and appear in the vertical summary | `validate-score` green; hand-check against fixtures |
| Menu | Primary pipeline is the first menu item and requires minimal decisions; advanced options are one level deeper | Manual walkthrough + existing diagnostics still pass |
| Overall | All RULES constraints still hold (stdlib, no force-kill, unique paths, privacy, no PHI in repo) | Full contributor checklist from RULES.md |

---

## 9. Risks and non-goals

**Risks**

- Interactive mapping UI complexity on locked-down PCs → keep it simple console/menu, no external UI frameworks.
- Weight redistribution when metrics are disabled → document the rule clearly and keep it deterministic.
- Breaking column renames → must be versioned and called out in CHANGELOG and migration notes.

**Non-goals (for the phases above)**

- Automatic true ADC calculation from practice systems.
- Full HIPAA Safe Harbor de-identification beyond the existing privacy masking.
- Merging Python and PowerShell runtimes.
- Adding pip packages or network calls.
- Replacing the schema with free-form column names (schema stays canonical).

---

## 10. Immediate next actions

1. Review and refine this plan (especially final names for claim age and the exact required role list).
2. Confirm adoption of **Balance-Weighted Days Outstanding** as a core aging metric.
3. Update [FILE-CATALOG.md](./FILE-CATALOG.md) to include `PLAN.md`.
4. Decide whether P1 (mapping) or a small terminology-only change should be the first code commit after the plan is accepted.
5. Once terminology is locked, prepare a coordinated breaking change set for column renames + methodology + fixtures.

---

## 11. Document history

| Version | Notes |
|---------|--------|
| 0.1.0 | Initial draft. Captures four tracks (dynamic mapping, aging terminology + Balance-Weighted Days Outstanding, new metrics, menu simplification), evaluates the attached Balance-Weighted concept, and defines phased delivery under existing RULES constraints. |
