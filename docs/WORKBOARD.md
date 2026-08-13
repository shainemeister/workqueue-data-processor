---
title: "workqueue-data-processor — Active Workboard"
description: Single source of truth for open multi-phase work. Product vision stays in PLAN.md; shipped contracts stay on L4 owners.
version: "1.0.0"
status: current
audience:
  - ai-agents
  - developers
doc_type: other
related:
  - ../PLAN.md
  - ../kit/rules/workboard.md
  - ../CHANGELOG.md
  - ./plan/repo-kit-upgrade-2.4.0.md
last_updated: "2026-08-12"
---

# Workboard

**Updated:** 2026-08-12  
**Primary program:** none  
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

## Active program

No primary program. Next product work is **deferred** (Cluster 2 / 3 design freeze) — do **not** start product code until the matching `docs/plan/` freeze is signed.

| Field | Value |
|-------|--------|
| **Goal** | — |
| **L4 docs to update** | — |
| **Optional annex** | — |
| **Smoke / gates** | — |

### Phases

| ID | Work | Status | Commit | Notes |
|----|------|--------|--------|-------|
| — | — | — | — | |

### Progress log (newest first, max ~15 lines)

- 2026-08-12 Closed **repo-kit-upgrade-2.4.0** (workboard + continuity policy; PLAN triple surface).  
- 2026-08-12 Parked Cluster 3 research as a separate docs commit (`cb93513`).

---

## Deferred

| ID | Note |
|----|------|
| cluster-2-multi-file | Design freeze required before S3 product code. [plan/cluster-2-multi-file.md](./plan/cluster-2-multi-file.md) |
| cluster-3-analysis | Design freeze required; reporting-only vs V2. [plan/cluster-3-analysis.md](./plan/cluster-3-analysis.md) · research: [worklist grouping](./research/2026-08-12-worklist-grouping-and-industry-metrics.md) |
| b1.1-base-weight-retune | Optional; analyst-gated. [plan/b1.1-base-weight-retune.md](./plan/b1.1-base-weight-retune.md) |
| continuity-overlay | Optional filled overlay (`docs/project_build/continuity.md`); not opened this upgrade |

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
| Deep phase history | `docs/plan/` freeze notes (flat files; no annex folder) |
| Release notes | Project `CHANGELOG.md` |
| Multi-phase policy | `kit/rules/workboard.md` |

---

*Agents: register multi-phase work here before coding. Deep phase OOO only when that phase is activated.*
