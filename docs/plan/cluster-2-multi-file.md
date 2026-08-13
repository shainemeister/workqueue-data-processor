---
title: Cluster 2 — multi-file, aggregation, and output conventions
description: Design freeze for multi-file / naming / default-xlsx / preview; per-file scores; groups do not span files.
version: "1.1.0"
status: current
audience:
  - developers
  - analysts
doc_type: other
related:
  - ../../PLAN.md
  - ../PLAN.md
  - ../WORKBOARD.md
  - ../../kit/RULES.md
  - ../../kit/rules/architecture.md
  - ../../excel-toolkit/README.md
  - ../../kpi-analytics/SCORE-METHODOLOGY.md
  - ../../wq_schema/wq_schema.json
  - ../research/2026-08-12-worklist-grouping-and-industry-metrics.md
  - ./post-v1-enhancement/ooo.md
last_updated: "2026-08-12"
---

# Cluster 2 — multi-file, aggregation, and output conventions

**Document version:** 1.1.0  
**Status:** **freeze signed** (P7). Product code is **P8** — do not start it in this file.  
**Primary surface:** excel-toolkit menu / workflow (kpi-analytics only if a later rollup verb is required).  
**Product backlog owner:** [docs/PLAN.md](../PLAN.md) § Cluster 2.  
**Root stage:** [PLAN.md](../../PLAN.md) **S3**.  
**Live OOO:** [WORKBOARD](../WORKBOARD.md) · annex [post-v1-enhancement](./post-v1-enhancement/).  
**Signed:** 2026-08-12 (P7 proceed).

---

## Summary

When operators multi-select CSV/XLSX under `import\`, today each file is scored **per file** (batch-relative norms). Cluster 2 is **delivery UX** on top of that: a Work Queue **label**, predictable Excel names, preview before score, and optional **file-level** totals. It is **not** a new score and **not** a cross-file worklist.

**Gate:** this freeze is the Cluster 2 gate. P8 may implement only what is frozen here.

| Must | Must not |
|------|----------|
| Keep **per-file** `score` (batch-relative `v1_*` / `kpi_q_*`) | Concatenate files and re-score as one batch |
| Treat **one input file = one WQ label** (stem, or `wq_label`) | Add a required schema WQ-name field in P8 |
| Keep **per-file** groups / worklists (P4–P6) | Merge `*_groups.csv` across files |
| Write intermediate scored CSV (unique-path policy) | Clobber outputs; menu `-Force` |
| Preview **without** calling `score` | Parse PHI into preview banners |
| Excel as the **human** deliverable | Delete CSV artifacts or put priority math in PowerShell |

---

## Contents

1. [Summary](#summary)
2. [Intent slices](#intent-slices)
3. [Frozen decisions](#frozen-decisions)
4. [Cross-file groups (program trigger)](#cross-file-groups-program-trigger)
5. [Hard constraints](#hard-constraints)
6. [P8 slice order (not an implementation OOO)](#p8-slice-order-not-an-implementation-ooo)
7. [Acceptance outline](#acceptance-outline)
8. [Document history](#document-history)

---

## Intent slices

| ID | Intent | Freeze |
|----|--------|--------|
| **2.1** | Totals (and optional combined **view**) by Work Queue identity | File-level reporting only; no combined **score** |
| **2.2** | Output naming `[WQ]_MM-DD-YYYY.xlsx` | Excel deliverable only; date = export calendar date |
| **2.3** | Prefer `.xlsx` as the human deliverable | CSVs stay as engine artifacts |
| **2.4** | Multi-file preview before score | Name, row count, max `out_ins_amt`; no `score` |

Canonical narrative: [docs/PLAN.md](../PLAN.md) Cluster 2 sections.

---

## Frozen decisions

| # | Question | Decision |
|---|----------|----------|
| 1 | **WQ identity** | **Filename stem** of the processable CSV (after any Excel→CSV import). Override: profile `wq_label` when that profile is applied to the batch, or a later optional operator label. `wq_status` is a **row** status — not identity. **No** new required `wq_schema` field in P8. |
| 2 | **Combined vs per-file scoring** | **Per-file only.** Minmax / `kpi_q_*` shares stay batch-relative to that file. A “combined view” is presentation of separately scored outputs (e.g. one workbook per file, or a rollup of **file-level** counts and dollars). |
| 3 | **Where aggregation lives** | Per-file groups: already kpi-analytics `--group-by` / `--group-preset` (shipped). File-level / by-WQ **totals**: post-score **presentation** (Excel sheet or a later optional kpi rollup of **existing** columns). No new V1 metrics. No priority/KPI **formula** in PowerShell. |
| 4 | **What totals means** | Per file: row count, `sum(out_ins_amt)`, `sum(billed_amount)`, `max(v1_priority_score)`, `min(days_until_appeal_deadline)` when present. **Do not** average `v1_priority_score`. **Do not** sum `kpi_q_share_*` or aging **Δ pp** **across files** (those percents are that file’s batch). Cross-file rollup, if built: **count + dollars only**. |
| 5 | **Date source for naming** | System **local calendar date of the Excel export** (`MM-DD-YYYY`). Not `as_of_date` (`as_of_date` is the score aging anchor). No operator date override in the first P8 slice. Collisions: existing unique `name_N` suffix. |
| 6 | **Intermediate scored CSV** | **Yes.** Score-only and automation keep CSV. Unique-path policy unchanged. Menu never uses `-Force` / `--force`. |
| 7 | **Preview metrics** | For each selected file (after import): file name, WQ label (stem), data row count, **max** `out_ins_amt` if that header exists and parses as numeric. Always when **2+** files; single-file preview may be skipped. **Must not** call `score`. Missing amount column → omit max, still show name + count. |

Sanitize WQ label for filenames: keep letters, digits, underscore, hyphen; replace other characters with `_`; empty stem → `wq`.

---

## Cross-file groups (program trigger)

P7 exists in [post-v1-enhancement](./post-v1-enhancement/ooo.md) because Cluster 3 left **cross-file groups** blocked on WQ identity.

**Frozen:** groups and worklists **do not span files**.

| Case | Behavior |
|------|----------|
| One file | P4–P6 groups / Worklist unchanged |
| Several files, several stems | One scored output + groups + worklist **per file** |
| Several files, same stem | Still **per file** (unique output paths). Do not merge groups. Operator who needs one worklist concatenates **before** `score` (out of product). |

A later by-WQ **dollar/count** rollup (2.1) is **not** a groups CSV and **not** a two-level worklist.

---

## Hard constraints

From [kit/RULES.md](../../kit/RULES.md) / architecture / [SCORE-METHODOLOGY](../../kpi-analytics/SCORE-METHODOLOGY.md):

- No scoring math in PowerShell; no Excel COM from Python  
- Composition via files + `kpi-analytics.cmd` subprocess only  
- Non-clobber outputs (`name_N` unless Force)  
- No PHI in profiles, preview banners, or tracked samples  
- Full certification after product/gate changes (P8, not this freeze)  
- Same change set: code + CLI-GUIDE / README + CHANGELOG + FILE-CATALOG when P8 ships  

---

## P8 slice order (not an implementation OOO)

Do **not** expand this into a phase novel until P8 is `active` on the board.

| Order | Slice | Notes |
|-------|--------|--------|
| 1 | **2.4** preview | Cheapest; no score; no naming contract |
| 2 | **2.2** Excel name | Human `.xlsx` only; CSV stems stay as today |
| 3 | **2.3** wording | Menu/README: Excel is the deliverable; CSV remains |
| 4 | **2.1** file-level totals | Last; presentation of already-scored columns; no combined score |

---

## Acceptance outline

- [x] Open questions table marked **frozen** (this file 1.1.0)  
- [x] Cross-file groups: **no** (per-file worklists)  
- [x] docs/PLAN.md Cluster 2 status → freeze signed / P8 ready (same change set)  
- [x] Root PLAN stage S3 note updated (same change set)  
- [ ] P8 product: dual toolkit boundaries; full certification  
- [ ] P8 must not alter V1 metric keys or combine files for `score`  

---

## Document history

| Version | Notes |
|---------|--------|
| 1.1.0 | P7 freeze: per-file score; filename / `wq_label` identity; no schema WQ field; groups do not span files; preview/naming/xlsx-as-deliverable signed |
| 1.0.0 | Extracted freeze checklist from docs/PLAN Cluster 2 for kit docs/plan surface |
