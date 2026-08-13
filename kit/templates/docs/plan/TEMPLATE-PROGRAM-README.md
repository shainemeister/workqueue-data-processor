---
title: "{{PROGRAM_ID}} — program annex"
description: Optional deep order-of-operations pack. Not active unless linked from the workboard.
version: "1.0.0"
status: draft
audience:
  - ai-agents
  - developers
doc_type: plan
related:
  - ../../WORKBOARD.md
  - ../../../PLAN.md
  - ../../../kit/rules/workboard.md
last_updated: "{{ISO_DATE}}"
---

# {{PROGRAM_NAME}}

**Board:** [docs/WORKBOARD.md](../../WORKBOARD.md) — this pack is active **only** while that board’s **Optional annex** field points here.  
**Policy:** [kit/rules/workboard.md](../../../kit/rules/workboard.md)  
**Mission (not todos):** [PLAN.md](../../../PLAN.md)

| Field | Value |
|-------|--------|
| **Program id** | {{PROGRAM_ID}} |
| **Status** | `draft` / `active` / `done` / `archived` |
| **Next phase** | {{PHASE_ID}} |
| **L4 owners to update on ship** | {{AUTHORITY_MAP_PATHS}} |

## Contents of this annex

| File | Role |
|------|------|
| This README | Status, next phase, link **back** to the board |
| [TEMPLATE-OOO.md](./TEMPLATE-OOO.md) *(rename)* | Goals, non-goals, master OOO, verify, risks |

## Rules

1. Do not duplicate the live phase table into `PLAN.md`.  
2. Do not write implementation OOOs for later phases until that phase is `active` on the board.  
3. On program complete: `git mv` this folder to `docs/plan/archive/{{PROGRAM_ID}}/` and promote promises to L4.

Replace every `{{PLACEHOLDER}}`.
