$action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument '"C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\scripts\start_sovereign_sync_silent.vbs"'
$trigger = New-ScheduledTaskTrigger -Daily -At "04:00"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName "Antigravity_Jules_GitHub_Continuous_Sync" -Action $action -Trigger $trigger -Settings $settings -Description "Antigravity Sovereign Dual-Interface Continuous Development & Autonomous Sync Daemon" -Force
Write-Host "Scheduled task registered successfully."
