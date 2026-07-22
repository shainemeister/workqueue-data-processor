#requires -Version 5.1
<#
.SYNOPSIS
    Compatibility forwarder to Export-CsvToExcel.ps1.

.DESCRIPTION
    Older entry point. Prefer Export-CsvToExcel.ps1 or Start-ExcelMenu.cmd.
    Forwards all arguments; default output remains output\wq_data.xlsx for
    backward compatibility with prior docs.
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

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path -Parent $scriptDir
$target    = Join-Path $scriptDir 'Export-CsvToExcel.ps1'

if (-not (Test-Path -LiteralPath $target)) {
    throw ("Export-CsvToExcel.ps1 not found: {0}" -f $target)
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $repoRoot 'output\wq_data.xlsx'
}

$forward = @{
    OutputPath = $OutputPath
    SheetName  = $SheetName
}

if (-not [string]::IsNullOrWhiteSpace($CsvPath)) { $forward['CsvPath'] = $CsvPath }
if (-not [string]::IsNullOrWhiteSpace($SchemaPath)) { $forward['SchemaPath'] = $SchemaPath }
if ($SchemaFormat -ne 'Auto') { $forward['SchemaFormat'] = $SchemaFormat }
if (-not [string]::IsNullOrWhiteSpace($DisplayNameProperty)) { $forward['DisplayNameProperty'] = $DisplayNameProperty }
if ($UseDisplayNames) { $forward['UseDisplayNames'] = $true }
if ($Visible) { $forward['Visible'] = $true }
if ($DryRun) { $forward['DryRun'] = $true }
if ($Force) { $forward['Force'] = $true }

& $target @forward
exit $LASTEXITCODE
