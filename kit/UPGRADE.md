---
title: Upgrade repo-kit
description: Durable guide for upgrading an existing kit baseline, including 1.x to 2.x layout migration (standards under kit/) and merge options.
version: "1.1.0"
status: current
audience:
  - developers
  - maintainers
doc_type: other
related:
  - RULES.md
  - SETUP.md
  - CHANGELOG.md
  - ../README.md
  - rules/versioning-and-git.md
  - rules/hygiene.md
last_updated: "2026-07-28"
---

# Upgrade repo-kit

Durable procedure for **repositories that already adopted** the Repository Standards Kit. Not deleted after initiation—keep under project `kit/` or always open this file at Kit source.

**Document version:** 1.1.0  

**Related:** [RULES.md](./RULES.md) · [SETUP.md](./SETUP.md) · [CHANGELOG.md](./CHANGELOG.md) · [README.md](../README.md) · [versioning-and-git.md](./rules/versioning-and-git.md) · [hygiene.md](./rules/hygiene.md)

---

## Summary

| Situation | Use |
|-----------|-----|
| **No** Kit baseline / never adopted | Stop — use [SETUP.md](./SETUP.md) (first adopt) |
| Baseline ≥ 2.0 **and** standards already under `kit/` | [Routine upgrade procedure](#routine-upgrade-procedure) |
| Baseline **&lt; 2.0** **or** standards still on **project root** (1.x layout) | [Migrate from kit 1.x / root layout to 2.x](#migrate-from-kit-1x--root-layout-to-2x) then routine steps for remaining deltas |

**Prerequisite:** Kit baseline table exists (in `kit/RULES.md`, or root `RULES.md` until migrated). See [Kit baseline](./RULES.md#kit-baseline).

**Packaging target:** merge standards into the project’s **`kit/`** tree. Keep product code and **project root** `CHANGELOG.md` outside `kit/`. See [hygiene.md](./rules/hygiene.md).

---

## Contents

1. [Summary](#summary)
2. [Choose your path](#choose-your-path)
3. [Routine upgrade procedure](#routine-upgrade-procedure)
4. [Migrate from kit 1.x / root layout to 2.x](#migrate-from-kit-1x--root-layout-to-2x)
5. [Merge strategy options](#merge-strategy-options)
6. [Preserve list](#preserve-list)
7. [Copy-paste AI prompts](#copy-paste-ai-prompts)
8. [Document history](#document-history)

---

## Choose your path

| Path | Condition | Jump to |
|------|-----------|---------|
| **First adopt into existing repo** | No Kit baseline | [SETUP.md](./SETUP.md) (selective / align mode) |
| **Routine upgrade** | Standards under `kit/`; baseline current major | [Routine upgrade procedure](#routine-upgrade-procedure) |
| **Layout + path migration** | 1.x baseline **or** root-level RULES/MARKDOWN-STANDARD/rules | [Migrate from kit 1.x / root layout to 2.x](#migrate-from-kit-1x--root-layout-to-2x) |

---

## Routine upgrade procedure

1. Read this project’s **Kit baseline** (Adopted kit version, Kit source, Adopted on) in **`kit/RULES.md`**.  
2. Open **Kit source** (canonical: https://github.com/shainemeister/repo-kit) → [`kit/CHANGELOG.md`](./CHANGELOG.md) → `## repo-kit`.  
3. List releases **after** your Adopted kit version only.  
4. Build a **focused merge plan**: only pieces this project uses (hub `RULES.md`, `rules/*`, `MARKDOWN-STANDARD.md`, templates, configs, `.gitignore` patterns).  
5. **Merge into project `kit/`** — not onto the product root.  
6. **Preserve** project-specific values — see [Preserve list](#preserve-list).  
7. Fix relative links (`../README.md`, `../CHANGELOG.md`, `../packages/…`).  
8. Update **Adopted kit version** and **Adopted on**; keep Kit source unchanged (unless deliberate fork).  
9. **Project root** `CHANGELOG.md`: short note (e.g. “Upgraded repo-kit baseline to X.Y.Z”)—**never** paste full kit history.  
10. Re-run the project verification table / [completion rule](./rules/verification-and-ops.md#completion-rule).  
11. Optional: refresh local `kit/UPGRADE.md` from upstream.

---

## Migrate from kit 1.x / root layout to 2.x

Kit **2.0+** packages standards under `kit/` and splits RULES into a hub plus domain modules. **Adopting projects** should use the same packaging: standards under **`kit/`**, repository-specific data outside.

### Upstream path migration (kit source)

| Old (1.x upstream) | New (2.x upstream) |
|--------------------|--------------------|
| `/RULES.md` | `/kit/RULES.md` + `/kit/rules/*` |
| `/SETUP.md` | `/kit/SETUP.md` |
| *(none)* | `/kit/UPGRADE.md` (this file) |
| `/MARKDOWN-STANDARD.md` | `/kit/MARKDOWN-STANDARD.md` |
| `/CHANGELOG.md` | `/kit/CHANGELOG.md` (kit history only) |
| `/configs/` | `/kit/configs/` |
| `/templates/` | `/kit/templates/` |
| `/examples/` | `/kit/examples/` |

### Adopter layout migration (your product repo)

| Before (1.x-style product repo) | After (2.x-style product repo) |
|---------------------------------|--------------------------------|
| Root `RULES.md` | **`kit/RULES.md`** |
| Root `rules/` (if any) | **`kit/rules/`** |
| Root `MARKDOWN-STANDARD.md` | **`kit/MARKDOWN-STANDARD.md`** |
| Root `SETUP.md` | Remove after use; do not keep permanent |
| Root `UPGRADE.md` (if any) | **`kit/UPGRADE.md`** |
| Root `CHANGELOG.md` | **Stay at project root** (project history) |
| Packages / src | **Stay outside `kit/`** |

### What to do

| Topic | Guidance |
|-------|----------|
| Move standards into `kit/` | `git mv` or equivalent; update all relative links |
| Modular rules | Prefer `kit/RULES.md` + `kit/rules/*` |
| Contracts module | Ensure [contracts](./rules/contracts.md) exists; authority-map row for contract policy |
| Project CHANGELOG | Remains at **repo root** |
| Product code | Never under `kit/` |
| Authority map | Standards → `kit/…`; product → packages/paths outside; history → `../CHANGELOG.md` from kit files |
| AI / runbooks | Point at `kit/UPGRADE.md`, `kit/RULES.md`, Kit source `kit/CHANGELOG.md` |

### Checklist

- [ ] Confirm baseline is 1.x **or** standards still live at project root  
- [ ] Create `kit/` if missing; move RULES, MARKDOWN-STANDARD, rules modules, UPGRADE into `kit/`  
- [ ] Merge hub shape + domain modules from upstream  
- [ ] Keep project `CHANGELOG.md` at root; do not replace it with kit CHANGELOG  
- [ ] Update authority map paths and deep links  
- [ ] Update agent prompts / internal docs to `kit/…` paths  
- [ ] Set baseline to latest 2.x after applying deltas  
- [ ] Project CHANGELOG note for major kit / layout upgrade  

Then run [Routine upgrade procedure](#routine-upgrade-procedure) for any remaining releases.

---

## Merge strategy options

| Strategy | When | How |
|----------|------|-----|
| **Selective file merge into `kit/`** | Default | Copy/merge changed upstream kit files into project `kit/` |
| **Reference / submodule** | Want upstream tracking | Submodule or sibling clone; filled project hub still documents product paths; compare `kit/CHANGELOG` on upgrade |
| **Single-file RULES under `kit/`** | Small teams | One `kit/RULES.md`; port deltas from hub + children manually; still record baseline |
| **Hub + rules/ under `kit/`** | Recommended | `kit/RULES.md` + `kit/rules/*.md` |

---

## Preserve list

Never clobber on merge:

- Authority map **product paths** (outside `kit/`)  
- Language surface inventory **filled rows**  
- Verification commands  
- Package CLI / SECURITY / METHODOLOGY content  
- Project root CHANGELOG **history**  
- Kit baseline **Kit source** URL (unless deliberate fork)  

---

## Copy-paste AI prompts

### Routine upgrade

```text
Upgrade repo-kit for this repository (Kit baseline in kit/RULES.md).

1. Read Kit baseline (Adopted kit version, Kit source).
2. Open kit/UPGRADE.md and kit/CHANGELOG.md under ## repo-kit at Kit source (https://github.com/shainemeister/repo-kit).
3. Follow UPGRADE routine procedure; merge only appropriate deltas into this project's kit/; preserve authority map product paths and verification.
4. Update Kit baseline; add a short note to project root CHANGELOG.md.
```

### 1.x / root layout → 2.x migration

```text
Migrate this repository to repo-kit 2.x packaging using kit/UPGRADE.md (Migrate from kit 1.x / root layout to 2.x).
Move standards under kit/; keep product code and project CHANGELOG outside kit/. Preserve authority map product paths. Update baseline and project CHANGELOG.
```

### First adopt into existing repo (no baseline)

```text
This repository has no repo-kit baseline. Follow kit/SETUP.md selective adoption: add kit/ for standards, keep product outside kit/, record Kit baseline in kit/RULES.md. Do not use UPGRADE until after first adopt.
```

---

## Document history

| Version | Notes |
|---------|--------|
| 1.1.0 | Adopter target is project `kit/`; 1.x/root layout migration moves standards into kit/; product CHANGELOG stays at root |
| 1.0.0 | Initial durable upgrade guide for kit 2.0 |
