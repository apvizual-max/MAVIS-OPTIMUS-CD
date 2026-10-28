Set WshShell = CreateObject("WScript.Shell")
scriptPath = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File ""C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\scripts\jules_github_sovereign_daemon.ps1"" -Silent"
WshShell.Run scriptPath, 0, False
