---
title: Cluster 3 — grouping, sorting, and denial analysis sheet
description: Design-freeze checklist for post-score analysis; keep reporting-only vs V2 boundary explicit.
version: "1.0.0"
status: developing
audience:
  - developers
  - analysts
doc_type: other
related:
  - ../../PLAN.md
  - ../PLAN.md
  - ../WQ_Priority_Matrix_Concept.md
  - ../../kpi-analytics/SCORE-METHODOLOGY.md
  - ../../kit/RULES.md
last_updated: "2026-08-10"
---

# Cluster 3 — grouping, sorting, and denial analysis sheet

**Status:** developing (not implementation-ready).  
**Primary surface:** post-score reporting (both toolkits as needed).  
**Product backlog owner:** [docs/PLAN.md](../PLAN.md) § Cluster 3.  
**Root stage:** [PLAN.md](../../PLAN.md) **S4**.  
**V2 design (not this cluster):** [WQ_Priority_Matrix_Concept.md](../WQ_Priority_Matrix_Concept.md).

---

## Summary

Beyond default priority ranking: group/filter helpers, multi-sort, and a denial-category analysis sheet on summary Excel. Closest cluster to V2 design territory—**reporting-only** work may ship under this plan; anything that changes priority formulas is **V2**, not Cluster 3.

**Gate:** freeze open questions and V2 boundary **before** product code.

---

## Contents

1. [Summary](#summary)
2. [Intent slices](#intent-slices)
3. [Open questions (must freeze)](#open-questions-must-freeze)
4. [V2 boundary](#v2-boundary)
5. [Hard constraints](#hard-constraints)
6. [Acceptance outline (after freeze)](#acceptance-outline-after-freeze)
7. [Document history](#document-history)

---

## Intent slices

| ID | Intent |
|----|--------|
| **3.1** | Group qualifier (e.g. balance or DOS filters by patient) while preserving scored detail |
| **3.2** | Multiple explicit sort keys on scored output / Excel |
| **3.3** | Analysis sheet on summary workbook (denial categories + metrics) |

---

## Open questions (must freeze)

| # | Question | Notes |
|---|----------|--------|
| 1 | Filter language (sum thresholds, date windows, combinations) | Privacy: patient tokens vs names |
| 2 | Grouping at score-time vs post-score CSV vs Excel-only | Prefer post-score |
| 3 | Stable secondary sort keys | Deterministic ordering |
| 4 | Category columns (`code_category`, `reason_code_list`, …) | Configurable role |
| 5 | Metrics per category | Count, outstanding, avg priority, aging distribution |

---

## V2 boundary

| In Cluster 3 (if frozen) | Out of scope (V2 concept) |
|--------------------------|---------------------------|
| Reporting sheets / sorts / filters | New weighted priority metrics |
| Denial category **summaries** | Denial volume/velocity **in** `v1_priority_score` |
| No change to dual `kpi_q_*` model | Recovery probability / capacity (V3) |

If analysis begins to feed priority weights, re-scope under [WQ_Priority_Matrix_Concept.md](../WQ_Priority_Matrix_Concept.md) V2 and a new plan version.

---

## Hard constraints

- Explainable scores and dual RCM attribution preserved  
- Toolkit runtime separation  
- Privacy masking interaction documented for any patient grouping  
- Certification after product code  
- Canonical docs co-updated (CLI-GUIDE / SCORE-METHODOLOGY / Excel README as applicable)  

---

## Acceptance outline (after freeze)

- [ ] Open questions frozen; V2 boundary signed off  
- [ ] docs/PLAN.md Cluster 3 status updated  
- [ ] Root PLAN stage S4 note updated  
- [ ] Implementation does not alter V1 metric keys without versioned contract change  

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | Extracted freeze checklist from docs/PLAN Cluster 3 for kit docs/plan surface |
