---
title: PLAN.md Agent Models Hook
description: Durable control surface contract for Agent Instruct in adopter PLAN.md.
version: "1.2.0"
status: current
audience:
  - developers
  - maintainers
doc_type: other
related:
  - README.md
  - OPS.md
  - BUILD.md
  - CATALOG.md
  - PARAMS.md
  - examples/PLAN-agent-models-snippet.md
  - ../SETUP.md
  - ../UPGRADE.md
last_updated: "2026-08-10"
---

# PLAN.md Agent Models Hook

When a project uses **Agent Instruct**, root **PLAN.md** is the **durable control surface**. It references the Instruct docs and declares which agent models are active, disabled, overlaid, and tuned. Mid-project adjustments happen here; AI then re-runs BUILD. Session utilization follows **[OPS.md](./OPS.md)**.

**Document version:** 1.2.0  

**Related:** [README.md](./README.md) · [OPS.md](./OPS.md) · [BUILD.md](./BUILD.md) · [CATALOG.md](./CATALOG.md) · [PARAMS.md](./PARAMS.md) · [examples/PLAN-agent-models-snippet.md](./examples/PLAN-agent-models-snippet.md) · [SETUP.md](../SETUP.md) · [UPGRADE.md](../UPGRADE.md)

---

## Summary

| Must | Must not |
|------|----------|
| Include **Agent models** when using Agent Instruct | Leave agent enablement only in chat history |
| Link to kit Instruct paths (`kit/agents/*` including OPS) | Duplicate full FRAMEWORK/BUILD text inside PLAN |
| List `active_models` / `disabled` / `overlays` explicitly | Imply “all catalog agents always on” without statement |
| Treat an **empty Active models list** as intentional empty set | Conflate empty list with “unset → enable catalog defaults” |
| Overlays are **repo-relative** paths only | Remote `http(s)` overlay URLs |
| Evolve Agent models when features/core tasks grow | Leave enablement stale after new surfaces |
| Treat PLAN edits as the path for durable user intent | Require kit fork for product emphasis changes |

### PLAN dual path

| Path | Requirement |
|------|-------------|
| **With Agent Instruct** | PLAN.md **required**; must include Agent models section; run BUILD after adopt and on enablement change |
| **Bare kit adopt** | PLAN optional; no Agent models ⇒ no BUILD, no generated packs |

---

## Contents

1. [Summary](#summary)
2. [Required section](#required-section)
3. [Field contract](#field-contract)
4. [Trust boundary](#trust-boundary)
5. [Minimal template](#minimal-template)
6. [Mid-project adjustment procedure](#mid-project-adjustment-procedure)
7. [Durable vs session-only](#durable-vs-session-only)
8. [Interaction with other PLAN sections](#interaction-with-other-plan-sections)
9. [SETUP and UPGRADE](#setup-and-upgrade)
10. [Document history](#document-history)

---

## Required section

**Title (recommended):** `## Agent models`

Acceptable aliases if consistent in-repo: `## Agents`, `## Agent Instruct`. Prefer **Agent models**.

**Placement:** After mission/summary and architecture pointers is fine; must be discoverable (listed in PLAN contents if PLAN has a contents block).

---

## Field contract

| Field | Required | Description |
|-------|----------|-------------|
| **Instruct authority** | yes | Links to FRAMEWORK, BUILD, PARAMS, CATALOG, PLAN-HOOK, RUNTIME, **OPS** |
| **active_models** | yes when Instruct in use | List of agent ids under `### Active models` (markdown bullets). **Empty list** (zero bullets, or a single `*(none)*` line) means no agents active (emit nothing). **Unset** after first BUILD is not the same as empty — see BUILD resolution |
| **disabled** | yes (may be empty) | Ids explicitly off |
| **overlays** | yes (may be empty) | **Repo-relative** paths to adopter/platform pack sources |
| **use_catalog_defaults** | optional | If `true`, first-time/BUILD may apply CATALOG suggested defaults when `active_models` is unset; default is first-BUILD-only behavior per [BUILD](./BUILD.md#resolution-rules) |
| **tuning** | recommended | emphasize, must_not_extra, always_on_extra (keep tiny), notes |
| **stage_gates** | optional | Map agent id → min stage |
| **regenerate_when** | recommended | Conditions that require BUILD regen |
| **last_generated** | optional | ISO date / kit agents version note after BUILD |

### `active_models` semantics

PLAN is **markdown-native**. BUILD algorithm docs may write `active_models: []` as shorthand for an **empty** Active models list in PLAN.

| State | Meaning for BUILD |
|-------|-------------------|
| **Agent models** section **absent** | Bare adopt — no BUILD |
| Active models **unset** (section present, field never filled; Instruct in use) | Catalog defaults only on **first BUILD** or when `use_catalog_defaults: true`; otherwise require an explicit list |
| **Empty** Active models list | Zero bullets under `### Active models`, or a single `*(none)*` (or equivalent “none”) line — active set empty; **emit nothing**; **not** “all catalog agents” |
| **Non-empty** bullet list | Enabled set (minus `disabled`, plus overlay ids) |

Do **not** imply “all catalog agents always on” without an explicit list or documented first-BUILD defaults report.

### `tuning` subkeys (recommended)

| Key | Meaning |
|-----|---------|
| `emphasize` | Agent ids or themes to prefer when multiple match |
| `must_not_extra` | Project-specific prohibitions injected into relevant packs (**Must not** / Tuning) |
| `always_on_extra` | Extra always-on bullets (strict size budget) |
| `notes` | Freeform human notes for BUILD (not law) |

---

## Trust boundary

| Rule | Detail |
|------|--------|
| Overlay paths | **Repo-relative** only (e.g. `docs/agents/product-review.md`) |
| Remote URLs | BUILD must **not** follow `http://` or `https://` overlay paths |
| PLAN tuning | Intentional privileged instruction for **this** repo — not untrusted content fetched from outside the tree |
| Overlay vs kit seed | Same id: **overlay wins**; BUILD reports a shadow warning ([BUILD source load order](./BUILD.md#source-load-order)) |

---

## Minimal template

```markdown
## Agent models

### Instruct authority

| Doc | Path |
|-----|------|
| Framework | kit/agents/FRAMEWORK.md |
| Params | kit/agents/PARAMS.md |
| Catalog | kit/agents/CATALOG.md |
| PLAN hook | kit/agents/PLAN-HOOK.md |
| Build | kit/agents/BUILD.md |
| Runtime | kit/agents/RUNTIME.md |
| Order of operations | kit/agents/OPS.md |

### Active models

- maintainer
- implementer
- docs-author
- security
- plan-author
- reviewer

### Disabled

- adopter   # example: after first kit adopt complete

### Overlays

<!-- adopter-only packs; paths relative to repo root -->
<!-- - docs/agents/product-continuity.md -->

### Tuning

- emphasize: []
- must_not_extra: []
- always_on_extra: []
- notes: ""

### Stage gates

<!-- - reviewer: 3 -->

### Regenerate when

- PLAN mission / stages / non-goals change
- Authority map or language inventory change
- active_models / disabled / overlays / tuning change
- Kit agents templates upgrade (see UPGRADE.md)
- New project agent packs added
- New package, public surface, language, or durable task class
- Material change to pack expertise targets (new contract owners)
```

Also: [examples/PLAN-agent-models-snippet.md](./examples/PLAN-agent-models-snippet.md).

---

## Mid-project adjustment procedure

```text
1. User (or AI with user intent) edits PLAN Agent models fields
2. Confirm durable vs session-only
3. AI runs BUILD procedure (kit/agents/BUILD.md)
4. If new project agent: write kit/agents/generated/<id>.md with expertise map (+ map row if durable and needed)
5. Review generated packs diff
6. Commit: PLAN + generated packs (+ CHANGELOG if release-worthy)
```

| Change type | Typical commit type |
|-------------|---------------------|
| Enable/disable agents only | `chore(agents):` or `docs(plan):` |
| New product overlay / expert persona | `docs(agents):` + pack files |
| Feature/surface growth → expertise regen | `docs(agents):` or `chore(agents):` after map update |
| Kit template upgrade regen | `chore(agents):` after UPGRADE |

### Feature and core-task lifecycle

When the product gains durable work shapes, update agents in the same initiative—not only in chat.

| Trigger | PLAN / agent action |
|---------|---------------------|
| New package or product area | Ensure authority map paths exist; BUILD so implementer/docs/security expertise covers them |
| New public CLI/API/behavior | Co-update L4 contracts; BUILD if verify/authority paths change |
| New language in inventory | Often enable/emphasize `security`; BUILD |
| New durable task class | New adopter pack or overlay + `active_models` + BUILD ([OPS create persona](./OPS.md#creating-a-new-expert-persona)) |
| Stage complete / post-adopt | `disabled` += `adopter` when appropriate; adjust `stage_gates` / `emphasize` |

Full utilization and co-maintain: [OPS.md](./OPS.md).

---

## Durable vs session-only

| Intent | Where it goes |
|--------|----------------|
| “From now on, security agent is required” | PLAN `active_models` |
| “For this PR, review harder” | Session: load `reviewer`; optional temporary emphasize |
| “Never commit .env” | Prefer `.gitignore` + security pack verify; may add `must_not_extra` |
| “Ignore adopter agent” | PLAN `disabled` |
| “Add design-review persona” | Overlay or generated pack + active_models |

**Rule:** If the user will be angry when the next session forgets it → **PLAN**.

---

## Interaction with other PLAN sections

| PLAN area | Effect on agents |
|-----------|------------------|
| Mission / non-goals | Feeds implementer/reviewer must_not |
| Stages | stage_gates; adopter vs implementer emphasis |
| Verification policy | verify[] alignment |
| Architecture pointers | implementer authority_paths |
| “Must not invent” lists | Injected into implementer + reviewer |

BUILD reads these sections when filling templates; it does not delete them.

---

## SETUP and UPGRADE

**SETUP:** When using Agent Instruct—ensure PLAN.md exists, insert Agent models if missing, run first BUILD, keep Agent models when deleting SETUP. Bare adopt may skip. See [SETUP.md](../SETUP.md).

**UPGRADE:** Preserve Agent models; re-run BUILD after template merge with [source load order](./BUILD.md#source-load-order) (kit seeds regen; adopter/platform packs preserved). Never reset `active_models` without user intent. See [UPGRADE.md](../UPGRADE.md).

---

## Document history

| Version | Notes |
|---------|--------|
| 1.2.0 | OPS in Instruct authority; feature/core-task lifecycle; regenerate_when surface growth (kit 2.2.0) |
| 1.1.1 | Markdown-native empty Active models (zero bullets / `*(none)*`); `[]` = BUILD shorthand only |
| 1.1.0 | active_models unset vs empty; use_catalog_defaults; trust boundary; overlay shadow |
| 1.0.0 | Initial PLAN hook (kit 2.1.0) |
