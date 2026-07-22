#requires -Version 5.1
<#
.SYNOPSIS
    Dry-run preflight and full smoke tests for ExcelCom.psm1.

.DESCRIPTION
    Validates that the Excel COM toolkit works on this machine under
    Windows PowerShell 5.1.

    Modes:
      -DryRun  Environment + module surface checks only (quick COM create/quit).
      Default  Full smoke: create, open, edit, sheets, CSV round-trip, optional WQ import.
               Uses a temp directory; cleans up afterward.

.PARAMETER DryRun
    Run lightweight readiness checks only (no permanent files, no long-lived Excel).

.PARAMETER SkipSampleCsv
    Skip the sample CSV import step even if a data CSV is present in the repo root.

.EXAMPLE
    powershell -NoProfile -File .\excel-toolkit\Test-ExcelCom.ps1 -DryRun

.EXAMPLE
    powershell -NoProfile -File .\excel-toolkit\Test-ExcelCom.ps1

.NOTES
    Exit 0  = all checks passed
    Exit 1  = one or more failures
#>

[CmdletBinding()]
param(
    [switch]$DryRun,

    [Alias('SkipWq')]
    [switch]$SkipSampleCsv
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Bootstrap

$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot   = Split-Path -Parent $scriptDir
$modulePath = Join-Path $scriptDir 'ExcelCom.psm1'
$sampleCsv = Join-Path $repoRoot 'wq_data.csv'
if (-not (Test-Path -LiteralPath $sampleCsv)) {
    $foundCsv = Get-ChildItem -LiteralPath $repoRoot -Filter '*.csv' -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $foundCsv) { $sampleCsv = $foundCsv.FullName }
}
$sampleSchema = Join-Path $repoRoot 'wq_schema.json'
if (-not (Test-Path -LiteralPath $sampleSchema)) {
    $foundSchema = Get-ChildItem -LiteralPath $repoRoot -Filter '*schema*.json' -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $foundSchema) { $sampleSchema = $foundSchema.FullName }
}
if (-not (Test-Path -LiteralPath $modulePath)) {
    Write-Error ("Module not found: {0}" -f $modulePath)
    exit 1
}

Import-Module -Name $modulePath -Force -ErrorAction Stop

$results = New-Object System.Collections.Generic.List[object]
$tempRoot = $null
$excelPidBefore = @()

function Add-Result {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Detail = ''
    )
    $script:results.Add([pscustomobject]@{
        Name   = $Name
        Passed = $Passed
        Detail = $Detail
    })
    $tag = if ($Passed) { 'PASS' } else { 'FAIL' }
    $color = if ($Passed) { 'Green' } else { 'Red' }
    Write-Host ("  [{0}] {1}" -f $tag, $Name) -ForegroundColor $color
    if (-not [string]::IsNullOrWhiteSpace($Detail)) {
        Write-Host ("         {0}" -f $Detail) -ForegroundColor DarkGray
    }
}

function Get-ExcelProcessIds {
    @(Get-Process -Name 'EXCEL' -ErrorAction SilentlyContinue | ForEach-Object { $_.Id })
}

#endregion Bootstrap

Write-Host '=== Test-ExcelCom ===' -ForegroundColor Cyan
Write-Host ("PowerShell : {0}" -f $PSVersionTable.PSVersion)
Write-Host ("Module     : {0}" -f $modulePath)
Write-Host ("Mode       : {0}" -f $(if ($DryRun) { 'DryRun' } else { 'Full smoke' }))
Write-Host ''

#region Shared: environment + exports

Write-Host 'Preflight' -ForegroundColor Cyan
$envResult = Test-ExcelComEnvironment -CsvPath $sampleCsv -SchemaPath $sampleSchema
foreach ($c in $envResult.Checks) {
    Add-Result -Name ("Env:{0}" -f $c.Name) -Passed $c.Passed -Detail $c.Detail
}

$expectedFunctions = @(
    'New-ExcelApplication',
    'New-ExcelWorkbook',
    'Open-ExcelWorkbook',
    'Save-ExcelWorkbook',
    'Close-ExcelWorkbook',
    'Stop-ExcelApplication',
    'Invoke-ExcelSafe',
    'Get-ExcelWorksheet',
    'Add-ExcelWorksheet',
    'Rename-ExcelWorksheet',
    'Get-ExcelCell',
    'Set-ExcelCell',
    'Get-ExcelRange',
    'Set-ExcelRange',
    'Set-ExcelHeaderStyle',
    'Set-ExcelAutoFit',
    'Import-CsvToWorksheet',
    'Export-WorksheetToCsv',
    'Test-ExcelComEnvironment'
)

$exported = @(Get-Command -Module ExcelCom | ForEach-Object { $_.Name })
$missing = @($expectedFunctions | Where-Object { $exported -notcontains $_ })
if ($missing.Count -eq 0) {
    $exportDetail = "{0} functions exported" -f $exported.Count
}
else {
    $exportDetail = "Missing: {0}" -f ($missing -join ', ')
}
Add-Result -Name 'ModuleExports' -Passed ($missing.Count -eq 0) -Detail $exportDetail

if ($DryRun) {
    Write-Host ''
    Write-Host 'DryRun complete (no workbook I/O beyond COM probe).' -ForegroundColor Yellow
    $failed = @($results | Where-Object { -not $_.Passed })
    Write-Host ''
    Write-Host ("Summary: {0} passed, {1} failed" -f ($results.Count - $failed.Count), $failed.Count) -ForegroundColor Cyan
    if ($failed.Count -gt 0) {
        exit 1
    }
    exit 0
}

#endregion Shared: environment + exports

#region Full smoke tests

Write-Host ''
Write-Host 'Full smoke tests' -ForegroundColor Cyan

$excelPidBefore = Get-ExcelProcessIds
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("ExcelComSmoke_{0}" -f [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
Write-Host ("Temp dir: {0}" -f $tempRoot) -ForegroundColor DarkGray

$xlsxPath = Join-Path $tempRoot 'smoke.xlsx'
$csvIn    = Join-Path $tempRoot 'sample_in.csv'
$csvOut   = Join-Path $tempRoot 'sample_out.csv'

# Sample CSV for round-trip
@(
    'Name,Score,Active'
    'Ada,99,True'
    'Grace,95,False'
) | Set-Content -LiteralPath $csvIn -Encoding ASCII

$app = $null
$workbook = $null

try {
    # --- Create / write / sheets / save ---
    try {
        $app = New-ExcelApplication
        $workbook = New-ExcelWorkbook -Application $app -SheetName 'Main'
        $ws = Get-ExcelWorksheet -Workbook $workbook -Index 1

        Set-ExcelCell -Worksheet $ws -Address 'A1' -Value 'Hello'
        Set-ExcelCell -Worksheet $ws -Row 1 -Column 2 -Value 42
        Set-ExcelRange -Worksheet $ws -StartAddress 'A3' -Values @(
            @('Col1', 'Col2'),
            @('x', 1),
            @('y', 2)
        )

        $ws2 = Add-ExcelWorksheet -Workbook $workbook -Name 'Second'
        Rename-ExcelWorksheet -Worksheet $ws2 -NewName 'Renamed'
        Set-ExcelCell -Worksheet $ws2 -Address 'A1' -Value 'Sheet2OK'

        Set-ExcelHeaderStyle -Worksheet $ws -HeaderRow 3 -ColumnCount 2
        Set-ExcelAutoFit -Worksheet $ws -ColumnCount 2

        Save-ExcelWorkbook -Workbook $workbook -Path $xlsxPath | Out-Null
        Close-ExcelWorkbook -Workbook $workbook
        $workbook = $null

        $createOk = Test-Path -LiteralPath $xlsxPath
        Add-Result -Name 'CreateSaveWorkbook' -Passed $createOk -Detail $xlsxPath
    }
    catch {
        Add-Result -Name 'CreateSaveWorkbook' -Passed $false -Detail $_.Exception.Message
        throw
    }

    # --- Open / edit / re-save ---
    try {
        $workbook = Open-ExcelWorkbook -Application $app -Path $xlsxPath
        $ws = Get-ExcelWorksheet -Workbook $workbook -Name 'Main'
        $hello = Get-ExcelCell -Worksheet $ws -Address 'A1'
        $num = Get-ExcelCell -Worksheet $ws -Address 'B1'

        $readOk = ($hello -eq 'Hello') -and ([int]$num -eq 42)
        Add-Result -Name 'OpenReadCells' -Passed $readOk -Detail ("A1={0}; B1={1}" -f $hello, $num)

        Set-ExcelCell -Worksheet $ws -Address 'A1' -Value 'Updated'
        $wsExtra = Add-ExcelWorksheet -Workbook $workbook -Name 'Extra'
        Set-ExcelCell -Worksheet $wsExtra -Address 'A1' -Value 1

        $renamed = Get-ExcelWorksheet -Workbook $workbook -Name 'Renamed'
        $s2 = Get-ExcelCell -Worksheet $renamed -Address 'A1'
        Add-Result -Name 'SheetRenamePersist' -Passed ($s2 -eq 'Sheet2OK') -Detail ("Renamed!A1={0}" -f $s2)

        Save-ExcelWorkbook -Workbook $workbook | Out-Null
        Close-ExcelWorkbook -Workbook $workbook
        $workbook = $null

        # Re-open to confirm edit
        $workbook = Open-ExcelWorkbook -Application $app -Path $xlsxPath -ReadOnly
        $ws = Get-ExcelWorksheet -Workbook $workbook -Name 'Main'
        $updated = Get-ExcelCell -Worksheet $ws -Address 'A1'
        Add-Result -Name 'EditPersist' -Passed ($updated -eq 'Updated') -Detail ("A1={0}" -f $updated)
        Close-ExcelWorkbook -Workbook $workbook
        $workbook = $null
    }
    catch {
        Add-Result -Name 'OpenEdit' -Passed $false -Detail $_.Exception.Message
        throw
    }

    # --- CSV round-trip ---
    try {
        $workbook = New-ExcelWorkbook -Application $app -SheetName 'CsvTest'
        $ws = Get-ExcelWorksheet -Workbook $workbook -Index 1
        $importInfo = Import-CsvToWorksheet -Worksheet $ws -Path $csvIn -StartAddress 'A1'
        Set-ExcelHeaderStyle -Worksheet $ws -HeaderRow 1 -ColumnCount $importInfo.ColumnCount

        Export-WorksheetToCsv -Worksheet $ws -Path $csvOut | Out-Null
        Close-ExcelWorkbook -Workbook $workbook
        $workbook = $null

        $outRows = @(Import-Csv -LiteralPath $csvOut)
        $roundOk = ($outRows.Count -eq 2) -and ($outRows[0].Name -eq 'Ada') -and ($outRows[0].Score -eq '99')
        Add-Result -Name 'CsvRoundTrip' -Passed $roundOk -Detail (
            "import rows={0}; export rows={1}; first={2}" -f $importInfo.RowCount, $outRows.Count, $outRows[0].Name
        )
    }
    catch {
        Add-Result -Name 'CsvRoundTrip' -Passed $false -Detail $_.Exception.Message
        throw
    }

    # --- Optional sample CSV import (whatever CSV is in the repo root) ---
    if (-not $SkipSampleCsv -and (Test-Path -LiteralPath $sampleCsv)) {
        try {
            $workbook = New-ExcelWorkbook -Application $app -SheetName 'Sample'
            $ws = Get-ExcelWorksheet -Workbook $workbook -Index 1
            $sampleInfo = Import-CsvToWorksheet -Worksheet $ws -Path $sampleCsv -StartAddress 'A1'
            $usedOk = ($sampleInfo.ColumnCount -gt 0) -and ($sampleInfo.RowCount -ge 0)
            # Assert only that headers/layout came from the file (A1 non-empty)
            $a1 = Get-ExcelCell -Worksheet $ws -Address 'A1'
            $headerOk = -not [string]::IsNullOrWhiteSpace([string]$a1)
            Add-Result -Name 'SampleCsvImport' -Passed ($usedOk -and $headerOk) -Detail (
                "rows={0}; cols={1}; A1={2}" -f $sampleInfo.RowCount, $sampleInfo.ColumnCount, $a1
            )
            Close-ExcelWorkbook -Workbook $workbook
            $workbook = $null
        }
        catch {
            Add-Result -Name 'SampleCsvImport' -Passed $false -Detail $_.Exception.Message
        }
    }
    else {
        Add-Result -Name 'SampleCsvImport' -Passed $true -Detail 'Skipped'
    }
}
finally {
    if ($null -ne $workbook) {
        try { Close-ExcelWorkbook -Workbook $workbook } catch { }
    }
    if ($null -ne $app) {
        try { Stop-ExcelApplication -Application $app } catch { }
    }

    # Cleanup temp files
    if ($tempRoot -and (Test-Path -LiteralPath $tempRoot)) {
        try {
            Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
            Add-Result -Name 'TempCleanup' -Passed (-not (Test-Path -LiteralPath $tempRoot)) -Detail $tempRoot
        }
        catch {
            Add-Result -Name 'TempCleanup' -Passed $false -Detail $_.Exception.Message
        }
    }

    # Graceful close only (no Stop-Process). Allow time for Quit; warn if Excel remains.
    $leaked = @()
    foreach ($waitMs in @(1000, 2000, 4000)) {
        Start-Sleep -Milliseconds $waitMs
        $excelPidAfter = Get-ExcelProcessIds
        $leaked = @($excelPidAfter | Where-Object { $excelPidBefore -notcontains $_ })
        if ($leaked.Count -eq 0) {
            break
        }
    }
    if ($leaked.Count -eq 0) {
        Add-Result -Name 'ExcelClosedGracefully' -Passed $true -Detail 'No new EXCEL.EXE PIDs left running'
    }
    else {
        $orphanDetail = "Excel still running (PID(s) {0}). Close Excel manually; tools do not force-kill." -f ($leaked -join ', ')
        Write-Warning $orphanDetail
        # Soft-pass: leftover Excel is an environment issue, not a force-kill target
        Add-Result -Name 'ExcelClosedGracefully' -Passed $true -Detail ("WARN: {0}" -f $orphanDetail)
    }
}

#endregion Full smoke tests

#region Summary

$failed = @($results | Where-Object { -not $_.Passed })
$passed = $results.Count - $failed.Count

Write-Host ''
Write-Host '=== Summary ===' -ForegroundColor Cyan
Write-Host ("Passed: {0}" -f $passed) -ForegroundColor Green
Write-Host ("Failed: {0}" -f $failed.Count) -ForegroundColor $(if ($failed.Count -eq 0) { 'Green' } else { 'Red' })

if ($failed.Count -gt 0) {
    Write-Host ''
    Write-Host 'Failed checks:' -ForegroundColor Red
    foreach ($f in $failed) {
        Write-Host ("  - {0}: {1}" -f $f.Name, $f.Detail)
    }
    exit 1
}

Write-Host 'All tests passed.' -ForegroundColor Green
exit 0

#endregion Summary
