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
