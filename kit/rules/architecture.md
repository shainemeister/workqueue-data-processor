---
title: Architecture and Boundaries
description: Package composition, entry points, runtime separation, and dependency policy.
version: "1.0.1"
status: current
audience:
  - developers
  - architects
doc_type: other
related:
  - ../RULES.md
  - ./contracts.md
  - ./security.md
last_updated: "2026-07-28"
---

# Architecture and Boundaries

Structural rules for how packages and runtimes relate. Public surfaces those packages expose are **contracts**—see [contracts.md](./contracts.md).

**Document version:** 1.0.1  

**Related:** [RULES.md](../RULES.md) · [contracts.md](./contracts.md) · [security.md](./security.md)

---

## Summary

Keep packages composable at the workflow layer. Document intentional cross-stack boundaries. Prefer schema- and config-driven behavior over buried hard-coding.

---

## Contents

1. [Summary](#summary)
2. [Architecture rules](#architecture-rules)
3. [Document history](#document-history)

---

## Architecture rules

| Rule | Detail |
|------|--------|
| **Clear entry points** | Prefer documented CLI launchers, `__main__` modules, or public package APIs over ad-hoc scripts as the primary surface |
| **Composition** | Join packages at the **workflow** layer (files, CLI, messages), not by merging unrelated engines into one process unless that is an explicit design |
| **Runtime separation** | Do not call one stack from another in product code without an intentional, documented boundary |
| **Dependencies** | Declare the dependency policy in README and security docs (e.g. stdlib-only, locked set, or full package index). No hidden downloads or telemetry in product paths unless documented |
| **Domain hard-coding** | Prefer schema-, config-, or interface-driven behavior over hard-coded business field lists buried in engines |

Public automation surfaces (CLI, API, schema fields) must follow [contracts.md](./contracts.md) for co-updates and versioning.

### This repository (filled)

| Rule | Detail |
|------|--------|
| **Runtime separation** | Do **not** call Excel COM from Python product code. Do **not** implement priority/KPI math in PowerShell product code. |
| **Composition** | Join toolkits at the **workflow** layer (generate/score CSV → export XLSX), not by merging engines. Interactive composition may live in `excel-toolkit\Start-ExcelMenu.ps1` (subprocess `kpi-analytics.cmd`, then Excel export). |
| **Excel entry points** | Prefer `excel-toolkit.cmd` / `ExcelToolkit.ps1` (automation) or `Import-Module ExcelToolkit.psm1` (in-process). Treat `Export-WqDataToExcel.ps1` as a legacy forwarder. |
| **KPI entry points** | Prefer `kpi-analytics.cmd` or `python -m kpi_modules`. Keep `kpi_modules` importable without side effects beyond CLI `__main__`. |
| **Dependencies** | No pip packages, no download-and-run, no credential stores, no hidden telemetry in product paths. |
| **Excel lifecycle** | Close via Quit + controlled retry + user warning. **Never** force-kill `EXCEL.EXE` in toolkit code. |
| **Output collision** | Product writers **must not** clobber an existing destination by default. Prefer a free path with a numerical suffix (`name_1.ext`). Use explicit `-Force` (or documented equivalent) only when the caller intends to replace that exact path. |
| **Domain hard-coding** | Export layout is CSV/schema-driven. Avoid hard-coded business field lists in the Excel engine. |

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.1 | Project fill: Excel/Python runtime separation, entry points, output collision |
| 1.0.0 | Extracted from RULES 1.4.1 for kit 2.0; data/contract rules moved to contracts.md |
