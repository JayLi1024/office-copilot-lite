# register-tasks.ps1
# 注册一个登录启动任务:helper,wscript 静默跑 vbs,zero 窗口

$installDir = $env:OCL_INSTALL_DIR
$helperVbs = Join-Path $installDir "run-helper.vbs"

if (-not (Test-Path $helperVbs)) {
    Write-Error "[register-tasks] run-helper.vbs 不存在: $helperVbs"
    exit 1
}

# 先清旧任务(任何 OfficeCopilotLite\* 任务都清,兼容老版本)
& cmd /c 'schtasks /Delete /TN "OfficeCopilotLite\Helper" /F >nul 2>nul'
& cmd /c 'schtasks /Delete /TN "OfficeCopilotLite\Bridge" /F >nul 2>nul'

# 注册 Helper
$ohAction = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$helperVbs`""
$ohTrigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$ohSettings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Days 365) `
    -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "OfficeCopilotLite\Helper" `
    -Action $ohAction -Trigger $ohTrigger -Settings $ohSettings `
    -Description "Office Copilot Lite Helper 服务(登录时自动静默启动)" `
    -Force | Out-Null

# 立即拉起(免重启)
Start-ScheduledTask -TaskName "OfficeCopilotLite\Helper"

Write-Host "[register-tasks] 已注册并启动:OfficeCopilotLite\Helper -> $helperVbs"
