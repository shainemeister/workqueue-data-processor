---
title: Versioning and Git
description: Three version surfaces, mandatory CHANGELOG, kit baseline pointer, git hygiene, commit format, and AI disclosure.
version: "1.0.2"
status: current
audience:
  - developers
doc_type: other
related:
  - ../RULES.md
  - ../UPGRADE.md
  - ../../CHANGELOG.md
  - ./contracts.md
  - ./verification-and-ops.md
last_updated: "2026-07-30"
---

# Versioning and Git

Version surfaces, CHANGELOG discipline, and git / commit rules.

**Document version:** 1.0.2  

**Related:** [RULES.md](../RULES.md) · [UPGRADE.md](../UPGRADE.md) · [CHANGELOG.md](../../CHANGELOG.md) · [contracts.md](./contracts.md) · [verification-and-ops.md](./verification-and-ops.md)

---

## Summary

| Must | Must not |
|------|----------|
| Maintain **project root** `CHANGELOG.md` (Keep a Changelog) | Ship version bumps without CHANGELOG |
| Keep [Kit baseline](../RULES.md#kit-baseline) current in `kit/RULES.md` | Paste full kit history into project CHANGELOG |
| Keep standards under `kit/` ([hygiene](./hygiene.md)) | Flatten standards onto product root as default |
| Use conventional commits that match staged files | Vague subjects (`update stuff`, `wip`) |
| Disclose AI assistance when applicable | Rewrite shared published history without coordination |

**Kit upgrades:** follow durable [UPGRADE.md](../UPGRADE.md)—not SETUP after initiation.

---

## Contents

1. [Summary](#summary)
2. [Three version surfaces](#three-version-surfaces)
3. [Mandatory project CHANGELOG](#mandatory-project-changelog)
4. [Kit baseline and upgrades](#kit-baseline-and-upgrades)
5. [Consistency rules](#consistency-rules)
6. [Git rules](#git-rules)
7. [Commit message format](#commit-message-format)
8. [Documentation consistency in commits](#documentation-consistency-in-commits)
9. [Suggested commit workflow](#suggested-commit-workflow)
10. [Remotes](#remotes)
11. [Document history](#document-history)

---

## Three version surfaces

| Surface | What it is | Authority |
|---------|------------|-----------|
| **Kit version** | Semver of the Repository Standards Kit as a whole | Upstream [kit/CHANGELOG.md](https://github.com/shainemeister/repo-kit/blob/main/kit/CHANGELOG.md) dated sections (`### [X.Y.Z] - YYYY-MM-DD`) under `## repo-kit` |
| **Project / package version** | The adopting repo’s product or library semver | Project packaging metadata **and** project root `CHANGELOG.md` |
| **Document version** | Per-document frontmatter `version` + `last_updated` | That document only—not automatically equal to package or kit version |

| Surface | When to bump |
|---------|----------------|
| Package / library version | CLI contract, public API, scoring/export behavior, or stable output field names change |
| Document frontmatter `version` + `last_updated` | That document’s guidance or contract changes |
| Methodology **Document history** table | Material formula or interpretation changes |
| Project `CHANGELOG.md` | See [Mandatory project CHANGELOG](#mandatory-project-changelog) |
| Kit baseline (adopted kit version) | On first adopt and every kit upgrade — see [Kit baseline](../RULES.md#kit-baseline) |

### This repository — package version surfaces

| Surface | When to bump |
|---------|----------------|
| `kpi_modules.__version__` | CLI contract, scoring behavior, or stable output column names change |
| `ExcelToolkitVersion` (module) | CLI verbs/options/JSON shapes or export behavior change |
| Project / package authority | Also root [CHANGELOG.md](../../CHANGELOG.md) under `## workqueue-data-processor` |

---

## Mandatory project CHANGELOG

Every repository that adopts this kit **must** maintain a root **`CHANGELOG.md`**. Docs-only and standards repos are not exempt: they version documentation and policy releases the same way.

| Rule | Detail |
|------|--------|
| **Required file** | **Project root** `CHANGELOG.md` — listed in the [authority map](../RULES.md#authority-map) and [hygiene](./hygiene.md); standards stay under `kit/` |
| **Format** | [Keep a Changelog](https://keepachangelog.com/) categories; dates ISO 8601 (`YYYY-MM-DD`) |
| **Structure** | `## <Repository Name>` → dated `### [X.Y.Z] - YYYY-MM-DD` → `#### Added` / `#### Changed` / … |
| **Categories** | Use as needed: **Added**, **Changed**, **Deprecated**, **Removed**, **Fixed**, **Security** |
| **Same change set** | Release-worthy behavior or contract changes include the CHANGELOG entry with the code/docs that ship them |

There is **no Unreleased section**. Record each change under the `### [X.Y.Z]` version section that ships it.

**When a CHANGELOG entry is required**

| Change | CHANGELOG |
|--------|-----------|
| Package / public contract version bump | **Required** — matching `### [X.Y.Z]` under the repository H2 |
| Behavior, CLI, API, schema, security-model change | **Required** under the version section that ships the change |
| Kit adoption or kit upgrade | **Required** (note kit version; do **not** paste kit release history) |
| Security fix | **Required** |
| Pure typo or non-contract wording | Optional; **must not** ship a package version bump without a matching version section |

**This kit repository** records kit history under `## repo-kit` in [kit/CHANGELOG.md](../CHANGELOG.md), not under a product repository H2.

---

## Kit baseline and upgrades

Fill and keep the [Kit baseline](../RULES.md#kit-baseline) table in every adopting project’s **`kit/RULES.md`**. Update it on every kit upgrade.

**Procedure (do not duplicate here):** [UPGRADE.md](../UPGRADE.md) — routine upgrade, 1.x → 2.0 migration, merge options, AI prompts.

After initiation, `SETUP.md` is gone. Kit baseline + UPGRADE keep upgrades trackable.

---

## Consistency rules

1. Frontmatter `version` and the in-doc status line must **match** when both exist.  
2. Docs that cite a product version must stay aligned with the code version they describe.  
3. Prefer **backward-compatible** additions (new columns, new optional flags) over silent renames. Breaking changes require explicit notes in the CLI/API guide, history, and CHANGELOG.  
4. Design / concept docs may advance without implementing code; label implementation status clearly.  
5. Behavior or contract changes, their **canonical** docs, the appropriate **version bump**, and the **CHANGELOG** entry belong in the **same change set** when the change is release-worthy — see [contracts.md](./contracts.md).  
6. Kit version and project/package version are **independent**. Adopting a new kit does not force a product version bump unless product behavior also changes.

---

## Git rules

### What to track

| Track | Do not track |
|-------|----------------|
| Source (`.py`, `.ps1`, `.psm1`, `.cmd`) | `output\` |
| Schema, sample data, fixtures | `__pycache__\`, `*.pyc` |
| `import\` synthetic / non-PHI inputs | Real PHI/PII extracts under `import\` (or anywhere) |
| Docs, `kit/`, `.gitignore`, style configs | `.venv\`, `venv\`, `.env` |
| Diagnostics folder **README** files | Secrets, IDE-only folders already ignored |
| | `kpi-analytics\diagnostics\last_diagnostics.*` (regenerable package diagnostics) |
| | `excel-toolkit\diagnostics\last_diagnostics.*` (regenerable package diagnostics) |
| | `certification\last_certification.*` (regenerable formal cert outputs) |

Respect [`.gitignore`](../../.gitignore). Do not force-add ignored generated artifacts “for convenience.”

### Commits and history

1. **Review before commit:** `git status` and `git diff`. Confirm no accidental large dumps, credentials, or regenerable artifacts.  
2. **Small, focused commits** preferred over mixed unrelated changes—one logical concern / one authority-map surface when practical. Prefer a **short stack** over a single mixed mega-commit.  
3. **Messages** follow [Commit message format](#commit-message-format) below.  
4. **Do not rewrite published shared history** (`push --force` to a shared default branch) without explicit coordination.  
5. **Branches (recommended):** `feature/…`, `fix/…`, `docs/…` when work is non-trivial.  
6. **Contract-breaking changes:** prefer review (PR) when a remote exists; call out migration notes in the commit or PR body.  
7. **No secrets in history.** If leaked, rotate credentials and treat history cleanup as an incident—not a casual amend.

---

## Commit message format

**Principle:** The commit subject (and body, when present) should remain understandable **years later** when searching history—name the real surface and intent, not a temporary mood.

Use a **Conventional Commits–style** subject so history stays scannable.

```text
<type>(<scope>): <imperative summary>
```

| Part | Rule |
|------|------|
| **type** | One of the types in the table below |
| **scope** | Package or area; see [Scope conventions](#scope-conventions). Omit for true repo-wide root files when no better scope fits |
| **summary** | Imperative mood, specific, ≤ ~72 characters; no trailing period |
| **body** (optional) | For non-trivial commits: **why** the change matters and any **migration** notes; link to the canonical doc if non-obvious. Tiny one-line docs fixes may omit a body |

| type | Use when |
|------|----------|
| `feat` | User-visible behavior: new CLI verb/flag, API, export capability, diagnostics |
| `fix` | Correct wrong behavior without changing the intended contract |
| `docs` | Documentation only (README, CLI guide, methodology, security, catalog, templates) |
| `chore` | Version bumps, `.gitignore`, packaging/layout hygiene with no product behavior change |
| `refactor` | Internal structure only; same public contracts |
| `test` | Fixtures, validation harness, probes (no product API change) |

### Scope conventions

| Context | Preferred scopes | Notes |
|---------|------------------|--------|
| **Toolkits** | `kpi-analytics`, `excel-toolkit` | Use when the change is limited to that surface |
| **Standards / policy** | `kit`, or omit | `kit/RULES.md`, domain modules, MARKDOWN-STANDARD, templates |
| **Omit scope** | — | Root-wide files with no single toolkit owner (`docs/FILE-CATALOG.md`, root README, schema, CHANGELOG) |

Scopes are advisory: consistency within a repo matters more than matching this table exactly.

### Optional footers

Useful when needed; **not** mandatory (except the AI disclosure block, which is **required when applicable**):

| Footer | Use when |
|--------|----------|
| `BREAKING CHANGE: <description>` | Public contract breaks; describe migration |
| `Refs: <issue-or-doc>` | Link a tracker item or canonical doc |
| `Co-authored-by: Name <email>` | Shared authorship |
| AI disclosure block (`Assisted-by` / `Compliance` / `Instructed-by`) | **Required** when AI meaningfully assisted; see [AI-assisted commits](#ai-assisted-commits-required-disclosure) |

### AI-assisted commits (required disclosure)

When an AI system meaningfully assists with the **change itself** (code, docs, configuration, or the commit message), the commit **must** include the following footer block. Pure human-only commits omit it.

| Trailer | Required content |
|---------|------------------|
| `Assisted-by:` | AI make / model (and optional tool) that assisted **this** commit — fill at commit time |
| `Compliance:` | Explicit reference to maintenance rules (`RULES.md` or this module set) |
| `Instructed-by:` | Directing human — **value of** `git config user.name` for the committer |

**Template form** (copy structure; resolve fields at commit time):

```text
Assisted-by: <AI make / model>
Compliance: RULES.md
Instructed-by: <git config user.name>
```

**How to resolve fields**

| Field | Resolution |
|-------|------------|
| `Assisted-by` | Name the AI make/model/tool that actually performed the work for this commit. Do not hardcode a vendor from documentation. |
| `Instructed-by` | Run `git config user.name` and use that exact string. If unset, configure it before committing so disclosure matches Git author identity. |

```text
git config user.name
```

**Example values for `Assisted-by`** (use the one that actually did the work):

| Situation | Example value |
|-----------|----------------|
| xAI Grok assistant | `Grok (xAI)` |
| Anthropic Claude | `Claude 4 Sonnet` (or the exact model name used) |
| GitHub Copilot | `GitHub Copilot` |
| Cursor agent | `Cursor Agent` |
| Other | Name the primary assistant for this commit |

**Rules**

1. Place the three lines at the end of the commit message (after any body or other footers).  
2. **`Assisted-by` is dynamic:** use the real AI make/model (and tool if useful) that performed the work for **this** commit.  
3. **`Instructed-by` is dynamic:** set it to the output of `git config user.name`.  
4. The presence of this block asserts that the human (Git-configured committer) reviewed the result and that the change follows maintenance contracts.  
5. Do **not** put the AI disclosure in the subject line.

**When it is required**

| Situation | Disclosure |
|-----------|------------|
| AI wrote or substantially edited product code, docs, or config | **Required** |
| AI drafted the commit message itself | **Required** |
| AI only suggested a one-line fix that the human rewrote | Optional (prefer to include) |
| Pure human work | Omit |

**Good example** (illustrative; `Instructed-by` must match `git config user.name`):

```text
docs(rules): require AI disclosure footer on assisted commits

Add Assisted-by / Compliance / Instructed-by trailers so AI
participation is transparent and auditable years later.

Assisted-by: Grok (xAI)
Compliance: RULES.md
Instructed-by: Jane Developer
```

### Examples (match this voice)

**Good:**

```text
feat(kpi-analytics): add enterprise diagnostics module and gate helpers
chore(kpi-analytics): bump package version to 1.6.0
docs(kpi-analytics): document diagnostics command, gate flags, and CLI contract
docs: catalog diagnostics module and diagnostics folder
fix(excel-toolkit): retry Excel Quit before warning the user
docs: upgrade repo-kit baseline to 2.0.1 with kit/ layout
```

**Bad → good:**

| Avoid | Prefer |
|-------|--------|
| `update stuff` | `docs(kpi-analytics): document validate-score exit codes` |
| `wip` | Finish, then commit a clear subject |
| `fix bugs` | `fix(excel-toolkit): handle missing CSV path without crash` |
| `feat: updates` (docs-only staged) | `docs: …` — do not use `feat` for documentation-only changes |

---

## Documentation consistency in commits

Commit messages and **what is staged** must stay consistent with the documentation authority map and [contracts.md](./contracts.md).

| Situation | Commit practice |
|-----------|-----------------|
| Behavior / CLI / API / security model changes | Update the **canonical** doc in the **same change set** |
| Prefer readability of history | Prefer **one logical surface per commit** |
| Code + matching docs for one feature | Either (a) one commit with code **and** its canonical docs, or (b) a short stack |
| Path add/remove/rename | Include inventory/catalog update when the project maintains one |
| Package version bump | Subject uses `chore(<scope>): bump … to X.Y.Z` |
| Docs-only edits | Use `docs` / `docs(<scope>)`. Do not use `feat` for documentation |

**Pre-commit message check:**

1. Does the subject type match the staged content?  
2. Is this **one logical surface** (or an intentional code+docs pair)?  
3. If CLI/API shapes changed, is the matching guide updated?  
4. If trust/execution model changed, is the matching security doc updated?  
5. If formulas or public output fields changed, are methodology + fixtures updated?  
6. If product code or gate config changed: will the **full** certification harness pass (pylint + security + Gitleaks)?  
7. Is partial recert avoided (no security-only or pylint-only cert rewrite)?  
8. If release-worthy: is [CHANGELOG.md](../../CHANGELOG.md) updated?  
9. Would a reviewer find the subject by searching the feature name used in the README?  
10. Would this subject still make sense **two years** from now without the PR description?  
11. If AI assisted: are `Assisted-by` / `Compliance` / `Instructed-by` present? Does `Assisted-by` name the AI that did the work? Does `Instructed-by` match `git config user.name`?

---

## Suggested commit workflow

```text
git status
git diff
git add path/to/file
git commit -m "type(scope): imperative summary of this file or surface"
git status
```

On Windows Command Prompt, path separators may be `\`; Git accepts `/` in paths on all common platforms. Stage one focused surface (or one logical pair) per commit.

For a multi-file feature, a typical stack is: implementation → package version → docs → inventory / RULES if those changed.

---

## Remotes

A remote is optional. When one exists, do not assume write access to `main`/`master` without team convention. Tags for releases are optional but should match the package version if used.

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.2 | Project fill: package version surfaces, track table, scopes, pre-commit checks |
| 1.0.1 | Kit baseline path `kit/RULES.md`; standards under kit/; project CHANGELOG at root |
| 1.0.0 | Extracted from RULES 1.4.1 for kit 2.0; upgrade playbook deferred to UPGRADE.md; kit CHANGELOG path under kit/ |
