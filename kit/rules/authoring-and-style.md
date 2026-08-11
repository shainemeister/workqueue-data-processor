---
title: Authoring and Style
description: Documentation rules, formatting conventions, Python pylint gate, and non-Python style gates.
version: "1.0.0"
status: current
audience:
  - developers
  - technical-writers
doc_type: other
related:
  - ../RULES.md
  - ../MARKDOWN-STANDARD.md
  - ./contracts.md
  - ./verification-and-ops.md
  - ../configs/pylintrc
last_updated: "2026-07-28"
---

# Authoring and Style

How to write and structure documentation, and how to gate product code style (Domain B).

**Document version:** 1.0.0  

**Related:** [RULES.md](../RULES.md) · [MARKDOWN-STANDARD.md](../MARKDOWN-STANDARD.md) · [contracts.md](./contracts.md) · [verification-and-ops.md](./verification-and-ops.md) · [pylintrc](../configs/pylintrc)

---

## Summary

| Must | Must not |
|------|----------|
| Follow MARKDOWN-STANDARD for substantial docs | Leave `{{PLACEHOLDERS}}` in finished docs |
| Update canonical docs with behavior changes | Use README as the only deep contract |
| Run declared style gates before complete | Ship pylint as a product runtime dependency |

Canonical owner policy: [contracts.md](./contracts.md). Document shape: [MARKDOWN-STANDARD.md](../MARKDOWN-STANDARD.md).

---

## Contents

1. [Summary](#summary)
2. [Documentation rules](#documentation-rules)
3. [Formatting and style](#formatting-and-style)
4. [Python style gate (pylint)](#python-style-gate-pylint)
5. [Non-Python style gates](#non-python-style-gates)
6. [Document history](#document-history)

---

## Documentation rules

1. **Substantial documents** follow [MARKDOWN-STANDARD.md](../MARKDOWN-STANDARD.md): YAML frontmatter, single H1, lead, Summary before Contents, body, history when versioned.  
2. **New docs** start from [templates/](../templates/); leave no unresolved `{{PLACEHOLDERS}}`. Pick templates from [project interest](../SETUP.md#5-pick-templates-by-interest) so contracts exist before or with first code.  
3. **Behavior change ⇒ doc change** in the same commit or PR — see [contracts.md](./contracts.md):  
   - CLI verbs, flags, exit codes, JSON shapes → matching CLI / API guide  
   - Formulas, output columns, validation → methodology (+ fixtures if contract shifts)  
   - Trust boundary or execution model → matching security doc  
4. **Prefer link + short summary** over pasting another document in full.  
5. **Root README** stays an overview; deep contracts stay in package docs.  
6. **Status honesty:** set frontmatter `status` to `draft` / `current` / `deprecated` accurately.  
7. **Platform-aware examples** follow [MARKDOWN-STANDARD — Platform-aware examples](../MARKDOWN-STANDARD.md#platform-aware-examples): declare primary OS when examples are OS-specific; dual fences when multi-platform.

---

## Formatting and style

| Area | Rule |
|------|------|
| Voice | Complete sentences; direct and professional; tables for parallel facts |
| Emphasis | **Bold** for critical terms and UI labels |
| Identifiers | `` `inline code` `` for paths, flags, column names, module names |
| Markdown structure | Per [MARKDOWN-STANDARD.md](../MARKDOWN-STANDARD.md); language-tagged code fences |
| Links | Relative from the file’s directory (`./CLI-GUIDE.md`, `../README.md`) |
| Paths in prose | Consistent separators within a file; match [platform-aware rules](../MARKDOWN-STANDARD.md#platform-aware-examples) |
| Examples | Prefer placeholders (`C:\path\to\...` and/or `/path/to/...`) plus one concrete repo-relative example; dual shell fences when multi-OS |
| Platform | State primary platform(s) for verify/build examples; fill verification table with the command(s) the team actually runs |
| Python | When the project ships Python product code: **PEP-8 via pylint** — see [Python style gate (pylint)](#python-style-gate-pylint) |
| Other languages | Declare a style gate — see [Non-Python style gates](#non-python-style-gates) |

---

## Python style gate (pylint)

All **product** Python under the packages this project ships must stay **pylint-clean** under the project’s gate config before sharing behavior or packaging changes.

| Item | Rule |
|------|------|
| **Config** | [configs/pylintrc](../configs/pylintrc) — copy to the package or repo as `.pylintrc` (or pass `--rcfile`). PEP-8–aligned conventions (line length 100, docstrings, names, unused imports/vars, selected errors) |
| **Scope** | Product packages and modules only (not one-off scratch scripts unless the project says so) |
| **Command** | `python -m pylint <package_or_paths>` (or `py -3.x -m pylint …` on Windows) |
| **Pass criteria** | Exit code **0** and score **10.00/10** under that config |
| **When to run** | After any edit to product `*.py`, `.pylintrc` / `pylintrc`, or packaging that can affect style |
| **Product dependency** | **No.** Pylint is **developer tooling** only. Do **not** add pylint as a required install for end users of the product. |
| **Out of gate** | Design/refactor metrics (`too-many-*`, large-file complexity) are intentionally relaxed in the default config; do not “fix” them by silent API rewrites. Full default pylint without the gate config is informational only. |
| **Non-Python repos** | This gate does not apply. |

If pylint is not installed on a developer machine, install it into the **developer environment** (user/global Python or a dev extra), never into a product runtime path meant only for end users.

**Adopt steps:**

1. Copy `configs/pylintrc` (from kit: `kit/configs/pylintrc`) to the package or repo root as `.pylintrc`.  
2. **Must:** set `py-version` to the project’s supported Python (the file ships a starter default only—change it).  
3. Point the [verification table](./verification-and-ops.md#verification-before-ship) at the real package path.  
4. Extend `good-names` only when short identifiers are intentional and repeated.

---

## Non-Python style gates

Projects that ship non-Python product code should declare **one primary gate per language surface** in RULES or a thin overlay: tool name, command, and pass criteria. Put the command in the [verification table](./verification-and-ops.md#verification-before-ship). Non-Python gates **do not** inherit the pylint 10.00 score rule.

Recommended starting points (advisory—choose what the team will actually run):

| Language / ecosystem | Common gate tools | Typical pass criteria |
|----------------------|-------------------|------------------------|
| JavaScript / TypeScript | eslint, prettier | Lint exit 0; format clean (or check mode clean) |
| Go | gofmt / go fmt, golangci-lint | Format clean; linter exit 0 under project config |
| Rust | rustfmt, clippy | Format clean; clippy clean under project flags |
| Shell | shellcheck | No errors (or project-defined severity) |
| Other / mixed | Document tool + command in verification table | Exit 0 / project-defined |

**Rules:**

1. Name the tool and pass criteria explicitly—do not leave “we lint somehow” implied.  
2. Keep style tools as **developer tooling** unless the product truly requires them at runtime.  
3. Docs-only repositories may omit language style gates entirely.

Language inventory (which surfaces exist) lives in [security.md](./security.md#language-surface-inventory).

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | Extracted from RULES 1.4.1 for kit 2.0 |
