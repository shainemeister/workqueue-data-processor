#requires -Version 5.1
<#
.SYNOPSIS
    High-level Excel Toolkit operations for PowerShell and CLI consumers.

.DESCRIPTION
    Builds on ExcelCom.psm1. Prefer this module from other PowerShell scripts:

        Import-Module .\excel-toolkit\ExcelToolkit.psm1 -Force
        Export-ExcelFromCsv -CsvPath .\data.csv -OutputPath .\out.xlsx
        Import-CsvFromExcel -ExcelPath .\data.xlsx -OutputPath .\out.csv

    For Python / Task Scheduler / cmd, use ExcelToolkit.ps1 (CLI) instead.

.NOTES
    Project : workqueue-data-processor / excel-toolkit
    Compat  : Windows PowerShell 5.1
#>

Set-StrictMode -Version Latest

$script:ExcelToolkitVersion = '1.4.0'
$script:ExcelToolkitDiagnosticsReportVersion = 1

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

#region Output safety

function Resolve-ExcelToolkitUniquePath {
    <#
    .SYNOPSIS
        Resolve a destination path that will not clobber an existing file.

    .DESCRIPTION
        Without -Force, if the path already exists, appends _1, _2, ... before the
        extension until a free path is found (cap 999). With -Force, returns the
        exact path (caller may overwrite).

    .OUTPUTS
        PSCustomObject: Path (write target), RequestedPath, PathAdjusted (bool)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [switch]$Force,

        [int]$MaxAttempts = 999
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'Output path is required.'
    }

    $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

    if ($Force -or -not (Test-Path -LiteralPath $resolved)) {
        return [pscustomobject]@{
            Path          = $resolved
            RequestedPath = $resolved
            PathAdjusted  = $false
        }
    }

    $dir  = [System.IO.Path]::GetDirectoryName($resolved)
    $base = [System.IO.Path]::GetFileNameWithoutExtension($resolved)
    $ext  = [System.IO.Path]::GetExtension($resolved)

    for ($i = 1; $i -le $MaxAttempts; $i++) {
        $candidate = Join-Path $dir ('{0}_{1}{2}' -f $base, $i, $ext)
        if (-not (Test-Path -LiteralPath $candidate)) {
            return [pscustomobject]@{
                Path          = $candidate
                RequestedPath = $resolved
                PathAdjusted  = $true
            }
        }
    }

    throw ("Could not find a free output path after {0} attempts for: {1}" -f $MaxAttempts, $resolved)
}

function Assert-ExcelToolkitOutputWritable {
    <#
    .SYNOPSIS
        Legacy name: resolve a non-clobbering path unless -Force.

    .DESCRIPTION
        Prefer Resolve-ExcelToolkitUniquePath. This wrapper returns the unique Path
        string for older call sites.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [switch]$Force
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $Path
    }

    $info = Resolve-ExcelToolkitUniquePath -Path $Path -Force:$Force
    return $info.Path
}

#endregion Output safety

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

    .PARAMETER Password
        Optional workbook open password (SecureString) applied when saving the .xlsx.
        Never log this value. Empty/null = unprotected workbook.

    .PARAMETER Force
        Overwrite the exact OutputPath if it already exists. Without -Force, an
        existing path is not replaced: a free sibling path is chosen (name_1.ext, ...).

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

        [SecureString]$Password,

        [switch]$Force,

        [switch]$PassThru
    )

    $result = [pscustomobject]@{
        Success            = $false
        OutputPath         = $null
        RequestedOutputPath = $null
        PathAdjusted       = $false
        RowCount           = 0
        ColumnCount        = 0
        DryRun             = [bool]$DryRun
        Message            = ''
        HeadersSample      = @()
        SchemaFormat       = $null
        SheetName          = $SheetName
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

        # Unique path unless -Force (including DryRun planning)
        $pathInfo = Resolve-ExcelToolkitUniquePath -Path $OutputPath -Force:$Force
        $OutputPath = $pathInfo.Path
        $result.RequestedOutputPath = $pathInfo.RequestedPath
        $result.PathAdjusted = [bool]$pathInfo.PathAdjusted
        $result.OutputPath = $OutputPath
        $result.RowCount = $rowCount
        $result.ColumnCount = $propertyNames.Count
        $result.HeadersSample = @($displayHeaders | Select-Object -First 5)

        if ($DryRun) {
            $result.Success = $true
            if ($pathInfo.PathAdjusted) {
                $result.Message = ("DryRun complete - would write to {0} (avoided overwrite of {1})." -f $OutputPath, $pathInfo.RequestedPath)
            }
            else {
                $result.Message = 'DryRun complete - no workbook written.'
            }
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

            $saveParams = @{
                Workbook = $workbook
                Path     = $OutputPath
            }
            if ($null -ne $Password -and $Password.Length -gt 0) {
                $saveParams['Password'] = $Password
            }
            $saved = Save-ExcelWorkbook @saveParams
            Close-ExcelWorkbook -Workbook $workbook
            $workbook = $null

            $result.Success = $true
            $result.OutputPath = $saved
            $result.RowCount = $importInfo.RowCount
            $result.ColumnCount = $importInfo.ColumnCount
            if ($pathInfo.PathAdjusted) {
                $result.Message = ("Export complete (wrote {0}; avoided overwrite of {1})." -f $saved, $pathInfo.RequestedPath)
            }
            else {
                $result.Message = 'Export complete.'
            }
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

#region Import

function Import-CsvFromExcel {
    <#
    .SYNOPSIS
        Import an Excel workbook sheet to a CSV file.

    .DESCRIPTION
        Opens a local .xlsx/.xls via Excel COM, reads the chosen worksheet
        used range, and writes a UTF-8 CSV. Supports workbook open passwords:
        optional -Password (SecureString), or interactive SecureString prompt
        when allowed and the file requires a password.

        Returns a result object (does not call exit). Safe for Import-Module callers.
        Never includes the password in the result object or messages.

    .PARAMETER ExcelPath
        Input workbook path (required).

    .PARAMETER OutputPath
        Destination .csv path (required for real import).

    .PARAMETER SheetName
        Optional worksheet name. Default: first sheet.

    .PARAMETER Password
        Optional workbook open password as SecureString.

    .PARAMETER AllowPasswordPrompt
        When $true (default), prompt interactively if open fails for password reasons
        and no usable password was supplied. Set $false for automation / -Json CLI.

    .PARAMETER Visible
        Show Excel UI. Default: hidden.

    .PARAMETER DryRun
        Validate open and sheet selection only; do not write CSV.

    .PARAMETER Force
        Overwrite the exact OutputPath if it already exists. Without -Force, an
        existing path is not replaced: a free sibling path is chosen (name_1.csv, ...).

    .OUTPUTS
        PSCustomObject with Success, ExcelPath, OutputPath, RequestedOutputPath,
        PathAdjusted, RowCount, ColumnCount, SheetName, DryRun, Message,
        HeadersSample, PasswordUsed (boolean only).

    .EXAMPLE
        Import-CsvFromExcel -ExcelPath .\import\data.xlsx -OutputPath .\import\data.csv

    .EXAMPLE
        Import-CsvFromExcel -ExcelPath .\locked.xlsx -OutputPath .\out.csv -Password $secure
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExcelPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [string]$SheetName = '',

        [SecureString]$Password,

        [bool]$AllowPasswordPrompt = $true,

        [switch]$Visible,

        [switch]$DryRun,

        [switch]$Force,

        [switch]$PassThru
    )

    $result = [pscustomobject]@{
        Success             = $false
        ExcelPath           = $null
        OutputPath          = $null
        RequestedOutputPath = $null
        PathAdjusted        = $false
        RowCount            = 0
        ColumnCount         = 0
        SheetName           = $null
        DryRun              = [bool]$DryRun
        Message             = ''
        HeadersSample       = @()
        PasswordUsed        = $false
    }

    try {
        $ExcelPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ExcelPath)
        $OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
        $result.ExcelPath = $ExcelPath

        if (-not (Test-Path -LiteralPath $ExcelPath)) {
            throw ("Excel file not found: {0}" -f $ExcelPath)
        }

        # Unique path unless -Force (before Excel work; applies to DryRun too)
        $pathInfo = Resolve-ExcelToolkitUniquePath -Path $OutputPath -Force:$Force
        $OutputPath = $pathInfo.Path
        $result.RequestedOutputPath = $pathInfo.RequestedPath
        $result.PathAdjusted = [bool]$pathInfo.PathAdjusted
        $result.OutputPath = $OutputPath

        $envResult = Test-ExcelComEnvironment
        if (-not $envResult.Passed) {
            $failed = @($envResult.Checks | Where-Object { -not $_.Passed } | ForEach-Object { $_.Name })
            throw ("Environment preflight failed: {0}" -f ($failed -join ', '))
        }

        $app = $null
        $workbook = $null
        $securePwd = $Password
        $passwordUsed = ($null -ne $securePwd -and $securePwd.Length -gt 0)

        try {
            $app = New-ExcelApplication -Visible:$Visible

            $openAttempts = 0
            $maxAttempts = 2
            $opened = $false
            $lastOpenError = $null

            while (-not $opened -and $openAttempts -lt $maxAttempts) {
                $openAttempts++
                try {
                    $openParams = @{
                        Application = $app
                        Path        = $ExcelPath
                        ReadOnly    = $true
                    }
                    if ($null -ne $securePwd -and $securePwd.Length -gt 0) {
                        $openParams['Password'] = $securePwd
                    }
                    $workbook = Open-ExcelWorkbook @openParams
                    $opened = $true
                }
                catch {
                    $lastOpenError = $_.Exception.Message
                    $isPwd = Test-ExcelPasswordRelatedError -Message $lastOpenError
                    if (-not $isPwd) {
                        throw $lastOpenError
                    }

                    # Wrong password supplied explicitly
                    if ($null -ne $Password -and $Password.Length -gt 0 -and $openAttempts -eq 1 -and -not $AllowPasswordPrompt) {
                        throw 'Incorrect workbook password (or the file could not be opened with the supplied password).'
                    }

                    if (-not $AllowPasswordPrompt) {
                        throw 'Workbook requires a password. Provide -Password, or run interactively to be prompted.'
                    }

                    if ($openAttempts -ge $maxAttempts) {
                        throw 'Incorrect workbook password (or the file could not be opened).'
                    }

                    try {
                        $securePwd = Read-Host -Prompt 'Workbook password' -AsSecureString
                    }
                    catch {
                        throw 'Workbook requires a password, but an interactive prompt is not available. Provide -Password.'
                    }

                    if ($null -eq $securePwd -or $securePwd.Length -eq 0) {
                        throw 'Workbook requires a password. No password was entered.'
                    }
                    $passwordUsed = $true
                }
            }

            if (-not $opened -or $null -eq $workbook) {
                throw $(if ($lastOpenError) { $lastOpenError } else { 'Failed to open workbook.' })
            }

            $result.PasswordUsed = [bool]$passwordUsed

            if (-not [string]::IsNullOrWhiteSpace($SheetName)) {
                $ws = Get-ExcelWorksheet -Workbook $workbook -Name $SheetName
                $result.SheetName = $SheetName
            }
            else {
                $ws = Get-ExcelWorksheet -Workbook $workbook -Index 1
                try {
                    $result.SheetName = [string]$ws.Name
                }
                catch {
                    $result.SheetName = 'Sheet1'
                }
            }

            # Sample headers from first row of used range (best-effort; COM cleanup on Quit)
            $headersSample = @()
            $colCount = 0
            $dataRowCount = 0
            try {
                $used = $ws.UsedRange
                if ($null -ne $used) {
                    $colCount = [int]$used.Columns.Count
                    $totalRows = [int]$used.Rows.Count
                    if ($totalRows -gt 0) {
                        $dataRowCount = [Math]::Max(0, $totalRows - 1)
                    }
                    $maxSample = [Math]::Min(5, $colCount)
                    for ($c = 1; $c -le $maxSample; $c++) {
                        $val = $used.Cells.Item(1, $c).Value2
                        $headersSample += $(if ($null -eq $val) { '' } else { [string]$val })
                    }
                }
            }
            catch {
                Write-Verbose ("Header sample: {0}" -f $_.Exception.Message)
            }

            $result.ColumnCount = $colCount
            $result.RowCount = $dataRowCount
            $result.HeadersSample = @($headersSample)

            if ($DryRun) {
                Close-ExcelWorkbook -Workbook $workbook
                $workbook = $null
                $result.Success = $true
                if ($pathInfo.PathAdjusted) {
                    $result.Message = ("DryRun complete - would write to {0} (avoided overwrite of {1})." -f $OutputPath, $pathInfo.RequestedPath)
                }
                else {
                    $result.Message = 'DryRun complete - no CSV written.'
                }
                return $result
            }

            $saved = Export-WorksheetToCsv -Worksheet $ws -Path $OutputPath
            Close-ExcelWorkbook -Workbook $workbook
            $workbook = $null

            # Prefer Import-Csv for accurate data-row count and headers
            if (Test-Path -LiteralPath $saved) {
                $csvRows = @(Import-Csv -LiteralPath $saved)
                $result.RowCount = $csvRows.Count
                if ($csvRows.Count -gt 0) {
                    $names = @($csvRows[0].PSObject.Properties | ForEach-Object { $_.Name })
                    $result.ColumnCount = $names.Count
                    $result.HeadersSample = @($names | Select-Object -First 5)
                }
                elseif ($colCount -gt 0) {
                    # Header-only file
                    $result.RowCount = 0
                }
            }

            $result.Success = $true
            $result.OutputPath = $saved
            if ($pathInfo.PathAdjusted) {
                $result.Message = ("Import complete (wrote {0}; avoided overwrite of {1})." -f $saved, $pathInfo.RequestedPath)
            }
            else {
                $result.Message = 'Import complete.'
            }
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
            $securePwd = $null
        }

        return $result
    }
    catch {
        $result.Success = $false
        $result.Message = $_.Exception.Message
        # Never attach password material; PasswordUsed stays boolean default unless set above
        return $result
    }
}

#endregion Import

#region Enterprise diagnostics gate

function Get-ExcelToolkitDiagnosticsDir {
    <#
    .SYNOPSIS
        Return the excel-toolkit\diagnostics directory path.
    #>
    [CmdletBinding()]
    param()
    return (Join-Path $PSScriptRoot 'diagnostics')
}

function Get-ExcelToolkitDiagnosticsReportPaths {
    <#
    .SYNOPSIS
        Return paths for the machine certificate JSON and human text report.
    #>
    [CmdletBinding()]
    param()
    $dir = Get-ExcelToolkitDiagnosticsDir
    return [pscustomobject]@{
        Directory = $dir
        JsonPath  = (Join-Path $dir 'last_diagnostics.json')
        TextPath  = (Join-Path $dir 'last_diagnostics.txt')
    }
}

function Get-ExcelToolkitUtcNowIso {
    return ([datetime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss+00:00'))
}

function New-ExcelToolkitDiagnosticsCheck {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [bool]$Passed,

        [string]$Detail = '',

        [ValidateSet('critical', 'advisory')]
        [string]$Severity = 'critical'
    )
    return [pscustomobject]@{
        Name     = $Name
        Passed   = [bool]$Passed
        Severity = $Severity
        Detail   = $Detail
    }
}

function Invoke-ExcelToolkitReadinessChecks {
    <#
    .SYNOPSIS
        Run DryRun-style readiness checks (env, module exports, Excel COM).

    .DESCRIPTION
        Shared suite for diagnostics certificate and Test-ExcelCom -DryRun.
        Does not write permanent workbooks. Excel COM uses graceful Quit path.
    #>
    [CmdletBinding()]
    param(
        [string]$CsvPath,

        [string]$SchemaPath,

        [switch]$SkipExcelProbe
    )

    $checks = New-Object System.Collections.Generic.List[object]

    # Reuse COM environment preflight (PS version, temp, optional paths, Excel COM)
    $envResult = Test-ExcelComEnvironment -CsvPath $CsvPath -SchemaPath $SchemaPath -SkipExcelProbe:$SkipExcelProbe
    foreach ($c in @($envResult.Checks)) {
        $checks.Add((New-ExcelToolkitDiagnosticsCheck -Name $c.Name -Passed ([bool]$c.Passed) -Detail ([string]$c.Detail) -Severity 'critical'))
    }

    # Module surface (ExcelCom) — same spirit as Test-ExcelCom.ps1 DryRun
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
    $exported = @()
    try {
        $exported = @(Get-Command -Module ExcelCom -ErrorAction Stop | ForEach-Object { $_.Name })
    }
    catch {
        $exported = @()
    }
    $missing = @($expectedFunctions | Where-Object { $exported -notcontains $_ })
    if ($missing.Count -eq 0) {
        $exportDetail = ('{0} ExcelCom functions exported' -f $exported.Count)
        $exportOk = $true
    }
    else {
        $exportDetail = ('Missing: {0}' -f ($missing -join ', '))
        $exportOk = $false
    }
    $checks.Add((New-ExcelToolkitDiagnosticsCheck -Name 'ModuleExports' -Passed $exportOk -Detail $exportDetail -Severity 'critical'))

    # Diagnostics directory writable
    $diagDir = Get-ExcelToolkitDiagnosticsDir
    $diagWriteOk = $false
    $diagDetail = $diagDir
    try {
        if (-not (Test-Path -LiteralPath $diagDir)) {
            New-Item -ItemType Directory -Path $diagDir -Force | Out-Null
        }
        $probe = Join-Path $diagDir ('.write_probe_{0}.tmp' -f [guid]::NewGuid().ToString('N'))
        'ok' | Set-Content -LiteralPath $probe -Encoding ASCII
        $diagWriteOk = Test-Path -LiteralPath $probe
        Remove-Item -LiteralPath $probe -Force -ErrorAction SilentlyContinue
        if ($diagWriteOk) {
            $diagDetail = ('{0} (writable)' -f $diagDir)
        }
    }
    catch {
        $diagWriteOk = $false
        $diagDetail = $_.Exception.Message
    }
    $checks.Add((New-ExcelToolkitDiagnosticsCheck -Name 'DiagnosticsDirWritable' -Passed $diagWriteOk -Detail $diagDetail -Severity 'critical'))

    # Toolkit module identity
    $checks.Add((New-ExcelToolkitDiagnosticsCheck -Name 'ToolkitVersion' -Passed $true -Detail (Get-ExcelToolkitVersion) -Severity 'advisory'))
    $checks.Add((New-ExcelToolkitDiagnosticsCheck -Name 'ToolkitRoot' -Passed $true -Detail $PSScriptRoot -Severity 'advisory'))

    return $checks.ToArray()
}

function Format-ExcelToolkitDiagnosticsTextReport {
    param(
        [Parameter(Mandatory = $true)]
        $Result
    )

    $overall = if ($Result.OverallPass) { 'PASS' } else { 'FAIL' }
    $lines = New-Object System.Collections.Generic.List[string]
    [void]$lines.Add('Excel Toolkit — Enterprise Diagnostics')
    [void]$lines.Add(('ToolkitVersion: {0}' -f $Result.ToolkitVersion))
    [void]$lines.Add(('PowerShellVersion: {0}' -f $Result.PowerShellVersion))
    [void]$lines.Add(('Platform: {0}' -f $Result.Platform))
    [void]$lines.Add(('OverallPass: {0}' -f $overall))
    [void]$lines.Add(('StartedAt: {0}' -f $Result.StartedAt))
    [void]$lines.Add(('FinishedAt: {0}' -f $Result.FinishedAt))
    [void]$lines.Add(('ToolkitRoot: {0}' -f $Result.ToolkitRoot))
    [void]$lines.Add('')
    [void]$lines.Add('Checks:')
    foreach ($c in @($Result.Checks)) {
        $flag = if ($c.Passed) { 'PASS' } else { 'FAIL' }
        $sev = $c.Severity
        if ([string]::IsNullOrWhiteSpace($sev)) { $sev = 'critical' }
        [void]$lines.Add(('  [{0}] ({1}) {2}: {3}' -f $flag, $sev, $c.Name, $c.Detail))
    }
    $failed = @($Result.CriticalFailed)
    if ($failed.Count -gt 0) {
        [void]$lines.Add('')
        [void]$lines.Add(('Critical failures: {0}' -f ($failed -join ', ')))
    }
    [void]$lines.Add('')
    [void]$lines.Add([string]$Result.Message)
    [void]$lines.Add('')
    [void]$lines.Add('Privacy: this report records environment and module/COM readiness only; it does not include claim rows or PHI.')
    [void]$lines.Add('')
    return ($lines -join "`r`n")
}

function Write-ExcelToolkitDiagnosticsReports {
    <#
    .SYNOPSIS
        Write last_diagnostics.json and last_diagnostics.txt under diagnostics\.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Result
    )

    $paths = Get-ExcelToolkitDiagnosticsReportPaths
    if (-not (Test-Path -LiteralPath $paths.Directory)) {
        New-Item -ItemType Directory -Path $paths.Directory -Force | Out-Null
    }

    # ConvertTo-Json for gate readers (Depth covers Checks array)
    $json = $Result | ConvertTo-Json -Depth 8
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($paths.JsonPath, $json + "`r`n", $utf8)

    $text = Format-ExcelToolkitDiagnosticsTextReport -Result $Result
    [System.IO.File]::WriteAllText($paths.TextPath, $text, $utf8)

    return [pscustomobject]@{
        JsonPath = $paths.JsonPath
        TextPath = $paths.TextPath
    }
}

function Invoke-ExcelToolkitDiagnostics {
    <#
    .SYNOPSIS
        Run readiness diagnostics and optionally write the pass/fail certificate.

    .PARAMETER Write
        When $true (default), refresh last_diagnostics.json/.txt.

    .PARAMETER CsvPath / SchemaPath
        Optional path checks (same as probe).
    #>
    [CmdletBinding()]
    param(
        [bool]$Write = $true,

        [string]$CsvPath,

        [string]$SchemaPath,

        [switch]$SkipExcelProbe
    )

    $started = Get-ExcelToolkitUtcNowIso
    $checks = @(Invoke-ExcelToolkitReadinessChecks -CsvPath $CsvPath -SchemaPath $SchemaPath -SkipExcelProbe:$SkipExcelProbe)

    $criticalFailed = @(
        $checks |
            Where-Object { $_.Severity -eq 'critical' -and -not $_.Passed } |
            ForEach-Object { [string]$_.Name }
    )
    $overall = ($criticalFailed.Count -eq 0)
    $finished = Get-ExcelToolkitUtcNowIso

    $result = [pscustomobject]@{
        ReportVersion     = [int]$script:ExcelToolkitDiagnosticsReportVersion
        Success           = [bool]$overall
        OverallPass       = [bool]$overall
        Command           = 'diagnostics'
        Version           = (Get-ExcelToolkitVersion)
        ToolkitVersion    = (Get-ExcelToolkitVersion)
        PowerShellVersion = [string]$PSVersionTable.PSVersion
        Platform          = [string][System.Environment]::OSVersion.Platform
        StartedAt         = $started
        FinishedAt        = $finished
        ToolkitRoot       = $PSScriptRoot
        CriticalFailed    = $criticalFailed
        Checks            = $checks
        Message           = $(
            if ($overall) {
                'Diagnostics passed. Operational commands may proceed.'
            }
            else {
                'Diagnostics failed. Fix critical failures before export-csv/import-excel.'
            }
        )
        ReportJsonPath    = $null
        ReportTextPath    = $null
    }

    if ($Write) {
        try {
            $written = Write-ExcelToolkitDiagnosticsReports -Result $result
            $result.ReportJsonPath = $written.JsonPath
            $result.ReportTextPath = $written.TextPath
        }
        catch {
            $result.Success = $false
            $result.OverallPass = $false
            $result.Message = ('Diagnostics checks finished but report write failed: {0}' -f $_.Exception.Message)
            $cf = New-Object System.Collections.Generic.List[string]
            foreach ($n in @($result.CriticalFailed)) { [void]$cf.Add([string]$n) }
            if ($cf -notcontains 'ReportWrite') { [void]$cf.Add('ReportWrite') }
            $result.CriticalFailed = $cf.ToArray()
            $checkList = New-Object System.Collections.Generic.List[object]
            foreach ($c in @($result.Checks)) { [void]$checkList.Add($c) }
            [void]$checkList.Add((New-ExcelToolkitDiagnosticsCheck -Name 'ReportWrite' -Passed $false -Detail $_.Exception.Message -Severity 'critical'))
            $result.Checks = $checkList.ToArray()
        }
    }

    return $result
}

function Test-ExcelToolkitPassCertificate {
    <#
    .SYNOPSIS
        Return the stored diagnostics report if it is a valid pass certificate; else $null.
    #>
    [CmdletBinding()]
    param()

    $paths = Get-ExcelToolkitDiagnosticsReportPaths
    if (-not (Test-Path -LiteralPath $paths.JsonPath)) {
        return $null
    }

    try {
        $raw = Get-Content -LiteralPath $paths.JsonPath -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return $null
        }
        $data = $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return $null
    }

    if ($null -eq $data) {
        return $null
    }

    $reportVer = 0
    try { $reportVer = [int]$data.ReportVersion } catch { $reportVer = 0 }
    if ($reportVer -ne [int]$script:ExcelToolkitDiagnosticsReportVersion) {
        return $null
    }

    $pass = $false
    try { $pass = [bool]$data.OverallPass } catch { $pass = $false }
    if (-not $pass) {
        return $null
    }

    $certToolkit = [string]$data.ToolkitVersion
    if ($certToolkit -ne (Get-ExcelToolkitVersion)) {
        return $null
    }

    return $data
}

function Assert-ExcelToolkitDiagnosticsPass {
    <#
    .SYNOPSIS
        Ensure a valid diagnostics pass certificate exists (auto-run if missing).

    .DESCRIPTION
        Gate decision object:
          GateOk, GateMode (cached|ran|skipped|blocked), Diagnostics, Message, report paths.

    .PARAMETER Force
        Re-run diagnostics even if a valid certificate exists.

    .PARAMETER Skip
        Emergency bypass (does not write a pass certificate).
    #>
    [CmdletBinding()]
    param(
        [switch]$Force,

        [switch]$Skip,

        [string]$CsvPath,

        [string]$SchemaPath
    )

    if ($Skip) {
        return [pscustomobject]@{
            GateOk                  = $true
            GateMode                = 'skipped'
            DiagnosticsGateSkipped  = $true
            Diagnostics             = $null
            ReportJsonPath          = $null
            ReportTextPath          = $null
            Message                 = 'Diagnostics gate skipped (-SkipDiagnosticsGate). Emergency/support use only.'
        }
    }

    if (-not $Force) {
        $cached = Test-ExcelToolkitPassCertificate
        if ($null -ne $cached) {
            $paths = Get-ExcelToolkitDiagnosticsReportPaths
            $textPath = $null
            if (Test-Path -LiteralPath $paths.TextPath) {
                $textPath = $paths.TextPath
            }
            return [pscustomobject]@{
                GateOk                  = $true
                GateMode                = 'cached'
                DiagnosticsGateSkipped  = $false
                Diagnostics             = $cached
                ReportJsonPath          = $paths.JsonPath
                ReportTextPath          = $textPath
                Message                 = 'Diagnostics certificate valid (cached pass).'
            }
        }
    }

    $result = Invoke-ExcelToolkitDiagnostics -Write $true -CsvPath $CsvPath -SchemaPath $SchemaPath
    if ($result.OverallPass) {
        return [pscustomobject]@{
            GateOk                  = $true
            GateMode                = 'ran'
            DiagnosticsGateSkipped  = $false
            Diagnostics             = $result
            ReportJsonPath          = $result.ReportJsonPath
            ReportTextPath          = $result.ReportTextPath
            Message                 = 'Diagnostics auto-ran and passed.'
        }
    }

    $textPath = $result.ReportTextPath
    if ([string]::IsNullOrWhiteSpace($textPath)) {
        $textPath = (Get-ExcelToolkitDiagnosticsReportPaths).TextPath
    }
    return [pscustomobject]@{
        GateOk                  = $false
        GateMode                = 'blocked'
        DiagnosticsGateSkipped  = $false
        Diagnostics             = $result
        ReportJsonPath          = $result.ReportJsonPath
        ReportTextPath          = $textPath
        Message                 = (
            'Diagnostics gate blocked this command. See: {0}. Re-run: excel-toolkit.cmd diagnostics -Force' -f $textPath
        )
    }
}

function Add-ExcelToolkitGateFields {
    <#
    .SYNOPSIS
        Attach diagnostics gate metadata onto a CLI/result hashtable or PSCustomObject fields.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Target,

        [Parameter(Mandatory = $true)]
        $Gate
    )

    $Target['DiagnosticsGate'] = [string]$Gate.GateMode
    $Target['DiagnosticsGateSkipped'] = [bool]$Gate.DiagnosticsGateSkipped
    if (-not [string]::IsNullOrWhiteSpace([string]$Gate.ReportJsonPath)) {
        $Target['DiagnosticsReportJsonPath'] = [string]$Gate.ReportJsonPath
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$Gate.ReportTextPath)) {
        $Target['DiagnosticsReportTextPath'] = [string]$Gate.ReportTextPath
    }
    return $Target
}

#endregion Enterprise diagnostics gate

Export-ModuleMember -Function @(
    'Get-ExcelToolkitVersion',
    'Resolve-ExcelToolkitUniquePath',
    'Export-ExcelFromCsv',
    'Import-CsvFromExcel',
    'Get-ExcelToolkitDiagnosticsDir',
    'Get-ExcelToolkitDiagnosticsReportPaths',
    'Invoke-ExcelToolkitReadinessChecks',
    'Invoke-ExcelToolkitDiagnostics',
    'Write-ExcelToolkitDiagnosticsReports',
    'Test-ExcelToolkitPassCertificate',
    'Assert-ExcelToolkitDiagnosticsPass',
    'Add-ExcelToolkitGateFields'
)
