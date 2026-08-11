---
title: repo-kit upgrade 2.0.1 to 2.3.1
description: Execution record for standards upgrade (Agent Instruct, Operator enforcement, AI docs workspace).
version: "1.1.0"
status: complete
audience:
  - developers
  - maintainers
doc_type: other
related:
  - ../../PLAN.md
  - ../PLAN.md
  - ../../kit/RULES.md
  - ../../kit/UPGRADE.md
  - ../../CHANGELOG.md
last_updated: "2026-08-10"
---

# repo-kit upgrade 2.0.1 to 2.3.1

**Status:** complete (landed on branch; project CHANGELOG **[1.14.0]**).  
**Control surface:** [PLAN.md](../../PLAN.md) · **Product backlog:** [docs/PLAN.md](../PLAN.md)

---

## Summary

| Item | Value |
|------|--------|
| From | repo-kit **2.0.1** |
| To | repo-kit **2.3.1** |
| Path | Routine upgrade (standards already under `kit/`) |
| Instruct | Adopted (`kit/agents/` + root Agent models + generated packs) |
| Docs workspace | Full scaffold under `docs/` without clobbering product PLAN / FILE-CATALOG / concept |

---

## Scope completed

- [x] Merge portable kit law (UPGRADE 1.5.0, domain modules, agents core, templates)  
- [x] Three-way fill `kit/RULES.md` hub + product architecture/security/verification preserves  
- [x] Root `PLAN.md` Agent models; six generated packs  
- [x] `docs/README.md` + research/plan/project_build/resources  
- [x] Kit baseline **2.3.1**; root CHANGELOG short note only  

---

## Dual PLAN surface (as-built)

| Path | Role |
|------|------|
| Root `PLAN.md` | Agent models + mission/stages (control) |
| `docs/PLAN.md` | Product Cluster backlog |
| `docs/plan/` | Execution notes (this file) |

---

## Verify (post-upgrade)

- [x] Kit baseline 2.3.1 in `kit/RULES.md`  
- [x] Six packs under `kit/agents/generated/`  
- [x] `docs/README.md` + four modules  
- [x] Product `docs/PLAN.md` / FILE-CATALOG / concept unclobbered  
- [x] No `## repo-kit` history dump in project CHANGELOG  

Compliance audit vs GitHub source: portable law byte-identical; product fills preserved (see session audit).

---

## Document history

| Version | Notes |
|---------|--------|
| 1.1.0 | Marked complete; full frontmatter; dual-surface links |
| 1.0.0 | Initial execution note at upgrade time |
