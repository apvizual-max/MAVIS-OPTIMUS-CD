# jules-third-door.ps1 - tests the doors that were NOT tried yet.
#
# WHY THIS EXISTS:
#   Measured 2026-10-28: the CD session 3384046284391976636 and the clean
#   SENTINEL session 2227387981514727588 both took a :sendMessage and neither
#   woke up (no new devBoxStarted). So the wake is not about the order of the
#   two known doors - it is about a door we have not found.
#
#   The verb probe found the candidates and the server named them:
#     - aida /v1/swebot/tasks/{id}:resume  -> exists, but rejects the
#       :interact body ("Unknown name userActivity"). Its own body is unknown.
#     - public /v1alpha/sessions/{id}:approvePlan -> the method EXISTS
#       (google.labs.jules.v1alpha.JulesService.ApprovePlan). Our earlier 404
#       was measured with the API key; the error says the method wants OAuth.
#
#   So this script tries, in order, on ONE real session and measures after
#   each: does a new devBoxStarted appear? The wake signal is read from the
#   step list, not from the task state, because the state does not move for
#   minutes after the agent wakes up.
#
# ASCII ONLY: executed by Windows PowerShell 5.1.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SessionId,
    [string]$Exclude = '',
    [int]$WaitSeconds = 90,
    [string]$SecretsFile = 'E:\--- System Secrets\JULES - APIs.md'
)

$ErrorActionPreference = 'Continue'

function Get-ApiKey([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return '' }
    foreach ($line in (Get-Content -LiteralPath $path)) {
        $t = $line.Trim()
        if ($t -and $t -notmatch '^#' -and $t -notmatch '^-{2,}$' -and $t -notmatch '^\w+:' -and $t.Length -ge 30) { return $t }
    }
    return ''
}

function Get-OAuthToken {
    try {
        if (-not ('JulesCred5' -as [type])) {
            Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class JulesCred5 {
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
        if (-not [JulesCred5]::CredRead('jules-cli:default', 1, 0, [ref]$ptr)) { return '' }
        if ($ptr -eq [IntPtr]::Zero) { return '' }
        $c = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptr, [type][JulesCred5+CREDENTIAL])
        $bytes = New-Object byte[] $c.CredentialBlobSize
        [System.Runtime.InteropServices.Marshal]::Copy($c.CredentialBlob, $bytes, 0, $c.CredentialBlobSize) | Out-Null
        [JulesCred5]::CredFree($ptr)
        $parsed = ([System.Text.Encoding]::UTF8.GetString($bytes)) | ConvertFrom-Json
        if ($parsed.token -and $parsed.token.access_token) { return [string]$parsed.token.access_token }
        if ($parsed.access_token) { return [string]$parsed.access_token }
        return ''
    } catch {
        return ''
    }
}

function Get-Signature([string]$oauth, [string]$id) {
    try {
        $d = Invoke-RestMethod -Uri ('https://aida.googleapis.com/v1/swebot/tasks/' + $id) -Headers @{ Authorization = ('Bearer ' + $oauth) } -Method Get -TimeoutSec 60
        $steps = @($d.task.activitySteps)
        $dev = 0
        $user = 0
        $agent = 0
        $pending = ''
        foreach ($s in $steps) {
            if ($s.agentActivity.devBoxStarted) { $dev++ }
            if ($s.agentActivity.agentMessaged) {
                $agent++
                if ($s.agentActivity.agentMessaged.requiresUserResponse -eq $true) { $pending = [string]$s.id }
            }
            if ($s.userActivity) { $user++ }
        }
        return [pscustomobject]@{ Dev = $dev; User = $user; Agent = $agent; Steps = $steps.Count; Pending = $pending; Status = [string]$d.task.taskStatus; Swebot = [string]$d.task.swebotTaskStatus }
    } catch {
        return $null
    }
}

function Invoke-Door([string]$url, [string]$method, [hashtable]$headers, [string]$body) {
    try {
        $params = @{ Uri = $url; Headers = $headers; Method = $method; TimeoutSec = 60; UseBasicParsing = $true }
        if ($body) { $params['ContentType'] = 'application/json'; $params['Body'] = $body }
        $resp = Invoke-WebRequest @params
        return [pscustomobject]@{ Code = [int]$resp.StatusCode; Text = [string]$resp.Content }
    } catch {
        $code = 0
        $text = ''
        if ($_.Exception.Response) {
            try { $code = [int]$_.Exception.Response.StatusCode } catch { }
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $text = $reader.ReadToEnd()
                $reader.Close()
            } catch { }
        } else { $text = $_.Exception.Message }
        return [pscustomobject]@{ Code = $code; Text = $text }
    }
}

function Show([string]$label, $sig) {
    if ($null -eq $sig) { Write-Host ('  ' + $label.PadRight(30) + 'NU A RASPUNS'); return }
    Write-Host ('  ' + $label.PadRight(30) + 'status=' + $sig.Status.PadRight(18) + ' swebot=' + $sig.Swebot.PadRight(38) + ' dev=' + $sig.Dev + ' user=' + $sig.User + ' steps=' + $sig.Steps)
}

$key = Get-ApiKey $SecretsFile
$oauth = Get-OAuthToken
if (-not $oauth) { Write-Host 'EROARE: token OAuth absent.'; exit 2 }

if ($Exclude -and $SessionId -eq $Exclude) {
    Write-Host ('Sesiune exclusa intentionat: ' + $SessionId)
    exit 0
}

Write-Host ('=== SESSIUNE ' + $SessionId + ' - caut a treia usa ===')
$before = Get-Signature $oauth $SessionId
Show 'INAINTE' $before
if ($null -eq $before) { Write-Host 'EROARE: pasii interni nu pot fi cititi.'; exit 3 }

# --- door 1: public approvePlan with OAuth (the API key is blocked for it) ---
Write-Host ''
Write-Host 'USA 1: public /v1alpha/sessions/{id}:approvePlan  cu OAuth'
$b1 = @{ Authorization = ('Bearer ' + $oauth); 'Content-Type' = 'application/json' }
foreach ($body in @('{}', '{"approved":true}')) {
    $r = Invoke-Door ('https://jules.googleapis.com/v1alpha/sessions/' + $SessionId + ':approvePlan') 'POST' $b1 $body
    Write-Host ('  corp=' + $body + ' -> HTTP ' + $r.Code + '  ' + (($r.Text -replace '\s+', ' ').Substring(0, [Math]::Min(160, ($r.Text -replace '\s+', ' ').Length))))
}

# --- door 2: aida resume, empty body ---
Write-Host ''
Write-Host 'USA 2: aida /v1/swebot/tasks/{id}:resume  cu corp {}'
$b2 = @{ Authorization = ('Bearer ' + $oauth); 'Content-Type' = 'application/json' }
$r2 = Invoke-Door ('https://aida.googleapis.com/v1/swebot/tasks/' + $SessionId + ':resume') 'POST' $b2 '{}'
Write-Host ('  HTTP ' + $r2.Code + '  ' + (($r2.Text -replace '\s+', ' ').Substring(0, [Math]::Min(300, ($r2.Text -replace '\s+', ' ').Length))))

# --- door 3: aida resume with a body that mirrors the interact shape ---
if ($r2.Code -eq 400) {
    Write-Host ''
    Write-Host 'USA 3: aida :resume cu corp care contine activitate de utilizator'
    foreach ($body in @(
        '{"feedback":{"feedback":"continua","feedbackId":"00000000-0000-0000-0000-000000000000"}}',
        '{"message":"continua"}',
        '{"agentActivity":{}}'
    )) {
        $r3 = Invoke-Door ('https://aida.googleapis.com/v1/swebot/tasks/' + $SessionId + ':resume') 'POST' $b2 $body
        $short = ($r3.Text -replace '\s+', ' ')
        Write-Host ('  corp=' + $body.Substring(0, [Math]::Min(60, $body.Length)) + ' -> HTTP ' + $r3.Code + '  ' + $short.Substring(0, [Math]::Min(220, $short.Length)))
    }
}

# --- measure ---
Write-Host ''
Write-Host ('astept ' + $WaitSeconds + 's dupa usi ...')
$deadline = (Get-Date).AddSeconds($WaitSeconds)
$woke = $false
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 15
    $now = Get-Signature $oauth $SessionId
    Show (Get-Date -Format 'HH:mm:ss') $now
    if ($null -ne $now) {
        if ($now.Dev -gt $before.Dev) {
            Write-Host ''
            Write-Host '*** TREZIT: devBoxStarted nou. ***'
            $woke = $true
            break
        }
        if ($now.Status -ne 'AWAITING_USER_FEEDBACK' -and $now.Status -ne $before.Status) {
            Write-Host ''
            Write-Host ('*** STARE SCHIMBATA: ' + $now.Status + ' ***')
            $woke = $true
            break
        }
    }
}
if (-not $woke) { Write-Host ''; Write-Host 'VERDICT: nicio usa noua nu a trezit agentul.' }
exit 0
