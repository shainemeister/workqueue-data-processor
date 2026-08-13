---
title: Excel Toolkit CLI Reference
description: Command-line syntax, exit codes, JSON shapes, and use cases for ExcelToolkit.ps1 / excel-toolkit.cmd.
version: "1.18.0"
status: current
audience:
  - developers
  - automation
doc_type: cli
related:
  - README.md
  - ENTERPRISE-SECURITY.md
  - diagnostics/README.md
last_updated: "2026-08-13"
---

# Excel Toolkit — CLI Reference

Professional reference for the **command-line interface** used by automation, Task Scheduler, Python, and other processes.

**Toolkit version:** 1.18.0 (see `version` command / `Get-ExcelToolkitVersion`)

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

This guide is the authoritative **command-line contract** for the Excel Toolkit. It documents how to invoke `excel-toolkit.cmd` / `ExcelToolkit.ps1`, each verb (`version`, `probe`, `diagnostics`, `export-csv`, `import-excel`, `help`), global flags (`-Json`, `-Quiet`), exit codes (**0** / **1** / **2**), and illustrative JSON shapes for automation.

| Command | Produces |
|---------|----------|
| `version` | Toolkit version string (or JSON with version fields) |
| `probe` | Environment readiness (PowerShell, Excel COM, paths) |
| `diagnostics` | Enterprise readiness suite; writes `diagnostics\last_diagnostics.json` / `.txt` (gate certificate) |
| `export-csv` | Formatted `.xlsx` workbook from a CSV (optional schema display names; optional open password) |
| `import-excel` | CSV from a local `.xlsx` / `.xls` (password-aware; interactive prompt when needed) |

Use **Import-Module** APIs when already in-process PowerShell; use this CLI for Task Scheduler, cmd, Python, and cross-language orchestration. Security constraints are summarized in [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md).

---

## Contents

1. [Summary](#summary)
2. [Architecture](#architecture)
3. [When to use the CLI vs the module](#1-when-to-use-the-cli-vs-the-module)
4. [Invocation](#2-invocation)
5. [Exit codes](#3-exit-codes)
6. [Global options](#4-global-options)
7. [Commands](#5-commands) (`version`, `probe`, `diagnostics`, `export-csv`, `import-excel`, `help`)
8. [Example use cases](#6-example-use-cases)
9. [Data contract](#7-data-contract-export-csv--import-excel)
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
| Interactive user | `Start-ExcelMenu.cmd` — **Process my data** lists `import\` CSV/Excel; multi-select accepts `1`, `1,2`, `1-3`, `1,3-5,8`, or a full path; 2+ files show a **preview** (name, WQ stem, row count, max `out_ins_amt`) without scoring. Full pipeline / Score only / **Build worklist** pick an optional **scoring profile** (subprocess `score --profile`); Build worklist also picks `--group-preset`. **Express score** skips those picks, scores `--output-mode slim`, and writes one `POI_Scores` sheet. Excel deliverable names `[WQ]_MM-DD-YYYY.xlsx`. Score path runs mapping preflight + guided column mapping when headers need attention; optional workbook password on Excel export except Express. Advanced → scoring profiles list/help. CLI: `export-csv -PoiScoreSheetOnly` (1.14.0), `-TotalsCsv` (1.12.0), Groups/Worklist (1.10.0). |

The CLI is a thin wrapper around the same module functions. It does not replace `Import-Module` for in-process PowerShell work.

---

## 2. Invocation

### 2.1 From Command Prompt or batch

```bat
cd /d C:\path\to\workqueue-data-processor\excel-toolkit

excel-toolkit.cmd version
excel-toolkit.cmd probe -CsvPath ..\wq_schema\wq_data.csv
excel-toolkit.cmd export-csv -CsvPath ..\wq_schema\wq_data.csv -OutputPath ..\output\export.xlsx -Json
```

`excel-toolkit.cmd` starts PowerShell with **process-scoped** `-ExecutionPolicy Bypass` only (does not change machine policy). See [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md).

### 2.2 Direct PowerShell

```powershell
cd C:\path\to\workqueue-data-processor\excel-toolkit

powershell -NoProfile -ExecutionPolicy Bypass -File .\ExcelToolkit.ps1 version
powershell -NoProfile -ExecutionPolicy Bypass -File .\ExcelToolkit.ps1 probe -Json
powershell -NoProfile -ExecutionPolicy Bypass -File .\ExcelToolkit.ps1 export-csv `
  -CsvPath ..\wq_schema\wq_data.csv `
  -OutputPath ..\output\export.xlsx `
  -UseDisplayNames `
  -SchemaPath ..\wq_schema\wq_schema.json `
  -Json
```

### 2.3 General form

```text
ExcelToolkit.ps1 <command> [options]
```

| Part | Description |
|------|-------------|
| `<command>` | `version` · `probe` · `export-csv` · `import-excel` · `help` |
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
{"Success":true,"Version":"1.7.1","Command":"version"}
```

Without `-Json`, stdout is the bare version string (for example `1.7.1`).

---

### 5.2 `probe`

Runs environment preflight (PowerShell readiness, temp write, optional path checks, Excel COM create/quit). Does **not** write the diagnostics certificate (use `diagnostics` for that).

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
excel-toolkit.cmd probe -CsvPath ..\wq_schema\wq_data.csv -SchemaPath ..\wq_schema\wq_schema.json -Json
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
  "Version": "1.7.1",
  "Message": "Preflight passed.",
  "Checks": [
    { "Name": "ExcelCom", "Passed": true, "Detail": "Excel version 16.0" }
  ]
}
```

**Exit codes:** `0` if all checks pass; `1` if any check fails.

---

### 5.2b `diagnostics`

Enterprise readiness suite (module exports, Excel COM create/quit, diagnostics folder writable). Always refreshes `diagnostics\last_diagnostics.json` and `.txt` when it can write.

**Syntax**

```text
ExcelToolkit.ps1 diagnostics [-Force] [-CsvPath <path>] [-SchemaPath <path>] [-Json] [-Quiet]
```

| Option | Required | Description |
|--------|----------|-------------|
| `-Force` | No | Accepted for symmetry (diagnostics always re-runs and overwrites the certificate) |
| `-CsvPath` / `-SchemaPath` | No | Optional path checks |
| `-Json` / `-Quiet` | No | Output style |

**Certificate files** (gitignored; regenerable per machine):

| File | Role |
|------|------|
| `diagnostics\last_diagnostics.json` | Gate certificate (machine-readable) |
| `diagnostics\last_diagnostics.txt` | Human PASS/FAIL list for IT |

**Gate behavior (export-csv / import-excel):**

| Situation | Result |
|-----------|--------|
| No valid pass cert | Auto-run diagnostics; continue only if pass (`DiagnosticsGate=ran`) |
| Valid cert for current toolkit version | Skip suite (`DiagnosticsGate=cached`) |
| Cert deleted or version changed | Auto-run again |
| Critical check fails | Block command (`DiagnosticsGate=blocked`); exit **1** |

| Flag on gated commands | Meaning |
|------------------------|---------|
| `-ForceDiagnostics` | Re-run diagnostics before this command |
| `-SkipDiagnosticsGate` | Emergency/support only — do not require a pass cert |

**Examples**

```bat
excel-toolkit.cmd diagnostics
excel-toolkit.cmd diagnostics -Json
```

**Exit codes:** `0` if OverallPass; `1` if any critical check fails.

---

### 5.3 `export-csv`

Exports a **data CSV** to a formatted `.xlsx` workbook. Column layout is always driven by the CSV header row. An optional schema supplies display labels only.

**Syntax**

```text
ExcelToolkit.ps1 export-csv -CsvPath <path> [-OutputPath <path>]
    [-SchemaPath <path>] [-SchemaFormat Auto|Json|Csv]
    [-UseDisplayNames] [-DisplayNameProperty <name>]
    [-SheetName <name>] [-GroupsCsv <path>] [-GroupsSheetName <name>]
    [-Worklist] [-WorklistSheetName <name>]
    [-TotalsCsv <path>] [-TotalsSheetName <name>]
    [-PoiScoreSheetOnly] [-PoiScoreSheetName <name>]
    [-Visible] [-DryRun]
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
| `-SheetName` | No | `Data` | Detail worksheet tab name |
| `-GroupsCsv` | No | — | Optional kpi-analytics `*_groups.csv`. Adds a **Groups** sheet (copy only; no scoring math). |
| `-GroupsSheetName` | No | `Groups` | Groups tab name (must differ from `-SheetName`) |
| `-Worklist` | No | off | Also write a two-level **Worklist** sheet (GROUP then matching CLAIM rows). Requires `-GroupsCsv`. |
| `-WorklistSheetName` | No | `Worklist` | Worklist tab name |
| `-TotalsCsv` | No | — | Optional file-level totals CSV (`metric`,`value`). Adds a **Totals** sheet (copy only; no scoring math). |
| `-TotalsSheetName` | No | `Totals` | Totals tab name (must differ from Data / Groups / Worklist) |
| `-PoiScoreSheetOnly` | No | off | Write **only** a `POI_Scores` sheet: identity + score-input + context **source** columns (if present) + four slim scores. Copy only; no scoring math. Cannot combine with `-GroupsCsv` / `-Worklist` / `-TotalsCsv`. Requires slim score columns. |
| `-PoiScoreSheetName` | No | `POI_Scores` | Tab name when `-PoiScoreSheetOnly` is set |
| `-Visible` | No | off | Show Excel UI (debug) |
| `-Password` | No | — | Optional workbook **open** password when saving `.xlsx` (not logged; not in JSON) |
| `-Force` | No | off | Replace the **exact** `-OutputPath` if it exists. Default: **do not overwrite** — write to a free sibling path with a numerical suffix (`export_1.xlsx`, …) |
| `-DryRun` | No | off | Validate and plan only; no file write |
| `-Json` | No | off | JSON result on stdout |
| `-Quiet` | No | off | Less host text |

\* If `-OutputPath` is omitted, the CLI uses `\<repo>\output\export.xlsx` (parent of `excel-toolkit`).

**Collision policy:** if the destination already exists and `-Force` is **not** set, the toolkit writes to `name_1.ext`, `name_2.ext`, … (cap 999). JSON always reports the **actual** `OutputPath`, plus `RequestedOutputPath` and `PathAdjusted`.

**Examples**

Dry-run (no workbook):

```bat
excel-toolkit.cmd export-csv -CsvPath ..\wq_schema\wq_data.csv -OutputPath ..\output\export.xlsx -DryRun
```

Export with technical CSV headers:

```bat
excel-toolkit.cmd export-csv -CsvPath ..\wq_schema\wq_data.csv -OutputPath ..\output\export.xlsx
```

Export with schema display names + JSON for automation:

```bat
excel-toolkit.cmd export-csv ^
  -CsvPath ..\wq_schema\wq_data.csv ^
  -SchemaPath ..\wq_schema\wq_schema.json ^
  -UseDisplayNames ^
  -OutputPath ..\output\export.xlsx ^
  -Json
```

Express POI score sheet from a slim scored CSV (identity + score-input source + four scores):

```bat
excel-toolkit.cmd export-csv ^
  -CsvPath ..\output\wq_scored.csv ^
  -OutputPath ..\output\wq_poi_scores.xlsx ^
  -PoiScoreSheetOnly ^
  -Json
```

Create a password-protected workbook (synthetic fixture password example):

```bat
excel-toolkit.cmd export-csv ^
  -CsvPath ..\import\wq_synthetic_data.csv ^
  -OutputPath ..\import\wq_synthetic_data_protected.xlsx ^
  -Password SyntheticTest1
```

**JSON shape (illustrative)**

```json
{
  "Success": true,
  "Command": "export-csv",
  "Version": "1.7.1",
  "OutputPath": "C:\\...\\output\\export.xlsx",
  "RequestedOutputPath": "C:\\...\\output\\export.xlsx",
  "PathAdjusted": false,
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

### 5.4 `import-excel`

Imports a local **Excel workbook** to a **CSV** file. Column layout comes from the worksheet used range (first row treated as headers by `Import-Csv` consumers). Supports **workbook open passwords**.

**Syntax**

```text
ExcelToolkit.ps1 import-excel -ExcelPath <path> [-OutputPath <path>]
    [-SheetName <name>] [-Password <text>]
    [-Visible] [-DryRun]
    [-Json] [-Quiet]
```

| Option | Required | Default | Description |
|--------|----------|---------|-------------|
| `-ExcelPath` | **Yes** | — | Input `.xlsx` or `.xls` |
| `-OutputPath` | No | `\<repo>\import\<excel-basename>.csv` | Destination CSV (default folder is **`import\`**) |
| `-SheetName` | No | first worksheet | Tab name when set |
| `-Password` | No | — | Workbook open password for automation (**not logged**; not in JSON) |
| `-Force` | No | off | Replace the **exact** `-OutputPath` if it exists. Default: unique numerical suffix (`name_1.csv`, …) |
| `-Visible` | No | off | Show Excel UI (debug) |
| `-DryRun` | No | off | Open and plan only; no CSV write |
| `-Json` | No | off | JSON result on stdout |
| `-Quiet` | No | off | Less host text |

**Password behavior**

| Situation | Behavior |
|-----------|----------|
| File not password-protected | Opens without prompting |
| Protected + interactive (no `-Json`) and no `-Password` | Prompts once with masked `Read-Host -AsSecureString` |
| Protected + `-Password` supplied | Uses supplied password (for Task Scheduler / tests) |
| Protected + `-Json` and no `-Password` | Exit **1** with a clear message (no hang) |
| Wrong password | Exit non-zero; password never echoed |

JSON payloads include **`PasswordUsed`** (boolean only)—never the secret.

**Examples**

Import unprotected workbook from `import\` (explicit non-colliding output path):

```bat
excel-toolkit.cmd import-excel ^
  -ExcelPath ..\import\wq_synthetic_data.xlsx ^
  -OutputPath ..\import\from_xlsx_smoke.csv ^
  -Json
```

Import password-protected workbook (automation):

```bat
excel-toolkit.cmd import-excel ^
  -ExcelPath ..\import\wq_synthetic_data_protected.xlsx ^
  -OutputPath ..\import\from_xlsx_protected_smoke.csv ^
  -Password SyntheticTest1 ^
  -Json
```

Interactive (prompt if needed; default CSV is `import\<excel-basename>.csv`):

```bat
excel-toolkit.cmd import-excel -ExcelPath ..\import\wq_synthetic_data_protected.xlsx
```

**Default path caution:** omitting `-OutputPath` writes `import\<basename>.csv`. If that file already exists (for example tracked `import\wq_synthetic_data.csv`), the import **does not overwrite** it; it writes `import\<basename>_1.csv` (or the next free `_N`) unless `-Force` is set.

**JSON shape (illustrative)**

```json
{
  "Success": true,
  "Command": "import-excel",
  "Version": "1.7.1",
  "ExcelPath": "C:\\...\\import\\wq_synthetic_data.xlsx",
  "OutputPath": "C:\\...\\import\\wq_synthetic_data_1.csv",
  "RequestedOutputPath": "C:\\...\\import\\wq_synthetic_data.csv",
  "PathAdjusted": true,
  "RowCount": 250,
  "ColumnCount": 40,
  "DryRun": false,
  "Message": "Import complete (wrote ...; avoided overwrite of ...).",
  "HeadersSample": ["wq_status", "related_charge_lines"],
  "SheetName": "Data",
  "PasswordUsed": false
}
```

**Exit codes:** `0` success; `1` validation / missing or wrong password; `2` runtime (COM).

**Synthetic fixture password:** demo workbooks under `import\` use the known non-secret value `SyntheticTest1` when protected. Do not reuse real credentials in repo examples.

---

### 5.5 `help`

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
    -CsvPath (Join-Path $PSScriptRoot '..\wq_schema\wq_data.csv') `
    -OutputPath (Join-Path $PSScriptRoot '..\output\from_component.xlsx') `
    -SchemaPath (Join-Path $PSScriptRoot '..\wq_schema\wq_schema.json') `
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
    "-CsvPath", str(root / "wq_schema" / "wq_data.csv"),
    "-SchemaPath", str(root / "wq_schema" / "wq_schema.json"),
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
excel-toolkit.cmd probe -CsvPath ..\wq_schema\wq_data.csv -Json
if errorlevel 1 exit /b 1
excel-toolkit.cmd export-csv -CsvPath ..\wq_schema\wq_data.csv -OutputPath ..\output\export.xlsx
```

### 6.5 Import Excel from `import\` (module)

```powershell
Import-Module .\ExcelToolkit.psm1 -Force
$r = Import-CsvFromExcel `
    -ExcelPath ..\import\wq_synthetic_data.xlsx `
    -OutputPath ..\import\from_xlsx_smoke.csv
if (-not $r.Success) { throw $r.Message }
```

### 6.6 Task Scheduler

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

## 7. Data contract (export-csv / import-excel)

| Direction | Input | Output | Notes |
|-----------|-------|--------|-------|
| **export-csv** | Data CSV (+ optional schema) | `.xlsx` | CSV headers drive columns; schema only for display labels |
| **import-excel** | `.xlsx` / `.xls` | CSV | Worksheet used range; first row becomes header names for `Import-Csv` |

Schema label properties (export only; first match wins): `display_name`, `wq_field_name`, `label`, `title`.

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
| Workbook passwords | Process memory only; never logged or written to JSON; interactive SecureString prompt when allowed |

Full detail: [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md).

---

## 9. Troubleshooting

| Symptom | What to check |
|---------|----------------|
| Exit code 1 on `probe` | Excel installed? FullLanguage? Paths valid? |
| Exit code 1 on `diagnostics` | Read `diagnostics\last_diagnostics.txt` FAIL lines |
| Exit code 1 on `export-csv` | Gate blocked? See diagnostics report. Or `-CsvPath` set? Schema required if `-UseDisplayNames`? Unique-path cap exceeded? |
| Exit code 1 on `import-excel` | Gate blocked? Or `-ExcelPath` set? Password required with `-Json`? Wrong password? Unique-path cap exceeded? |
| Unexpected new `name_N` file | Destination already existed; check `PathAdjusted` / `RequestedOutputPath` in JSON |
| Exit code 2 | Excel COM/save failure; file locked - close Excel and retry |
| Empty JSON / parse error in Python | Ensure `-Json` and read **stdout** only; check `returncode` first |
| Scripts blocked | AppLocker/WDAC/GPO - see enterprise doc; do not add more aggressive flags |
| Password prompt never appears with `-Json` | Expected — supply `-Password` for automation |

---

## 10. Version

CLI and module version are aligned at **1.18.0** via `Get-ExcelToolkitVersion` / `version` command. Bump when shipping breaking CLI contract changes (verbs, exit codes, JSON field names).

**1.18.0 notes:** Express column `patient` follows `invoice_num`. After a successful **menu** Excel write (Full pipeline / Worklist / Express), generated `output\` CSVs for that run are deleted. Score-only and Export-only keep CSVs. CLI `export-csv` does not delete inputs.

**1.17.0 notes:** Express `POI_Scores` uses the frozen **column order** in [slim-poi-output.md](../docs/plan/slim-poi-output.md) (include if present). Row order is unchanged.

**1.16.0 notes:** Express `POI_Scores` also copies context source columns when present (`plan`, `reason_code_list`, `remittance_code`, `cpt_codes`, `modifiers`, `diagnosis_codes`, `billing_provider`, `department`, `billing_provider_tax_id`, `billing_provider_npi`). Schema name is `cpt_codes`.

**1.15.0 notes:** `-PoiScoreSheetOnly` / Express `POI_Scores` also copies score-input **source** columns when present (`out_ins_amt`, `billed_amount`, deadline days, `days_on_wq_tab`, `denial_count`, `last_worked_date`). Still no `v1_raw_*`. Copy only.

**1.14.2 notes:** Action **[5]** label is **Express score** (same DarkGray as [1]–[4]; no extra Express hint line).

**1.14.1 notes:** Process my data action list prints toolkit version and lists **[5] Express score**. Numbers [1]–[5] unchanged. Close and relaunch the menu after upgrade.

**1.14.0 notes:** `export-csv -PoiScoreSheetOnly` writes one **POI_Scores** sheet (identity + four slim scores; copy only). Process my data **Express score** composes `score --output-mode slim` then this switch (no profile / password / Full-Slim pick; no summary xlsx). JSON: `PoiScoreSheetOnly`, `PoiScoreSheet`, `PoiScoreRowCount`.

**1.13.0 notes:** Process my data offers **Score output** Full or Slim. Slim composes `kpi-analytics.cmd score --output-mode slim` (no `--profile`). No scoring math in PowerShell.

**1.12.1 notes:** Worklist key match is case-sensitive (same trim / `(blank)` rule as kpi-analytics `_cell_label`). PowerShell `-ne` is not used.

**1.12.0 notes:** Cluster 2 menu: multi-file preview (no `score`); Excel names `[WQ]_MM-DD-YYYY.xlsx` (WQ = filename stem or profile `wq_label`); `export-csv -TotalsCsv` copies a file-level totals CSV to a **Totals** sheet. Per-file scoring unchanged. See [README.md](./README.md).

**1.11.0 notes:** interactive `Start-ExcelMenu` **Process my data → Build worklist** composes `kpi-analytics.cmd score --group-preset` / `--groups` then `Export-ExcelFromCsv -GroupsCsv -Worklist`. Group picker: `payer_category` (default) / `payer` / `category` / `location`. Same scoring-profile pick as Full pipeline. No new Excel CLI verbs; no scoring math in PowerShell. See [README.md](./README.md).

**1.10.0 notes:** `export-csv -GroupsCsv` copies a kpi-analytics groups file to a **Groups** sheet. `-Worklist` adds a two-level **Worklist** sheet (GROUP then CLAIM) by matching group key columns. No scoring or KPI math in PowerShell.

**1.9.0 notes:** interactive `Start-ExcelMenu` Full pipeline / Score only offer a **scoring profile** picker (package default = omit `--profile`; listed POI presets or typed name/path). Choice is applied once per batch and passed to every `kpi-analytics.cmd score` invoke (preflight dry-run, full score, guided mapping, rank-enrich dry-run). Advanced tools → **Scoring profiles (list / CLI help)** runs `profile-list` only. No new Excel CLI verbs; no scoring math in PowerShell. See [README.md](./README.md) and [kpi-analytics CLI — Scoring profiles](../kpi-analytics/CLI-GUIDE.md#scoring-profiles-260).

**1.8.0 notes:** after score, partial ranks (`RankCompleteness` ≠ full) show a banner and require confirm to keep CSVs / export Excel.

**1.8.1 notes:** partial-rank banner also applies after **guided (interactive) mapping**. The interactive score path has no JSON stdout; the menu now refreshes rank metadata via a dry-run when a mapping file is available, and treats guided scores without `RankCompleteness` as partial (fail-safe) so the confirm gate is not skipped.

**1.7.3 notes:** guided mapping only for missing/ambiguous roles; low-confidence warns and continues.

**1.7.2 notes:** menu file discovery no longer double-lists `.xlsx` (Windows `-Filter '*.xls'` quirk).

**1.7.1 notes:** fix guided-mapping menu crash (`ExitCode` property missing) by running interactive score via `Start-Process` without capturing stdout into the PowerShell pipeline.

**1.7.0 notes:** interactive `Start-ExcelMenu` score path adds **mapping preflight** (dry-run) and **guided column mapping** when roles are missing/ambiguous/low-confidence. Sibling `<stem>_mapping.json` next to the input CSV is auto-applied. Non-interactive hosts fail clearly instead of hanging. CLI verbs unchanged. See [README.md](./README.md).

**1.6.0 notes:** interactive `Start-ExcelMenu` guided **Process my data** flow — unified CSV/Excel discovery under `import\`, print-style multi-select (`1`, `1-3`, `1,3-5,8`), action choice (full pipeline / score only / export only), optional workbook open password on every menu Excel export (SecureString; never logged). Advanced tools retained. CLI verbs unchanged (`export-csv -Password` already supported). See [README.md](./README.md).

**1.5.0 notes:** interactive `Start-ExcelMenu` simplified — main options: full pipeline, score only, export CSV→Excel, Advanced tools (schema export, import, schema, diagnostics). CLI verbs unchanged.

**1.4.0 notes:** `diagnostics` command and first-run **diagnostics gate** for `export-csv` / `import-excel` (pass certificate under `diagnostics\last_diagnostics.*`; delete cert to force re-run). JSON on gated commands includes `DiagnosticsGate` and report paths.

**1.3.0 notes:** default collision policy is unique numerical suffix (not refuse). JSON adds `RequestedOutputPath` and `PathAdjusted`. Interactive pipeline composition with `kpi-analytics` is documented in [README.md](./README.md) (not a CLI verb).