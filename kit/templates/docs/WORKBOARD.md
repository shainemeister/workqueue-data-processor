---
title: "{{PROJECT_NAME}} — Active Workboard"
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
last_updated: "{{ISO_DATE}}"
---

# Workboard

**Updated:** {{ISO_DATE}}  
**Primary program:** {{PROGRAM_ID_OR_none}}  
**Rules:** [kit/rules/workboard.md](../kit/rules/workboard.md) · [PLAN.md](../PLAN.md) (mission) · [docs/plan/archive](./plan/archive/) (history)

| Status | Meaning |
|--------|---------|
| `open` | Not started |
| `active` | Current phase (prefer exactly one) |
| `blocked` | Waiting on user / decision |
| `done` | Shipped + verified + L4/CHANGELOG as required |
| `cancelled` | Explicitly dropped |
| `deferred` | Parked |

---

## Active program — {{PROGRAM_NAME}}

| Field | Value |
|-------|--------|
| **Goal** | {{ONE_LINE_GOAL}} |
| **L4 docs to update** | {{AUTHORITY_MAP_OWNERS_OR_dash}} |
| **Optional annex** | {{docs/plan/PROGRAM_ID_OR_dash}} |
| **Smoke / gates** | {{DECLARED_GATES_OR_dash}} |

### Phases

| ID | Work | Status | Commit | Notes |
|----|------|--------|--------|-------|
| {{P0}} | {{PHASE_WORK}} | `open` | — | |

### Progress log (newest first, max ~15 lines)

- {{ISO_DATE}} Registered **{{PROGRAM_ID}}**.

---

## Deferred

| ID | Note |
|----|------|
| — | |

---

## Recently completed (max 5 programs)

| Program | Ended | L4 pointer |
|---------|-------|------------|
| — | — | — |

---

## Not on this board

| Concern | Where |
|---------|--------|
| Mission / stage doctrine / Agent models | Root `PLAN.md` |
| Shipped contracts / how-it-works | Authority-map L4 owners |
| Deep phase history | `docs/plan/archive/` |
| Release notes | Project `CHANGELOG.md` |
| Multi-phase policy | `kit/rules/workboard.md` |

---

*Agents: register multi-phase work here before coding. Deep phase OOO only when that phase is activated. Replace every `{{PLACEHOLDER}}`.*
