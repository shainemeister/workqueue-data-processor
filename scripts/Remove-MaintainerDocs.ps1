#requires -Version 5.1
<#
.SYNOPSIS
    Remove maintainer-only docs from this working copy after a clone.

.DESCRIPTION
    Deletes tracked planning / kit / certification / fixture trees from the
    working directory so an operator checkout is smaller. Product toolkits,
    schema, import samples, LICENSE, and toolkit user guides stay.

    This is not git clean and not a history rewrite. Git still has every file.
    Restore with:  git checkout -- .

    Do not commit the deletions.

.PARAMETER WhatIf
    Print paths that would be removed; do not delete.

.PARAMETER Force
    Skip the confirmation prompt.

.PARAMETER GitCleanUntracked
    Also run "git clean -fd" for untracked files. Does not use -x (ignored
    output\ and local import copies are kept).
#>
[CmdletBinding(SupportsShouldProcess = $false)]
param(
    [switch]$WhatIf,
    [switch]$Force,
    [switch]$GitCleanUntracked
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$repoRoot = Split-Path -Parent $scriptDir

$marker = Join-Path $repoRoot 'Start-ExcelMenu.cmd'
$kpiDir = Join-Path $repoRoot 'kpi-analytics'
$excelDir = Join-Path $repoRoot 'excel-toolkit'
if (-not (Test-Path -LiteralPath $marker) -or -not (Test-Path -LiteralPath $kpiDir) -or -not (Test-Path -LiteralPath $excelDir)) {
    throw 'Run this script from a workqueue-data-processor clone (Start-ExcelMenu.cmd + both toolkits).'
}

# Maintainer / AI / certification only. Do not list toolkit README or CLI-GUIDE.
$relativeTargets = @(
    'kit',
    'docs',
    'certification',
    'PLAN.md',
    'CHANGELOG.md',
    'kpi-analytics\fixtures',
    'excel-toolkit\sample-test'
)

$toRemove = New-Object System.Collections.Generic.List[string]
foreach ($rel in $relativeTargets) {
    $full = Join-Path $repoRoot $rel
    if (Test-Path -LiteralPath $full) {
        $toRemove.Add($full)
    }
}

Write-Host 'Operator working-copy slim' -ForegroundColor Cyan
Write-Host 'Removes maintainer docs from this folder only. Git history is unchanged.' -ForegroundColor DarkGray
Write-Host 'Kept: toolkits, wq_schema, import, LICENSE, README, Start-ExcelMenu.cmd,' -ForegroundColor DarkGray
Write-Host '      toolkit README / CLI-GUIDE / methodology / ENTERPRISE-SECURITY.' -ForegroundColor DarkGray
Write-Host ''
if ($toRemove.Count -eq 0) {
    Write-Host 'Nothing to remove (already slim, or paths missing).' -ForegroundColor Yellow
}
else {
    Write-Host 'Will remove:' -ForegroundColor Cyan
    foreach ($p in $toRemove) {
        Write-Host ("  {0}" -f $p) -ForegroundColor DarkGray
    }
}

if ($GitCleanUntracked) {
    Write-Host 'Also: git clean -fd (untracked only; ignored output\ / import copies kept).' -ForegroundColor DarkGray
}

if ($WhatIf) {
    Write-Host 'WhatIf: no files deleted.' -ForegroundColor Yellow
    exit 0
}

if (-not $Force) {
    $ans = Read-Host 'Delete these paths from the working copy? [y/N]'
    if ($ans -notmatch '^[Yy]$') {
        Write-Host 'Cancelled.' -ForegroundColor Yellow
        exit 0
    }
}

foreach ($p in $toRemove) {
    if (Test-Path -LiteralPath $p -PathType Container) {
        Remove-Item -LiteralPath $p -Recurse -Force
    }
    else {
        Remove-Item -LiteralPath $p -Force
    }
    Write-Host ("Removed {0}" -f $p) -ForegroundColor Green
}

if ($GitCleanUntracked) {
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($null -eq $git) {
        Write-Host 'git not on PATH; skipped untracked clean.' -ForegroundColor Yellow
    }
    else {
        Push-Location -LiteralPath $repoRoot
        try {
            & git clean -fd
        }
        finally {
            Pop-Location
        }
    }
}

Write-Host ''
Write-Host 'Restore later:  git checkout -- .' -ForegroundColor Cyan
Write-Host 'Do not commit these deletions.' -ForegroundColor Yellow
exit 0
