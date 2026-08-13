---
title: post-v1-enhancement — order of operations
description: Goals, constraints, phased OOO, verification, and risks for grouped POI worklists and later Cluster 2 / B1.1.
version: "1.0.1"
status: draft
audience:
  - ai-agents
  - developers
  - analysts
doc_type: plan
related:
  - ./README.md
  - ../../WORKBOARD.md
  - ../../../PLAN.md
  - ../../PLAN.md
  - ../cluster-3-analysis.md
  - ../cluster-2-multi-file.md
  - ../b1.1-base-weight-retune.md
  - ../../research/2026-08-12-worklist-grouping-and-industry-metrics.md
  - ../../../kpi-analytics/SCORE-METHODOLOGY.md
  - ../../../wq_schema/wq_schema.json
  - ../../../kit/rules/workboard.md
last_updated: "2026-08-12"
---

# post-v1-enhancement — order of operations

**Board:** [docs/WORKBOARD.md](../../WORKBOARD.md)  
**Annex index:** [README.md](./README.md)  
**Research:** [worklist grouping and industry metrics](../../research/2026-08-12-worklist-grouping-and-industry-metrics.md)

---

## 1. Goals and non-goals

### Goals (must)

| ID | Goal |
|----|------|
| G1 | Let a follow-up rep work **groups** of claims (payer, denial type, patient, provider, location, …) sorted for efficient contact while targeting the active **POI** |
| G2 | Keep V1 `v1_*` scores and dual `kpi_q_*` **unchanged** (reporting / work-order layer only) |
| G3 | Freeze Cluster 3 **before** any grouping or sort product code |
| G4 | Leave Cluster 2 and B1.1 optional until their own freezes / evidence |

### Non-goals (must not in this program)

| Item | Why |
|------|-----|
| Category volume / velocity **inside** `v1_priority_score` | That is V2 ([WQ_Priority_Matrix_Concept](../../WQ_Priority_Matrix_Concept.md)); S5 |
| Net collection, denial *rate*, appeal success as labeled KPIs | Extract lacks payments, denominators, outcomes |
| Unmasking patient names in scored/git outputs | Privacy / RULES |
| Pip packages or Excel COM from Python | Architecture |
| Priority/KPI math in PowerShell | Architecture |
| Starting Cluster 2/3 code before freeze | PLAN `must_not_extra` |

### Invariants (hard)

```text
No Excel COM from Python; no priority/KPI math in PowerShell
No pip / network in product kpi-analytics
Do not clobber outputs by default
Do not collapse dual kpi_q_* or drop v1_* audit columns
No real PHI in git; patient groups honor score-output masking
Full certification after any product/code or gate change
Do not start Cluster 2/3 code until the matching freeze is signed
```

---

## 2. Constraint map

| Fact | Implication for the OOO |
|------|-------------------------|
| Scores are **batch-relative** | Do not rank groups by average `v1_priority_score` alone; prefer sum `$` / `kpi_q_*` |
| Schema has no WQ-name field | Cross-file groups wait on Cluster 2 identity |
| `reason_code_list` / CPT may be multi-value | Freeze must say raw vs first token vs explode |
| Default score masks `patient`, blanks `dob` | Patient groups use tokens unless an explicit unmask policy exists |
| Static `kpi_q_*` share sums; aging **Δ pp** does not | Group only additive families |
| Two toolkits join at files/CLI | Group math in kpi-analytics; Excel only presents |

**Surfaces this program may touch** (later phases; P0–P1 touch docs only):

| Surface | Paths |
|---------|--------|
| Workboard / annex | `docs/WORKBOARD.md`, `docs/plan/post-v1-enhancement/` |
| Cluster 3 freeze | `docs/plan/cluster-3-analysis.md`, `docs/PLAN.md` |
| KPI CLI (P4+) | `kpi-analytics/CLI-GUIDE.md`, `kpi_modules/` |
| Excel (P5–P6) | `excel-toolkit/CLI-GUIDE.md`, menu scripts |
| Project history | `CHANGELOG.md` |
| Catalog | `docs/FILE-CATALOG.md` |

---

## 3. Master order of operations

```text
P0  Register program
   → board + annex linked (this open)
        │
        ▼
P1  Cluster 3 design freeze
   → cluster-3-analysis.md signed; still no product code
        │
        ▼
P2  Optional Excel rehearsal (option A)
   → synthetic scored workbook; keys look right
        │
        ▼
P3  Implement 3.2 multi-sort
   → first product code; post-score / Excel only
        │
        ▼
P4  Group summary CSV (option B)
   → kpi-analytics; aggregates of existing columns
        │
        ▼
P5  Excel groups + two-level worklist (C + D)
   → composition only
        │
        ▼
P6  Menu “Build worklist” (E)
   → only if P4–P5 exist
        │
        ▼
P7  Cluster 2 freeze (only if groups must span files)
        │
        ▼
P8  Cluster 2 implement
        │
        ▼
P9  B1.1 retune (analyst-gated; optional)
        │
        ▼
P10 V2/V3 — not this program
```

| Phase | Theme | Why this order |
|-------|--------|----------------|
| **P0** | Register | RULES: board before phase code |
| **P1** | Freeze worklists | Latest product goal; blocks all 3.x code |
| **P2** | Rehearse | Cheap; no CLI contract |
| **P3** | Multi-sort | Smallest post-score slice |
| **P4** | Groups CSV | Automatable; independent of Excel |
| **P5** | Excel worklist | Needs P4 (or equivalent) contract |
| **P6** | Menu | After file/sheet contract |
| **P7–P8** | Cluster 2 | WQ identity only if cross-file |
| **P9** | B1.1 | Independent; fixtures |
| **P10** | V2 | Out of program |

Defer per-phase implementation detail until that phase is `active` on the board.

### P1 straw men (not frozen)

| Topic | Straw man |
|-------|-----------|
| Default group key | `payer` + `code_category` |
| Optional keys | `patient` (tokens), `account`, `billing_provider`, `location` |
| Group rank | `sum(out_ins_amt)` then `sum(kpi_q_share_total_ar_pct)`; POI tie-breaks per research note |
| Output | Groups CSV **and** Excel sheet; detail preserved |
| Multi-value codes | First token until proven otherwise |
| Cross-file | Out of Cluster 3; Cluster 2 |

---

## 4. Verification

| Phase | Declared gates / checks |
|-------|-------------------------|
| P0 | Author checklist; FILE-CATALOG; relative links; no cert |
| P1 | Freeze file + `docs/PLAN.md` status same change set; no product code |
| P2 | Manual Excel on synthetic scored output |
| P3+ product | Full `.\certification\Invoke-Certification.ps1`; OverallPass; outputs unstaged |
| P4 | pylint `kpi_modules` 10.00/10 (via harness); CLI-GUIDE + fixtures if contract |
| P5–P6 | PSSA/parse on excel-toolkit product scripts (via harness) |
| P9 | Fixtures + SCORE-METHODOLOGY + CHANGELOG |

Do not invent gates outside the inventory / verification table.

---

## 5. Docs and CHANGELOG on ship

| Phase | L4 owners to update |
|-------|---------------------|
| P0 | FILE-CATALOG; plan indexes; WORKBOARD (this annex) |
| P1 | `docs/plan/cluster-3-analysis.md`; `docs/PLAN.md` |
| P3 | excel and/or kpi CLI if sort is a public flag |
| P4 | `kpi-analytics/CLI-GUIDE.md`; README; CHANGELOG; package version |
| P5–P6 | excel CLI-GUIDE / README / ENTERPRISE-SECURITY if trust model unchanged except new verb |
| P8 | excel + kpi contracts as frozen |
| P9 | SCORE-METHODOLOGY; `config_default.json`; CHANGELOG |

---

## 6. Risks and rollback

| Risk | Mitigation |
|------|------------|
| Treating group rank as a new priority score | Keep V1 columns; group file is a **separate** output |
| Averaging `v1_priority_score` | Ban as sole sort; use `$` / `kpi_q` sums |
| PHI via patient groups | Tokens only on scored output; no unmask in git |
| Cluster 3 vs V2 creep | Freeze repeats V2 boundary; category-in-score = P10 / S5 |
| Starting code during P1 | Board P1 stays `blocked` until freeze signed |
| Cross-file groups without WQ identity | Stay on P7–P8; per-file norms remain default |

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.1 | P3–P6 shipped; P1 filters still blocked |
| 1.0.0 | Initial master OOO at program open |
