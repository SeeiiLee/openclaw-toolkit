param(
    [string]$DataRoot    = "F:\QClawData",
    [string]$QclawExe    = "D:\ImportantTools\QClaw\QClaw.exe",
    [string]$FlagFile    = "F:\QClawData\qclaw_guardian.flag",
    [string]$LogFile     = "F:\QClawData\logs\qclaw_guardian.log",
    [int]$CheckInterval  = 2,
    [int]$MaxRestartIn   = 15,
    [int]$MaxRestarts    = 5
)

$ErrorActionPreference = "SilentlyContinue"
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$LogDir = Split-Path $LogFile -Parent
if (-not (Test-Path $LogDir)) {
    try { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null } catch {}
}

if (-not (Test-Path $FlagFile)) { exit 0 }

$flagContent = Get-Content $FlagFile -Raw -ErrorAction SilentlyContinue
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
if ($flagContent) {
    $logLine = "$ts [INFO] Flag found:"
    try { $logLine | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch {}
    try { $flagContent | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch {}
}

$qclawProcess = Get-Process -ErrorAction SilentlyContinue | Where-Object {
    ($_.Path -eq $QclawExe) -or ($_.ProcessName -eq "QClaw") -or ($_.ProcessName -like "*QClaw*")
} | Select-Object -First 1

if ($qclawProcess) {
    $logLine = "$ts [INFO] QClaw running PID $($qclawProcess.Id)"
    try { $logLine | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch {}
    exit 0
}

$logLine = "$ts [INFO] QClaw not running, restart triggered"
try { $logLine | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch {}

$counterFile = Join-Path $DataRoot "qclaw_restart_counter.json"
$counter = @{ count = 0; firstAttempt = $null }
if (Test-Path $counterFile) {
    try { $counter = Get-Content $counterFile | ConvertFrom-Json } catch {}
}

$now = Get-Date
if ($counter.firstAttempt) {
    try {
        $firstTime = [DateTime]::Parse($counter.firstAttempt)
        $elapsed = ($now - $firstTime).TotalMinutes
        if ($elapsed -gt $MaxRestartIn) {
            $logLine = "$ts [INFO] Window expired, reset counter"
            try { $logLine | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch {}
            $counter = @{ count = 0; firstAttempt = $now.ToString("o") }
        }
    } catch {}
} else {
    $counter.firstAttempt = $now.ToString("o")
}

if ($counter.count -ge $MaxRestarts) {
    $logLine = "$ts [WARN] Max restarts reached, giving up"
    try { $logLine | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch {}
    exit 1
}

$counter.count = $counter.count + 1
try { $counter | ConvertTo-Json | Set-Content $counterFile -Encoding UTF8 } catch {}
$logLine = "$ts [INFO] Restart attempt $($counter.count)"
try { $logLine | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch {}

$zombie = Get-Process -ErrorAction SilentlyContinue | Where-Object {
    ($_.Path -eq $QclawExe) -or ($_.ProcessName -eq "QClaw") -or ($_.ProcessName -like "*QClaw*")
}
if ($zombie) {
    $logLine = "$ts [INFO] Zombie found PID $($zombie.Id), killing"
    try { $logLine | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch {}
    Stop-Process -Id $zombie.Id -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
}

$logLine = "$ts [INFO] Starting QClaw: $QclawExe"
try { $logLine | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch {}
try { Start-Process $QclawExe -WindowStyle Hidden -ErrorAction SilentlyContinue } catch {}

Start-Sleep -Seconds 5

$verify = Get-Process -ErrorAction SilentlyContinue | Where-Object {
    ($_.Path -eq $QclawExe) -or ($_.ProcessName -eq "QClaw") -or ($_.ProcessName -like "*QClaw*")
} | Select-Object -First 1

if ($verify) {
    $logLine = "$ts [INFO] QClaw restarted OK PID $($verify.Id)"
    try { $logLine | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch {}
    try { Remove-Item $counterFile -Force -ErrorAction SilentlyContinue } catch {}
} else {
    $logLine = "$ts [WARN] QClaw restart verify failed"
    try { $logLine | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch {}
}

exit 0
