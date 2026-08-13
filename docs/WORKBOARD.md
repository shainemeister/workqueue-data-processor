---
title: "workqueue-data-processor — Active Workboard"
description: Single source of truth for open multi-phase work. Product vision stays in PLAN.md; shipped contracts stay on L4 owners.
version: "1.1.17"
status: current
audience:
  - ai-agents
  - developers
doc_type: other
related:
  - ../PLAN.md
  - ../kit/rules/workboard.md
  - ../CHANGELOG.md
  - ./plan/post-v1-enhancement/README.md
  - ./plan/repo-kit-upgrade-2.4.0.md
last_updated: "2026-08-13"
---

# Workboard

**Updated:** 2026-08-13  
**Primary program:** `post-v1-enhancement`  
**Rules:** [kit/rules/workboard.md](../kit/rules/workboard.md) · [PLAN.md](../PLAN.md) (mission) · [docs/plan/](./plan/) (freeze notes)

| Status | Meaning |
|--------|---------|
| `open` | Not started |
| `active` | Current phase (prefer exactly one) |
| `blocked` | Waiting on user / decision |
| `done` | Shipped + verified + L4/CHANGELOG as required |
| `cancelled` | Explicitly dropped |
| `deferred` | Parked |

---

## Active program — post-v1-enhancement

| Field | Value |
|-------|--------|
| **Goal** | Grouped follow-up worklists targeting the active POI; reporting-only; V1 / `kpi_q_*` unchanged |
| **L4 docs to update** | After product phases: toolkit CLI-GUIDE / README; SCORE-METHODOLOGY only if formulas change (they must not). P0: FILE-CATALOG |
| **Optional annex** | [docs/plan/post-v1-enhancement/](./plan/post-v1-enhancement/) |
| **Smoke / gates** | P0–P1 docs only. P3+ : full `.\certification\Invoke-Certification.ps1` |

### Phases

| ID | Work | Status | Commit | Notes |
|----|------|--------|--------|-------|
| P0 | Register board + annex | `done` | `67b5c2a` | Annex + indexes |
| P1 | Cluster 3 design freeze (worklists / groups / sort / sheet) | `blocked` | — | Needs group key, output shape, privacy. [cluster-3-analysis.md](./plan/cluster-3-analysis.md) |
| P2 | Optional Excel rehearsal (option A) | `done` | `cb78d08` | Findings: [p2-rehearsal.md](./plan/post-v1-enhancement/p2-rehearsal.md) |
| P3 | Implement 3.2 multi-sort | `done` | `b3759d6` | kpi 2.8.0 `--sort` / `--sort-preset` (docs `bf66b2d`) |
| P4 | Group summary CSV (option B) | `done` | `a2e3601` | kpi 2.9.0 `--group-by` / `--group-preset` (docs `db334da`) |
| P5 | Excel groups / two-level worklist (C+D) | `done` | `cf14c23` | excel 1.10.0 `-GroupsCsv` / `-Worklist` (docs `20868cb`) |
| P6 | Menu Build worklist (E) | `done` | `926ed01` | excel 1.11.0 menu [4]; composition only |
| P7 | Cluster 2 design freeze | `done` | `d151313` | Per-file score; no cross-file groups; [cluster-2-multi-file.md](./plan/cluster-2-multi-file.md) |
| P8 | Cluster 2 implement | `done` | `322b6c6` | excel 1.12.0 preview / naming / Totals |
| P9 | B1.1 base-weight retune | `deferred` | — | Analyst-gated |
| P10 | V2/V3 in-score category metrics | `cancelled` | — | Not this program (S5) |
| P11 | Register audit-fix OOO | `done` | `df1cbe5` | Surgical P12–P14 from P3–P8 review |
| P12 | Worklist case-sensitive key match | `done` | `5f6622f` | excel 1.12.1; `-cne`; smoke 4 rows; cert pass |
| P13 | Cluster 3 PLAN wording | `done` | `851d86e` | Partial vs remaining 3.1 filters |
| P14 | Preview comment + kpi ENTERPRISE 2.9.0 | `done` | `851d86e` | No trust-boundary change |
| P15 | Freeze slim multi-POI detail output | `done` | `114ac02` | [slim-poi-output.md](./plan/slim-poi-output.md) |
| P16 | kpi `--output-mode slim` | `done` | `114ac02` | 2.10.0; one norm pass |
| P17 | Slim golden fixture | `done` | `114ac02` | `slim_poi_expected.json`; cert check |
| P18 | Menu Full / Slim | `done` | `114ac02` | excel 1.13.0 compose |
| P19 | L4 + CHANGELOG + catalog | `done` | `114ac02` | repo 1.20.0 |
| P20 | Freeze Express POI Excel sheet | `done` | `cb20bb0` | slim-poi-output 1.1.0 |
| P21 | Menu [5] Express score | `done` | `cb20bb0` | slim; skip profile/password |
| P22 | export-csv -PoiScoreSheetOnly | `done` | `cb20bb0` | Copy columns; no math |
| P23 | L4 + CHANGELOG + cert | `done` | `cb20bb0` | excel 1.14.0 |
| P24 | Menu [5] Express visibility | `done` | `dcd1d1e` | Cyan + version stamp; lock in Test-SelectionRange |
| P25 | Freeze Express score-input source columns | `done` | `2c13194` | slim-poi-output 1.2.0 |
| P26 | Copy source-input columns on POI_Scores | `done` | `2c13194` | Present if present; no math |
| P27 | L4 + CHANGELOG + cert | `done` | `2c13194` | excel 1.15.0 |
| P28 | Freeze Express context source columns | `done` | `b9c0959` | slim-poi-output 1.3.0 |
| P29 | Copy context columns on POI_Scores | `done` | `b9c0959` | plan / codes / billing; `cpt_codes` |
| P30 | L4 + CHANGELOG + cert | `done` | `b9c0959` | excel 1.16.0 |

### Progress log (newest first, max ~15 lines)

- 2026-08-13 Shipped P28–P30 Express context source columns (`b9c0959`; excel 1.16.0).  
- 2026-08-13 Opened P28–P30 Express context source columns (plan / codes / billing).  
- 2026-08-13 Shipped P25–P27 Express score-input source columns (`2c13194`; excel 1.15.0).  
- 2026-08-13 Opened P25–P27 Express score-input source columns on `POI_Scores`.  
- 2026-08-13 Menu [5] label simplified to Express score (same highlight as [1]–[4]).  
- 2026-08-13 Shipped P24 Express action-list visibility (`dcd1d1e`; excel 1.14.1).  
- 2026-08-13 Opened P24 Express action-list visibility (operator could not see [5]).  
- 2026-08-13 Shipped P20–P23 Express score (`cb20bb0`; excel 1.14.0).  
- 2026-08-13 Opened P20–P23 Express score (all POI → one Excel sheet).  
- 2026-08-12 Shipped P15–P19 slim multi-POI detail (`114ac02`; kpi 2.10.0 / excel 1.13.0).  
- 2026-08-12 Opened P15–P19 slim multi-POI detail output (opt-in; full default).  
- 2026-08-12 Closed P11–P14 audit-fix (Worklist 1.12.1, PLAN partial, kpi ENTERPRISE 2.9.0).  
- 2026-08-12 Opened P11–P14 audit-fix stack (Worklist `-cne`, PLAN Cluster 3 wording, kpi security version).  
- 2026-08-12 P8 shipped excel-toolkit 1.12.0 preview, `[WQ]_MM-DD-YYYY.xlsx`, Totals sheet.  
- 2026-08-12 P7 signed Cluster 2 freeze (per-file score; groups do not span files).  
- 2026-08-12 P6 shipped excel-toolkit 1.11.0 menu Build worklist; P1 filters still `blocked`.  
- 2026-08-12 P5 shipped excel-toolkit 1.10.0 Groups + Worklist sheets; P1 filters still `blocked`.  
- 2026-08-12 P4 shipped kpi-analytics 2.9.0 groups CSV; 3.1 CSV frozen; P1 filters/patient freeze still `blocked`.  
- 2026-08-12 P3 shipped kpi-analytics 2.8.0 detail sort; 3.2 frozen; P1 grouping freeze still `blocked`.  
- 2026-08-12 P2 rehearsal on synthetic scored workbook; P1 remains `blocked` (user deferred freeze).  
- 2026-08-12 Registered **post-v1-enhancement**; P0 annex written; P1 `blocked` on freeze questions.  
- 2026-08-12 Closed **repo-kit-upgrade-2.4.0** (workboard + continuity policy; PLAN triple surface).  
- 2026-08-12 Parked Cluster 3 research as a separate docs commit (`cb93513`).

---

## Deferred

| ID | Note |
|----|------|
| b1.1-base-weight-retune | Optional; analyst-gated (P9). [plan/b1.1-base-weight-retune.md](./plan/b1.1-base-weight-retune.md) |
| continuity-overlay | Optional filled overlay (`docs/project_build/continuity.md`); not opened |
| kit-adopter-404s | SETUP / kit CHANGELOG links; wait upstream repo-kit |

---

## Recently completed (max 5 programs)

| Program | Ended | L4 pointer |
|---------|-------|------------|
| repo-kit-upgrade-2.4.0 | 2026-08-12 | [kit/RULES.md](../kit/RULES.md) kit baseline **2.4.0** · [CHANGELOG 1.14.2](../CHANGELOG.md) · [plan/repo-kit-upgrade-2.4.0.md](./plan/repo-kit-upgrade-2.4.0.md) |
| repo-kit-upgrade-2.3.1 | 2026-08-10 | [plan/repo-kit-upgrade-2.3.1.md](./plan/repo-kit-upgrade-2.3.1.md) |

---

## Not on this board

| Concern | Where |
|---------|--------|
| Mission / stage doctrine / Agent models | Root `PLAN.md` |
| Product Clusters 1–3 backlog | `docs/PLAN.md` |
| Shipped contracts / how-it-works | Authority-map L4 owners (toolkit CLI, SCORE-METHODOLOGY, schema) |
| Deep phase history | Annex while open; `docs/plan/` freeze notes |
| Release notes | Project `CHANGELOG.md` |
| Multi-phase policy | `kit/rules/workboard.md` |

---

*Agents: P28–P30 shipped (Express context source columns). Next: P1 filters remain blocked; P9 deferred.*
