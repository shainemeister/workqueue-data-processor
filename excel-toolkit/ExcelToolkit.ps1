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
    Verb: version | probe | diagnostics | export-csv | import-excel | help

.EXAMPLE
    .\ExcelToolkit.ps1 version

.EXAMPLE
    .\ExcelToolkit.ps1 probe -CsvPath ..\wq_data.csv -Json

.EXAMPLE
    .\ExcelToolkit.ps1 diagnostics -Json

.EXAMPLE
    .\ExcelToolkit.ps1 export-csv -CsvPath ..\wq_data.csv -OutputPath ..\output\export.xlsx -Json

.EXAMPLE
    .\ExcelToolkit.ps1 import-excel -ExcelPath ..\import\wq_synthetic_data.xlsx -OutputPath ..\import\from_xlsx_smoke.csv -Json

.NOTES
    See CLI-GUIDE.md for full syntax and examples.
    -Password is never written to JSON, host success lines, or logs.
    export-csv / import-excel auto-run diagnostics once until a pass certificate exists.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('version', 'probe', 'diagnostics', 'export-csv', 'import-excel', 'help', '')]
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
    [switch]$ForceDiagnostics,
    [switch]$SkipDiagnosticsGate,
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
  diagnostics             Enterprise readiness suite; write diagnostics\last_diagnostics.*
  export-csv              Export a data CSV to .xlsx
  import-excel            Import an Excel workbook to .csv
  help                    Show this help

Common options:
  -Json                   Emit one JSON object on stdout
  -Quiet                  Suppress human-readable host text (non-JSON)

probe options:
  -CsvPath <path>         Optional CSV to validate
  -SchemaPath <path>      Optional schema to validate

diagnostics options:
  -Force                  Re-run and overwrite certificate even if a valid pass exists
  -CsvPath / -SchemaPath  Optional path checks (same as probe)
  -Json / -Quiet

export-csv / import-excel gate:
  First run auto-executes diagnostics when no valid pass certificate exists.
  -ForceDiagnostics       Re-run diagnostics before this command
  -SkipDiagnosticsGate    Emergency/support only (skip pass requirement)

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
  -Force                  Replace exact OutputPath if it exists (default: unique suffix)

import-excel options:
  -ExcelPath <path>       Input .xlsx / .xls (required)
  -OutputPath <path>      Output .csv (default: ..\import\<excel-basename>.csv)
  -SheetName <name>       Worksheet name (default: first sheet)
  -Password <text>        Workbook password for automation (not logged)
  -Visible                Show Excel UI
  -DryRun                 Validate open only; do not write CSV
  -Force                  Replace exact OutputPath if it exists (default: unique suffix)

  Password notes:
  - Interactive runs prompt when a workbook needs a password and -Password is omitted.
  - With -Json (non-interactive), supply -Password when the file is protected.
  - Password is never included in JSON output.

  Output safety:
  - Existing destinations are not replaced by default; a free path name_1.ext is used.
  - -Force overwrites the exact path (automation only).
  - Omitting -OutputPath on import writes under import\ using the workbook base name.

Exit codes:  0 success | 1 validation | 2 runtime

Docs:  CLI-GUIDE.md
'@ | Write-Host
}

function Invoke-CliDiagnosticsGate {
    <#
    .SYNOPSIS
        Run Assert-ExcelToolkitDiagnosticsPass for gated CLI commands.
        Returns $true if the command may proceed; sets $script:exitCode on block.
    #>
    param(
        [string]$OptionalCsvPath,
        [string]$OptionalSchemaPath
    )

    $gateParams = @{
        Force = $ForceDiagnostics
        Skip  = $SkipDiagnosticsGate
    }
    if (-not [string]::IsNullOrWhiteSpace($OptionalCsvPath)) {
        $gateParams['CsvPath'] = $OptionalCsvPath
    }
    if (-not [string]::IsNullOrWhiteSpace($OptionalSchemaPath)) {
        $gateParams['SchemaPath'] = $OptionalSchemaPath
    }

    $gate = Assert-ExcelToolkitDiagnosticsPass @gateParams

    if ($SkipDiagnosticsGate -and -not $Quiet -and -not $Json) {
        Write-Host 'WARNING: Diagnostics gate skipped (-SkipDiagnosticsGate). Emergency/support use only.' -ForegroundColor Yellow
    }

    if ($gate.GateOk) {
        if ($gate.GateMode -eq 'ran' -and -not $Quiet -and -not $Json) {
            Write-Host ("Diagnostics auto-ran and passed. Report: {0}" -f $gate.ReportTextPath) -ForegroundColor DarkGray
        }
        return $gate
    }

    # Blocked
    $blocked = [ordered]@{
        Success                     = $false
        Command                     = $Command
        Version                     = (Get-ExcelToolkitVersion)
        Message                     = [string]$gate.Message
        DiagnosticsGate             = [string]$gate.GateMode
        DiagnosticsGateSkipped      = [bool]$gate.DiagnosticsGateSkipped
        DiagnosticsReportJsonPath   = $gate.ReportJsonPath
        DiagnosticsReportTextPath   = $gate.ReportTextPath
    }
    if ($Json) {
        [pscustomobject]$blocked | ConvertTo-Json -Compress -Depth 6
    }
    else {
        Write-Host ("FAIL: {0}" -f $gate.Message) -ForegroundColor Red
        if (-not [string]::IsNullOrWhiteSpace([string]$gate.ReportTextPath)) {
            Write-Host ("  See: {0}" -f $gate.ReportTextPath) -ForegroundColor Yellow
        }
    }
    $script:exitCode = 1
    return $null
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
        'diagnostics' {
            Write-CliHost 'Excel Toolkit diagnostics...' Cyan
            # Always re-run and write reports (certificate refresh). -Force is accepted for symmetry with KPI.
            $diag = Invoke-ExcelToolkitDiagnostics -Write $true -CsvPath $CsvPath -SchemaPath $SchemaPath
            $obj = [pscustomobject]@{
                Success                   = [bool]$diag.Success
                OverallPass               = [bool]$diag.OverallPass
                Command                   = 'diagnostics'
                Version                   = (Get-ExcelToolkitVersion)
                ToolkitVersion            = [string]$diag.ToolkitVersion
                PowerShellVersion         = [string]$diag.PowerShellVersion
                ReportVersion             = [int]$diag.ReportVersion
                CriticalFailed            = @($diag.CriticalFailed)
                Checks                    = @($diag.Checks)
                Message                   = [string]$diag.Message
                DiagnosticsReportJsonPath = $diag.ReportJsonPath
                DiagnosticsReportTextPath = $diag.ReportTextPath
            }
            if ($Json) {
                $obj | ConvertTo-Json -Compress -Depth 8
            }
            else {
                foreach ($c in @($diag.Checks)) {
                    $tag = if ($c.Passed) { 'PASS' } else { 'FAIL' }
                    Write-Host ("  [{0}] {1}: {2}" -f $tag, $c.Name, $c.Detail)
                }
                if ($diag.OverallPass) {
                    Write-Host 'OK' -ForegroundColor Green
                    if ($diag.ReportTextPath) {
                        Write-Host ("  Report: {0}" -f $diag.ReportTextPath) -ForegroundColor DarkGray
                    }
                }
                else {
                    Write-Host 'FAIL' -ForegroundColor Red
                    if ($diag.ReportTextPath) {
                        Write-Host ("  Report: {0}" -f $diag.ReportTextPath) -ForegroundColor Yellow
                    }
                }
            }
            $exitCode = $(if ($diag.OverallPass) { 0 } else { 1 })
        }
        'export-csv' {
            if ([string]::IsNullOrWhiteSpace($CsvPath)) {
                throw 'export-csv requires -CsvPath'
            }
            if ([string]::IsNullOrWhiteSpace($OutputPath)) {
                $OutputPath = Join-Path $repoRoot 'output\export.xlsx'
            }

            $gate = Invoke-CliDiagnosticsGate -OptionalCsvPath $CsvPath -OptionalSchemaPath $SchemaPath
            if ($null -eq $gate) {
                break
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
            $payloadHt = @{
                Success             = [bool]$r.Success
                Command             = 'export-csv'
                Version             = (Get-ExcelToolkitVersion)
                OutputPath          = $r.OutputPath
                RequestedOutputPath = $r.RequestedOutputPath
                PathAdjusted        = [bool]$r.PathAdjusted
                RowCount            = $r.RowCount
                ColumnCount         = $r.ColumnCount
                DryRun              = [bool]$r.DryRun
                Message             = $r.Message
                HeadersSample       = @($r.HeadersSample)
                SheetName           = $r.SheetName
            }
            $null = Add-ExcelToolkitGateFields -Target $payloadHt -Gate $gate
            $payload = [pscustomobject]$payloadHt

            if ($Json) {
                $payload | ConvertTo-Json -Compress -Depth 6
            }
            else {
                if ($r.Success) {
                    Write-Host ("OK: {0}" -f $r.Message) -ForegroundColor Green
                    Write-Host ("  Output : {0}" -f $r.OutputPath)
                    if ($r.PathAdjusted) {
                        Write-Host ("  Requested: {0}" -f $r.RequestedOutputPath)
                    }
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
                if ($r.Message -match 'not found|required|No columns|preflight|Schema file|password|free output path') {
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

            $gate = Invoke-CliDiagnosticsGate -OptionalSchemaPath $SchemaPath
            if ($null -eq $gate) {
                break
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
            $payloadHt = @{
                Success             = [bool]$r.Success
                Command             = 'import-excel'
                Version             = (Get-ExcelToolkitVersion)
                ExcelPath           = $r.ExcelPath
                OutputPath          = $r.OutputPath
                RequestedOutputPath = $r.RequestedOutputPath
                PathAdjusted        = [bool]$r.PathAdjusted
                RowCount            = $r.RowCount
                ColumnCount         = $r.ColumnCount
                DryRun              = [bool]$r.DryRun
                Message             = $r.Message
                HeadersSample       = @($r.HeadersSample)
                SheetName           = $r.SheetName
                PasswordUsed        = [bool]$r.PasswordUsed
            }
            $null = Add-ExcelToolkitGateFields -Target $payloadHt -Gate $gate
            $payload = [pscustomobject]$payloadHt

            if ($Json) {
                $payload | ConvertTo-Json -Compress -Depth 6
            }
            else {
                if ($r.Success) {
                    Write-Host ("OK: {0}" -f $r.Message) -ForegroundColor Green
                    Write-Host ("  Excel  : {0}" -f $r.ExcelPath)
                    Write-Host ("  Output : {0}" -f $r.OutputPath)
                    if ($r.PathAdjusted) {
                        Write-Host ("  Requested: {0}" -f $r.RequestedOutputPath)
                    }
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
                if ($r.Message -match 'not found|required|password|preflight|No columns|interactive prompt|free output path') {
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
