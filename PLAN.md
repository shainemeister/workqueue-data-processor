---
title: Project control surface — Work Queue Data Processor
description: Durable mission, stages, non-goals, and Agent Instruct control surface; product backlog and execution plans live under docs/.
version: "1.2.1"
status: current
audience:
  - developers
  - maintainers
doc_type: other
related:
  - README.md
  - docs/PLAN.md
  - docs/README.md
  - docs/plan/README.md
  - kit/RULES.md
  - kit/agents/OPS.md
  - kit/agents/PLAN-HOOK.md
  - kit/rules/ai-docs-workspace.md
  - kit/rules/workboard.md
  - docs/WORKBOARD.md
last_updated: "2026-08-12"
---

# Project control surface — Work Queue Data Processor

Durable **control surface** for repository mission, stages, and **Agent Instruct**.  
Product enhancement backlog: [docs/PLAN.md](./docs/PLAN.md).  
Live multi-phase execution: [docs/WORKBOARD.md](./docs/WORKBOARD.md).  
Detailed execution plans: [docs/plan/](./docs/plan/).

**Document version:** 1.2.1  

**Related:** [README.md](./README.md) · [docs/PLAN.md](./docs/PLAN.md) · [docs/WORKBOARD.md](./docs/WORKBOARD.md) · [docs/plan/](./docs/plan/) · [kit/RULES.md](./kit/RULES.md) · [kit/agents/OPS.md](./kit/agents/OPS.md) · [ai-docs-workspace](./kit/rules/ai-docs-workspace.md) · [workboard](./kit/rules/workboard.md)

---

## Summary

| Item | Value |
|------|--------|
| Product | Local offline tools for professional-billing **Work Queue** extracts: explainable priority scoring + RCM claim impact + Excel export |
| Toolkits | **kpi-analytics** (Python 3.13 stdlib) · **excel-toolkit** (PowerShell 5.1 + Excel COM) |
| Shared contract | `wq_schema/` |
| Product backlog | [docs/PLAN.md](./docs/PLAN.md) — Cluster 1 complete; Clusters 2–3 developing |
| Execution board | [docs/WORKBOARD.md](./docs/WORKBOARD.md) — what is open / next / SHA |
| Execution plans | [docs/plan/](./docs/plan/) |
| Maintenance hub | [kit/RULES.md](./kit/RULES.md) (repo-kit **2.4.0**) |
| AI docs workspace | [docs/README.md](./docs/README.md) |

### Plan document map (kit triple surface)

| Surface | Path | Owns |
|---------|------|------|
| **Control** | This file (`PLAN.md`) | Mission, stages, non-goals, **Agent models** |
| **Workboard** | [docs/WORKBOARD.md](./docs/WORKBOARD.md) | Live multi-phase execution (open / next / SHA) |
| **Product backlog** | [docs/PLAN.md](./docs/PLAN.md) | Clusters 1–3, product sequencing, open questions |
| **Execution plans** | [docs/plan/](./docs/plan/) | Multi-step freeze/implement notes (not Agent models) |
| **Design concept** | [docs/WQ_Priority_Matrix_Concept.md](./docs/WQ_Priority_Matrix_Concept.md) | V1–V3 priority matrix vision (V1 live) |
| **Law** | [kit/RULES.md](./kit/RULES.md) | Maintenance policy; L4 wins over packs and workspace notes |

Do **not** store Agent models only under `docs/`. Do **not** put project research under `kit/`. Do **not** paste live phase tables into this file — use the workboard.

### Workboard

Live “what is open” lives on [docs/WORKBOARD.md](./docs/WORKBOARD.md) ([kit/rules/workboard.md](./kit/rules/workboard.md)). This file stays doctrine (mission, stages, Agent models). Register multi-phase work on the board **before** phase code. Optional annex under `docs/plan/<id>/` only when the board cannot hold the OOO.

---

## Mission

Provide **offline, explainable** work-queue prioritization and RCM claim-impact analytics for professional billing denials/follow-ups, with optional Excel delivery—safe for controlled Windows desktops (no pip product deps, no elevation, no PHI in git).

---

## Stages

| Stage | Status | Notes |
|-------|--------|-------|
| **S0** Kit + dual toolkit baseline | **Done** | Standards under `kit/`; kpi-analytics + excel-toolkit; certification |
| **S1** V1 priority + RCM + mapping + gap-safety | **Done** | See SCORE-METHODOLOGY; gap-safety closed |
| **S2** Scoring profiles + menu profile pick (Cluster 1) | **Done** | kpi **2.6.0+**, excel **1.9.0**, residual **1f** |
| **S3** Multi-file / delivery UX (Cluster 2) | **Freeze signed** | P7 signed — [docs/plan/cluster-2-multi-file.md](./docs/plan/cluster-2-multi-file.md); product code is P8 |
| **S4** Grouping / sort / denial analysis sheet (Cluster 3) | **Developing** | Reporting-only vs V2 boundary — [docs/plan/cluster-3-analysis.md](./docs/plan/cluster-3-analysis.md) |
| **S5** Priority Matrix V2/V3 | **Design only** | [docs/WQ_Priority_Matrix_Concept.md](./docs/WQ_Priority_Matrix_Concept.md); not product PLAN implementation |

Optional residual: base-weight retune — [docs/plan/b1.1-base-weight-retune.md](./docs/plan/b1.1-base-weight-retune.md).

---

## Non-goals

- Cloud, multi-user SaaS, or network-dependent product paths  
- Pip packages or Excel COM from **kpi-analytics** product code  
- Priority/KPI math in **PowerShell** product code  
- Merging the two toolkits into one process/language  
- Collapsing scores into a single opaque number (no dual attribution / audit columns)  
- Committing real PHI, production extracts, or regenerable cert/diagnostics/`output\` artifacts  
- Force-killing Excel or permanent ExecutionPolicy changes  
- Claiming third-party compliance seals (HIPAA Safe Harbor, SOC 2, etc.)  

---

## Architecture constraints

| Constraint | Rule |
|------------|------|
| Runtime separation | No Excel COM from Python product code; no priority/KPI math in PowerShell product code |
| Composition | Workflow layer only (files + subprocess CLI) |
| Dependencies | kpi-analytics: Python 3.13 **stdlib only** |
| Explainability | Full `v1_*` audit columns; dual RCM `kpi_q_*` independent of priority |
| Outputs | Do not clobber existing destinations by default (`name_N` suffix) |
| Privacy | No real PHI in tracked samples; score-output masking defaults on |

Canonical detail: [kit/rules/architecture.md](./kit/rules/architecture.md) · toolkit ENTERPRISE-SECURITY docs.

---

## Contents

1. [Summary](#summary)
2. [Mission](#mission)
3. [Stages](#stages)
4. [Non-goals](#non-goals)
5. [Architecture constraints](#architecture-constraints)
6. [Workboard](#workboard)
7. [Agent models](#agent-models)
8. [Document history](#document-history)

---

## Agent models

### Instruct authority

| Doc | Path |
|-----|------|
| Framework | [kit/agents/FRAMEWORK.md](./kit/agents/FRAMEWORK.md) |
| Params | [kit/agents/PARAMS.md](./kit/agents/PARAMS.md) |
| Catalog | [kit/agents/CATALOG.md](./kit/agents/CATALOG.md) |
| PLAN hook | [kit/agents/PLAN-HOOK.md](./kit/agents/PLAN-HOOK.md) |
| Build | [kit/agents/BUILD.md](./kit/agents/BUILD.md) |
| Runtime | [kit/agents/RUNTIME.md](./kit/agents/RUNTIME.md) |
| Order of operations | [kit/agents/OPS.md](./kit/agents/OPS.md) |

### Active models

- maintainer
- implementer
- docs-author
- security
- plan-author
- reviewer

### Disabled

- adopter

### Overlays

(none)

### Stage gates

| Agent id | Min stage | Notes |
|----------|-----------|-------|
| implementer | S1 | Product code after V1 baseline |
| security | S0 | Always available for inventory/cert work |
| plan-author | S0 | Backlog and freeze docs |
| reviewer | S1 | PR / completion review |

### Tuning

- emphasize: []
- must_not_extra:
  - Do not add pip packages to kpi-analytics product code
  - Do not implement priority/KPI math in PowerShell product code
  - Do not call Excel COM from Python product code
  - Do not commit real PHI or regenerable cert/diagnostics/output artifacts
  - Do not force-kill Excel or permanently change ExecutionPolicy
  - Do not start Cluster 2/3 product code until design freeze in docs/plan/
- always_on_extra: []
- notes: "Triple PLAN surface: this file = Agent models + mission/stages; docs/WORKBOARD.md = live multi-phase; docs/PLAN.md = product backlog; docs/plan/ = execution detail."

### Regenerate when

- PLAN mission / stages / non-goals change
- Authority map or language inventory change
- active_models / disabled / overlays / tuning change
- Kit agents templates upgrade
- New package, public surface, language, or durable task class
- Material change to pack expertise targets

### Last generated

- 2026-08-12 (repo-kit 2.4.0 workboard/continuity; kit seeds regen; Cluster 2/3 freeze retained)

---

## Document history

| Version | Notes |
|---------|--------|
| 1.2.1 | S3 Cluster 2 freeze signed (P7); product code remains P8 |
| 1.2.0 | Triple surface: pointer to docs/WORKBOARD.md; no live phase tables (kit 2.4.0) |
| 1.1.0 | Kit dual-surface compliance: mission, stages, non-goals, plan map, stage gates; links to docs/plan execution plans |
| 1.0.0 | Initial control surface + Agent models for repo-kit 2.3.1 / Agent Instruct adoption |
