---
title: AI Docs Workspace
description: Project root docs/ as modular AI resource workspace—research, plan, project_build, resources; lifecycle and promotion to L4.
version: "1.0.0"
status: current
audience:
  - developers
  - maintainers
  - technical-writers
doc_type: other
related:
  - ../RULES.md
  - ./hygiene.md
  - ./contracts.md
  - ./verification-and-ops.md
  - ../SETUP.md
  - ../UPGRADE.md
  - ../agents/OPS.md
  - ../agents/PLAN-HOOK.md
  - ../templates/docs/README.md
last_updated: "2026-08-10"
---

# AI Docs Workspace

Policy for the project **root `docs/`** tree: a **modular AI resource workspace** for research, detailed plans, project build context, and curated resources. Live content is **outside `kit/`**. Portable policy and templates live under `kit/`.

**Document version:** 1.0.0  

**Related:** [RULES.md](../RULES.md) · [hygiene.md](./hygiene.md) · [contracts.md](./contracts.md) · [verification-and-ops.md](./verification-and-ops.md) · [SETUP.md](../SETUP.md) · [OPS.md](../agents/OPS.md) · [templates/docs/](../templates/docs/)

---

## Summary

| Must | Must not |
|------|----------|
| Keep live AI workspace at **project root `docs/`** (outside `kit/`) | Put project research/build notes under `kit/` or replace L4 contracts |
| Scaffold modules **when needed**; maintain modules **when used** | Force empty four-module trees on trivial Q&A or bare day-one ceremony |
| Keep `docs/README.md` accurate when `docs/` exists | Abandon stale critical plans without status/archive |
| **Promote** durable product promises to canonical L4 owners ([contracts](./contracts.md)) | Dual-own public API/CLI/SECURITY/CHANGELOG law inside `docs/` |
| Complement root **`PLAN.md`** with `docs/plan/` detail | Move Agent models out of PLAN into docs-only storage |
| Prefer thin markdown + links | Paste full `kit/rules/*` or secrets into the workspace |

**Enforcement:** Policy + operator checklist ([RULES — Operator enforcement](../RULES.md#operator-enforcement)). **Not** a Domain A/B gate.

---

## Contents

1. [Summary](#summary)
2. [Purpose](#purpose)
3. [Separation from other surfaces](#separation-from-other-surfaces)
4. [Default modular layout](#default-modular-layout)
5. [Lifecycle (dynamic)](#lifecycle-dynamic)
6. [Promotion to L4](#promotion-to-l4)
7. [PLAN.md dual surface](#planmd-dual-surface)
8. [Enforcement triggers](#enforcement-triggers)
9. [Authoring and trust](#authoring-and-trust)
10. [Anti-patterns](#anti-patterns)
11. [Document history](#document-history)

---

## Purpose

`docs/` is designed as a **resource for AI** (and humans) maintaining the repository:

| Need | Module |
|------|--------|
| Investigations, spikes, findings | `docs/research/` |
| Detailed execution / phased build plans | `docs/plan/` |
| Implementation context, ADRs-lite, build notes | `docs/project_build/` |
| Curated in-repo and external pointers | `docs/resources/` |
| What exists and how to use it | `docs/README.md` |

It is **working memory that survives sessions**—not the Progress Tracker (reply-level) and not kit standards.

---

## Separation from other surfaces

| Surface | Role | Relationship to `docs/` |
|---------|------|-------------------------|
| **`kit/`** | Portable standards / law | Policy + templates only; no project research dumps |
| **Package docs** (README, CLI, SECURITY, …) | **L4 product contracts** | Promote findings here when they become promises |
| **Root `PLAN.md`** | Durable mission, stages, Agent models | Control surface; `docs/plan/` holds detail |
| **`kit/agents/*`** | Instruct + packs (views) | Packs may link into `docs/`; packs do not own workspace law |
| **Progress Tracker** | End-of-reply status | Ephemeral; durable notes go to `docs/` |

On conflict with L4 (`kit/RULES.md`, domain modules, product contracts), **L4 wins**. Fix `docs/` or promote correctly—do not silently override law.

---

## Default modular layout

```text
docs/                          # project root — outside kit/
  README.md                    # AI index (required once docs/ exists)
  research/                    # optional until research work
  plan/                        # optional until multi-step plans
  project_build/               # optional until non-trivial implementation context
  resources/                   # optional until curated refs accumulate
```

| Module id | Path | Contents |
|-----------|------|----------|
| **index** | `docs/README.md` | Enabled modules, purpose, update rules, links to policy |
| **research** | `docs/research/` | Spikes, comparisons, findings, source notes |
| **plan** | `docs/plan/` | Execution plans, PR breakdowns, option matrices |
| **project_build** | `docs/project_build/` | Build/implement notes, phased context for AI |
| **resources** | `docs/resources/` | Curated repo paths + external citations with purpose |

**Modular per project:** omit unused modules (note in index). Add project-specific modules (e.g. `docs/design/`) only with authority-map update when durable.

**Path stability:** prefer kit default names. Alternate paths allowed if authority map and `docs/README.md` record them.

Templates: [templates/docs/](../templates/docs/).

---

## Lifecycle (dynamic)

```text
1. Trigger (research / multi-step plan / non-trivial build / user asks for workspace)
2. If no docs/: create docs/README.md (index) first
3. Create only the module folder(s) needed for this work
4. Write or update thin markdown for the task
5. Keep index module list accurate
6. If finding becomes product law → promote to L4 same change set
7. If durable mission/stages/Agent models change → update root PLAN.md
8. Track useful markdown in git; no secrets or huge binaries
```

| Phase | Action |
|-------|--------|
| **Scaffold** | On first need—not required for pure Q&A |
| **Maintain** | Update active module(s) in the same initiative |
| **Index** | Whenever modules add/remove/rename or purpose shifts |
| **Archive** | Prefer `status: archived` / `archive/` over silent delete of still-referenced plans |
| **UPGRADE** | Preserve project `docs/**` content; merge kit policy/templates only |

---

## Promotion to L4

When workspace content becomes a **stable product or maintenance promise**:

| Finding type | Promote to |
|--------------|------------|
| Public CLI/API/behavior | Package contract (authority map owner) |
| Trust / secrets / inventory | `SECURITY.md` / language inventory |
| Repo maintenance policy | `kit/RULES.md` / `kit/rules/*` |
| Durable stages / Agent models | Root `PLAN.md` |
| Release-worthy history | Project root `CHANGELOG.md` |

Leave a short pointer in `docs/` if helpful. Do **not** leave the only copy of a public contract inside `docs/`.

---

## PLAN.md dual surface

| Need | Where |
|------|--------|
| Mission, non-goals, stages, **Agent models** | Root **`PLAN.md`** |
| Long execution plan, options, research synthesis, PR plan | **`docs/plan/`** |
| Session-only scratch | Chat / Progress Tracker—optional later write to docs |

**Rule:** Agent Instruct enablement stays in PLAN ([PLAN-HOOK](../agents/PLAN-HOOK.md)). Detailed plans may live under `docs/plan/` and should link to PLAN when Instruct is in use.

---

## Enforcement triggers

| Situation | Required workspace action |
|-----------|---------------------------|
| Pure Q&A / no repo work | None (`Progress: no repo changes`) |
| Trivial single-step edit | Optional; no forced scaffold |
| Research / multi-source investigation | Ensure `docs/research/` (+ index) |
| Multi-step or durable execution plan | Ensure `docs/plan/` and/or root `PLAN.md` as appropriate |
| Non-trivial implementation / architecture notes | Ensure `docs/project_build/` |
| Curated external or cross-repo refs for AI | Ensure `docs/resources/` |
| `docs/` already exists | Keep index honest; maintain modules you touch |
| User explicitly requests workspace | Scaffold/maintain as asked |

Standing checklist: [RULES — Operator enforcement](../RULES.md#operator-enforcement). Instruct co-maintain: [OPS](../agents/OPS.md).

---

## Authoring and trust

| Prefer | Avoid |
|--------|--------|
| Short notes + relative links to L4 | Full copies of contracts or kit rules |
| Dated filenames or H1 + `last_updated` when useful | Undated contradictory drafts as “current” |
| External **citations with purpose** under resources | Remote URLs as substitute law or overlays |
| Clear status (`draft` / `active` / `archived`) | Secrets, credentials, production dumps |
| One concern per file when plans grow | Monolithic mega-files that block AI load |

External citations follow the same trust idea as Agent Instruct expertise: **guidance only**; L4 wins.

---

## Anti-patterns

| Bad | Prefer |
|-----|--------|
| Research only in chat | `docs/research/` |
| Public CLI matrix only in `docs/plan/` | Package CLI-GUIDE + pointer |
| Agent models only under `docs/` | Root `PLAN.md` Agent models |
| Project notes under `kit/docs/` | Root `docs/` |
| Empty four modules forever “for compliance” | Scaffold on need |
| `docs/` redefines hygiene/SAST/CHANGELOG | Link L4; promote if needed |
| Huge binary dumps in resources | Links or external storage documented in README |

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | Initial AI docs workspace policy (kit 2.3.0) |
