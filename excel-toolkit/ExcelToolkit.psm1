#requires -Version 5.1
<#
.SYNOPSIS
    High-level Excel Toolkit operations for PowerShell and CLI consumers.

.DESCRIPTION
    Builds on ExcelCom.psm1. Prefer this module from other PowerShell scripts:

        Import-Module .\excel-toolkit\ExcelToolkit.psm1 -Force
        Export-ExcelFromCsv -CsvPath .\data.csv -OutputPath .\out.xlsx

    For Python / Task Scheduler / cmd, use ExcelToolkit.ps1 (CLI) instead.

.NOTES
    Project : workqueue-data-processor / excel-toolkit
    Compat  : Windows PowerShell 5.1
#>

Set-StrictMode -Version Latest

$script:ExcelToolkitVersion = '1.1.0'

$excelComPath = Join-Path $PSScriptRoot 'ExcelCom.psm1'
if (-not (Test-Path -LiteralPath $excelComPath)) {
    throw ("ExcelCom.psm1 not found next to ExcelToolkit.psm1: {0}" -f $excelComPath)
}
Import-Module -Name $excelComPath -Force -ErrorAction Stop

#region Version

function Get-ExcelToolkitVersion {
    <#
    .SYNOPSIS
        Returns the Excel Toolkit version string.
    #>
    [CmdletBinding()]
    param()
    return $script:ExcelToolkitVersion
}

#endregion Version

#region Schema helpers

function Resolve-ExcelToolkitSchemaFormat {
    param(
        [string]$Path,
        [string]$Format
    )
    if ($Format -eq 'Json' -or $Format -eq 'Csv') {
        return $Format
    }
    $ext = [System.IO.Path]::GetExtension($Path)
    if ($ext -match '^\.csv$') { return 'Csv' }
    if ($ext -match '^\.json$') { return 'Json' }
    return 'Json'
}

function Get-ExcelToolkitSchemaDisplayLabel {
    param(
        $FieldObject,
        [string]$PreferredProperty
    )
    if ($null -eq $FieldObject) { return $null }

    $candidates = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($PreferredProperty)) {
        $candidates.Add($PreferredProperty)
    }
    foreach ($name in @('display_name', 'wq_field_name', 'label', 'title')) {
        if ($candidates -notcontains $name) {
            $candidates.Add($name)
        }
    }
    foreach ($propName in $candidates) {
        $prop = $FieldObject.PSObject.Properties[$propName]
        if ($null -ne $prop -and $null -ne $prop.Value -and -not [string]::IsNullOrWhiteSpace([string]$prop.Value)) {
            return [string]$prop.Value
        }
    }
    return $null
}

function Get-ExcelToolkitSchemaFields {
    param(
        [string]$Path,
        [string]$Format = 'Auto'
    )
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        return @()
    }

    $resolved = Resolve-ExcelToolkitSchemaFormat -Path $Path -Format $Format
    $fields = @()

    if ($resolved -eq 'Csv') {
        foreach ($row in @(Import-Csv -LiteralPath $Path)) {
            if ($null -eq $row) { continue }
            $fnProp = $row.PSObject.Properties['field_name']
            if ($null -eq $fnProp -or [string]::IsNullOrWhiteSpace([string]$fnProp.Value)) { continue }
            $fields += $row
        }
        return $fields
    }

    $schema = (Get-Content -LiteralPath $Path -Raw -Encoding UTF8) | ConvertFrom-Json
    if ($null -ne $schema.PSObject.Properties['fields'] -and $null -ne $schema.fields) {
        $fields = @($schema.fields)
    }
    elseif ($schema -is [System.Array]) {
        $fields = @($schema)
    }
    return $fields
}

function New-ExcelToolkitHeaderMap {
    param(
        [string]$Path,
        [string]$PreferredProperty,
        [string]$Format = 'Auto'
    )
    $map = @{}
    foreach ($field in @(Get-ExcelToolkitSchemaFields -Path $Path -Format $Format)) {
        if ($null -eq $field) { continue }
        $fnProp = $field.PSObject.Properties['field_name']
        if ($null -eq $fnProp -or [string]::IsNullOrWhiteSpace([string]$fnProp.Value)) { continue }
        $label = Get-ExcelToolkitSchemaDisplayLabel -FieldObject $field -PreferredProperty $PreferredProperty
        if (-not [string]::IsNullOrWhiteSpace($label)) {
            $map[[string]$fnProp.Value] = $label
        }
    }
    return $map
}

#endregion Schema helpers

#region Export

function Export-ExcelFromCsv {
    <#
    .SYNOPSIS
        Export a data CSV to a formatted Excel workbook.

    .DESCRIPTION
        Column layout comes only from the CSV header row. Optional schema supplies
        display labels. No column names are hard-coded.

        Returns a result object (does not call exit). Safe for Import-Module callers.

    .PARAMETER CsvPath
        Input data CSV (required).

    .PARAMETER SchemaPath
        Optional schema (JSON or CSV) when -UseDisplayNames is set.

    .PARAMETER SchemaFormat
        Auto (default), Json, or Csv.

    .PARAMETER OutputPath
        Destination .xlsx path (required for real export; required for dry-run plan too).

    .PARAMETER UseDisplayNames
        Map field_name headers through the schema display labels.

    .PARAMETER DisplayNameProperty
        Preferred schema label property; otherwise auto-detects common names.

    .PARAMETER SheetName
        Worksheet tab name. Default: Data

    .PARAMETER Visible
        Show Excel UI. Default: hidden.

    .PARAMETER DryRun
        Validate and plan only; do not write a workbook.

    .PARAMETER PassThru
        Return the result object (always returned; switch kept for pipeline clarity).

    .OUTPUTS
        PSCustomObject with Success, OutputPath, RowCount, ColumnCount, DryRun, Message, HeadersSample

    .EXAMPLE
        Export-ExcelFromCsv -CsvPath .\data.csv -OutputPath .\out.xlsx

    .EXAMPLE
        Export-ExcelFromCsv -CsvPath .\data.csv -SchemaPath .\schema.json -UseDisplayNames -OutputPath .\out.xlsx -DryRun
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CsvPath,

        [string]$SchemaPath,

        [ValidateSet('Auto', 'Json', 'Csv')]
        [string]$SchemaFormat = 'Auto',

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [switch]$UseDisplayNames,

        [string]$DisplayNameProperty = '',

        [string]$SheetName = 'Data',

        [switch]$Visible,

        [switch]$DryRun,

        [switch]$PassThru
    )

    $result = [pscustomobject]@{
        Success       = $false
        OutputPath    = $null
        RowCount      = 0
        ColumnCount   = 0
        DryRun        = [bool]$DryRun
        Message       = ''
        HeadersSample = @()
        SchemaFormat  = $null
        SheetName     = $SheetName
    }

    try {
        $CsvPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($CsvPath)
        $OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
        if (-not [string]::IsNullOrWhiteSpace($SchemaPath)) {
            $SchemaPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($SchemaPath)
        }

        if (-not (Test-Path -LiteralPath $CsvPath)) {
            throw ("CSV not found: {0}" -f $CsvPath)
        }

        $resolvedFormat = 'Auto'
        if (-not [string]::IsNullOrWhiteSpace($SchemaPath)) {
            $resolvedFormat = Resolve-ExcelToolkitSchemaFormat -Path $SchemaPath -Format $SchemaFormat
        }
        $result.SchemaFormat = $resolvedFormat

        $schemaForPreflight = $null
        if ($UseDisplayNames) {
            if ([string]::IsNullOrWhiteSpace($SchemaPath) -or -not (Test-Path -LiteralPath $SchemaPath)) {
                throw ("Schema file required for -UseDisplayNames but not found: {0}" -f $SchemaPath)
            }
            $schemaForPreflight = $SchemaPath
        }

        $envResult = Test-ExcelComEnvironment -CsvPath $CsvPath -SchemaPath $schemaForPreflight
        if (-not $envResult.Passed) {
            $failed = @($envResult.Checks | Where-Object { -not $_.Passed } | ForEach-Object { $_.Name })
            throw ("Environment preflight failed: {0}" -f ($failed -join ', '))
        }

        $csvRows = @(Import-Csv -LiteralPath $CsvPath)
        $rowCount = $csvRows.Count
        $propertyNames = @()
        if ($rowCount -gt 0) {
            $propertyNames = @($csvRows[0].PSObject.Properties | ForEach-Object { $_.Name })
        }
        else {
            $headerLine = Get-Content -LiteralPath $CsvPath -TotalCount 1
            if (-not [string]::IsNullOrWhiteSpace($headerLine)) {
                $dummy = $headerLine + [Environment]::NewLine + $headerLine
                $hdrObj = @($dummy | ConvertFrom-Csv) | Select-Object -First 1
                if ($null -ne $hdrObj) {
                    $propertyNames = @($hdrObj.PSObject.Properties | ForEach-Object { $_.Name })
                }
            }
        }

        if ($propertyNames.Count -lt 1) {
            throw ("No columns found in CSV: {0}" -f $CsvPath)
        }

        $headerMap = $null
        $displayHeaders = @($propertyNames)
        if ($UseDisplayNames) {
            $headerMap = New-ExcelToolkitHeaderMap -Path $SchemaPath -PreferredProperty $DisplayNameProperty -Format $resolvedFormat
            $displayHeaders = foreach ($p in $propertyNames) {
                if ($headerMap.ContainsKey($p)) { $headerMap[$p] } else { $p }
            }
        }

        $result.RowCount = $rowCount
        $result.ColumnCount = $propertyNames.Count
        $result.HeadersSample = @($displayHeaders | Select-Object -First 5)
        $result.OutputPath = $OutputPath

        if ($DryRun) {
            $result.Success = $true
            $result.Message = 'DryRun complete - no workbook written.'
            return $result
        }

        $app = $null
        $workbook = $null
        try {
            $app = New-ExcelApplication -Visible:$Visible
            $workbook = New-ExcelWorkbook -Application $app -SheetName $SheetName
            $ws = Get-ExcelWorksheet -Workbook $workbook -Index 1

            if ($csvRows.Count -eq 0) {
                Set-ExcelRange -Worksheet $ws -StartAddress 'A1' -Values @(, @($displayHeaders))
                $importInfo = [pscustomobject]@{
                    RowCount    = 0
                    ColumnCount = $propertyNames.Count
                }
            }
            else {
                $importParams = @{
                    Worksheet    = $ws
                    InputObject  = $csvRows
                    StartAddress = 'A1'
                }
                if ($null -ne $headerMap) {
                    $importParams['HeaderMap'] = $headerMap
                }
                $importInfo = Import-CsvToWorksheet @importParams
            }

            Set-ExcelHeaderStyle -Worksheet $ws -HeaderRow 1 -ColumnCount $importInfo.ColumnCount -Freeze
            Set-ExcelAutoFit -Worksheet $ws -ColumnCount $importInfo.ColumnCount

            $saved = Save-ExcelWorkbook -Workbook $workbook -Path $OutputPath
            Close-ExcelWorkbook -Workbook $workbook
            $workbook = $null

            $result.Success = $true
            $result.OutputPath = $saved
            $result.RowCount = $importInfo.RowCount
            $result.ColumnCount = $importInfo.ColumnCount
            $result.Message = 'Export complete.'
        }
        catch {
            $msg = $_.Exception.Message
            if ($msg -match 'locked|in use|Cannot access|already open|Permission') {
                $msg = $msg + ' Close Excel completely and try again. Tools never force-kill Excel.'
            }
            throw $msg
        }
        finally {
            if ($null -ne $workbook) {
                try { Close-ExcelWorkbook -Workbook $workbook } catch { }
            }
            if ($null -ne $app) {
                Stop-ExcelApplication -Application $app
            }
        }

        return $result
    }
    catch {
        $result.Success = $false
        $result.Message = $_.Exception.Message
        return $result
    }
}

#endregion Export

Export-ModuleMember -Function @(
    'Get-ExcelToolkitVersion',
    'Export-ExcelFromCsv'
)
