$m = Join-Path $PSScriptRoot 'SampleTools.psm1'
Import-Module $m -Force
if ((Get-SampleModulePing) -eq 'PING_OK') {
  Write-Host 'OK: psm1 works'
  exit 0
}
Write-Host 'FAIL: psm1'
exit 1
