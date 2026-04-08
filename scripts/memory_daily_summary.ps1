# ============================================================
# memory_daily_summary.ps1 — Obsidian 每日记忆汇总脚本
# 由 cron 定时调用，读取当日全部记忆，生成精华摘要
# ============================================================
# 参数：
#   -Date <string>   日期（格式 yyyy-MM-dd），默认今天
#   -OutputPath <string>  输出到的总记忆文件，默认 ..\记忆库\MEMORY.md
# 使用示例：
#   .\memory_daily_summary.ps1
#   .\memory_daily_summary.ps1 -Date "2026-04-08"
# ============================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$Date = (Get-Date -Format "yyyy-MM-dd"),

    [Parameter(Mandatory=$false)]
    [string]$OutputPath = $null
)

$ScriptRoot = $PSScriptRoot
if (-not $OutputPath) {
    $MemoryDir = Join-Path (Split-Path $ScriptRoot -Parent) "记忆库"
    $OutputPath = Join-Path $MemoryDir "MEMORY.md"
}
$MemoryDir = Split-Path $OutputPath -Parent
$SourceFile = Join-Path $MemoryDir "$Date-经验记录.md"

if (-not (Test-Path $SourceFile)) {
    Write-Host "INFO: $Date 无记忆记录，跳过"
    exit 0
}

$Content = Get-Content $SourceFile -Raw -Encoding UTF8

$Categories = @{}
$Entries = @()

$Lines = $Content -split "`n"
$CurrentCategory = $null
$CurrentLines = @()

foreach ($Line in $Lines) {
    if ($Line -match "^## \d{2}:\d{2}:\d{2} \| ([^\|]+)$") {
        if ($CurrentCategory) {
            $Entries += @{
                Category = $CurrentCategory
                Lines = $CurrentLines -join "`n"
            }
        }
        $CurrentCategory = $matches[1].Trim()
        $CurrentLines = @()
    } elseif ($CurrentCategory) {
        $CurrentLines += $Line
    }
}
if ($CurrentCategory) {
    $Entries += @{
        Category = $CurrentCategory
        Lines = $CurrentLines -join "`n"
    }
}

$Count = $Entries.Count
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"

$Section = @"

## $Date 日记忆汇总

> 汇总时间: $Timestamp | 共 $Count 条记录

"@

if ($Entries.Count -gt 0) {
    $ByCategory = $Entries | Group-Object { $_.Category }
    foreach ($Group in $ByCategory) {
        $Section += "`n### $($Group.Name) `n`n"
        foreach ($Entry in $Group.Group) {
            $CleanContent = ($Entry.Lines -split "`n" | Where-Object {
                $_ -match '\S' -and
                $_ -notmatch '^---$' -and
                $_ -notmatch '^## ' -and
                $_ -notmatch '^\*\*Session' -and
                $_ -notmatch '^\*\*类型'
            }) -join " "
            $CleanContent = $CleanContent.Trim()
            if ($CleanContent) {
                $Section += "- $CleanContent`n"
            }
        }
    }
} else {
    $Section += "`n今日无记录。`n"
}

$Section += "`n---\n"

if (-not (Test-Path $OutputPath)) {
    $DefaultHeader = @"
# 经验记忆总库

> 此文件由 Kairo 每日自动汇总维护。手动添加的内容不会被覆盖。

"@
    $DefaultHeader | Out-File -FilePath $OutputPath -Encoding UTF8
}

$TempFile = Join-Path $MemoryDir ".tmp_summary_$Date.md"
$Section | Out-File -FilePath $TempFile -Encoding UTF8

$ExistingContent = Get-Content $OutputPath -Raw -Encoding UTF8
if ($ExistingContent -notmatch "(?s)## $Date 日记忆汇总") {
    $UpdatedContent = $ExistingContent + "`n" + $Section
    $UpdatedContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "OK: 已汇总到 $OutputPath"
} else {
    Write-Host "INFO: $Date 已汇总过，跳过"
}

Remove-Item $TempFile -ErrorAction SilentlyContinue
