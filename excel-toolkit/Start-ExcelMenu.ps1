#requires -Version 5.1
<#
.SYNOPSIS
    Interactive menu for guided Process-my-data flow and advanced tools.

.DESCRIPTION
    Double-click Start-ExcelMenu.cmd (recommended) or run this script under
    Windows PowerShell 5.1. No PowerShell syntax knowledge is required for
    common tasks.

    Main menu: Process my data (discover CSV/Excel under import\, print-style
    multi-select, then full pipeline / score only / export), and Advanced tools
    (schema-header export, import, folders, schema, diagnostics, scoring
    profiles list/help, environment).

    Scoring uses sibling kpi-analytics with a mapping preflight: schema-aligned
    headers score silently; incomplete/ambiguous headers open guided column
    mapping on an interactive console (or fail clearly when non-interactive).
    A sibling <stem>_mapping.json next to the CSV is auto-applied when present.
    Full pipeline, Score only, and Build worklist optionally pick a scoring
    profile (POI focus) and pass it as kpi-analytics score --profile.
    Build worklist also picks a --group-preset and exports Data + Groups +
    Worklist sheets (no scoring math in PowerShell). Express score skips
    profile / password / Full-Slim picks, scores --output-mode slim, and
    writes one POI_Scores sheet (identity + score-input + context source + four scores; copy only).
    Multi-file preview (2+ files) shows name, WQ stem, row count, max
    out_ins_amt without scoring. Excel deliverable names use
    [WQ]_MM-DD-YYYY.xlsx. File-level Totals sheet copies existing scored
    columns (count / dollar sums / max priority / min appeal).

    Column layout for the Data sheet comes from your data CSV. Worklist and
    POI_Scores use frozen composition headers (copy only; no scoring math).
    An optional schema (JSON or CSV) supplies display labels only.
    Existing output files are not overwritten: a free path with a numerical
    suffix (name_1.ext) is chosen instead. Optional workbook open password is
    offered on Excel paths except Express (unprotected POI_Scores only).

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
$testScript   = Join-Path $scriptDir 'Test-ExcelCom.ps1'
$toolkitModulePath = Join-Path $scriptDir 'ExcelToolkit.psm1'
$modulePath   = Join-Path $scriptDir 'ExcelCom.psm1'

# --- Session schema settings (Advanced -> Schema; used by schema-header export) ---
$sessionSchemaFormat = 'Auto'   # Auto | Json | Csv
$sessionSchemaPath   = $null    # full path; null = auto-resolve from format

function Ensure-ExcelMenuDiagnosticsPass {
    <#
    .SYNOPSIS
        First-run Excel diagnostics gate for menu Excel operations.
        Returns $true if the operation may proceed.
    #>
    [CmdletBinding()]
    param()

    if (-not (Test-Path -LiteralPath $toolkitModulePath)) {
        Write-Host ("ExcelToolkit.psm1 not found: {0}" -f $toolkitModulePath) -ForegroundColor Red
        return $false
    }

    Import-Module -Name $toolkitModulePath -Force -ErrorAction Stop
    $gate = Assert-ExcelToolkitDiagnosticsPass
    if (-not $gate.GateOk) {
        Write-Host ("FAIL: {0}" -f $gate.Message) -ForegroundColor Red
        if (-not [string]::IsNullOrWhiteSpace([string]$gate.ReportTextPath)) {
            Write-Host ("  See: {0}" -f $gate.ReportTextPath) -ForegroundColor Yellow
        }
        return $false
    }
    if ($gate.GateMode -eq 'ran') {
        Write-Host ("Diagnostics auto-ran and passed. Report: {0}" -f $gate.ReportTextPath) -ForegroundColor DarkGray
    }
    return $true
}

function Get-ExcelMenuToolkitVersion {
    <#
    .SYNOPSIS
        excel-toolkit version for menu banners (same source as Get-ExcelToolkitVersion).
    #>
    [CmdletBinding()]
    param()

    if (Get-Command -Name Get-ExcelToolkitVersion -ErrorAction SilentlyContinue) {
        return [string](Get-ExcelToolkitVersion)
    }
    if (-not (Test-Path -LiteralPath $toolkitModulePath)) {
        return 'unknown'
    }
    Import-Module -Name $toolkitModulePath -Force -ErrorAction Stop
    return [string](Get-ExcelToolkitVersion)
}

function Wait-ForEnter {
    param([string]$Prompt = 'Press Enter to return to the menu...')
    Write-Host ''
    try {
        $null = Read-Host $Prompt
    }
    catch { }
}

function Get-SchemaDir {
    return (Join-Path $repoRoot 'wq_schema')
}

function Get-DefaultSchemaPathForFormat {
    param([string]$Format)

    $schemaDir = Get-SchemaDir
    if ($Format -eq 'Csv') {
        $preferred = Join-Path $schemaDir 'wq_schema.csv'
        if (Test-Path -LiteralPath $preferred) { return $preferred }
        if (Test-Path -LiteralPath $schemaDir) {
            $hit = Get-ChildItem -LiteralPath $schemaDir -Filter '*schema*.csv' -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($null -ne $hit) { return $hit.FullName }
        }
        return $preferred
    }

    if ($Format -eq 'Json') {
        $preferred = Join-Path $schemaDir 'wq_schema.json'
        if (Test-Path -LiteralPath $preferred) { return $preferred }
        if (Test-Path -LiteralPath $schemaDir) {
            $hit = Get-ChildItem -LiteralPath $schemaDir -Filter '*schema*.json' -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($null -ne $hit) { return $hit.FullName }
        }
        return $preferred
    }

    # Auto: prefer JSON then CSV under wq_schema\
    $j = Join-Path $schemaDir 'wq_schema.json'
    if (Test-Path -LiteralPath $j) { return $j }
    if (Test-Path -LiteralPath $schemaDir) {
        $jHit = Get-ChildItem -LiteralPath $schemaDir -Filter '*schema*.json' -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $jHit) { return $jHit.FullName }
        $c = Join-Path $schemaDir 'wq_schema.csv'
        if (Test-Path -LiteralPath $c) { return $c }
        $cHit = Get-ChildItem -LiteralPath $schemaDir -Filter '*schema*.csv' -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $cHit) { return $cHit.FullName }
    }
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
    Write-Host 'Opens workbook(s) (password-protected files prompt for a password) and writes CSV under import\ by default.' -ForegroundColor DarkGray
    Write-Host ''

    $paths = @(Select-ImportInputs -FilterKind Excel -Title 'Excel files under import\:')
    if ($paths.Count -eq 0) {
        Write-Host 'No workbook selected.' -ForegroundColor Yellow
        return
    }

    $ok = 0
    $fail = 0
    foreach ($excelPath in $paths) {
        if (-not (Test-IsExcelPath -Path $excelPath)) {
            Write-Host ("Skipping non-Excel path: {0}" -f $excelPath) -ForegroundColor Yellow
            $fail++
            continue
        }
        if (-not (Test-Path -LiteralPath $excelPath)) {
            Write-Host ("Excel file not found: {0}" -f $excelPath) -ForegroundColor Red
            $fail++
            continue
        }
        $out = Invoke-ImportExcelFile -ExcelPath $excelPath
        if ($null -ne $out) { $ok++ } else { $fail++ }
    }
    Write-Host ("Import done: {0} succeeded, {1} failed." -f $ok, $fail) -ForegroundColor $(if ($fail -eq 0) { 'Green' } else { 'Yellow' })
}

function Invoke-ProcessMyData {
    <#
    .SYNOPSIS
        Guided entry: discover import\ files, select with ranges, route to pipeline/score/export/import.
    #>
    Write-Host ''
    Write-Host 'Process my data' -ForegroundColor Cyan
    Write-Host 'Pick files under import\ (CSV and/or Excel). Ranges like 1-3 or 1,3-5 work.' -ForegroundColor DarkGray
    Write-Host ''

    $selected = @(Select-ImportInputs -FilterKind All)
    if ($selected.Count -eq 0) {
        Write-Host 'No files selected.' -ForegroundColor Yellow
        return
    }

    $csvPaths = New-Object System.Collections.Generic.List[string]
    $excelPaths = New-Object System.Collections.Generic.List[string]
    foreach ($p in $selected) {
        if (Test-IsCsvPath -Path $p) {
            $csvPaths.Add($p)
        }
        elseif (Test-IsExcelPath -Path $p) {
            $excelPaths.Add($p)
        }
        else {
            Write-Host ("Unsupported file type (skipped): {0}" -f $p) -ForegroundColor Yellow
        }
    }

    # Import Excel workbooks first so mixed selections become CSVs for downstream actions
    if ($excelPaths.Count -gt 0) {
        Write-Host ''
        Write-Host ("Importing {0} Excel file(s) to CSV..." -f $excelPaths.Count) -ForegroundColor Cyan
        foreach ($xp in $excelPaths) {
            $imported = Invoke-ImportExcelFile -ExcelPath $xp
            if ($null -ne $imported -and -not [string]::IsNullOrWhiteSpace($imported)) {
                if (-not ($csvPaths -contains $imported)) {
                    $csvPaths.Add($imported)
                }
            }
        }
    }

    if ($csvPaths.Count -eq 0) {
        Write-Host 'No CSV available to process after selection/import.' -ForegroundColor Yellow
        return
    }

    Write-Host ''
    Write-Host ("Ready to process {0} CSV file(s):" -f $csvPaths.Count) -ForegroundColor Cyan
    foreach ($c in $csvPaths) {
        Write-Host ("  - {0}" -f $c) -ForegroundColor DarkGray
    }

    Show-ExcelMenuMultiFilePreview -CsvPaths @($csvPaths.ToArray())

    # Defaults: full pipeline for CSV work; if selection was pure Excel, still offer pipeline first after import
    $defaultAction = '1'
    $menuVersion = Get-ExcelMenuToolkitVersion
    Write-Host ''
    Write-Host 'What should I do with the selected file(s)?' -ForegroundColor Cyan
    Write-Host ("excel-toolkit {0}" -f $menuVersion) -ForegroundColor DarkGray
    Write-Host 'Excel is the human deliverable; scored CSV is still written under output\.' -ForegroundColor DarkGray
    Write-Host '  [1] Full pipeline (Score -> Excel deliverable)     <- recommended' -ForegroundColor DarkGray
    Write-Host '  [2] Score only (CSV artifacts)' -ForegroundColor DarkGray
    Write-Host '  [3] Export only (CSV -> Excel deliverable, no scoring)' -ForegroundColor DarkGray
    Write-Host '  [4] Build worklist (Score + Groups + Worklist Excel)' -ForegroundColor DarkGray
    Write-Host '  [5] Express score' -ForegroundColor DarkGray
    $action = Read-Host ("Choice [{0}]" -f $defaultAction)
    if ([string]::IsNullOrWhiteSpace($action)) {
        $action = $defaultAction
    }

    $pathsArray = @($csvPaths.ToArray())
    switch ($action.Trim()) {
        '1' {
            Invoke-KpiScoreExportMenu -InputPaths $pathsArray
        }
        '2' {
            Invoke-KpiScoreExportMenu -ScoreOnly -InputPaths $pathsArray
        }
        '3' {
            $pw = Read-OptionalExportPassword
            if ($null -ne $pw) {
                Invoke-MenuExportCsv -CsvPaths $pathsArray -Password $pw
            }
            else {
                Invoke-MenuExportCsv -CsvPaths $pathsArray
            }
        }
        '4' {
            Invoke-KpiScoreExportMenu -Worklist -InputPaths $pathsArray
        }
        '5' {
            Invoke-KpiScoreExportMenu -Express -InputPaths $pathsArray
        }
        default {
            Write-Host 'Unrecognized choice; cancelling.' -ForegroundColor Yellow
        }
    }
}

function Test-ExcelMenuHostInteractive {
    <#
    .SYNOPSIS
        True when the menu host can run Python guided mapping (console TTY).
    #>
    [CmdletBinding()]
    param()

    if (-not [Environment]::UserInteractive) {
        return $false
    }
    try {
        # Redirected stdin (automation) cannot complete Python input() prompts.
        if ([Console]::IsInputRedirected) {
            return $false
        }
    }
    catch {
        # Some hosts lack Console; treat as non-interactive for safety.
        return $false
    }
    return $true
}

function Test-KpiScoreMappingNeedsGuide {
    <#
    .SYNOPSIS
        True when missing or ambiguous roles require guided mapping.
        Low-confidence alone does not force a guide (warn + continue instead).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $ScoreJson
    )

    if ($null -eq $ScoreJson) {
        return $false
    }

    $names = @($ScoreJson.PSObject.Properties.Name)

    if ($names -contains 'MissingRoles') {
        $missing = @($ScoreJson.MissingRoles)
        if ($missing.Count -gt 0) {
            return $true
        }
    }

    if ($names -contains 'AmbiguousRoles' -and $null -ne $ScoreJson.AmbiguousRoles) {
        $ak = @(
            $ScoreJson.AmbiguousRoles.PSObject.Properties |
                ForEach-Object { [string]$_.Name } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )
        if ($ak.Count -gt 0) {
            return $true
        }
    }

    return $false
}

function Get-KpiScoreLowConfidenceRoles {
    <#
    .SYNOPSIS
        Return low-confidence role names from score JSON (empty if none).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $ScoreJson
    )

    if ($null -eq $ScoreJson) {
        return @()
    }
    if ($ScoreJson.PSObject.Properties.Name -notcontains 'LowConfidenceRoles') {
        return @()
    }
    return @($ScoreJson.LowConfidenceRoles | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
}

function Test-KpiScoreRankIsFull {
    <#
    .SYNOPSIS
        True when score JSON RankCompleteness is full.
        Missing RankCompleteness after guided/interactive mapping is treated as
        NOT full (fail-safe) so the partial-rank banner still applies.
        Other paths with missing field still assume full (legacy automation JSON).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $ScoreJson
    )

    if ($null -eq $ScoreJson) {
        return $true
    }
    $names = @($ScoreJson.PSObject.Properties.Name)
    $guided = $false
    if ($names -contains 'GuidedMappingApplied') {
        try { $guided = [bool]$ScoreJson.GuidedMappingApplied } catch { $guided = $false }
    }
    if (-not $guided -and ($names -contains 'InteractiveMapping')) {
        try { $guided = [bool]$ScoreJson.InteractiveMapping } catch { $guided = $false }
    }
    if ($names -notcontains 'RankCompleteness') {
        # Fail-safe: guided path without completeness must not skip the banner.
        if ($guided) { return $false }
        return $true
    }
    $rc = [string]$ScoreJson.RankCompleteness
    if ([string]::IsNullOrWhiteSpace($rc)) {
        if ($guided) { return $false }
        return $true
    }
    return ($rc.Trim().ToLowerInvariant() -eq 'full')
}

function Show-KpiPartialRankBanner {
    <#
    .SYNOPSIS
        Print a high-visibility partial-rank summary from score JSON.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $ScoreJson
    )

    if ($null -eq $ScoreJson) {
        return
    }

    $names = @($ScoreJson.PSObject.Properties.Name)
    $rc = if ($names -contains 'RankCompleteness') { [string]$ScoreJson.RankCompleteness } else { 'partial' }
    Write-Host ''
    Write-Host '  *** PARTIAL PRIORITY RANK ***' -ForegroundColor Yellow
    Write-Host ("  RankCompleteness: {0}" -f $rc) -ForegroundColor Yellow

    if ($names -contains 'IncompleteReasons') {
        $reasons = @($ScoreJson.IncompleteReasons)
        if ($reasons.Count -gt 0) {
            Write-Host ("  Reasons: {0}" -f ($reasons -join ', ')) -ForegroundColor Yellow
        }
    }
    if ($names -contains 'MissingRoles') {
        $m = @($ScoreJson.MissingRoles)
        if ($m.Count -gt 0) {
            Write-Host ("  Missing roles: {0}" -f ($m -join ', ')) -ForegroundColor Yellow
        }
    }
    if ($names -contains 'SkippedMetrics' -and $null -ne $ScoreJson.SkippedMetrics) {
        $sk = @($ScoreJson.SkippedMetrics.PSObject.Properties.Name)
        if ($sk.Count -gt 0) {
            Write-Host ("  Skipped metrics: {0}" -f ($sk -join ', ')) -ForegroundColor Yellow
        }
    }
    if ($names -contains 'LowCoverageMetrics') {
        $lc = @($ScoreJson.LowCoverageMetrics)
        if ($lc.Count -gt 0) {
            Write-Host ("  Low coverage metrics: {0}" -f ($lc -join ', ')) -ForegroundColor Yellow
        }
    }
    Write-Host '  Scores may not be a full V1 ranking. Fix mapping/dates or accept partial results.' -ForegroundColor DarkYellow
    Write-Host '  Tip: kpi-analytics score --strict full fails closed for automation.' -ForegroundColor DarkGray
    Write-Host ''
}

function Confirm-KpiKeepPartialRankOutputs {
    <#
    .SYNOPSIS
        Ask whether to keep partial scored CSVs. Default N.
        Returns $true to keep / continue; $false to discard.
    #>
    [CmdletBinding()]
    param()

    $ans = Read-Host '  Accept partial ranking and keep outputs? [y/N]'
    return ($ans -match '^[Yy]')
}

function Remove-KpiScoredOutputPair {
    <#
    .SYNOPSIS
        Delete scored detail + summary + optional groups CSV paths (partial rank decline).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ScoredCsv,

        [Parameter(Mandatory = $false)]
        [string]$SummaryCsv,

        [Parameter(Mandatory = $false)]
        [string]$GroupsCsv
    )

    foreach ($p in @($ScoredCsv, $SummaryCsv, $GroupsCsv)) {
        if (-not [string]::IsNullOrWhiteSpace($p) -and (Test-Path -LiteralPath $p)) {
            Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
            Write-Host ("  Removed: {0}" -f $p) -ForegroundColor DarkGray
        }
    }
}

function Get-KpiSiblingMappingPath {
    <#
    .SYNOPSIS
        Return path to <stem>_mapping.json next to a CSV when the file exists.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CsvPath
    )

    $dir = [System.IO.Path]::GetDirectoryName($CsvPath)
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($CsvPath)
    if ([string]::IsNullOrWhiteSpace($dir) -or [string]::IsNullOrWhiteSpace($stem)) {
        return $null
    }
    $candidate = Join-Path $dir ('{0}_mapping.json' -f $stem)
    if (Test-Path -LiteralPath $candidate) {
        return $candidate
    }
    return $null
}

function ConvertFrom-KpiScoreJsonText {
    <#
    .SYNOPSIS
        Parse score JSON from stdout (last JSON object line preferred).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $null
    }

    $trimmed = $Text.Trim()
    $lines = @($trimmed -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        $line = $lines[$i].Trim()
        if ($line.StartsWith('{')) {
            try {
                return ($line | ConvertFrom-Json -ErrorAction Stop)
            }
            catch { }
        }
    }
    try {
        return ($trimmed | ConvertFrom-Json -ErrorAction Stop)
    }
    catch {
        return $null
    }
}

function ConvertTo-KpiScoreCmdArgumentLine {
    <#
    .SYNOPSIS
        Build a cmd.exe /c argument string for kpi-analytics.cmd (quoted args).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IEnumerable]$ScoreArgs
    )

    $quoted = foreach ($a in $ScoreArgs) {
        if ($null -eq $a) { '""'; continue }
        $s = [string]$a
        if ($s -match '[\s"]') {
            '"' + ($s.Replace('"', '""')) + '"'
        }
        else {
            $s
        }
    }
    $inner = ($quoted -join ' ')
    return ('/c ""{0}" {1}"' -f $kpiAnalyticsCmd, $inner)
}

function Invoke-KpiAnalyticsProfileList {
    <#
    .SYNOPSIS
        Call sibling kpi-analytics.cmd profile-list --json (metadata only; no scoring).
    .OUTPUTS
        PSCustomObject: ExitCode, Success, Profiles (array of entries), ProfilesDir, Message, Json
    #>
    [CmdletBinding()]
    param()

    $empty = [pscustomobject]@{
        ExitCode    = 1
        Success     = $false
        Profiles    = @()
        ProfilesDir = ''
        Message     = ''
        Json        = $null
    }

    if (-not (Test-Path -LiteralPath $kpiAnalyticsCmd)) {
        $empty.Message = ("kpi-analytics launcher not found: {0}" -f $kpiAnalyticsCmd)
        return $empty
    }

    $listArgs = [System.Collections.Generic.List[string]]::new()
    $listArgs.Add('profile-list')
    $listArgs.Add('--json')

    $tmpOut = [System.IO.Path]::GetTempFileName()
    $tmpErr = [System.IO.Path]::GetTempFileName()
    $exitCode = 1
    $stdout = ''
    $stderr = ''

    try {
        $argLine = ConvertTo-KpiScoreCmdArgumentLine -ScoreArgs $listArgs
        $proc = Start-Process -FilePath 'cmd.exe' `
            -ArgumentList $argLine `
            -WorkingDirectory $kpiAnalyticsDir `
            -Wait -PassThru -NoNewWindow `
            -RedirectStandardOutput $tmpOut `
            -RedirectStandardError $tmpErr

        if ($null -ne $proc) {
            $exitCode = [int]$proc.ExitCode
        }
        if (Test-Path -LiteralPath $tmpOut) {
            $stdout = [System.IO.File]::ReadAllText($tmpOut)
        }
        if (Test-Path -LiteralPath $tmpErr) {
            $stderr = [System.IO.File]::ReadAllText($tmpErr)
        }
    }
    catch {
        $empty.Message = $_.Exception.Message
        return $empty
    }
    finally {
        Remove-Item -LiteralPath $tmpOut, $tmpErr -Force -ErrorAction SilentlyContinue
    }

    $jsonObj = ConvertFrom-KpiScoreJsonText -Text $stdout
    $profiles = @()
    $profilesDir = ''
    $ok = ($exitCode -eq 0)
    $msg = ''

    if ($null -ne $jsonObj) {
        $names = @($jsonObj.PSObject.Properties.Name)
        if ($names -contains 'Success') {
            try { $ok = $ok -and [bool]$jsonObj.Success } catch { }
        }
        if ($names -contains 'ProfilesDir') {
            $profilesDir = [string]$jsonObj.ProfilesDir
        }
        if ($names -contains 'Profiles' -and $null -ne $jsonObj.Profiles) {
            $profiles = @($jsonObj.Profiles)
        }
        if ($names -contains 'Message' -and -not [string]::IsNullOrWhiteSpace([string]$jsonObj.Message)) {
            $msg = [string]$jsonObj.Message
        }
    }
    elseif (-not [string]::IsNullOrWhiteSpace($stderr)) {
        $msg = $stderr.Trim()
        $ok = $false
    }
    elseif (-not $ok) {
        $msg = 'profile-list failed (no JSON).'
    }

    return [pscustomobject]@{
        ExitCode    = $exitCode
        Success     = $ok
        Profiles    = $profiles
        ProfilesDir = $profilesDir
        Message     = $msg
        Json        = $jsonObj
    }
}

function Select-KpiScoringProfile {
    <#
    .SYNOPSIS
        Interactive scoring-profile picker for menu score paths.
    .DESCRIPTION
        Returns $null for package default (no --profile), or a non-empty token
        (profile name or path) for kpi-analytics score --profile.
        Lists metadata via profile-list only; does not merge configs or score.
    .PARAMETER SkipPrompt
        When set, return $null without prompting (non-interactive hosts).
    #>
    [CmdletBinding()]
    param(
        [switch]$SkipPrompt
    )

    if ($SkipPrompt -or -not (Test-ExcelMenuHostInteractive)) {
        return $null
    }

    $listResult = $null
    $validEntries = @()

    while ($true) {
        Write-Host ''
        Write-Host 'Scoring profile (optional POI focus; not a column mapping profile):' -ForegroundColor Cyan
        Write-Host '  [1] Balanced (package default)     <- recommended' -ForegroundColor DarkGray

        $listResult = Invoke-KpiAnalyticsProfileList
        $validEntries = @()
        $optNum = 2

        if (-not $listResult.Success) {
            $failMsg = $listResult.Message
            if ([string]::IsNullOrWhiteSpace($failMsg)) {
                $failMsg = 'Could not list profiles via kpi-analytics profile-list.'
            }
            Write-Host ("  (List unavailable: {0})" -f $failMsg) -ForegroundColor Yellow
            Write-Host '  Use [1] default or [P] to type a known name/path.' -ForegroundColor Yellow
        }
        else {
            foreach ($p in @($listResult.Profiles)) {
                if ($null -eq $p) { continue }
                $pNames = @($p.PSObject.Properties.Name)
                $isValid = $true
                if ($pNames -contains 'Valid') {
                    try { $isValid = [bool]$p.Valid } catch { $isValid = $true }
                }
                $name = ''
                if ($pNames -contains 'Name') { $name = [string]$p.Name }
                if ([string]::IsNullOrWhiteSpace($name) -and ($pNames -contains 'FileName')) {
                    $name = [System.IO.Path]::GetFileNameWithoutExtension([string]$p.FileName)
                }
                $desc = ''
                if ($pNames -contains 'Description') { $desc = [string]$p.Description }

                if (-not $isValid) {
                    $label = if (-not [string]::IsNullOrWhiteSpace($name)) { $name } else { '(invalid entry)' }
                    Write-Host ("  [skip] {0} — invalid (not selectable)" -f $label) -ForegroundColor DarkYellow
                    continue
                }
                if ([string]::IsNullOrWhiteSpace($name)) {
                    continue
                }

                $validEntries += [pscustomobject]@{
                    Number = $optNum
                    Name   = $name
                }
                $descShort = $desc
                if (-not [string]::IsNullOrWhiteSpace($descShort) -and $descShort.Length -gt 72) {
                    $descShort = $descShort.Substring(0, 69) + '...'
                }
                if ([string]::IsNullOrWhiteSpace($descShort)) {
                    Write-Host ("  [{0}] {1}" -f $optNum, $name) -ForegroundColor DarkGray
                }
                else {
                    Write-Host ("  [{0}] {1} — {2}" -f $optNum, $name, $descShort) -ForegroundColor DarkGray
                }
                $optNum++
            }
            if ($validEntries.Count -eq 0) {
                Write-Host '  (No valid profiles found under kpi-analytics\profiles\.)' -ForegroundColor Yellow
            }
        }

        Write-Host '  [L] List all profiles (refresh)' -ForegroundColor DarkGray
        Write-Host '  [P] Enter profile name or path' -ForegroundColor DarkGray
        $choice = Read-Host 'Choice [1]'
        if ([string]::IsNullOrWhiteSpace($choice)) {
            $choice = '1'
        }
        $choice = $choice.Trim()

        if ($choice -match '^[Ll]$') {
            continue
        }

        if ($choice -match '^[Pp]$') {
            $typed = Read-Host 'Profile name or path (blank cancels)'
            if ([string]::IsNullOrWhiteSpace($typed)) {
                continue
            }
            $token = $typed.Trim()
            Write-Host ("Using scoring profile: {0}" -f $token) -ForegroundColor Cyan
            return $token
        }

        if ($choice -eq '1') {
            Write-Host 'Using package default scoring (no --profile).' -ForegroundColor DarkGray
            return $null
        }

        $asInt = 0
        if ([int]::TryParse($choice, [ref]$asInt)) {
            $hit = @($validEntries | Where-Object { $_.Number -eq $asInt })
            if ($hit.Count -eq 1) {
                $token = [string]$hit[0].Name
                Write-Host ("Using scoring profile: {0}" -f $token) -ForegroundColor Cyan
                return $token
            }
        }

        Write-Host 'Unrecognized choice; try again (1 = default, L = refresh, P = type name).' -ForegroundColor Yellow
    }
}

function Show-KpiScoringProfilesHelp {
    <#
    .SYNOPSIS
        Advanced: list scoring profiles via KPI CLI and print composition help.
    #>
    [CmdletBinding()]
    param()

    Write-Host ''
    Write-Host 'Scoring profiles (list / CLI help)' -ForegroundColor Cyan
    Write-Host 'Metadata only — no claim rows. Menu scoring passes --profile to kpi-analytics.' -ForegroundColor DarkGray
    Write-Host ''

    $listResult = Invoke-KpiAnalyticsProfileList
    if (-not $listResult.Success) {
        $failMsg = $listResult.Message
        if ([string]::IsNullOrWhiteSpace($failMsg)) {
            $failMsg = 'profile-list failed.'
        }
        Write-Host ("FAIL: {0}" -f $failMsg) -ForegroundColor Red
        Write-Host 'Try: kpi-analytics\kpi-analytics.cmd profile-list --json' -ForegroundColor Yellow
    }
    else {
        if (-not [string]::IsNullOrWhiteSpace($listResult.ProfilesDir)) {
            Write-Host ("Profiles dir: {0}" -f $listResult.ProfilesDir) -ForegroundColor DarkGray
        }
        $count = @($listResult.Profiles).Count
        Write-Host ("Found {0} profile file(s):" -f $count) -ForegroundColor Cyan
        if ($count -eq 0) {
            Write-Host '  (none)' -ForegroundColor DarkGray
        }
        else {
            foreach ($p in @($listResult.Profiles)) {
                if ($null -eq $p) { continue }
                $pNames = @($p.PSObject.Properties.Name)
                $name = if ($pNames -contains 'Name') { [string]$p.Name } else { '?' }
                $desc = if ($pNames -contains 'Description') { [string]$p.Description } else { '' }
                $valid = $true
                if ($pNames -contains 'Valid') {
                    try { $valid = [bool]$p.Valid } catch { $valid = $true }
                }
                $flag = if ($valid) { 'ok' } else { 'INVALID' }
                if ([string]::IsNullOrWhiteSpace($desc)) {
                    Write-Host ("  - {0} [{1}]" -f $name, $flag) -ForegroundColor DarkGray
                }
                else {
                    Write-Host ("  - {0} [{1}] — {2}" -f $name, $flag, $desc) -ForegroundColor DarkGray
                }
            }
        }
    }

    Write-Host ''
    Write-Host 'CLI tips (from repo root or kpi-analytics\):' -ForegroundColor Cyan
    Write-Host '  kpi-analytics.cmd profile-list --json' -ForegroundColor DarkGray
    Write-Host '  kpi-analytics.cmd profile-show maximize_cash --json' -ForegroundColor DarkGray
    Write-Host '  kpi-analytics.cmd score --profile maximize_cash --json' -ForegroundColor DarkGray
    Write-Host '  Package default = omit --profile (Balanced).' -ForegroundColor DarkGray
    Write-Host '  Do not put claim rows in profile JSON. Prefer user_*.json for local saves.' -ForegroundColor DarkGray
    Write-Host '  Full contract: kpi-analytics\CLI-GUIDE.md (Scoring profiles).' -ForegroundColor DarkGray
    Write-Host '  Process my data (Full pipeline / Score only / Build worklist) can pick a profile interactively.' -ForegroundColor DarkGray
}

function Select-KpiScoreInvokeResult {
    <#
    .SYNOPSIS
        Normalize score invoke output to a single object that has ExitCode.
        Guards against accidental multi-object pipeline pollution.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        $Raw
    )

    if ($null -eq $Raw) {
        return $null
    }

    $items = @($Raw)
    for ($i = $items.Count - 1; $i -ge 0; $i--) {
        $item = $items[$i]
        if ($null -eq $item) { continue }
        try {
            if ($item.PSObject.Properties.Name -contains 'ExitCode') {
                return $item
            }
        }
        catch { }
    }

    # Fallback: last object even if shape is unexpected (caller will fail clearly).
    return $items[$items.Count - 1]
}

function New-KpiScoreInvokeResult {
    <#
    .SYNOPSIS
        Build the standard score-invoke result object (single pipeline object).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$ExitCode,

        [Parameter(Mandatory = $false)]
        [string]$StdOut = '',

        [Parameter(Mandatory = $false)]
        [string]$StdErr = '',

        [Parameter(Mandatory = $false)]
        $Json = $null
    )

    return [pscustomobject]@{
        ExitCode = $ExitCode
        StdOut   = $StdOut
        StdErr   = $StdErr
        Json     = $Json
    }
}

function Invoke-KpiAnalyticsScore {
    <#
    .SYNOPSIS
        Call sibling kpi-analytics.cmd score with absolute paths; return exit + JSON.

    .DESCRIPTION
        Default path redirects stdout/stderr and requests --json (automation-safe).
        -InteractiveMapping runs without stream redirects so Python can use a TTY for
        guided column mapping (no --json). Uses Start-Process (not &) so Python stdout
        does not pollute the PowerShell pipeline / return value.
        Caller should prefer Invoke-KpiAnalyticsScoreWithMapping for menu flows.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$CsvPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [string]$SummaryPath,

        [Parameter(Mandatory = $false)]
        [string]$MappingPath,

        [Parameter(Mandatory = $false)]
        [string]$Profile,

        [Parameter(Mandatory = $false)]
        [string]$GroupPreset,

        [Parameter(Mandatory = $false)]
        [string]$GroupsPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputMode,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun,

        [Parameter(Mandatory = $false)]
        [switch]$InteractiveMapping
    )

    if (-not (Test-Path -LiteralPath $kpiAnalyticsCmd)) {
        throw ("kpi-analytics launcher not found: {0}" -f $kpiAnalyticsCmd)
    }

    $scoreArgs = [System.Collections.Generic.List[string]]::new()
    $scoreArgs.Add('score')
    $scoreArgs.Add('--csv')
    $scoreArgs.Add($CsvPath)
    $scoreArgs.Add('--output')
    $scoreArgs.Add($OutputPath)
    $scoreArgs.Add('--summary')
    $scoreArgs.Add($SummaryPath)
    if (-not [string]::IsNullOrWhiteSpace($MappingPath)) {
        $scoreArgs.Add('--mapping')
        $scoreArgs.Add($MappingPath)
    }
    if (-not [string]::IsNullOrWhiteSpace($Profile)) {
        $scoreArgs.Add('--profile')
        $scoreArgs.Add($Profile)
    }
    if (-not [string]::IsNullOrWhiteSpace($GroupPreset)) {
        $scoreArgs.Add('--group-preset')
        $scoreArgs.Add($GroupPreset)
    }
    if (-not [string]::IsNullOrWhiteSpace($GroupsPath)) {
        $scoreArgs.Add('--groups')
        $scoreArgs.Add($GroupsPath)
    }
    if (-not [string]::IsNullOrWhiteSpace($OutputMode)) {
        $scoreArgs.Add('--output-mode')
        $scoreArgs.Add($OutputMode)
    }
    if ($DryRun) {
        $scoreArgs.Add('--dry-run')
    }
    if ($InteractiveMapping) {
        $scoreArgs.Add('--interactive-mapping')
    }

    $exitCode = 1
    $stdout = ''
    $stderr = ''

    if ($InteractiveMapping) {
        # Inherit this console so sys.stdin/stdout.isatty() can succeed in Python.
        # Do not use --json or RedirectStandard* — prompts stay on the console.
        # Use Start-Process (not &) so console text is NOT written to the PS pipeline
        # (which would make $result.ExitCode fail on a string[]).
        try {
            $argLine = ConvertTo-KpiScoreCmdArgumentLine -ScoreArgs $scoreArgs
            $proc = Start-Process -FilePath 'cmd.exe' `
                -ArgumentList $argLine `
                -WorkingDirectory $kpiAnalyticsDir `
                -Wait -PassThru -NoNewWindow
            if ($null -ne $proc) {
                $exitCode = [int]$proc.ExitCode
            }
        }
        catch {
            $stderr = $_.Exception.Message
            $exitCode = 1
        }

        $synthOk = ($exitCode -eq 0)
        # Prefer filesystem proof when exit code is available.
        if ($synthOk -and -not (Test-Path -LiteralPath $OutputPath)) {
            $synthOk = $false
            $exitCode = 1
        }
        $synthMsg = if ($synthOk) {
            'Score complete (interactive mapping).'
        }
        else {
            if (-not [string]::IsNullOrWhiteSpace($stderr)) {
                $stderr
            }
            else {
                'Score failed during interactive mapping.'
            }
        }
        $jsonObj = [pscustomobject]@{
            Success              = $synthOk
            Command              = 'score'
            InputPath            = $CsvPath
            OutputPath           = $OutputPath
            SummaryPath          = $SummaryPath
            InteractiveMapping   = $true
            GuidedMappingApplied = $synthOk
            Message              = $synthMsg
        }

        # Enrich with real RankCompleteness via dry-run --json when a mapping file is
        # available so the partial-rank banner matches guided role choices. Without a
        # mapping file, leave RankCompleteness absent; Test-KpiScoreRankIsFull treats
        # guided+missing as partial (fail-safe).
        if ($synthOk) {
            $enrichMap = $MappingPath
            if ([string]::IsNullOrWhiteSpace($enrichMap)) {
                $csvItem = Get-Item -LiteralPath $CsvPath -ErrorAction SilentlyContinue
                if ($null -ne $csvItem) {
                    $candidateMap = Join-Path $csvItem.DirectoryName ($csvItem.BaseName + '_mapping.json')
                    if (Test-Path -LiteralPath $candidateMap) {
                        $enrichMap = $candidateMap
                    }
                }
            }
            if (-not [string]::IsNullOrWhiteSpace($enrichMap) -and (Test-Path -LiteralPath $enrichMap)) {
                try {
                    $enrichParams = @{
                        CsvPath            = $CsvPath
                        OutputPath         = $OutputPath
                        SummaryPath        = $SummaryPath
                        MappingPath        = $enrichMap
                        DryRun             = $true
                        InteractiveMapping = $false
                    }
                    if (-not [string]::IsNullOrWhiteSpace($Profile)) {
                        $enrichParams['Profile'] = $Profile
                    }
                    $enrichRaw = Invoke-KpiAnalyticsScore @enrichParams
                    $enrich = Select-KpiScoreInvokeResult -Raw $enrichRaw
                    if ($null -ne $enrich -and $null -ne $enrich.Json) {
                        $ej = $enrich.Json
                        $eNames = @($ej.PSObject.Properties.Name)
                        foreach ($prop in @(
                                'RankCompleteness', 'IncompleteReasons', 'ActiveMetrics',
                                'SkippedMetrics', 'LowCoverageMetrics', 'RowCount',
                                'ScoreMin', 'ScoreMax', 'ScoreMean'
                            )) {
                            if ($eNames -contains $prop) {
                                $jsonObj | Add-Member -NotePropertyName $prop -NotePropertyValue $ej.$prop -Force
                            }
                        }
                        $jsonObj | Add-Member -NotePropertyName 'GuidedMappingApplied' -NotePropertyValue $true -Force
                        $jsonObj | Add-Member -NotePropertyName 'InteractiveMapping' -NotePropertyValue $true -Force
                        $jsonObj | Add-Member -NotePropertyName 'OutputPath' -NotePropertyValue $OutputPath -Force
                        $jsonObj | Add-Member -NotePropertyName 'SummaryPath' -NotePropertyValue $SummaryPath -Force
                        if ($eNames -contains 'RankCompleteness') {
                            $jsonObj | Add-Member -NotePropertyName 'Message' -NotePropertyValue (
                                'Score complete (interactive mapping; rank metadata refreshed).'
                            ) -Force
                        }
                    }
                }
                catch {
                    Write-Verbose ("Rank completeness enrich after guided map failed: {0}" -f $_.Exception.Message)
                }
            }
        }

        return (New-KpiScoreInvokeResult -ExitCode $exitCode -StdOut $stdout -StdErr $stderr -Json $jsonObj)
    }

    # Non-interactive / automation path: capture JSON via redirected stdout.
    $scoreArgs.Add('--json')
    $tmpOut = [System.IO.Path]::GetTempFileName()
    $tmpErr = [System.IO.Path]::GetTempFileName()

    try {
        $argLine = ConvertTo-KpiScoreCmdArgumentLine -ScoreArgs $scoreArgs

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

    $jsonObj = ConvertFrom-KpiScoreJsonText -Text $stdout

    return (New-KpiScoreInvokeResult -ExitCode $exitCode -StdOut $stdout -StdErr $stderr -Json $jsonObj)
}

function Invoke-KpiAnalyticsScoreWithMapping {
    <#
    .SYNOPSIS
        Score with mapping preflight: auto-load sibling mapping; guided mapping on TTY when needed.
    .DESCRIPTION
        1) Optional sibling <stem>_mapping.json next to the CSV.
        2) Dry-run score (JSON, redirected) to inspect mapping health.
        3) If problems and host is interactive → full score with --interactive-mapping (console TTY).
        4) If problems and host is non-interactive → fail with clear guidance (no hang).
        5) If clean → full score with redirects + JSON (unchanged automation-friendly path).
        Optional -Profile is passed through to every score invoke as --profile (no merge in PS).
        Optional -GroupPreset / -GroupsPath are passed as --group-preset / --groups.
        Optional -OutputMode is passed as --output-mode (full or slim).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CsvPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [string]$SummaryPath,

        [Parameter(Mandatory = $false)]
        [string]$Profile,

        [Parameter(Mandatory = $false)]
        [string]$GroupPreset,

        [Parameter(Mandatory = $false)]
        [string]$GroupsPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputMode
    )

    $mappingPath = Get-KpiSiblingMappingPath -CsvPath $CsvPath
    if (-not [string]::IsNullOrWhiteSpace($mappingPath)) {
        Write-Host ("  Using mapping profile: {0}" -f $mappingPath) -ForegroundColor DarkGray
    }
    if (-not [string]::IsNullOrWhiteSpace($Profile)) {
        Write-Host ("  Scoring profile: {0}" -f $Profile) -ForegroundColor DarkGray
    }
    if (-not [string]::IsNullOrWhiteSpace($GroupPreset)) {
        Write-Host ("  Group preset: {0}" -f $GroupPreset) -ForegroundColor DarkGray
    }

    Write-Host '  Mapping preflight (dry-run)...' -ForegroundColor DarkGray
    $preParams = @{
        CsvPath     = $CsvPath
        OutputPath  = $OutputPath
        SummaryPath = $SummaryPath
        DryRun      = $true
    }
    if (-not [string]::IsNullOrWhiteSpace($mappingPath)) {
        $preParams['MappingPath'] = $mappingPath
    }
    if (-not [string]::IsNullOrWhiteSpace($Profile)) {
        $preParams['Profile'] = $Profile
    }
    if (-not [string]::IsNullOrWhiteSpace($GroupPreset)) {
        $preParams['GroupPreset'] = $GroupPreset
    }
    if (-not [string]::IsNullOrWhiteSpace($GroupsPath)) {
        $preParams['GroupsPath'] = $GroupsPath
    }
    if (-not [string]::IsNullOrWhiteSpace($OutputMode)) {
        $preParams['OutputMode'] = $OutputMode
    }
    $preflight = Select-KpiScoreInvokeResult -Raw (Invoke-KpiAnalyticsScore @preParams)

    if ($null -eq $preflight -or $null -eq $preflight.PSObject.Properties['ExitCode']) {
        $msg = 'Score preflight returned an unexpected result (no ExitCode).'
        return (New-KpiScoreInvokeResult -ExitCode 1 -StdErr $msg -Json ([pscustomobject]@{
                    Success = $false
                    Message = $msg
                }))
    }

    $preOk = ($preflight.ExitCode -eq 0)
    $preJson = $preflight.Json
    if ($null -ne $preJson -and $preJson.PSObject.Properties.Name -contains 'Success') {
        $preOk = $preOk -and [bool]$preJson.Success
    }

    if (-not $preOk) {
        # Hard failure (diagnostics, zero metrics, IO). Surface as-is.
        return $preflight
    }

    $needsGuide = Test-KpiScoreMappingNeedsGuide -ScoreJson $preJson
    $lowRoles = @(Get-KpiScoreLowConfidenceRoles -ScoreJson $preJson)

    if (-not $needsGuide) {
        if ($lowRoles.Count -gt 0) {
            Write-Host (
                "  Warning: low-confidence date/number samples for: {0}. " +
                "Scoring continues with current mapping; check TypeChecks / metric coverage if results look wrong."
            ) -f ($lowRoles -join ', ') -ForegroundColor Yellow
        }
        $runParams = @{
            CsvPath     = $CsvPath
            OutputPath  = $OutputPath
            SummaryPath = $SummaryPath
        }
        if (-not [string]::IsNullOrWhiteSpace($mappingPath)) {
            $runParams['MappingPath'] = $mappingPath
        }
        if (-not [string]::IsNullOrWhiteSpace($Profile)) {
            $runParams['Profile'] = $Profile
        }
        if (-not [string]::IsNullOrWhiteSpace($GroupPreset)) {
            $runParams['GroupPreset'] = $GroupPreset
        }
        if (-not [string]::IsNullOrWhiteSpace($GroupsPath)) {
            $runParams['GroupsPath'] = $GroupsPath
        }
        if (-not [string]::IsNullOrWhiteSpace($OutputMode)) {
            $runParams['OutputMode'] = $OutputMode
        }
        return (Select-KpiScoreInvokeResult -Raw (Invoke-KpiAnalyticsScore @runParams))
    }

    # Missing and/or ambiguous roles — guided mapping required.
    $bits = New-Object System.Collections.Generic.List[string]
    if ($null -ne $preJson) {
        if ($preJson.PSObject.Properties.Name -contains 'MissingRoles') {
            $m = @($preJson.MissingRoles)
            if ($m.Count -gt 0) {
                $bits.Add(('missing roles: {0}' -f ($m -join ', ')))
            }
        }
        if ($preJson.PSObject.Properties.Name -contains 'AmbiguousRoles' -and $null -ne $preJson.AmbiguousRoles) {
            $ak = @(
                $preJson.AmbiguousRoles.PSObject.Properties |
                    ForEach-Object { [string]$_.Name } |
                    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            )
            if ($ak.Count -gt 0) {
                $bits.Add(('ambiguous: {0}' -f ($ak -join ', ')))
            }
        }
        if ($lowRoles.Count -gt 0) {
            $bits.Add(('low confidence: {0}' -f ($lowRoles -join ', ')))
        }
    }
    $problemText = if ($bits.Count -gt 0) { ($bits -join '; ') } else { 'column mapping needs review' }

    if (-not (Test-ExcelMenuHostInteractive)) {
        $msg = (
            "Column mapping is incomplete ({0}). " +
            "Re-run from an interactive console (Process my data), or pass a mapping profile " +
            "via kpi-analytics score --mapping path.json / --interactive-mapping."
        ) -f $problemText
        Write-Host ("  FAIL: {0}" -f $msg) -ForegroundColor Red
        return [pscustomobject]@{
            ExitCode = 1
            StdOut   = ''
            StdErr   = $msg
            Json     = [pscustomobject]@{
                Success            = $false
                Command            = 'score'
                InputPath          = $CsvPath
                OutputPath         = $OutputPath
                SummaryPath        = $SummaryPath
                InteractiveMapping = $false
                Message            = $msg
            }
        }
    }

    Write-Host ("  Mapping needs attention ({0})." -f $problemText) -ForegroundColor Yellow
    Write-Host '  Starting guided column mapping (follow prompts; s=skip role, q=abort)...' -ForegroundColor Cyan

    $guideParams = @{
        CsvPath            = $CsvPath
        OutputPath         = $OutputPath
        SummaryPath        = $SummaryPath
        InteractiveMapping = $true
    }
    if (-not [string]::IsNullOrWhiteSpace($mappingPath)) {
        $guideParams['MappingPath'] = $mappingPath
    }
    if (-not [string]::IsNullOrWhiteSpace($Profile)) {
        $guideParams['Profile'] = $Profile
    }
    if (-not [string]::IsNullOrWhiteSpace($GroupPreset)) {
        $guideParams['GroupPreset'] = $GroupPreset
    }
    if (-not [string]::IsNullOrWhiteSpace($GroupsPath)) {
        $guideParams['GroupsPath'] = $GroupsPath
    }
    if (-not [string]::IsNullOrWhiteSpace($OutputMode)) {
        $guideParams['OutputMode'] = $OutputMode
    }
    return (Select-KpiScoreInvokeResult -Raw (Invoke-KpiAnalyticsScore @guideParams))
}

function Select-KpiOutputMode {
    <#
    .SYNOPSIS
        Full (default) vs slim WQ+POI scores. Slim skips the scoring-profile pick.
    #>
    [CmdletBinding()]
    param()

    Write-Host ''
    Write-Host 'Score output:' -ForegroundColor Cyan
    Write-Host '  [1] Full (WQ + v1 audit + kpi_q)     <- recommended' -ForegroundColor DarkGray
    Write-Host '  [2] Slim (WQ + score per POI preset)' -ForegroundColor DarkGray
    $choice = Read-Host 'Choice [1]'
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = '1' }
    switch ($choice.Trim()) {
        '1' { return 'full' }
        '2' { return 'slim' }
        default {
            Write-Host 'Unrecognized output choice; using Full.' -ForegroundColor Yellow
            return 'full'
        }
    }
}

function Select-KpiGroupPreset {
    <#
    .SYNOPSIS
        Interactive group-preset picker for menu worklist path.
        Returns a kpi-analytics --group-preset name, or $null if cancelled.
    #>
    [CmdletBinding()]
    param()

    Write-Host ''
    Write-Host 'Group worklist by (kpi-analytics --group-preset):' -ForegroundColor Cyan
    Write-Host '  [1] Payer + denial category     <- recommended' -ForegroundColor DarkGray
    Write-Host '  [2] Payer only' -ForegroundColor DarkGray
    Write-Host '  [3] Denial category only' -ForegroundColor DarkGray
    Write-Host '  [4] Location' -ForegroundColor DarkGray
    Write-Host '  [0] Cancel' -ForegroundColor DarkGray
    $choice = Read-Host 'Choice [1]'
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = '1' }
    switch ($choice.Trim()) {
        '1' { return 'payer_category' }
        '2' { return 'payer' }
        '3' { return 'category' }
        '4' { return 'location' }
        '0' { return $null }
        default {
            Write-Host 'Unrecognized group choice; cancelling.' -ForegroundColor Yellow
            return $null
        }
    }
}

function ConvertTo-ExcelMenuWqFileToken {
    <#
    .SYNOPSIS
        Sanitize a WQ label for [WQ]_MM-DD-YYYY.xlsx names (freeze: letters, digits, _ , -).
    #>
    [CmdletBinding()]
    param(
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return 'wq'
    }
    $chars = $Text.ToCharArray()
    $buf = New-Object System.Text.StringBuilder
    foreach ($ch in $chars) {
        if ([char]::IsLetterOrDigit($ch) -or $ch -eq '_' -or $ch -eq '-') {
            [void]$buf.Append($ch)
        }
        else {
            [void]$buf.Append('_')
        }
    }
    $out = $buf.ToString().Trim('_')
    if ([string]::IsNullOrWhiteSpace($out)) {
        return 'wq'
    }
    return $out
}

function ConvertTo-ExcelMenuOptionalDouble {
    <#
    .SYNOPSIS
        Parse a CSV cell as a number (invariant). Returns $null when blank or not numeric.
    #>
    [CmdletBinding()]
    param(
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $null
    }
    $t = $Text.Trim()
    if ($t.Length -eq 0) {
        return $null
    }
    $t = $t.Replace('$', '').Replace(',', '')
    $n = 0.0
    if ([double]::TryParse($t, [System.Globalization.NumberStyles]::Float,
            [System.Globalization.CultureInfo]::InvariantCulture, [ref]$n)) {
        return $n
    }
    return $null
}

function Get-ExcelMenuCsvHeaderMatch {
    param(
        [string[]]$Headers,
        [string]$Name
    )

    $want = $Name.ToLowerInvariant()
    foreach ($h in @($Headers)) {
        if ([string]::IsNullOrWhiteSpace($h)) { continue }
        if ($h.ToLowerInvariant() -eq $want) {
            return $h
        }
    }
    return $null
}

function Get-KpiProfileWqLabel {
    <#
    .SYNOPSIS
        Read optional profile JSON wq_label. No config merge and no score.
    #>
    [CmdletBinding()]
    param(
        [string]$ProfileToken
    )

    if ([string]::IsNullOrWhiteSpace($ProfileToken)) {
        return $null
    }
    $path = $null
    $token = $ProfileToken.Trim()
    if ($token.IndexOfAny([char[]]@('\', '/')) -ge 0 -or $token.EndsWith('.json', [StringComparison]::OrdinalIgnoreCase)) {
        if (Test-Path -LiteralPath $token) {
            $path = $token
        }
    }
    else {
        $dir = Join-Path $kpiAnalyticsDir 'profiles'
        foreach ($cand in @(($token + '.json'), ('poi_' + $token + '.json'))) {
            $tryPath = Join-Path $dir $cand
            if (Test-Path -LiteralPath $tryPath) {
                $path = $tryPath
                break
            }
        }
    }
    if ([string]::IsNullOrWhiteSpace($path)) {
        return $null
    }
    try {
        $raw = Get-Content -LiteralPath $path -Raw -Encoding UTF8
        $obj = $raw | ConvertFrom-Json
        if ($null -eq $obj) { return $null }
        if (@($obj.PSObject.Properties.Name) -contains 'wq_label') {
            $v = [string]$obj.wq_label
            if (-not [string]::IsNullOrWhiteSpace($v)) {
                return $v.Trim()
            }
        }
    }
    catch {
        return $null
    }
    return $null
}

function Get-ExcelMenuWqLabelForFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CsvPath,

        [string]$BatchProfileLabel
    )

    if (-not [string]::IsNullOrWhiteSpace($BatchProfileLabel)) {
        return (ConvertTo-ExcelMenuWqFileToken -Text $BatchProfileLabel)
    }
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($CsvPath)
    return (ConvertTo-ExcelMenuWqFileToken -Text $stem)
}

function Get-ExcelMenuDeliverableXlsxPath {
    <#
    .SYNOPSIS
        Planned Excel deliverable path: [WQ]_MM-DD-YYYY.xlsx (or _summary).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputDir,

        [Parameter(Mandatory = $true)]
        [string]$WqLabel,

        [ValidateSet('data', 'summary')]
        [string]$Kind = 'data'
    )

    $datePart = Get-Date -Format 'MM-dd-yyyy'
    $base = '{0}_{1}' -f $WqLabel, $datePart
    if ($Kind -eq 'summary') {
        $base = '{0}_summary' -f $base
    }
    return (Join-Path $OutputDir ($base + '.xlsx'))
}

function Get-ExcelMenuCsvPreview {
    <#
    .SYNOPSIS
        File name, WQ stem, row count, max out_ins_amt. Does not call score. No PHI columns printed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CsvPath
    )

    $name = [System.IO.Path]::GetFileName($CsvPath)
    $label = ConvertTo-ExcelMenuWqFileToken -Text ([System.IO.Path]::GetFileNameWithoutExtension($CsvPath))
    $rowCount = 0
    $hasAmt = $false
    $maxAmt = $null
    if (Test-Path -LiteralPath $CsvPath) {
        $rows = @(Import-Csv -LiteralPath $CsvPath)
        $rowCount = $rows.Count
        if ($rowCount -gt 0) {
            $headers = @($rows[0].PSObject.Properties | ForEach-Object { $_.Name })
            $amtCol = Get-ExcelMenuCsvHeaderMatch -Headers $headers -Name 'out_ins_amt'
            if (-not [string]::IsNullOrWhiteSpace($amtCol)) {
                $hasAmt = $true
                foreach ($r in $rows) {
                    $cell = [string]$r.PSObject.Properties[$amtCol].Value
                    $v = ConvertTo-ExcelMenuOptionalDouble -Text $cell
                    if ($null -ne $v) {
                        if ($null -eq $maxAmt -or $v -gt $maxAmt) {
                            $maxAmt = $v
                        }
                    }
                }
            }
        }
    }
    return [pscustomobject]@{
        FileName      = $name
        WqLabel       = $label
        RowCount      = $rowCount
        HasOutInsAmt  = $hasAmt
        MaxOutInsAmt  = $maxAmt
    }
}

function Show-ExcelMenuMultiFilePreview {
    <#
    .SYNOPSIS
        Print preview for 2+ selected CSVs. Skipped when fewer than two files.
    #>
    [CmdletBinding()]
    param(
        [string[]]$CsvPaths
    )

    $paths = @($CsvPaths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($paths.Count -lt 2) {
        return
    }

    Write-Host ''
    Write-Host 'Multi-file preview (no score):' -ForegroundColor Cyan
    foreach ($p in $paths) {
        try {
            $info = Get-ExcelMenuCsvPreview -CsvPath $p
            $line = ('  {0}  wq={1}  rows={2}' -f $info.FileName, $info.WqLabel, $info.RowCount)
            if ($info.HasOutInsAmt) {
                if ($null -ne $info.MaxOutInsAmt) {
                    $line = $line + ('  max_out_ins_amt={0}' -f $info.MaxOutInsAmt)
                }
                else {
                    $line = $line + '  max_out_ins_amt=(none numeric)'
                }
            }
            Write-Host $line -ForegroundColor DarkGray
        }
        catch {
            Write-Host ("  {0}  (preview failed: {1})" -f $p, $_.Exception.Message) -ForegroundColor Yellow
        }
    }
    Write-Host 'Each file is scored separately. Groups and worklists do not span files.' -ForegroundColor DarkGray
}

function Get-ExcelMenuFileTotals {
    <#
    .SYNOPSIS
        File-level totals from already-scored columns (count / sum / max / min). Not a new score.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScoredCsv,

        [Parameter(Mandatory = $true)]
        [string]$WqLabel,

        [string]$SourceFile
    )

    $inv = [System.Globalization.CultureInfo]::InvariantCulture
    $list = New-Object System.Collections.Generic.List[object]
    $list.Add([pscustomobject]@{ metric = 'wq_label'; value = $WqLabel })
    $srcName = ''
    if (-not [string]::IsNullOrWhiteSpace($SourceFile)) {
        $srcName = [System.IO.Path]::GetFileName($SourceFile)
    }
    $list.Add([pscustomobject]@{ metric = 'source_file'; value = $srcName })

    $rows = @()
    if (Test-Path -LiteralPath $ScoredCsv) {
        $rows = @(Import-Csv -LiteralPath $ScoredCsv)
    }
    $list.Add([pscustomobject]@{ metric = 'claim_count'; value = [string]$rows.Count })

    $headers = @()
    if ($rows.Count -gt 0) {
        $headers = @($rows[0].PSObject.Properties | ForEach-Object { $_.Name })
    }

    $sumCols = @(
        @{ Metric = 'sum_out_ins_amt'; Column = 'out_ins_amt' },
        @{ Metric = 'sum_billed_amount'; Column = 'billed_amount' }
    )
    foreach ($spec in $sumCols) {
        $col = Get-ExcelMenuCsvHeaderMatch -Headers $headers -Name $spec.Column
        if ([string]::IsNullOrWhiteSpace($col)) {
            continue
        }
        $sum = 0.0
        $any = $false
        foreach ($r in $rows) {
            $v = ConvertTo-ExcelMenuOptionalDouble -Text ([string]$r.PSObject.Properties[$col].Value)
            if ($null -ne $v) {
                $sum += $v
                $any = $true
            }
        }
        if ($any) {
            $list.Add([pscustomobject]@{ metric = $spec.Metric; value = $sum.ToString($inv) })
        }
    }

    $maxCol = Get-ExcelMenuCsvHeaderMatch -Headers $headers -Name 'v1_priority_score'
    if (-not [string]::IsNullOrWhiteSpace($maxCol)) {
        $mx = $null
        foreach ($r in $rows) {
            $v = ConvertTo-ExcelMenuOptionalDouble -Text ([string]$r.PSObject.Properties[$maxCol].Value)
            if ($null -ne $v) {
                if ($null -eq $mx -or $v -gt $mx) { $mx = $v }
            }
        }
        if ($null -ne $mx) {
            $list.Add([pscustomobject]@{ metric = 'max_v1_priority_score'; value = $mx.ToString($inv) })
        }
    }

    $minCol = Get-ExcelMenuCsvHeaderMatch -Headers $headers -Name 'days_until_appeal_deadline'
    if (-not [string]::IsNullOrWhiteSpace($minCol)) {
        $mn = $null
        foreach ($r in $rows) {
            $v = ConvertTo-ExcelMenuOptionalDouble -Text ([string]$r.PSObject.Properties[$minCol].Value)
            if ($null -ne $v) {
                if ($null -eq $mn -or $v -lt $mn) { $mn = $v }
            }
        }
        if ($null -ne $mn) {
            $list.Add([pscustomobject]@{ metric = 'min_days_until_appeal_deadline'; value = $mn.ToString($inv) })
        }
    }

    return @($list.ToArray())
}

function Show-ExcelMenuFileTotals {
    param(
        [object[]]$Totals
    )

    if ($null -eq $Totals -or @($Totals).Count -eq 0) {
        return
    }
    Write-Host '  File totals (existing columns; not a new score):' -ForegroundColor DarkGray
    foreach ($t in @($Totals)) {
        Write-Host ("    {0}={1}" -f $t.metric, $t.value) -ForegroundColor DarkGray
    }
}

function Write-ExcelMenuFileTotalsCsv {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Totals,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $dir = [System.IO.Path]::GetDirectoryName($Path)
    if (-not [string]::IsNullOrWhiteSpace($dir) -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    @($Totals) | Export-Csv -LiteralPath $Path -NoTypeInformation -Encoding UTF8
}

function Get-ImportProcessableFiles {
    <#
    .SYNOPSIS
        Discover processable files under import\ (CSV and Excel).
    .PARAMETER FilterKind
        All (default), Csv only, or Excel only.
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('All', 'Csv', 'Excel')]
        [string]$FilterKind = 'All'
    )

    $items = New-Object System.Collections.Generic.List[object]
    if (-not (Test-Path -LiteralPath $importDir)) {
        return @()
    }

    $files = @()
    if ($FilterKind -eq 'All' -or $FilterKind -eq 'Csv') {
        $files += @(Get-ChildItem -LiteralPath $importDir -Filter '*.csv' -File -ErrorAction SilentlyContinue)
    }
    if ($FilterKind -eq 'All' -or $FilterKind -eq 'Excel') {
        $files += @(Get-ChildItem -LiteralPath $importDir -Filter '*.xlsx' -File -ErrorAction SilentlyContinue)
        # Windows Win32 -Filter '*.xls' also matches '*.xlsx' (legacy short-pattern quirk).
        # Keep true .xls only so each workbook appears once in the menu list.
        $files += @(
            Get-ChildItem -LiteralPath $importDir -Filter '*.xls' -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -ieq '.xls' }
        )
    }

    foreach ($f in @($files | Sort-Object Name)) {
        $ext = $f.Extension.ToLowerInvariant()
        $kind = if ($ext -eq '.csv') { 'CSV' } else { 'Excel' }
        $items.Add([pscustomobject]@{
            FullName      = $f.FullName
            Name          = $f.Name
            Kind          = $kind
            Length        = $f.Length
            LastWriteTime = $f.LastWriteTime
            Extension     = $ext
        })
    }

    return @($items.ToArray())
}

function Format-FileSizeLabel {
    param([long]$Bytes)
    if ($Bytes -ge 1MB) {
        return ('{0:N1} MB' -f ($Bytes / 1MB))
    }
    if ($Bytes -ge 1KB) {
        return ('{0:N0} KB' -f ($Bytes / 1KB))
    }
    return ('{0:N0} B' -f $Bytes)
}

function Parse-SelectionRange {
    <#
    .SYNOPSIS
        Parse print-style multi-select (1, 1,2, 1-3, 1,3-5,8) or a full path.
    .PARAMETER Raw
        User selection string.
    .PARAMETER Candidates
        Ordered list of objects with FullName (1-based indices).
    .OUTPUTS
        String array of unique full paths in selection order.
    #>
    [CmdletBinding()]
    param(
        [string]$Raw,
        [object[]]$Candidates
    )

    $selected = New-Object System.Collections.Generic.List[string]
    if ([string]::IsNullOrWhiteSpace($Raw)) {
        return @()
    }

    $raw = $Raw.Trim().Trim('"')
    $count = @($Candidates).Count

    # Path fallback: separators, drive letter, or known data extension
    $looksLikePath = (
        $raw -match '[\\/]' -or
        $raw -match '^[A-Za-z]:' -or
        $raw -match '\.(csv|xlsx|xls)$'
    )
    # Pure index tokens use digits, commas, spaces, semicolons, and hyphens for ranges
    $onlySelectionTokens = ($raw -match '^[\d,\s;\-]+$')

    if ($looksLikePath -and -not $onlySelectionTokens) {
        try {
            $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($raw)
        }
        catch {
            throw ("Invalid path: {0}" -f $_.Exception.Message)
        }
        if (-not (Test-Path -LiteralPath $resolved)) {
            throw ("File not found: {0}" -f $resolved)
        }
        $selected.Add($resolved)
        return @($selected.ToArray())
    }

    if ($count -lt 1) {
        throw 'No files available to select by number. Enter a full path instead.'
    }

    if (-not $onlySelectionTokens) {
        throw ("Not a valid selection (use numbers, ranges like 1-3, lists like 1,3-5, or a full path): {0}" -f $raw)
    }

    $parts = @($raw -split '[,;\s]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    foreach ($p in $parts) {
        if ($p -match '^(\d+)-(\d+)$') {
            $start = [int]$Matches[1]
            $end = [int]$Matches[2]
            if ($start -gt $end) {
                throw ("Inverted range not allowed: {0} (use ascending, e.g. {1}-{2})" -f $p, $end, $start)
            }
            if ($start -lt 1 -or $end -gt $count) {
                throw ("Selection out of range: {0} (valid 1-{1})" -f $p, $count)
            }
            for ($n = $start; $n -le $end; $n++) {
                $full = [string]$Candidates[$n - 1].FullName
                if (-not ($selected -contains $full)) {
                    $selected.Add($full)
                }
            }
            continue
        }

        $n = 0
        if (-not [int]::TryParse($p, [ref]$n)) {
            throw ("Not a valid selection number: {0}" -f $p)
        }
        if ($n -lt 1 -or $n -gt $count) {
            throw ("Selection out of range: {0} (valid 1-{1})" -f $n, $count)
        }
        $full = [string]$Candidates[$n - 1].FullName
        if (-not ($selected -contains $full)) {
            $selected.Add($full)
        }
    }

    return @($selected.ToArray())
}

function Select-ImportInputs {
    <#
    .SYNOPSIS
        List import\ files and accept print-style multi-select or a typed path.
    .PARAMETER FilterKind
        All (CSV + Excel), Csv only, or Excel only.
    .PARAMETER Title
        Optional list heading.
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('All', 'Csv', 'Excel')]
        [string]$FilterKind = 'All',

        [string]$Title = ''
    )

    $candidates = @(Get-ImportProcessableFiles -FilterKind $FilterKind)

    if ($candidates.Count -gt 0) {
        if ([string]::IsNullOrWhiteSpace($Title)) {
            switch ($FilterKind) {
                'Csv'   { $Title = 'CSV files under import\:' }
                'Excel' { $Title = 'Excel files under import\:' }
                default { $Title = 'Files under import\:' }
            }
        }
        Write-Host $Title -ForegroundColor Cyan
        for ($i = 0; $i -lt $candidates.Count; $i++) {
            $item = $candidates[$i]
            $sizeLabel = Format-FileSizeLabel -Bytes ([long]$item.Length)
            $dateLabel = $item.LastWriteTime.ToString('yyyy-MM-dd')
            Write-Host ("  {0,2}) {1,-36} ({2}, {3}, {4})" -f ($i + 1), $item.Name, $item.Kind, $sizeLabel, $dateLabel)
        }
        Write-Host ''
        Write-Host 'Enter number(s)/ranges e.g. 1 or 1-3 or 1,3-5 - or a full path:' -ForegroundColor DarkGray
        $raw = Read-Host 'Selection'
    }
    else {
        $kindNote = switch ($FilterKind) {
            'Csv'   { '.csv' }
            'Excel' { '.xlsx/.xls' }
            default { '.csv/.xlsx/.xls' }
        }
        Write-Host ("No {0} files found under {1}" -f $kindNote, $importDir) -ForegroundColor Yellow
        $openFolder = Read-Host 'Open import\ folder? [y/N]'
        if ($openFolder -match '^[Yy]') {
            if (-not (Test-Path -LiteralPath $importDir)) {
                New-Item -ItemType Directory -Path $importDir -Force | Out-Null
            }
            Start-Process -FilePath 'explorer.exe' -ArgumentList $importDir | Out-Null
        }
        $raw = Read-Host 'Enter full path to a file'
    }

    return @(Parse-SelectionRange -Raw $raw -Candidates $candidates)
}

function Select-CsvInputsForPipeline {
    <#
    .SYNOPSIS
        List import\ CSVs and accept multi-select indices, ranges, or a typed path.
    #>
    return @(Select-ImportInputs -FilterKind Csv -Title 'CSV files under import\:')
}

function Read-OptionalExportPassword {
    <#
    .SYNOPSIS
        Ask whether to protect Excel output with a workbook open password.
    .OUTPUTS
        SecureString when the user opts in with a non-empty password; otherwise $null.
    #>
    [CmdletBinding()]
    param()

    Write-Host ''
    Write-Host 'Protect the Excel workbook with a password?' -ForegroundColor Cyan
    Write-Host '  [Y] Yes - set open password' -ForegroundColor DarkGray
    Write-Host '  [N] No  - leave unprotected (default)' -ForegroundColor DarkGray
    $ans = Read-Host 'Choice [N]'
    if ($ans -notmatch '^[Yy]') {
        return $null
    }

    $secure = Read-Host -Prompt 'Workbook open password' -AsSecureString
    if ($null -eq $secure -or $secure.Length -eq 0) {
        Write-Host 'Empty password - leaving workbook unprotected.' -ForegroundColor Yellow
        return $null
    }
    return $secure
}

function Test-IsExcelPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $ext = [System.IO.Path]::GetExtension($Path)
    if ([string]::IsNullOrWhiteSpace($ext)) { return $false }
    $ext = $ext.ToLowerInvariant()
    return ($ext -eq '.xlsx' -or $ext -eq '.xls')
}

function Test-IsCsvPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $ext = [System.IO.Path]::GetExtension($Path)
    if ([string]::IsNullOrWhiteSpace($ext)) { return $false }
    return ($ext.ToLowerInvariant() -eq '.csv')
}

function Invoke-ImportExcelFile {
    <#
    .SYNOPSIS
        Import one workbook to CSV under import\ (unique path; password prompt if needed).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExcelPath
    )

    if (-not (Test-Path -LiteralPath $toolkitModulePath)) {
        throw ("ExcelToolkit.psm1 not found: {0}" -f $toolkitModulePath)
    }
    if (-not (Ensure-ExcelMenuDiagnosticsPass)) {
        return $null
    }
    if (-not (Test-Path -LiteralPath $importDir)) {
        New-Item -ItemType Directory -Path $importDir -Force | Out-Null
    }

    Import-Module -Name $toolkitModulePath -Force -ErrorAction Stop

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($ExcelPath)
    $defaultOut = Join-Path $importDir ("{0}.csv" -f $baseName)

    Write-Host ("Importing: {0}" -f $ExcelPath) -ForegroundColor Cyan
    Write-Host ("  Planned CSV: {0}" -f $defaultOut) -ForegroundColor DarkGray
    Write-Host 'If that CSV already exists, a free path with a numerical suffix is used (no overwrite).' -ForegroundColor DarkGray

    $importParams = @{
        ExcelPath           = $ExcelPath
        OutputPath          = $defaultOut
        AllowPasswordPrompt = $true
    }

    $r = Import-CsvFromExcel @importParams
    if ($r.Success) {
        Write-Host ("  OK: {0}" -f $r.OutputPath) -ForegroundColor Green
        if ($r.PasswordUsed) {
            Write-Host '  Password: used (value not shown)' -ForegroundColor DarkGray
        }
        return [string]$r.OutputPath
    }

    Write-Host ("  FAIL import: {0}" -f $r.Message) -ForegroundColor Red
    return $null
}

function Invoke-MenuExportCsv {
    <#
    .SYNOPSIS
        Export one or more CSVs to Excel in-process (optional workbook password).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$CsvPaths,

        [switch]$UseDisplayNames,

        [SecureString]$Password
    )

    if (-not (Test-Path -LiteralPath $toolkitModulePath)) {
        throw ("ExcelToolkit.psm1 not found: {0}" -f $toolkitModulePath)
    }
    if (-not (Ensure-ExcelMenuDiagnosticsPass)) {
        return
    }
    if (-not (Test-Path -LiteralPath $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    Import-Module -Name $toolkitModulePath -Force -ErrorAction Stop

    $schemaPath = Get-EffectiveSchemaPath
    $schemaFormat = Get-EffectiveSchemaFormat -Path $schemaPath

    $okCount = 0
    $failCount = 0
    foreach ($csvPath in @($CsvPaths)) {
        Write-Host ('-' * 50) -ForegroundColor DarkGray
        Write-Host ("Export: {0}" -f $csvPath) -ForegroundColor Cyan
        if (-not (Test-Path -LiteralPath $csvPath)) {
            Write-Host ("  FAIL: CSV not found: {0}" -f $csvPath) -ForegroundColor Red
            $failCount++
            continue
        }

        $wqLabel = Get-ExcelMenuWqLabelForFile -CsvPath $csvPath
        $plannedXlsx = Get-ExcelMenuDeliverableXlsxPath -OutputDir $outputDir -WqLabel $wqLabel -Kind data

        $exportParams = @{
            CsvPath    = $csvPath
            OutputPath = $plannedXlsx
        }
        if (-not [string]::IsNullOrWhiteSpace($schemaPath)) {
            $exportParams['SchemaPath'] = $schemaPath
        }
        if ($schemaFormat -eq 'Json' -or $schemaFormat -eq 'Csv') {
            $exportParams['SchemaFormat'] = $schemaFormat
        }
        if ($UseDisplayNames) {
            $exportParams['UseDisplayNames'] = $true
        }
        if ($null -ne $Password -and $Password.Length -gt 0) {
            $exportParams['Password'] = $Password
        }

        try {
            $r = Export-ExcelFromCsv @exportParams
            if ($r.Success) {
                Write-Host ("  OK: {0}" -f $r.OutputPath) -ForegroundColor Green
                $okCount++
            }
            else {
                Write-Host ("  FAIL: {0}" -f $r.Message) -ForegroundColor Red
                $failCount++
            }
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

function Invoke-KpiScoreExportMenu {
    <#
    .SYNOPSIS
        Score selected CSVs via kpi-analytics; optionally export scored + summary to Excel.
    .PARAMETER ScoreOnly
        When set, write scored and summary CSVs only (no Excel COM export).
    .PARAMETER InputPaths
        Optional preselected CSV paths (skips interactive file pick).
    .PARAMETER Password
        Optional workbook open password for Excel exports (SecureString).
    .PARAMETER SkipPasswordPrompt
        When set with Excel export, do not prompt; use -Password as-is (may be $null).
    .PARAMETER Profile
        Optional scoring profile name or path for score --profile. When omitted on an
        interactive host, prompts once per batch (package default = no --profile).
    .PARAMETER SkipProfilePrompt
        When set, do not prompt for a scoring profile (use -Profile as-is, may be empty).
    .PARAMETER Worklist
        Score with --group-preset and export Data + Groups + Worklist sheets.
    .PARAMETER Express
        Score --output-mode slim; export one POI_Scores sheet (identity + score-input + context source + four scores).
        Skips profile, password, and Full/Slim picks. No summary xlsx.
    #>
    [CmdletBinding()]
    param(
        [switch]$ScoreOnly,

        [string[]]$InputPaths,

        [SecureString]$Password,

        [switch]$SkipPasswordPrompt,

        [string]$Profile,

        [switch]$SkipProfilePrompt,

        [switch]$Worklist,

        [switch]$Express
    )

    $modeFlags = @($ScoreOnly, $Worklist, $Express) | Where-Object { $_ }
    if (@($modeFlags).Count -gt 1) {
        throw '-ScoreOnly, -Worklist, and -Express are mutually exclusive'
    }

    Write-Host ''
    if ($ScoreOnly) {
        Write-Host 'Score only (KPI CSV)' -ForegroundColor Cyan
        Write-Host 'Runs kpi-analytics score; writes scored + summary CSVs under output\.' -ForegroundColor DarkGray
        Write-Host 'No Excel export on this path.' -ForegroundColor DarkGray
    }
    elseif ($Worklist) {
        Write-Host 'Build worklist (Score -> Groups + Worklist Excel)' -ForegroundColor Cyan
        Write-Host 'kpi-analytics scores and writes *_groups.csv; Excel COM adds Groups + Worklist + Totals sheets.' -ForegroundColor DarkGray
        Write-Host 'Excel is the human deliverable ([WQ]_MM-DD-YYYY.xlsx). No scoring math in PowerShell.' -ForegroundColor DarkGray
    }
    elseif ($Express) {
        Write-Host 'Express score (all POI -> one POI_Scores sheet)' -ForegroundColor Cyan
        Write-Host 'kpi-analytics scores --output-mode slim; Excel COM copies identity, score-input and context source columns, and four scores.' -ForegroundColor DarkGray
        Write-Host 'No profile pick, password, or Full/Slim pick. Summary CSV is kept; no summary Excel.' -ForegroundColor DarkGray
        Write-Host 'Excel is the human deliverable ([WQ]_MM-DD-YYYY.xlsx). No scoring math in PowerShell.' -ForegroundColor DarkGray
    }
    else {
        Write-Host 'Run full pipeline (Score CSV -> Excel deliverable)' -ForegroundColor Cyan
        Write-Host 'Runs kpi-analytics score, then exports scored + summary CSVs to Excel.' -ForegroundColor DarkGray
        Write-Host 'Excel is the human deliverable ([WQ]_MM-DD-YYYY.xlsx); CSV artifacts stay under output\.' -ForegroundColor DarkGray
        Write-Host 'Engines stay separate: Python scores; Excel COM formats workbooks.' -ForegroundColor DarkGray
    }
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

    $inputs = @()
    if ($null -ne $InputPaths -and @($InputPaths).Count -gt 0) {
        $inputs = @($InputPaths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }
    else {
        $inputs = @(Select-CsvInputsForPipeline)
    }
    if ($inputs.Count -eq 0) {
        Write-Host 'No CSV selected.' -ForegroundColor Yellow
        return
    }

    Write-Host ''
    if ($ScoreOnly) {
        Write-Host ("Selected {0} file(s). First score may run Python diagnostics (one-time gate)." -f $inputs.Count) -ForegroundColor DarkGray
    }
    else {
        Write-Host ("Selected {0} file(s). First KPI score may run Python diagnostics; first Excel export may run Excel diagnostics (one-time gates)." -f $inputs.Count) -ForegroundColor DarkGray
    }
    Write-Host ''

    $resolvedOutputMode = 'full'
    if ($Express) {
        $resolvedOutputMode = 'slim'
        Write-Host 'Express: slim scores (all shipped POI) -> one POI_Scores sheet.' -ForegroundColor Cyan
    }
    else {
        $resolvedOutputMode = Select-KpiOutputMode
        if ($resolvedOutputMode -eq 'slim') {
            Write-Host 'Slim output: WQ columns + one score per shipped POI (no --profile).' -ForegroundColor Cyan
        }
    }

    # One scoring profile for the whole batch (composition only; no merge in PowerShell).
    $resolvedProfile = $null
    if ($resolvedOutputMode -eq 'slim') {
        $resolvedProfile = $null
    }
    elseif ($PSBoundParameters.ContainsKey('Profile') -and -not [string]::IsNullOrWhiteSpace($Profile)) {
        $resolvedProfile = $Profile.Trim()
        Write-Host ("Scoring profile (provided): {0}" -f $resolvedProfile) -ForegroundColor Cyan
    }
    elseif ($SkipProfilePrompt) {
        $resolvedProfile = $null
    }
    else {
        $resolvedProfile = Select-KpiScoringProfile
    }

    $resolvedGroupPreset = $null
    if ($Worklist) {
        $resolvedGroupPreset = Select-KpiGroupPreset
        if ([string]::IsNullOrWhiteSpace($resolvedGroupPreset)) {
            Write-Host 'Worklist cancelled (no group preset).' -ForegroundColor Yellow
            return
        }
        Write-Host ("Group preset: {0}" -f $resolvedGroupPreset) -ForegroundColor Cyan
    }

    $batchProfileWqLabel = $null
    if (-not [string]::IsNullOrWhiteSpace($resolvedProfile)) {
        $batchProfileWqLabel = Get-KpiProfileWqLabel -ProfileToken $resolvedProfile
        if (-not [string]::IsNullOrWhiteSpace($batchProfileWqLabel)) {
            Write-Host ("WQ label (profile wq_label): {0}" -f $batchProfileWqLabel) -ForegroundColor Cyan
        }
    }

    # Excel COM gate only when this action will export workbooks
    if (-not $ScoreOnly) {
        if (-not (Ensure-ExcelMenuDiagnosticsPass)) {
            return
        }
    }

    $exportPassword = $null
    if (-not $ScoreOnly -and -not $Express) {
        if ($SkipPasswordPrompt) {
            $exportPassword = $Password
        }
        else {
            $exportPassword = Read-OptionalExportPassword
        }
    }

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
            $plannedGroupsCsv   = Join-Path $outputDir ('{0}_scored_groups.csv' -f $stem)

            $scoredCsvInfo  = Resolve-ExcelToolkitUniquePath -Path $plannedScoredCsv
            $summaryCsvInfo = Resolve-ExcelToolkitUniquePath -Path $plannedSummaryCsv
            $groupsCsvInfo  = $null
            if ($Worklist) {
                $groupsCsvInfo = Resolve-ExcelToolkitUniquePath -Path $plannedGroupsCsv
            }

            $groupsAdjusted = ($Worklist -and $null -ne $groupsCsvInfo -and $groupsCsvInfo.PathAdjusted)
            if ($scoredCsvInfo.PathAdjusted -or $summaryCsvInfo.PathAdjusted -or $groupsAdjusted) {
                Write-Host '  Unique CSV paths (avoided overwrite):' -ForegroundColor Yellow
                Write-Host ("    Scored  : {0}" -f $scoredCsvInfo.Path)
                Write-Host ("    Summary : {0}" -f $summaryCsvInfo.Path)
                if ($Worklist -and $null -ne $groupsCsvInfo) {
                    Write-Host ("    Groups  : {0}" -f $groupsCsvInfo.Path)
                }
            }
            else {
                Write-Host ("  Scored CSV  : {0}" -f $scoredCsvInfo.Path)
                Write-Host ("  Summary CSV : {0}" -f $summaryCsvInfo.Path)
            }

            Write-Host '  Scoring (kpi-analytics)...' -ForegroundColor Cyan
            $scoreMapParams = @{
                CsvPath     = $csvPath
                OutputPath  = $scoredCsvInfo.Path
                SummaryPath = $summaryCsvInfo.Path
            }
            if (-not [string]::IsNullOrWhiteSpace($resolvedProfile)) {
                $scoreMapParams['Profile'] = $resolvedProfile
            }
            if ($Worklist) {
                $scoreMapParams['GroupPreset'] = $resolvedGroupPreset
                $scoreMapParams['GroupsPath'] = $groupsCsvInfo.Path
                Write-Host ("  Groups CSV  : {0}" -f $groupsCsvInfo.Path) -ForegroundColor DarkGray
            }
            if ($resolvedOutputMode -eq 'slim') {
                $scoreMapParams['OutputMode'] = 'slim'
            }
            $scoreResult = Select-KpiScoreInvokeResult -Raw (
                Invoke-KpiAnalyticsScoreWithMapping @scoreMapParams
            )

            if ($null -eq $scoreResult -or $null -eq $scoreResult.PSObject.Properties['ExitCode']) {
                Write-Host '  FAIL score: unexpected result from kpi-analytics invoke (no ExitCode).' -ForegroundColor Red
                $failCount++
                continue
            }

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
            $profileNote = ''
            if ($null -ne $scoreJson) {
                $sjNames = @($scoreJson.PSObject.Properties.Name)
                if ($sjNames -contains 'ProfileName' -and -not [string]::IsNullOrWhiteSpace([string]$scoreJson.ProfileName)) {
                    $profileNote = (" profile={0}" -f $scoreJson.ProfileName)
                }
                elseif (-not [string]::IsNullOrWhiteSpace($resolvedProfile)) {
                    $profileNote = (" profile={0}" -f $resolvedProfile)
                }
            }
            elseif (-not [string]::IsNullOrWhiteSpace($resolvedProfile)) {
                $profileNote = (" profile={0}" -f $resolvedProfile)
            }
            $groupNote = ''
            if ($Worklist -and $null -ne $scoreJson) {
                $sjNames = @($scoreJson.PSObject.Properties.Name)
                if ($sjNames -contains 'GroupCount') {
                    $groupNote = (" groups={0}" -f $scoreJson.GroupCount)
                }
            }
            Write-Host ("  Score OK.{0}{1}{2}" -f $rowNote, $profileNote, $groupNote) -ForegroundColor Green

            # H2: surface partial ranks; require confirm before keeping / Excel export.
            $rankIsFull = Test-KpiScoreRankIsFull -ScoreJson $scoreJson
            if (-not $rankIsFull) {
                Show-KpiPartialRankBanner -ScoreJson $scoreJson
                if (-not (Confirm-KpiKeepPartialRankOutputs)) {
                    Write-Host '  Partial rank declined; removing scored CSVs for this file.' -ForegroundColor Yellow
                    $removeParams = @{
                        ScoredCsv  = $actualScoredCsv
                        SummaryCsv = $actualSummaryCsv
                    }
                    if ($Worklist) {
                        $declineGroups = $groupsCsvInfo.Path
                        if ($null -ne $scoreJson -and $scoreJson.GroupsPath) {
                            $declineGroups = [string]$scoreJson.GroupsPath
                        }
                        $removeParams['GroupsCsv'] = $declineGroups
                    }
                    Remove-KpiScoredOutputPair @removeParams
                    $failCount++
                    continue
                }
                Write-Host '  Continuing with PARTIAL rank outputs.' -ForegroundColor Yellow
            }

            $fileWqLabel = Get-ExcelMenuWqLabelForFile -CsvPath $csvPath -BatchProfileLabel $batchProfileWqLabel
            $fileTotals = @()
            try {
                $fileTotals = @(Get-ExcelMenuFileTotals -ScoredCsv $actualScoredCsv -WqLabel $fileWqLabel -SourceFile $csvPath)
                Show-ExcelMenuFileTotals -Totals $fileTotals
            }
            catch {
                Write-Host ("  File totals skipped: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
                $fileTotals = @()
            }

            if ($ScoreOnly) {
                Write-Host ("  Scored CSV  : {0}" -f $actualScoredCsv) -ForegroundColor Green
                Write-Host ("  Summary CSV : {0}" -f $actualSummaryCsv) -ForegroundColor Green
                Write-Host '  Score-only complete for this file.' -ForegroundColor Green
                $okCount++
                continue
            }

            $plannedScoredXlsx  = Get-ExcelMenuDeliverableXlsxPath -OutputDir $outputDir -WqLabel $fileWqLabel -Kind data
            $plannedSummaryXlsx = Get-ExcelMenuDeliverableXlsxPath -OutputDir $outputDir -WqLabel $fileWqLabel -Kind summary

            if (-not $rankIsFull) {
                Write-Host '  Exporting PARTIAL-rank workbooks...' -ForegroundColor Yellow
            }
            if ($Express) {
                Write-Host '  Exporting POI_Scores workbook...' -ForegroundColor Cyan
            }
            else {
                Write-Host '  Exporting scored workbook...' -ForegroundColor Cyan
            }
            $ex1Params = @{
                CsvPath    = $actualScoredCsv
                OutputPath = $plannedScoredXlsx
            }
            if ($Express) {
                $ex1Params['PoiScoreSheetOnly'] = $true
            }
            elseif (@($fileTotals).Count -gt 0) {
                $plannedTotalsCsv = Join-Path $outputDir ('{0}_scored_totals.csv' -f $stem)
                $totalsCsvInfo = Resolve-ExcelToolkitUniquePath -Path $plannedTotalsCsv
                try {
                    Write-ExcelMenuFileTotalsCsv -Totals $fileTotals -Path $totalsCsvInfo.Path
                    $ex1Params['TotalsCsv'] = $totalsCsvInfo.Path
                    Write-Host ("  Totals CSV  : {0}" -f $totalsCsvInfo.Path) -ForegroundColor DarkGray
                }
                catch {
                    Write-Host ("  Totals sheet skipped: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
                }
            }
            if ($Worklist) {
                $actualGroupsCsv = $groupsCsvInfo.Path
                if ($null -ne $scoreJson -and $scoreJson.GroupsPath) {
                    $actualGroupsCsv = [string]$scoreJson.GroupsPath
                }
                if (-not (Test-Path -LiteralPath $actualGroupsCsv)) {
                    Write-Host ("  FAIL groups CSV missing: {0}" -f $actualGroupsCsv) -ForegroundColor Red
                    $failCount++
                    continue
                }
                $ex1Params['GroupsCsv'] = $actualGroupsCsv
                $ex1Params['Worklist'] = $true
                Write-Host ("  Groups CSV  : {0}" -f $actualGroupsCsv) -ForegroundColor DarkGray
            }
            if ($null -ne $exportPassword -and $exportPassword.Length -gt 0) {
                $ex1Params['Password'] = $exportPassword
            }
            $ex1 = Export-ExcelFromCsv @ex1Params
            if (-not $ex1.Success) {
                Write-Host ("  FAIL scored Excel: {0}" -f $ex1.Message) -ForegroundColor Red
                Write-Host ("  Scored CSV still at: {0}" -f $actualScoredCsv) -ForegroundColor Yellow
                $failCount++
                continue
            }
            Write-Host ("  Scored XLSX : {0}" -f $ex1.OutputPath) -ForegroundColor Green
            $exNames = @($ex1.PSObject.Properties.Name)
            if ($Express -and $exNames -contains 'PoiScoreRowCount') {
                Write-Host ("  POI_Scores rows: {0}" -f $ex1.PoiScoreRowCount) -ForegroundColor DarkGray
            }
            if ($exNames -contains 'TotalsRowCount' -and $ex1.TotalsRowCount -gt 0) {
                Write-Host ("  Totals rows : {0}" -f $ex1.TotalsRowCount) -ForegroundColor DarkGray
            }
            if ($Worklist) {
                if ($exNames -contains 'WorklistRowCount') {
                    Write-Host ("  Worklist rows: {0}" -f $ex1.WorklistRowCount) -ForegroundColor DarkGray
                }
            }

            if (-not $Express) {
                Write-Host '  Exporting summary workbook...' -ForegroundColor Cyan
                if (-not (Test-Path -LiteralPath $actualSummaryCsv)) {
                    Write-Host ("  FAIL summary CSV missing: {0}" -f $actualSummaryCsv) -ForegroundColor Red
                    $failCount++
                    continue
                }
                $ex2Params = @{
                    CsvPath    = $actualSummaryCsv
                    OutputPath = $plannedSummaryXlsx
                }
                if ($null -ne $exportPassword -and $exportPassword.Length -gt 0) {
                    $ex2Params['Password'] = $exportPassword
                }
                $ex2 = Export-ExcelFromCsv @ex2Params
                if (-not $ex2.Success) {
                    Write-Host ("  FAIL summary Excel: {0}" -f $ex2.Message) -ForegroundColor Red
                    Write-Host ("  Summary CSV still at: {0}" -f $actualSummaryCsv) -ForegroundColor Yellow
                    $failCount++
                    continue
                }
                Write-Host ("  Summary XLSX: {0}" -f $ex2.OutputPath) -ForegroundColor Green
            }
            else {
                Write-Host ("  Summary CSV : {0}" -f $actualSummaryCsv) -ForegroundColor DarkGray
            }

            if ($Worklist) {
                Write-Host '  Worklist complete for this file.' -ForegroundColor Green
            }
            elseif ($Express) {
                Write-Host '  Express complete for this file.' -ForegroundColor Green
            }
            else {
                Write-Host '  Pipeline complete for this file.' -ForegroundColor Green
            }
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
        Write-Host '  1) Check readiness (dry-run + pass certificate)'
        Write-Host '  2) Run full self-test'
        Write-Host '  0) Back'
        Write-Host '================================================' -ForegroundColor Cyan
        Write-Host ''
        $sub = Read-Host 'Select a diagnostics option'
        switch -Regex ($sub) {
            '^[1]$' {
                # Stamp enterprise pass certificate (same suite as first-run gate)
                if (Test-Path -LiteralPath $toolkitModulePath) {
                    try {
                        Import-Module -Name $toolkitModulePath -Force -ErrorAction Stop
                        Write-Host 'Excel Toolkit diagnostics (readiness)...' -ForegroundColor Cyan
                        $diag = Invoke-ExcelToolkitDiagnostics -Write $true
                        foreach ($c in @($diag.Checks)) {
                            $tag = if ($c.Passed) { 'PASS' } else { 'FAIL' }
                            $color = if ($c.Passed) { 'Green' } else { 'Red' }
                            Write-Host ("  [{0}] {1}: {2}" -f $tag, $c.Name, $c.Detail) -ForegroundColor $color
                        }
                        if ($diag.OverallPass) {
                            Write-Host 'OK — pass certificate written.' -ForegroundColor Green
                            if ($diag.ReportTextPath) {
                                Write-Host ("  Report: {0}" -f $diag.ReportTextPath) -ForegroundColor DarkGray
                            }
                        }
                        else {
                            Write-Host 'FAIL — certificate records failure; fix issues before export.' -ForegroundColor Red
                            if ($diag.ReportTextPath) {
                                Write-Host ("  Report: {0}" -f $diag.ReportTextPath) -ForegroundColor Yellow
                            }
                        }
                    }
                    catch {
                        Write-Host ("Diagnostics error: {0}" -f $_.Exception.Message) -ForegroundColor Red
                    }
                }
                else {
                    $null = Invoke-ToolScript -Path $testScript -Arguments @{ DryRun = $true }
                }
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
        Write-Host '  B) Back'
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
    Write-Host '  Work Queue Data Tools' -ForegroundColor Cyan
    Write-Host '================================================' -ForegroundColor Cyan
    Write-Host '  1) Process my data'
    Write-Host '  2) Advanced tools...'
    Write-Host '  0) Exit'
    Write-Host '================================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'Happy path: place CSV/Excel under import\, choose 1, pick files (1-3 or 1,3-5).' -ForegroundColor DarkGray
    Write-Host ("Schema (Advanced): {0}" -f $schemaNote) -ForegroundColor DarkGray
    Write-Host 'Existing outputs are not overwritten (unique name_N.ext when needed).' -ForegroundColor DarkGray
}

function Invoke-AdvancedMenu {
    <#
    .SYNOPSIS
        Secondary tools: schema-header export, import, folders, schema, diagnostics, env.
    #>
    $inAdvanced = $true
    while ($inAdvanced) {
        Clear-Host
        $schemaPath = Get-EffectiveSchemaPath
        $schemaFmt  = Get-EffectiveSchemaFormat -Path $schemaPath
        $schemaNote = '{0} | {1}' -f $schemaFmt, (Split-Path -Leaf $schemaPath)

        Write-Host '================================================' -ForegroundColor Cyan
        Write-Host '  Advanced tools' -ForegroundColor Cyan
        Write-Host '================================================' -ForegroundColor Cyan
        Write-Host '  1) Export CSV to Excel (schema display headers)'
        Write-Host '  2) Import Excel to CSV (password prompt if needed)'
        Write-Host '  3) Open output folder'
        Write-Host '  4) Show environment / policy info'
        Write-Host '  5) Schema: show source, preview, change JSON/CSV'
        Write-Host '  6) Diagnostics (readiness / self-test)'
        Write-Host '  7) Scoring profiles (list / CLI help)'
        Write-Host '  0) Back to main menu'
        Write-Host '================================================' -ForegroundColor Cyan
        Write-Host ''
        Write-Host ("Current schema: {0}" -f $schemaNote) -ForegroundColor DarkGray
        Write-Host 'Headers come from your data CSV; schema is for display labels only.' -ForegroundColor DarkGray
        Write-Host 'Import CSV defaults to the import\ folder.' -ForegroundColor DarkGray
        Write-Host ''

        $sub = Read-Host 'Select an advanced option'
        switch ($sub) {
            '1' {
                try {
                    $csvList = @(Select-CsvInputsForPipeline)
                    if ($csvList.Count -eq 0) {
                        Write-Host 'No CSV selected.' -ForegroundColor Yellow
                    }
                    else {
                        $pw = Read-OptionalExportPassword
                        if ($null -ne $pw) {
                            Invoke-MenuExportCsv -CsvPaths $csvList -UseDisplayNames -Password $pw
                        }
                        else {
                            Invoke-MenuExportCsv -CsvPaths $csvList -UseDisplayNames
                        }
                    }
                }
                catch {
                    Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
                }
                Wait-ForEnter
            }
            '2' {
                try {
                    Invoke-ImportExcelMenu
                }
                catch {
                    Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
                }
                Wait-ForEnter
            }
            '3' {
                try {
                    Open-OutputFolder
                }
                catch {
                    Write-Host ("Could not open folder: {0}" -f $_.Exception.Message) -ForegroundColor Red
                }
                Wait-ForEnter
            }
            '4' {
                try {
                    Show-EnvironmentInfo
                }
                catch {
                    Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
                }
                Wait-ForEnter
            }
            '5' {
                try {
                    Invoke-SchemaMenu
                }
                catch {
                    Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
                    Wait-ForEnter
                }
            }
            '6' {
                try {
                    Invoke-DiagnosticsMenu
                }
                catch {
                    Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
                    Wait-ForEnter
                }
            }
            '7' {
                try {
                    Show-KpiScoringProfilesHelp
                }
                catch {
                    Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
                }
                Wait-ForEnter
            }
            '0' {
                $inAdvanced = $false
            }
            default {
                Write-Host 'Please enter a number from the advanced menu.' -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
        }
    }
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
                Invoke-ProcessMyData
            }
            catch {
                Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
            }
            Wait-ForEnter
        }
        '2' {
            try {
                Invoke-AdvancedMenu
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
