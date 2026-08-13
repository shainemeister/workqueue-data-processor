#requires -Version 5.1
# Dev-only smoke test for Parse-SelectionRange (not product packaging).
$ErrorActionPreference = 'Stop'

$menuPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'Start-ExcelMenu.ps1'
$errs = $null
$tokens = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($menuPath, [ref]$tokens, [ref]$errs)
if ($errs -and $errs.Count -gt 0) {
    $errs | ForEach-Object { Write-Host $_.ToString() -ForegroundColor Red }
    exit 1
}
Write-Host 'PARSE_OK' -ForegroundColor Green

# Extract and define Parse-SelectionRange by reading the menu script AST is heavy;
# reimplement the same contract here for unit checks, then spot-check file still defines the name.
$menuText = [System.IO.File]::ReadAllText($menuPath)
if ($menuText -notmatch 'function Parse-SelectionRange') {
    throw 'Parse-SelectionRange not found in Start-ExcelMenu.ps1'
}
if ($menuText -notmatch 'function Get-ImportProcessableFiles') {
    throw 'Get-ImportProcessableFiles not found'
}
if ($menuText -notmatch 'function Invoke-ProcessMyData') {
    throw 'Invoke-ProcessMyData not found'
}
if ($menuText -notmatch 'function Read-OptionalExportPassword') {
    throw 'Read-OptionalExportPassword not found'
}
if ($menuText -notmatch '1\) Process my data') {
    throw 'Main menu Process my data label not found'
}
if ($menuText -notmatch '\[5\] Express score') {
    throw 'Process my data action [5] Express score not found'
}
Write-Host 'SYMBOLS_OK' -ForegroundColor Green

# Dot-source helpers only: run the function definitions by isolating via a temp module approach.
# Load the menu's parser by invoking a sandbox that copies the function from the file via ScriptBlock.
$ast = [System.Management.Automation.Language.Parser]::ParseFile($menuPath, [ref]$null, [ref]$null)
$funcAst = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
        $node.Name -eq 'Parse-SelectionRange'
    }, $true) | Select-Object -First 1
if ($null -eq $funcAst) {
    throw 'Could not locate Parse-SelectionRange AST'
}
. ([scriptblock]::Create($funcAst.Extent.Text))

$candidates = @(
    [pscustomobject]@{ FullName = 'C:\a\one.csv' }
    [pscustomobject]@{ FullName = 'C:\a\two.csv' }
    [pscustomobject]@{ FullName = 'C:\a\three.csv' }
    [pscustomobject]@{ FullName = 'C:\a\four.xlsx' }
    [pscustomobject]@{ FullName = 'C:\a\five.csv' }
)

function Assert-Eq {
    param($Name, $Got, $Expected)
    $gs = (@($Got) -join '|')
    $es = (@($Expected) -join '|')
    if ($gs -ne $es) {
        throw ("FAIL {0}: got=[{1}] expected=[{2}]" -f $Name, $gs, $es)
    }
    Write-Host ("OK {0}" -f $Name) -ForegroundColor Green
}

Assert-Eq 'single' (Parse-SelectionRange -Raw '1' -Candidates $candidates) @('C:\a\one.csv')
Assert-Eq 'list' (Parse-SelectionRange -Raw '1,3' -Candidates $candidates) @('C:\a\one.csv', 'C:\a\three.csv')
Assert-Eq 'range' (Parse-SelectionRange -Raw '1-3' -Candidates $candidates) @('C:\a\one.csv', 'C:\a\two.csv', 'C:\a\three.csv')
Assert-Eq 'mixed' (Parse-SelectionRange -Raw '1,3-5' -Candidates $candidates) @('C:\a\one.csv', 'C:\a\three.csv', 'C:\a\four.xlsx', 'C:\a\five.csv')
Assert-Eq 'spaces' (Parse-SelectionRange -Raw '1 2 3' -Candidates $candidates) @('C:\a\one.csv', 'C:\a\two.csv', 'C:\a\three.csv')
Assert-Eq 'dupes' (Parse-SelectionRange -Raw '1,1,2' -Candidates $candidates) @('C:\a\one.csv', 'C:\a\two.csv')
Assert-Eq 'empty' (Parse-SelectionRange -Raw '' -Candidates $candidates) @()

$threw = $false
try { Parse-SelectionRange -Raw '5-2' -Candidates $candidates | Out-Null } catch { $threw = $true }
if (-not $threw) { throw 'inverted range should throw' }
Write-Host 'OK inverted' -ForegroundColor Green

$threw = $false
try { Parse-SelectionRange -Raw '9' -Candidates $candidates | Out-Null } catch { $threw = $true }
if (-not $threw) { throw 'out of range should throw' }
Write-Host 'OK oor' -ForegroundColor Green

# Path fallback against real import file if present
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$sampleCsv = Join-Path $repoRoot 'import\wq_synthetic_data.csv'
if (Test-Path -LiteralPath $sampleCsv) {
    $got = @(Parse-SelectionRange -Raw $sampleCsv -Candidates $candidates)
    Assert-Eq 'path' $got @($sampleCsv)
}

Write-Host 'ALL_PARSER_TESTS_OK' -ForegroundColor Green
exit 0
