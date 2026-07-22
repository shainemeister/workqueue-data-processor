@echo off
REM KPI Analytics CLI shim — process-local only; does not change machine policy.
REM Usage: kpi-analytics.cmd <command> [options]
setlocal
set "SCRIPT_DIR=%~dp0"
pushd "%SCRIPT_DIR%" >nul

where py >nul 2>&1
if %ERRORLEVEL%==0 (
  py -3.13 -m kpi_modules %*
  set "EC=%ERRORLEVEL%"
  popd >nul
  exit /b %EC%
)

where python >nul 2>&1
if %ERRORLEVEL%==0 (
  python -m kpi_modules %*
  set "EC=%ERRORLEVEL%"
  popd >nul
  exit /b %EC%
)

echo [kpi-analytics] Python 3.13 not found on PATH (tried py -3.13 and python). 1>&2
popd >nul
exit /b 1
