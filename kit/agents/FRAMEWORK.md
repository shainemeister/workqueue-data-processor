---
title: Agent Instruct Framework
description: Layered context system for agent packs as views over canonical law.
version: "1.1.0"
status: current
audience:
  - developers
  - maintainers
doc_type: other
related:
  - README.md
  - OPS.md
  - PARAMS.md
  - CATALOG.md
  - PLAN-HOOK.md
  - BUILD.md
  - RUNTIME.md
  - ../RULES.md
  - ../rules/contracts.md
last_updated: "2026-08-10"
---

# Agent Instruct Framework

Agent Instruct is a **layered context system**: thin always-on rules, PLAN as control surface, kit Instruct docs as the build/run playbook, generated **AgentPacks** as on-demand expert views, and **canonical kit/product docs** as the only law.

**Utilization procedure:** [OPS.md](./OPS.md) (required when Instruct is in use).

**Document version:** 1.1.0  

**Related:** [README.md](./README.md) · [OPS.md](./OPS.md) · [PARAMS.md](./PARAMS.md) · [CATALOG.md](./CATALOG.md) · [PLAN-HOOK.md](./PLAN-HOOK.md) · [BUILD.md](./BUILD.md) · [RUNTIME.md](./RUNTIME.md) · [RULES.md](../RULES.md)

---

## Summary

| Must | Must not |
|------|----------|
| Separate layers L0–L4 | Collapse all instructions into one always-on file |
| Classify packs by **job type** + **portability** | Treat every pack as freeform “persona” with no schema |
| When Instruct is in use: run [OPS](./OPS.md) O3 (one primary expert pack per task) | Load every specialist for every task |
| Keep always-on under a size budget | Always-on multi-kB doctrine dumps |
| Point packs at authority paths + curated expertise (repo + external citations) | Override RULES with pack prose or external URLs |
| Co-maintain L4 docs/rules; evolve agents with features/core tasks | Leave packs stale after surface growth |
| Keep RULES as description + link hub | Embed full pack bodies in RULES.md |

**Enforcement:** Policy + AI convention when Instruct is in use—**not** a Domain A/B gate. Bare adopt may skip agents.

---

## Contents

1. [Summary](#summary)
2. [Layers (L0–L4)](#layers-l0l4)
3. [Job types (taxonomy)](#job-types-taxonomy)
4. [Portability](#portability)
5. [Composition pattern](#composition-pattern)
6. [Hard rules](#hard-rules)
7. [Size and activation principles](#size-and-activation-principles)
8. [Document history](#document-history)

---

## Layers (L0–L4)

```text
L0  Always-on project rules (thin)
    e.g. project rules — environment + “open PLAN / kit/agents”
         │
L1  PLAN.md
    mission, stages, non-goals, **Agent models** section (user knob)
         │
L2  Instruct set (kit/agents/*)
    FRAMEWORK, PARAMS, CATALOG, PLAN-HOOK, BUILD, RUNTIME, templates
         │
L3  Generated AgentPacks (kit/agents/generated/)
    role/doctrine views — short procedures + links
         │
L4  Canonical law
    kit/RULES.md, kit/rules/*, product PLAN/architecture/security docs
```

| Layer | Source of truth for… | Regenerated? |
|-------|----------------------|--------------|
| L0 | Session environment constraints | Rarely |
| L1 | What agents are active + user tuning | Human/AI edit |
| L2 | How to build/run agents | Kit upgrade |
| L3 | Task-shaped instructions | **Yes** via BUILD |
| L4 | Contracts, paths, verify commands | Contract process |

**Rule:** If L3 and L4 conflict, **L4 wins**. Fix the pack or BUILD, not the law by silent pack override.

---

## Job types (taxonomy)

| Type | Answers | Kit default use |
|------|---------|-----------------|
| **environment** | Where am I? What must I never break operationally? | Thin L0 only |
| **role** | How do I act as maintainer / implementer / security? | Yes — catalog core |
| **doctrine** | Hard pass/fail quality or correctness rules | Optional thin packs |
| **playbook** | Ordered steps for a capability (adopt, plan) | adopter, plan-author |
| **pipeline** | Scripts + deterministic postprocess | **Not** in kit defaults |
| **reference** | Large API/corpus lookup | **Not** in kit defaults (link out) |

Project-generated agents may use role/doctrine/playbook for design, modeling, creative, QA, writing, etc. **Upstream catalog does not** list product pipelines.

---

## Portability

| Value | Meaning | Lives in |
|-------|---------|----------|
| **kit** | Valid for any adopter of repo-kit | `kit/agents/` catalog + templates |
| **adopter** | Product- or org-specific | PLAN overlays / generated packs |
| **platform** | Specific agent host | Optional adopter emit only |

Never promote **platform** or **adopter** packs into kit CATALOG as defaults without an explicit kit design decision and CHANGELOG entry.

---

## Composition pattern

```text
Hub (broad domain or role family)
  └── Doctrine (defaults + QC / must-not)
        └── Specialist (one concern)
              └── Pipeline (execution — platform/adopter only)
```

**Kit examples (guidance only):**

- `implementer` may compose_with `reviewer` when pre-done checks are needed  
- `security` may compose_with `maintainer` for release commits  
- Product hub (adopter) may compose_with kit `implementer` + product overlay  

### Compose default (required)

1. Load **one primary** pack by catalog match against the user task.  
2. Load a `compose_with` pack **only** when the task clearly needs a second concern.  
3. **Never** auto-load the full compose matrix because a hub matched.

Detail: [RUNTIME.md](./RUNTIME.md).

---

## Hard rules

1. **No dual authority** — Packs do not redefine CHANGELOG, SAST, or hygiene law.  
2. **Link, don’t paste** — Body ≤ short procedure; cite `authority_paths`.  
3. **PLAN is durable tuning** — Session-only instruction is ephemeral unless written into PLAN.  
4. **BUILD is template fill** — Prefer structured fill from PLAN + authority map over freeform rewrite of kit law.  
5. **Negative triggers** — Every role pack should know when **not** to dominate.  
6. **Verify before done** — Packs list `verify[]` aligned with RULES verification table / inventory. If any **declared** Domain A/B gate or required verify item fails or is skipped → **STOP**; do not claim complete ([completion rule](../rules/verification-and-ops.md#completion-rule)).  
7. **Product overlays stay out of kit defaults** — Listed in PLAN as **repo-relative** paths only, not CATALOG.  
8. **Contracts co-update** — Behavior/contract change still updates L4 in the same change set ([contracts.md](../rules/contracts.md)).  
9. **RULES stays light** — Map row = description + path; procedure lives in the linked file. **Do not fold** full Agent Instruct into the hub.  
10. **Dynamic agents are first-class for adopters** — New project personas use the same schema and get a map row (when durable) + pack file under `kit/agents/generated/` with `portability: adopter` (or `platform`). BUILD [source load order](./BUILD.md#source-load-order) preserves those packs on kit upgrade.  
11. **O3 when Instruct is in use** — Follow [OPS.md](./OPS.md): match one primary expert pack, open expertise, co-maintain L4, verify, evolve agents with features/core tasks. Bare adopt skips O3.  
12. **Expert packs** — Document `authority_paths` plus curated `references` / Expertise map (in-repo + trusted external citations). External URLs are guidance only; never overlays or substitute law.

---

## Size and activation principles

| Class | Principle |
|-------|-----------|
| L0 always-on | Minimal: point to PLAN + `kit/agents/README.md` (+ OPS when Instruct) |
| Catalog row | name + description + triggers only |
| Pack body | Procedure + Expertise map (scannable; avoid essay-length law) |
| RULES map cell | One short phrase + path |
| Reference / expertise | Open on demand; prefer few high-signal links |

Activation modes and budgets: [RUNTIME.md](./RUNTIME.md). Utilization: [OPS.md](./OPS.md). Schema: [PARAMS.md](./PARAMS.md).

---

## Document history

| Version | Notes |
|---------|--------|
| 1.1.0 | O3 required when Instruct in use; expertise principle; OPS link (kit 2.2.0) |
| 1.0.1 | STOP on failed gates; overlays repo-relative; preserve adopter packs; RULES not foldable |
| 1.0.0 | Initial framework (kit 2.1.0) |
