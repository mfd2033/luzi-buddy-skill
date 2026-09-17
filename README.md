# luzi-skill

炉子(luzi.top) Agent API 的 CodeBuddy Skill。把官方声明的能力封装成可调用接口，token 通过环境变量读取，避免硬编码泄露。

## 安装为 CodeBuddy Skill

把本仓库放进 CodeBuddy 的 skills 目录（或在本目录通过 skill 管理器部署）。核心文件：

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
| 浏览广场 | GET | `/api/v1/community/plaza/publications` |

## 未验证能力（谨慎使用）

资产写入、随手记写入、配方写入、标签写入、文件读取、文件上传、从广场存副本、部署材料 —— 这些官方能力尚未验证端点与写权限，调用前请先小范围试探，避免误改线上数据。

## 安全提醒

- 本仓库为**公开**仓库，**绝不要**在其中提交真实 `LUZI_AGENT_TOKEN`。
- 凭证仅通过环境变量或本地 `.env` 提供。
