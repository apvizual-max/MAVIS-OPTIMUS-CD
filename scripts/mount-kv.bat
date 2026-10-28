@echo off
REM mount-kv.bat - thin launcher for mount-kv.ps1.
REM The scheduled task OPTIMUS_mount_KV may point here or directly at the
REM PowerShell script. The exit code of the PowerShell script is propagated
REM unchanged, so a failed mount is visible as a non zero LastTaskResult.
REM ASCII ONLY, LF endings, no BOM.
setlocal
set "PS1=%~dp0mount-kv.ps1"
if not exist "%PS1%" (
    echo FAIL mount-kv.ps1 not found next to this launcher: "%PS1%"
    endlocal
    exit /b 3
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
set "RC=%ERRORLEVEL%"
endlocal & exit /b %RC%
