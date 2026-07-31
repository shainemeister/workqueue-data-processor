---
title: File Catalog
description: Concise purpose inventory of every intentional source file in this repository.
version: "1.9.0"
status: current
audience:
  - developers
  - analysts
  - security
doc_type: other
related:
  - ../README.md
  - ../CHANGELOG.md
  - ../kit/MARKDOWN-STANDARD.md
  - ../kit/RULES.md
  - ../LICENSE
  - ../certification/README.md
  - PLAN.md
last_updated: "2026-07-30"
---

# File Catalog

Concise, path-level inventory of intentional source files in **workqueue-data-processor**. Use this when onboarding, reviewing layout, or deciding which entry point to call.

**Document version:** 1.9.0  
**Baseline layout:** scannable root + `wq_schema/` data contract + `kit/` standards + `docs/`  

**Related:** [README.md](../README.md) · [CHANGELOG.md](../CHANGELOG.md) · [kit/MARKDOWN-STANDARD.md](../kit/MARKDOWN-STANDARD.md) · [kit/RULES.md](../kit/RULES.md) · [PLAN.md](./PLAN.md)

---

## Summary

This repository holds a **Work Queue (WQ) data contract** under **`wq_schema/`**, two local toolkits (**excel-toolkit**: PowerShell 5.1 + Excel COM; **kpi-analytics**: Python 3.13 stdlib only), standards under **`kit/`**, and maintainer/design docs under **`docs/`**.

Each row below states **what the file is for** in one sentence. Runtime contracts live in toolkit READMEs and CLI guides; this catalog does not restate flags or formulas.

| Area | Preferred entry points |
|------|------------------------|
| Interactive Excel | `Start-ExcelMenu.cmd` (root or `excel-toolkit\`) |
| Excel automation CLI | `excel-toolkit\excel-toolkit.cmd` |
| KPI score / generate / validate / diagnostics | `kpi-analytics\kpi-analytics.cmd` |
| Markdown conventions | [kit/MARKDOWN-STANDARD.md](../kit/MARKDOWN-STANDARD.md) |
| Maintenance policy | [kit/RULES.md](../kit/RULES.md) |
| Project history | [CHANGELOG.md](../CHANGELOG.md) |
| Living development plan | [PLAN.md](./PLAN.md) |

Generated artifacts under `output\` and Python `__pycache__\` are intentionally **not** cataloged as source.

---

## Contents

1. [Summary](#summary)
2. [Repository layout](#repository-layout)
3. [Root](#root)
4. [wq_schema](#wq_schema)
5. [docs](#docs)
6. [kit](#kit)
7. [import](#import)
8. [excel-toolkit](#excel-toolkit)
9. [excel-toolkit/sample-test](#excel-toolkitsample-test)
10. [kpi-analytics](#kpi-analytics)
11. [kpi-analytics/kpi_modules](#kpi-analyticskpi_modules)
12. [kpi-analytics/profiles](#kpi-analyticsprofiles)
13. [kpi-analytics/diagnostics](#kpi-analyticsdiagnostics)
14. [kpi-analytics/fixtures](#kpi-analyticsfixtures)
15. [certification](#certification)
16. [Generated and ignored paths](#generated-and-ignored-paths)
17. [Document history](#document-history)

---

## Repository layout

```text
workqueue-data-processor/
  README.md, CHANGELOG.md, LICENSE, .gitignore
  Start-ExcelMenu.cmd
  wq_schema/              # shared WQ data contract (schema + sample)
  docs/                   # maintainer inventory, plan, design concepts
  kit/                    # repo-kit standards (RULES hub, rules modules, templates, UPGRADE)
  import/                 # tracked synthetic / non-PHI inputs only
  excel-toolkit/          # PowerShell Excel COM toolkit
  kpi-analytics/          # Python KPI + priority scoring
  certification/          # formal Domain A/B self-attestation (outputs gitignored)
  output/                 # generated only (gitignored)
```

---

## Root

| Path | Type | Summary |
|------|------|---------|
| [README.md](../README.md) | doc | Repository overview: WQ two-file data model, toolkit map, and synthetic → score → Excel flow. |
| [LICENSE](../LICENSE) | legal | MIT license for this repository. |
| [CHANGELOG.md](../CHANGELOG.md) | doc | Project history (Keep a Changelog); required by repo-kit. Kit version lives in kit/RULES kit baseline only. |
| [Start-ExcelMenu.cmd](../Start-ExcelMenu.cmd) | launcher | Root convenience shim; calls `excel-toolkit\Start-ExcelMenu.cmd`. |
| [.gitignore](../.gitignore) | config | Excludes `output\`, local numbered `import\` copies, mapping profiles, package diagnostics certs, formal `certification/last_certification.*` + logs, Python caches, env dirs, editor noise. |

---

## wq_schema

Shared **data contract** for both toolkits (not package-local). Product defaults for `--schema` / `--template-csv` and Excel schema lookup resolve here.

| Path | Type | Summary |
|------|------|---------|
| [wq_schema.json](../wq_schema/wq_schema.json) | data | Canonical field catalog (`field_name`, types, nullability, display names). |
| [wq_schema.csv](../wq_schema/wq_schema.csv) | data | Same schema as CSV for spreadsheet review and display-name mapping. |
| [wq_data.csv](../wq_schema/wq_data.csv) | data | Small sample WQ fact table; column headers use schema `field_name` values (also generate template). |

---

## docs

Maintainer and design documentation (not end-user product entry points).

| Path | Type | Summary |
|------|------|---------|
| [FILE-CATALOG.md](./FILE-CATALOG.md) | doc | This inventory: concise purpose of each intentional source file. |
| [PLAN.md](./PLAN.md) | doc | Living post-V1 plan (0.3.0): Cluster 1 CLI shipped (kpi 2.6.0); residual menu profile picker + optional base retune; Clusters 2–3 multi-file / analysis still developing. |
| [WQ_Priority_Matrix_Concept.md](./WQ_Priority_Matrix_Concept.md) | doc | Progressive V1–V3 priority-score design; V1 is the live implementation target. |

---

## kit

Standards from [repo-kit](https://github.com/shainemeister/repo-kit) **2.0.1** (project-filled). Product code stays outside this tree.

| Path | Type | Summary |
|------|------|---------|
| [RULES.md](../kit/RULES.md) | doc | Maintenance hub: authority map, kit baseline (**2.0.1**), Must/Must not, domain module index |
| [UPGRADE.md](../kit/UPGRADE.md) | doc | Durable upgrade procedure and 1.x → 2.x layout migration |
| [MARKDOWN-STANDARD.md](../kit/MARKDOWN-STANDARD.md) | doc | Markdown structure, frontmatter, platform-aware examples, author checklist |
| [rules/hygiene.md](../kit/rules/hygiene.md) | doc | Packaging: standards under `kit/`; product outside |
| [rules/authoring-and-style.md](../kit/rules/authoring-and-style.md) | doc | Docs rules; pylint; PowerShell style gates |
| [rules/architecture.md](../kit/rules/architecture.md) | doc | Runtime separation, entry points, composition |
| [rules/contracts.md](../kit/rules/contracts.md) | doc | Contract ownership, co-updates, data/schema rules |
| [rules/security.md](../kit/rules/security.md) | doc | Inventory, SAST, certification renewal enforcement |
| [rules/versioning-and-git.md](../kit/rules/versioning-and-git.md) | doc | Version surfaces, CHANGELOG, commits, AI disclosure |
| [rules/verification-and-ops.md](../kit/rules/verification-and-ops.md) | doc | Verification table, completion, checklist, anti-patterns |
| [configs/pylintrc](../kit/configs/pylintrc) | config | Kit starter pylint config (product gate uses `kpi-analytics/.pylintrc`) |
| [templates/](../kit/templates/) | template | Document skeletons (README, CLI, methodology, security, certification, concept, generic) |

---

## import

Tracked **input** files for scoring demos and local runs. Prefer synthetic or de-identified data only—**no real PHI** (`kit/RULES.md` / contracts). Scored results go under `output\` (gitignored). Local numbered copies (`wq_synthetic_data_1.csv`, etc.) and `*_mapping.json` are **gitignored**—do not force-add them.

| Path | Type | Summary |
|------|------|---------|
| [wq_synthetic_data.csv](../import/wq_synthetic_data.csv) | data | Synthetic professional-billing WQ extract (~250 rows); default `score` / `generate` path for kpi-analytics. |
| [wq_synthetic_data.xlsx](../import/wq_synthetic_data.xlsx) | data | Same synthetic rows as CSV, unprotected workbook for excel-toolkit `import-excel` demos. |
| [wq_synthetic_data_protected.xlsx](../import/wq_synthetic_data_protected.xlsx) | data | Same synthetic rows with workbook open password `SyntheticTest1` (known non-secret fixture password). |

---

## excel-toolkit

**Runtime:** Windows PowerShell 5.1 + desktop Microsoft Excel (COM).  
**Docs:** [excel-toolkit/README.md](../excel-toolkit/README.md) · [CLI-GUIDE.md](../excel-toolkit/CLI-GUIDE.md) · [ENTERPRISE-SECURITY.md](../excel-toolkit/ENTERPRISE-SECURITY.md)

| Path | Type | Summary |
|------|------|---------|
| [README.md](../excel-toolkit/README.md) | doc | Toolkit overview: menu, modules, CLI, prerequisites, and consumer notes. |
| [CLI-GUIDE.md](../excel-toolkit/CLI-GUIDE.md) | doc | CLI contract: verbs, exit codes, JSON shapes, and automation examples. |
| [ENTERPRISE-SECURITY.md](../excel-toolkit/ENTERPRISE-SECURITY.md) | doc | Trust boundary, disallowed patterns, and execution-policy guidance for COM automation. |
| [ExcelCom.psm1](../excel-toolkit/ExcelCom.psm1) | module | Low-level Excel COM lifecycle, range I/O, CSV sheet import/export, optional workbook passwords, and safe Quit (no force-kill). |
| [ExcelToolkit.psm1](../excel-toolkit/ExcelToolkit.psm1) | module | High-level API: version helpers, unique paths, export/import, and enterprise diagnostics gate (`Assert-ExcelToolkitDiagnosticsPass`, readiness suite). |
| [ExcelToolkit.ps1](../excel-toolkit/ExcelToolkit.ps1) | script | CLI entry: `version` / `probe` / `diagnostics` / `export-csv` / `import-excel` / `help` over `ExcelToolkit.psm1`. |
| [diagnostics/README.md](../excel-toolkit/diagnostics/README.md) | doc | Pass certificate + first-run gate; distinct from root `certification/` (json/txt gitignored). |
| [excel-toolkit.cmd](../excel-toolkit/excel-toolkit.cmd) | launcher | Windows shim: process-scoped `-ExecutionPolicy Bypass` → `ExcelToolkit.ps1`. |
| [Start-ExcelMenu.cmd](../excel-toolkit/Start-ExcelMenu.cmd) | launcher | Double-click launcher for the interactive menu (process-scoped Bypass only). |
| [Start-ExcelMenu.ps1](../excel-toolkit/Start-ExcelMenu.ps1) | script | Interactive menu: Process my data (unified CSV/Excel discovery, print-style ranges, pipeline/score/export, mapping preflight + guided column mapping via kpi-analytics TTY, optional export password) and Advanced tools; unique output paths (`name_N.ext`) by default. |
| [Export-CsvToExcel.ps1](../excel-toolkit/Export-CsvToExcel.ps1) | script | Thin menu/legacy wrapper around `Export-ExcelFromCsv` in the high-level module. |
| [Export-WqDataToExcel.ps1](../excel-toolkit/Export-WqDataToExcel.ps1) | script | Compatibility forwarder to `Export-CsvToExcel.ps1` (legacy entry name). |
| [Test-ExcelCom.ps1](../excel-toolkit/Test-ExcelCom.ps1) | script | Dry-run and full smoke tests for COM readiness and workbook operations. |

**Call preference:** automation → `excel-toolkit.cmd` / `ExcelToolkit.ps1`; in-process PowerShell → `Import-Module ExcelToolkit.psm1`; interactive → `Start-ExcelMenu.cmd`. Prefer new work on the CLI/module path over the legacy export script names.

---

## excel-toolkit/sample-test

Minimal probes for locked-down corporate PCs: can `.cmd`, `.ps1`, and `.psm1` execute at all?

| Path | Type | Summary |
|------|------|---------|
| [README.md](../excel-toolkit/sample-test/README.md) | doc | Hand-typeable probe instructions and expected OK/FAIL outcomes. |
| [SampleTools.psm1](../excel-toolkit/sample-test/SampleTools.psm1) | module | Tiny module exporting `Get-SampleModulePing` for import checks. |
| [Test-CanRun.cmd](../excel-toolkit/sample-test/Test-CanRun.cmd) | launcher | Double-click entry that runs `Test-CanRun.ps1` under process-scoped Bypass. |
| [Test-CanRun.ps1](../excel-toolkit/sample-test/Test-CanRun.ps1) | script | Verifies basic PowerShell script execution from a `.cmd` host. |
| [Test-Psm1.cmd](../excel-toolkit/sample-test/Test-Psm1.cmd) | launcher | Double-click entry for the module-import probe. |
| [Test-Psm1.ps1](../excel-toolkit/sample-test/Test-Psm1.ps1) | script | Imports `SampleTools.psm1` and asserts the ping export returns `PING_OK`. |
| [Test-Env.cmd](../excel-toolkit/sample-test/Test-Env.cmd) | launcher | Double-click entry for the enterprise environment checks. |
| [Test-Env.ps1](../excel-toolkit/sample-test/Test-Env.ps1) | script | Reports LanguageMode, process policy, module load, Excel COM, and temp write. |
| [Test-SelectionRange.ps1](../excel-toolkit/sample-test/Test-SelectionRange.ps1) | script | Dev smoke test: parse `Start-ExcelMenu.ps1` and unit-check print-style selection ranges. |

---

## kpi-analytics

**Runtime:** Python **3.13** standard library only (no pip packages).  
**Docs:** [kpi-analytics/README.md](../kpi-analytics/README.md) · [CLI-GUIDE.md](../kpi-analytics/CLI-GUIDE.md) · [SCORE-METHODOLOGY.md](../kpi-analytics/SCORE-METHODOLOGY.md)

| Path | Type | Summary |
|------|------|---------|
| [README.md](../kpi-analytics/README.md) | doc | Package overview: score / generate / validate workflow, layout, and consumption notes. |
| [CLI-GUIDE.md](../kpi-analytics/CLI-GUIDE.md) | doc | CLI contract for `kpi-analytics.cmd` and `python -m kpi_modules`. |
| [ENTERPRISE-SECURITY.md](../kpi-analytics/ENTERPRISE-SECURITY.md) | doc | Offline stdlib-only trust model; no Office automation, network, or third-party deps. |
| [SCORE-METHODOLOGY.md](../kpi-analytics/SCORE-METHODOLOGY.md) | doc | Implementation methodology: V1 priority columns, `kpi_q_*` impacts, and summary CSV. |
| [RCM_KPI_Claim_Impact_Methodology.md](../kpi-analytics/RCM_KPI_Claim_Impact_Methodology.md) | doc | Dual-attribution theory for Days in AR and aging-percentage claim impacts. |
| [kpi-analytics.cmd](../kpi-analytics/kpi_analytics.cmd) | launcher | Shim: prefer `py -3.13 -m kpi_modules`, else `python -m kpi_modules`. |
| [.pylintrc](../kpi-analytics/.pylintrc) | config | **Dev tooling only** — PEP-8 style gate for `kpi_modules` (not a product runtime dependency). |

---

## kpi-analytics/kpi_modules

Python package implementing scoring, RCM quantifiers, synthesis, diagnostics, and CLI.

| Path | Type | Summary |
|------|------|---------|
| [__init__.py](../kpi-analytics/kpi_modules/__init__.py) | module | Package identity and `__version__` (currently 2.6.0). |
| [__main__.py](../kpi-analytics/kpi_modules/__main__.py) | module | Enables `python -m kpi_modules`; delegates to CLI `main()`. |
| [cli.py](../kpi-analytics/kpi_modules/cli.py) | module | Argparse CLI: `version`, `probe`, `diagnostics`, `score` (incl. `--profile`, `--interactive-mapping`, `--strict`), `generate`, `validate-score`, `profile-list` / `profile-show` / `profile-save`; diagnostics gate on operational score/generate/validate. |
| [column_map.py](../kpi-analytics/kpi_modules/column_map.py) | module | Role-based CSV header resolution, alias auto-detect, sample verification, guided mapping, mapping profile JSON, availability-aware metric set. |
| [completeness.py](../kpi-analytics/kpi_modules/completeness.py) | module | Rank completeness evaluation (`RankCompleteness`, strict roles/full tiers) for score JSON and CLI `--strict`. |
| [diagnostics.py](../kpi-analytics/kpi_modules/diagnostics.py) | module | Enterprise runtime/import dry-run, durable pass/fail report, operational gate helpers. |
| [config.py](../kpi-analytics/kpi_modules/config.py) | module | Loads and validates JSON config; resolves healthy vs chaos weight sets (optional active-metric renorm). |
| [config_default.json](../kpi-analytics/kpi_modules/config_default.json) | config | Default field maps, weights, thresholds, and KPI quantifier settings. |
| [profiles.py](../kpi-analytics/kpi_modules/profiles.py) | module | Scoring profile envelope, deep-merge onto package default, path resolve, list/show/save helpers. |
| [io_csv.py](../kpi-analytics/kpi_modules/io_csv.py) | module | Stdlib CSV read/write helpers shared by score and generate paths. |
| [metrics.py](../kpi-analytics/kpi_modules/metrics.py) | module | Raw priority metrics (claim age, BWDO, denial count, dual-deadline, balances, appeal, WQ age); date parse including Excel serials. |
| [normalize.py](../kpi-analytics/kpi_modules/normalize.py) | module | Normalizes raw metrics to [0, 1] via minmax or percentile ranks. |
| [privacy.py](../kpi-analytics/kpi_modules/privacy.py) | module | Score-output PHI masking for patient name / DOB (header aliases; prefix+4-digit token by default; configurable omit). |
| [score_v1.py](../kpi-analytics/kpi_modules/score_v1.py) | module | Orchestrates metrics → queue mode → weights → norms → contributions → final score; accepts pre-merged config and mapping roles. |
| [kpi_quantifiers.py](../kpi-analytics/kpi_modules/kpi_quantifiers.py) | module | Portfolio KPIs plus per-claim static share and resolution-delta (`kpi_q_*`) columns. |
| [summary_report.py](../kpi-analytics/kpi_modules/summary_report.py) | module | Builds the vertical summary CSV (metric rows with values, formulas, explanations). |
| [synthesize.py](../kpi-analytics/kpi_modules/synthesize.py) | module | Generates synthetic professional-billing WQ rows for demos and local tests. |
| [probe.py](../kpi-analytics/kpi_modules/probe.py) | module | Optional path preflight (Python version, imports, optional CSV paths); does not satisfy gate. |
| [validate_score.py](../kpi-analytics/kpi_modules/validate_score.py) | module | Integrity checks on scores/KPI Q plus optional golden-fixture comparison. |

---

## kpi-analytics/profiles

Shipped POI focus presets and optional operator-saved scoring profiles. User files `user_*.json` are gitignored.

| Path | Type | Summary |
|------|------|---------|
| [poi_protect_writeoffs.json](../kpi-analytics/profiles/poi_protect_writeoffs.json) | config | Focus preset: aging / deadline urgency POI multipliers. |
| [poi_maximize_cash.json](../kpi-analytics/profiles/poi_maximize_cash.json) | config | Focus preset: dollars / BWDO POI multipliers. |
| [poi_suppress_aging.json](../kpi-analytics/profiles/poi_suppress_aging.json) | config | Focus preset: stall / denial emphasis; mild age downweight. |

---

## kpi-analytics/diagnostics

Enterprise dry-run certificate folder. Generated reports are gitignored.

| Path | Type | Summary |
|------|------|---------|
| [README.md](../kpi-analytics/diagnostics/README.md) | doc | Certificate purpose, privacy, re-run; distinct from root `certification/`. |
| `last_diagnostics.json` | generated | Machine-readable pass certificate (gate reads this; not tracked). |
| `last_diagnostics.txt` | generated | Human PASS/FAIL listing for IT (not tracked). |

---

## kpi-analytics/fixtures

Small golden inputs used by `validate-score` and hand-check documentation.

| Path | Type | Summary |
|------|------|---------|
| [excel_serial_dates_input.csv](../kpi-analytics/fixtures/excel_serial_dates_input.csv) | fixture | Sample rows with Excel serial `service_date` / `last_worked_date` (regression for date parse 2.2.0). |
| [v1_handcalc_input.csv](../kpi-analytics/fixtures/v1_handcalc_input.csv) | fixture | Tiny claim set sized for hand-calculable priority scoring. |
| [v1_handcalc_config.json](../kpi-analytics/fixtures/v1_handcalc_config.json) | fixture | Config binding fields/weights for the V1 handcalc case. |
| [v1_handcalc_expected.json](../kpi-analytics/fixtures/v1_handcalc_expected.json) | fixture | Golden expected priority outputs for the handcalc case. |
| [rcm_impact_example.csv](../kpi-analytics/fixtures/rcm_impact_example.csv) | fixture | Small claim set for RCM dual-attribution checks. |
| [rcm_impact_config.json](../kpi-analytics/fixtures/rcm_impact_config.json) | fixture | Config for the RCM impact fixture run. |
| [rcm_impact_expected.json](../kpi-analytics/fixtures/rcm_impact_expected.json) | fixture | Golden expected portfolio totals and claim-level KPI Q values. |

---

## certification

Formal **security + code-validation** self-attestation package (developer-only). Not package diagnostics. Operational commands live here; renewal policy is in [kit/rules/security.md](../kit/rules/security.md).

| Path | Type | Summary |
|------|------|---------|
| [README.md](../certification/README.md) | doc | Operator guide: surfaces, dual-mode Gitleaks, product-only PSSA, schema fields, advisory password Warning note |
| [checks.json](../certification/checks.json) | config | Declarative required Domain A/B checks (pylint 10.00, Bandit, PSSA Error, dual Gitleaks, validate-score handcalc + **validate-score-rcm**) |
| [Invoke-Certification.ps1](../certification/Invoke-Certification.ps1) | script | Full-suite harness; root via `kit\RULES.md`; `PackageVersions`/`DurationMs`/`Message`; exit 0 iff OverallPass |

---

## Generated and ignored paths

These paths are produced at runtime or by the interpreter. They are listed for orientation only and are excluded from git via `.gitignore`.

| Path | Note |
|------|------|
| `output\` | Scored CSVs, summary CSVs, and Excel workbooks from toolkit runs (not tracked inputs). |
| `import\wq_synthetic_data_N.*` / `import\*_mapping.json` | Local operator copies / mapping profiles (gitignored; not catalog source). |
| `kpi-analytics\profiles\user_*.json` | User-created scoring profiles (gitignored; shipped presets may be tracked later). |
| `kpi-analytics\diagnostics\last_diagnostics.*` | Regenerable package diagnostics certificates. |
| `excel-toolkit\diagnostics\last_diagnostics.*` | Regenerable package diagnostics certificates. |
| `certification\last_certification.*` | Regenerable formal security + code-validation certs (not package diagnostics). |
| `certification\logs\` | Optional tool reports from the certification harness (e.g. gitleaks JSON). |
| `**/__pycache__\` / `*.pyc` | Python bytecode cache under `kpi_modules` and elsewhere. |
| `.venv\` / `venv\` | Local virtual environments if created (not required; stdlib-only runtime). |

To regenerate typical demo artifacts:

```bat
cd kpi-analytics
kpi-analytics.cmd score --output ..\output\wq_scored.csv
rem optional refresh of tracked input: generate (defaults to import\wq_synthetic_data.csv)
cd ..\excel-toolkit
excel-toolkit.cmd export-csv -CsvPath ..\output\wq_scored.csv -OutputPath ..\output\wq_scored.xlsx
rem optional: rebuild synthetic Excel fixtures under import\
excel-toolkit.cmd export-csv -CsvPath ..\import\wq_synthetic_data.csv -OutputPath ..\import\wq_synthetic_data.xlsx -Force
excel-toolkit.cmd export-csv -CsvPath ..\import\wq_synthetic_data.csv -OutputPath ..\import\wq_synthetic_data_protected.xlsx -Password SyntheticTest1 -Force
excel-toolkit.cmd import-excel -ExcelPath ..\import\wq_synthetic_data.xlsx -OutputPath ..\import\from_xlsx_smoke.csv
rem Existing destinations require -Force to overwrite
```

---

## Document history

| Version | Notes |
|---------|--------|
| 1.9.0 | kpi-analytics 2.6.0: `profiles.py`, shipped `profiles/poi_*.json` focus presets; CLI profile verbs; PLAN blurb updated for 0.3.0 backlog status |
| 1.8.6 | Data contract moved to `wq_schema/` (`wq_schema.json`, `wq_schema.csv`, `wq_data.csv`); root no longer holds schema/sample CSVs |
| 1.8.5 | Root cleanup: `PLAN.md`, `FILE-CATALOG.md`, and concept doc under `docs/`; root keeps data contract + entry shim only among product docs |
| 1.8.4 | repo-kit **2.0.1**: standards under `kit/`; catalog hub + rules modules + templates; root RULES/MARKDOWN/templates removed |
| 1.0.0 | Initial path-level inventory for root, excel-toolkit, kpi-analytics, fixtures, and templates |
| 1.1.0 | `diagnostics.py`, `diagnostics/` folder, toolkit version 1.6.0 gate certificate |
| 1.1.1 | `privacy.py` score-output PHI masking; toolkit version 1.7.0 |
| 1.1.2 | `import\` tracked inputs; default score/generate paths; toolkit 1.8.0 |
| 1.1.3 | Synthetic import `.xlsx` fixtures; excel-toolkit 1.2.0 `import-excel` |
| 1.3.0 | `column_map.py` role mapping; kpi-analytics 1.9.0; PLAN.md living plan already cataloged |
| 1.3.1 | Removed root `PLAN.md` after R1–R3 shipped (history remains in CHANGELOG / git) |
| 1.4.0 | excel-toolkit 1.6.0 guided Process my data menu; re-catalog PLAN.md; `Test-SelectionRange.ps1` |
| 1.4.1 | Removed root `PLAN.md` after 1.4.0 / excel-toolkit 1.6.0 menu work shipped (history remains in CHANGELOG / git) |
| 1.5.0 | kpi-analytics 2.1.0 mapping verification + guided mapping; PLAN.md for dynamic schema adaptation marked implemented |
| 1.5.1 | Removed root `PLAN.md` after 1.5.0 / kpi-analytics 2.1.0 mapping work shipped (history remains in CHANGELOG / git) |
| 1.5.2 | repo-kit baseline **1.1.7** (RULES security modularity + SAST; TEMPLATE-SECURITY modularity notes; no path add/remove) |
| 1.5.3 | repo-kit baseline **1.2.0**: TEMPLATE-CERTIFICATION-README; RULES inventory/certification; `.gitignore` formal cert outputs; Gitleaks opt-in; kit reflection notes |
| 1.6.0 | `certification/` package (README, checks.json, Invoke-Certification.ps1); Secrets/Gitleaks declared; RULES renewal enforcement |
| 1.6.1 | Root MIT LICENSE; certification hardening (product-only PSSA, dual Gitleaks, declarative pylint score, cert schema polish) |
| 1.6.2 | Re-added root `PLAN.md` (post-V1 enhancement concepts, draft) |
| 1.7.0 | excel-toolkit 1.7.0 menu mapping preflight + guided column mapping (Start-ExcelMenu.ps1) |
| 1.7.2 | kpi-analytics 2.2.0 Excel serial date parse; fixture `excel_serial_dates_input.csv` |
| 1.8.3 | RULES hygiene: catalog kit baseline 1.2.1; gitignore local import copies/mapping/user profiles; certification layout + RCM check; cli --strict note |
| 1.1.4 | excel-toolkit 1.3.0: unique output paths; menu Score→Excel (kpi-analytics composition) |
| 1.1.5 | excel-toolkit 1.4.0: diagnostics gate + `diagnostics\` certificate folder |
| 1.2.0 | Root `CHANGELOG.md`; repo-kit 1.1.1 baseline (RULES kit baseline, MARKDOWN platform-aware examples, templates sync) |
| 1.2.1 | Added root `PLAN.md` (development plan for dynamic mapping, aging terminology, new metrics, menu simplification) |
