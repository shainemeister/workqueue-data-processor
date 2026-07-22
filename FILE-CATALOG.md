---
title: File Catalog
description: Concise purpose inventory of every intentional source file in this repository.
version: "1.1.0"
status: current
audience:
  - developers
  - analysts
  - security
doc_type: other
related:
  - README.md
  - MARKDOWN-STANDARD.md
  - RULES.md
last_updated: "2026-07-22"
---

# File Catalog

Concise, path-level inventory of intentional source files in **workqueue-data-processor**. Use this when onboarding, reviewing layout, or deciding which entry point to call.

**Document version:** 1.1.0  
**Baseline layout:** repository root  

**Related:** [README.md](./README.md) · [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md) · [RULES.md](./RULES.md)

---

## Summary

This repository holds a **Work Queue (WQ) data contract** (schema + CSV), two local toolkits (**excel-toolkit**: PowerShell 5.1 + Excel COM; **kpi-analytics**: Python 3.13 stdlib only), design/methodology docs, and markdown templates.

Each row below states **what the file is for** in one sentence. Runtime contracts live in toolkit READMEs and CLI guides; this catalog does not restate flags or formulas.

| Area | Preferred entry points |
|------|------------------------|
| Interactive Excel | `Start-ExcelMenu.cmd` (root or `excel-toolkit\`) |
| Excel automation CLI | `excel-toolkit\excel-toolkit.cmd` |
| KPI score / generate / validate / diagnostics | `kpi-analytics\kpi-analytics.cmd` |
| Markdown conventions | [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md) |
| Maintenance policy | [RULES.md](./RULES.md) |

Generated artifacts under `output\` and Python `__pycache__\` are intentionally **not** cataloged as source.

---

## Contents

1. [Summary](#summary)
2. [Repository layout](#repository-layout)
3. [Root](#root)
4. [excel-toolkit](#excel-toolkit)
5. [excel-toolkit/sample-test](#excel-toolkitsample-test)
6. [kpi-analytics](#kpi-analytics)
7. [kpi-analytics/kpi_modules](#kpi-analyticskpi_modules)
8. [kpi-analytics/diagnostics](#kpi-analyticsdiagnostics)
9. [kpi-analytics/fixtures](#kpi-analyticsfixtures)
10. [templates](#templates)
11. [Generated and ignored paths](#generated-and-ignored-paths)
12. [Document history](#document-history)

---

## Repository layout

```text
workqueue-data-processor/
  README.md, FILE-CATALOG.md, MARKDOWN-STANDARD.md, RULES.md
  wq_schema.json, wq_schema.csv, wq_data.csv
  WQ_Priority_Matrix_Concept.md
  Start-ExcelMenu.cmd
  excel-toolkit/          # PowerShell Excel COM toolkit
  kpi-analytics/          # Python KPI + priority scoring
  templates/              # Markdown document skeletons
  output/                 # generated only (gitignored)
```

---

## Root

| Path | Type | Summary |
|------|------|---------|
| [README.md](./README.md) | doc | Repository overview: WQ two-file data model, toolkit map, and synthetic → score → Excel flow. |
| [FILE-CATALOG.md](./FILE-CATALOG.md) | doc | This inventory: concise purpose of each intentional source file. |
| [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md) | doc | Repo-wide markdown structure, frontmatter fields, and author checklist. |
| [RULES.md](./RULES.md) | doc | Maintenance rules: authority map, formatting, architecture, data, git, and verification. |
| [Start-ExcelMenu.cmd](./Start-ExcelMenu.cmd) | launcher | Root convenience shim; calls `excel-toolkit\Start-ExcelMenu.cmd`. |
| [wq_schema.json](./wq_schema.json) | data | Canonical field catalog (`field_name`, types, nullability, display names). |
| [wq_schema.csv](./wq_schema.csv) | data | Same schema as CSV for spreadsheet review and display-name mapping. |
| [wq_data.csv](./wq_data.csv) | data | Sample WQ fact table; column headers use schema `field_name` values. |
| [WQ_Priority_Matrix_Concept.md](./WQ_Priority_Matrix_Concept.md) | doc | Progressive V1–V3 priority-score design; V1 is the live implementation target. |
| [.gitignore](./.gitignore) | config | Excludes `output\`, Python caches, local env dirs, and common editor noise. |

---

## excel-toolkit

**Runtime:** Windows PowerShell 5.1 + desktop Microsoft Excel (COM).  
**Docs:** [excel-toolkit/README.md](./excel-toolkit/README.md) · [CLI-GUIDE.md](./excel-toolkit/CLI-GUIDE.md) · [ENTERPRISE-SECURITY.md](./excel-toolkit/ENTERPRISE-SECURITY.md)

| Path | Type | Summary |
|------|------|---------|
| [README.md](./excel-toolkit/README.md) | doc | Toolkit overview: menu, modules, CLI, prerequisites, and consumer notes. |
| [CLI-GUIDE.md](./excel-toolkit/CLI-GUIDE.md) | doc | CLI contract: verbs, exit codes, JSON shapes, and automation examples. |
| [ENTERPRISE-SECURITY.md](./excel-toolkit/ENTERPRISE-SECURITY.md) | doc | Trust boundary, disallowed patterns, and execution-policy guidance for COM automation. |
| [ExcelCom.psm1](./excel-toolkit/ExcelCom.psm1) | module | Low-level Excel COM lifecycle, range I/O, CSV sheet import, and safe Quit (no force-kill). |
| [ExcelToolkit.psm1](./excel-toolkit/ExcelToolkit.psm1) | module | High-level API: version helpers, schema header maps, and `Export-ExcelFromCsv`. |
| [ExcelToolkit.ps1](./excel-toolkit/ExcelToolkit.ps1) | script | CLI entry: `version` / `probe` / `export-csv` / `help` over `ExcelToolkit.psm1`. |
| [excel-toolkit.cmd](./excel-toolkit/excel-toolkit.cmd) | launcher | Windows shim: process-scoped `-ExecutionPolicy Bypass` → `ExcelToolkit.ps1`. |
| [Start-ExcelMenu.cmd](./excel-toolkit/Start-ExcelMenu.cmd) | launcher | Double-click launcher for the interactive menu (process-scoped Bypass only). |
| [Start-ExcelMenu.ps1](./excel-toolkit/Start-ExcelMenu.ps1) | script | Interactive menu for export and self-tests; column layout driven by CSV/schema, not hard-coded domain lists. |
| [Export-CsvToExcel.ps1](./excel-toolkit/Export-CsvToExcel.ps1) | script | Thin menu/legacy wrapper around `Export-ExcelFromCsv` in the high-level module. |
| [Export-WqDataToExcel.ps1](./excel-toolkit/Export-WqDataToExcel.ps1) | script | Compatibility forwarder to `Export-CsvToExcel.ps1` (legacy entry name). |
| [Test-ExcelCom.ps1](./excel-toolkit/Test-ExcelCom.ps1) | script | Dry-run and full smoke tests for COM readiness and workbook operations. |

**Call preference:** automation → `excel-toolkit.cmd` / `ExcelToolkit.ps1`; in-process PowerShell → `Import-Module ExcelToolkit.psm1`; interactive → `Start-ExcelMenu.cmd`. Prefer new work on the CLI/module path over the legacy export script names.

---

## excel-toolkit/sample-test

Minimal probes for locked-down corporate PCs: can `.cmd`, `.ps1`, and `.psm1` execute at all?

| Path | Type | Summary |
|------|------|---------|
| [README.md](./excel-toolkit/sample-test/README.md) | doc | Hand-typeable probe instructions and expected OK/FAIL outcomes. |
| [SampleTools.psm1](./excel-toolkit/sample-test/SampleTools.psm1) | module | Tiny module exporting `Get-SampleModulePing` for import checks. |
| [Test-CanRun.cmd](./excel-toolkit/sample-test/Test-CanRun.cmd) | launcher | Double-click entry that runs `Test-CanRun.ps1` under process-scoped Bypass. |
| [Test-CanRun.ps1](./excel-toolkit/sample-test/Test-CanRun.ps1) | script | Verifies basic PowerShell script execution from a `.cmd` host. |
| [Test-Psm1.cmd](./excel-toolkit/sample-test/Test-Psm1.cmd) | launcher | Double-click entry for the module-import probe. |
| [Test-Psm1.ps1](./excel-toolkit/sample-test/Test-Psm1.ps1) | script | Imports `SampleTools.psm1` and asserts the ping export returns `PING_OK`. |
| [Test-Env.cmd](./excel-toolkit/sample-test/Test-Env.cmd) | launcher | Double-click entry for enterprise environment checks. |
| [Test-Env.ps1](./excel-toolkit/sample-test/Test-Env.ps1) | script | Reports LanguageMode, process policy, module load, Excel COM, and temp write. |

---

## kpi-analytics

**Runtime:** Python **3.13** standard library only (no pip packages).  
**Docs:** [kpi-analytics/README.md](./kpi-analytics/README.md) · [CLI-GUIDE.md](./kpi-analytics/CLI-GUIDE.md) · [SCORE-METHODOLOGY.md](./kpi-analytics/SCORE-METHODOLOGY.md)

| Path | Type | Summary |
|------|------|---------|
| [README.md](./kpi-analytics/README.md) | doc | Package overview: score / generate / validate workflow, layout, and consumption notes. |
| [CLI-GUIDE.md](./kpi-analytics/CLI-GUIDE.md) | doc | CLI contract for `kpi-analytics.cmd` and `python -m kpi_modules`. |
| [ENTERPRISE-SECURITY.md](./kpi-analytics/ENTERPRISE-SECURITY.md) | doc | Offline stdlib-only trust model; no Office automation, network, or third-party deps. |
| [SCORE-METHODOLOGY.md](./kpi-analytics/SCORE-METHODOLOGY.md) | doc | Implementation methodology: V1 priority columns, `kpi_q_*` impacts, and summary CSV. |
| [RCM_KPI_Claim_Impact_Methodology.md](./kpi-analytics/RCM_KPI_Claim_Impact_Methodology.md) | doc | Dual-attribution theory for Days in AR and aging-percentage claim impacts. |
| [kpi-analytics.cmd](./kpi-analytics/kpi-analytics.cmd) | launcher | Shim: prefer `py -3.13 -m kpi_modules`, else `python -m kpi_modules`. |

---

## kpi-analytics/kpi_modules

Python package implementing scoring, RCM quantifiers, synthesis, diagnostics, and CLI.

| Path | Type | Summary |
|------|------|---------|
| [__init__.py](./kpi-analytics/kpi_modules/__init__.py) | module | Package identity and `__version__` (currently 1.6.0). |
| [__main__.py](./kpi-analytics/kpi_modules/__main__.py) | module | Enables `python -m kpi_modules`; delegates to CLI `main()`. |
| [cli.py](./kpi-analytics/kpi_modules/cli.py) | module | Argparse CLI: `version`, `probe`, `diagnostics`, `score`, `generate`, `validate-score`; diagnostics gate. |
| [diagnostics.py](./kpi-analytics/kpi_modules/diagnostics.py) | module | Enterprise runtime/import dry-run, durable pass/fail report, operational gate helpers. |
| [config.py](./kpi-analytics/kpi_modules/config.py) | module | Loads and validates JSON config; resolves healthy vs chaos weight sets. |
| [config_default.json](./kpi-analytics/kpi_modules/config_default.json) | config | Default field maps, weights, thresholds, and KPI quantifier settings. |
| [io_csv.py](./kpi-analytics/kpi_modules/io_csv.py) | module | Stdlib CSV read/write helpers shared by score and generate paths. |
| [metrics.py](./kpi-analytics/kpi_modules/metrics.py) | module | Raw Priority Matrix V1 metrics (AR days, disparity, balances, appeal urgency, WQ age). |
| [normalize.py](./kpi-analytics/kpi_modules/normalize.py) | module | Normalizes raw metrics to [0, 1] via minmax or percentile ranks. |
| [score_v1.py](./kpi-analytics/kpi_modules/score_v1.py) | module | Orchestrates metrics → queue mode → weights → norms → contributions → final score. |
| [kpi_quantifiers.py](./kpi-analytics/kpi_modules/kpi_quantifiers.py) | module | Portfolio KPIs plus per-claim static share and resolution-delta (`kpi_q_*`) columns. |
| [summary_report.py](./kpi-analytics/kpi_modules/summary_report.py) | module | Builds the vertical summary CSV (metric rows with values, formulas, explanations). |
| [synthesize.py](./kpi-analytics/kpi_modules/synthesize.py) | module | Generates synthetic professional-billing WQ rows for demos and local tests. |
| [probe.py](./kpi-analytics/kpi_modules/probe.py) | module | Optional path preflight (Python version, imports, optional CSV paths); does not satisfy gate. |
| [validate_score.py](./kpi-analytics/kpi_modules/validate_score.py) | module | Integrity checks on scores/KPI Q plus optional golden-fixture comparison. |

---

## kpi-analytics/diagnostics

Enterprise dry-run certificate folder. Generated reports are gitignored.

| Path | Type | Summary |
|------|------|---------|
| [README.md](./kpi-analytics/diagnostics/README.md) | doc | Explains certificate purpose, privacy, and re-run commands. |
| `last_diagnostics.json` | generated | Machine-readable pass certificate (gate reads this; not tracked). |
| `last_diagnostics.txt` | generated | Human PASS/FAIL listing for IT (not tracked). |

---

## kpi-analytics/fixtures

Small golden inputs used by `validate-score` and hand-check documentation.

| Path | Type | Summary |
|------|------|---------|
| [v1_handcalc_input.csv](./kpi-analytics/fixtures/v1_handcalc_input.csv) | fixture | Tiny claim set sized for hand-calculable priority scoring. |
| [v1_handcalc_config.json](./kpi-analytics/fixtures/v1_handcalc_config.json) | fixture | Config binding fields/weights for the V1 handcalc case. |
| [v1_handcalc_expected.json](./kpi-analytics/fixtures/v1_handcalc_expected.json) | fixture | Golden expected priority outputs for the handcalc case. |
| [rcm_impact_example.csv](./kpi-analytics/fixtures/rcm_impact_example.csv) | fixture | Small claim set for RCM dual-attribution checks. |
| [rcm_impact_config.json](./kpi-analytics/fixtures/rcm_impact_config.json) | fixture | Config for the RCM impact fixture run. |
| [rcm_impact_expected.json](./kpi-analytics/fixtures/rcm_impact_expected.json) | fixture | Golden expected portfolio totals and claim-level KPI Q values. |

---

## templates

Copy-paste skeletons aligned with [MARKDOWN-STANDARD.md](./MARKDOWN-STANDARD.md). Replace `{{PLACEHOLDERS}}`; delete unused sections.

| Path | Type | Summary |
|------|------|---------|
| [TEMPLATE-README.md](./templates/TEMPLATE-README.md) | template | Skeleton for product/toolkit README (`doc_type: readme`). |
| [TEMPLATE-CLI.md](./templates/TEMPLATE-CLI.md) | template | Skeleton for CLI reference (`doc_type: cli`). |
| [TEMPLATE-METHODOLOGY.md](./templates/TEMPLATE-METHODOLOGY.md) | template | Skeleton for formula / how-it-works methodology docs. |
| [TEMPLATE-SECURITY.md](./templates/TEMPLATE-SECURITY.md) | template | Skeleton for enterprise security and execution notes. |
| [TEMPLATE-CONCEPT.md](./templates/TEMPLATE-CONCEPT.md) | template | Skeleton for progressive or multi-version design concepts. |
| [TEMPLATE-GENERIC.md](./templates/TEMPLATE-GENERIC.md) | template | Minimal generic document skeleton (`doc_type: other`). |

---

## Generated and ignored paths

These paths are produced at runtime or by the interpreter. They are listed for orientation only and are excluded from git via `.gitignore`.

| Path | Note |
|------|------|
| `output\` | Scored CSVs, summary CSVs, synthetic data, and Excel workbooks from toolkit runs. |
| `kpi-analytics\diagnostics\last_diagnostics.*` | Regenerable enterprise diagnostics certificates. |
| `**/__pycache__\` / `*.pyc` | Python bytecode cache under `kpi_modules` and elsewhere. |
| `.venv\` / `venv\` | Local virtual environments if created (not required; stdlib-only runtime). |

To regenerate typical demo artifacts:

```bat
cd kpi-analytics
kpi-analytics.cmd generate --rows 100 --output ..\output\wq_data_synthetic.csv
kpi-analytics.cmd score --csv ..\output\wq_data_synthetic.csv --output ..\output\wq_scored.csv
cd ..\excel-toolkit
excel-toolkit.cmd export-csv -CsvPath ..\output\wq_scored.csv -OutputPath ..\output\wq_scored.xlsx
```

---

## Document history

| Version | Notes |
|---------|--------|
| 1.0.0 | Initial path-level inventory for root, excel-toolkit, kpi-analytics, fixtures, and templates |
| 1.1.0 | `diagnostics.py`, `diagnostics/` folder, toolkit version 1.6.0 gate certificate |
