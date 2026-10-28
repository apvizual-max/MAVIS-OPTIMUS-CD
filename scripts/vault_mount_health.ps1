# vault_mount_health.ps1 - replaces the retired X: vault mount task.
#
# WHY THIS REPLACED A MOUNT:
#   OPTIMUS_mount_KV ran E:\CLAUDE\OPTIMUS_Knoledge_Vault\mount-kv.bat, which
#   mapped a drive letter to the Central Obsidian Knoledge Vault. Measured
#   2026-10-28: E:\CLAUDE no longer exists, there is no mount-kv.bat anywhere
#   on E: or D:, and no X: drive exists (file system drives: C, D, E, G, Z).
#   The vault is not mounted any more - it is a plain folder at E:\MINTE.
#   The task was therefore failing on every boot with exit code 1, pointing at
#   a path that no longer exists, and it could not be disabled from this
#   session because the task definition is protected.
#
# WHAT IT DOES NOW:
#   It checks the thing the task actually cared about - that the Central
#   Obsidian Vault and the Second Brain are reachable on this machine - and
#   writes a dated line into the CD log. If the vault is not there, it says
#   so loudly and exits non-zero. A task that used to fail for a reason
#   nobody could see now states its own reason.
#
# ASCII ONLY: executed by Windows PowerShell 5.1.

[CmdletBinding()]
param(
    [string]$VaultRoot = 'E:\MINTE',
    [string]$SecondBrain = 'E:\MINTE\00_KV_SECOND BRAIN',
    [string]$LogFile = ''
)

$ErrorActionPreference = 'Continue'

if (-not $LogFile) {
    $base = Split-Path -Parent $PSScriptRoot
    $LogFile = Join-Path $base 'logs\vault-mount-health.log'
}
$logDir = Split-Path -Parent $LogFile
if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Line([string]$text) {
    $line = '[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] ' + $text
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
    Write-Host $line
}

$problems = 0

if (-not (Test-Path -LiteralPath $VaultRoot)) {
    Write-Line ('FAIL vault root not reachable: ' + $VaultRoot)
    $problems++
} else {
    Write-Line ('OK   vault root reachable: ' + $VaultRoot)
}

if (-not (Test-Path -LiteralPath $SecondBrain)) {
    Write-Line ('FAIL Second Brain folder not reachable: ' + $SecondBrain)
    $problems++
} else {
    Write-Line ('OK   Second Brain folder reachable: ' + $SecondBrain)
}

if ($problems -gt 0) {
    Write-Line ('VAULT_PROBLEMS=' + $problems)
    exit 1
}

Write-Line 'VAULT_PROBLEMS=0'
exit 0
