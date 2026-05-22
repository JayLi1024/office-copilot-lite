@echo off
chcp 65001 >nul 2>&1
title Office Copilot Lite - Restart Service

echo Restarting helper...

schtasks /End /TN "OfficeCopilotLite\Helper" >nul 2>&1
timeout /t 2 /nobreak >nul
schtasks /Run /TN "OfficeCopilotLite\Helper" >nul 2>&1
timeout /t 3 /nobreak >nul

powershell -NoProfile -Command ^
    "$conn = Test-NetConnection -ComputerName 127.0.0.1 -Port 18765 -InformationLevel Quiet -WarningAction SilentlyContinue; Add-Type -AssemblyName System.Windows.Forms; if ($conn) { [System.Windows.Forms.MessageBox]::Show('Helper service restarted. Open Excel and try again.','Office Copilot Lite','OK','Information') | Out-Null } else { [System.Windows.Forms.MessageBox]::Show('Helper did not start. Try rebooting or re-run install.bat','Office Copilot Lite','OK','Warning') | Out-Null }"
