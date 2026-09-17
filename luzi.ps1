<#
.SYNOPSIS
  luzi-skill: 调用炉子(luzi.top) Agent API 已验证的读取能力
.DESCRIPTION
  Token 从环境变量 LUZI_AGENT_TOKEN 读取，也可放置于脚本同目录 .env 文件（LUZI_AGENT_TOKEN=...）
  用法: .\luzi.ps1 <assets|notes|tags|tagsall|recipes|search|plaza> [-Query "关键词"]
  search 必带 -Query，例如: .\luzi.ps1 search -Query "前端设计"
#>
param(
  [Parameter(Position=0)] [string]$Resource = 'assets',
  [string]$Query,
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
if ($Resource -eq 'search') {
  if (-not $Query) {
    Write-Error 'search 需要查询词：请加 -Query "你的关键词"（如 .\luzi.ps1 search -Query "前端设计"）'
    exit 1
  }
  $uri += '?q=' + [System.Uri]::EscapeDataString($Query)
}
try {
  # 关键：PowerShell 5.1 的 Invoke-RestMethod / Invoke-WebRequest 会把响应体
  # 按 ISO-8859-1 解码成字符串，导致 UTF-8 中文变成 Mojibake（如 ç­è§é¢ä¸è½½å¨）。
  # 改用 curl.exe 直接把原始字节写入文件（UTF-8），再读回即可完整保留中文。
  $tmp = Join-Path $env:TEMP "luzi_resp_$(Get-Random).json"
  curl.exe -sS -H "Authorization: Bearer $Token" "$uri" -o $tmp
  if (-not (Test-Path $tmp)) { throw 'curl produced no response file' }
  $json = Get-Content -Raw -Encoding utf8 $tmp
  Remove-Item $tmp -Force
  $r = $json | ConvertFrom-Json
  $r | ConvertTo-Json -Depth 10 -Compress:$false
} catch {
  Write-Error "请求失败: $_"
  if ($_.Exception.Response) { $_.Exception.Response.StatusCode }
  exit 1
}
