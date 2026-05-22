# uninstall-core.ps1
# 卸载所有改动,逆序回滚

Add-Type -AssemblyName System.Windows.Forms

$confirm = [System.Windows.Forms.MessageBox]::Show(
    "确认卸载 Office Copilot Lite 吗?`n`n会清理:`n- 登录启动任务`n- Excel 信任目录注册表`n- Wef 网络共享`n- 安装目录文件",
    "Office Copilot Lite - 卸载",
    "YesNo", "Warning")
if ($confirm -ne "Yes") {
    Write-Host "[uninstall] 用户取消"
    exit 0
}

# 读 config 拿 cert thumbprint(可选)
$configPath = Join-Path $env:LOCALAPPDATA "OfficeCopilotLite\config.json"
$certThumbprint = $null
if (Test-Path $configPath) {
    try {
        $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
        $certThumbprint = $cfg.cert_thumbprint
    } catch {}
}

# 检测路径
$installDir = Join-Path $env:LOCALAPPDATA "OfficeCopilotLite"

Write-Host "[uninstall] 1/7 停止并删除登录启动任务"
& cmd /c 'schtasks /End /TN "OfficeCopilotLite\Helper" >nul 2>nul'
& cmd /c 'schtasks /End /TN "OfficeCopilotLite\Bridge" >nul 2>nul'
Start-Sleep -Seconds 1
& cmd /c 'schtasks /Delete /TN "OfficeCopilotLite\Helper" /F >nul 2>nul'
& cmd /c 'schtasks /Delete /TN "OfficeCopilotLite\Bridge" /F >nul 2>nul'

Write-Host "[uninstall] 2/7 杀进程"
Stop-Process -Name helper -Force -ErrorAction SilentlyContinue
Stop-Process -Name bridge -Force -ErrorAction SilentlyContinue
Stop-Process -Name office-helper -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Host "[uninstall] 3/7 清理 Excel 信任目录注册表"
$guid = "{4e2fd29d-dad0-40b3-af3c-a16e347a5ddc}"
$catalogPath = "HKCU:\Software\Microsoft\Office\16.0\WEF\TrustedCatalogs\$guid"
if (Test-Path $catalogPath) {
    Remove-Item -Path $catalogPath -Recurse -Force
    Write-Host "  已删: $catalogPath"
}

Write-Host "[uninstall] 4/7 删除 Wef 网络共享"
$cleanUser = $env:USERNAME -replace '[^a-zA-Z0-9]', ''
$shareName = "OCLWef$cleanUser"
& cmd /c "net share $shareName /delete /y" 2>$null

Write-Host "[uninstall] 5/7 运行 helper.exe uninstall(如可用)"
$helperExe = Join-Path $installDir "helper.exe"
if (Test-Path $helperExe) {
    & $helperExe uninstall 2>$null
}

Write-Host "[uninstall] 6/7 (可选)删除自签证书"
if ($certThumbprint) {
    $confirmCert = [System.Windows.Forms.MessageBox]::Show(
        "是否同时删除自签证书?`n`n证书是 helper 安装时为 https://localhost 生成的,作用域只在当前用户。`n卸载场景下建议删除。",
        "Office Copilot Lite - 删除证书",
        "YesNo", "Question")
    if ($confirmCert -eq "Yes") {
        Get-ChildItem Cert:\CurrentUser\Root | Where-Object Thumbprint -eq $certThumbprint |
            Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "  证书 $certThumbprint 已删"
    }
}

Write-Host "[uninstall] 7/7 删除安装目录"
if (Test-Path $installDir) {
    Remove-Item -Path $installDir -Recurse -Force
}

# 顺手删桌面 3 个快捷方式
$desktop = [Environment]::GetFolderPath("Desktop")
@(
    "修改网关地址(Office Copilot Lite).lnk",
    "重启服务(Office Copilot Lite).lnk",
    "卸载 Office Copilot Lite.lnk"
) | ForEach-Object {
    $lnk = Join-Path $desktop $_
    if (Test-Path $lnk) { Remove-Item $lnk -Force -ErrorAction SilentlyContinue }
}

[System.Windows.Forms.MessageBox]::Show(
    "✅ Office Copilot Lite 已卸载。`n`n如果 Excel 信任中心还显示加载项条目(GPO 锁定环境),请联系 IT 手动删除。",
    "Office Copilot Lite", "OK", "Information") | Out-Null
