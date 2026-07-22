# sample-minimal (short)

All files go in **one folder**. Names must match exactly.

## 1) Can .psm1 run?

### SampleTools.psm1
```
function Get-SampleModulePing { 'PING_OK' }
Export-ModuleMember -Function Get-SampleModulePing
```

### Test-Psm1.ps1
```
$m = Join-Path $PSScriptRoot 'SampleTools.psm1'
Import-Module $m -Force
if ((Get-SampleModulePing) -eq 'PING_OK') {
  Write-Host 'OK: psm1 works'
  exit 0
}
Write-Host 'FAIL: psm1'
exit 1
```

### Test-Psm1.cmd
```
@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-Psm1.ps1"
echo Exit=%ERRORLEVEL%
pause
```

Double-click `Test-Psm1.cmd` → expect `OK: psm1 works`.

## 2) Enterprise checks (short)

Double-click **`Test-Env.cmd`** (needs `SampleTools.psm1` next to it).

### Test-Env.ps1 (hand-type)
```
# Easy enterprise checks. Look for FAIL lines.
$fail = 0

$lm = $ExecutionContext.SessionState.LanguageMode
if ($lm -eq 'FullLanguage') { 'PASS LanguageMode' } else { 'FAIL LanguageMode'; $fail++ }

$ep = Get-ExecutionPolicy -Scope Process
if ($ep -eq 'Bypass') { 'PASS ExecPolicy' } else { "FAIL ExecPolicy $ep"; $fail++ }

try {
  Import-Module "$PSScriptRoot\SampleTools.psm1" -Force
  if ((Get-SampleModulePing) -eq 'PING_OK') { 'PASS Module' } else { 'FAIL Module'; $fail++ }
} catch { 'FAIL Module'; $fail++ }

try {
  $x = New-Object -ComObject Excel.Application
  $x.Quit()
  'PASS ExcelCOM'
} catch { 'FAIL ExcelCOM'; $fail++ }

try {
  $t = "$env:TEMP\t.txt"
  'ok' | Set-Content $t
  if (Test-Path $t) { 'PASS TempWrite'; Remove-Item $t -Force } else { 'FAIL TempWrite'; $fail++ }
} catch { 'FAIL TempWrite'; $fail++ }

if ($fail -eq 0) { 'OK'; exit 0 }
"FAIL count=$fail"; exit 1
```

| Line | Meaning |
|------|---------|
| PASS LanguageMode | Not ConstrainedLanguage |
| PASS ExecPolicy | Process Bypass (from .cmd) |
| PASS Module | .psm1 import works |
| PASS ExcelCOM | Excel automation works |
| PASS TempWrite | Can write temp files |
| OK | All good |

## Files

| File | Purpose |
|------|---------|
| `SampleTools.psm1` | Tiny module |
| `Test-Psm1.cmd` / `.ps1` | Module load test |
| `Test-Env.cmd` / `.ps1` | Enterprise probes |
| `Test-CanRun.cmd` / `.ps1` | Optional: ps1 + psm1 only |

## After probes pass

Use the full toolkit under **`excel-toolkit\`** only:

| Next step | Command / path |
|-----------|----------------|
| Interactive menu | `excel-toolkit\Start-ExcelMenu.cmd` |
| CLI preflight | `excel-toolkit\excel-toolkit.cmd probe` |
| CLI guide | `excel-toolkit\CLI-GUIDE.md` |
| Enterprise notes | `excel-toolkit\ENTERPRISE-SECURITY.md` |
