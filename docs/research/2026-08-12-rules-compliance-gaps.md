---
title: RULES.md compliance gaps — workqueue-data-processor
description: Maintainer audit of the repo against kit/RULES.md and domain modules; improvement candidates with evidence.
version: "1.1.0"
status: current
audience:
  - maintainers
  - developers
doc_type: other
related:
  - ../README.md
  - ../../kit/RULES.md
  - ../../kit/rules/hygiene.md
  - ../../kit/rules/contracts.md
  - ../../kit/rules/security.md
  - ../../kit/rules/versioning-and-git.md
  - ../../kit/rules/verification-and-ops.md
  - ../../docs/FILE-CATALOG.md
  - ../../PLAN.md
last_updated: "2026-08-12"
---

# RULES.md compliance gaps — workqueue-data-processor

Snapshot of how this repository stands against [kit/RULES.md](../../kit/RULES.md) (hub **2.3.1**) and the domain modules. Written so a later session can pick a slice without re-walking the tree.

**Document version:** 1.1.0  
**Audited at:** `67bd4b2` on `docs/repo-kit-upgrade-2.3.1` (2026-08-12)  
**Fixes applied:** 2026-08-12 (P1 + catalog P2 + empty dirs; see [Applied](#applied-2026-08-12))  
**Primary pack:** `maintainer` ([OPS](../../kit/agents/OPS.md) O3)

**Related:** [kit/RULES.md](../../kit/RULES.md) · [FILE-CATALOG.md](../FILE-CATALOG.md) · [docs/README.md](../README.md) · [PLAN.md](../../PLAN.md)

---

## Summary

The product layout matches the kit story: standards under `kit/`, two independent toolkits, shared `wq_schema/`, formal `certification/`, dual PLAN surfaces, and Agent Instruct packs. Regenerable artifacts are gitignored and **not** tracked. Schema, sample, and import headers match (40/40).

**P1 and local P2 items from the first pass are applied** (security-doc version, pack YAML, catalog facts, empty dirs). Remaining: upstream kit-adopter 404s, published-history nits, and product backlog.

| Priority | Finding | Status |
|----------|---------|--------|
| **P1** | ENTERPRISE-SECURITY cited toolkit **2.6.0** vs package **2.7.0** | **Applied** — doc **2.7.0** + non-clobber note |
| **P1** | Generated packs: orphan YAML list items from BUILD `must_not_extra` | **Applied** — frontmatter valid; extras in Must not (incl. Cluster 2/3 freeze) |
| **P2** | FILE-CATALOG `__version__` / `kpi_analytics.cmd` typo | **Applied** — catalog **1.10.2** |
| **P2** | Empty `vendor/` and `excel-toolkit/menus/` | **Applied** — removed (untracked) |
| **P2** | Kit docs still link to deleted `kit/SETUP.md` and non-copied `kit/CHANGELOG.md` | **Open** — wait for upstream repo-kit; do not re-add SETUP |
| **P3** | CHANGELOG `[1.10.0]` uses non-standard `#### Docs` | **Open** — do not rewrite published history |
| **P3** | Some older commits omit AI disclosure trailers | **Open** — do not rewrite `master`; apply trailers going forward |
| **Backlog** | Cluster 2 / 3 **developing**; B1.1 **pending** | Unchanged — freeze before product code |

**Not a P1:** local `last_certification.*` is for `67b5be5` (product HEAD before the docs-only kit upgrade). [Narrow docs-only exception](../../kit/rules/security.md#certification-renewal-enforcement-required) applies to `67bd4b2`. Outputs are untracked.

---

## Contents

1. [Summary](#summary)
2. [Applied (2026-08-12)](#applied-2026-08-12)
3. [How this audit was run](#how-this-audit-was-run)
4. [What is healthy](#what-is-healthy)
5. [Improvement candidates](#improvement-candidates)
6. [Suggested work slices](#suggested-work-slices)
7. [Out of scope](#out-of-scope)
8. [Document history](#document-history)

---

## Applied (2026-08-12)

Surgical maintenance (no product Python/PowerShell). Project [CHANGELOG 1.14.1](../../CHANGELOG.md).

| Slice | What changed |
|-------|----------------|
| A | [FILE-CATALOG.md](../FILE-CATALOG.md) **1.10.2**: `__version__` **2.7.0**; launcher link `kpi-analytics.cmd` |
| B | [kpi-analytics/ENTERPRISE-SECURITY.md](../../kpi-analytics/ENTERPRISE-SECURITY.md) **2.7.0**: unique-suffix / `--force`; diagnostics smoke note |
| C | Six `kit/agents/generated/*.md`: valid YAML; PLAN `must_not_extra` in Must not (incl. Cluster 2/3 freeze); leaked “Open for law” paths moved into Expertise maps; implementer verify string single-quoted |
| D | Removed empty untracked `vendor/` and `excel-toolkit/menus/` |

Not applied: kit SETUP/CHANGELOG 404s (upstream), published CHANGELOG `#### Docs`, old commit trailers, Cluster 2/3.

---

## How this audit was run

| Step | Source |
|------|--------|
| Hub + Must / Must not | [kit/RULES.md](../../kit/RULES.md) |
| Domain modules | [kit/rules/](../../kit/rules/) (all eight) |
| Instruct | Root [PLAN.md](../../PLAN.md) Agent models; pack `maintainer` |
| Tree vs catalog | `git ls-files` (144 tracked) vs [FILE-CATALOG.md](../FILE-CATALOG.md) |
| Ignore hygiene | `git ls-files` of `output/`, `last_*`, `__pycache__`, cert logs — **empty** |
| Schema contract | `wq_schema.json` vs `wq_schema.csv` vs `wq_data.csv` vs `import/wq_synthetic_data.csv` |
| Product imports | `kpi_modules` — stdlib + relative only |
| Relative links | 987 markdown targets; 33 missing (almost all kit SETUP / kit CHANGELOG / templates) |

This note is **working memory**. It is not a second RULES tree. Promote a row to L4 only when you actually fix that surface.

---

## What is healthy

| Domain | Evidence |
|--------|----------|
| **Packaging** | Standards under `kit/`; product in `excel-toolkit/`, `kpi-analytics/`, `wq_schema/`, `certification/`; no root `RULES.md`; no permanent `SETUP.md` |
| **Kit baseline** | Adopted **2.3.1** on **2026-08-10**; project [CHANGELOG 1.14.0](../../CHANGELOG.md) notes the upgrade without pasting kit history |
| **Architecture** | No Excel COM from Python; no KPI math in PowerShell (grep of `Stop-Process` / `Invoke-WebRequest` / `pip` in product paths is clean); composition via CLI/files |
| **Dependencies** | `kpi_modules` imports are stdlib + package-relative only |
| **Contracts (data)** | 40 schema fields = JSON = CSV twin = `wq_data.csv` = tracked import CSV |
| **Git ignore** | `output/`, diagnostics certs, `certification/last_certification.*` + `logs/`, pycache, numbered import copies, `user_*.json` — present on disk, **not tracked** |
| **Instruct enablement** | Active: maintainer, implementer, docs-author, security, plan-author, reviewer. Disabled: adopter. Last generated 2026-08-10 |
| **PLAN dual surface** | Root PLAN = mission/stages/Agent models; `docs/PLAN.md` = backlog; `docs/plan/` = freezes |
| **Landing README** | No frontmatter; Summary + use cases + quick start ([MARKDOWN-STANDARD landing](../../kit/MARKDOWN-STANDARD.md#landing--root-readme-no-frontmatter)) |
| **Style config** | `kpi-analytics/.pylintrc` `py-version = 3.13` (kit starter also 3.13) |
| **Last product cert** | `OverallPass=true`, 16/16, commit `67b5be5`, kpi **2.7.0**, excel **1.9.0** (local, gitignored) |
| **AI disclosure (recent)** | `67bd4b2`, `67b5be5`, `d4fa168`, `8308972`, `baf4e53` include `Assisted-by` / `Compliance` / `Instructed-by: Shaine Meister` |

---

## Improvement candidates

### 1. Contract version drift (P1) — applied

[versioning consistency](../../kit/rules/versioning-and-git.md#consistency-rules): docs that cite a product version must match the code they describe. **Fixed 2026-08-12** in ENTERPRISE-SECURITY **2.7.0**.

| Surface | Declared | Code / peer docs |
|---------|----------|------------------|
| [kpi-analytics/ENTERPRISE-SECURITY.md](../../kpi-analytics/ENTERPRISE-SECURITY.md) frontmatter + “Toolkit version” | **2.6.0** (`last_updated` 2026-07-30) | `__version__` **2.7.0**; README / CLI-GUIDE / SCORE-METHODOLOGY **2.7.0** |
| 2.7.0 behavior that may belong in the security doc | — | Non-clobber outputs (`--force`); diagnostics smoke now includes `profiles` / `re` ([CHANGELOG 1.10.0](../../CHANGELOG.md)) |

Trust-model change in 2.7.0 looks **small** (overwrite policy, not network/privilege). Still a same-change-set miss: the canonical security doc was not bumped with the package.

**Fix shape:** bump ENTERPRISE-SECURITY to **2.7.0**, note non-clobber / diagnostics import-smoke, `last_updated`. No package version bump (already shipped).

---

### 2. Generated Instruct packs — BUILD fill quality (P1) — applied

**Fixed 2026-08-12.** Historical defect (all six packs): orphan YAML list items inside frontmatter. Example from `maintainer.md` before repair:

```text
compose_with:
  - security
  - docs-author
# BUILD fills: workqueue-data-processor, - Do not add pip packages …
- Do not implement priority/KPI math in PowerShell product code
…
---
```

Orphan `-` list items sit **inside** YAML (before closing `---`). A strict YAML parse of the pack header fails. Body **Must not** also repeats those lines with a doubled “Do not”.

**Why it matters:** [OPS](../../kit/agents/OPS.md) treats packs as views that must stay valid after BUILD. PLAN `tuning.must_not_extra` is a multi-line list; BUILD concatenated it into a comment and leaked it as YAML.

**Fix shape:** re-run [BUILD](../../kit/agents/BUILD.md) after tightening fill (join extras as body bullets only; keep frontmatter valid). Review pack diff. No product behavior change.

---

### 3. FILE-CATALOG accuracy (P2) — catalog facts applied

Authority map: add/remove/**rename** of intentional files updates [FILE-CATALOG.md](../FILE-CATALOG.md) in the same change set. Catalog also cites live versions. **Version row + launcher link fixed in 1.10.2.**

| Issue | Detail |
|-------|--------|
| Stale version | `kpi_modules/__init__.py` row says “currently **2.6.0**”; file is **2.7.0** |
| Broken catalog link | Launcher row target `../kpi-analytics/kpi_analytics.cmd` (underscore) — real file is `kpi-analytics.cmd` |
| Folder-level kit/agents | Individual FRAMEWORK / CATALOG / PARAMS / templates / generated packs are not one-row-each (acceptable if folder summaries stay honest) |
| Untracked empty dirs | `vendor/PsMenuKit/…` and `excel-toolkit/menus/` exist locally, are **not** in git, and are **not** cataloged |

**Fix shape:** correct the two catalog facts (this change set may already include them if the inventory is touched). Delete or `.gitkeep`+catalog the empty dirs only if they are intentional.

---

### 4. Kit-adopter broken links (P2)

Relative-link scan: **33** missing targets. Product docs are clean except the catalog typo above.

| Cluster | Paths | Cause |
|---------|-------|--------|
| Deleted SETUP | `kit/UPGRADE.md`, `kit/rules/hygiene.md`, `kit/rules/ai-docs-workspace.md`, `kit/rules/authoring-and-style.md`, `kit/agents/README.md`, `kit/agents/PLAN-HOOK.md` → `kit/SETUP.md` | Correct lifecycle (SETUP gone); leftover links in **upstream kit text** |
| No local kit CHANGELOG | `kit/rules/hygiene.md`, `kit/rules/versioning-and-git.md`, `kit/UPGRADE.md` → `kit/CHANGELOG.md` | Adopters must **not** copy kit history; links still assume kit-repo layout |
| Templates | `kit/templates/TEMPLATE-*.md` → sibling `README.md` / `CLI-GUIDE.md` | Expected placeholders; not product law |

**Fix shape:** do **not** re-add SETUP. Prefer waiting for upstream repo-kit to retarget SETUP/CHANGELOG links at GitHub + project root CHANGELOG. Local patch only if maintainers keep tripping on 404s. Do not invent a second kit CHANGELOG in this repo.

---

### 5. Empty local directories (P2) — applied

`vendor/` and `excel-toolkit/menus/` were empty trees (no tracked files, no product references). **Removed 2026-08-12.**

**Fix shape:** remove the empty dirs, or document+track them if a future Cluster 2 menu split or vendored PsMenuKit is planned. Do not silently start using `vendor/` without architecture + catalog + inventory.

---

### 6. CHANGELOG category drift (P3)

[Keep a Changelog categories](../../kit/rules/versioning-and-git.md#mandatory-project-changelog) allowed here: Added, Changed, Deprecated, Removed, Fixed, Security.

[CHANGELOG 1.10.0](../../CHANGELOG.md) has `#### Docs` for CLI/methodology notes. Mild. Future entries should fold doc-only notes under **Changed** (or omit if not release-worthy). Do not rewrite published history without coordination.

---

### 7. AI disclosure inconsistency (P3)

Required when AI meaningfully assisted. Present on several 2026-07/08 commits. **Absent** on:

| Commit | Subject |
|--------|---------|
| `3c3140e` | `feat(certification): engine hardening and dynamic security invariants` |
| `ddd8166` | `docs: refresh PLAN backlog after Cluster 1 profile ship` |
| `5449bae` | `feat(kpi-analytics): add scoring profiles and POI focus presets` |

If those were human-only, omission is correct. If AI drafted them, history is already published—do not rewrite `master`; apply the trailer going forward.

`git config user.name` = **Shaine Meister** (Instructed-by cascade step 1).

---

### 8. Workspace / authoring nits (P3)

| Item | Note |
|------|------|
| `docs/research/README.md` and `docs/project_build/README.md` | Thin scaffolds without frontmatter — allowed for tiny READMEs |
| `config_default.json` description | Still says “kpi-analytics **2.0**” |
| Diagnostics folder docs | Excel diagnostics README **1.6.1** / KPI **2.2.0** vs toolkit 1.9.0 / 2.7.0 — document versions may stay independent if the folder contract did not change |
| Certification vs current branch | Local cert bound to `67b5be5`; HEAD `67bd4b2` is docs-only kit upgrade — renewal optional |
| `master` vs this branch | `master` / `origin/master` still at `67b5be5` (excel 1.9.0). Kit 2.3.1 lives only on `docs/repo-kit-upgrade-2.3.1` until merged |

---

### 9. Product backlog (not RULES violations)

Tracked in [docs/PLAN.md](../PLAN.md) and [docs/plan/](../plan/). PLAN `tuning.must_not_extra` already forbids starting Cluster 2/3 code before freeze.

| Item | Status | Constraint reminder |
|------|--------|---------------------|
| Cluster 2 multi-file / naming / default xlsx | developing — [cluster-2-multi-file.md](../plan/cluster-2-multi-file.md) | No scoring math in PowerShell; non-clobber outputs |
| Cluster 3 group / sort / denial sheet | developing — [cluster-3-analysis.md](../plan/cluster-3-analysis.md) | Reporting-only vs V2 boundary |
| B1.1 base-weight retune | pending | Fixtures + SCORE-METHODOLOGY + CHANGELOG together |
| Priority Matrix V2/V3 | design only | [WQ_Priority_Matrix_Concept.md](../WQ_Priority_Matrix_Concept.md) |

---

## Suggested work slices

Independent, smallest-first. Each slice should be its own commit surface.

| # | Slice | Status |
|---|-------|--------|
| A–D | Catalog, ENTERPRISE-SECURITY, pack YAML, empty dirs | **Done** 2026-08-12 |
| E | Upstream-shaped kit link retargets | Still wait for repo-kit; do not re-add SETUP |
| F | Cluster 2 freeze (product) | After freeze: implementer + full certification |

Do not mix remaining E/F with an already-applied A–D stack.

---

## Out of scope

- Re-running certification for this docs-only research note  
- Rewriting published commits to add missing AI trailers  
- Implementing Cluster 2/3  
- Treating this file as L4 law  

---

## Document history

| Version | Notes |
|---------|--------|
| 1.1.0 | Applied P1 + local P2 slices (CHANGELOG 1.14.1); remaining open items listed |
| 1.0.0 | Initial RULES-gap audit at `67bd4b2` |
