---
name: luzi-skill
description: 调用炉子(luzi.top) Agent API 的读取能力。已验证读取：资产/随手记/标签/配方/搜索/广场。Token 通过环境变量 LUZI_AGENT_TOKEN 提供。当用户需要读取或操作炉子中的资产、随手记、配方、标签、广场内容时使用。
---

# luzi-skill（炉子 Agent API）

封装炉子(luzi.top) Agent 凭证的 HTTP API 调用。

- **Base URL**: `https://app.luzi.top/api/v1/`
- **认证**: `Authorization: Bearer $LUZI_AGENT_TOKEN`

> ⚠️ 安全红线：Token 只能来自环境变量 `LUZI_AGENT_TOKEN` 或本地 `.env`（已被 `.gitignore` 忽略），**切勿**把真实 token 提交到公开仓库。

## 已验证的能力（已用 token 实测返回 200 + 真实数据）
| 能力 | 方法 | 端点 |
|---|---|---|
| 资产读取 | GET | `/api/v1/assets/` |
| 随手记读取 | GET | `/api/v1/notes/` |
| 标签读取 | GET | `/api/v1/notes/tags` 与 `/api/v1/tags/` |
| 配方读取 | GET | `/api/v1/recipes/` |
| 搜索读取 | GET | `/api/v1/search?q=<词>`（需带 `q` 参数，否则 400） |
| 浏览广场 | GET | `/api/v1/community/plaza/publications`（2026-09-17 真实 token 实测 200，返回 `total`/`limit`/`offset` + `items[]`，每条含 `id`/`title`/`title_zh`/`summary`/`tags`/`cover_public_url`/`save_count`/`copied_count` 等字段） |

## 用法
配套脚本 `luzi.ps1`（PowerShell）：

```powershell
$env:LUZI_AGENT_TOKEN = 'lza_xxx'   # 你的 agent 凭证
.\luzi.ps1 assets      # 读取资产
.\luzi.ps1 notes       # 读取随手记
.\luzi.ps1 tags        # 读取随手记标签
.\luzi.ps1 tagsall     # 读取全部标签
.\luzi.ps1 recipes     # 读取配方
.\luzi.ps1 search -Query "前端设计"   # 搜索读取（必须带 -Query）
.\luzi.ps1 plaza       # 浏览广场
```

也可直接用 `Invoke-RestMethod`：

```powershell
$h = @{Authorization="Bearer $env:LUZI_AGENT_TOKEN"}
Invoke-RestMethod -Uri "https://app.luzi.top/api/v1/assets/" -Headers $h
```

## 未验证的能力（端点/写操作尚未实测，使用前请先小范围试探）
官方声明还包括：资产写入、随手记写入、配方写入、标签写入、文件读取、文件上传、从广场存副本、部署材料。这些尚未验证端点与写权限，调用前请先确认，避免误改线上数据。

## 环境变量
- `LUZI_AGENT_TOKEN`：必填，炉子 agent 凭证（形如 `lza_...`）。
- 或在本目录 `.env` 写入 `LUZI_AGENT_TOKEN=...`（该文件已被忽略，不要提交）。
