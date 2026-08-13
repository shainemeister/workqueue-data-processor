---
title: Code Continuity
description: Optional overlay policy for surgical edits, named protected surfaces, and git continuity so working behavior stays continuous.
version: "1.0.0"
status: current
audience:
  - developers
  - maintainers
doc_type: other
related:
  - ../RULES.md
  - ./architecture.md
  - ./contracts.md
  - ./workboard.md
  - ./versioning-and-git.md
  - ./verification-and-ops.md
  - ../templates/TEMPLATE-CONTINUITY.md
last_updated: "2026-08-12"
---

# Code Continuity

Optional **overlay policy** for repositories with high-blast-radius surfaces. Generic kit rules still apply. This module states **when** to maintain a filled overlay and the portable edit defaults. It does **not** name product files.

**Document version:** 1.0.0

**Related:** [RULES.md](../RULES.md) · [architecture.md](./architecture.md) · [contracts.md](./contracts.md) · [workboard.md](./workboard.md) · [verification-and-ops.md](./verification-and-ops.md) · [TEMPLATE-CONTINUITY.md](../templates/TEMPLATE-CONTINUITY.md)

---

## Summary

| Must | Must not |
|------|----------|
| Prefer **surgical** edits (smallest unique change) | Full-file rewrite of a named protected surface unless the user explicitly requests restore |
| Name protected surfaces in a **filled overlay** when the repo has high-blast-radius code | Ship product-specific paths in this kit module |
| Commit after each solid, verified step | Stack many unrelated concerns in one uncommitted blob |
| Run declared verification before “done” | Claim complete on a shallow probe alone when the inventory declares more |
| Update canonical L4 docs + CHANGELOG when contracts change | Behavior-only commits for release-worthy public surfaces |
| Update `docs/WORKBOARD.md` when multi-phase work advances ([workboard.md](./workboard.md)) | Claim phase complete only in chat without board + commit |

**Dual path:** docs-only, trivial, or low-coupling repos may skip a filled overlay. **Not** a Domain A/B gate.

---

## Contents

1. [Summary](#summary)
2. [When to maintain an overlay](#when-to-maintain-an-overlay)
3. [What this kit file is not](#what-this-kit-file-is-not)
4. [Portable edit policy](#portable-edit-policy)
5. [Protected surfaces (adopter-filled)](#protected-surfaces-adopter-filled)
6. [Git continuity](#git-continuity)
7. [Relationship to the workboard](#relationship-to-the-workboard)
8. [Document history](#document-history)

---

## When to maintain an overlay

Copy [TEMPLATE-CONTINUITY.md](../templates/TEMPLATE-CONTINUITY.md) into the **adopting** repository as a **separate filled overlay** when **any** of these are true:

- A small set of files, if rewritten casually, regress working behavior  
- Multi-turn AI work has already caused lost polish or history  
- The authority map already lists high-blast-radius owners  

**Typical overlay homes** (pick one; record it in the authority map and, when Instruct is in use, PLAN overlays): a project path such as `docs/project_build/continuity.md`, or a clearly named file under `kit/` that is **not** this portable module. Do **not** replace this file’s empty surface table with product paths.

Leave the template placeholders **unfilled in this kit module**. Adopters replace `{{…}}` only in their overlay.

On [UPGRADE](../UPGRADE.md): **preserve** the filled overlay. Merge new portable Musts from **this** file; do not overwrite the adopter’s surface table with the empty template.

---

## What this kit file is not

| This file | Adopter overlay |
|-----------|-----------------|
| Portable policy + defaults | Named paths, gates, and UI/runtime invariants |
| Domain-agnostic | Product-, stack-, or org-specific |
| Safe to merge from upstream | Must be preserved on upgrade |

Do **not** add industry, game, CAD, or vendor file lists here.

---

## Portable edit policy

1. **Read before write** — open the current file region; do not reconstruct from disposable dumps by default.  
2. **Surgical replace** — patch functions/blocks; do not overwrite an entire large file with a fragment.  
3. **No opportunistic scope** — if the ask names one surface, do not retouch another protected surface “while here.”  
4. **One protected surface per change set** unless the user explicitly requests a multi-surface fix **and** each step is committed.  
5. **Stop on regression** — if a fix breaks a declared smoke or a named invariant, revert that change before inventing a second large fix.  
6. **Declared gates still win** — [verification-and-ops](./verification-and-ops.md#completion-rule).

---

## Protected surfaces (adopter-filled)

The kit default table is empty of product paths. Adopters fill:

| Surface | Paths (canonical) | Risk if mishandled |
|---------|-------------------|--------------------|
| *none until the adopter names them* | — | — |

**Rule:** touch a named surface only when the user task **names** it; keep diffs minimal; verify the overlay’s listed gates after.

---

## Git continuity

| Practice | Detail |
|----------|--------|
| Commits on a named branch | Baseline required; no multi-hour uncommitted rewrites of protected surfaces |
| Conventional commits | `type(scope):` matching staged files |
| Commit after verify | Declared gates for that slice |
| Multi-phase phase ship | Include `docs/WORKBOARD.md` status + commit SHA in the same change set when practical |
| One logical surface | Prefer one protected surface or one public contract per commit |
| AI disclosure | When AI-assisted: trailers per [versioning-and-git.md](./versioning-and-git.md) |
| Rollback | Prefer revert / restore from git over hand-merging broken trees |

Never treat disposable scratch files as source of truth over `git` + the working tree.

---

## Relationship to the workboard

Continuity is **how** to change code. The [workboard](./workboard.md) is **what** multi-phase work is open. When both apply, phase ship includes the board and respects named protected surfaces.

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | Initial optional continuity policy + overlay contract (kit 2.4.0) |
