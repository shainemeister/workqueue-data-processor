---
title: post-v1-enhancement — program annex
description: Deep order-of-operations for grouped POI worklists and later Cluster 2/B1.1. Active only while linked from the workboard.
version: "1.0.1"
status: active
audience:
  - ai-agents
  - developers
  - analysts
doc_type: plan
related:
  - ../../WORKBOARD.md
  - ../../../PLAN.md
  - ../../PLAN.md
  - ../cluster-3-analysis.md
  - ../cluster-2-multi-file.md
  - ../../research/2026-08-12-worklist-grouping-and-industry-metrics.md
  - ../../../kit/rules/workboard.md
last_updated: "2026-08-12"
---

# post-v1-enhancement

**Board:** [docs/WORKBOARD.md](../../WORKBOARD.md) — this pack is active **only** while that board’s **Optional annex** field points here.  
**Policy:** [kit/rules/workboard.md](../../../kit/rules/workboard.md)  
**Mission (not todos):** [PLAN.md](../../../PLAN.md)  
**Master OOO:** [ooo.md](./ooo.md)

| Field | Value |
|-------|--------|
| **Program id** | `post-v1-enhancement` |
| **Status** | `active` |
| **Next phase** | **P6** Menu Build worklist (`open`) |
| **L4 owners to update on ship** | After product phases: toolkit CLI-GUIDE / README / SCORE-METHODOLOGY as applicable; `CHANGELOG.md`; FILE-CATALOG |

## Contents of this annex

| File | Role |
|------|------|
| This README | Status, next phase, link **back** to the board |
| [ooo.md](./ooo.md) | Goals, non-goals, invariants, master OOO, verify, risks |
| [p2-rehearsal.md](./p2-rehearsal.md) | P2 option A findings (synthetic group keys) |

## Rules

1. Do not duplicate the live phase table into `PLAN.md`.  
2. Do not write implementation OOOs for later phases until that phase is `active` on the board.  
3. Do not start Cluster 2/3 **product** code until the matching freeze is signed.  
4. On program complete: `git mv` this folder to `docs/plan/archive/post-v1-enhancement/` and promote promises to L4.

## Next freeze questions (P1)

See [ooo.md § P1 straw men](./ooo.md#p1-straw-men-not-frozen) and [cluster-3-analysis.md](../cluster-3-analysis.md).

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.1 | P2 rehearsal note; next phase still P1 freeze |
| 1.0.0 | Opened with workboard registration |
