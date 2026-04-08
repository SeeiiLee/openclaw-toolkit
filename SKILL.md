---
name: openclaw-toolkit
description: Cyrus 个人 OpenClaw 工具包。包含记忆系统（自动记录对话中的教训/决策/洞察到 Obsidian）、看家模式（监控 QClaw 进程存活）、密钥管理（解密加密备份文件恢复账号凭据）。当 Cyrus 提到需要记录重要信息、恢复密码、或者 QClaw 异常中断时使用。设计为可移植：新机器部署 OpenClaw 后直接复制整个 skill 目录即可复用。
---

# OpenClaw Toolkit - Cyrus 个人工具包

## 工具包总览

| 脚本 | ID | 用途 |
|------|----|------|
| memory_append.ps1 | TOOL-MEM-001 | 关键词触发，自动写入 Obsidian 记忆库 |
| memory_daily_summary.ps1 | TOOL-MEM-002 | 每日会话结束前汇总所有记录 |
| qclaw_guardian.ps1 | TOOL-SEC-002 | QClaw 进程存活监控与自动重启 |
| secure_get.py | TOOL-SEC-001 | 解密加密备份文件，恢复账号凭据 |

## 1. 记忆系统

### 工作流程

对话进行中 -> Kairo 检测到关键词（共12类：教训/决策/洞察/偏好/模式/里程碑/工具变化/外部变化/商业洞察/约定/经验固化/自我反思）-> 自动调用 memory_append.ps1，安静记录（用户无感知）-> 会话结束前调用 memory_daily_summary.ps1 -> 写入 Obsidian 记忆库

### 使用方式

自动触发：Kairo 在对话中检测到关键词后自动执行，无需用户操作。

手动调用：
powershell -File memory_append.ps1 -Content 内容 -Type 教训
powershell -File memory_daily_summary.ps1

配置文件 references/memory_categories.json 定义了各类别对应的触发关键词，可直接编辑。

## 2. 看家模式

### 工作流程

Task Scheduler 每 2 分钟触发 qclaw_guardian.ps1 -> 检查 QClaw 进程是否存在 -> 未运行则启动并写入日志，已运行则静默退出。

### 使用方式

手动测试：powershell -File qclaw_guardian.ps1

设置定时任务（需管理员权限）：
$action = New-ScheduledTaskAction -Execute powershell.exe -Argument -File F:\QClawData\workspace\scripts\qclaw_guardian.ps1
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 2) -RepetitionDuration ([TimeSpan]::MaxValue)
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName QClaw_Guardian

## 3. 密钥管理

### 使用方式

python secure_get.py
python secure_get.py --filter b站
python secure_get.py --show-passwords --filter b站

依赖：pip install cryptography

## 4. 新机器部署

复制整个 openclaw-toolkit/ 目录到新机器的 skills 目录：
Copy-Item -Recurse F:\QClawData\skills\openclaw-toolkit \\新机器\c$\Users\用户名\.qclaw\skills\

然后修改脚本中的路径：Obsidian vault 路径、加密备份目录路径（默认 E:\KEY BACKUP）、QClaw 可执行文件路径。
完整元数据见 references/manifest.json。

## 5. 工作流程背景

这些工具解决了一个核心问题：跨 session 信息丢失。
Cyrus 是连续创业者，在 Etsy、亚马逊等平台运营。他与 AI Agent Kairo 合作，但每次新会话开始时，Kairo 会丢失之前积累的经验和判断。
记忆系统的设计：Kairo 在对话中安静地记录，离开时汇总。这样下一个 session 打开 Obsidian，就能继承上一个 session 的经验。

完整脚本：scripts/（可执行脚本）、references/（配置文件和 manifest）
