# mount-kv.ps1 - mounts the PKMS KV vault on a separate drive letter (X:).
#
# WHAT THIS REPLACES:
#   The scheduled task OPTIMUS_mount_KV used to run
#   E:\CLAUDE\OPTIMUS_Knoledge_Vault\mount-kv.bat, the launcher of the retired
#   Central Obsidian Knoledge Vault. Measured 2026-10-28: E:\CLAUDE does not
#   exist any more, so the task failed with result 1 at every trigger
#   (boot, logon, session state change).
#
# WHAT IT DOES NOW:
#   Mounts the PKMS KV root (a Google Drive mirror) on drive X: and VERIFIES
#   the mapping by measurement, never by assumption:
#     - X: resolves
#     - X:\INDEX CENTRAL.md exists
#     - X:\00_Inbox exists
#     - the resolved target of X: is the KV root, string for string
#   A mapping that exists but points somewhere else is a FAILURE (exit 2).
#
# MECHANISM ORDER (probed on this machine on 2026-10-28, not guessed):
#   1. Directory junction at X: (New-Item -ItemType Junction, then mklink /J).
#      A junction is machine wide, but it needs an existing parent path and a
#      drive root has no parent. Measured: "Cannot find drive. A drive with
#      the name 'X' does not exist." and mklink /J: "The system cannot find
#      the path specified." Elevation does not change that.
#   2. DefineDosDevice with DDD_NO_BROADCAST_SYSTEM - a global DOS device.
#      Measured: created WITHOUT elevation (returned True) and seen from
#      session 0 (where the scheduled task runs) AND from the console
#      session 1. This is the mechanism that satisfies "visible to every
#      process on the machine".
#   3. subst X: "<KV root>" - the fallback. Measured to work without
#      elevation, but subst is SESSION scoped: the mapping is visible only to
#      the processes of the session that created it. Measured 2026-10-28: the
#      task ran green and X: did NOT exist in the console session.
#      The global device of step 2 is what makes X: work everywhere.
#
# USAGE (unattended, no prompt, no credential):
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\mount-kv.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\mount-kv.ps1 -Unmount
#
# EXIT CODES:
#   0 = mounted and verified (or already mounted and verified)
#   1 = the KV root itself is not reachable
#   2 = a mapping exists on the drive letter but points somewhere else
#   3 = no mapping could be created, or the mapping failed verification
#
# ASCII ONLY: executed by Windows PowerShell 5.1.

[CmdletBinding()]
param(
    [string]$KvRoot = 'E:\Google\GDrive\GDrive-Second_Brain_PKMS',
    [string]$DriveLetter = 'X',
    [string]$LogFile = '',
    [switch]$Unmount
)

$ErrorActionPreference = 'Continue'
$script:KvCreatedKind = ''

if (-not $LogFile) {
    $LogFile = Join-Path (Split-Path -Parent $PSScriptRoot) 'logs\mount-kv.log'
}
$script:KvLogPath = $LogFile
try {
    $logDir = Split-Path -Parent $LogFile
    if (-not (Test-Path -LiteralPath $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
} catch {
    $script:KvLogPath = ''
}

$script:KvLogWriteFailures = 0
function Write-KvOut {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Message)
    [Console]::Out.WriteLine($Message)
    if ($script:KvLogPath) {
        # MEASURED 2026-10-29: the empty catch here DISCARDED the entry on a
        # write failure ("used by another process"). This log is the mount
        # record - the thing that explains WHY the vault was not mounted.
        # Retry, then count the loss. Same idiom as jules-lib.ps1.
        $line = '[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] [session ' + (Get-Process -Id $PID).SessionId + '] ' + $Message
        $written = $false
        for ($attempt = 1; $attempt -le 5 -and -not $written; $attempt++) {
            try {
                Add-Content -LiteralPath $script:KvLogPath -Value $line -Encoding UTF8 -ErrorAction Stop
                $written = $true
            } catch {
                Start-Sleep -Milliseconds (250 * [math]::Pow(2, $attempt - 1))
            }
        }
        if (-not $written) { $script:KvLogWriteFailures++ }
    }
}

function Initialize-KvType {
    if (-not ('KvDosDevice' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;

public static class KvDosDevice
{
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern uint QueryDosDevice(string deviceName, StringBuilder targetPath, int max);

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern bool DefineDosDevice(uint flags, string deviceName, string targetPath);
}
'@ -ErrorAction SilentlyContinue | Out-Null
    }
    return ('KvDosDevice' -as [type]) -ne $null
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
    if (-not (Initialize-KvType)) { return '' }
    $sb = New-Object System.Text.StringBuilder 2048
    $n = [KvDosDevice]::QueryDosDevice(($Letter + ':'), $sb, 2048)
    if ($n -gt 0) { return $sb.ToString() }
    return ''
}

function Set-GlobalDosDevice {
    param([string]$Letter, [string]$Target)
    if (-not (Initialize-KvType)) { return $false }
    $flags = 0x8
    $ok = [KvDosDevice]::DefineDosDevice($flags, ($Letter + ':'), ('\??\' + $Target))
    if (-not $ok) {
        $err = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Write-KvOut ('INFO DefineDosDevice failed (Win32 ' + $err + ')')
        return $false
    }
    return $true
}

function Remove-GlobalDosDevice {
    param([string]$Letter, [string]$Target)
    if (-not (Initialize-KvType)) { return $false }
    # Measured 2026-10-28: the removal needs the SAME target path.
    # DefineDosDevice(0x2, "X:", NULL) fails with Win32 123.
    $flags = 0x2
    $ok = [KvDosDevice]::DefineDosDevice($flags, ($Letter + ':'), ('\??\' + $Target))
    return $ok
}

function Test-SubstEntry {
    param([string]$Letter)
    $table = & cmd.exe /c subst 2>$null
    foreach ($line in @($table)) {
        if ($line -match ('^' + $Letter + ':\\: => (.+)$')) { return $true }
    }
    return $false
}

function Get-MappingInfo {
    param([string]$Letter)
    $driveRoot = $Letter + ':\'
    $info = [pscustomobject]@{ Exists = $false; Kind = 'none'; Target = '' }

    if (Test-Path -LiteralPath $driveRoot) {
        $info.Exists = $true
        try {
            $item = Get-Item -LiteralPath $driveRoot -Force -ErrorAction Stop
            if ($item.LinkType) {
                $info.Kind = [string]$item.LinkType
                $targets = @($item.Target)
                if ($targets.Count -gt 0) { $info.Target = Get-NormalizedPath ([string]$targets[0]) }
            }
        } catch {
            $info.Kind = 'unknown'
        }
    }

    $dos = Get-DosTarget $Letter
    if ($dos) {
        $info.Exists = $true
        if ($info.Target -eq '') {
            # A subst and a global DOS device look identical through
            # QueryDosDevice, so the kind is only asserted when this script
            # created the mapping itself. Otherwise it stays 'mapped'.
            if ($script:KvCreatedKind) { $info.Kind = $script:KvCreatedKind } else { $info.Kind = 'mapped' }
            $info.Target = Get-NormalizedPath $dos
        }
    }
    return $info
}

function Get-MountChecks {
    param([string]$Letter, [string]$Expected)
    $list = New-Object System.Collections.ArrayList
    $driveRoot = $Letter + ':\'

    $resolves = Test-Path -LiteralPath $driveRoot
    $null = $list.Add([pscustomobject]@{ Name = 'drive root resolves'; Ok = $resolves; Detail = $driveRoot })

    $indexFile = $Letter + ':\INDEX CENTRAL.md'
    $hasIndex = Test-Path -LiteralPath $indexFile
    $null = $list.Add([pscustomobject]@{ Name = 'INDEX CENTRAL.md present'; Ok = $hasIndex; Detail = $indexFile })

    $inboxDir = $Letter + ':\00_Inbox'
    $hasInbox = Test-Path -LiteralPath $inboxDir
    $null = $list.Add([pscustomobject]@{ Name = '00_Inbox present'; Ok = $hasInbox; Detail = $inboxDir })

    $info = Get-MappingInfo $Letter
    $targetOk = ($info.Target -eq $Expected)
    $null = $list.Add([pscustomobject]@{ Name = 'resolves to the KV root'; Ok = $targetOk; Detail = ('actual=' + $info.Target + ' expected=' + $Expected) })

    return $list
}

function Write-Checks {
    param($Checks)
    foreach ($c in $Checks) {
        $tag = 'FAIL'
        if ($c.Ok) { $tag = 'OK  ' }
        Write-KvOut ($tag + ' ' + $c.Name + ' - ' + $c.Detail)
    }
}

function Get-VerdictCode {
    param($Checks)
    foreach ($c in $Checks) {
        if ($c.Name -eq 'resolves to the KV root' -and -not $c.Ok) { return 2 }
    }
    foreach ($c in $Checks) {
        if (-not $c.Ok) { return 3 }
    }
    return 0
}

$root = Get-NormalizedPath $KvRoot
$letter = $DriveLetter.TrimEnd(':').ToUpper()

Write-KvOut ('mount-kv: KV root   = ' + $root)
Write-KvOut ('mount-kv: drive     = ' + $letter + ':')
Write-KvOut ('mount-kv: session   = ' + (Get-Process -Id $PID).SessionId)

if (-not (Test-Path -LiteralPath $KvRoot -PathType Container)) {
    Write-KvOut ('FAIL KV root not reachable: ' + $KvRoot)
    exit 1
}

if ($Unmount) {
    $info = Get-MappingInfo $letter
    if (-not $info.Exists) {
        Write-KvOut ('NOOP no mapping on ' + $letter + ': - nothing to unmount')
        exit 0
    }
    if ($info.Target -ne $root) {
        Write-KvOut ('SKIP mapping on ' + $letter + ': points to ' + $info.Target + ' - not the KV root, left untouched')
        exit 0
    }
    # Both removal paths are tried: subst for a session scoped mapping, and
    # DefineDosDevice for a global one. Measured 2026-10-28: "subst X: /D"
    # answers "Invalid parameter - X:" for a global device, and
    # DefineDosDevice(DDD_REMOVE_DEFINITION, "X:", NULL) answers Win32 123,
    # so the removal needs the same target path that was used to create it.
    & cmd.exe /c ('subst {0}: /D' -f $letter) 2>&1 | Out-Null
    $after = Get-MappingInfo $letter
    if ($after.Exists) {
        $null = Remove-GlobalDosDevice $letter $root
        $after = Get-MappingInfo $letter
    }
    if ($after.Exists) {
        Write-KvOut ('FAIL could not remove the mapping on ' + $letter + ':')
        exit 3
    }
    Write-KvOut ('OK   mapping on ' + $letter + ': removed - nothing inside the KV was touched')
    exit 0
}

$existing = Get-MappingInfo $letter
$junctionError = ''
if ($existing.Exists) {
    if ($existing.Target -eq $root) {
        Write-KvOut ('OK   ' + $letter + ': is already mapped to the KV root (kind=' + $existing.Kind + ')')
    } else {
        Write-KvOut ('FAIL a mapping already exists on ' + $letter + ': and points to ' + $existing.Target)
        Write-KvOut ('FAIL expected: ' + $root + ' - refusing to touch a mapping that is not the KV root')
        exit 2
    }
} else {
    Write-KvOut ('STEP 1/3 trying a directory junction at ' + $letter + ':\ (machine wide, needs a parent path)')
    try {
        $null = New-Item -ItemType Junction -Path ($letter + ':\') -Target $KvRoot -ErrorAction Stop
        Write-KvOut ('OK   junction created at ' + $letter + ':\')
    } catch {
        $junctionError = $_.Exception.Message
        Write-KvOut ('INFO junction via New-Item failed: ' + $junctionError)
        $mk = & cmd.exe /c ('mklink /J {0}:\ "{1}"' -f $letter, $KvRoot) 2>&1
        $mkText = (@($mk) | ForEach-Object { [string]$_ }) -join ' '
        if ($mkText.Trim().Length -gt 0) { Write-KvOut ('INFO junction via mklink: ' + $mkText.Trim()) }
    }

    $afterJunction = Get-MappingInfo $letter
    if (-not $afterJunction.Exists) {
        Write-KvOut ('STEP 2/3 creating the global DOS device (measured to work without elevation, visible in every session)')
        if (Set-GlobalDosDevice $letter $KvRoot) {
            $script:KvCreatedKind = 'global-device'
        }
    }

    $afterDevice = Get-MappingInfo $letter
    if (-not $afterDevice.Exists) {
        Write-KvOut ('STEP 3/3 falling back to subst ' + $letter + ': "' + $KvRoot + '" (session scoped)')
        & cmd.exe /c ('subst {0}: "{1}"' -f $letter, $KvRoot) 2>&1 | Out-Null
        $script:KvCreatedKind = 'subst'
    }
}

$checks = Get-MountChecks $letter $root
Write-Checks $checks
$code = Get-VerdictCode $checks
if ($code -eq 0) {
    $final = Get-MappingInfo $letter
    Write-KvOut ('VERDICT MOUNTED - ' + $letter + ': is the PKMS KV root (kind=' + $final.Kind + ', verified)')
    if ($final.Kind -eq 'subst') {
        Write-KvOut 'WARNING subst is session scoped - this mapping is visible only in this session'
    } elseif ($final.Kind -eq 'global-device') {
        Write-KvOut 'OK   the mapping is a global DOS device - visible to every session of this machine'
    } else {
        Write-KvOut 'OK   the mapping resolves to the KV root from this session'
    }
    exit 0
}

Write-KvOut ('VERDICT FAILED - ' + $letter + ': could not be mounted and verified as the KV root')
if ($junctionError) {
    Write-KvOut ('REASON junction at a drive root needs a parent path that does not exist: ' + $junctionError)
}
Write-KvOut ('REASON expected target: ' + $root)
exit $code
