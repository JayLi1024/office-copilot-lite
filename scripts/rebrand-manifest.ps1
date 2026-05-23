# rebrand-manifest.ps1
# 把 helper.exe install 部署的 manifest.xml 改成 Office Copilot Lite 品牌
# 不改 GUID/URL/Hosts(那些 Office 用来识别加载项的)

$manifestPath = Join-Path $env:OCL_WEF_DIR "manifest.xml"
if (-not (Test-Path $manifestPath)) {
    Write-Error "[rebrand-manifest] manifest.xml 不存在: $manifestPath"
    Write-Error "可能 helper.exe install 还没跑成功"
    exit 1
}

$xml = Get-Content $manifestPath -Raw -Encoding UTF8

# 三个品牌字段
$replacements = @{
    '<ProviderName>Anthropic</ProviderName>' = '<ProviderName>Office Copilot Lite</ProviderName>'
    '<DisplayName DefaultValue="Claude" />' = '<DisplayName DefaultValue="Office Copilot Lite" />'
    '<Description DefaultValue="Claude in Microsoft Office"/>' = '<Description DefaultValue="AI 助手:让 Office 帮你填表/排版/写文档"/>'
}

$changed = 0
foreach ($old in $replacements.Keys) {
    $new = $replacements[$old]
    if ($xml.Contains($old)) {
        $xml = $xml.Replace($old, $new)
        $changed++
        Write-Host "[rebrand-manifest] 已改: $old"
    } else {
        Write-Host "[rebrand-manifest] 跳过(未找到): $old"
    }
}

if ($changed -eq 0) {
    Write-Warning "[rebrand-manifest] 没有任何字段被替换,manifest.xml 可能已是品牌版或格式不符"
} else {
    Set-Content -Path $manifestPath -Value $xml -Encoding UTF8 -NoNewline
    Write-Host "[rebrand-manifest] 完成,共 $changed 项替换"
}
