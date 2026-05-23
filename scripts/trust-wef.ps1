# trust-wef.ps1
# 写 HKCU 注册表把共享路径加进 Office 信任目录,免去手动 GUI 操作
# 对 Excel/Word/PowerPoint 三个 app 都写

$shareUrl = "\\$env:OCL_COMPUTER\$env:OCL_SHARE_NAME"
$guid = "{$env:OCL_GUID}"  # 注册表 GUID 必须带花括号

# 信任目录注册表路径
$basePath = "HKCU:\Software\Microsoft\Office\16.0\WEF\TrustedCatalogs"

# 确保 base path 存在
if (-not (Test-Path $basePath)) {
    New-Item -Path $basePath -Force | Out-Null
}

# 创建 GUID 子项
$catalogPath = Join-Path $basePath $guid
if (-not (Test-Path $catalogPath)) {
    New-Item -Path $catalogPath -Force | Out-Null
}

# 写字段
Set-ItemProperty -Path $catalogPath -Name "Id" -Value $guid -Type String
Set-ItemProperty -Path $catalogPath -Name "Url" -Value $shareUrl -Type String
Set-ItemProperty -Path $catalogPath -Name "Flags" -Value 1 -Type DWord  # 1 = 显示在菜单中
Set-ItemProperty -Path $catalogPath -Name "Type" -Value 2 -Type DWord    # 2 = 网络共享

Write-Host "[trust-wef] 信任目录已写入注册表: $shareUrl"
Write-Host "  Excel/Word/PowerPoint 共用 HKCU 这一份配置"
