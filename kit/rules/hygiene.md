---
title: Root Hygiene
description: Unified packaging—standards under kit/, repository-specific data outside; SETUP and UPGRADE lifecycles.
version: "1.4.0"
status: current
audience:
  - developers
  - technical-writers
doc_type: other
related:
  - ../RULES.md
  - ../SETUP.md
  - ../UPGRADE.md
  - ../CHANGELOG.md
  - ../agents/README.md
  - ./ai-docs-workspace.md
  - ./workboard.md
  - ../../README.md
last_updated: "2026-08-12"
---

# Root Hygiene

Keep the repository root **scannable**: entry points and project-specific surfaces first; **standards under `kit/`**; product code and AI workspace in purpose directories outside `kit/`.

**Document version:** 1.4.0  

**Related:** [RULES.md](../RULES.md) · [SETUP.md](../SETUP.md) · [UPGRADE.md](../UPGRADE.md) · [CHANGELOG.md](../CHANGELOG.md) · [agents/README.md](../agents/README.md) · [ai-docs-workspace.md](./ai-docs-workspace.md) · [workboard.md](./workboard.md) · [README.md](../../README.md)

---

## Summary

**Unified packaging:** this kit repository and **adopting product repositories** both keep standards under `kit/`. Repository-specific data (product code, project CHANGELOG, PLAN, **`docs/` AI workspace**) stays **outside** `kit/`.

| Must | Must not |
|------|----------|
| Keep adopted standards under `kit/` | Dump RULES / MARKDOWN-STANDARD / rules modules onto product root as the default |
| Keep product code outside `kit/` | Put packages, services, or app source under `kit/` |
| Keep AI resource workspace at root **`docs/`** when used ([ai-docs-workspace](./ai-docs-workspace.md)) | Put project research/build notes under `kit/` or as root-file sprawl |
| Prefer purpose directories over extra root files | Accumulate ephemeral SETUP after initiation |
| Update the authority map when listed paths change | Force-add regenerable artifacts |
| Keep UPGRADE durable (or re-fetch from Kit source) | Mix kit release history into project CHANGELOG |

---

## Contents

1. [Summary](#summary)
2. [Unified packaging](#unified-packaging)
3. [What belongs at project root](#what-belongs-at-project-root)
4. [What belongs under kit/](#what-belongs-under-kit)
5. [What does not belong at root or under kit/](#what-does-not-belong-at-root-or-under-kit)
6. [Separation rules](#separation-rules)
7. [Supporting practices](#supporting-practices)
8. [SETUP and UPGRADE lifecycles](#setup-and-upgrade-lifecycles)
9. [Document history](#document-history)

---

## Unified packaging

| Context | Standards | Repository-specific |
|---------|-----------|---------------------|
| **This repository (repo-kit)** | Entire payload under [`kit/`](../) | Root README (kit landing), LICENSE, `.gitignore`; kit history in `kit/CHANGELOG.md` under `## repo-kit` |
| **Adopting product repo** | Same: standards under **`kit/`** (copy/merge from upstream `kit/`, or link/submodule) | Root product README, **project** `CHANGELOG.md`, optional `PLAN.md`, optional/dynamic **`docs/`**, packages/src, certification |

**Default for new implementations:** `kit/RULES.md` (filled hub) + `kit/rules/*` — not root-level `RULES.md`.

**Escape hatch:** reference or submodule the upstream kit without a local copy; still treat *project* history and product code as outside any standards tree, and record Kit baseline in the project’s maintenance hub path you document in the authority map.

---

## What belongs at project root

| File / item | Role |
|-------------|------|
| `README.md` | Product / public landing (no frontmatter) |
| `LICENSE` | License |
| `.gitignore` | Ignore rules |
| `CHANGELOG.md` | **Project** history (**required**) — repository H2 → version H3 → categories; **not** kit release notes |
| `PLAN.md` | Project plan (repo-specific; not shipped by the kit). **Required when using Agent Instruct** (Agent models section); optional for bare adopt |
| `docs/` | **AI resource workspace** (research, plan, project_build, resources)—scaffold when needed; outside `kit/` ([ai-docs-workspace](./ai-docs-workspace.md)) |
| `docs/WORKBOARD.md` | **Multi-phase execution board** when used ([workboard](./workboard.md)) — project data, not kit law |
| Package or product entry files | Only when they are the natural top-level surface |
| `.pylintrc` | Optional Python style gate (or package-local / under `kit/configs/`) |

---

## What belongs under `kit/`

| File / item | Role |
|-------------|------|
| `RULES.md` | Maintenance hub + authority map + kit baseline (**project-filled**) |
| `rules/` | Domain modules from upstream `kit/rules/` |
| `MARKDOWN-STANDARD.md` | Authoring standard (or link to upstream) |
| `UPGRADE.md` | Durable upgrade guide (local copy optional; may always open from Kit source) |
| `SETUP.md` | One-time only — **delete or archive after initiation** |
| `configs/` | Optional local style configs (e.g. pylintrc) |
| `templates/` | Optional local document skeletons |
| `examples/` | Optional reference only (usually not required in product repos) |
| `agents/` | Agent Instruct law, templates, examples; project-filled packs under `agents/generated/` (views, not product code) |

**Do not** treat upstream kit `CHANGELOG.md` as the product’s project history. Read Kit source `kit/CHANGELOG.md` under `## repo-kit` when upgrading.

---

## What does not belong at root or under `kit/`

| Concern | Preferred home |
|---------|----------------|
| Product packages / services | `packages/`, `src/`, or project-chosen layout **outside** `kit/` |
| Package-level contracts (CLI, SECURITY, methodology) | Inside the package |
| Formal security + code-validation certificates | `certification/` at repo root (or documented path); regenerable outputs gitignored |
| AI research / detailed plans / build notes | Root **`docs/`** modules—not under `kit/` and not as ad-hoc root `notes.md` sprawl |
| Scripts / helpers | `scripts/` or `tooling/` (keep minimal) |
| Regenerable output | Never committed |
| CI workflows | `.github/` (or equivalent) |

---

## Separation rules

1. **Do not** put product code under `kit/`.  
2. **Do not** put kit release history into project root `CHANGELOG.md`.  
3. **Do not** use the project root as a dump of all standards files; keep standards under `kit/`.  
4. **Do not** put project AI research or build notes under `kit/`; use root `docs/` ([ai-docs-workspace](./ai-docs-workspace.md)).  
5. Authority map lists **owners**: standards paths under `kit/`, product and `docs/` paths outside (e.g. `packages/my-service/CLI-GUIDE.md`, `docs/plan/…`).  
6. Relative links from files under `kit/` to root or product use `../` (e.g. `../README.md`, `../CHANGELOG.md`, `../docs/…`, `../packages/…`).  
7. Existing 1.x adoptions may gradually move root-level standards into `kit/`; greenfield **must** use this layout — see [UPGRADE.md](../UPGRADE.md).

---

## Supporting practices

1. Update the [authority map](../RULES.md#authority-map) in the **same change set** whenever an intentional path is added, removed, or renamed (when the map lists that path).  
2. Prefer purpose directories over additional root files.  
3. Mark ephemeral files clearly (e.g. SETUP header) so they do not accumulate.  
4. Respect `.gitignore`; never force-add regenerable artifacts.  
5. Prefer [contracts.md](./contracts.md) cross-link rules when docs move.

---

## SETUP and UPGRADE lifecycles

| File | Lifecycle | Audience |
|------|-----------|----------|
| [SETUP.md](../SETUP.md) | **Ephemeral** — follow, then delete or archive from the project’s `kit/` | First adopt (greenfield or existing repo without baseline) |
| [UPGRADE.md](../UPGRADE.md) | **Durable** — keep under `kit/` or always open from Kit source | Already adopted; routine upgrades and 1.x → 2.x layout migration |
| [Kit baseline](../RULES.md#kit-baseline) | **Durable** in project `kit/RULES.md` | Survives SETUP removal; required for upgrades |

First adopt: [SETUP.md](../SETUP.md). Later kit bumps: [UPGRADE.md](../UPGRADE.md).

---

## Document history

| Version | Notes |
|---------|--------|
| 1.4.0 | `docs/WORKBOARD.md` allowed at docs root (kit 2.4.0) |
| 1.3.0 | Root `docs/` AI workspace outside kit; separation rules (kit 2.3.0) |
| 1.2.0 | Agent Instruct: `kit/agents/`; PLAN required when using agents; generated packs are project-filled views under `kit/` |
| 1.1.0 | Unified packaging: adopters keep standards under `kit/`; product and project CHANGELOG outside; remove “flatten to root” default |
| 1.0.0 | Extracted from RULES 1.4.1 for kit 2.0; dual layout (later superseded) |
