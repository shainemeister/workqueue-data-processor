---
title: Excel Toolkit CLI Reference
description: Command-line syntax, exit codes, JSON shapes, and use cases for ExcelToolkit.ps1 / excel-toolkit.cmd.
version: "1.1.0"
status: current
audience:
  - developers
  - automation
doc_type: cli
related:
  - README.md
  - ENTERPRISE-SECURITY.md
last_updated: "2026-07-22"
---

# Excel Toolkit — CLI Reference

Professional reference for the **command-line interface** used by automation, Task Scheduler, Python, and other processes.

**Toolkit version:** 1.1.0 (see `version` command / `Get-ExcelToolkitVersion`)

**Related docs:** [README.md](./README.md) · [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md)

| Item | Value |
|------|--------|
| **Toolkit folder** | `excel-toolkit\` |
| **CLI script** | `ExcelToolkit.ps1` |
| **Windows shim** | `excel-toolkit.cmd` |
| **Library (PowerShell)** | `ExcelToolkit.psm1` + `ExcelCom.psm1` |
| **Human menu** | `Start-ExcelMenu.cmd` |

---

## Summary

This guide is the authoritative **command-line contract** for the Excel Toolkit. It documents how to invoke `excel-toolkit.cmd` / `ExcelToolkit.ps1`, each verb (`version`, `probe`, `export-csv`, `help`), global flags (`-Json`, `-Quiet`), exit codes (**0** / **1** / **2**), and illustrative JSON shapes for automation.

| Command | Produces |
|---------|----------|
| `version` | Toolkit version string (or JSON with version fields) |
| `probe` | Environment readiness (PowerShell, Excel COM, paths) |
| `export-csv` | Formatted `.xlsx` workbook from a CSV (optional schema display names) |

Use **Import-Module** APIs when already in-process PowerShell; use this CLI for Task Scheduler, cmd, Python, and cross-language orchestration. Security constraints are summarized in [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md).

---

## Contents

1. [Summary](#summary)
2. [Architecture](#architecture)
3. [When to use the CLI vs the module](#1-when-to-use-the-cli-vs-the-module)
4. [Invocation](#2-invocation)
5. [Exit codes](#3-exit-codes)
6. [Global options](#4-global-options)
7. [Commands](#5-commands)
8. [Example use cases](#6-example-use-cases)
9. [Data contract](#7-data-contract-export-csv)
10. [Enterprise constraints](#8-enterprise-constraints-cli)
11. [Troubleshooting](#9-troubleshooting)
12. [Version](#10-version)

---

## Architecture

```text
ExcelToolkit.ps1 (CLI)  →  ExcelToolkit.psm1  →  ExcelCom.psm1
```

---

## 1. When to use the CLI vs the module

| Caller | Recommended API |
|--------|-----------------|
| Another **PowerShell** script (same process) | `Import-Module .\ExcelToolkit.psm1` and call `Export-ExcelFromCsv` / `Get-ExcelToolkitVersion` |
| **Python**, cmd, Task Scheduler, CI | **CLI** (`ExcelToolkit.ps1` or `excel-toolkit.cmd`) |
| Interactive user | `Start-ExcelMenu.cmd` |

The CLI is a thin wrapper around the same module functions. It does not replace `Import-Module` for in-process PowerShell work.

---

## 2. Invocation

### 2.1 From Command Prompt or batch

```bat
cd /d C:\path\to\workqueue-data-processor\excel-toolkit

excel-toolkit.cmd version
excel-toolkit.cmd probe -CsvPath ..\wq_data.csv
excel-toolkit.cmd export-csv -CsvPath ..\wq_data.csv -OutputPath ..\output\export.xlsx -Json
```

`excel-toolkit.cmd` starts PowerShell with **process-scoped** `-ExecutionPolicy Bypass` only (does not change machine policy). See [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md).

### 2.2 Direct PowerShell

```powershell
cd C:\path\to\workqueue-data-processor\excel-toolkit

powershell -NoProfile -ExecutionPolicy Bypass -File .\ExcelToolkit.ps1 version
powershell -NoProfile -ExecutionPolicy Bypass -File .\ExcelToolkit.ps1 probe -Json
powershell -NoProfile -ExecutionPolicy Bypass -File .\ExcelToolkit.ps1 export-csv `
  -CsvPath ..\wq_data.csv `
  -OutputPath ..\output\export.xlsx `
  -UseDisplayNames `
  -SchemaPath ..\wq_schema.json `
  -Json
```

### 2.3 General form

```text
ExcelToolkit.ps1 <command> [options]
```

| Part | Description |
|------|-------------|
| `<command>` | `version` · `probe` · `export-csv` · `help` |
| `[options]` | Command-specific parameters (below) |

---

## 3. Exit codes

| Code | Meaning |
|------|---------|
| **0** | Success |
| **1** | Validation / usage / preflight failure (bad path, missing args, environment check failed) |
| **2** | Runtime failure (Excel COM / save / unexpected error during export) |

Callers should treat any non-zero code as failure. Prefer parsing **`-Json`** output for details.

---

## 4. Global options

Available on most commands:

| Option | Type | Description |
|--------|------|-------------|
| `-Json` | switch | Write a single JSON object to **stdout** (machine-readable) |
| `-Quiet` | switch | Suppress human-oriented host text when not using `-Json` |

When `-Json` is set, structured results go to stdout. Do not mix with interactive prompts.

---

## 5. Commands

### 5.1 `version`

Prints the toolkit version string.

**Syntax**

```text
ExcelToolkit.ps1 version [-Json]
```

**Examples**

```bat
excel-toolkit.cmd version
```

```bat
excel-toolkit.cmd version -Json
```

**JSON shape (illustrative)**

```json
{"Success":true,"Version":"1.1.0","Command":"version"}
```

Without `-Json`, stdout is the bare version string (for example `1.1.0`).

---

### 5.2 `probe`

Runs environment preflight (PowerShell readiness, temp write, optional path checks, Excel COM create/quit).

**Syntax**

```text
ExcelToolkit.ps1 probe [-CsvPath <path>] [-SchemaPath <path>] [-Json] [-Quiet]
```

| Option | Required | Description |
|--------|----------|-------------|
| `-CsvPath` | No | If set, verify this CSV exists and is readable |
| `-SchemaPath` | No | If set, verify this schema file exists and is readable |
| `-Json` | No | JSON result |
| `-Quiet` | No | Minimal host output |

**Examples**

```bat
excel-toolkit.cmd probe
```

```bat
excel-toolkit.cmd probe -CsvPath ..\wq_data.csv -SchemaPath ..\wq_schema.json -Json
```

**Human output (illustrative)**

```text
  [PASS] PowerShellVersion: 5.1.x (target: 5.1+)
  [PASS] TempWritable: ...
  [PASS] ExcelCom: Excel version 16.0
OK
```

**JSON shape (illustrative)**

```json
{
  "Success": true,
  "Command": "probe",
  "Version": "1.1.0",
  "Message": "Preflight passed.",
  "Checks": [
    { "Name": "ExcelCom", "Passed": true, "Detail": "Excel version 16.0" }
  ]
}
```

**Exit codes:** `0` if all checks pass; `1` if any check fails.

---

### 5.3 `export-csv`

Exports a **data CSV** to a formatted `.xlsx` workbook. Column layout is always driven by the CSV header row. An optional schema supplies display labels only.

**Syntax**

```text
ExcelToolkit.ps1 export-csv -CsvPath <path> [-OutputPath <path>]
    [-SchemaPath <path>] [-SchemaFormat Auto|Json|Csv]
    [-UseDisplayNames] [-DisplayNameProperty <name>]
    [-SheetName <name>] [-Visible] [-DryRun]
    [-Json] [-Quiet]
```

| Option | Required | Default | Description |
|--------|----------|---------|-------------|
| `-CsvPath` | **Yes** | — | Input data CSV |
| `-OutputPath` | No* | `..\output\export.xlsx` relative to repo root when omitted | Destination `.xlsx` |
| `-SchemaPath` | No | — | Schema file for display names |
| `-SchemaFormat` | No | `Auto` | `Auto`, `Json`, or `Csv` |
| `-UseDisplayNames` | No | off | Apply schema labels to header row |
| `-DisplayNameProperty` | No | auto | Force a schema property for labels |
| `-SheetName` | No | `Data` | Worksheet tab name |
| `-Visible` | No | off | Show Excel UI (debug) |
| `-DryRun` | No | off | Validate and plan only; no file write |
| `-Json` | No | off | JSON result on stdout |
| `-Quiet` | No | off | Less host text |

\* If `-OutputPath` is omitted, the CLI uses `\<repo>\output\export.xlsx` (parent of `excel-toolkit`).

**Examples**

Dry-run (no workbook):

```bat
excel-toolkit.cmd export-csv -CsvPath ..\wq_data.csv -OutputPath ..\output\export.xlsx -DryRun
```

Export with technical CSV headers:

```bat
excel-toolkit.cmd export-csv -CsvPath ..\wq_data.csv -OutputPath ..\output\export.xlsx
```

Export with schema display names + JSON for automation:

```bat
excel-toolkit.cmd export-csv ^
  -CsvPath ..\wq_data.csv ^
  -SchemaPath ..\wq_schema.json ^
  -UseDisplayNames ^
  -OutputPath ..\output\export.xlsx ^
  -Json
```

**JSON shape (illustrative)**

```json
{
  "Success": true,
  "Command": "export-csv",
  "Version": "1.1.0",
  "OutputPath": "C:\\...\\output\\export.xlsx",
  "RowCount": 1,
  "ColumnCount": 40,
  "DryRun": false,
  "Message": "Export complete.",
  "HeadersSample": ["WQ Status", "Related Charge lines"],
  "SheetName": "Data"
}
```

**Exit codes:** `0` success; `1` validation/preflight; `2` runtime (COM/save).

---

### 5.4 `help`

Prints built-in command summary.

```bat
excel-toolkit.cmd help
```

---

## 6. Example use cases

### 6.1 PowerShell component script (same process — prefer module)

```powershell
$toolkit = Join-Path $PSScriptRoot '..\excel-toolkit\ExcelToolkit.psm1'
Import-Module $toolkit -Force

$r = Export-ExcelFromCsv `
    -CsvPath (Join-Path $PSScriptRoot '..\wq_data.csv') `
    -OutputPath (Join-Path $PSScriptRoot '..\output\from_component.xlsx') `
    -SchemaPath (Join-Path $PSScriptRoot '..\wq_schema.json') `
    -UseDisplayNames

if (-not $r.Success) { throw $r.Message }
Write-Host "Wrote $($r.OutputPath)"
```

### 6.2 PowerShell calling CLI (isolation)

```powershell
$cli = Join-Path $PSScriptRoot '..\excel-toolkit\ExcelToolkit.ps1'
& powershell -NoProfile -ExecutionPolicy Bypass -File $cli export-csv `
    -CsvPath '.\data.csv' -OutputPath '.\out.xlsx' -Json
if ($LASTEXITCODE -ne 0) { throw "excel-toolkit failed: $LASTEXITCODE" }
```

### 6.3 Python orchestration

```python
import json
import subprocess
from pathlib import Path

root = Path(r"C:\path\to\workqueue-data-processor")
cli = root / "excel-toolkit" / "ExcelToolkit.ps1"

cmd = [
    "powershell",
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", str(cli),
    "export-csv",
    "-CsvPath", str(root / "wq_data.csv"),
    "-SchemaPath", str(root / "wq_schema.json"),
    "-UseDisplayNames",
    "-OutputPath", str(root / "output" / "from_python.xlsx"),
    "-Json",
]

proc = subprocess.run(cmd, capture_output=True, text=True)
if proc.returncode != 0:
    raise RuntimeError(f"excel-toolkit failed ({proc.returncode}): {proc.stdout or proc.stderr}")

result = json.loads(proc.stdout)
assert result.get("Success") is True
print("Wrote", result["OutputPath"])
```

### 6.4 Preflight before a batch job

```bat
excel-toolkit.cmd probe -CsvPath ..\wq_data.csv -Json
if errorlevel 1 exit /b 1
excel-toolkit.cmd export-csv -CsvPath ..\wq_data.csv -OutputPath ..\output\export.xlsx
```

### 6.5 Task Scheduler

Program/script:

```text
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
```

Arguments:

```text
-NoProfile -ExecutionPolicy Bypass -File "C:\path\to\excel-toolkit\ExcelToolkit.ps1" export-csv -CsvPath "C:\path\to\data.csv" -OutputPath "C:\path\to\out.xlsx" -Json
```

Start in: folder containing your data (optional).

---

## 7. Data contract (export-csv)

| Input | Role |
|-------|------|
| **Data CSV** | Source of truth for column **order** and technical names |
| **Schema (optional)** | Maps `field_name` → display label only |

Schema label properties (first match wins): `display_name`, `wq_field_name`, `label`, `title`.

No business column names are hard-coded in the toolkit engine.

---

## 8. Enterprise constraints (CLI)

| Topic | Behavior |
|-------|----------|
| Elevation | Not required |
| Force-kill Excel | **Never** |
| Network | Not used |
| Permanent execution policy | Not changed |
| Launcher Bypass | Process-scoped only via `.cmd` |

Full detail: [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md).

---

## 9. Troubleshooting

| Symptom | What to check |
|---------|----------------|
| Exit code 1 on `probe` | Excel installed? FullLanguage? Paths valid? |
| Exit code 1 on `export-csv` | `-CsvPath` set? Schema required if `-UseDisplayNames`? |
| Exit code 2 | Excel COM/save failure; file locked - close Excel and retry |
| Empty JSON / parse error in Python | Ensure `-Json` and read **stdout** only; check `returncode` first |
| Scripts blocked | AppLocker/WDAC/GPO - see enterprise doc; do not add more aggressive flags |

---

## 10. Version

CLI and module version are aligned at **1.1.0** via `Get-ExcelToolkitVersion` / `version` command. Bump when shipping breaking CLI contract changes (verbs, exit codes, JSON field names).