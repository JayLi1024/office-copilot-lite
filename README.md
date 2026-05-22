# Office Copilot Lite

> 一键安装的 Excel / Word / PowerPoint AI 加载项,在加载项 UI 里填 LLM 网关 URL + Key 就能用。

[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)

---

## 是什么

Office Copilot Lite 让你的 Excel/Word/PPT 长出和 Microsoft Copilot 一样的 AI 聊天面板,**直接操作单元格 / 段落 / 幻灯片**。可以接任意 Anthropic-compatible 的 LLM 网关:

- ✅ DeepSeek 官方 (`https://api.deepseek.com/anthropic`) — **首推,稳定且便宜**
- ✅ Anthropic 官方 Claude
- ✅ Kimi (Moonshot) / GLM-5 (智谱)等原生兼容 Anthropic 的国产模型
- ✅ 第三方中转 / 自部署网关

## 适合谁

- 学校老师批量填表 / 写文档
- 财务/行政日常 Excel 自动化
- 不想付 Microsoft Copilot 月费的轻量用户

## 安装(给最终用户)

1. 从 [Releases](https://github.com/USER/office-copilot-lite/releases) 下载 `office-copilot-lite-vX.Y.Z.zip`
2. 把 `helper.exe`(原 office-helper)放到 `bin/helper.exe`
3. 解压后**双击 `install.bat`**(UAC 点是)
4. 看到"✅ 安装成功"
5. 打开 Excel → 加载项 → 共享文件夹 → 双击 "Office Copilot Lite"
6. 在 AI 面板里填:
   - **Gateway URL**: `https://api.deepseek.com/anthropic`
   - **API Key**: 你自己的 sk-...
   - **Auth Header**: `X-Api-Key`

完成。

详细使用说明:[`docs/老师使用说明.md`](docs/老师使用说明.md)。

## 系统要求

- Windows 10/11
- Microsoft 365 或 Office LTSC 2024(**LTSC 2021 / Office 2019 / WPS 不支持**)
- 管理员权限(只在安装时需要)

## 项目结构

```
office-copilot-lite/
├─ install.bat              ← 用户双击入口
├─ uninstall.bat
├─ 重启服务.bat
├─ bin/
│  └─ helper.exe            ← Rust 单体服务(Wef HTTPS + 反代)
├─ scripts/                 ← PowerShell 子脚本
│  ├─ install-core.ps1
│  ├─ uninstall-core.ps1
│  ├─ detect-paths.ps1      ← 路径自动检测(Wef/共享名/计算机名/端口)
│  ├─ register-tasks.ps1    ← 注册登录启动任务
│  ├─ trust-wef.ps1         ← 写信任目录注册表
│  ├─ share-wef.ps1         ← net share Wef
│  └─ rebrand-manifest.ps1  ← 改加载项品牌
├─ docs/
│  ├─ 老师使用说明.md
│  └─ screenshots/
└─ .github/workflows/
   └─ release.yml           ← tag 触发自动打包 Release zip
```

## 工作原理

```
┌─ Excel/Word/PPT ─┐
│  AI 聊天面板     │
└────────┬─────────┘
         │ HTTPS(自签证书)
         ↓
┌────────────────────┐
│  helper.exe        │  127.0.0.1:18765
│  本机 HTTPS 服务   │  (只 serve 加载项 webview,不参与 LLM 流量)
└────────────────────┘

webview JS  →  你在 UI 里填的 URL(如 api.deepseek.com)
            带 X-Api-Key: 你的 key
```

简洁清晰:**LLM 流量直接从 webview JS 到上游 API,本机服务只提供加载项资源**。

## 致谢

- [@哈雷彗星 (Haleclipse)](https://linux.do/u/haleclipse) — `helper.exe` 来自其 office-helper 项目
- [Anthropic](https://www.anthropic.com/) & [Microsoft](https://www.microsoft.com/) — Claude in Office 加载项的原始作者

## License

MIT
