# ============================================================
# memory_append.ps1 — Obsidian 记忆追加脚本
# ============================================================
param(
    [Parameter(Mandatory=$true)]
    [string]$Type,
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]$Content,
    [Parameter(Mandatory=$false)]
    [string]$Session = "unknown"
)

$CfgPath = Join-Path $PSScriptRoot "memory_categories.json"
$MemoryDir = Join-Path (Split-Path $PSScriptRoot -Parent) "记忆库"
$Today = Get-Date -Format "yyyy-MM-dd"
$LogFile = Join-Path $MemoryDir "auto_append.log"

function Write-Log {
    param([string]$Msg)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$ts [$Session] $Msg" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

if (-not (Test-Path $CfgPath)) {
    Write-Host "ERROR: 配置文件不存在: $CfgPath"
    exit 1
}

try {
    $Cfg = Get-Content $CfgPath -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    Write-Host "ERROR: 配置文件格式错误: $_"
    exit 1
}

$Category = $Cfg.categories | Where-Object { $_.type -eq $Type } | Select-Object -First 1
if (-not $Category) {
    Write-Host "ERROR: 未知分类类型: $Type"
    exit 1
}

if (-not (Test-Path $MemoryDir)) {
    New-Item -ItemType Directory -Path $MemoryDir -Force | Out-Null
}

$LogPath = Join-Path $MemoryDir "$Today-经验记录.md"

if (-not (Test-Path $LogPath)) {
    $Header = @"
---
creation_date: $Today
tags: [记忆, 自动记录]
---

# $Today 经验记录

> 此文件由 Kairo 自动维护。

---
"@
    $Header | Out-File -FilePath $LogPath -Encoding UTF8
}

$Ts = Get-Date -Format "HH:mm:ss"
$Entry = @"

## $Ts | $($Category.emoji) $($Category.label)

**Session:** $Session | **类型:** $($Category.label)

$Content

---
"@

$Entry | Out-File -FilePath $LogPath -Append -Encoding UTF8
Write-Log "OK [$($Category.type)] $Content"
Write-Host "OK: 已追加 [$($Category.label)] 到 $LogPath"
