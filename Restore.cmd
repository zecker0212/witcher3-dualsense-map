@echo off
cd /d "%~dp0"
if exist "%~dp0installation.json" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup.ps1" -Action Uninstall
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0RestoreOriginal.ps1"
)
echo.
pause
