# vault_mount_health.ps1 - health check for the PKMS KV vault mount.
#
# WHY THIS FILE EXISTS:
#   The scheduled task OPTIMUS_mount_KV used to run
#   E:\CLAUDE\OPTIMUS_Knoledge_Vault\mount-kv.bat, the launcher of the retired
#   Central Obsidian Knoledge Vault. Measured 2026-10-28: E:\CLAUDE does not
#   exist any more, so the task failed with result 1 at every trigger
#   (boot, logon, session state change). The vault itself is NOT gone: it
#   moved. Its new home is E:\Google\GDrive\GDrive-Second_Brain_PKMS, a
#   Google Drive mirror, and it is mounted on drive X:.
#
# WHAT IT CHECKS NOW:
#   The thing the task actually cares about - that the KV root is reachable
#   AND that X: is mounted on it and really resolves there. A mapping that
#   exists but points somewhere else is a PROBLEM, not a healthy vault.
#   Every check writes a dated line into logs\vault-mount-health.log.
#
# OUTPUT CONTRACT (other scripts read it, do not change it):
#   a line "VAULT_PROBLEMS=<n>" and an exit code of 0 when healthy, 1 when not.
#
# ASCII ONLY: executed by Windows PowerShell 5.1.

[CmdletBinding()]
param(
    [string]$VaultRoot = 'E:\Google\GDrive\GDrive-Second_Brain_PKMS',
    [string]$DriveLetter = 'X',
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

function Get-NormalizedPath {
    param([string]$Path)
    if (-not $Path) { return '' }
    $r = $Path.Trim()
    if ($r.StartsWith('\??\')) { $r = $r.Substring(4) }
    if ($r.StartsWith('\DosDevices\')) { $r = $r.Substring(12) }
    $r = $r.TrimEnd('\')
    if ($r -eq '') { $r = '\' }
    return $r
}

function Get-DosTarget {
    param([string]$Letter)
    if (-not ('KvDosDevice' -as [type])) {
        Add-Type -TypeDefinition 'using System; using System.Text; using System.Runtime.InteropServices; public static class KvDosDevice { [DllImport("kernel32.dll", CharSet=CharSet.Auto, SetLastError=true)] public static extern uint QueryDosDevice(string deviceName, StringBuilder targetPath, int max); }' -ErrorAction SilentlyContinue | Out-Null
    }
    if ('KvDosDevice' -as [type]) {
        $sb = New-Object System.Text.StringBuilder 2048
        $n = [KvDosDevice]::QueryDosDevice(($Letter + ':'), $sb, 2048)
        if ($n -gt 0) { return $sb.ToString() }
        return ''
    }
    $table = & cmd.exe /c subst 2>$null
    foreach ($line in @($table)) {
        if ($line -match ('^' + $Letter + ':\\: => (.+)$')) { return $Matches[1] }
    }
    return ''
}

$problems = 0
$root = Get-NormalizedPath $VaultRoot
$letter = $DriveLetter.TrimEnd(':').ToUpper()
$driveRoot = $letter + ':\'

if (-not (Test-Path -LiteralPath $VaultRoot -PathType Container)) {
    Write-Line ('FAIL KV root not reachable: ' + $VaultRoot)
    $problems++
} else {
    Write-Line ('OK   KV root reachable: ' + $root)
}

if (-not (Test-Path -LiteralPath $driveRoot)) {
    Write-Line ('FAIL drive not mounted: ' + $letter + ':')
    $problems++
} else {
    Write-Line ('OK   drive mounted: ' + $letter + ':')
}

$indexFile = $letter + ':\INDEX CENTRAL.md'
if (-not (Test-Path -LiteralPath $indexFile)) {
    Write-Line ('FAIL missing through the mount: ' + $indexFile)
    $problems++
} else {
    Write-Line ('OK   present through the mount: ' + $indexFile)
}

$inboxDir = $letter + ':\00_Inbox'
if (-not (Test-Path -LiteralPath $inboxDir)) {
    Write-Line ('FAIL missing through the mount: ' + $inboxDir)
    $problems++
} else {
    Write-Line ('OK   present through the mount: ' + $inboxDir)
}

$actual = Get-NormalizedPath (Get-DosTarget $letter)
if ($actual -eq '') {
    Write-Line ('FAIL ' + $letter + ': does not resolve to a known target (expected: ' + $root + ')')
    $problems++
} elseif ($actual -ne $root) {
    Write-Line ('FAIL ' + $letter + ': resolves to ' + $actual + ' - expected: ' + $root)
    $problems++
} else {
    Write-Line ('OK   ' + $letter + ': resolves to the KV root: ' + $actual)
}

if ($problems -gt 0) {
    Write-Line ('VAULT_PROBLEMS=' + $problems)
    exit 1
}

Write-Line 'VAULT_PROBLEMS=0'
exit 0
