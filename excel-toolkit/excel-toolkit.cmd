@echo off
REM Excel Toolkit CLI shim (process-scoped Bypass only; does not change machine policy).
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0ExcelToolkit.ps1" %*
exit /b %ERRORLEVEL%
