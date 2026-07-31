---
title: Root Hygiene
description: Unified packaging—standards under kit/, repository-specific data outside; SETUP and UPGRADE lifecycles.
version: "1.1.2"
status: current
audience:
  - developers
  - technical-writers
doc_type: other
related:
  - ../RULES.md
  - ../SETUP.md
  - ../UPGRADE.md
  - ../../CHANGELOG.md
  - ../../README.md
last_updated: "2026-07-30"
---

# Root Hygiene

Keep the repository root **scannable**: entry points and project-specific surfaces first; **standards under `kit/`**; product code in purpose directories outside `kit/`.

**Document version:** 1.1.2  

**Related:** [RULES.md](../RULES.md) · [UPGRADE.md](../UPGRADE.md) · [CHANGELOG.md](../../CHANGELOG.md) · [README.md](../../README.md)

---

## Summary

**Unified packaging:** this kit repository and **adopting product repositories** both keep standards under `kit/`. Repository-specific data (product code, project CHANGELOG, PLAN) stays **outside** `kit/`.

| Must | Must not |
|------|----------|
| Keep adopted standards under `kit/` | Dump RULES / MARKDOWN-STANDARD / rules modules onto product root as the default |
| Keep product code outside `kit/` | Put packages, services, or app source under `kit/` |
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
| **Adopting product repo** | Same: standards under **`kit/`** (copy/merge from upstream `kit/`, or link/submodule) | Root product README, **project** `CHANGELOG.md`, optional `PLAN.md`, packages/src, certification |

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
| `Start-ExcelMenu.cmd` | Natural top-level entry shim |
| Data contract files | `wq_schema/` (`wq_schema.json`, `wq_schema.csv`, `wq_data.csv`) |
| Package or product entry files | Only when they are the natural top-level surface |
| `.pylintrc` | Optional Python style gate (this repo: package-local `kpi-analytics/.pylintrc`) |

**This repository** keeps maintainer/design docs under **`docs/`** (not root):

| Path | Role |
|------|------|
| `docs/PLAN.md` | Living product plan |
| `docs/FILE-CATALOG.md` | Path-level inventory |
| `docs/WQ_Priority_Matrix_Concept.md` | Priority design concept (V1–V3) |

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

**Do not** treat upstream kit `CHANGELOG.md` as the product’s project history. Read Kit source `kit/CHANGELOG.md` under `## repo-kit` when upgrading.

---

## What does not belong at root or under `kit/`

| Concern | Preferred home |
|---------|----------------|
| Product packages / services | `excel-toolkit/`, `kpi-analytics/` (**outside** `kit/`) |
| Package-level contracts (CLI, SECURITY, methodology) | Inside the package |
| Formal security + code-validation certificates | `certification/` at repo root; regenerable outputs gitignored — **not** package diagnostics |
| Maintainer / design docs (this repo) | `docs/` (PLAN, FILE-CATALOG, concept) |
| Tracked demo inputs | `import/` |
| Regenerable output | `output/` — never committed |
| Style configs | Package-local (e.g. `kpi-analytics/.pylintrc`) or `kit/configs/` starter |
| Ephemeral adoption guide | Do not re-add `SETUP.md` after initiation |
| Scripts / helpers | `scripts/` or `tooling/` (keep minimal) |
| CI workflows | `.github/` (or equivalent) |

---

## Separation rules

1. **Do not** put product code under `kit/`.  
2. **Do not** put kit release history into project root `CHANGELOG.md`.  
3. **Do not** use the project root as a dump of all standards files; keep standards under `kit/`.  
4. Authority map lists **owners**: standards paths under `kit/`, product paths outside (e.g. `packages/my-service/CLI-GUIDE.md`).  
5. Relative links from files under `kit/` to root or product use `../` (e.g. `../README.md`, `../CHANGELOG.md`, `../packages/…`).  
6. Existing 1.x adoptions may gradually move root-level standards into `kit/`; greenfield **must** use this layout — see [UPGRADE.md](../UPGRADE.md).

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
| 1.1.2 | Project fill: maintainer docs under `docs/`; root keeps data contract + entry shim |
| 1.1.1 | Project fill: FILE-CATALOG, Start-ExcelMenu, data contract, toolkit paths |
| 1.1.0 | Unified packaging: adopters keep standards under `kit/`; product and project CHANGELOG outside; remove “flatten to root” default |
| 1.0.0 | Extracted from RULES 1.4.1 for kit 2.0; dual layout (later superseded) |
