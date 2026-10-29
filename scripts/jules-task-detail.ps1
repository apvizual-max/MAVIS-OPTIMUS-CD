# jules-task-detail.ps1
# Dumps the INTERNAL task fields of a Jules session that the public API does
# not expose: latestPlan, inProgressWork, taskStatus, suggestedTitle.
#
# MEASURED 2026-10-29: the public state lagged behind the truth by minutes
# (a session was visibly active while the public "updated" field was 16
# minutes old), so the internal fields are the ones worth reading when the
# question is "is it working or is it stuck".
#
# Usage:
#   powershell -NoProfile -File jules-task-detail.ps1 -SessionId 5402382992082227353
#
# ASCII ONLY: executed by Windows PowerShell 5.1.

[CmdletBinding()]
param(
    [string]$SessionId = ''
)

$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class NativeCred {
    [DllImport("advapi32.dll", EntryPoint = "CredReadW", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool CredRead(string target, int type, int reservedFlag, out IntPtr credentialPtr);
    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern void CredFree(IntPtr cred);
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CREDENTIAL {
        public int Flags; public int Type; public string TargetName; public string Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public int CredentialBlobSize; public IntPtr CredentialBlob; public int Persist;
        public int AttributeCount; public IntPtr Attributes; public string TargetAlias; public string UserName;
    }
    public static string GetPassword(string target) {
        IntPtr credPtr;
        if (CredRead(target, 1, 0, out credPtr)) {
            CREDENTIAL cred = (CREDENTIAL)Marshal.PtrToStructure(credPtr, typeof(CREDENTIAL));
            byte[] passwordBytes = new byte[cred.CredentialBlobSize];
            Marshal.Copy(cred.CredentialBlob, passwordBytes, 0, cred.CredentialBlobSize);
            CredFree(credPtr);
            return Encoding.UTF8.GetString(passwordBytes);
        }
        return null;
    }
}
"@

function Get-JulesToken {
    # The blob is UTF-8 bytes copied into a byte array. Reading it with
    # PtrToStringAuto instead produced a mangled string that was not valid
    # JSON - the same extraction the daemon uses is the one that works.
    $tokenJson = [NativeCred]::GetPassword('jules-cli:default')
    if (-not $tokenJson) { return '' }
    try {
        $parsed = $tokenJson | ConvertFrom-Json
        if ($parsed.token.access_token) { return [string]$parsed.token.access_token }
        if ($parsed.access_token) { return [string]$parsed.access_token }
        return ''
    } catch { return '' }
}

if (-not $SessionId) { Write-Output 'EROARE: -SessionId lipseste'; exit 2 }

$tok = Get-JulesToken
if (-not $tok) {
    Write-Output 'Refreshing the OAuth token...'
    $null = cmd.exe /c 'jules.cmd remote list --repo 2>nul'
    $tok = Get-JulesToken
}
if (-not $tok) { Write-Output 'EROARE: tokenul OAuth Jules nu a putut fi obtinut'; exit 2 }

$h = @{ 'Authorization' = 'Bearer ' + $tok }
$task = Invoke-RestMethod -Uri ('https://aida.googleapis.com/v1/swebot/tasks/' + $SessionId) -Method Get -Headers $h -TimeoutSec 60
$t = $task.task

Write-Output ('TASK ' + $SessionId)
Write-Output ('  taskStatus        = ' + $t.taskStatus)
Write-Output ('  swebotTaskStatus  = ' + $t.swebotTaskStatus)
Write-Output ('  suggestedTitle    = ' + $t.suggestedTitle)
Write-Output ('  userLastInteractedAt = ' + $t.userLastInteractedAt)
Write-Output ('  activitySteps     = ' + @($t.activitySteps).Count)
Write-Output ''
Write-Output '  --- latestPlan ---'
if ($t.latestPlan) {
    $p = $t.latestPlan
    Write-Output ('    planId  = ' + $p.planId)
    Write-Output ('    state   = ' + $p.state)
    if ($p.steps) {
        foreach ($s in @($p.steps)) { Write-Output ('    step: ' + $s.description) }
    } else {
        Write-Output ('    (campuri: ' + (($p.PSObject.Properties | ForEach-Object { $_.Name }) -join ', ') + ')')
    }
} else { Write-Output '    (niciun plan)' }
Write-Output ''
Write-Output '  --- inProgressWork ---'
if ($t.inProgressWork) {
    $w = $t.inProgressWork
    Write-Output ('    (campuri: ' + (($w.PSObject.Properties | ForEach-Object { $_.Name }) -join ', ') + ')')
    foreach ($pp in $w.PSObject.Properties) {
        $v = $pp.Value
        if ($v -is [string] -and $v.Length -gt 400) { $v = $v.Substring(0, 400) + '...' }
        Write-Output ('    ' + $pp.Name + ' = ' + $v)
    }
} else { Write-Output '    (nicio lucru in desfasurare)' }
Write-Output ''
Write-Output '  --- ultimii pasi ---'
$steps = @($t.activitySteps)
$start = [Math]::Max(0, $steps.Count - 10)
for ($i = $start; $i -lt $steps.Count; $i++) {
    $st = $steps[$i]
    # MEASURED 2026-10-29: the aida shape nests the activity kind as an
    # OBJECT (agentActivity.devBoxStarted = { ... }), not as a boolean. A
    # detector that looked for $true printed empty kinds and hid what the
    # agent was actually doing.
    $kinds = @()
    foreach ($pp in $st.PSObject.Properties) {
        if ($null -eq $pp.Value) { continue }
        if ($pp.Value -is [string]) { continue }
        $inner = @($pp.Value.PSObject.Properties | ForEach-Object { $_.Name })
        if ($inner.Count -gt 0) { $kinds += ($pp.Name + ': ' + ($inner -join ',')) }
    }
    Write-Output ('    [' + $i + '] ' + $st.id + '  ' + ($kinds -join ' | '))
}
exit 0
