---
id: plan-author
title: PLAN author
layer: playbook
portability: kit
activation: catalog_match
description: >
  Draft or revise project PLAN.md from project interest: goals, non-goals,
  stages, and Agent models section. Register multi-phase work on the
  workboard; do not paste live phase tables into PLAN.
triggers:
  - plan
  - PLAN.md
  - project interest
  - roadmap
  - stages
  - non-goals
  - workboard
  - multi-phase
  - OOO
negative_triggers:
  - pure code bugfix with no plan impact
authority_paths:
  - PLAN.md
  - kit/agents/PLAN-HOOK.md
  - kit/agents/OPS.md
  - kit/rules/ai-docs-workspace.md
  - kit/rules/workboard.md
  - kit/MARKDOWN-STANDARD.md
  - README.md
references:
  - path: kit/agents/PLAN-HOOK.md
    kind: repo
    purpose: Agent models field contract and lifecycle
  - path: kit/agents/OPS.md
    kind: repo
    purpose: Utilization O3 after agents exist
  - path: kit/agents/BUILD.md
    kind: repo
    purpose: Regen after enablement changes
  - path: kit/rules/ai-docs-workspace.md
    kind: repo
    purpose: Triple surface — PLAN vs workboard vs docs/plan
  - path: kit/rules/workboard.md
    kind: repo
    purpose: Multi-phase board, annex, archive, agent resume
  - path: docs/WORKBOARD.md
    kind: repo
    purpose: Live execution board when multi-phase work exists
  - path: kit/MARKDOWN-STANDARD.md
    kind: repo
    purpose: Structure for durable PLAN docs when applicable
verify:
  - PLAN has mission-level summary
  - Agent models section present per PLAN-HOOK when using Agent Instruct (omit for bare adopt)
  - stages consistent if used
  - multi-step execution detail in docs/plan/ when used (not only chat)
  - multi-phase work registered on docs/WORKBOARD.md when applicable
  - PLAN does not contain a live phase-status table
compose_with:
  - docs-author
# BUILD fills: {{PROJECT_NAME}}, {{TUNING_MUST_NOT_EXTRA}}
---

# PLAN author

## Must

- Capture mission, non-goals, and constraints clearly.
- Include Agent models section (active/disabled/overlays/tuning) when using Agent Instruct.
- Prefer durable PLAN edits over chat-only intent.
- When features/core tasks grow: update Agent models regenerate_when and active set as needed.
- Put detailed multi-step execution plans in `docs/plan/` when needed; keep Agent models in root PLAN.md.
- When work is multi-phase: register `docs/WORKBOARD.md` before phase code; annex only if the board cannot hold the OOO.

## Must not

- Invent product architecture not implied by interest or user.
- Duplicate full kit Instruct docs inside PLAN.
- Require Agent models for bare kit adopt (no Instruct).
- Move Agent models exclusively under `docs/` (control surface stays PLAN.md).
- Paste live phase tables into PLAN.md (use the workboard).
- {{TUNING_MUST_NOT_EXTRA}}

## Expertise map

### In-repo

- `PLAN.md` — project plan (this surface)
- `docs/plan/` — detailed execution plans and optional annexes
- `docs/WORKBOARD.md` — active multi-phase board
- `kit/rules/workboard.md` — board lifecycle
- `kit/agents/PLAN-HOOK.md` — Agent models contract
- `kit/agents/OPS.md` — utilization and lifecycle
- `kit/agents/BUILD.md` — emit packs after enablement
- `kit/rules/ai-docs-workspace.md` — AI docs workspace
- `kit/MARKDOWN-STANDARD.md` — durable doc shape
- Root `README.md` — product purpose alignment

### External (citations — guidance only)

- Prefer project-specific planning conventions. No required external standard.

## Procedure

1. Restate project interest in one sentence.
2. Draft/update mission, non-goals, stages as needed.
3. If multi-step execution detail is needed: ensure `docs/plan/` (+ `docs/README.md` index) per ai-docs-workspace.
3b. If multi-phase: register or update `docs/WORKBOARD.md`; create an annex only when the phase table cannot hold the OOO; link the annex from the board.
4. If using Agent Instruct: ensure Agent models section matches PLAN-HOOK (include OPS in Instruct authority); link kit/agents/; hand off to BUILD after enablement or surface-growth changes.
5. If bare adopt (no Instruct): omit Agent models and skip BUILD; mission/non-goals verify is enough.
6. On new durable task classes: document intent to add adopter packs (OPS create persona).

## Open for law

See authority_paths and Expertise map — do not restate full modules here.
