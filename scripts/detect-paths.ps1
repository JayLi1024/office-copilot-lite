# detect-paths.ps1
# 自动检测所有路径,设置 OCL_* 环境变量供后续脚本用
# 老师 0 输入,这一步完全静默

# 安装目录
$env:OCL_INSTALL_DIR = Join-Path $env:LOCALAPPDATA "OfficeCopilotLite"

# Office Wef 目录(加载项 manifest 部署位置)
$env:OCL_WEF_DIR = Join-Path $env:LOCALAPPDATA "Microsoft\Office\16.0\Wef"

# 计算机名 + 用户名(用于 schtasks / UNC 路径)
$env:OCL_COMPUTER = $env:COMPUTERNAME
$env:OCL_USERNAME = $env:USERNAME

# 共享名(加用户名前缀避免冲突,符合 net share 命名规则:不能含空格)
$cleanUser = $env:OCL_USERNAME -replace '[^a-zA-Z0-9]', ''
$env:OCL_SHARE_NAME = "OCLWef$cleanUser"

# Office 版本(可选,用于环境检查)
try {
    $env:OCL_OFFICE_VER = (Get-ItemProperty `
        "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" `
        -ErrorAction Stop).VersionToReport
} catch {
    $env:OCL_OFFICE_VER = "unknown"
}

# manifest 固定 GUID(与原版 Anthropic 加载项一致,改字段不改 GUID 保证升级兼容)
$env:OCL_GUID = "4e2fd29d-dad0-40b3-af3c-a16e347a5ddc"

# 端口(冲突时自动顺延,bridge 还要避开 helper 已选的端口)
$env:OCL_HELPER_PORT = 18765
$env:OCL_BRIDGE_PORT = 18766

function Test-PortInUse($port) {
    $null -ne (Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)
}

# helper 端口顺延
for ($i = 0; $i -lt 10; $i++) {
    if (-not (Test-PortInUse $env:OCL_HELPER_PORT)) { break }
    $env:OCL_HELPER_PORT = [int]$env:OCL_HELPER_PORT + 1
}

# bridge 端口顺延,且避开 helper 已选的端口
for ($i = 0; $i -lt 10; $i++) {
    if ([int]$env:OCL_BRIDGE_PORT -eq [int]$env:OCL_HELPER_PORT) {
        $env:OCL_BRIDGE_PORT = [int]$env:OCL_BRIDGE_PORT + 1
        continue
    }
    if (-not (Test-PortInUse $env:OCL_BRIDGE_PORT)) { break }
    $env:OCL_BRIDGE_PORT = [int]$env:OCL_BRIDGE_PORT + 1
}

Write-Host "[detect-paths] 路径检测完成:"
Write-Host "  安装目录:    $env:OCL_INSTALL_DIR"
Write-Host "  Wef 目录:    $env:OCL_WEF_DIR"
Write-Host "  计算机名:    $env:OCL_COMPUTER"
Write-Host "  用户名:      $env:OCL_USERNAME"
Write-Host "  共享名:      $env:OCL_SHARE_NAME"
Write-Host "  Office 版本: $env:OCL_OFFICE_VER"
Write-Host "  helper 端口: $env:OCL_HELPER_PORT"
Write-Host "  bridge 端口: $env:OCL_BRIDGE_PORT"
