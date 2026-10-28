Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' The daemon path is derived from this file's own location instead of being
' hardcoded. The hardcoded C:\...\Antigravity_JULES_INT\ path died on
' 2026-10-27 08:00, when that junction was removed during the CD tree
' reorganisation. The scheduled task kept pointing at it and the 2026-10-28
' 03:00 run failed silently with exit code 1 - a whole day of the CD engine
' dead, with no log line explaining why. A path that is derived from the
' caller survives the next move.
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
daemon = scriptDir & "\jules_github_sovereign_daemon.ps1"

If Not fso.FileExists(daemon) Then
    WshShell.Echo "CD daemon not found: " & daemon
    WScript.Quit 2
End If

scriptPath = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & daemon & """ -Silent"
WshShell.Run scriptPath, 0, False
