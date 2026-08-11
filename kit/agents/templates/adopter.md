---
id: adopter
title: Kit adopter
layer: playbook
portability: kit
activation: catalog_match
description: >
  First-time repo-kit adoption: SETUP checklist, kit/ layout, authority map,
  kit baseline, delete SETUP.
triggers:
  - adopt repo-kit
  - SETUP
  - first kit
  - authority map
  - kit baseline
negative_triggers:
  - kit already adopted (baseline present)
  - routine feature work
authority_paths:
  - kit/SETUP.md
  - kit/RULES.md
  - kit/rules/hygiene.md
  - kit/UPGRADE.md
  - kit/agents/PLAN-HOOK.md
  - kit/agents/BUILD.md
  - kit/agents/OPS.md
references:
  - path: kit/SETUP.md
    kind: repo
    purpose: One-time adoption checklist
  - path: kit/rules/hygiene.md
    kind: repo
    purpose: kit/ vs product packaging
  - path: kit/agents/OPS.md
    kind: repo
    purpose: Utilization after first BUILD when Instruct is chosen
  - path: kit/UPGRADE.md
    kind: repo
    purpose: Later upgrades (not first adopt)
verify:
  - kit/ present with standards
  - kit baseline filled
  - SETUP removed or archived
  - project root CHANGELOG exists
  - Agent models section present and first BUILD run when using agents
compose_with:
  - plan-author
  - maintainer
# BUILD fills: {{PROJECT_NAME}}, {{TUNING_MUST_NOT_EXTRA}}
---

# Kit adopter

## Must

- Keep standards under kit/; product outside.
- Fill authority map with real or planned paths.
- Record kit baseline before deleting SETUP.
- When using Agent Instruct: ensure PLAN Agent models + first BUILD; point operators at OPS for ongoing utilization.

## Must not

- Flatten RULES/standards onto product root as default.
- Force a product directory rewrite on existing repos.
- Delete Agent models when deleting SETUP.
- {{TUNING_MUST_NOT_EXTRA}}

## Expertise map

### In-repo

- `kit/SETUP.md` — adopt then delete
- `kit/RULES.md` — hub, baseline, map
- `kit/rules/hygiene.md` — packaging
- `kit/UPGRADE.md` — durable upgrades
- `kit/agents/PLAN-HOOK.md` — Agent models
- `kit/agents/BUILD.md` — first emit
- `kit/agents/OPS.md` — utilization after adopt

### External (citations — guidance only)

- Kit source — https://github.com/shainemeister/repo-kit (canonical upstream)

## Procedure

1. Open kit/RULES.md authority map intent, then follow kit/SETUP.md adoption mode (greenfield or existing).
2. Copy/merge kit pieces into the target repo’s kit/. Include kit/agents/ **only when using Agent Instruct** (bare adopt may omit agents and skip BUILD).
3. Fill authority map, inventory, verification table.
4. If using agents: insert Agent models section if missing (include OPS in Instruct authority); run BUILD per kit/agents/BUILD.md; thereafter use OPS O3.
5. Record baseline; delete or archive SETUP.
6. Point future upgrades at UPGRADE.md.

## Open for law

See authority_paths and Expertise map — do not restate full modules here.
