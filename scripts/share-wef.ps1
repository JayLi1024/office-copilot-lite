# share-wef.ps1
# 把 Wef 目录共享出来,让 Office 信任目录能用 UNC 路径找到 manifest
# 依赖 detect-paths.ps1 设置的 OCL_WEF_DIR, OCL_SHARE_NAME

$shareName = $env:OCL_SHARE_NAME
$wefDir = $env:OCL_WEF_DIR

# 先确保 Wef 目录存在(office-helper install 之后应该有)
if (-not (Test-Path $wefDir)) {
    Write-Error "[share-wef] Wef 目录不存在: $wefDir"
    Write-Error "可能 helper.exe install 还没跑成功"
    exit 1
}

# 检查是否已共享(同名共享会冲突)
$existing = net share | Select-String -Pattern "^\s*$shareName\s"
if ($existing) {
    Write-Host "[share-wef] 共享 $shareName 已存在,跳过"
    exit 0
}

# 创建共享(只读,所有人可访问 — Office 加载项需要)
$cmd = "net share $shareName=`"$wefDir`" /grant:everyone,read /remark:`"Office Copilot Lite Wef`""
Write-Host "[share-wef] $cmd"
& cmd /c $cmd
if ($LASTEXITCODE -ne 0) {
    Write-Error "[share-wef] net share 失败,exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "[share-wef] 共享创建成功: \\$env:OCL_COMPUTER\$shareName -> $wefDir"
