#Requires -Version 5.1
<#
.SYNOPSIS
    Full security + code-validation certification harness (developer-only).

.DESCRIPTION
    Runs every required check in certification/checks.json (Domain A security and
    Domain B code validation, including pylint and dual-mode Gitleaks), writes
    last_certification.json and last_certification.txt, and exits 0 only when
    OverallPass is true.

    Not a product launcher. Do not call from kpi-analytics, excel-toolkit, or
    package diagnostics gates. Partial runs are not supported: the full suite
    always executes.

.NOTES
    PowerShell 5.1 compatible. Save as UTF-8 with BOM.
#>
[CmdletBinding()]
param(
    [string]$RepoRoot = '',
    [switch]$SkipWrite
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

function Get-RepoRoot {
    param([string]$Hint)
    if ($Hint -and (Test-Path -LiteralPath (Join-Path $Hint 'RULES.md'))) {
        return (Resolve-Path -LiteralPath $Hint).Path
    }
    $here = $PSScriptRoot
    if (-not $here) { $here = Split-Path -Parent $MyInvocation.MyCommand.Path }
    $candidate = Split-Path -Parent $here
    if (Test-Path -LiteralPath (Join-Path $candidate 'RULES.md')) {
        return (Resolve-Path -LiteralPath $candidate).Path
    }
    throw "Could not resolve repository root (expected RULES.md above certification\)."
}

function Get-GitMeta {
    param([string]$Root)
    $meta = [ordered]@{
        GitCommit = ''
        GitBranch = ''
        GitDirty  = $false
    }
    Push-Location $Root
    try {
        $commit = & git rev-parse HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $commit) { $meta.GitCommit = ($commit | Out-String).Trim() }
        $branch = & git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $branch) { $meta.GitBranch = ($branch | Out-String).Trim() }
        $porcelain = & git status --porcelain 2>$null
        if ($LASTEXITCODE -eq 0) {
            $dirtyText = ($porcelain | Out-String).Trim()
            $meta.GitDirty = -not [string]::IsNullOrWhiteSpace($dirtyText)
        }
    } finally {
        Pop-Location
    }
    return $meta
}

function Get-ToolVersion {
    param([string]$Name, [scriptblock]$Block)
    try {
        $out = & $Block 2>&1 | Out-String
        $line = ($out -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 1)
        if ($line) { return $line.Trim() }
    } catch { }
    return 'unknown'
}

function Get-PackageVersions {
    param([string]$Root)
    $versions = [ordered]@{
        kpi_modules        = 'unknown'
        ExcelToolkitVersion = 'unknown'
    }

    $initPath = Join-Path $Root 'kpi-analytics\kpi_modules\__init__.py'
    if (Test-Path -LiteralPath $initPath) {
        try {
            $text = Get-Content -LiteralPath $initPath -Raw -ErrorAction Stop
            if ($text -match '__version__\s*=\s*["'']([^"'']+)["'']') {
                $versions.kpi_modules = $Matches[1]
            }
        } catch { }
    }

    $psmPath = Join-Path $Root 'excel-toolkit\ExcelToolkit.psm1'
    if (Test-Path -LiteralPath $psmPath) {
        try {
            $text = Get-Content -LiteralPath $psmPath -Raw -ErrorAction Stop
            if ($text -match 'ExcelToolkitVersion\s*=\s*[''"]([^''"]+)[''"]') {
                $versions.ExcelToolkitVersion = $Matches[1]
            }
        } catch { }
    }

    return $versions
}

function Test-IsPureAscii {
    param([byte[]]$Bytes)
    foreach ($b in $Bytes) {
        if ($b -gt 127) { return $false }
    }
    return $true
}

function Test-Utf8BomOrAscii {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return $true
    }
    return (Test-IsPureAscii -Bytes $bytes)
}

function Get-CheckExcludeNames {
    param([object]$Check)
    $exclude = @()
    if ($Check.PSObject.Properties.Name -contains 'ExcludeDirectoryNames' -and $Check.ExcludeDirectoryNames) {
        $exclude = @($Check.ExcludeDirectoryNames)
    }
    return $exclude
}

function Get-CheckIncludePatterns {
    param([object]$Check)
    if ($Check.PSObject.Properties.Name -contains 'Include' -and $Check.Include) {
        return @($Check.Include)
    }
    return @('*.ps1', '*.psm1')
}

function Test-PathExcludedByDirectoryNames {
    param(
        [string]$FullPath,
        [string]$BasePath,
        [string[]]$ExcludeDirectoryNames
    )
    if (-not $ExcludeDirectoryNames -or $ExcludeDirectoryNames.Count -eq 0) {
        return $false
    }
    $relPath = $FullPath.Substring($BasePath.Length).TrimStart('\', '/')
    foreach ($ex in $ExcludeDirectoryNames) {
        if ($FullPath -match [regex]::Escape([IO.Path]::DirectorySeparatorChar + $ex + [IO.Path]::DirectorySeparatorChar) -or
            $FullPath -match [regex]::Escape('/' + $ex + '/')) {
            return $true
        }
        if ($relPath -like ($ex + '\*') -or $relPath -like ($ex + '/*')) {
            return $true
        }
    }
    return $false
}

function Get-ProductScriptFiles {
    param(
        [string]$Root,
        [object]$Check
    )
    $rel = [string]$Check.Path
    $base = Join-Path $Root $rel
    if (-not (Test-Path -LiteralPath $base)) {
        return @{ Ok = $false; Base = $base; Files = @(); Error = "Path not found: $rel" }
    }

    $exclude = Get-CheckExcludeNames -Check $Check
    $patterns = Get-CheckIncludePatterns -Check $Check
    $files = @()
    foreach ($pat in $patterns) {
        $files += Get-ChildItem -LiteralPath $base -Recurse -File -Filter $pat -ErrorAction SilentlyContinue
    }
    $files = $files | Where-Object {
        -not (Test-PathExcludedByDirectoryNames -FullPath $_.FullName -BasePath $base -ExcludeDirectoryNames $exclude)
    } | Sort-Object FullName -Unique

    return @{ Ok = $true; Base = $base; Files = @($files); Error = $null }
}

function Invoke-PsParseBomCheck {
    param(
        [string]$Root,
        [object]$Check
    )
    $resolved = Get-ProductScriptFiles -Root $Root -Check $Check
    if (-not $resolved.Ok) {
        return @{ Passed = $false; Detail = $resolved.Error; ExitCode = 1 }
    }
    $files = $resolved.Files
    if ($files.Count -eq 0) {
        return @{ Passed = $false; Detail = "No scripts matched under $($Check.Path)"; ExitCode = 1 }
    }

    $bomFails = @()
    $parseFails = @()
    $tokens = $null
    $errors = $null

    foreach ($f in $files) {
        if (-not (Test-Utf8BomOrAscii -Path $f.FullName)) {
            $bomFails += $f.Name
        }
        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tokens, [ref]$errors)
        if ($errors -and $errors.Count -gt 0) {
            $parseFails += ($f.Name + ' (' + $errors[0].Message + ')')
        }
    }

    $parts = @()
    $parts += ("files={0}" -f $files.Count)
    if ($bomFails.Count -gt 0) {
        $parts += ("bom_fail={0}:{1}" -f $bomFails.Count, (($bomFails | Select-Object -First 5) -join ','))
    }
    if ($parseFails.Count -gt 0) {
        $parts += ("parse_fail={0}:{1}" -f $parseFails.Count, (($parseFails | Select-Object -First 3) -join '; '))
    }
    $passed = ($bomFails.Count -eq 0 -and $parseFails.Count -eq 0)
    if ($passed) { $parts += 'parse_ok; bom_or_ascii_ok' }
    return @{
        Passed   = $passed
        Detail   = ($parts -join '; ')
        ExitCode = $(if ($passed) { 0 } else { 1 })
    }
}

function Invoke-PssaCheck {
    param(
        [string]$Root,
        [object]$Check
    )
    $mod = Get-Module -ListAvailable -Name PSScriptAnalyzer | Select-Object -First 1
    if (-not $mod) {
        return @{ Passed = $false; Detail = 'PSScriptAnalyzer module not installed'; ExitCode = 1 }
    }
    Import-Module PSScriptAnalyzer -ErrorAction SilentlyContinue

    $resolved = Get-ProductScriptFiles -Root $Root -Check $Check
    if (-not $resolved.Ok) {
        return @{ Passed = $false; Detail = $resolved.Error; ExitCode = 1 }
    }
    $files = $resolved.Files
    if ($files.Count -eq 0) {
        return @{ Passed = $false; Detail = "No scripts matched under $($Check.Path)"; ExitCode = 1 }
    }

    $sev = 'Error'
    if ($Check.PSObject.Properties.Name -contains 'AnalyzerSeverity' -and $Check.AnalyzerSeverity) {
        $sev = [string]$Check.AnalyzerSeverity
    }

    $results = @()
    foreach ($f in $files) {
        $results += @(Invoke-ScriptAnalyzer -Path $f.FullName -Severity $sev -ErrorAction SilentlyContinue)
    }
    $count = $results.Count
    $detail = if ($count -eq 0) {
        "0 Error findings on $($files.Count) product scripts (PSScriptAnalyzer $($mod.Version); sample-test excluded)"
    } else {
        $rules = ($results | Select-Object -ExpandProperty RuleName -Unique | Select-Object -First 8) -join ','
        "$count Error finding(s) on $($files.Count) product scripts; rules=$rules"
    }
    return @{
        Passed   = ($count -eq 0)
        Detail   = $detail
        ExitCode = $(if ($count -eq 0) { 0 } else { 1 })
    }
}

function Find-Gitleaks {
    $cmd = Get-Command gitleaks -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $wingetRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    if (Test-Path -LiteralPath $wingetRoot) {
        $hit = Get-ChildItem -Path $wingetRoot -Recurse -Filter gitleaks.exe -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

function Get-GitleaksFindingCount {
    param([string]$ReportPath)
    $findingCount = 0
    if (Test-Path -LiteralPath $ReportPath) {
        try {
            $raw = Get-Content -LiteralPath $ReportPath -Raw -ErrorAction SilentlyContinue
            if ($raw -and $raw.Trim().StartsWith('[')) {
                $arr = $raw | ConvertFrom-Json
                if ($arr) { $findingCount = @($arr).Count }
            }
        } catch {
            # leave findingCount 0; rely on exit code
        }
    }
    return $findingCount
}

function Invoke-GitleaksCheck {
    param(
        [string]$Root,
        [string]$LogsDir,
        [object]$Check
    )
    $exe = Find-Gitleaks
    if (-not $exe) {
        return @{ Passed = $false; Detail = 'gitleaks not found on PATH or WinGet packages'; ExitCode = 1; Version = 'missing' }
    }

    $modes = @('workdir', 'git')
    if ($Check.PSObject.Properties.Name -contains 'Modes' -and $Check.Modes) {
        $modes = @($Check.Modes | ForEach-Object { [string]$_ })
    }

    $prefix = 'gitleaks'
    if ($Check.PSObject.Properties.Name -contains 'ReportFileNamePrefix' -and $Check.ReportFileNamePrefix) {
        $prefix = [string]$Check.ReportFileNamePrefix
    }

    if (-not (Test-Path -LiteralPath $LogsDir)) {
        New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
    }

    $ver = & $exe version 2>&1 | Out-String
    $verLine = ($ver -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 1)
    if (-not $verLine) { $verLine = 'unknown' }

    $modeParts = @()
    $allPassed = $true
    $worstCode = 0

    foreach ($mode in $modes) {
        $modeKey = $mode.ToLowerInvariant()
        $reportName = "$prefix-$modeKey.json"
        $reportPath = Join-Path $LogsDir $reportName
        $args = @(
            'detect',
            '--source', $Root,
            '--report-path', $reportPath,
            '--report-format', 'json',
            '--exit-code', '1'
        )
        if ($modeKey -eq 'workdir' -or $modeKey -eq 'no-git' -or $modeKey -eq 'tree') {
            $args += '--no-git'
            $modeLabel = 'workdir'
        } elseif ($modeKey -eq 'git' -or $modeKey -eq 'history') {
            $modeLabel = 'git'
        } else {
            $allPassed = $false
            $modeParts += ("unknown_mode=$mode")
            $worstCode = 1
            continue
        }

        $null = & $exe @args 2>&1 | Out-String
        $code = $LASTEXITCODE
        if ($null -eq $code) { $code = 0 }
        $findings = Get-GitleaksFindingCount -ReportPath $reportPath
        $modeOk = ($code -eq 0)
        if (-not $modeOk) {
            $allPassed = $false
            if ([int]$code -gt $worstCode) { $worstCode = [int]$code }
            $modeParts += ("${modeLabel}=fail(exit=$code;findings=$findings)")
        } else {
            $modeParts += ("${modeLabel}=pass")
        }
    }

    $detail = if ($allPassed) {
        "$(($modeParts) -join '; '); no leaks (gitleaks $verLine)"
    } else {
        "$(($modeParts) -join '; '); see certification/logs/${prefix}-*.json (no secret values in cert)"
    }

    return @{
        Passed   = $allPassed
        Detail   = $detail
        ExitCode = $(if ($allPassed) { 0 } else { $(if ($worstCode -eq 0) { 1 } else { $worstCode }) })
        Version  = $verLine.Trim()
    }
}

function Test-PylintScoreMeetsRequirement {
    param(
        [string]$ActualScoreText,
        [string]$RequiredScoreText
    )
    if ([string]::IsNullOrWhiteSpace($ActualScoreText) -or [string]::IsNullOrWhiteSpace($RequiredScoreText)) {
        return $false
    }
    try {
        $actual = [double]::Parse($ActualScoreText, [System.Globalization.CultureInfo]::InvariantCulture)
        $required = [double]::Parse($RequiredScoreText, [System.Globalization.CultureInfo]::InvariantCulture)
        # Accept exact 10.00 style scores within a tiny float epsilon
        return ($actual + 1e-9) -ge $required
    } catch {
        return $false
    }
}

function Invoke-ProcessCheck {
    param(
        [string]$Root,
        [object]$Check
    )
    $wdRel = [string]$Check.WorkingDirectory
    if (-not $wdRel) { $wdRel = '.' }
    $wd = if ($wdRel -eq '.' -or $wdRel -eq '') { $Root } else { Join-Path $Root $wdRel }
    if (-not (Test-Path -LiteralPath $wd)) {
        return @{ Passed = $false; Detail = "WorkingDirectory missing: $wdRel"; ExitCode = 1 }
    }

    $exeName = [string]$Check.Executable
    $exePath = $null
    if ([System.IO.Path]::IsPathRooted($exeName)) {
        $exePath = $exeName
    } else {
        $local = Join-Path $wd $exeName
        if (Test-Path -LiteralPath $local) {
            $exePath = $local
        } else {
            $cmd = Get-Command $exeName -ErrorAction SilentlyContinue
            if ($cmd) { $exePath = $cmd.Source }
        }
    }
    if (-not $exePath) {
        return @{ Passed = $false; Detail = "Executable not found: $exeName"; ExitCode = 1 }
    }

    $argList = @()
    if ($Check.PSObject.Properties.Name -contains 'Arguments' -and $Check.Arguments) {
        $argList = @($Check.Arguments)
    }

    $successCodes = @(0)
    if ($Check.PSObject.Properties.Name -contains 'SuccessExitCodes' -and $Check.SuccessExitCodes) {
        $successCodes = @($Check.SuccessExitCodes | ForEach-Object { [int]$_ })
    }

    Push-Location $wd
    try {
        $output = & $exePath @argList 2>&1 | Out-String
        $code = $LASTEXITCODE
        if ($null -eq $code) { $code = 0 }
    } finally {
        Pop-Location
    }

    $passed = $successCodes -contains [int]$code
    $summary = ($output -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -Last 3) -join ' | '
    if ($summary.Length -gt 240) { $summary = $summary.Substring(0, 237) + '...' }
    $detail = "exit $code"
    if ($summary) { $detail = "$detail; $summary" }

    # Declarative pylint score gate (checks.json RequirePylintScore)
    $requireScore = $null
    if ($Check.PSObject.Properties.Name -contains 'RequirePylintScore' -and $Check.RequirePylintScore) {
        $requireScore = [string]$Check.RequirePylintScore
    }
    if ($requireScore) {
        if ($output -match 'rated at ([\d\.]+)/10') {
            $score = $Matches[1]
            $detail = "exit $code; score $score/10"
            if (-not (Test-PylintScoreMeetsRequirement -ActualScoreText $score -RequiredScoreText $requireScore)) {
                $passed = $false
                $detail += " (require $requireScore/10)"
            }
        } else {
            $passed = $false
            $detail = "exit $code; pylint score not found in output (require $requireScore/10)"
        }
    }

    return @{
        Passed   = [bool]$passed
        Detail   = $detail
        ExitCode = [int]$code
    }
}

function New-CheckResult {
    param(
        [object]$Check,
        [bool]$Passed,
        [string]$Detail,
        [int]$ExitCode,
        [int]$DurationMs
    )
    return [ordered]@{
        Name       = [string]$Check.Name
        Id         = [string]$Check.Id
        Domain     = [string]$Check.Domain
        Surface    = [string]$Check.Surface
        Passed     = $Passed
        Severity   = [string]$Check.Severity
        Required   = [bool]$Check.Required
        Detail     = $Detail
        ExitCode   = $ExitCode
        DurationMs = $DurationMs
    }
}

# --- main ---
$repoRoot = Get-RepoRoot -Hint $RepoRoot
$certDir = Join-Path $repoRoot 'certification'
$checksPath = Join-Path $certDir 'checks.json'
$logsDir = Join-Path $certDir 'logs'
$jsonOut = Join-Path $certDir 'last_certification.json'
$txtOut = Join-Path $certDir 'last_certification.txt'

if (-not (Test-Path -LiteralPath $checksPath)) {
    Write-Error "Missing checks.json at $checksPath"
    exit 2
}

$manifest = Get-Content -LiteralPath $checksPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $manifest.LanguageSurfaces -or @($manifest.LanguageSurfaces).Count -eq 0) {
    Write-Error "checks.json LanguageSurfaces is empty; declare inventory surfaces."
    exit 2
}
if (-not $manifest.Checks -or @($manifest.Checks).Count -eq 0) {
    Write-Error "checks.json Checks is empty."
    exit 2
}

$started = (Get-Date).ToUniversalTime().ToString('o')
$git = Get-GitMeta -Root $repoRoot
$packageVersions = Get-PackageVersions -Root $repoRoot

$toolVersions = [ordered]@{
    python            = (Get-ToolVersion 'python' { py -3.13 --version })
    pylint            = (Get-ToolVersion 'pylint' { py -3.13 -m pylint --version })
    bandit            = (Get-ToolVersion 'bandit' { py -3.13 -m bandit --version })
    PSScriptAnalyzer  = (Get-ToolVersion 'PSScriptAnalyzer' {
            $m = Get-Module -ListAvailable PSScriptAnalyzer | Select-Object -First 1
            if ($m) { "PSScriptAnalyzer $($m.Version)" } else { 'missing' }
        })
    gitleaks          = 'unknown'
    powershell        = $PSVersionTable.PSVersion.ToString()
}

$checkResults = @()
foreach ($check in @($manifest.Checks)) {
    Write-Host ("[cert] Running {0} ({1}/{2})..." -f $check.Id, $check.Domain, $check.Surface)
    $kind = [string]$check.Kind
    $result = $null
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    switch ($kind) {
        'process' {
            $result = Invoke-ProcessCheck -Root $repoRoot -Check $check
        }
        'ps-parse-bom' {
            $result = Invoke-PsParseBomCheck -Root $repoRoot -Check $check
        }
        'pssa' {
            $result = Invoke-PssaCheck -Root $repoRoot -Check $check
        }
        'gitleaks' {
            $result = Invoke-GitleaksCheck -Root $repoRoot -LogsDir $logsDir -Check $check
            if ($result.ContainsKey('Version')) { $toolVersions.gitleaks = $result.Version }
        }
        default {
            $result = @{ Passed = $false; Detail = "Unknown Kind: $kind"; ExitCode = 1 }
        }
    }
    $sw.Stop()
    $durationMs = [int]$sw.ElapsedMilliseconds
    $entry = New-CheckResult -Check $check -Passed ([bool]$result.Passed) -Detail ([string]$result.Detail) -ExitCode ([int]$result.ExitCode) -DurationMs $durationMs
    $checkResults += $entry
    $status = if ($entry.Passed) { 'PASS' } else { 'FAIL' }
    Write-Host ("[cert] {0}: {1} — {2} ({3} ms)" -f $status, $entry.Name, $entry.Detail, $durationMs)
}

$secFailed = @($checkResults | Where-Object { $_.Domain -eq 'Security' -and $_.Required -and -not $_.Passed } | ForEach-Object { $_.Name })
$codeFailed = @($checkResults | Where-Object { $_.Domain -eq 'CodeValidation' -and $_.Required -and -not $_.Passed } | ForEach-Object { $_.Name })
$secPass = ($secFailed.Count -eq 0)
$codePass = ($codeFailed.Count -eq 0)
$overall = $secPass -and $codePass

$requiredTotal = @($checkResults | Where-Object { $_.Required }).Count
$requiredPassed = @($checkResults | Where-Object { $_.Required -and $_.Passed }).Count
$allFailedNames = @($checkResults | Where-Object { $_.Required -and -not $_.Passed } | ForEach-Object { $_.Name })
if ($overall) {
    $message = "OverallPass=true; $requiredPassed/$requiredTotal required checks passed"
} else {
    $failList = if ($allFailedNames.Count) { ($allFailedNames -join ', ') } else { '(none listed)' }
    $message = "OverallPass=false; $requiredPassed/$requiredTotal required checks passed; failed: $failList"
}

$finished = (Get-Date).ToUniversalTime().ToString('o')
$surfaces = @($manifest.LanguageSurfaces)

$passCriteria = [ordered]@{}
foreach ($c in @($manifest.Checks)) {
    $passCriteria[[string]$c.Id] = [string]$c.PassCriteria
}

$disclaimer = 'Self-attestation of automated checks only. Not a third-party audit. Not package diagnostics. No claim rows, passwords, or secret values in this certificate.'

$certificate = [ordered]@{
    CertificateType   = 'SecurityAndCodeValidationCertification'
    SchemaVersion     = '1.0'
    OverallPass       = $overall
    Message           = $message
    GeneratedAt       = $finished
    StartedAt         = $started
    FinishedAt        = $finished
    RepoRoot          = $repoRoot
    GitCommit         = $git.GitCommit
    GitBranch         = $git.GitBranch
    GitDirty          = [bool]$git.GitDirty
    LanguageSurfaces  = $surfaces
    PackageVersions   = $packageVersions
    ToolVersions      = $toolVersions
    PassCriteria      = $passCriteria
    Domains           = [ordered]@{
        Security = [ordered]@{
            OverallPass    = $secPass
            CriticalFailed = @($secFailed)
        }
        CodeValidation = [ordered]@{
            OverallPass    = $codePass
            CriticalFailed = @($codeFailed)
        }
    }
    Checks            = @($checkResults)
    Disclaimer        = $disclaimer
}

if (-not $SkipWrite) {
    if (-not (Test-Path -LiteralPath $certDir)) {
        New-Item -ItemType Directory -Path $certDir -Force | Out-Null
    }
    $jsonText = $certificate | ConvertTo-Json -Depth 8
    [System.IO.File]::WriteAllText($jsonOut, $jsonText, [System.Text.UTF8Encoding]::new($false))

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('Security and Code-Validation Certification')
    [void]$sb.AppendLine('==========================================')
    [void]$sb.AppendLine("CertificateType: $($certificate.CertificateType)")
    [void]$sb.AppendLine("SchemaVersion:   $($certificate.SchemaVersion)")
    [void]$sb.AppendLine("OverallPass:     $($certificate.OverallPass)")
    [void]$sb.AppendLine("Message:         $($certificate.Message)")
    [void]$sb.AppendLine("GeneratedAt:     $($certificate.GeneratedAt)")
    [void]$sb.AppendLine("RepoRoot:        $($certificate.RepoRoot)")
    [void]$sb.AppendLine("GitCommit:       $($certificate.GitCommit)")
    [void]$sb.AppendLine("GitBranch:       $($certificate.GitBranch)")
    [void]$sb.AppendLine("GitDirty:        $($certificate.GitDirty)")
    [void]$sb.AppendLine("LanguageSurfaces: $($surfaces -join ', ')")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('PackageVersions')
    [void]$sb.AppendLine('---------------')
    foreach ($k in $packageVersions.Keys) {
        [void]$sb.AppendLine("$k = $($packageVersions[$k])")
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Domains')
    [void]$sb.AppendLine('-------')
    [void]$sb.AppendLine("Security.OverallPass:        $secPass")
    [void]$sb.AppendLine("Security.CriticalFailed:     $(if ($secFailed.Count) { $secFailed -join ', ' } else { '(none)' })")
    [void]$sb.AppendLine("CodeValidation.OverallPass:  $codePass")
    [void]$sb.AppendLine("CodeValidation.CriticalFailed: $(if ($codeFailed.Count) { $codeFailed -join ', ' } else { '(none)' })")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('ToolVersions')
    [void]$sb.AppendLine('------------')
    foreach ($k in $toolVersions.Keys) {
        [void]$sb.AppendLine("$k = $($toolVersions[$k])")
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Checks')
    [void]$sb.AppendLine('------')
    foreach ($c in $checkResults) {
        $mark = if ($c.Passed) { 'PASS' } else { 'FAIL' }
        [void]$sb.AppendLine("[$mark] $($c.Name) | Domain=$($c.Domain) Surface=$($c.Surface) Severity=$($c.Severity) DurationMs=$($c.DurationMs)")
        [void]$sb.AppendLine("       $($c.Detail)")
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Disclaimer')
    [void]$sb.AppendLine('----------')
    [void]$sb.AppendLine($disclaimer)
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('IT one-liner: Automated security static analysis and code validation for declared language surfaces produced a ' + $(if ($overall) { 'PASS' } else { 'FAIL' }) + " certificate for commit $($certificate.GitCommit) at $($certificate.GeneratedAt). Self-attestation only; not a third-party audit.")

    [System.IO.File]::WriteAllText($txtOut, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))
    Write-Host ""
    Write-Host "Wrote: $jsonOut"
    Write-Host "Wrote: $txtOut"
}

Write-Host ""
Write-Host ("OverallPass = {0}" -f $overall)
Write-Host $message
if ($overall) { exit 0 } else { exit 1 }
