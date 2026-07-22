@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Test-Psm1.ps1"
echo Exit=%ERRORLEVEL%
pause
