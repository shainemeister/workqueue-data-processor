---
title: repo-kit upgrade 2.3.1 to 2.4.0
description: Execution record for standards upgrade (workboard + optional continuity; PLAN triple surface).
version: "1.0.0"
status: complete
audience:
  - developers
  - maintainers
doc_type: other
related:
  - ../../PLAN.md
  - ../PLAN.md
  - ../WORKBOARD.md
  - ../../kit/RULES.md
  - ../../kit/UPGRADE.md
  - ../../CHANGELOG.md
last_updated: "2026-08-12"
---

# repo-kit upgrade 2.3.1 to 2.4.0

**Status:** complete (landed on branch; project CHANGELOG **[1.14.2]**).  
**Control surface:** [PLAN.md](../../PLAN.md) · **Product backlog:** [docs/PLAN.md](../PLAN.md) · **Board:** [docs/WORKBOARD.md](../WORKBOARD.md)

---

## Summary

| Item | Value |
|------|--------|
| From | repo-kit **2.3.1** |
| To | repo-kit **2.4.0** |
| Path | Routine upgrade (standards already under `kit/`) |
| Instruct | Preserved Agent models; regen kit-portability packs |
| Workboard | Filled `docs/WORKBOARD.md` (program then closed) |
| Continuity overlay | Policy + template only; **no** filled product overlay |

---

## Scope completed

- [x] Merge portable 2.4.0 law (`workboard.md`, `continuity.md`, UPGRADE 1.6.0, ai-docs-workspace 1.1.0, hygiene 1.4.0, contracts 1.3.0)  
- [x] Three-way `kit/RULES.md` 2.4.0 + `verification-and-ops` 1.5.0 (product cert table preserved)  
- [x] Agent Instruct: OPS 1.2.0, PLAN-HOOK 1.3.0, CATALOG 1.2.0, seed templates; regen plan-author / implementer / docs-author  
- [x] Root PLAN 1.2.0 workboard pointer; no live phase tables  
- [x] Scaffold filled `docs/WORKBOARD.md`; keep existing `docs/plan/*.md` flat  
- [x] FILE-CATALOG + docs indexes + CHANGELOG **1.14.2**  
- [x] Kit baseline **2.4.0**  

---

## Triple PLAN surface (as-built)

| Path | Role |
|------|------|
| Root `PLAN.md` | Agent models + mission/stages (control) |
| `docs/WORKBOARD.md` | Live multi-phase (open / next / SHA) |
| `docs/PLAN.md` | Product Cluster backlog |
| `docs/plan/` | Execution notes (this file) |

---

## Verify (post-upgrade)

- [x] Kit baseline 2.4.0 in `kit/RULES.md`  
- [x] `docs/WORKBOARD.md` has no `{{PLACEHOLDER}}`  
- [x] `kit/rules/continuity.md` product-path table still empty  
- [x] Six packs under `kit/agents/generated/`; adopter still disabled  
- [x] Product `docs/PLAN.md` / FILE-CATALOG / concept unclobbered  
- [x] No `## repo-kit` history dump in project CHANGELOG  
- [x] No `kit/SETUP.md` re-added  

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | Execution record at 2.4.0 upgrade time |
