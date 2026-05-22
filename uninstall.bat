@echo off
chcp 65001 >nul 2>&1
title Office Copilot Lite Uninstaller

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs -Wait"
    exit /b
)

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\uninstall-core.ps1"

echo.
echo ------------------------------------------
echo Press any key to close this window.
pause >nul
