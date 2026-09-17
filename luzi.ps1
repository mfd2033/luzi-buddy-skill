<#
.SYNOPSIS
  luzi-skill: 调用炉子(luzi.top) Agent API 已验证的读取能力
.DESCRIPTION
  Token 从环境变量 LUZI_AGENT_TOKEN 读取，也可放置于脚本同目录 .env 文件（LUZI_AGENT_TOKEN=...）
  用法: .\luzi.ps1 <assets|notes|tags|tagsall|recipes|search|plaza>
#>
param(
  [Parameter(Position=0)] [string]$Resource = 'assets',
  [string]$Token = $env:LUZI_AGENT_TOKEN,
  [string]$BaseUrl = 'https://app.luzi.top/api/v1'
)

# 若环境变量缺失，尝试从同目录 .env 读取（不提交该文件）
if (-not $Token) {
  $envPath = Join-Path $PSScriptRoot '.env'
  if (Test-Path $envPath) {
    foreach ($l in (Get-Content -Encoding utf8 $envPath)) {
      if ($l -match '^\s*LUZI_AGENT_TOKEN\s*=\s*(.+)$') { $Token = $Matches[1].Trim().Trim('"') }
    }
  }
}
if (-not $Token) {
  Write-Error '缺少 LUZI_AGENT_TOKEN：请设置环境变量，或在脚本同目录 .env 中写入 LUZI_AGENT_TOKEN=...'
  exit 1
}

$map = @{
  assets  = 'assets/'
  notes   = 'notes/'
  tags    = 'notes/tags'
  tagsall = 'tags/'
  recipes = 'recipes/'
  search  = 'search'
  plaza   = 'community/plaza/publications'
}
if (-not $map.ContainsKey($Resource)) {
  Write-Error "未知资源: $Resource。可用: $($map.Keys -join ', ')"
  exit 1
}

$uri = "$BaseUrl/$($map[$Resource])"
try {
  $r = Invoke-RestMethod -Uri $uri -Headers @{Authorization = "Bearer $Token" } -Method Get -TimeoutSec 30
  $r | ConvertTo-Json -Depth 10 -Compress:$false
} catch {
  Write-Error "请求失败: $_"
  if ($_.Exception.Response) { $_.Exception.Response.StatusCode }
  exit 1
}
