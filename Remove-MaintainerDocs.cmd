@echo off
REM Remove maintainer-only docs from this working copy. Does not rewrite git.
REM Restore: git checkout -- .
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Remove-MaintainerDocs.ps1" %*
