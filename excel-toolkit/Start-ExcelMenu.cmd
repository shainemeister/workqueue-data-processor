@echo off
REM Excel Data Tools - double-click launcher
REM Process-scoped Bypass only (does not change machine policy permanently).
REM Single entry point for policy flags; keep this minimal for enterprise review.
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-ExcelMenu.ps1"
set ERR=%ERRORLEVEL%
if not "%ERR%"=="0" (
  echo.
  echo The menu exited with code %ERR%.
  pause
)
endlocal & exit /b %ERR%
