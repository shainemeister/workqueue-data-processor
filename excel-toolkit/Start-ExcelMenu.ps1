#requires -Version 5.1
<#
.SYNOPSIS
    Interactive menu for Excel CSV export, Excel->CSV import, schema, and diagnostics.

.DESCRIPTION
    Double-click Start-ExcelMenu.cmd (recommended) or run this script under
    Windows PowerShell 5.1. No PowerShell syntax knowledge is required for
    common tasks.

    Main menu: Score CSV to Excel (KPI pipeline), export, import (CSV defaults
    under import\), folders, schema, and Diagnostics (readiness + full self-test).

    Column layout always comes from your data CSV. An optional schema (JSON or
    CSV) supplies display labels only. Nothing domain-specific is hard-coded.
    Existing output files are not overwritten: a free path with a numerical
    suffix (name_1.ext) is chosen instead.

.NOTES
    Launch via Start-ExcelMenu.cmd so the process uses -ExecutionPolicy Bypass
    for this session only (does not change machine policy permanently).
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Paths and helpers

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$repoRoot     = Split-Path -Parent $scriptDir
$outputDir    = Join-Path $repoRoot 'output'
$importDir    = Join-Path $repoRoot 'import'
$kpiAnalyticsDir = Join-Path $repoRoot 'kpi-analytics'
$kpiAnalyticsCmd = Join-Path $kpiAnalyticsDir 'kpi-analytics.cmd'
$exportScript = Join-Path $scriptDir 'Export-CsvToExcel.ps1'
$testScript   = Join-Path $scriptDir 'Test-ExcelCom.ps1'
$toolkitModulePath = Join-Path $scriptDir 'ExcelToolkit.psm1'
$modulePath   = Join-Path $scriptDir 'ExcelCom.psm1'

# --- Session schema settings (option 7; used by export options 3/4) ---
$sessionSchemaFormat = 'Auto'   # Auto | Json | Csv
$sessionSchemaPath   = $null    # full path; null = auto-resolve from format

function Wait-ForEnter {
    param([string]$Prompt = 'Press Enter to return to the menu...')
    Write-Host ''
    try {
        $null = Read-Host $Prompt
    }
    catch { }
}

function Get-DefaultSchemaPathForFormat {
    param([string]$Format)

    if ($Format -eq 'Csv') {
        $preferred = Join-Path $repoRoot 'wq_schema.csv'
        if (Test-Path -LiteralPath $preferred) { return $preferred }
        $hit = Get-ChildItem -LiteralPath $repoRoot -Filter '*schema*.csv' -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $hit) { return $hit.FullName }
        return $preferred
    }

    if ($Format -eq 'Json') {
        $preferred = Join-Path $repoRoot 'wq_schema.json'
        if (Test-Path -LiteralPath $preferred) { return $preferred }
        $hit = Get-ChildItem -LiteralPath $repoRoot -Filter '*schema*.json' -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $hit) { return $hit.FullName }
        return $preferred
    }

    # Auto: prefer JSON then CSV
    $j = Join-Path $repoRoot 'wq_schema.json'
    if (Test-Path -LiteralPath $j) { return $j }
    $jHit = Get-ChildItem -LiteralPath $repoRoot -Filter '*schema*.json' -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $jHit) { return $jHit.FullName }
    $c = Join-Path $repoRoot 'wq_schema.csv'
    if (Test-Path -LiteralPath $c) { return $c }
    $cHit = Get-ChildItem -LiteralPath $repoRoot -Filter '*schema*.csv' -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $cHit) { return $cHit.FullName }
    return $j
}

function Get-EffectiveSchemaPath {
    if (-not [string]::IsNullOrWhiteSpace($script:sessionSchemaPath)) {
        return $script:sessionSchemaPath
    }
    return (Get-DefaultSchemaPathForFormat -Format $script:sessionSchemaFormat)
}

function Get-EffectiveSchemaFormat {
    param([string]$Path)

    if ($script:sessionSchemaFormat -eq 'Json' -or $script:sessionSchemaFormat -eq 'Csv') {
        return $script:sessionSchemaFormat
    }

    $ext = [System.IO.Path]::GetExtension($Path)
    if ($ext -match '^\.csv$') { return 'Csv' }
    if ($ext -match '^\.json$') { return 'Json' }
    return 'Json'
}

function Get-PropertyValueSafe {
    <#
    .SYNOPSIS
        Read a note/property by name without throwing under StrictMode when missing.
    #>
    param(
        $Object,
        [string]$Name
    )

    if ($null -eq $Object -or [string]::IsNullOrWhiteSpace($Name)) {
        return $null
    }

    $prop = $Object.PSObject.Properties[$Name]
    if ($null -eq $prop) {
        return $null
    }
    if ($null -eq $prop.Value) {
        return $null
    }
    $text = [string]$prop.Value
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }
    return $text
}

function Get-SchemaDisplayLabelFromObject {
    param($FieldObject)

    if ($null -eq $FieldObject) { return $null }
    foreach ($name in @('display_name', 'wq_field_name', 'label', 'title')) {
        $val = Get-PropertyValueSafe -Object $FieldObject -Name $name
        if (-not [string]::IsNullOrWhiteSpace($val)) {
            return $val
        }
    }
    return $null
}

function ConvertTo-SchemaFieldRow {
    param($Source)

    if ($null -eq $Source) { return $null }

    $fn = Get-PropertyValueSafe -Object $Source -Name 'field_name'
    if ([string]::IsNullOrWhiteSpace($fn)) {
        return $null
    }

    $label = Get-SchemaDisplayLabelFromObject -FieldObject $Source
    $dtype = Get-PropertyValueSafe -Object $Source -Name 'data_type'

    return [pscustomobject]@{
        field_name   = $fn
        display_name = $label
        data_type    = $dtype
    }
}

function Get-SchemaFieldsForDisplay {
    <#
    .SYNOPSIS
        Load schema fields for menu preview. Always returns a flat object[].
    .NOTES
        Do not use "return ,$array" - the unary comma nests the array so callers
        see Count=1 and cannot read .field_name on rows.
    #>
    param(
        [string]$Path,
        [string]$Format
    )

    $list = New-Object System.Collections.Generic.List[object]
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        return @()
    }

    $fmt = Get-EffectiveSchemaFormat -Path $Path
    if ($Format -eq 'Json' -or $Format -eq 'Csv') {
        $fmt = $Format
    }

    if ($fmt -eq 'Csv') {
        $rows = @(Import-Csv -LiteralPath $Path -ErrorAction Stop)
        foreach ($row in $rows) {
            $item = ConvertTo-SchemaFieldRow -Source $row
            if ($null -ne $item) {
                [void]$list.Add($item)
            }
        }
    }
    else {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop
        $schema = $raw | ConvertFrom-Json -ErrorAction Stop
        $fields = @()

        $hasFields = $false
        if ($null -ne $schema) {
            $fieldsProp = $schema.PSObject.Properties['fields']
            if ($null -ne $fieldsProp -and $null -ne $fieldsProp.Value) {
                $fields = @($fieldsProp.Value)
                $hasFields = $true
            }
        }
        if (-not $hasFields -and $schema -is [System.Array]) {
            $fields = @($schema)
        }

        foreach ($field in $fields) {
            $item = ConvertTo-SchemaFieldRow -Source $field
            if ($null -ne $item) {
                [void]$list.Add($item)
            }
        }
    }

    # Flat array - never wrap with unary comma
    return @($list.ToArray())
}

function Get-ExportArguments {
    param([switch]$UseDisplayNames)

    $args = @{}
    $schemaPath = Get-EffectiveSchemaPath
    $schemaFormat = Get-EffectiveSchemaFormat -Path $schemaPath

    if (-not [string]::IsNullOrWhiteSpace($schemaPath)) {
        $args['SchemaPath'] = $schemaPath
    }
    if ($schemaFormat -eq 'Json' -or $schemaFormat -eq 'Csv') {
        $args['SchemaFormat'] = $schemaFormat
    }
    if ($UseDisplayNames) {
        $args['UseDisplayNames'] = $true
    }
    return $args
}

function Invoke-ToolScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [hashtable]$Arguments = @{}
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw ("Script not found: {0}" -f $Path)
    }

    Write-Host ''
    Write-Host ("Running: {0}" -f (Split-Path -Leaf $Path)) -ForegroundColor Cyan
    Write-Host ('-' * 50) -ForegroundColor DarkGray

    $argList = New-Object System.Collections.Generic.List[string]
    # Child is a new process (needs its own process-scoped policy).
    # Bypass here is process-only - does not change machine policy.
    $argList.Add('-NoLogo')
    $argList.Add('-NoProfile')
    $argList.Add('-ExecutionPolicy')
    $argList.Add('Bypass')
    $argList.Add('-File')
    $argList.Add($Path)

    foreach ($key in @($Arguments.Keys)) {
        $val = $Arguments[$key]
        if ($val -is [bool] -or $val -is [System.Management.Automation.SwitchParameter]) {
            if ([bool]$val) {
                $argList.Add(('-{0}' -f $key))
            }
        }
        elseif ($null -ne $val -and -not [string]::IsNullOrWhiteSpace([string]$val)) {
            $argList.Add(('-{0}' -f $key))
            $argList.Add([string]$val)
        }
    }

    $exitCode = 1
    try {
        $proc = Start-Process -FilePath 'powershell.exe' `
            -ArgumentList $argList.ToArray() `
            -Wait -PassThru -NoNewWindow
        $exitCode = [int]$proc.ExitCode
    }
    catch {
        $exitCode = 1
        Write-Host ''
        Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Host 'If scripts are blocked, run via Start-ExcelMenu.cmd or ask IT to allowlist this folder.' -ForegroundColor Yellow
        Write-Host 'If a file is locked, close Excel completely and try again (tools never force-kill Excel).' -ForegroundColor Yellow
    }

    Write-Host ('-' * 50) -ForegroundColor DarkGray
    if ($exitCode -eq 0) {
        Write-Host 'Finished successfully.' -ForegroundColor Green
    }
    else {
        Write-Host ("Finished with exit code {0}." -f $exitCode) -ForegroundColor Yellow
    }
    return $exitCode
}

function Invoke-ImportExcelMenu {
    Write-Host ''
    Write-Host 'Import Excel to CSV' -ForegroundColor Cyan
    Write-Host 'Opens a workbook (password-protected files prompt for a password) and writes a CSV under import\ by default.' -ForegroundColor DarkGray
    Write-Host ''

    if (-not (Test-Path -LiteralPath $toolkitModulePath)) {
        throw ("ExcelToolkit.psm1 not found: {0}" -f $toolkitModulePath)
    }

    if (-not (Test-Path -LiteralPath $importDir)) {
        New-Item -ItemType Directory -Path $importDir -Force | Out-Null
    }

    $candidates = @()
    if (Test-Path -LiteralPath $importDir) {
        $xlsx = @(Get-ChildItem -LiteralPath $importDir -Filter '*.xlsx' -File -ErrorAction SilentlyContinue)
        $xls = @(Get-ChildItem -LiteralPath $importDir -Filter '*.xls' -File -ErrorAction SilentlyContinue)
        $candidates = @($xlsx + $xls | Sort-Object Name)
    }

    if ($candidates.Count -gt 0) {
        Write-Host 'Workbooks under import\:' -ForegroundColor Cyan
        for ($i = 0; $i -lt $candidates.Count; $i++) {
            Write-Host ("  [{0}] {1}" -f ($i + 1), $candidates[$i].Name)
        }
        Write-Host '  [P] Enter a full path'
        $pick = Read-Host 'Select workbook (number or P)'
        if ($pick -match '^[Pp]$') {
            $excelPath = Read-Host 'Excel file path'
        }
        elseif ($pick -match '^\d+$') {
            $idx = [int]$pick - 1
            if ($idx -lt 0 -or $idx -ge $candidates.Count) {
                throw 'Invalid selection.'
            }
            $excelPath = $candidates[$idx].FullName
        }
        else {
            throw 'Invalid selection.'
        }
    }
    else {
        Write-Host ("No .xlsx/.xls found under {0}" -f $importDir) -ForegroundColor Yellow
        $excelPath = Read-Host 'Excel file path'
    }

    if ([string]::IsNullOrWhiteSpace($excelPath)) {
        throw 'Excel path is required.'
    }
    if (-not (Test-Path -LiteralPath $excelPath)) {
        throw ("Excel file not found: {0}" -f $excelPath)
    }

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($excelPath)
    $defaultOut = Join-Path $importDir ("{0}.csv" -f $baseName)
    $outPrompt = Read-Host ("Output CSV path [{0}]" -f $defaultOut)
    if ([string]::IsNullOrWhiteSpace($outPrompt)) {
        $outPrompt = $defaultOut
    }

    try {
        $outPrompt = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($outPrompt.Trim('"'))
    }
    catch {
        throw ("Invalid output path: {0}" -f $_.Exception.Message)
    }

    Import-Module -Name $toolkitModulePath -Force -ErrorAction Stop
    Write-Host ''
    Write-Host ("Importing: {0}" -f $excelPath) -ForegroundColor Cyan
    Write-Host ("  Planned: {0}" -f $outPrompt) -ForegroundColor Cyan
    Write-Host 'If that CSV already exists, a free path with a numerical suffix is used (no overwrite).' -ForegroundColor DarkGray

    $importParams = @{
        ExcelPath           = $excelPath
        OutputPath          = $outPrompt
        AllowPasswordPrompt = $true
    }

    $r = Import-CsvFromExcel @importParams
    if ($r.Success) {
        Write-Host ("OK: {0}" -f $r.Message) -ForegroundColor Green
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
    }
    else {
        Write-Host ("FAIL: {0}" -f $r.Message) -ForegroundColor Red
    }
}

function Invoke-KpiAnalyticsScore {
    <#
    .SYNOPSIS
        Call sibling kpi-analytics.cmd score with absolute paths; return exit + JSON.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$CsvPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [string]$SummaryPath
    )

    if (-not (Test-Path -LiteralPath $kpiAnalyticsCmd)) {
        throw ("kpi-analytics launcher not found: {0}" -f $kpiAnalyticsCmd)
    }

    $tmpOut = [System.IO.Path]::GetTempFileName()
    $tmpErr = [System.IO.Path]::GetTempFileName()
    $exitCode = 1
    $stdout = ''
    $stderr = ''

    try {
        # kpi-analytics.cmd must run with cwd = kpi-analytics\ (module import)
        $argLine = '/c ""{0}" score --csv "{1}" --output "{2}" --summary "{3}" --json"' -f `
            $kpiAnalyticsCmd, $CsvPath, $OutputPath, $SummaryPath

        $proc = Start-Process -FilePath 'cmd.exe' `
            -ArgumentList $argLine `
            -WorkingDirectory $kpiAnalyticsDir `
            -Wait -PassThru -NoNewWindow `
            -RedirectStandardOutput $tmpOut `
            -RedirectStandardError $tmpErr

        $exitCode = [int]$proc.ExitCode
        if (Test-Path -LiteralPath $tmpOut) {
            $stdout = [System.IO.File]::ReadAllText($tmpOut)
        }
        if (Test-Path -LiteralPath $tmpErr) {
            $stderr = [System.IO.File]::ReadAllText($tmpErr)
        }
    }
    finally {
        Remove-Item -LiteralPath $tmpOut, $tmpErr -Force -ErrorAction SilentlyContinue
    }

    $jsonObj = $null
    $trimmed = $stdout.Trim()
    if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
        # Prefer last JSON object line if diagnostics noise appears on stdout
        $lines = @($trimmed -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        for ($i = $lines.Count - 1; $i -ge 0; $i--) {
            $line = $lines[$i].Trim()
            if ($line.StartsWith('{')) {
                try {
                    $jsonObj = $line | ConvertFrom-Json -ErrorAction Stop
                    break
                }
                catch { }
            }
        }
        if ($null -eq $jsonObj) {
            try {
                $jsonObj = $trimmed | ConvertFrom-Json -ErrorAction Stop
            }
            catch { }
        }
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        StdOut   = $stdout
        StdErr   = $stderr
        Json     = $jsonObj
    }
}

function Select-CsvInputsForPipeline {
    <#
    .SYNOPSIS
        List import\ CSVs and accept multi-select indices or a typed path.
    #>
    $selected = New-Object System.Collections.Generic.List[string]

    $candidates = @()
    if (Test-Path -LiteralPath $importDir) {
        $candidates = @(Get-ChildItem -LiteralPath $importDir -Filter '*.csv' -File -ErrorAction SilentlyContinue |
            Sort-Object Name)
    }

    if ($candidates.Count -gt 0) {
        Write-Host 'CSV files under import\:' -ForegroundColor Cyan
        for ($i = 0; $i -lt $candidates.Count; $i++) {
            $item = $candidates[$i]
            Write-Host ("  {0,2}) {1}  ({2:N0} bytes, {3})" -f ($i + 1), $item.Name, $item.Length, $item.LastWriteTime)
        }
        Write-Host ''
        Write-Host 'Enter number(s) e.g. 1 or 1,2 - or a full path to a CSV:' -ForegroundColor DarkGray
        $raw = Read-Host 'Selection'
    }
    else {
        Write-Host ("No .csv files found under {0}" -f $importDir) -ForegroundColor Yellow
        $raw = Read-Host 'Enter full path to a data CSV'
    }

    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @()
    }

    $raw = $raw.Trim().Trim('"')

    # Typed path (contains path separators or ends with .csv and is not pure numbers)
    $looksLikePath = ($raw -match '[\\/]' -or $raw -match '\.csv$' -or $raw -match '^[A-Za-z]:')
    $onlyIndexList = ($raw -match '^[\d,\s]+$')

    if ($looksLikePath -and -not $onlyIndexList) {
        try {
            $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($raw)
        }
        catch {
            throw ("Invalid path: {0}" -f $_.Exception.Message)
        }
        if (-not (Test-Path -LiteralPath $resolved)) {
            throw ("CSV not found: {0}" -f $resolved)
        }
        $selected.Add($resolved)
        return @($selected.ToArray())
    }

    $parts = @($raw -split '[,;\s]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    foreach ($p in $parts) {
        $n = 0
        if (-not [int]::TryParse($p, [ref]$n)) {
            throw ("Not a valid selection number: {0}" -f $p)
        }
        if ($n -lt 1 -or $n -gt $candidates.Count) {
            throw ("Selection out of range: {0} (1-{1})" -f $n, $candidates.Count)
        }
        $full = $candidates[$n - 1].FullName
        if (-not ($selected -contains $full)) {
            $selected.Add($full)
        }
    }

    return @($selected.ToArray())
}

function Invoke-KpiScoreExportMenu {
    Write-Host ''
    Write-Host 'Score CSV -> Excel (KPI pipeline)' -ForegroundColor Cyan
    Write-Host 'Runs kpi-analytics score, then exports scored + summary CSVs to Excel.' -ForegroundColor DarkGray
    Write-Host 'Engines stay separate: Python scores; Excel COM formats workbooks.' -ForegroundColor DarkGray
    Write-Host 'Existing outputs are kept; new files use a free numerical suffix when needed.' -ForegroundColor DarkGray
    Write-Host ''

    if (-not (Test-Path -LiteralPath $kpiAnalyticsCmd)) {
        throw ("kpi-analytics not found at: {0}`nInstall/place the sibling kpi-analytics toolkit next to excel-toolkit." -f $kpiAnalyticsCmd)
    }
    if (-not (Test-Path -LiteralPath $toolkitModulePath)) {
        throw ("ExcelToolkit.psm1 not found: {0}" -f $toolkitModulePath)
    }

    Import-Module -Name $toolkitModulePath -Force -ErrorAction Stop

    if (-not (Test-Path -LiteralPath $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    $inputs = @(Select-CsvInputsForPipeline)
    if ($inputs.Count -eq 0) {
        Write-Host 'No CSV selected.' -ForegroundColor Yellow
        return
    }

    Write-Host ''
    Write-Host ("Selected {0} file(s). First KPI run may run diagnostics (one-time gate)." -f $inputs.Count) -ForegroundColor DarkGray
    Write-Host ''

    $okCount = 0
    $failCount = 0

    foreach ($csvPath in $inputs) {
        Write-Host ('-' * 50) -ForegroundColor DarkGray
        Write-Host ("Input: {0}" -f $csvPath) -ForegroundColor Cyan

        try {
            $stem = [System.IO.Path]::GetFileNameWithoutExtension($csvPath)
            if ([string]::IsNullOrWhiteSpace($stem)) { $stem = 'wq_data' }

            $plannedScoredCsv   = Join-Path $outputDir ('{0}_scored.csv' -f $stem)
            $plannedSummaryCsv  = Join-Path $outputDir ('{0}_scored_summary.csv' -f $stem)

            $scoredCsvInfo  = Resolve-ExcelToolkitUniquePath -Path $plannedScoredCsv
            $summaryCsvInfo = Resolve-ExcelToolkitUniquePath -Path $plannedSummaryCsv

            if ($scoredCsvInfo.PathAdjusted -or $summaryCsvInfo.PathAdjusted) {
                Write-Host '  Unique CSV paths (avoided overwrite):' -ForegroundColor Yellow
                Write-Host ("    Scored  : {0}" -f $scoredCsvInfo.Path)
                Write-Host ("    Summary : {0}" -f $summaryCsvInfo.Path)
            }
            else {
                Write-Host ("  Scored CSV  : {0}" -f $scoredCsvInfo.Path)
                Write-Host ("  Summary CSV : {0}" -f $summaryCsvInfo.Path)
            }

            Write-Host '  Scoring (kpi-analytics)...' -ForegroundColor Cyan
            $scoreResult = Invoke-KpiAnalyticsScore `
                -CsvPath $csvPath `
                -OutputPath $scoredCsvInfo.Path `
                -SummaryPath $summaryCsvInfo.Path

            $scoreOk = ($scoreResult.ExitCode -eq 0)
            $scoreJson = $scoreResult.Json
            if ($null -ne $scoreJson -and $scoreJson.PSObject.Properties.Name -contains 'Success') {
                $scoreOk = $scoreOk -and [bool]$scoreJson.Success
            }

            if (-not $scoreOk) {
                $msg = 'Score failed.'
                if ($null -ne $scoreJson -and $scoreJson.Message) {
                    $msg = [string]$scoreJson.Message
                }
                elseif (-not [string]::IsNullOrWhiteSpace($scoreResult.StdErr)) {
                    $msg = $scoreResult.StdErr.Trim()
                }
                elseif (-not [string]::IsNullOrWhiteSpace($scoreResult.StdOut)) {
                    $msg = $scoreResult.StdOut.Trim()
                }
                Write-Host ("  FAIL score (exit {0}): {1}" -f $scoreResult.ExitCode, $msg) -ForegroundColor Red
                $diagTxt = Join-Path $kpiAnalyticsDir 'diagnostics\last_diagnostics.txt'
                if (Test-Path -LiteralPath $diagTxt) {
                    Write-Host ("  See diagnostics: {0}" -f $diagTxt) -ForegroundColor Yellow
                }
                $failCount++
                continue
            }

            $actualScoredCsv = $scoredCsvInfo.Path
            $actualSummaryCsv = $summaryCsvInfo.Path
            if ($null -ne $scoreJson) {
                if ($scoreJson.OutputPath) { $actualScoredCsv = [string]$scoreJson.OutputPath }
                if ($scoreJson.SummaryPath) { $actualSummaryCsv = [string]$scoreJson.SummaryPath }
            }

            $rowNote = ''
            if ($null -ne $scoreJson -and $scoreJson.PSObject.Properties.Name -contains 'RowCount') {
                $rowNote = (" rows={0}" -f $scoreJson.RowCount)
            }
            Write-Host ("  Score OK.{0}" -f $rowNote) -ForegroundColor Green

            $plannedScoredXlsx  = [System.IO.Path]::ChangeExtension($actualScoredCsv, '.xlsx')
            $plannedSummaryXlsx = [System.IO.Path]::ChangeExtension($actualSummaryCsv, '.xlsx')

            Write-Host '  Exporting scored workbook...' -ForegroundColor Cyan
            $ex1 = Export-ExcelFromCsv -CsvPath $actualScoredCsv -OutputPath $plannedScoredXlsx
            if (-not $ex1.Success) {
                Write-Host ("  FAIL scored Excel: {0}" -f $ex1.Message) -ForegroundColor Red
                Write-Host ("  Scored CSV still at: {0}" -f $actualScoredCsv) -ForegroundColor Yellow
                $failCount++
                continue
            }
            Write-Host ("  Scored XLSX : {0}" -f $ex1.OutputPath) -ForegroundColor Green

            Write-Host '  Exporting summary workbook...' -ForegroundColor Cyan
            if (-not (Test-Path -LiteralPath $actualSummaryCsv)) {
                Write-Host ("  FAIL summary CSV missing: {0}" -f $actualSummaryCsv) -ForegroundColor Red
                $failCount++
                continue
            }
            $ex2 = Export-ExcelFromCsv -CsvPath $actualSummaryCsv -OutputPath $plannedSummaryXlsx
            if (-not $ex2.Success) {
                Write-Host ("  FAIL summary Excel: {0}" -f $ex2.Message) -ForegroundColor Red
                Write-Host ("  Summary CSV still at: {0}" -f $actualSummaryCsv) -ForegroundColor Yellow
                $failCount++
                continue
            }
            Write-Host ("  Summary XLSX: {0}" -f $ex2.OutputPath) -ForegroundColor Green

            Write-Host '  Pipeline complete for this file.' -ForegroundColor Green
            $okCount++
        }
        catch {
            Write-Host ("  FAIL: {0}" -f $_.Exception.Message) -ForegroundColor Red
            $failCount++
        }
    }

    Write-Host ('-' * 50) -ForegroundColor DarkGray
    Write-Host ("Done: {0} succeeded, {1} failed." -f $okCount, $failCount) -ForegroundColor $(if ($failCount -eq 0) { 'Green' } else { 'Yellow' })

    if ($okCount -gt 0) {
        $open = Read-Host 'Open output folder? [y/N]'
        if ($open -match '^[Yy]') {
            Open-OutputFolder
        }
    }
}

function Invoke-DiagnosticsMenu {
    $inDiag = $true
    while ($inDiag) {
        Write-Host ''
        Write-Host '================================================' -ForegroundColor Cyan
        Write-Host '  Diagnostics' -ForegroundColor Cyan
        Write-Host '================================================' -ForegroundColor Cyan
        Write-Host '  1) Check readiness (dry-run)'
        Write-Host '  2) Run full self-test'
        Write-Host '  0) Back to main menu'
        Write-Host '================================================' -ForegroundColor Cyan
        Write-Host ''
        $sub = Read-Host 'Select a diagnostics option'
        switch -Regex ($sub) {
            '^[1]$' {
                $null = Invoke-ToolScript -Path $testScript -Arguments @{ DryRun = $true }
                Wait-ForEnter
            }
            '^[2]$' {
                $null = Invoke-ToolScript -Path $testScript
                Wait-ForEnter
            }
            '^[0Bb]$' {
                $inDiag = $false
            }
            default {
                Write-Host 'Please enter 1, 2, or 0 (back).' -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
        }
    }
}

function Show-EnvironmentInfo {
    Write-Host ''
    Write-Host 'Environment' -ForegroundColor Cyan
    Write-Host ("  PowerShell     : {0}" -f $PSVersionTable.PSVersion)
    Write-Host ("  Script folder  : {0}" -f $scriptDir)
    Write-Host ("  Data folder    : {0}" -f $repoRoot)
    Write-Host ("  Import folder  : {0}" -f $importDir)
    Write-Host ("  Output folder  : {0}" -f $outputDir)
    Write-Host ''
    Write-Host 'Execution policy (read-only; this menu does not change it permanently):' -ForegroundColor Cyan
    Get-ExecutionPolicy -List | ForEach-Object {
        Write-Host ("  {0,-16} {1}" -f $_.Scope, $_.ExecutionPolicy)
    }

    Write-Host ''
    Write-Host 'Excel COM probe:' -ForegroundColor Cyan
    if (Test-Path -LiteralPath $modulePath) {
        try {
            Import-Module -Name $modulePath -Force -ErrorAction Stop
            $result = Test-ExcelComEnvironment -SkipExcelProbe:$false
            foreach ($c in $result.Checks) {
                $tag = 'FAIL'
                $color = 'Red'
                if ($c.Passed) {
                    $tag = 'PASS'
                    $color = 'Green'
                }
                Write-Host ("  [{0}] {1}: {2}" -f $tag, $c.Name, $c.Detail) -ForegroundColor $color
            }
        }
        catch {
            Write-Host ("  Could not run probe: {0}" -f $_.Exception.Message) -ForegroundColor Red
        }
    }
    else {
        Write-Host ("  Module missing: {0}" -f $modulePath) -ForegroundColor Red
    }
}

function Open-OutputFolder {
    if (-not (Test-Path -LiteralPath $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        Write-Host ("Created: {0}" -f $outputDir) -ForegroundColor Yellow
    }
    Write-Host ("Opening: {0}" -f $outputDir) -ForegroundColor Cyan
    Start-Process -FilePath 'explorer.exe' -ArgumentList $outputDir
}

function Show-SchemaRawPreview {
    param(
        [string]$Path,
        [int]$MaxLines = 8
    )

    Write-Host ''
    Write-Host ("Schema file preview (first {0} lines)" -f $MaxLines) -ForegroundColor Cyan
    try {
        $lines = @(Get-Content -LiteralPath $Path -TotalCount $MaxLines -ErrorAction Stop)
        if ($lines.Count -eq 0) {
            Write-Host '  (file is empty)' -ForegroundColor Yellow
            return
        }
        $n = 0
        foreach ($line in $lines) {
            $n++
            $text = $line
            if ($null -eq $text) { $text = '' }
            if ($text.Length -gt 120) {
                $text = $text.Substring(0, 117) + '...'
            }
            Write-Host ("  {0,3}| {1}" -f $n, $text) -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Host ("  Could not read file text: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
}

function Show-SchemaSummary {
    $path = Get-EffectiveSchemaPath
    $fmt  = Get-EffectiveSchemaFormat -Path $path
    $exists = Test-Path -LiteralPath $path

    Write-Host ''
    Write-Host 'Schema configuration' -ForegroundColor Cyan
    Write-Host ("  Session format setting : {0}" -f $script:sessionSchemaFormat)
    Write-Host ("  Effective format       : {0}" -f $fmt)
    Write-Host ("  Schema source path     : {0}" -f $path)
    if ($exists) {
        $item = Get-Item -LiteralPath $path
        Write-Host ("  File exists            : Yes ({0:N0} bytes, {1})" -f $item.Length, $item.LastWriteTime)
    }
    else {
        Write-Host '  File exists            : No' -ForegroundColor Yellow
    }

    if (-not $exists) {
        Write-Host ''
        Write-Host 'No schema file found at that path. Use the options below to pick JSON/CSV or enter a path.' -ForegroundColor Yellow
        return
    }

    # Always show a raw peek so the user sees file content even if parse fails
    Show-SchemaRawPreview -Path $path -MaxLines 8

    try {
        # Ensure a flat list of row objects (do not nest arrays)
        $fields = @(Get-SchemaFieldsForDisplay -Path $path -Format $fmt)

        # Guard: if a nested array slipped through, unwrap once
        if ($fields.Count -eq 1 -and $fields[0] -is [System.Array]) {
            $fields = @($fields[0])
        }

        Write-Host ''
        Write-Host ("  Field count            : {0}" -f $fields.Count)

        if ($fields.Count -eq 0) {
            Write-Host ''
            Write-Host 'No fields parsed. Schema rows need a field_name property/column.' -ForegroundColor Yellow
            Write-Host 'JSON: { "fields": [ { "field_name": "...", "display_name": "..." } ] }' -ForegroundColor DarkGray
            Write-Host 'CSV:  field_name,display_name,data_type' -ForegroundColor DarkGray
            return
        }

        Write-Host ''
        Write-Host 'Field map (field_name -> display label)' -ForegroundColor Cyan
        Write-Host ('  {0,-34} {1,-34} {2}' -f 'field_name', 'display_name', 'data_type')
        Write-Host ('  {0,-34} {1,-34} {2}' -f ('-' * 32), ('-' * 32), ('-' * 10))

        $maxShow = 50
        $shown = 0
        foreach ($f in $fields) {
            if ($null -eq $f) { continue }

            # Skip accidental nested arrays
            if ($f -is [System.Array]) { continue }

            $fn = Get-PropertyValueSafe -Object $f -Name 'field_name'
            if ([string]::IsNullOrWhiteSpace($fn)) { continue }

            $dn = Get-PropertyValueSafe -Object $f -Name 'display_name'
            if ([string]::IsNullOrWhiteSpace($dn)) {
                $dn = '(same as field_name)'
            }

            $dt = Get-PropertyValueSafe -Object $f -Name 'data_type'
            if ([string]::IsNullOrWhiteSpace($dt)) {
                $dt = '-'
            }

            # Truncate long cells for console width
            if ($fn.Length -gt 32) { $fn = $fn.Substring(0, 29) + '...' }
            if ($dn.Length -gt 32) { $dn = $dn.Substring(0, 29) + '...' }

            Write-Host ('  {0,-34} {1,-34} {2}' -f $fn, $dn, $dt)
            $shown++
            if ($shown -ge $maxShow) {
                $remaining = $fields.Count - $shown
                if ($remaining -gt 0) {
                    Write-Host ("  ... and {0} more field(s)" -f $remaining) -ForegroundColor DarkGray
                }
                break
            }
        }

        if ($shown -eq 0) {
            Write-Host '  (rows loaded but no readable field_name values)' -ForegroundColor Yellow
        }
        else {
            Write-Host ''
            Write-Host ("Showing {0} of {1} field(s)." -f $shown, $fields.Count) -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Host ''
        Write-Host ("  Error reading schema   : {0}" -f $_.Exception.Message) -ForegroundColor Red
        Write-Host '  See raw file preview above. Check JSON/CSV format or switch type with J/C.' -ForegroundColor Yellow
    }
}

function Set-SchemaFormatInteractive {
    param([ValidateSet('Json', 'Csv')][string]$Format)

    $script:sessionSchemaFormat = $Format
    $candidate = Get-DefaultSchemaPathForFormat -Format $Format

    # If current path extension does not match, switch to default for that format
    $current = $script:sessionSchemaPath
    if ([string]::IsNullOrWhiteSpace($current)) {
        $current = $candidate
    }

    $ext = [System.IO.Path]::GetExtension($current)
    $matchesFormat = $false
    if ($Format -eq 'Json' -and $ext -match '^\.json$') { $matchesFormat = $true }
    if ($Format -eq 'Csv' -and $ext -match '^\.csv$') { $matchesFormat = $true }

    if (-not $matchesFormat) {
        # Try same base name with new extension
        $base = [System.IO.Path]::GetFileNameWithoutExtension($current)
        $dir  = Split-Path -Parent $current
        if ([string]::IsNullOrWhiteSpace($dir)) { $dir = $repoRoot }
        $newExt = if ($Format -eq 'Json') { '.json' } else { '.csv' }
        $swapped = Join-Path $dir ($base + $newExt)
        if (Test-Path -LiteralPath $swapped) {
            $script:sessionSchemaPath = $swapped
        }
        else {
            $script:sessionSchemaPath = $candidate
        }
    }
    else {
        $script:sessionSchemaPath = $current
    }

    Write-Host ''
    Write-Host ("Schema format set to: {0}" -f $Format) -ForegroundColor Green
    Write-Host ("Schema source path  : {0}" -f (Get-EffectiveSchemaPath))
    if (-not (Test-Path -LiteralPath (Get-EffectiveSchemaPath))) {
        Write-Host 'Warning: that file does not exist yet. Enter a path (option P) or place the file in the data folder.' -ForegroundColor Yellow
    }
}

function Set-SchemaPathInteractive {
    Write-Host ''
    Write-Host 'Enter full path to schema file (.json or .csv).' -ForegroundColor Cyan
    Write-Host 'Leave blank to cancel.' -ForegroundColor DarkGray
    $inputPath = Read-Host 'Schema path'
    if ([string]::IsNullOrWhiteSpace($inputPath)) {
        Write-Host 'Cancelled.' -ForegroundColor Yellow
        return
    }

    try {
        $full = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($inputPath.Trim('"'))
    }
    catch {
        Write-Host ("Invalid path: {0}" -f $_.Exception.Message) -ForegroundColor Red
        return
    }

    $script:sessionSchemaPath = $full
    $ext = [System.IO.Path]::GetExtension($full)
    if ($ext -match '^\.csv$') {
        $script:sessionSchemaFormat = 'Csv'
    }
    elseif ($ext -match '^\.json$') {
        $script:sessionSchemaFormat = 'Json'
    }
    else {
        Write-Host 'Note: extension is not .json or .csv; session format left as-is (or Auto).' -ForegroundColor Yellow
    }

    Write-Host ("Schema path set to  : {0}" -f $full) -ForegroundColor Green
    Write-Host ("Schema format set to: {0}" -f $script:sessionSchemaFormat) -ForegroundColor Green
    if (-not (Test-Path -LiteralPath $full)) {
        Write-Host 'Warning: file not found at that path.' -ForegroundColor Yellow
    }
}

function Invoke-SchemaMenu {
    $inSchemaMenu = $true
    while ($inSchemaMenu) {
        Clear-Host
        Write-Host '================================================' -ForegroundColor Cyan
        Write-Host '  Schema source & preview' -ForegroundColor Cyan
        Write-Host '================================================' -ForegroundColor Cyan
        Show-SchemaSummary
        Write-Host ''
        Write-Host '------------------------------------------------' -ForegroundColor DarkGray
        Write-Host '  J) Use JSON schema format'
        Write-Host '  C) Use CSV schema format'
        Write-Host '  A) Auto-detect format from file extension'
        Write-Host '  P) Set schema file path manually'
        Write-Host '  R) Refresh preview'
        Write-Host '  B) Back to main menu'
        Write-Host '------------------------------------------------' -ForegroundColor DarkGray
        Write-Host ''
        Write-Host 'CSV schema columns: field_name, display_name (or wq_field_name), optional data_type' -ForegroundColor DarkGray
        Write-Host ''

        $sub = Read-Host 'Select an option'
        switch -Regex ($sub) {
            '^[Jj]$' {
                Set-SchemaFormatInteractive -Format 'Json'
                Wait-ForEnter -Prompt 'Press Enter to continue...'
            }
            '^[Cc]$' {
                Set-SchemaFormatInteractive -Format 'Csv'
                Wait-ForEnter -Prompt 'Press Enter to continue...'
            }
            '^[Aa]$' {
                $script:sessionSchemaFormat = 'Auto'
                if ([string]::IsNullOrWhiteSpace($script:sessionSchemaPath)) {
                    $script:sessionSchemaPath = Get-DefaultSchemaPathForFormat -Format 'Auto'
                }
                Write-Host ''
                Write-Host 'Schema format set to: Auto (from file extension)' -ForegroundColor Green
                Write-Host ("Schema source path  : {0}" -f (Get-EffectiveSchemaPath))
                Wait-ForEnter -Prompt 'Press Enter to continue...'
            }
            '^[Pp]$' {
                Set-SchemaPathInteractive
                Wait-ForEnter -Prompt 'Press Enter to continue...'
            }
            '^[Rr]$' {
                # loop redraws summary
            }
            '^[Bb]$' {
                $inSchemaMenu = $false
            }
            default {
                Write-Host 'Please choose J, C, A, P, R, or B.' -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
        }
    }
}

function Show-Menu {
    Clear-Host
    $schemaPath = Get-EffectiveSchemaPath
    $schemaFmt  = Get-EffectiveSchemaFormat -Path $schemaPath
    $schemaNote = '{0} | {1}' -f $schemaFmt, (Split-Path -Leaf $schemaPath)

    Write-Host '================================================' -ForegroundColor Cyan
    Write-Host '  Excel Data Tools' -ForegroundColor Cyan
    Write-Host '================================================' -ForegroundColor Cyan
    Write-Host '  1) Score CSV -> Excel (KPI pipeline)'
    Write-Host '  2) Export CSV to Excel'
    Write-Host '  3) Export CSV to Excel (schema display headers)'
    Write-Host '  4) Import Excel to CSV (password prompt if needed)'
    Write-Host '  5) Open output folder'
    Write-Host '  6) Show environment / policy info'
    Write-Host '  7) Schema: show source, preview, change JSON/CSV'
    Write-Host '  8) Diagnostics (readiness / self-test)'
    Write-Host '  0) Exit'
    Write-Host '================================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host ("Current schema: {0}" -f $schemaNote) -ForegroundColor DarkGray
    Write-Host 'Headers/columns come from your data CSV; schema is for display labels only.' -ForegroundColor DarkGray
    Write-Host 'Existing outputs are not overwritten (unique name_N.ext when needed).' -ForegroundColor DarkGray
    Write-Host 'Import CSV defaults to the import\ folder. Pipeline uses kpi-analytics + Excel.' -ForegroundColor DarkGray
}

#endregion Paths and helpers

#region Main loop

# Initialize default schema path for session
$sessionSchemaPath = Get-DefaultSchemaPathForFormat -Format $sessionSchemaFormat

$running = $true
while ($running) {
    Show-Menu
    $choice = Read-Host 'Select an option'

    switch ($choice) {
        '1' {
            try {
                Invoke-KpiScoreExportMenu
            }
            catch {
                Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
            }
            Wait-ForEnter
        }
        '2' {
            $null = Invoke-ToolScript -Path $exportScript -Arguments (Get-ExportArguments)
            Wait-ForEnter
        }
        '3' {
            $null = Invoke-ToolScript -Path $exportScript -Arguments (Get-ExportArguments -UseDisplayNames)
            Wait-ForEnter
        }
        '4' {
            try {
                Invoke-ImportExcelMenu
            }
            catch {
                Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
            }
            Wait-ForEnter
        }
        '5' {
            try {
                Open-OutputFolder
            }
            catch {
                Write-Host ("Could not open folder: {0}" -f $_.Exception.Message) -ForegroundColor Red
            }
            Wait-ForEnter
        }
        '6' {
            try {
                Show-EnvironmentInfo
            }
            catch {
                Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
            }
            Wait-ForEnter
        }
        '7' {
            try {
                Invoke-SchemaMenu
            }
            catch {
                Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
                Wait-ForEnter
            }
        }
        '8' {
            try {
                Invoke-DiagnosticsMenu
            }
            catch {
                Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
                Wait-ForEnter
            }
        }
        '0' {
            $running = $false
        }
        default {
            Write-Host 'Please enter a number from the menu.' -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
}

Write-Host 'Goodbye.' -ForegroundColor Cyan

#endregion Main loop
