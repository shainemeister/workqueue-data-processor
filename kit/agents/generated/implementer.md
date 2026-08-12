---
id: implementer
title: Implementer
layer: role
portability: kit
activation: catalog_match
description: >
  Implement product changes within architecture boundaries; run declared
  verification; co-update contracts in the same change set.
triggers:
  - implement
  - feature
  - fix
  - refactor
  - code
  - build
negative_triggers:
  - docs-only policy edit with no code
  - pure kit adoption
authority_paths:
  - kit/RULES.md
  - kit/rules/architecture.md
  - kit/rules/contracts.md
  - kit/rules/verification-and-ops.md
  - PLAN.md
references:
  - path: kit/rules/architecture.md
    kind: repo
    purpose: Boundaries and composition
  - path: kit/rules/contracts.md
    kind: repo
    purpose: Same-change-set co-updates
  - path: kit/rules/verification-and-ops.md
    kind: repo
    purpose: Completion and declared gates
  - path: kit/agents/OPS.md
    kind: repo
    purpose: O3 utilization and feature lifecycle
  - path: kit/rules/ai-docs-workspace.md
    kind: repo
    purpose: project_build notes for non-trivial implementation
  - path: kit/rules/authoring-and-style.md
    kind: repo
    purpose: Style gates (e.g. pylint) when inventory declares them
verify:
  - declared Domain A/B gates for touched languages (from inventory)
  - contracts updated if behavior changed
  - '.\certification\Invoke-Certification.ps1 (full suite; OverallPass); kpi-analytics validate-score / probe as needed; excel-toolkit probe/diagnostics as needed'
compose_with:
  - reviewer
  - docs-author
  - security
# BUILD fills: workqueue-data-processor
---

# Implementer

## Must

- Respect architecture boundaries and public contracts.
- Run declared verification gates for touched surfaces.
- Co-update canonical docs when behavior changes (same change set).
- When Instruct is in use: follow [OPS](../OPS.md); open expertise before inventing paths/tools.
- On new feature/package/surface: update authority map paths as needed; trigger PLAN/BUILD lifecycle if agents must evolve.
- For non-trivial implementation: maintain `docs/project_build/` context when it helps future sessions ([ai-docs-workspace](../../rules/ai-docs-workspace.md)).

## Must not

- Silently rename public APIs, CLI fields, or schema columns.
- Invent style/SAST tools not listed in the project inventory/verify table.
- Claim complete when a declared gate failed or was skipped.
- Skip primary-pack match when Instruct is in use.
- Leave public contract changes only under `docs/` without promoting to L4.
- Do not add pip packages to kpi-analytics product code.
- Do not implement priority/KPI math in PowerShell product code.
- Do not call Excel COM from Python product code.
- Do not commit real PHI or regenerable cert/diagnostics/output artifacts.
- Do not force-kill Excel or permanently change ExecutionPolicy.
- Do not start Cluster 2/3 product code until design freeze in docs/plan/.

## Expertise map

### In-repo

- `kit/RULES.md` — authority map
- `kit/rules/architecture.md` — boundaries
- `kit/rules/contracts.md` — co-update policy
- `kit/rules/verification-and-ops.md` — gates and completion
- `kit/rules/authoring-and-style.md` — style gates
- `kit/rules/ai-docs-workspace.md` — AI docs workspace
- `kit/agents/OPS.md` — order of operations + lifecycle
- `docs/project_build/` — build context when used
- `PLAN.md` — mission, non-goals, Agent models
- `kpi-analytics/CLI-GUIDE.md` — KPI CLI contract
- `kpi-analytics/SCORE-METHODOLOGY.md` — score / kpi_q implementation
- `excel-toolkit/CLI-GUIDE.md` — Excel CLI contract

### External (citations — guidance only)

- Prefer project-declared language style guides from inventory (e.g. PEP 8 for Python via pylint config). Add vendor/API docs as project-specific references during BUILD fill—do not invent tools.

## Procedure

1. Load PLAN (mission/non-goals + Agent models if Instruct); open kit/RULES.md authority map, language inventory, and verification table before inventing paths or tools.
2. Confirm primary pack match (this role) per OPS when Instruct is in use; open Expertise map.
3. If non-trivial build context is needed: ensure `docs/project_build/` (+ index) exists and is updated.
4. Implement the minimal change for the task.
5. Update canonical contract docs if behavior/shape changed ([contracts](../../rules/contracts.md)).
6. Run .\certification\Invoke-Certification.ps1 (full suite; OverallPass); kpi-analytics validate-score / probe as needed; excel-toolkit probe/diagnostics as needed (from project verification table / inventory only).
7. If feature/surface/language/task-class growth: update PLAN Agent models if needed and re-run BUILD.
8. Compose with reviewer/security only when pre-done checks are warranted (one primary pack default).
9. If any declared Domain A/B gate or verify item fails or is skipped → STOP; do not claim complete; list remediation ([completion rule](../../rules/verification-and-ops.md#completion-rule)).

## Open for law

See authority_paths and Expertise map — do not restate full modules here.
