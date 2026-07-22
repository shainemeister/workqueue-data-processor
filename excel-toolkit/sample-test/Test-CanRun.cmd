@echo off
cd /d "%~dp0"
echo --- ps1 ---
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-CanRun.ps1"
if errorlevel 1 goto fail
echo --- psm1 ---
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-Psm1.ps1"
if errorlevel 1 goto fail
echo OK: cmd + ps1 + psm1
goto end
:fail
echo FAIL
:end
pause
