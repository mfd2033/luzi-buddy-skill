# luzi-skill

炉子(luzi.top) Agent API 的技能封装（Skill）。把官方声明的能力封装成可调用接口，token 通过环境变量读取，避免硬编码泄露。本技能与具体 Agent 工具无关，理论上任意支持 Skill 机制的 Agent 均可使用。

## 安装为 Agent 技能

把本仓库放进所用 Agent 工具的 skills 目录（或在本目录通过技能管理器部署）。核心文件：

- `SKILL.md` —— Skill 定义与使用说明
- `luzi.ps1` —— 调用炉子 Agent API 的 PowerShell 助手

## 快速开始

```powershell
# 设置你的 agent 凭证（形如 lza_...），不要写进仓库
$env:LUZI_AGENT_TOKEN = 'lza_xxxx'

# 读取资产
.\luzi.ps1 assets

# 其余资源：notes / tags / tagsall / recipes / search / plaza
```

也可以复制 `.env.example` 为 `.env` 填入 token（`.env` 已被 `.gitignore` 忽略，不会提交）。

## 已验证能力（实测 200 + 真实数据）

| 能力 | 方法 | 端点 |
|---|---|---|
| 资产读取 | GET | `/api/v1/assets/` |
| 随手记读取 | GET | `/api/v1/notes/` |
| 标签读取 | GET | `/api/v1/notes/tags`、`/api/v1/tags/` |
| 配方读取 | GET | `/api/v1/recipes/` |
| 搜索读取 | GET | `/api/v1/search` |
| 浏览广场 | GET | `/api/v1/community/plaza/publications`（2026-09-17 真实 token 实测 200，返回 `total`/`limit`/`offset` + `items[]`，每条含 `id`/`title`/`title_zh`/`summary`/`tags`/`cover_public_url`/`save_count` 等字段） |

### 调用示例

所有已验证能力统一通过 `luzi.ps1` 的 `<资源>` 参数调用，token 自动从环境变量或 `.env` 读取：

```powershell
.\luzi.ps1 assets   # 资产读取  -> GET /api/v1/assets/
.\luzi.ps1 notes    # 随手记读取 -> GET /api/v1/notes/
.\luzi.ps1 tags     # 随手记标签 -> GET /api/v1/notes/tags
.\luzi.ps1 tagsall  # 全部标签   -> GET /api/v1/tags/
.\luzi.ps1 recipes  # 配方读取   -> GET /api/v1/recipes/
.\luzi.ps1 search   # 搜索读取   -> GET /api/v1/search
.\luzi.ps1 plaza    # 浏览广场   -> GET /api/v1/community/plaza/publications
```

返回均为 JSON（脚本用 `ConvertTo-Json -Depth 10` 输出），典型结构：

| 资源 | 关键返回字段 |
|---|---|
| `assets` | `items[]`：`id`、`name`、`type`、`content`、`updated_at` 等 |
| `notes` | `items[]`：`id`、`title`、`body`、`tags`、`created_at` 等 |
| `tags` / `tagsall` | `items[]`：`id`、`name`、`count` 等 |
| `recipes` | `items[]`：`id`、`title`、`description`、`steps` 等 |
| `search` | `items[]`：按查询返回的匹配资产/随手记/配方 |
| `plaza` | `total`/`limit`/`offset` + `items[]`：`id`、`title`、`title_zh`、`summary`、`tags`、`cover_public_url`、`save_count`、`copied_count` 等 |

> 直接用 `Invoke-RestMethod` 也可，需手动带 `Authorization: Bearer $LUZI_AGENT_TOKEN` 头（见 `SKILL.md`）。

### 用户提示词示例

在任意 Agent 工具中唤起本技能时，可直接用下面这些自然语言（技能会按 `<资源>` 路由到对应端点）：

| 用户提示词（示例） | 路由到 |
|---|---|
| "读取我在炉子里的资产" / "列出我的资产" | `assets` |
| "看看我的随手记" / "读一下我的笔记" | `notes` |
| "列出随手记的标签" | `tags` |
| "列出全部标签" | `tagsall` |
| "读取我的配方" / "看看我的 recipes" | `recipes` |
| "在炉子里搜索 前端设计" | `search` |
| "浏览广场上的 skill" / "看看广场里有什么" | `plaza` |

> 提示词只需点明「资源类型」（资产 / 随手记 / 标签 / 配方 / 搜索 / 广场）与「读取」意图即可，技能会自动带上 `LUZI_AGENT_TOKEN` 调用对应端点。

## 未验证能力（谨慎使用）

资产写入、随手记写入、配方写入、标签写入、文件读取、文件上传、从广场存副本、部署材料 —— 这些官方能力尚未验证端点与写权限，调用前请先小范围试探，避免误改线上数据。

## 安全提醒

- 本仓库为**公开**仓库，**绝不要**在其中提交真实 `LUZI_AGENT_TOKEN`。
- 凭证仅通过环境变量或本地 `.env` 提供。
