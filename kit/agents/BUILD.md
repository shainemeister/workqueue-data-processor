---
title: Agent BUILD Procedure
description: AI-executable procedure to resolve the active agent set and emit thin AgentPacks.
version: "1.2.0"
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
  - FRAMEWORK.md
  - RUNTIME.md
  - ../RULES.md
  - ../UPGRADE.md
last_updated: "2026-08-10"
---

# Agent BUILD Procedure

**BUILD** is the AI-executable procedure that **resolves the active agent set** and **emits thin expert AgentPacks** from templates + PLAN + authority map. Prefer **deterministic template fill** over freeform rewriting of kit law.

**After BUILD:** operators use packs via **[OPS.md](./OPS.md)** (match, expertise, co-maintain, lifecycle).

**Document version:** 1.2.0  

**Related:** [README.md](./README.md) · [OPS.md](./OPS.md) · [PARAMS.md](./PARAMS.md) · [CATALOG.md](./CATALOG.md) · [PLAN-HOOK.md](./PLAN-HOOK.md) · [FRAMEWORK.md](./FRAMEWORK.md) · [RUNTIME.md](./RUNTIME.md) · [RULES.md](../RULES.md) · [UPGRADE.md](../UPGRADE.md)

---

## Summary

| Must | Must not |
|------|----------|
| Read PLAN Agent models before emit | Emit packs that ignore `disabled` |
| Fill from authority map real paths | Invent package paths not in the map |
| Keep pack bodies short; link L4; fill expertise map | Paste full `kit/rules/*.md` into packs |
| Validate packs per PARAMS rules (including expertise/references) | Leave packs without verify/authority_paths/expertise |
| Emit only under `kit/agents/generated/` | Scatter default emit paths without PLAN escape hatch |
| Regen when PLAN/authority/kit templates/feature surfaces change | Leave stale packs after enablement or surface growth |

**Prerequisite:** Agent models section present in PLAN.md. If missing and the project uses Agent Instruct, insert from [PLAN-HOOK.md](./PLAN-HOOK.md) first. Bare adopt without Agent models → **skip BUILD**.

---

## Contents

1. [Summary](#summary)
2. [Inputs](#inputs)
3. [Outputs](#outputs)
4. [Algorithm](#algorithm)
5. [Resolution rules](#resolution-rules)
6. [Source load order](#source-load-order)
7. [Template fill rules](#template-fill-rules)
8. [Failure modes](#failure-modes)
9. [Regen triggers](#regen-triggers)
10. [Document history](#document-history)

---

## Inputs

| Input | Source |
|-------|--------|
| Active set & tuning | PLAN.md Agent models |
| Mission / stages / non-goals | PLAN.md (other sections) |
| Default catalog | `kit/agents/CATALOG.md` |
| Schema | `kit/agents/PARAMS.md` |
| Role templates | `kit/agents/templates/<id>.md` |
| Authority map + inventory + verify table | `kit/RULES.md` (+ domain modules) |
| Domain modules | `kit/rules/*` (link targets, not paste sources) |
| Overlays | Paths listed in PLAN |
| Optional this-turn instruction | User message (ephemeral unless written to PLAN) |

---

## Outputs

| Output | Default path |
|--------|----------------|
| Generated packs | **`kit/agents/generated/<id>.md`** only |
| Optional project catalog slice | `kit/agents/generated/CATALOG.project.md` |
| Optional host skill emit | Host-specific path (adopter opt-in only) |
| PLAN `last_generated` | Optional stamp in Agent models section |

**Tracking (recommended):** commit thin generated packs so clones work offline. Kit upstream ships `generated/.gitkeep` + samples under [examples/](./examples/) only.

---

## Algorithm

```text
1. READ PLAN.md
   - If no PLAN / no Agent models and bare adopt → stop (no BUILD)
   - If Agent models missing but agents intended → insert PLAN-HOOK template; continue
2. LOAD kit/agents/CATALOG.md + PARAMS schema + templates/
3. READ kit/RULES.md authority map, language inventory, verification table
4. RESOLVE active set (see Resolution rules)
5. FOR each id in active set:
   a. Resolve source pack via Source load order (do not invent kits silently)
   b. If preserve (adopter/platform generated) → keep file; skip destructive overwrite
   c. Else FILL placeholders from PLAN + authority map + inventory + expertise/references
   d. APPLY tuning (emphasize notes, must_not_extra under Must not/Tuning, stage_min)
   e. ENSURE Expertise map + references (PARAMS); external entries need purpose
   f. VALIDATE (PARAMS validation rules including expertise)
   g. EMIT kit/agents/generated/<id>.md (kit-portability seeds and filled overlays)
6. FOR each new project agent created this BUILD (explicit PLAN/user action only):
   a. Ensure pack file exists under kit/agents/generated/
   b. Ensure PLAN lists id; durable map note if project maintains extra rows
7. EMIT optional CATALOG.project.md (id + description + triggers only)
8. OPTIONAL: host skill-shaped emit if PLAN/runtime config requests it
9. UPDATE PLAN last_generated if using that field
10. REPORT summary: enabled ids, disabled, overlays, shadows, preserves, validate warnings
```

---

## Resolution rules

Distinguish **section absent**, **field unset**, and **explicit empty list**. Never treat an intentional empty list as “turn on the whole catalog.”

**PLAN is markdown-native** (bullets under `### Active models`). Pseudo-code below uses `active_models: []` only as shorthand for an **empty** Active models list (zero bullets or a single `*(none)*` line)—see [PLAN-HOOK](./PLAN-HOOK.md#active_models-semantics).

```text
if Agent models section absent:
  → bare adopt → SKIP BUILD

if active_models field ABSENT or UNSET:
  if first_BUILD_for_agents OR PLAN.use_catalog_defaults == true:
    active := CATALOG suggested defaults for repo kind
      (infer docs-only vs code from inventory / PLAN)
    REPORT: "applied catalog defaults (first BUILD or use_catalog_defaults)"
  else:
    FAIL resolve: require explicit active_models list
    (do not invent full catalog)

if active_models present and is empty list []:
  # empty = zero bullets under ### Active models, or *(none)*
  active := []
  REPORT: "active set empty — emit nothing"
  # do NOT fall back to catalog defaults

if active_models present and non-empty:
  active := PLAN.active_models

active := active − PLAN.disabled

if PLAN.overlays:
  for each overlay path:
    if path is http(s) URL → FAIL that overlay (repo-relative only; see Trust)
    load overlay pack; add its id to active
    if id shadows a CATALOG seed id → WARN in report (overlay wins)

if stage_gates present:
  emit with activation: stage_gated where applicable

this-turn user instruction:
  if durable language → propose PLAN edit, then re-resolve
  if ephemeral → temporary compose only (do not write generated pack unless asked)
```

| `active_models` state | Behavior |
|-----------------------|----------|
| Section **absent** | Skip BUILD (bare adopt) |
| Field **absent/unset** | Catalog defaults only on **first BUILD** for agents or explicit `use_catalog_defaults: true`; otherwise require list |
| Explicit **`[]`** | Active set empty after disabled; emit nothing |
| Non-empty list | Use list − disabled, then overlays |

**Inventory influence:**

| Inventory | Effect |
|-----------|--------|
| Empty (docs-only) | security match-only or off unless PLAN forces on; verify/SAST fills = “none declared” / author checklist — never invent tools |
| Python present | implementer/security verify include pylint gate |
| TS/other declared | corresponding Domain B/A from RULES table |

---

## Source load order

For each id in the resolved active set, choose **one** source. Emit path is always `kit/agents/generated/<id>.md`.

| Priority | Source | Action |
|----------|--------|--------|
| 1 | PLAN **overlay** path for this id | Load overlay; fill/emit; **overlay wins** if id also exists as kit seed (report shadow) |
| 2 | Existing `generated/<id>.md` with `portability: adopter` or `platform` | **Preserve** — do not overwrite unless PLAN/user explicitly requests refresh for that id |
| 3 | Kit seed `templates/<id>.md` | Fill → emit (`portability: kit`) |
| 4 | Unknown id, no overlay, no existing pack | **Fail that id**; report; **do not invent** a PARAMS skeleton that clobbers future work |

**New project agents (explicit creation only):** When the user/PLAN deliberately adds a **new** project persona (not a typo id on regen), create from [PARAMS](./PARAMS.md) skeleton under `generated/`, set `portability: adopter` (or `platform`), add to `active_models`. Skeleton creation is **not** the path for unknown ids during routine UPGRADE regen.

**UPGRADE / regen:** Re-emit **kit-portability** packs derived from `templates/`. Preserve **adopter/platform** packs. See [UPGRADE.md — Agent Instruct on upgrade](../UPGRADE.md#agent-instruct-on-upgrade).

---

## Template fill rules

| Placeholder class | Fill from |
|-------------------|-----------|
| Authority paths | RULES authority map rows relevant to role (**repo-relative only**) |
| Verify commands | RULES verification table + inventory only |
| Expertise / references | Template defaults + map paths; add project contract paths; keep curated external citations with purpose |
| Mission must_not | PLAN non-goals / must not invent |
| Project name | README / PLAN title |
| Kit paths | Always `kit/...` as adopted |
| `must_not_extra` | PLAN tuning → **Must not** or **Tuning** section |

**Empty optional fills:**

| Situation | Behavior |
|-----------|----------|
| Optional bullet empty (`{{TUNING_MUST_NOT_EXTRA}}`, extra notes) | **Omit the line/bullet** entirely |
| `{{VERIFY_COMMANDS}}` / `{{SAST_COMMANDS}}` empty inventory | Docs-only checklist / “none declared” — **never invent tools** |
| Required project field unfilled | Fail validation; do not emit |
| Any remaining raw `{{PLACEHOLDER}}` | Fail validation ([PARAMS](./PARAMS.md)) — finished generated packs must not ship unfilled tokens |

**Body rules:**

1. Procedure steps only (ordered); include co-maintain L4 + STOP on failed gates.  
2. Must / Must not bullets (short).  
3. **Expertise map** — in-repo + external citations with purpose (align with YAML `references`).  
4. “Open these docs” list = authority_paths (+ expertise).  
5. No full reproduction of contracts.md or versioning-and-git.md.  
6. Source resolution uses [Source load order](#source-load-order) — never silent skeleton invent on unknown id.  
7. No `http(s)` in `authority_paths`; external only under references/expertise as citations.

**Trust boundary (overlays):** Overlay paths must be **repo-relative** files. BUILD must **not** fetch `http://` or `https://` overlay URLs. External citations in `references` are **not** overlays—do not download them into the tree. PLAN tuning is intentional privileged instruction for that repository, not untrusted external content.

---

## Failure modes

| Failure | Response |
|---------|----------|
| No PLAN.md (agents intended) | Create minimal PLAN from interest + Agent models template; do not invent product architecture |
| No PLAN / no Agent models (bare adopt) | Skip BUILD |
| `active_models` unset after first BUILD (no `use_catalog_defaults`) | Fail resolve; require explicit list |
| `active_models: []` | Emit nothing; report empty set (not a failure) |
| Authority map empty | Stop BUILD for implementer-heavy packs; run adopter/SETUP path first |
| Unknown agent id (no overlay, no generated pack) | Fail that id; report; do not invent skeleton |
| Existing adopter/platform pack on regen | Preserve; do not clobber |
| Overlay path missing | Fail that overlay; continue others; report |
| Overlay is remote URL | Fail that overlay; report trust boundary |
| Overlay id shadows CATALOG seed | Overlay wins; **warn** in report |
| Pack fails validation | Do not emit; fix template fill |
| Missing expertise/references on generated pack | Do not emit; fill from template + map ([PARAMS](./PARAMS.md)) |
| External reference without purpose | Do not emit; add purpose or drop link |
| `http(s)` in authority_paths | Fail validation; move to references as citation if appropriate |
| Conflict must vs must_not_extra | Prefer stricter must_not; surface in report |

---

## Regen triggers

Re-run BUILD when:

- PLAN Agent models fields change  
- PLAN mission/stages/non-goals change materially  
- Authority map or language inventory changes  
- Kit `templates/`, CATALOG, or OPS-related pack schema upgrade ([UPGRADE.md](../UPGRADE.md))  
- New project agent packs added  
- **New package, public surface, language, or durable task class** (update expertise/active set first)  
- User explicitly requests “regenerate agents”  

On kit upgrade regen, apply [Source load order](#source-load-order) so adopter packs survive.

Lifecycle context: [OPS.md — features and core tasks](./OPS.md#lifecycle-features-and-core-tasks) · [PLAN-HOOK](./PLAN-HOOK.md).

---

## Document history

| Version | Notes |
|---------|--------|
| 1.2.0 | Expertise fill + validation; feature/surface regen triggers; OPS pointer (kit 2.2.0) |
| 1.1.1 | Note: PLAN markdown-native empty Active models; `[]` is BUILD shorthand only |
| 1.1.0 | Unset vs empty active_models; source load order; preserve adopter packs; empty placeholder omit; overlay shadow + trust boundary |
| 1.0.0 | Initial BUILD procedure (kit 2.1.0) |
