# register_task.ps1 - (re)installs the CD continuous-sync scheduled task.
#
# WHY THE PATH IS DERIVED AND NOT HARDCODED:
#   This script used to point the task at
#   C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\scripts\start_sovereign_sync_silent.vbs
#   That junction was removed on 2026-10-27 08:00 during the CD tree
#   reorganisation. The task kept the dead path, so the 2026-10-28 03:00 run
#   failed with exit code 1 and the whole CD engine was dead for a day
#   without leaving a log line. The installer was the reason: anyone
#   re-running it would have re-buried the dead path.
#   The path is now derived from this script's own location, and the vbs
#   derives the daemon from its own location, so the chain survives the next
#   move.
#
# WHY THE TRIGGER IS 03:00 AND NOT 04:00:
#   The installed task has always fired at 03:00. The installer said 04:00.
#   Whichever ran last decided the schedule, and the documentation repeated
#   the wrong number. Measured 2026-10-28: the task fires at 03:00, so 03:00
#   is what gets written here and what the README says.
#
# ASCII ONLY: executed by Windows PowerShell 5.1.

$ErrorActionPreference = 'Stop'

$vbs = Join-Path $PSScriptRoot 'start_sovereign_sync_silent.vbs'
if (-not (Test-Path -LiteralPath $vbs)) {
    Write-Host ('EROARE: nu exista ' + $vbs)
    exit 2
}

$action = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument ('"' + $vbs + '"')
$trigger = New-ScheduledTaskTrigger -Daily -At '03:00'
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName 'Antigravity_Jules_GitHub_Continuous_Sync' -Action $action -Trigger $trigger -Settings $settings -Description 'Antigravity Sovereign Dual-Interface Continuous Development & Autonomous Sync Daemon' -Force

Write-Host ('Scheduled task registered. Action: wscript.exe "' + $vbs + '"')
Write-Host 'Trigger: daily at 03:00, StartWhenAvailable enabled.'
exit 0
