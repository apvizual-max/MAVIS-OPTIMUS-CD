# jules-aida-probe.ps1 - finds the doors that actually exist on the internal API.
#
# WHY THIS EXISTS:
#   Measured 2026-10-28: session sessions/3384046284391976636 answers every
#   door we know (:sendMessage x3, :interact x1) and stays
#   AWAITING_USER_FEEDBACK. The answers ARE stored - the internal task has 4
#   userActivity steps - but the agent never resumed: a session that DID
#   release (13310849418551960504) has a devBoxStarted step AFTER its
#   feedback, and this one has none.
#
#   So the missing piece is not "how to send" but "what is it waiting for".
#   Guessing a third door means guessing. This probe enumerates the REAL
#   surface: it dumps the raw task (plan, inProgressWork, agentConfig) and
#   asks the internal API which methods exist, by calling the candidate
#   verbs and reading the HTTP status. A 404 means "no such door"; a 400
#   means "the door exists and wants a different body".
#
#   It only READS on the session it is given, except for the method probe,
#   which is deliberately pointed at a session id that does not exist so a
#   wrong body can never mutate anything.
#
# ASCII ONLY: executed by Windows PowerShell 5.1.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\jules-aida-probe.ps1 -SessionId 3384046284391976636 -DumpRaw "$env:TEMP\aida.json"

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SessionId,
    [string]$DumpRaw = '',
    [switch]$SkipMethodProbe
)

$ErrorActionPreference = 'Continue'

function Get-OAuthToken {
    $credName = 'jules-cli:default'
    try {
        if (-not ('JulesCred2' -as [type])) {
            Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class JulesCred2 {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CREDENTIAL {
        public int Flags; public int Type; public string TargetName; public string Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public int CredentialBlobSize; public IntPtr CredentialBlob; public int Persist;
        public int AttributeCount; public IntPtr Attributes; public string TargetAlias; public string UserName;
    }
    [DllImport("advapi32.dll", EntryPoint = "CredReadW", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool CredRead(string target, int type, int reservedFlag, out IntPtr credentialPtr);
    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern void CredFree(IntPtr credential);
}
"@ -ErrorAction SilentlyContinue | Out-Null
        }
        $ptr = [IntPtr]::Zero
        if (-not [JulesCred2]::CredRead($credName, 1, 0, [ref]$ptr)) { return '' }
        if ($ptr -eq [IntPtr]::Zero) { return '' }
        $c = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptr, [type][JulesCred2+CREDENTIAL])
        $bytes = New-Object byte[] $c.CredentialBlobSize
        [System.Runtime.InteropServices.Marshal]::Copy($c.CredentialBlob, $bytes, 0, $c.CredentialBlobSize) | Out-Null
        [JulesCred2]::CredFree($ptr)
        $parsed = ([System.Text.Encoding]::UTF8.GetString($bytes)) | ConvertFrom-Json
        $token = ''
        $expiry = $null
        if ($parsed.token -and $parsed.token.access_token) {
            $token = [string]$parsed.token.access_token
            if ($parsed.token.expiry) { $expiry = [DateTime]::Parse([string]$parsed.token.expiry) }
        } elseif ($parsed.access_token) {
            $token = [string]$parsed.access_token
            if ($parsed.expiry) { $expiry = [DateTime]::Parse([string]$parsed.expiry) }
        }
        if (-not $token) { return '' }
        if ($expiry -and (Get-Date) -ge $expiry.AddMinutes(-2)) {
            try { $null = & cmd.exe /c 'jules.cmd remote list --repo 2>nul' } catch { }
            return Get-OAuthToken
        }
        return $token
    } catch {
        return ''
    }
}

function Invoke-Probe([string]$url, [string]$method, [string]$oauth, [string]$body) {
    try {
        $headers = @{ Authorization = ('Bearer ' + $oauth) }
        $params = @{ Uri = $url; Headers = $headers; Method = $method; TimeoutSec = 60; UseBasicParsing = $true }
        if ($body) {
            $params['ContentType'] = 'application/json'
            $params['Body'] = $body
        }
        $resp = Invoke-WebRequest @params
        return [pscustomobject]@{ Code = [int]$resp.StatusCode; Text = [string]$resp.Content }
    } catch {
        $code = 0
        $text = ''
        if ($_.Exception.Response) {
            try { $code = [int]$_.Exception.Response.StatusCode } catch { }
            try {
                $stream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $text = $reader.ReadToEnd()
                $reader.Close()
            } catch { }
        } else {
            $text = $_.Exception.Message
        }
        return [pscustomobject]@{ Code = $code; Text = $text }
    }
}

$oauth = Get-OAuthToken
if (-not $oauth) {
    Write-Host 'EROARE: token OAuth absent.'
    exit 2
}
Write-Host ('token OAuth: prezent')

$base = 'https://aida.googleapis.com/v1/swebot/tasks/'
$url = $base + $SessionId

Write-Host ''
Write-Host '=== TASK ==='
$r = Invoke-Probe $url 'GET' $oauth ''
Write-Host ('GET task -> HTTP ' + $r.Code + ' | bytes=' + $r.Text.Length)
if ($r.Code -ne 200) {
    Write-Host $r.Text
    exit 3
}

if ($DumpRaw) {
    try {
        [System.IO.File]::WriteAllText($DumpRaw, $r.Text, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host ('raw scris in ' + $DumpRaw + ' (' + (Get-Item -LiteralPath $DumpRaw).Length + ' bytes)')
    } catch {
        Write-Host ('raw NU s-a putut scrie: ' + $_.Exception.Message)
    }
}

$task = $r.Text | ConvertFrom-Json
Write-Host ('taskStatus          : ' + [string]$task.task.taskStatus)
Write-Host ('swebotTaskStatus    : ' + [string]$task.task.swebotTaskStatus)
Write-Host ('userLastInteractedAt: ' + [string]$task.task.userLastInteractedAt)
Write-Host ('updatedAt           : ' + [string]$task.task.updatedAt)
Write-Host ('inProgressWork      : ' + [string]$task.task.inProgressWork)
Write-Host ('taskAccess          : ' + ($task.task.taskAccess | ConvertTo-Json -Depth 6 -Compress))
Write-Host ('agentConfig         : ' + ($task.task.agentConfig | ConvertTo-Json -Depth 6 -Compress))
Write-Host ('latestPlan          :')
Write-Host ($task.task.latestPlan | ConvertTo-Json -Depth 8)

if (-not $SkipMethodProbe) {
    Write-Host ''
    Write-Host '=== PROBE USI (pe o sesiune inexistenta: 0 - nimic nu se modifica) ==='
    $verbs = @(
        'approvePlan', 'approve', 'reply', 'respond', 'sendMessage', 'interact',
        'cancel', 'stop', 'feedback', 'planApproved', 'confirm', 'resume', 'continue'
    )
    $bodies = @(
        '{}',
        '{"userActivity":{"feedbackGiven":{"feedback":"probe","feedbackId":"00000000-0000-0000-0000-000000000000"},"activityStepId":"00000000"}}',
        '{"approved":true}',
        '{"planApproved":true}'
    )
    foreach ($verb in $verbs) {
        $u = $base + '0000000000000000000:' + $verb
        $line = '{0,-16}' -f $verb
        foreach ($b in $bodies) {
            $res = Invoke-Probe $u 'POST' $oauth $b
            $line += (' {0}={1}' -f $res.Code, ($res.Text -replace '\s+', ' ').Substring(0, [Math]::Min(70, ($res.Text -replace '\s+', ' ').Length)))
            $line += ' |'
        }
        Write-Host $line
    }
}
exit 0
