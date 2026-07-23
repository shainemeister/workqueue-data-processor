#requires -Version 5.1
<#
.SYNOPSIS
    Export a CSV file to Excel (wrapper around Export-ExcelFromCsv).

.DESCRIPTION
    Thin script for menu and legacy callers. Core logic lives in ExcelToolkit.psm1.
    Prefer ExcelToolkit.ps1 (CLI) or Import-Module ExcelToolkit.psm1 from automation.

.NOTES
    See CLI-GUIDE.md and README.md.
#>

[CmdletBinding()]
param(
    [string]$CsvPath,
    [string]$SchemaPath,
    [ValidateSet('Auto', 'Json', 'Csv')]
    [string]$SchemaFormat = 'Auto',
    [string]$OutputPath,
    [switch]$UseDisplayNames,
    [string]$DisplayNameProperty = '',
    [string]$SheetName = 'Data',
    [switch]$Visible,
    [switch]$DryRun,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path -Parent $scriptDir
$modulePath = Join-Path $scriptDir 'ExcelToolkit.psm1'

if (-not (Test-Path -LiteralPath $modulePath)) {
    throw ("ExcelToolkit.psm1 not found: {0}" -f $modulePath)
}
Import-Module -Name $modulePath -Force -ErrorAction Stop

# Defaults for interactive / menu use
if ([string]::IsNullOrWhiteSpace($CsvPath)) {
    $preferred = Join-Path $repoRoot 'wq_data.csv'
    if (Test-Path -LiteralPath $preferred) {
        $CsvPath = $preferred
    }
    else {
        $first = Get-ChildItem -LiteralPath $repoRoot -Filter '*.csv' -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $first) { $CsvPath = $first.FullName } else { $CsvPath = $preferred }
    }
}
if ([string]::IsNullOrWhiteSpace($SchemaPath)) {
    $preferred = Join-Path $repoRoot 'wq_schema.json'
    if (Test-Path -LiteralPath $preferred) {
        $SchemaPath = $preferred
    }
    else {
        $first = Get-ChildItem -LiteralPath $repoRoot -Filter '*schema*.json' -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $first) { $SchemaPath = $first.FullName } else { $SchemaPath = $preferred }
    }
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $repoRoot 'output\export.xlsx'
}

$OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)

# Collision policy: unique numerical suffix unless -Force (no y/N overwrite prompt)
Write-Host '=== Export-CsvToExcel ===' -ForegroundColor Cyan
Write-Host ("CSV     : {0}" -f $CsvPath)
Write-Host ("Schema  : {0}" -f $SchemaPath)
Write-Host ("Output  : {0}" -f $OutputPath)
Write-Host ("Display : {0}" -f [bool]$UseDisplayNames)
Write-Host ("DryRun  : {0}" -f [bool]$DryRun)
Write-Host ("Force   : {0}" -f [bool]$Force)

$params = @{
    CsvPath      = $CsvPath
    OutputPath   = $OutputPath
    SchemaFormat = $SchemaFormat
    SheetName    = $SheetName
}
if (-not [string]::IsNullOrWhiteSpace($SchemaPath)) { $params['SchemaPath'] = $SchemaPath }
if ($UseDisplayNames) { $params['UseDisplayNames'] = $true }
if (-not [string]::IsNullOrWhiteSpace($DisplayNameProperty)) { $params['DisplayNameProperty'] = $DisplayNameProperty }
if ($Visible) { $params['Visible'] = $true }
if ($DryRun) { $params['DryRun'] = $true }
if ($Force) { $params['Force'] = $true }

# First-run diagnostics gate (pass certificate under diagnostics\)
$gate = Assert-ExcelToolkitDiagnosticsPass
if (-not $gate.GateOk) {
    Write-Host ''
    Write-Host ("FAIL: {0}" -f $gate.Message) -ForegroundColor Red
    if (-not [string]::IsNullOrWhiteSpace([string]$gate.ReportTextPath)) {
        Write-Host ("  See: {0}" -f $gate.ReportTextPath) -ForegroundColor Yellow
    }
    exit 1
}
if ($gate.GateMode -eq 'ran') {
    Write-Host ("Diagnostics auto-ran and passed. Report: {0}" -f $gate.ReportTextPath) -ForegroundColor DarkGray
}

$r = Export-ExcelFromCsv @params

if ($r.Success) {
    Write-Host ''
    Write-Host ("OK: {0}" -f $r.Message) -ForegroundColor Green
    Write-Host ("  Output  : {0}" -f $r.OutputPath)
    if ($r.PathAdjusted) {
        Write-Host ("  Requested: {0}" -f $r.RequestedOutputPath)
    }
    Write-Host ("  Rows    : {0}" -f $r.RowCount)
    Write-Host ("  Columns : {0}" -f $r.ColumnCount)
    if ($r.HeadersSample -and @($r.HeadersSample).Count -gt 0) {
        Write-Host ("  Headers : {0}" -f ($r.HeadersSample -join ', '))
    }
    exit 0
}

Write-Host ''
Write-Host ("FAIL: {0}" -f $r.Message) -ForegroundColor Red
if ($r.Message -match 'locked|Close Excel') {
    Write-Host 'Close Excel completely and try again. Tools never force-kill Excel.' -ForegroundColor Yellow
}
exit 1
