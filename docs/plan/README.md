---
title: docs/plan — execution plans index
description: Multi-step execution and design-freeze notes; complements root PLAN and product docs/PLAN.
version: "1.0.0"
status: current
audience:
  - developers
  - maintainers
doc_type: other
related:
  - ../../PLAN.md
  - ../PLAN.md
  - ../README.md
  - ../../kit/rules/ai-docs-workspace.md
last_updated: "2026-08-10"
---

# docs/plan/ — execution plans

Detailed **execution** and **design-freeze** notes for multi-step work.  
Not the Agent Instruct control surface (that is root [PLAN.md](../../PLAN.md)).  
Not the living product backlog (that is [docs/PLAN.md](../PLAN.md)).

**Policy:** [kit/rules/ai-docs-workspace.md](../../kit/rules/ai-docs-workspace.md)

---

## Summary

| Role | Path |
|------|------|
| Control + Agent models | [../../PLAN.md](../../PLAN.md) |
| Product Clusters backlog | [../PLAN.md](../PLAN.md) |
| This folder | Freeze notes, PR breakdowns, upgrade execution |

When a freeze becomes product law, promote to toolkit contracts / schema / CHANGELOG and update [docs/PLAN.md](../PLAN.md) status in the **same** change set.

---

## Index

| Plan | Status | Purpose |
|------|--------|---------|
| [repo-kit-upgrade-2.3.1.md](./repo-kit-upgrade-2.3.1.md) | **complete** | Standards upgrade 2.0.1 → 2.3.1 (Agent Instruct + docs workspace) |
| [cluster-2-multi-file.md](./cluster-2-multi-file.md) | **developing** | Design freeze checklist for multi-file / naming / default xlsx |
| [cluster-3-analysis.md](./cluster-3-analysis.md) | **developing** | Design freeze checklist for group/sort/denial analysis (reporting-only) |
| [b1.1-base-weight-retune.md](./b1.1-base-weight-retune.md) | **pending** | Optional evidence-based base weight / chaos retune |

---

## How to add a plan

1. Copy shape from an existing file in this folder (frontmatter + Summary + status).  
2. Link root PLAN stages and docs/PLAN cluster sections.  
3. Update **this index** and [docs/README.md](../README.md) if needed.  
4. Update [docs/FILE-CATALOG.md](../FILE-CATALOG.md) for new intentional paths.  
5. Do **not** put Agent models here.

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | Index for kit dual-surface plan layout after repo-kit 2.3.1 |
