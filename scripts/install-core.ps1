# install-core.ps1
# Office Copilot Lite 主安装流程
# 老师双击 install.bat 后,这个脚本接管做所有事
# 全程零路径输入,只问 LLM 网关 URL + API Key 两个字段

$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
$rootDir = Split-Path $scriptDir -Parent  # zip 解压目录

# 开始 transcript 落日志
$logPath = Join-Path $env:LOCALAPPDATA "OfficeCopilotLite\install.log"
$null = New-Item -ItemType Directory -Force -Path (Split-Path $logPath -Parent)
Start-Transcript -Path $logPath -Force | Out-Null

try {
    Add-Type -AssemblyName Microsoft.VisualBasic
    Add-Type -AssemblyName System.Windows.Forms

    Write-Host "════════════════════════════════════════════════════"
    Write-Host "  Office Copilot Lite 安装程序"
    Write-Host "  日志:$logPath"
    Write-Host "════════════════════════════════════════════════════"

    # ─── Step 0: 路径自动检测 ───
    # ─── Step 0: 路径自动检测 ───
    Write-Host "`n[0/8] 自动检测路径..."
    & (Join-Path $scriptDir "detect-paths.ps1")
    $installDir = $env:OCL_INSTALL_DIR

    # ─── Step 1: 环境检查 ───
    Write-Host "`n[1/8] 环境检查"
    $osBuild = [Environment]::OSVersion.Version.Build
    if ($osBuild -lt 19041) {
        throw "Windows 版本太老(build $osBuild),需要 Win10 20H1+ 或 Win11"
    }
    if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\Office\16.0")) {
        throw "未检测到 Office 16(M365/LTSC2024/LTSC2021),无法安装。请先装 Office。"
    }
    Write-Host "  ✓ Win10/11 build $osBuild"
    Write-Host "  ✓ Office 16 已装"

    # ─── Step 2: copy helper.exe 到本地 ───
    Write-Host "`n[2/8] 部署 helper.exe"
    $helperSrc = Join-Path $rootDir "bin\helper.exe"
    $helperDst = Join-Path $installDir "helper.exe"
    if (-not (Test-Path $helperSrc)) {
        throw "找不到 bin\helper.exe,发布包不完整"
    }
    $null = New-Item -ItemType Directory -Force -Path $installDir

    # 如果 helper 正在跑(reinstall 场景),先停了避免文件锁
    & cmd /c 'schtasks /End /TN "OfficeCopilotLite\Helper" >nul 2>nul'
    Stop-Process -Name helper -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1

    Copy-Item -Path $helperSrc -Destination $helperDst -Force
    Write-Host "  ✓ $helperDst"

    # ─── Step 3: helper.exe install(部署 manifest + 装证书) ───
    Write-Host "`n[3/8] 运行 helper.exe install(部署 manifest + 装证书)"
    Push-Location $installDir
    try {
        & .\helper.exe install
        if ($LASTEXITCODE -ne 0) {
            throw "helper.exe install 失败,exit code $LASTEXITCODE"
        }
    } finally {
        Pop-Location
    }
    Write-Host "  ✓ install 成功"

    # 抓取刚装的证书 thumbprint(供 uninstall 用)
    $certThumbprint = ""
    try {
        $cert = Get-ChildItem Cert:\CurrentUser\Root |
            Where-Object Subject -like "*rcgen*" |
            Sort-Object NotBefore -Descending |
            Select-Object -First 1
        if ($cert) {
            $certThumbprint = $cert.Thumbprint
            Write-Host "  ✓ 证书 thumbprint: $certThumbprint"
        }
    } catch {}

    # ─── Step 4: rebrand manifest ───
    Write-Host "`n[4/8] 改 manifest 为 Office Copilot Lite 品牌"
    & (Join-Path $scriptDir "rebrand-manifest.ps1")

    # ─── Step 5: 共享 Wef 目录 ───
    Write-Host "`n[5/8] 共享 Wef 网络目录"
    & (Join-Path $scriptDir "share-wef.ps1")

    # ─── Step 6: 写信任目录注册表 ───
    Write-Host "`n[6/8] 写 Excel 信任目录注册表"
    & (Join-Path $scriptDir "trust-wef.ps1")

    # ─── Step 7: 注册登录启动任务(只 Helper) ───
    Write-Host "`n[7/8] 注册登录启动任务(helper 静默自启)"

    # 动态生成 vbs(只 helper)
    $helperVbs = @"
' Office Copilot Lite - helper 静默启动器
Set sh = CreateObject("WScript.Shell")
sh.CurrentDirectory = "$installDir"
sh.Run """$installDir\helper.exe""", 0, False
"@
    Set-Content -Path (Join-Path $installDir "run-helper.vbs") -Value $helperVbs -Encoding ASCII

    & (Join-Path $scriptDir "register-tasks.ps1")

    # ─── Step 8: helper 健康检查 + 桌面快捷方式 + 完成提示 ───
    Write-Host "`n[8/8] 健康检查 + 桌面快捷方式 + 完成"

    # 检查 helper 18765
    $healthOk = $false
    for ($i = 1; $i -le 8; $i++) {
        Start-Sleep -Seconds 1
        try {
            $conn = Test-NetConnection -ComputerName 127.0.0.1 -Port 18765 -InformationLevel Quiet -WarningAction SilentlyContinue
            if ($conn) { $healthOk = $true; Write-Host "  ✓ helper 监听 18765(尝试 $i 次)"; break }
        } catch {}
    }
    if (-not $healthOk) {
        Write-Warning "  helper 探活超时,可能没起来。请查看 $logPath"
    }

    # 桌面快捷方式(只留卸载和重启)
    $shell = New-Object -ComObject WScript.Shell
    $desktop = [Environment]::GetFolderPath("Desktop")

    function New-Shortcut($Name, $Target) {
        $lnk = Join-Path $desktop "$Name.lnk"
        $s = $shell.CreateShortcut($lnk)
        # 直接调 cmd.exe 跑 .bat,绕过文件关联问题(有些机器 .bat 关联被改坏了)
        $s.TargetPath = "$env:SystemRoot\System32\cmd.exe"
        $s.Arguments = "/c `"`"$Target`"`""
        $s.WorkingDirectory = (Split-Path $Target -Parent)
        $s.WindowStyle = 7
        $s.IconLocation = "$env:SystemRoot\System32\imageres.dll,109"
        $s.Save()
    }
    New-Shortcut "重启服务(Office Copilot Lite)" (Join-Path $rootDir "重启服务.bat")
    New-Shortcut "卸载 Office Copilot Lite" (Join-Path $rootDir "uninstall.bat")
    Write-Host "  ✓ 桌面快捷方式(重启 / 卸载)"

    # 写一个最小 config.json,记录元信息(供 uninstall 用)
    $cleanUser = $env:USERNAME -replace '[^a-zA-Z0-9]', ''
    $cfg = [ordered]@{
        share_name = "OCLWef$cleanUser"
        installed_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        version = "1.0.0"
        cert_thumbprint = $certThumbprint
    }
    $cfg | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $installDir "config.json") -Encoding UTF8

    # 弹完成对话框
    $okMsg = @"
✅ Office Copilot Lite 安装成功

接下来:

1. 打开 Excel(或 Word / PowerPoint)
2. 顶部「开始」→「加载项」→「共享文件夹」标签
3. 双击「Office Copilot Lite」加载

加载后右侧出现 AI 面板,需要填:
  - Gateway URL: https://api.deepseek.com/anthropic
       (或者其他 Anthropic 兼容的 API 网关)
  - API Key:    你自己的 sk-... key
  - Auth Header: X-Api-Key

完成后就能用 AI 直接操作 Excel/Word/PPT。

任何问题:
  - 双击桌面「重启服务」
  - 不行就发日志给作者:$logPath
"@
    [System.Windows.Forms.MessageBox]::Show(
        $okMsg, "Office Copilot Lite", "OK", "Information") | Out-Null

    # 打开使用说明 PDF
    $userGuide = Join-Path $rootDir "docs\老师使用说明.pdf"
    if (Test-Path $userGuide) {
        Start-Process $userGuide
    } else {
        $userGuideMd = Join-Path $rootDir "docs\老师使用说明.md"
        if (Test-Path $userGuideMd) { Start-Process $userGuideMd }
    }
}
catch {
    Write-Error "[install-core] 安装失败: $_"
    [System.Windows.Forms.MessageBox]::Show(
        "❌ 安装失败,详见日志:`n$logPath`n`n请把这个文件发给作者排查。`n`n错误:`n$_",
        "Office Copilot Lite", "OK", "Error") | Out-Null
    exit 1
}
finally {
    Stop-Transcript | Out-Null
}
