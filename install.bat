@echo off
chcp 65001 >nul 2>&1
title Office Copilot Lite Installer

REM ---- UAC self-elevate (loud version) ----
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo Office Copilot Lite needs administrator privileges.
    echo Click "Yes" on the upcoming UAC prompt.
    echo If no prompt appears in 10 seconds, close this and retry.
    echo.
    timeout /t 2 /nobreak >nul
    powershell -NoProfile -Command "try { Start-Process -FilePath '%~f0' -Verb RunAs -Wait -ErrorAction Stop } catch { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('UAC was denied or failed. Please retry and click YES on the UAC prompt.','Office Copilot Lite','OK','Warning') | Out-Null }"
    exit /b
)

REM ---- Already admin ----
cd /d "%~dp0"
echo Running installer...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install-core.ps1"

echo.
echo ------------------------------------------
echo Done. Press any key to close this window.
pause >nul
