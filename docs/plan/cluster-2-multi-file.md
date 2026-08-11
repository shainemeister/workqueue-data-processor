---
title: Cluster 2 — multi-file, aggregation, and output conventions
description: Design-freeze checklist before multi-file / naming / default-xlsx product code.
version: "1.0.0"
status: developing
audience:
  - developers
  - analysts
doc_type: other
related:
  - ../../PLAN.md
  - ../PLAN.md
  - ../../kit/RULES.md
  - ../../kit/rules/architecture.md
  - ../../excel-toolkit/README.md
  - ../../wq_schema/wq_schema.json
last_updated: "2026-08-10"
---

# Cluster 2 — multi-file, aggregation, and output conventions

**Status:** developing (not implementation-ready).  
**Primary surface:** excel-toolkit menu / workflow (light kpi-analytics only if needed).  
**Product backlog owner:** [docs/PLAN.md](../PLAN.md) § Cluster 2.  
**Root stage:** [PLAN.md](../../PLAN.md) **S3**.

---

## Summary

When operators multi-select CSV/XLSX under `import\`, today each file is scored **per file** (batch-relative norms). Cluster 2 aims for by-WQ totals, predictable naming, default Excel deliverable, and multi-file preview—without breaking toolkit independence or non-clobber outputs.

**Gate:** freeze open questions below **before** product code.

---

## Contents

1. [Summary](#summary)
2. [Intent slices](#intent-slices)
3. [Open questions (must freeze)](#open-questions-must-freeze)
4. [Hard constraints](#hard-constraints)
5. [Acceptance outline (after freeze)](#acceptance-outline-after-freeze)
6. [Document history](#document-history)

---

## Intent slices

| ID | Intent |
|----|--------|
| **2.1** | Ingest multiple files; totals (and optional combined view) by Work Queue identity |
| **2.2** | Output naming convention `[WQ]_MM-DD-YYYY.xlsx` (or documented variant) |
| **2.3** | Prefer default deliverable `.xlsx`; CSV for score-only / automation |
| **2.4** | Multi-file preview: names, row counts, max of key metric before score |

Canonical narrative: [docs/PLAN.md](../PLAN.md) Cluster 2 sections.

---

## Open questions (must freeze)

| # | Question | Default assumption until freeze |
|---|----------|----------------------------------|
| 1 | Source of **WQ identity** (no schema WQ-name field) | Filename convention and/or operator label; optional later schema role |
| 2 | **Combined vs per-file** scoring | Per-file only (preserve batch-relative norms) |
| 3 | Where **aggregation** lives | Prefer post-score excel-toolkit / new verb only if needed |
| 4 | What **totals** means | Document row count, sum `out_ins_amt`, selected `kpi_q_*`, avg priority |
| 5 | Date source for naming | `as_of_date` vs system date vs operator override |
| 6 | Intermediate scored CSV still written? | Likely yes under unique path policy |
| 7 | Preview metrics | Default max `out_ins_amt`; optional others |

---

## Hard constraints

From [kit/RULES.md](../../kit/RULES.md) / architecture:

- No scoring math in PowerShell; no Excel COM from Python  
- Composition via files + `kpi-analytics.cmd` subprocess only  
- Non-clobber outputs (`name_N` unless Force)  
- No PHI in profiles or tracked samples  
- Full certification after product/gate changes  
- Same change set: code + CLI-GUIDE / README + CHANGELOG + FILE-CATALOG  

---

## Acceptance outline (after freeze)

- [ ] Open questions table marked **frozen** with owners/dates  
- [ ] docs/PLAN.md Cluster 2 status → ready / implementing  
- [ ] Root PLAN stage S3 note updated  
- [ ] Implementation PRs follow dual toolkit boundaries  
- [ ] Cert harness green when product code ships  

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | Extracted freeze checklist from docs/PLAN Cluster 2 for kit docs/plan surface |
