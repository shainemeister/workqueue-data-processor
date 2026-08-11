---
title: Agent Catalog
description: Default portable seed agents for repo-kit Agent Instruct.
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
  - BUILD.md
  - PLAN-HOOK.md
  - templates/
last_updated: "2026-08-10"
---

# Agent Catalog

Upstream repo-kit ships a **small catalog of portable seed agents**. Adopters enable/disable them via PLAN. Product-specific agents are **overlays or project-generated packs**, not rows in this default table. Seeds ship with **expertise** (in-repo + optional external citations) so BUILD emits expert packs.

**Document version:** 1.1.0  

**Related:** [README.md](./README.md) · [OPS.md](./OPS.md) · [PARAMS.md](./PARAMS.md) · [BUILD.md](./BUILD.md) · [PLAN-HOOK.md](./PLAN-HOOK.md) · [templates/](./templates/)

---

## Summary

| Must | Must not |
|------|----------|
| Keep default ids stable | Rename without migration note in kit CHANGELOG |
| Map each agent to real `kit/` authority paths + expertise | Reference product-only paths in kit defaults |
| Include triggers and negative triggers | Activate every agent always_on by default |
| Allow PLAN to disable any default | Force all agents on every adopter |
| Document that AI may generate more **expert** project agents | Stuff design/modeling/creative into upstream CATALOG as required defaults |

---

## Contents

1. [Summary](#summary)
2. [Default active set (suggested)](#default-active-set-suggested)
3. [Catalog entries](#catalog-entries)
4. [Compose matrix (suggested)](#compose-matrix-suggested)
5. [Project-generated agents](#project-generated-agents)
6. [Adopter overlays](#adopter-overlays)
7. [Document history](#document-history)

---

## Default active set (suggested)

For a **new greenfield product repo** after SETUP (when using Agent Instruct):

| id | Default |
|----|---------|
| `plan-author` | available (match) |
| `adopter` | available until first adopt complete; then often disabled in PLAN |
| `maintainer` | **on** |
| `implementer` | **on** |
| `docs-author` | **on** |
| `security` | **on** if language inventory non-empty; else match-only |
| `reviewer` | match / stage_gated optional |

Exact enablement is filled by BUILD from PLAN + inventory ([BUILD.md](./BUILD.md)).

---

## Catalog entries

### `plan-author`

| Field | Value |
|-------|--------|
| **title** | PLAN author |
| **layer** | playbook |
| **portability** | kit |
| **activation** | catalog_match |
| **description** | Draft or revise project PLAN.md from project interest: goals, non-goals, stages, agent models section. |
| **triggers** | plan, PLAN.md, project interest, roadmap, stages, non-goals |
| **negative_triggers** | pure code bugfix with no plan impact |
| **authority_paths** | `PLAN.md`, `kit/agents/PLAN-HOOK.md`, `kit/MARKDOWN-STANDARD.md`, root README |
| **compose_with** | `docs-author` |
| **verify** | PLAN has mission-level summary; Agent models section present per PLAN-HOOK **when using Agent Instruct** (omit for bare adopt); stages consistent if used |
| **template** | [templates/plan-author.md](./templates/plan-author.md) |

### `adopter`

| Field | Value |
|-------|--------|
| **title** | Kit adopter |
| **layer** | playbook |
| **portability** | kit |
| **activation** | catalog_match |
| **description** | First-time repo-kit adoption: SETUP checklist, kit/ layout, authority map, kit baseline, delete SETUP. |
| **triggers** | adopt repo-kit, SETUP, first kit, authority map, kit baseline |
| **negative_triggers** | kit already adopted (baseline present); routine feature work |
| **authority_paths** | `kit/SETUP.md`, `kit/RULES.md`, `kit/rules/hygiene.md`, `kit/UPGRADE.md`, `kit/agents/PLAN-HOOK.md`, `kit/agents/BUILD.md` |
| **compose_with** | `plan-author`, `maintainer` |
| **verify** | kit/ present; baseline filled; SETUP removed or archived; project CHANGELOG exists; Agent models + first BUILD when using agents |
| **template** | [templates/adopter.md](./templates/adopter.md) |

### `maintainer`

| Field | Value |
|-------|--------|
| **title** | Maintainer |
| **layer** | role |
| **portability** | kit |
| **activation** | catalog_match |
| **description** | Repository maintenance: conventional commits, CHANGELOG, hygiene, AI disclosure, version surfaces. |
| **triggers** | commit, changelog, release, version bump, git hygiene, tag |
| **negative_triggers** | greenfield product design with no repo metadata change |
| **authority_paths** | `kit/RULES.md`, `kit/rules/versioning-and-git.md`, `kit/rules/hygiene.md`, `CHANGELOG.md` |
| **compose_with** | `security`, `docs-author` |
| **verify** | commit type matches staged files; CHANGELOG if release-worthy; no secrets staged |
| **template** | [templates/maintainer.md](./templates/maintainer.md) |

### `implementer`

| Field | Value |
|-------|--------|
| **title** | Implementer |
| **layer** | role |
| **portability** | kit |
| **activation** | catalog_match |
| **description** | Implement product changes within architecture boundaries; run declared verification; co-update contracts. |
| **triggers** | implement, feature, fix, refactor, code, build |
| **negative_triggers** | docs-only policy edit with no code; pure kit adoption |
| **authority_paths** | `kit/rules/architecture.md`, `kit/rules/contracts.md`, `kit/rules/verification-and-ops.md`, `kit/RULES.md`, product PLAN |
| **compose_with** | `reviewer`, `docs-author`, `security` |
| **verify** | declared Domain A/B gates for touched languages; contracts updated if behavior changed |
| **template** | [templates/implementer.md](./templates/implementer.md) |

### `docs-author`

| Field | Value |
|-------|--------|
| **title** | Docs author |
| **layer** | role |
| **portability** | kit |
| **activation** | catalog_match |
| **description** | Author kit-shaped and product docs: frontmatter, Summary→Contents, cross-links, no dual contracts. |
| **triggers** | documentation, README, guide, markdown, frontmatter, docs |
| **negative_triggers** | binary asset work; pure runtime debug |
| **authority_paths** | `kit/MARKDOWN-STANDARD.md`, `kit/rules/authoring-and-style.md`, `kit/rules/contracts.md`, `kit/templates/` |
| **compose_with** | `maintainer`, `plan-author` |
| **verify** | links resolve; frontmatter version/last_updated if used; no template placeholders left in finished docs |
| **template** | [templates/docs-author.md](./templates/docs-author.md) |

### `security`

| Field | Value |
|-------|--------|
| **title** | Security |
| **layer** | role |
| **portability** | kit |
| **activation** | catalog_match |
| **description** | Language inventory, declared Domain A (SAST) gates, secrets hygiene, optional certification; Domain B style is implementer-led unless PLAN emphasizes security. |
| **triggers** | security, SAST, inventory, secrets, audit, certification, dependency |
| **negative_triggers** | docs-only repos with empty inventory (unless user enables); pure style/format-only tasks with no security surface |
| **authority_paths** | `kit/rules/security.md`, `kit/rules/verification-and-ops.md`, `kit/RULES.md` language surface inventory, `.gitignore` |
| **compose_with** | `maintainer`, `implementer` |
| **verify** | inventory matches shipped languages; declared Domain A gates run; no secrets committed |
| **template** | [templates/security.md](./templates/security.md) |

### `reviewer`

| Field | Value |
|-------|--------|
| **title** | Reviewer |
| **layer** | doctrine |
| **portability** | kit |
| **activation** | catalog_match (optional stage_gated) |
| **description** | Pre-merge / pre-done review: contracts, verify table, scope creep, commit hygiene, missing CHANGELOG. |
| **triggers** | review, check work, pre-merge, self-verify, acceptance |
| **negative_triggers** | early exploratory spike explicitly labeled draft |
| **authority_paths** | `kit/rules/verification-and-ops.md`, `kit/rules/contracts.md`, `kit/rules/versioning-and-git.md` |
| **compose_with** | `implementer`, `security`, `maintainer` |
| **verify** | verification checklist items addressed; open risks listed if incomplete |
| **template** | [templates/reviewer.md](./templates/reviewer.md) |

---

## Compose matrix (suggested)

Guidance only—runtime loads **one primary** pack; compose_with only when the task needs a second concern ([FRAMEWORK.md](./FRAMEWORK.md#compose-default-required)).

| Agent | Often compose_with |
|-------|--------------------|
| plan-author | docs-author |
| adopter | plan-author, maintainer |
| maintainer | security, docs-author |
| implementer | reviewer, docs-author, security |
| docs-author | maintainer |
| security | maintainer, implementer |
| reviewer | implementer, maintainer, security |

---

## Project-generated agents

| Rule | Detail |
|------|--------|
| **Not required in upstream CATALOG** | Design, modeling, creative, org-only QA, product continuity |
| **Listed in PLAN** | `overlays:` path list and/or `active_models` after BUILD |
| **portability** | `adopter` or `platform` |
| **Emit path** | `kit/agents/generated/<id>.md` |
| **Expertise** | Required: `authority_paths` + `references` / Expertise map (in-repo + trusted external citations with purpose) |
| **RULES** | Durable agents: short map description via project hub if needed; prefer PLAN + generated pack |
| **BUILD** | Same schema as seed agents; fill authority_paths and expertise from project map ([PARAMS](./PARAMS.md)) |
| **Lifecycle** | Create/adjust when new durable task classes appear ([OPS](./OPS.md#creating-a-new-expert-persona)) |

### Expert pack bar (project agents)

| Requirement | Detail |
|-------------|--------|
| Tailored use case | Clear `description` + `triggers` / `negative_triggers` |
| In-repo law | `authority_paths` to real product contracts and kit modules |
| References | Curated secondary markdown + optional external standards/vendor docs |
| Verify | Only declared inventory / verification table gates |
| Co-maintain | Procedure requires same-change-set L4 updates |

---

## Adopter overlays

| Rule | Detail |
|------|--------|
| **Not in this catalog** | Product continuity, CAD kernels, game skills, org-only personas |
| **Listed in PLAN** | `overlays:` path list ([PLAN-HOOK.md](./PLAN-HOOK.md)) |
| **portability** | `adopter` or `platform` |
| **BUILD** | Merge overlay packs into active set after kit defaults |
| **Paths** | Repo-relative only—never remote overlay URLs |

---

## Seed expertise (defaults)

Templates under [templates/](./templates/) carry the full Expertise map. Summary of external citation themes (guidance only):

| id | External citation themes (illustrative) |
|----|----------------------------------------|
| maintainer | Keep a Changelog; Conventional Commits |
| implementer | Language style guides per project inventory |
| security | OWASP guidance (citation); project SAST tool docs |
| docs-author | CommonMark / project MARKDOWN-STANDARD |
| reviewer | — (primarily in-repo verification/contracts) |
| plan-author | — (PLAN-HOOK + project PLAN) |
| adopter | — (SETUP / hygiene / UPGRADE) |

---

## Document history

| Version | Notes |
|---------|--------|
| 1.1.0 | Project expert pack bar; seed expertise themes; OPS lifecycle (kit 2.2.0) |
| 1.0.1 | plan-author verify dual-path; security Domain A focus |
| 1.0.0 | Initial seven seed agents (kit 2.1.0) |
