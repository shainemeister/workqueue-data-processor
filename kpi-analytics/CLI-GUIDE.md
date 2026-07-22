---
title: KPI Analytics CLI Reference
description: Command-line syntax, exit codes, JSON shapes, and automation examples for kpi-analytics.
version: "1.8.0"
status: current
audience:
  - developers
  - automation
doc_type: cli
related:
  - README.md
  - SCORE-METHODOLOGY.md
  - RCM_KPI_Claim_Impact_Methodology.md
  - ENTERPRISE-SECURITY.md
last_updated: "2026-07-22"
---

# KPI Analytics — CLI Reference

Professional reference for the command-line interface used by automation, Task Scheduler, cmd, and other processes.

**Toolkit version:** 1.8.0 (`version` command / `kpi_modules.__version__`)

**Related docs:** [README.md](./README.md) · [SCORE-METHODOLOGY.md](./SCORE-METHODOLOGY.md) · [RCM_KPI_Claim_Impact_Methodology.md](./RCM_KPI_Claim_Impact_Methodology.md) · [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md)

| Item | Value |
|------|--------|
| **Toolkit folder** | `kpi-analytics\` |
| **CLI module** | `python -m kpi_modules` |
| **Windows shim** | `kpi-analytics.cmd` |
| **Library** | `kpi_modules` (`score_v1`, `kpi_quantifiers`, `summary_report`, `synthesize`, `diagnostics`, …) |

## Summary

This guide is the authoritative **command-line contract** for KPI Analytics. It documents how to invoke `kpi-analytics.cmd` / `python -m kpi_modules`, each verb (`version`, `probe`, `diagnostics`, `score`, `generate`, `validate-score`), flags (`--json`, `--quiet`, diagnostics gate options), exit codes (**0** / **1** / **2**), and illustrative JSON shapes for automation.

| Command | Produces |
|---------|----------|
| `diagnostics` | Enterprise dry-run report under `diagnostics\last_diagnostics.json` / `.txt` (gate certificate) |
| `score` | Claim-level scored CSV (`v1_*` + `kpi_q_*`; patient/DOB masked by default) and optional vertical **summary** CSV |
| `generate` | Synthetic professional-billing WQ CSV (de-identified) |
| `validate-score` | Integrity checks on priority contributions and KPI Q checksums (optional golden fixtures) |
| `probe` | Optional path preflight (does **not** satisfy the diagnostics gate) |

Use **Import-Module-style** Python APIs when already in-process; use this CLI for Task Scheduler, cmd, and cross-language orchestration. Security constraints are summarized in [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md); scoring math is in [SCORE-METHODOLOGY.md](./SCORE-METHODOLOGY.md).

---

## Contents

1. [Summary](#summary)
2. [Architecture](#architecture)
3. [When to use the CLI vs the package](#1-when-to-use-the-cli-vs-the-package)
4. [Invocation](#2-invocation)
5. [Exit codes](#3-exit-codes)
6. [Global options](#4-global-options)
7. [Commands](#5-commands)
8. [Example use cases](#6-example-use-cases)
9. [Data contract](#7-data-contract)
10. [Enterprise constraints](#8-enterprise-constraints)
11. [Troubleshooting](#9-troubleshooting)
12. [Version](#10-version)

---

## Architecture

```text
kpi-analytics.cmd
    → python -m kpi_modules
        → kpi_modules.cli
            → diagnostics gate (score | generate | validate-score)
            → score_v1 / kpi_quantifiers / summary_report
            → synthesize / probe / diagnostics / validate_score / config
```

---

## 1. When to use the CLI vs the package

| Caller | Recommended API |
|--------|-----------------|
| Another **Python** script (same process) | Import `score_csv`, `generate_csv`, `load_config` |
| **cmd**, Task Scheduler, CI, PowerShell | **CLI** (`kpi-analytics.cmd` or `python -m kpi_modules`) |

The CLI is a thin wrapper around package functions.

---

## 2. Invocation

### 2.1 Command Prompt / batch

```bat
cd /d C:\path\to\workqueue-data-processor\kpi-analytics

kpi-analytics.cmd version
kpi-analytics.cmd diagnostics --json
kpi-analytics.cmd probe --json
kpi-analytics.cmd score --output ..\output\wq_scored.csv --json
kpi-analytics.cmd score --csv ..\import\wq_synthetic_data.csv --output ..\output\wq_scored.csv --json
kpi-analytics.cmd validate-score --json
```

`kpi-analytics.cmd` uses `py -3.13 -m kpi_modules` when available, otherwise `python -m kpi_modules`. See [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md).

### 2.2 Direct Python

```bat
cd /d C:\path\to\workqueue-data-processor\kpi-analytics
py -3.13 -m kpi_modules score --output ..\output\wq_scored.csv --json
py -3.13 -m kpi_modules score --csv ..\import\wq_synthetic_data.csv --output ..\output\wq_scored.csv --json
```

Working directory should be **`kpi-analytics\`** (so `kpi_modules` imports), or set `PYTHONPATH`.

### 2.3 General form

```text
python -m kpi_modules <command> [options]
```

| Part | Description |
|------|-------------|
| `<command>` | `version` · `probe` · `diagnostics` · `score` · `generate` · `validate-score` · `help` |
| `[options]` | Command-specific (below) |

---

## 3. Exit codes

| Code | Meaning |
|------|---------|
| **0** | Success |
| **1** | Validation / usage / preflight failure |
| **2** | Runtime failure |

Prefer **`--json`** stdout for machine-readable details.

---

## 4. Global options

| Option | Description |
|--------|-------------|
| `--json` | Single JSON object on **stdout** |
| `--quiet` | Less human host text when not using `--json` |

---

## 5. Commands

### 5.1 `version`

```text
python -m kpi_modules version [--json]
```

Without `--json`, prints the bare version string (e.g. `1.8.0`).

```json
{"Success":true,"Version":"1.8.0","Command":"version"}
```
---

### 5.2 `probe`

Optional path/environment preflight: Python version, a few stdlib imports, temp write, default config, optional paths.

```text
python -m kpi_modules probe [--csv <path>] [--config <path>] [--schema <path>] [--json] [--quiet]
```

Exit **0** if all checks pass; **1** otherwise.

**Note:** `probe` does **not** write the enterprise diagnostics certificate and does **not** satisfy the operational gate. Use `diagnostics` for first-run enterprise readiness.

---

### 5.3 `diagnostics`

Enterprise dry-run: runtime and import surface checks for the toolkit. Always refreshes the durable report under `diagnostics\`.

```text
python -m kpi_modules diagnostics [--force] [--json] [--quiet]
```

| Option | Description |
|--------|-------------|
| `--force` | Explicit re-run alias (command always re-runs when invoked) |
| `--json` | JSON result on stdout |
| `--quiet` | Minimal host text |

**Writes:**

| File | Role |
|------|------|
| `diagnostics\last_diagnostics.json` | Gate certificate (machine-readable) |
| `diagnostics\last_diagnostics.txt` | Human PASS/FAIL list for IT |

**Suite (critical unless noted):** Python 3.13+, executable path, each stdlib module used by the package, each `kpi_modules` submodule import, default config load, write access to `diagnostics\`. Advisory checks record platform/cwd.

**Privacy:** report contains environment metadata only — no claim rows or PHI.

Exit **0** if `OverallPass`; **1** if any critical check fails.

```json
{
  "Success": true,
  "OverallPass": true,
  "Command": "diagnostics",
  "Version": "1.8.0",
  "ToolkitVersion": "1.8.0",
  "PythonVersion": "3.13.0",
  "ReportJsonPath": "C:\\...\\kpi-analytics\\diagnostics\\last_diagnostics.json",
  "ReportTextPath": "C:\\...\\kpi-analytics\\diagnostics\\last_diagnostics.txt",
  "CriticalFailed": [],
  "Checks": [{"Name": "PythonVersion", "Passed": true, "Severity": "critical", "Detail": "..."}]
}
```

---

### 5.4 Diagnostics gate (operational commands)

Before `score`, `generate`, and `validate-score`, the CLI ensures a **valid pass certificate**:

| Condition | Behavior |
|-----------|----------|
| Valid pass for current `ToolkitVersion` + Python version | Proceed (`DiagnosticsGate`: `cached`) |
| Missing, failed, or stale certificate | **Auto-run** diagnostics; proceed only if pass (`ran`) |
| Auto-run fails | Exit **1**; point to `last_diagnostics.txt` (`blocked`) |

**Not gated:** `version`, `help`, `probe`, `diagnostics`.

| Flag (on gated commands) | Meaning |
|--------------------------|---------|
| `--force-diagnostics` | Re-run diagnostics before the command |
| `--skip-diagnostics-gate` | Bypass gate (emergency/support only; warns on stderr) |

Successful gated JSON may include `DiagnosticsGate` (`cached` \| `ran` \| `skipped`) and report path fields.

---

### 5.5 `score`

Scores a data CSV:

- Priority Matrix V1 (`v1_*`)
- RCM claim impacts (`kpi_q_*`)
- Vertical **summary** CSV (default on)

```text
python -m kpi_modules score [--csv <path>] [--output <path>]
    [--config <path>] [--summary <path>] [--no-summary]
    [--privacy | --no-privacy]
    [--dry-run] [--json] [--quiet]
```

| Option | Required | Default | Description |
|--------|----------|---------|-------------|
| `--csv` | No | `\<repo>\import\wq_synthetic_data.csv` | Input data CSV (tracked synthetic demo when present) |
| `--output` | No | `\<repo>\output\wq_scored.csv` | Claim-level scored CSV |
| `--summary` | No | `<output_stem>_summary.csv` | Vertical summary CSV |
| `--no-summary` | No | off | Skip summary file |
| `--config` | No | package default | Weights / KPI config |
| `--privacy` | No | (config) | Force PHI field masking on scored output |
| `--no-privacy` | No | (config) | Disable PHI field masking on scored output |
| `--dry-run` | No | off | No file writes |
| `--force-diagnostics` | No | off | Refresh diagnostics certificate first |
| `--skip-diagnostics-gate` | No | off | Emergency bypass of diagnostics gate |
| `--json` | No | off | JSON on stdout |
| `--quiet` | No | off | Minimal host text |

`--privacy` and `--no-privacy` are mutually exclusive. When omitted, `privacy.enabled` from the JSON config applies (default **on** in package `config_default.json`). Overrides only the master switch; patient/DOB modes still come from config.

**Examples**

```bat
kpi-analytics.cmd score --json

kpi-analytics.cmd score --csv ..\import\wq_synthetic_data.csv --output ..\output\wq_scored.csv --json

kpi-analytics.cmd score --no-privacy --json

kpi-analytics.cmd score --csv D:\exports\wq_export.csv ^
  --output ..\output\wq_scored.csv --privacy --json
```

**JSON shape (illustrative)**

```json
{
  "Success": true,
  "Command": "score",
  "Version": "1.8.0",
  "InputPath": "C:\\...\\import\\wq_synthetic_data.csv",
  "OutputPath": "C:\\...\\output\\wq_scored.csv",
  "SummaryPath": "C:\\...\\output\\wq_scored_summary.csv",
  "RowCount": 250,
  "ColumnCount": 84,
  "DryRun": false,
  "QueueMode": "chaos",
  "AsOfDate": "2026-07-22",
  "ScoreMin": 0.01,
  "ScoreMax": 0.80,
  "ScoreMean": 0.25,
  "ScoreColumn": "v1_priority_score",
  "DiagnosticsGate": "cached",
  "KpiTotals": {
    "kpi_total_ar": 284235.94,
    "kpi_days_in_ar": 55.5,
    "kpi_ar_over_90_pct": 71.53,
    "adc": 5121.78,
    "adc_source": "estimate_billed_90"
  },
  "PrivacyEnabled": true,
  "PrivacyPatientMode": "prefix_token",
  "PrivacyDobMode": "omit",
  "PrivacyUniquePatients": 198,
  "PrivacyCliOverride": null,
  "Message": "Score complete (detail + summary)."
}
```

`PrivacyCliOverride` is `true` / `false` when `--privacy` / `--no-privacy` was passed; `null` when the config alone decided masking.

**Summary CSV layout** (vertical / transposed):

| Column | Content |
|--------|---------|
| `section` | e.g. Run, Portfolio KPI, Portfolio KPI Q checksum, Claim column guide, Priority batch |
| `metric` | Metric name |
| `value` | Numeric or text value |
| `unit` | Unit when applicable |
| `formula` | Short formula |
| `explanation` | Plain-language description |

`KpiTotals` and `kpi_q_*` follow [RCM_KPI_Claim_Impact_Methodology.md](./RCM_KPI_Claim_Impact_Methodology.md). Priority fields follow [SCORE-METHODOLOGY.md](./SCORE-METHODOLOGY.md).

---

### 5.6 `generate`

Synthetic professional-billing WQ CSV (de-identified).

```text
python -m kpi_modules generate [--rows <n>] [--output <path>]
    [--schema <path>] [--template-csv <path>] [--seed <int>]
    [--append] [--start-index <n>] [--dry-run] [--json] [--quiet]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--rows` | `100` | Data rows to create |
| `--output` | `\<repo>\import\wq_synthetic_data.csv` | Destination (tracked **input** folder; refresh carefully) |
| `--schema` | `\<repo>\wq_schema.json` | Field list / types |
| `--template-csv` | `wq_data.csv` if present | Column **order** only |
| `--seed` | `42` | Reproducible RNG |
| `--append` | off | Append; continues Doe name index |
| `--dry-run` | off | No write |

Patients: `Doe,John{N}` / `Doe,Jane{N}`. DOB: Excel serial with day-of-month **01**.  
Use a path under `output\` only for one-off dumps you do not intend to track.

---

### 5.7 `validate-score`

Checks:

1. Priority integrity: `v1_priority_score ≈ sum(v1_contrib_*)`  
2. KPI Q checksums (share sum, Days in AR sum, aged contrib vs portfolio %)  
3. Optional golden expected JSON  

```text
python -m kpi_modules validate-score [--csv <path>] [--config <path>]
    [--expected <path>] [--scored-csv <path>] [--epsilon <float>]
    [--no-expected] [--json] [--quiet]
```

| Option | Default | Description |
|--------|---------|-------------|
| `--csv` | handcalc fixture if omitted | Input to recompute |
| `--config` | handcalc config when using that fixture | Config JSON |
| `--expected` | handcalc expected when applicable | Golden file |
| `--scored-csv` | — | Validate existing scored file |
| `--no-expected` | off | Integrity / KPI Q only |
| `--epsilon` | `1e-5` | Numeric tolerance |

```bat
kpi-analytics.cmd validate-score --json

kpi-analytics.cmd validate-score --csv fixtures\rcm_impact_example.csv ^
  --config fixtures\rcm_impact_config.json ^
  --expected fixtures\rcm_impact_expected.json --json

kpi-analytics.cmd validate-score --scored-csv ..\output\wq_scored_pro250_v151.csv --no-expected --json
```

---

### 5.8 `help`

Prints built-in help (`kpi-analytics.cmd help`).

---

## 6. Example use cases

### 6.1 First-run enterprise diagnostics

```bat
cd /d C:\path\to\workqueue-data-processor\kpi-analytics
kpi-analytics.cmd diagnostics --json
rem Share diagnostics\last_diagnostics.txt with IT if any FAIL lines
```

### 6.2 Score production extract + summary

```bat
cd /d C:\path\to\workqueue-data-processor\kpi-analytics
kpi-analytics.cmd score --csv D:\exports\wq_export.csv --output ..\output\wq_scored.csv --json
```

### 6.3 Synthetic volume then score

```bat
kpi-analytics.cmd generate --rows 250 --seed 42
kpi-analytics.cmd score --output ..\output\wq_scored.csv --json
```

### 6.4 PowerShell orchestration

```powershell
$cli = Join-Path $PSScriptRoot 'kpi-analytics.cmd'
Push-Location (Split-Path $cli)
& .\kpi-analytics.cmd score --csv ..\wq_data.csv --output ..\output\wq_scored.csv --json
if ($LASTEXITCODE -ne 0) { throw "kpi-analytics failed: $LASTEXITCODE" }
Pop-Location
```

### 6.5 Export scored data with excel-toolkit

```bat
cd ..\excel-toolkit
excel-toolkit.cmd export-csv -CsvPath ..\output\wq_scored.csv -OutputPath ..\output\wq_scored.xlsx -Json
```

### 6.6 Task Scheduler

Program: path to `python.exe` (3.13).  
Arguments: `-m kpi_modules score --csv "C:\data\wq.csv" --output "C:\data\out\wq_scored.csv" --json`  
Start in: `...\kpi-analytics`

---

## 7. Data contract

### 7.1 `score` detail CSV

| Block | Content |
|-------|---------|
| Original CSV columns | Preserved order and names; **`patient` / `dob` masked by default** (`privacy` config) |
| `v1_*` | Priority audit + `v1_priority_score` |
| `kpi_q_*` | Static RCM share/contrib + exact resolution Δ (pos/neg where configured) |

Patient default: `DOE,JOHN` → `DOE001,JOH001` (batch alpha-order token). DOB default: blank. See [SCORE-METHODOLOGY.md](./SCORE-METHODOLOGY.md) §12. Not a HIPAA Safe Harbor claim.

### 7.2 `score` summary CSV

One metric per **row** (not one metric per wide column). Sections: Run, Portfolio KPI, Portfolio KPI Q checksum, Claim column guide, Priority batch / weights / chaos, Reference.

### 7.3 `generate`

| Rule | Behavior |
|------|----------|
| Headers | Schema and/or template CSV |
| PHI | Synthetic Doe names; DOB day = 01 |
| Profile | Professional billing style denials and aging |

---

## 8. Enterprise constraints

| Topic | Behavior |
|-------|----------|
| Elevation | Not required |
| Third-party packages | Not used |
| Network | Not used |
| Excel automation | Not used |
| Machine policy | Not changed |
| Diagnostics report | Environment/import results only; no PHI |

See [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md).

---

## 9. Troubleshooting

| Symptom | Check |
|---------|--------|
| Exit 1 on `diagnostics` | Read `diagnostics\last_diagnostics.txt` FAIL lines |
| Exit 1 on gated command with DiagnosticsGate blocked | Fix environment; re-run `diagnostics --force` |
| Exit 1 on `probe` | Python 3.13+? Paths valid? |
| Exit 1 on `score` | Default `import\wq_synthetic_data.csv` present, or pass `--csv`? Config valid? File not locked? Gate passed? |
| Exit 1 on `validate-score` | Fixture expected outdated? Use `--no-expected` for integrity only |
| `No module named kpi_modules` | Start in `kpi-analytics\` |
| Days in AR unrealistic | Set `kpi_quantifiers.adc`; read `adc_source` in summary |
| Permission denied writing CSV | Close workbook in Excel |
| Cannot write diagnostics folder | ACL on `kpi-analytics\diagnostics\`; temporary `--skip-diagnostics-gate` |

---

## 10. Version

CLI and package version are aligned at **1.8.0**. Bump when changing verbs, exit codes, JSON field names, default paths, diagnostics gate behavior, privacy defaults, or `kpi_q_*` / summary contracts.
