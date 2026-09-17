---
name: luzi-buddy-skill
description: 炉子Buddy（luziBuddy）：调用炉子(luzi.top) Agent API 的读取能力。已验证读取：参考/随手记/标签/提示词/搜索/广场。Token 通过环境变量 LUZI_AGENT_TOKEN 提供。当用户需要读取或操作炉子中的参考、随手记、提示词、标签、广场内容时使用。
---

# luziBuddy（炉子Buddy）

炉子Buddy（luziBuddy）封装炉子(luzi.top) Agent 凭证的 HTTP API 调用。

- **Base URL**: `https://app.luzi.top/api/v1/`
- **认证**: `Authorization: Bearer $LUZI_AGENT_TOKEN`

> ⚠️ 安全红线：Token 只能来自环境变量 `LUZI_AGENT_TOKEN` 或本地 `.env`（已被 `.gitignore` 忽略），**切勿**把真实 token 提交到公开仓库。

## 已验证的能力（已用 token 实测返回 200 + 真实数据）

> 客户端功能名 ↔ API 资源名：`参考`=资产(`assets`)、`提示词`=配方(`recipes`)、`随手记`=notes、`搜索`=search、`广场`=plaza。`标签` 是随手记的子功能（内联 `#标签`）。`skill` 是客户端独立功能，其专属读取端点尚未验证（广场返回的多为 skill 作品）。

| 能力（客户端名 / API 资源） | 方法 | 端点 |
|---|---|---|
| 参考读取（资产 /assets/） | GET | `/api/v1/assets/` |
| 随手记读取（notes） | GET | `/api/v1/notes/` |
| 标签读取（notes 子功能） | GET | `/api/v1/notes/tags` 与 `/api/v1/tags/` |
| 提示词读取（配方 /recipes/） | GET | `/api/v1/recipes/` |
| 搜索读取（search） | GET | `/api/v1/search?q=<词>`（需带 `q` 参数，否则 400） |
| 浏览广场（plaza） | GET | `/api/v1/community/plaza/publications`（2026-09-17 真实 token 实测 200，返回 `total`/`limit`/`offset` + `items[]`，每条含 `id`/`title`/`title_zh`/`summary`/`tags`/`cover_public_url`/`save_count`/`copied_count` 等字段） |
| 随手记写入 | POST | `/api/v1/notes/`（2026-09-17 实测 201，请求体见下） |
| 标签写入 | POST | `/api/v1/tags/`（2026-09-17 实测 201，请求体必须含 `kind`，见下） |
| 随手记删除 | DELETE | `/api/v1/notes/{id}`（2026-09-17 实测 204） |
| 标签删除 | DELETE | `/api/v1/tags/{id}?expected_kind=tag`（2026-09-17 实测 204，缺 `expected_kind` 则 422） |

## 写入 / 删除能力（2026-09-17 实测）

> ⚠️ 写操作会改动你 luzi.top 账号里的**真实在线数据**。以下端点与约束均已用真实 token 实测通过；调用前仍建议小范围试探，并在测试后清理。

### 随手记写入 `POST /api/v1/notes/`
请求体（JSON）：
```json
{ "content_markdown": "正文内容，#标签 会被自动解析", "source_kind": "manual", "inline_tag_policy": "parse" }
```
- `content_markdown`：随手记正文（必填）。
- `source_kind`：来源，`manual` 为手动。
- `inline_tag_policy: "parse"`：正文中的 `#标签` 语法会被自动解析进 `tags[]`（实测已生效）。
- 响应 `201 Created`，返回完整 note 对象（含新生成的 `id` 与解析出的 `tags`）。

### 标签写入 `POST /api/v1/tags/`
请求体（JSON）：
```json
{ "name": "标签名", "kind": "tag" }
```
- `kind` **必填**，否则返回 `422 VALIDATION_ERROR`（`body.kind` 必填）。标签读取返回的 `kind` 即 `"tag"`。
- 响应 `201 Created`，返回 `{ id, name, normalized_name, is_system, kind }`。

### 删除
- `DELETE /api/v1/notes/{id}` → `204`（删除成功）。
- `DELETE /api/v1/tags/{id}?expected_kind=tag` → `204`；**必须带查询参数 `expected_kind=tag`**，否则 `422`（`query.expected_kind` 必填）。

### 关键坑：请求体必须文件化发送
直接 `curl -d "{...中文...}"` 经 PowerShell→curl 传递时，中文参数会把 JSON 结构破坏，服务端报 `422 JSON decode error`。**务必把请求体写成 UTF-8（无 BOM）文件，再用 `curl -d @file` 发送**（与 `luzi.ps1` 读响应的稳妥方案同源）：

```powershell
$b = "{""content_markdown"":""测试 #标签"",""source_kind"":""manual"",""inline_tag_policy"":""parse""}"
[System.IO.File]::WriteAllText($f, $b, [System.Text.UTF8Encoding]::new($false))
curl.exe -sS -X POST -H "Authorization: Bearer $env:LUZI_AGENT_TOKEN" -H "Content-Type: application/json" --data-binary "@$f" "https://app.luzi.top/api/v1/notes/"
```

## 用法
配套脚本 `luzi.ps1`（PowerShell）：

```powershell
$env:LUZI_AGENT_TOKEN = 'lza_xxx'   # 你的 agent 凭证
.\luzi.ps1 assets      # 读取参考（资产）
.\luzi.ps1 notes       # 读取随手记
.\luzi.ps1 tags        # 读取随手记标签
.\luzi.ps1 tagsall     # 读取全部标签
.\luzi.ps1 recipes     # 读取提示词（配方）
.\luzi.ps1 search -Query "前端设计"   # 搜索读取（必须带 -Query）
.\luzi.ps1 plaza       # 浏览广场
```

也可直接用 `Invoke-RestMethod`：

```powershell
$h = @{Authorization="Bearer $env:LUZI_AGENT_TOKEN"}
Invoke-RestMethod -Uri "https://app.luzi.top/api/v1/assets/" -Headers $h
```

## 未验证的能力（端点/写操作尚未实测，使用前请先小范围试探）
以下官方声明的能力**尚未**用真实 token 实测端点与写权限，调用前请先小范围试探，避免误改线上数据：
- 参考写入（资产 `POST /api/v1/assets/` 端点未实测）
- 提示词写入（配方 `POST /api/v1/recipes/` 端点未实测）
- skill 读取端点（广场返回的多为 skill 作品，但 `/skills/` 类专属端点未单独实测）
- 文件读取、文件上传
- 从广场存副本、部署材料
- 随手记/标签的**更新（PUT/PATCH）**端点（仅增删已实测，改尚未验证）

> 已验证：随手记写入 `POST /notes/`、标签写入 `POST /tags/`、随手记删除 `DELETE /notes/{id}`、标签删除 `DELETE /tags/{id}?expected_kind=tag`（详见上文「写入 / 删除能力」）。

## 环境变量
- `LUZI_AGENT_TOKEN`：必填，炉子 agent 凭证（形如 `lza_...`）。
- 或在本目录 `.env` 写入 `LUZI_AGENT_TOKEN=...`（该文件已被忽略，不要提交）。
