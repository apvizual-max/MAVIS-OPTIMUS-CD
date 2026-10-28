# jules-autopilot-task.ps1 - (re)installs the scheduled task that keeps the
# Jules fleet moving without a human.
#
# WHY THIS EXISTS:
#   Measured 2026-10-28: the push-triggered Jules sessions stop at
#   AWAITING_USER_FEEDBACK whenever Jules asks a question, and the only thing
#   that answered them was the sovereign daemon - which runs ONCE A DAY at
#   03:00. Between two daemon runs a pushed change could sit blocked for
#   hours. That is the hole in "no human in the loop".
#
#   The unblocking itself is proven (scripts\jules-autopilot.ps1):
#     POST /v1alpha/sessions/{id}:sendMessage  -> releases a question
#     POST aida /v1/swebot/tasks/{id}:interact -> releases a plan approval
#   Measured: 4 stuck sessions became 25 COMPLETED + 4 IN_PROGRESS on the
#   fleet, and the only session left blocked is on MAVIS-CLOUD, which is
#   excluded on purpose.
#
# WHY THE TASK IS NOT THE DAEMON:
#   The daemon also merges pull requests, prunes branches and clears
#   notifications. Running that every 15 minutes would change what the fleet
#   does, not just how fast it moves. This task only unblocks sessions. The
#   daemon keeps its daily 03:00 schedule.
#
# WHY THE PATH IS DERIVED AND NOT HARDCODED:
#   Same reason as register_task.ps1. A hardcoded path dies with the next
#   move of the tree; the path derived from this script's own location does
#   not.
#
# ASCII ONLY: executed by Windows PowerShell 5.1.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\jules-autopilot-task.ps1

$ErrorActionPreference = 'Stop'

$script = Join-Path $PSScriptRoot 'jules-autopilot.ps1'
if (-not (Test-Path -LiteralPath $script)) {
    Write-Host ('EROARE: nu exista ' + $script)
    exit 2
}

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-NoProfile -ExecutionPolicy Bypass -File "' + $script + '" -Apply')
# Every 15 minutes. Measured 2026-10-28: the transition of a stuck session
# to IN_PROGRESS took between 30 and 90 seconds after the answer was sent, so
# a 15 minute cadence is generous - it leaves room for the agent to work
# between two checks and does not hammer the API.
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(15) -RepetitionInterval (New-TimeSpan -Minutes 15)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 20)

Register-ScheduledTask -TaskName 'Jules_Autopilot_Fleet' -Action $action -Trigger $trigger -Settings $settings -Description 'Unblocks Jules sessions that wait for feedback, so the push mechanism runs without a human.' -Force | Out-Null

Write-Host ('Scheduled task registered: Jules_Autopilot_Fleet')
Write-Host ('Action: powershell -File "' + $script + '" -Apply')
Write-Host 'Trigger: every 15 minutes, StartWhenAvailable enabled.'
exit 0
