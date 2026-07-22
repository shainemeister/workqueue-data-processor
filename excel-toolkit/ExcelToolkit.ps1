#requires -Version 5.1
<#
.SYNOPSIS
    Command-line interface for the Excel Toolkit.

.DESCRIPTION
    Thin CLI for automation (Python, Task Scheduler, other scripts).
    PowerShell scripts in the same process should prefer:

        Import-Module .\ExcelToolkit.psm1 -Force

    Exit codes:
        0  success
        1  validation / usage / preflight failure
        2  runtime failure

.PARAMETER Command
    Verb: version | probe | export-csv | import-excel | help

.EXAMPLE
    .\ExcelToolkit.ps1 version

.EXAMPLE
    .\ExcelToolkit.ps1 probe -CsvPath ..\wq_data.csv -Json

.EXAMPLE
    .\ExcelToolkit.ps1 export-csv -CsvPath ..\wq_data.csv -OutputPath ..\output\export.xlsx -Json

.EXAMPLE
    .\ExcelToolkit.ps1 import-excel -ExcelPath ..\import\wq_synthetic_data.xlsx -OutputPath ..\import\from_xlsx_smoke.csv -Json

.NOTES
    See CLI-GUIDE.md for full syntax and examples.
    -Password is never written to JSON, host success lines, or logs.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('version', 'probe', 'export-csv', 'import-excel', 'help', '')]
    [string]$Command = 'help',

    [string]$CsvPath,
    [string]$ExcelPath,
    [string]$SchemaPath,
    [ValidateSet('Auto', 'Json', 'Csv')]
    [string]$SchemaFormat = 'Auto',
    [string]$OutputPath,
    [switch]$UseDisplayNames,
    [string]$DisplayNameProperty = '',
    [string]$SheetName = 'Data',
    [string]$Password = '',
    [switch]$Visible,
    [switch]$DryRun,
    [switch]$Force,
    [switch]$Json,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$exitCode = 0

function Write-CliHost {
    param([string]$Message, [ConsoleColor]$Color = [ConsoleColor]::Gray)
    if (-not $Quiet -and -not $Json) {
        Write-Host $Message -ForegroundColor $Color
    }
}

function ConvertTo-CliSecurePassword {
    param([string]$Plain)
    if ([string]::IsNullOrEmpty($Plain)) {
        return $null
    }
    if (Get-Command -Name ConvertTo-SecureStringPlain -ErrorAction SilentlyContinue) {
        return ConvertTo-SecureStringPlain -PlainPassword $Plain
    }
    $secure = New-Object System.Security.SecureString
    foreach ($ch in $Plain.ToCharArray()) {
        $secure.AppendChar($ch)
    }
    $secure.MakeReadOnly()
    return $secure
}

function Show-Help {
    @'
Excel Toolkit CLI
  Usage:  ExcelToolkit.ps1 <command> [options]

Commands:
  version                 Print toolkit version
  probe                   Run environment preflight (Excel COM, paths)
  export-csv              Export a data CSV to .xlsx
  import-excel            Import an Excel workbook to .csv
  help                    Show this help

Common options:
  -Json                   Emit one JSON object on stdout
  -Quiet                  Suppress human-readable host text (non-JSON)

probe options:
  -CsvPath <path>         Optional CSV to validate
  -SchemaPath <path>      Optional schema to validate

export-csv options:
  -CsvPath <path>         Input data CSV (required)
  -OutputPath <path>      Output .xlsx (default: ..\output\export.xlsx)
  -SchemaPath <path>      Optional schema for display names
  -SchemaFormat Auto|Json|Csv
  -UseDisplayNames        Apply schema display labels
  -DisplayNameProperty    Preferred schema label property
  -SheetName <name>       Worksheet name (default Data)
  -Password <text>        Optional workbook open password (not logged)
  -Visible                Show Excel UI
  -DryRun                 Validate only; do not write
  -Force                  Overwrite existing output file (default: refuse)

import-excel options:
  -ExcelPath <path>       Input .xlsx / .xls (required)
  -OutputPath <path>      Output .csv (default: ..\import\<excel-basename>.csv)
  -SheetName <name>       Worksheet name (default: first sheet)
  -Password <text>        Workbook password for automation (not logged)
  -Visible                Show Excel UI
  -DryRun                 Validate open only; do not write CSV
  -Force                  Overwrite existing output file (default: refuse)

  Password notes:
  - Interactive runs prompt when a workbook needs a password and -Password is omitted.
  - With -Json (non-interactive), supply -Password when the file is protected.
  - Password is never included in JSON output.

  Output safety:
  - Existing destination files are not overwritten unless -Force is set.
  - Omitting -OutputPath on import writes under import\ using the workbook base name.

Exit codes:  0 success | 1 validation | 2 runtime

Docs:  CLI-GUIDE.md
'@ | Write-Host
}

try {
    $here = $PSScriptRoot
    if ([string]::IsNullOrWhiteSpace($here)) {
        $here = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    $modulePath = Join-Path $here 'ExcelToolkit.psm1'
    if (-not (Test-Path -LiteralPath $modulePath)) {
        throw ("ExcelToolkit.psm1 not found: {0}" -f $modulePath)
    }
    Import-Module -Name $modulePath -Force -ErrorAction Stop

    # ExcelCom is loaded by ExcelToolkit.psm1 for export/import/probe internals
    $excelComPath = Join-Path $here 'ExcelCom.psm1'
    if (Test-Path -LiteralPath $excelComPath) {
        Import-Module -Name $excelComPath -Force -ErrorAction SilentlyContinue
    }

    $repoRoot = Split-Path -Parent $here
    $securePassword = ConvertTo-CliSecurePassword -Plain $Password
    # Clear plain CLI param from further accidental use in messages
    $Password = $null

    switch ($Command) {
        'help' {
            Show-Help
            $exitCode = 0
        }
        'version' {
            $ver = Get-ExcelToolkitVersion
            if ($Json) {
                [pscustomobject]@{ Success = $true; Version = $ver; Command = 'version' } | ConvertTo-Json -Compress
            }
            else {
                Write-Output $ver
            }
            $exitCode = 0
        }
        'probe' {
            Write-CliHost 'Excel Toolkit probe...' Cyan
            $probe = Test-ExcelComEnvironment -CsvPath $CsvPath -SchemaPath $SchemaPath
            $obj = [pscustomobject]@{
                Success = [bool]$probe.Passed
                Command = 'probe'
                Version = (Get-ExcelToolkitVersion)
                Checks  = @($probe.Checks)
                Message = $(if ($probe.Passed) { 'Preflight passed.' } else { 'Preflight failed.' })
            }
            if ($Json) {
                $obj | ConvertTo-Json -Compress -Depth 6
            }
            else {
                foreach ($c in $probe.Checks) {
                    $tag = if ($c.Passed) { 'PASS' } else { 'FAIL' }
                    Write-Host ("  [{0}] {1}: {2}" -f $tag, $c.Name, $c.Detail)
                }
                if ($probe.Passed) {
                    Write-Host 'OK' -ForegroundColor Green
                }
                else {
                    Write-Host 'FAIL' -ForegroundColor Red
                }
            }
            $exitCode = $(if ($probe.Passed) { 0 } else { 1 })
        }
        'export-csv' {
            if ([string]::IsNullOrWhiteSpace($CsvPath)) {
                throw 'export-csv requires -CsvPath'
            }
            if ([string]::IsNullOrWhiteSpace($OutputPath)) {
                $OutputPath = Join-Path $repoRoot 'output\export.xlsx'
            }

            Write-CliHost ("export-csv: {0} -> {1}" -f $CsvPath, $OutputPath) Cyan

            $exportParams = @{
                CsvPath      = $CsvPath
                OutputPath   = $OutputPath
                SchemaFormat = $SchemaFormat
                SheetName    = $SheetName
                DryRun       = $DryRun
                Visible      = $Visible
                Force        = $Force
            }
            if (-not [string]::IsNullOrWhiteSpace($SchemaPath)) {
                $exportParams['SchemaPath'] = $SchemaPath
            }
            if ($UseDisplayNames) {
                $exportParams['UseDisplayNames'] = $true
            }
            if (-not [string]::IsNullOrWhiteSpace($DisplayNameProperty)) {
                $exportParams['DisplayNameProperty'] = $DisplayNameProperty
            }
            if ($null -ne $securePassword) {
                $exportParams['Password'] = $securePassword
            }

            $r = Export-ExcelFromCsv @exportParams
            $payload = [pscustomobject]@{
                Success       = [bool]$r.Success
                Command       = 'export-csv'
                Version       = (Get-ExcelToolkitVersion)
                OutputPath    = $r.OutputPath
                RowCount      = $r.RowCount
                ColumnCount   = $r.ColumnCount
                DryRun        = [bool]$r.DryRun
                Message       = $r.Message
                HeadersSample = @($r.HeadersSample)
                SheetName     = $r.SheetName
            }

            if ($Json) {
                $payload | ConvertTo-Json -Compress -Depth 6
            }
            else {
                if ($r.Success) {
                    Write-Host ("OK: {0}" -f $r.Message) -ForegroundColor Green
                    Write-Host ("  Output : {0}" -f $r.OutputPath)
                    Write-Host ("  Rows   : {0}" -f $r.RowCount)
                    Write-Host ("  Cols   : {0}" -f $r.ColumnCount)
                    if ($r.HeadersSample -and $r.HeadersSample.Count -gt 0) {
                        Write-Host ("  Headers: {0}" -f ($r.HeadersSample -join ', '))
                    }
                }
                else {
                    Write-Host ("FAIL: {0}" -f $r.Message) -ForegroundColor Red
                }
            }

            if ($r.Success) {
                $exitCode = 0
            }
            else {
                if ($r.Message -match 'not found|required|No columns|preflight|Schema file|password|already exists') {
                    $exitCode = 1
                }
                else {
                    $exitCode = 2
                }
            }
        }
        'import-excel' {
            if ([string]::IsNullOrWhiteSpace($ExcelPath)) {
                throw 'import-excel requires -ExcelPath'
            }
            if ([string]::IsNullOrWhiteSpace($OutputPath)) {
                $baseName = [System.IO.Path]::GetFileNameWithoutExtension($ExcelPath)
                if ([string]::IsNullOrWhiteSpace($baseName)) {
                    $baseName = 'import'
                }
                $importDir = Join-Path $repoRoot 'import'
                if (-not (Test-Path -LiteralPath $importDir)) {
                    New-Item -ItemType Directory -Path $importDir -Force | Out-Null
                }
                $OutputPath = Join-Path $importDir ("{0}.csv" -f $baseName)
            }

            Write-CliHost ("import-excel: {0} -> {1}" -f $ExcelPath, $OutputPath) Cyan

            # Default SheetName for export is 'Data'; for import empty means first sheet
            $importSheet = $SheetName
            if ($importSheet -eq 'Data' -and -not $PSBoundParameters.ContainsKey('SheetName')) {
                $importSheet = ''
            }

            $importParams = @{
                ExcelPath            = $ExcelPath
                OutputPath           = $OutputPath
                DryRun               = $DryRun
                Visible              = $Visible
                Force                = $Force
                AllowPasswordPrompt  = (-not $Json)
            }
            if (-not [string]::IsNullOrWhiteSpace($importSheet)) {
                $importParams['SheetName'] = $importSheet
            }
            if ($null -ne $securePassword) {
                $importParams['Password'] = $securePassword
            }

            $r = Import-CsvFromExcel @importParams
            $payload = [pscustomobject]@{
                Success       = [bool]$r.Success
                Command       = 'import-excel'
                Version       = (Get-ExcelToolkitVersion)
                ExcelPath     = $r.ExcelPath
                OutputPath    = $r.OutputPath
                RowCount      = $r.RowCount
                ColumnCount   = $r.ColumnCount
                DryRun        = [bool]$r.DryRun
                Message       = $r.Message
                HeadersSample = @($r.HeadersSample)
                SheetName     = $r.SheetName
                PasswordUsed  = [bool]$r.PasswordUsed
            }

            if ($Json) {
                $payload | ConvertTo-Json -Compress -Depth 6
            }
            else {
                if ($r.Success) {
                    Write-Host ("OK: {0}" -f $r.Message) -ForegroundColor Green
                    Write-Host ("  Excel  : {0}" -f $r.ExcelPath)
                    Write-Host ("  Output : {0}" -f $r.OutputPath)
                    Write-Host ("  Sheet  : {0}" -f $r.SheetName)
                    Write-Host ("  Rows   : {0}" -f $r.RowCount)
                    Write-Host ("  Cols   : {0}" -f $r.ColumnCount)
                    if ($r.PasswordUsed) {
                        Write-Host '  Password: used (value not shown)'
                    }
                    if ($r.HeadersSample -and $r.HeadersSample.Count -gt 0) {
                        Write-Host ("  Headers: {0}" -f ($r.HeadersSample -join ', '))
                    }
                }
                else {
                    Write-Host ("FAIL: {0}" -f $r.Message) -ForegroundColor Red
                }
            }

            if ($r.Success) {
                $exitCode = 0
            }
            else {
                if ($r.Message -match 'not found|required|password|preflight|No columns|interactive prompt|already exists') {
                    $exitCode = 1
                }
                else {
                    $exitCode = 2
                }
            }
        }
        default {
            Show-Help
            $exitCode = 1
        }
    }
}
catch {
    $err = $_.Exception.Message
    if ($Json) {
        [pscustomobject]@{
            Success = $false
            Command = $Command
            Message = $err
        } | ConvertTo-Json -Compress
    }
    else {
        Write-Host ("FAIL: {0}" -f $err) -ForegroundColor Red
    }
    $exitCode = 1
}
finally {
    $securePassword = $null
}

exit $exitCode
