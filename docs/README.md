# docs/ — AI resource workspace

AI and maintainer workspace for **workqueue-data-processor** (outside `kit/`).

**Policy:** [kit/rules/ai-docs-workspace.md](../kit/rules/ai-docs-workspace.md)  
**Templates:** [kit/templates/docs/](../kit/templates/docs/)  
**Control surface + Agent models:** [../PLAN.md](../PLAN.md)  
**Workboard (live multi-phase):** [WORKBOARD.md](./WORKBOARD.md)  
**Product backlog:** [PLAN.md](./PLAN.md)  
**Execution plans:** [plan/](./plan/)

---

## Purpose

| Audience | Use |
|----------|-----|
| **Maintainers / AI** | Research, detailed execution plans, build notes, curated pointers |
| **Operators of scoring/Excel** | Prefer root [README.md](../README.md) and toolkit guides—not this tree |

Standards and portable law remain under **`kit/`**. Product contracts stay in toolkit folders.

---

## Plan surfaces (kit triple surface)

| Surface | Path | Owns |
|---------|------|------|
| Control + Agent models | [../PLAN.md](../PLAN.md) | Mission, stages, non-goals, Agent models |
| Workboard | [WORKBOARD.md](./WORKBOARD.md) | Live multi-phase (open / next / SHA) |
| Product backlog | [PLAN.md](./PLAN.md) | Clusters 1–3 living backlog |
| Execution / freezes | [plan/](./plan/) | Multi-step design freezes and upgrade notes |
| Design concept (V1–V3) | [WQ_Priority_Matrix_Concept.md](./WQ_Priority_Matrix_Concept.md) | Priority matrix vision; V1 live in kpi-analytics |
| Inventory | [FILE-CATALOG.md](./FILE-CATALOG.md) | Path-level intentional source map |

---

## Modules

| Module | Path | Status | Purpose |
|--------|------|--------|---------|
| Index | [README.md](./README.md) | active | This file |
| Workboard | [WORKBOARD.md](./WORKBOARD.md) | active | Live multi-phase board ([workboard](../kit/rules/workboard.md)) |
| Research | [research/](./research/) | active | Investigations, spikes, comparisons (see [research/README.md](./research/README.md)) |
| Plan | [plan/](./plan/) | active | Execution freezes (see [plan/README.md](./plan/README.md)) |
| Project build | [project_build/](./project_build/) | scaffolded | Implementation notes while shipping changes |
| Resources | [resources/](./resources/) | active | Curated pointers (see [resources/README.md](./resources/README.md)) |

### Plan index (quick)

| Plan | Status |
|------|--------|
| [plan/repo-kit-upgrade-2.4.0.md](./plan/repo-kit-upgrade-2.4.0.md) | complete |
| [plan/repo-kit-upgrade-2.3.1.md](./plan/repo-kit-upgrade-2.3.1.md) | complete |
| [plan/cluster-2-multi-file.md](./plan/cluster-2-multi-file.md) | shipped |
| [plan/cluster-3-analysis.md](./plan/cluster-3-analysis.md) | developing |
| [plan/b1.1-base-weight-retune.md](./plan/b1.1-base-weight-retune.md) | pending |
| [plan/post-v1-enhancement/](./plan/post-v1-enhancement/) | **open annex** (see [WORKBOARD](./WORKBOARD.md)) |

### Research index (quick)

| Note | Status |
|------|--------|
| [research/2026-08-12-rules-compliance-gaps.md](./research/2026-08-12-rules-compliance-gaps.md) | current — RULES gaps; P1/P2 applied 2026-08-12 |
| [research/2026-08-12-worklist-grouping-and-industry-metrics.md](./research/2026-08-12-worklist-grouping-and-industry-metrics.md) | draft — columns vs industry metrics; grouped worklists |

---

## How to update

1. Multi-step / research / build work → create or update the relevant module.  
2. Promote durable **product** promises to L4 owners (toolkit CLI/methodology/security, schema, CHANGELOG)—not only under `docs/`.  
3. Durable mission / **Agent models** → root [PLAN.md](../PLAN.md). Live multi-phase → [WORKBOARD.md](./WORKBOARD.md). Product cluster backlog → [PLAN.md](./PLAN.md). Freezes → [plan/](./plan/).  
4. Keep this index accurate when modules add/remove/rename.  
5. No secrets, real PHI, or huge binaries.

---

## Related

| Doc | Path |
|-----|------|
| Workspace policy | `kit/rules/ai-docs-workspace.md` |
| Workboard policy | `kit/rules/workboard.md` |
| Maintenance hub | `kit/RULES.md` |
| Operator enforcement | `kit/RULES.md#operator-enforcement` |
| Agent Instruct | `kit/agents/README.md` · `kit/agents/OPS.md` |
