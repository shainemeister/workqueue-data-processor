---
title: Authoring and Style
description: Documentation rules, formatting conventions, Python pylint gate, and non-Python style gates.
version: "1.0.1"
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

**Document version:** 1.0.1  

**Related:** [RULES.md](../RULES.md) · [MARKDOWN-STANDARD.md](../MARKDOWN-STANDARD.md) · [contracts.md](./contracts.md) · [verification-and-ops.md](./verification-and-ops.md) · [kpi-analytics/.pylintrc](../../kpi-analytics/.pylintrc) · [pylintrc](../configs/pylintrc)

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
7. **Platform-aware examples** follow [MARKDOWN-STANDARD — Platform-aware examples](../MARKDOWN-STANDARD.md#platform-aware-examples). This repository’s **primary platform is Windows** (PowerShell 5.1 + Excel COM for excel-toolkit; Windows-first launchers for kpi-analytics). Dual OS blocks in templates may be kept for portable skeletons; product docs may stay Windows-only when that matches reality.

Additional project rules:

- CLI verbs, flags, exit codes, JSON shapes → matching toolkit `CLI-GUIDE.md`  
- Scoring formulas, output columns, validation → `SCORE-METHODOLOGY.md` (+ fixtures if contract shifts)  
- Trust boundary or execution model → matching `ENTERPRISE-SECURITY.md`  
- Root [README.md](../../README.md) stays an **end-user landing page**; deep contracts stay in toolkit docs.

---

## Formatting and style

| Area | Rule |
|------|------|
| Voice | Complete sentences; direct and professional; tables for parallel facts |
| Emphasis | **Bold** for critical terms and UI labels |
| Identifiers | `` `inline code` `` for paths, flags, column names, module names |
| Markdown structure | Per [MARKDOWN-STANDARD.md](../MARKDOWN-STANDARD.md); language-tagged code fences |
| Links | Relative from the file’s directory (`./CLI-GUIDE.md`, `../README.md`) |
| Paths in prose | Consistent separators within a file; Windows-style examples are fine |
| PowerShell | Target **5.1**; no PowerShell 7-only syntax in `excel-toolkit\`. Save product `.ps1`/`.psm1` as **UTF-8 with BOM** (or pure ASCII). PowerShell 5.1 reads BOM-less UTF-8 as system ANSI and can **fail to parse** on Unicode punctuation (arrows, em dashes). |
| Python | Target **3.13**; **standard library only** in product `kpi-analytics\` code |
| Python style | PEP-8 via **pylint** against [kpi-analytics/.pylintrc](../../kpi-analytics/.pylintrc) — see [Python style gate (pylint)](#python-style-gate-pylint) |
| Other languages | Declare a style gate — see [Non-Python style gates](#non-python-style-gates) |
| Examples | Prefer placeholders (`C:\path\to\...`) plus one concrete repo-relative example |

---

## Python style gate (pylint)

All product Python under `kpi-analytics\kpi_modules\` must stay **pylint-clean** under the repo gate config before sharing scoring or packaging changes.

| Item | Rule |
|------|------|
| **Config** | [kpi-analytics/.pylintrc](../../kpi-analytics/.pylintrc) — PEP-8–aligned conventions (line length 100, docstrings, names, unused imports/vars, selected errors). Kit starter: [configs/pylintrc](../configs/pylintrc) |
| **Scope** | `kpi_modules` package only |
| **Command** | From `kpi-analytics\`: `py -3.13 -m pylint kpi_modules` (or `python -m pylint kpi_modules`) |
| **Pass criteria** | Exit code **0** and score **10.00/10** under that config |
| **When to run** | After any edit to `kpi_modules\*.py`, `.pylintrc`, or related packaging that can affect style |
| **Product dependency** | **No.** Pylint is **developer tooling** only. Do **not** add pylint (or any pip package) to product runtime, launchers, or enterprise install steps. End users run scoring with stdlib Python only. |
| **Out of gate** | Design/refactor metrics (`too-many-*`, large-file complexity) are intentionally relaxed in `.pylintrc`; do not “fix” them by silent API rewrites. Full default pylint without the config is informational only. |

If pylint is not installed on a developer machine, install it into the **developer** environment (user/global Python), never into a product `requirements.txt` or toolkit path meant for locked-down PCs.

**Maintain steps:**

1. Keep `.pylintrc` under `kpi-analytics\` (package-local).  
2. **Must:** keep `py-version` set to the supported product Python (**3.13**).  
3. Point the [verification table](./verification-and-ops.md#verification-before-ship) at `kpi_modules`.  
4. Extend `good-names` only when short identifiers are intentional and repeated.

---

## Non-Python style gates

Projects that ship non-Python product code declare **one primary gate per language surface**: tool name, command, and pass criteria. Non-Python gates **do not** inherit the pylint 10.00 score rule.

| Language / surface | Gate (this repo) | Pass criteria |
|--------------------|------------------|---------------|
| **Python** (`kpi_modules`) | pylint — see above | Exit 0, score 10.00/10 |
| **PowerShell** (`excel-toolkit`) | Manual / review gate: parse under **Windows PowerShell 5.1**; UTF-8 **with BOM** (or pure ASCII); no PS7-only syntax | Scripts load without parse errors; COM smoke via `excel-toolkit.cmd probe` / `Test-ExcelCom.ps1 -DryRun` as appropriate |
| Shell / other | Not a product surface here | — |

**Rules:**

1. Name the tool and pass criteria explicitly—do not leave “we lint somehow” implied.  
2. Keep style tools as **developer tooling** unless the product truly requires them at runtime.  
3. If a formal PowerShell linter (e.g. PSScriptAnalyzer) is later adopted as Domain B, document the command and pass criteria here and in the verification table. (This repo already uses PSScriptAnalyzer as **Domain A** — see [security.md](./security.md).)

Language inventory (which surfaces exist) lives in [security.md](./security.md#language-surface-inventory).

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.1 | Project fill: Windows primary, pylint path, PowerShell 5.1/BOM, Python 3.13 stdlib |
| 1.0.0 | Extracted from RULES 1.4.1 for kit 2.0 |
