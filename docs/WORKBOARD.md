---
title: "workqueue-data-processor — Active Workboard"
description: Single source of truth for open multi-phase work. Product vision stays in PLAN.md; shipped contracts stay on L4 owners.
version: "1.1.0"
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
last_updated: "2026-08-12"
---

# Workboard

**Updated:** 2026-08-12  
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
| P0 | Register board + annex | `done` | — | SHA when committed |
| P1 | Cluster 3 design freeze (worklists / groups / sort / sheet) | `blocked` | — | Needs group key, output shape, privacy. [cluster-3-analysis.md](./plan/cluster-3-analysis.md) |
| P2 | Optional Excel rehearsal (option A) | `open` | — | After P1 |
| P3 | Implement 3.2 multi-sort | `open` | — | First product code; after P1 |
| P4 | Group summary CSV (option B) | `open` | — | kpi-analytics |
| P5 | Excel groups / two-level worklist (C+D) | `open` | — | No scoring math in PowerShell |
| P6 | Menu Build worklist (E) | `open` | — | After P4–P5 |
| P7 | Cluster 2 design freeze | `open` | — | Only if groups span files |
| P8 | Cluster 2 implement | `open` | — | After P7 |
| P9 | B1.1 base-weight retune | `deferred` | — | Analyst-gated |
| P10 | V2/V3 in-score category metrics | `cancelled` | — | Not this program (S5) |

### Progress log (newest first, max ~15 lines)

- 2026-08-12 Registered **post-v1-enhancement**; P0 annex written; P1 `blocked` on freeze questions.  
- 2026-08-12 Closed **repo-kit-upgrade-2.4.0** (workboard + continuity policy; PLAN triple surface).  
- 2026-08-12 Parked Cluster 3 research as a separate docs commit (`cb93513`).

---

## Deferred

| ID | Note |
|----|------|
| cluster-2-multi-file | Design freeze before S3 product code unless P7 opens it. [plan/cluster-2-multi-file.md](./plan/cluster-2-multi-file.md) |
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

*Agents: continue P1 freeze questions only. Do not start Cluster 2/3 product code.*
