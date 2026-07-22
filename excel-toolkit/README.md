---
title: Excel Toolkit
description: PowerShell 5.1 Excel COM toolkit for CSV export, interactive menu, module API, and CLI.
version: "1.1.0"
status: current
audience:
  - users
  - developers
related:
  - README.md
  - CLI-GUIDE.md
  - ENTERPRISE-SECURITY.md
last_updated: "2026-07-22"
---

# Excel Toolkit (`excel-toolkit`)

PowerShell 5.1 toolkit: export CSV data to Excel, readiness checks, and Excel COM helpers—without needing to type PowerShell for everyday use.

**Toolkit version:** 1.1.0  
**Folder:** `excel-toolkit\` (this directory)

**Related docs:** [CLI-GUIDE.md](./CLI-GUIDE.md) · [ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md)

**Column layout is always driven by your CSV file.** An optional JSON schema can supply display labels. No column names are hard-coded in the engine.

---

## Who should use what

| Audience | Entry point |
|----------|-------------|
| Interactive users | `Start-ExcelMenu.cmd` (or root `Start-ExcelMenu.cmd`) |
| Other PowerShell scripts | `Import-Module .\ExcelToolkit.psm1` → `Export-ExcelFromCsv` |
| Python / Task Scheduler / cmd | CLI: `excel-toolkit.cmd` / `ExcelToolkit.ps1` — see [CLI-GUIDE.md](./CLI-GUIDE.md) |
| Smoke / self-test | `Test-ExcelCom.ps1` (menu option 2, or run directly) |

---

## For most users (recommended)

1. Double-click **`Start-ExcelMenu.cmd`** in this folder  
   (or **`Start-ExcelMenu.cmd`** at the repository root).
2. Choose a number from the menu:

| Option | What it does |
|--------|----------------|
| **1** | Check readiness (dry-run smoke) |
| **2** | Run full self-test |
| **3** | Export CSV → Excel (data CSV headers) |
| **4** | Export CSV → Excel (schema display headers) |
| **5** | Open the `output` folder |
| **6** | Show environment / policy info |
| **7** | Schema: show source, preview fields, switch JSON/CSV |
| **0** | Exit |

3. Open the `.xlsx` file under **`output\`**.

The `.cmd` launcher starts PowerShell with a **process-only** execution policy setting for that window. It does **not** permanently change organization policy.

If double-click fails because scripts are blocked by AppLocker/WDAC or Group Policy, contact IT to allowlist this folder or sign the scripts.

---

## Enterprise notes (summary)

Designed for controlled PCs (no admin, no permanent policy change). Full write-up: **[ENTERPRISE-SECURITY.md](./ENTERPRISE-SECURITY.md)**.

| Topic | Behavior |
|-------|----------|
| Elevation | Not required; no admin registry/policy writes |
| Execution policy | Process-scoped only from `.cmd` launchers (not machine-wide) |
| Excel close | `Quit` → wait → **one** reattempt → **notify user** if still open |
| Force-kill | **Never** kills `EXCEL.EXE` |
| P/Invoke / `Add-Type` | **Not used** |
| Auto Unblock-File | **Not used** (unblock manually if Windows marks files from the internet) |
| Network / downloads | Not used |
| Macros | Automation sets Excel to not run macros when opening files |

If Excel stays open after a run, close it yourself (or via Task Manager), then retry. Output files can stay locked until Excel exits.

---

## Prerequisites

| Need | Notes |
|------|--------|
| Windows PowerShell 5.1 | Built into Windows (`powershell.exe`) |
| Microsoft Excel | Desktop Excel for the current user (COM automation) |
| Your data files | A `.csv` (required for export); optional JSON/CSV schema for display names |

---

## Data layout (public-safe design)

| Source | Role |
|--------|------|
| **Data CSV** | Source of truth for column **order** and technical header names |
| **Schema** (optional JSON **or** CSV) | Maps `field_name` → display label only; does not add/remove columns |

Use **menu option 7** to preview the schema, see the file path, and switch between **JSON** and **CSV** schema formats for the session (options 3/4 honor that choice).

**JSON schema** — `fields` array with `field_name` plus a label property.

**CSV schema** — one row per field, for example:

```text
field_name,display_name,data_type,nullable
id,Identifier,str,false
```

Label properties (first match wins): `display_name`, `wq_field_name`, `label`, `title`  
Or pass `-DisplayNameProperty` / set format with `-SchemaFormat Auto|Json|Csv`.

Extra data-CSV columns not listed in the schema are still exported. Schema-only fields are **not** invented as empty columns.

---

## Files

| File | Purpose |
|------|---------|
| `Start-ExcelMenu.cmd` | Double-click menu launcher |
| `Start-ExcelMenu.ps1` | Interactive menu |
| `excel-toolkit.cmd` | CLI shim for automation |
| `ExcelToolkit.ps1` | CLI (`version`, `probe`, `export-csv`) |
| `ExcelToolkit.psm1` | High-level module (`Export-ExcelFromCsv`, version) |
| `ExcelCom.psm1` | Low-level Excel COM primitives |
| `Export-CsvToExcel.ps1` | Thin export wrapper (menu / legacy) |
| `Export-WqDataToExcel.ps1` | Compatibility forwarder |
| `Test-ExcelCom.ps1` | Smoke tests |
| `CLI-GUIDE.md` | CLI syntax and use cases |
| `ENTERPRISE-SECURITY.md` | Enterprise security reference |
| `README.md` | This document |

Architecture:

```text
Humans          → Start-ExcelMenu.cmd
PowerShell apps → ExcelToolkit.psm1  → ExcelCom.psm1
CLI / Python    → ExcelToolkit.ps1   → ExcelToolkit.psm1 → ExcelCom.psm1
```

---

## Using the toolkit from other PowerShell scripts

Prefer **Import-Module** (same process) over the CLI:

```powershell
$toolkit = Join-Path $PSScriptRoot '..\excel-toolkit\ExcelToolkit.psm1'
Import-Module $toolkit -Force

$r = Export-ExcelFromCsv `
    -CsvPath (Join-Path $PSScriptRoot '..\wq_data.csv') `
    -OutputPath (Join-Path $PSScriptRoot '..\output\from_script.xlsx') `
    -SchemaPath (Join-Path $PSScriptRoot '..\wq_schema.json') `
    -UseDisplayNames

if (-not $r.Success) { throw $r.Message }
```

### `Export-ExcelFromCsv` result object

| Property | Type | Description |
|----------|------|-------------|
| `Success` | bool | `$true` if the operation succeeded |
| `OutputPath` | string | Destination workbook path (planned or written) |
| `RowCount` | int | Data rows exported (excluding header) |
| `ColumnCount` | int | Column count from CSV header |
| `DryRun` | bool | `$true` if no file was written |
| `Message` | string | Human-readable status or error |
| `HeadersSample` | string[] | First few header labels (display or technical) |
| `SheetName` | string | Worksheet tab name |
| `SchemaFormat` | string | Resolved schema format when applicable |

Low-level cell/workbook control:

```powershell
Import-Module .\excel-toolkit\ExcelCom.psm1 -Force

Invoke-ExcelSafe -ScriptBlock {
    param($app)
    $wb = New-ExcelWorkbook -Application $app -SheetName 'Demo'
    $ws = Get-ExcelWorksheet -Workbook $wb -Index 1
    Set-ExcelCell -Worksheet $ws -Address 'A1' -Value 'Hello'
    Save-ExcelWorkbook -Workbook $wb -Path .\output\demo.xlsx
    Close-ExcelWorkbook -Workbook $wb
}
```

---

## CLI (Python, Task Scheduler, cmd)

Full syntax and examples: **[CLI-GUIDE.md](./CLI-GUIDE.md)**.

Quick start:

```bat
cd excel-toolkit
excel-toolkit.cmd version
excel-toolkit.cmd probe -CsvPath ..\wq_data.csv -Json
excel-toolkit.cmd export-csv -CsvPath ..\wq_data.csv -OutputPath ..\output\export.xlsx -Json
```

| Exit code | Meaning |
|-----------|---------|
| 0 | Success |
| 1 | Validation / preflight |
| 2 | Runtime (COM/save) |

### Using from Python

See **CLI-GUIDE.md § 6.3 Python orchestration**. Pattern: Python writes CSV → subprocess CLI `export-csv` → `.xlsx`.

---

## Troubleshooting

| Symptom | What to try |
|---------|-------------|
| Double-click does nothing / window closes | Run `excel-toolkit\Start-ExcelMenu.cmd` from a Command Prompt to see errors |
| "Excel could not be started" | Install/repair Excel for the current user |
| Scripts blocked / unauthorized | Ask IT to allowlist this folder or code-sign the scripts |
| File in use | Close the workbook in Excel, then export again |
| Wrong headers | Confirm CSV header row; for labels, check schema `field_name` matches CSV columns |

### Mark of the Web (downloaded zip)

If files were downloaded, Windows may mark them as from the internet. Right-click a script → Properties → **Unblock** (if shown). The toolkit does **not** auto-unblock files.

This toolkit does **not** change machine-wide execution policy and does not install software.

---

## Out of scope

Charts, pivot tables, macros, password-protected workbooks, and pure OpenXML (no Excel installed).
