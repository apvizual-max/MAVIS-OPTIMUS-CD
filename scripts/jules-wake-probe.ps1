# jules-wake-probe.ps1 - measures whether a Jules session actually WOKE UP.
#
# WHY THIS EXISTS:
#   Measured 2026-10-28: session sessions/3384046284391976636 (MAVIS-OPTIMUS-CD)
#   took four answers and stayed AWAITING_USER_FEEDBACK. Comparing it with
#   the two sessions that DID release showed the difference:
#
#     released 13310849418551960504:
#       agentMessaged -> userActivity(no activityStepId) -> devBoxStarted
#     released 7665116565709981265:
#       agentMessaged -> userActivity(no activityStepId) -> devBoxStarted
#     stuck    3384046284391976636:
#       agentMessaged -> userActivity(activityStepId) -> NO devBoxStarted, ever
#
#   The wake signal is a NEW devBoxStarted step: it means the agent took the
#   message and spun its devbox back up. The internal task status does not
#   move for minutes after that. So "the state is still AWAITING" is NOT a
#   verdict - the step list is the verdict, and it is what this script reads.
#
#   It also counts the userActivity steps, because a door can answer the
#   question (the step is recorded) without waking the agent (no devbox).
#   Answered and awake are two different facts.
#
# ASCII ONLY: executed by Windows PowerShell 5.1.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\jules-wake-probe.ps1 -SessionId 2227387981514727588 -Message "..." -WaitSeconds 120

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SessionId,
    [string]$Message = '',
    [string]$MessageFile = '',
    [string]$StepId = '',
    [int]$WaitSeconds = 120,
    [string]$SecretsFile = 'E:\--- System Secrets\JULES - APIs.md'
)

$ErrorActionPreference = 'Continue'

function Get-ApiKey([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return '' }
    foreach ($line in (Get-Content -LiteralPath $path)) {
        $t = $line.Trim()
        if ($t -and $t -notmatch '^#' -and $t -notmatch '^-{2,}$' -and $t -notmatch '^\w+:' -and $t.Length -ge 30) {
            return $t
        }
    }
    return ''
}

function Get-OAuthToken {
    $credName = 'jules-cli:default'
    try {
        if (-not ('JulesCred3' -as [type])) {
            Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class JulesCred3 {
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
        if (-not [JulesCred3]::CredRead($credName, 1, 0, [ref]$ptr)) { return '' }
        if ($ptr -eq [IntPtr]::Zero) { return '' }
        $c = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptr, [type][JulesCred3+CREDENTIAL])
        $bytes = New-Object byte[] $c.CredentialBlobSize
        [System.Runtime.InteropServices.Marshal]::Copy($c.CredentialBlob, $bytes, 0, $c.CredentialBlobSize) | Out-Null
        [JulesCred3]::CredFree($ptr)
        $parsed = ([System.Text.Encoding]::UTF8.GetString($bytes)) | ConvertFrom-Json
        $token = ''
        if ($parsed.token -and $parsed.token.access_token) { $token = [string]$parsed.token.access_token }
        elseif ($parsed.access_token) { $token = [string]$parsed.access_token }
        return $token
    } catch {
        return ''
    }
}

# The internal task is the only place that shows the wake signal, so the
# measurement needs the OAuth token. A missing token means the probe cannot
# measure - and a probe that cannot measure says so instead of guessing.
function Get-TaskSteps([string]$oauth, [string]$id) {
    if (-not $oauth) { return $null }
    try {
        $d = Invoke-RestMethod -Uri ('https://aida.googleapis.com/v1/swebot/tasks/' + $id) -Headers @{ Authorization = ('Bearer ' + $oauth) } -Method Get -TimeoutSec 60
        return @($d.task.activitySteps)
    } catch {
        return $null
    }
}

function Measure-Session([string]$key, [string]$oauth, [string]$id) {
    $steps = Get-TaskSteps $oauth $id
    $devBox = 0
    $userActs = 0
    $agentMsgs = 0
    $pending = ''
    if ($null -ne $steps) {
        foreach ($s in $steps) {
            if ($s.agentActivity.devBoxStarted) { $devBox++ }
            if ($s.agentActivity.agentMessaged) {
                $agentMsgs++
                if ($s.agentActivity.agentMessaged.requiresUserResponse -eq $true) { $pending = [string]$s.id }
            }
            if ($s.userActivity) { $userActs++ }
        }
    }
    $state = 'N/A'
    try {
        $p = Invoke-RestMethod -Uri ('https://jules.googleapis.com/v1alpha/sessions/' + $id) -Headers @{ 'X-Goog-Api-Key' = $key } -Method Get -TimeoutSec 45
        $state = [string]$p.state
    } catch {
        $state = 'NU A RASPUNS'
    }
    return [pscustomobject]@{
        State = $state
        DevBox = $devBox
        UserActs = $userActs
        AgentMsgs = $agentMsgs
        PendingStep = $pending
        Steps = $steps
    }
}

function Show([string]$label, $m) {
    $pend = ''
    if ($m.PendingStep) { $pend = ' pending=' + $m.PendingStep.Substring(0, 8) }
    Write-Host ('  ' + $label.PadRight(26) + 'state=' + $m.State.PadRight(24) + ' devBox=' + $m.DevBox + ' userActs=' + $m.UserActs + ' agentMsgs=' + $m.AgentMsgs + $pend)
}

$key = Get-ApiKey $SecretsFile
if (-not $key) {
    Write-Host ('EROARE: cheia Jules nu a fost gasita in ' + $SecretsFile)
    exit 2
}

# MEASURED 2026-10-28: passing the message inline through -File breaks it.
# PowerShell hands the arguments to powershell.exe as one command line, and a
# message that contains a double quote (the verdict format does:
# "VERDICT: nothing to repair. Checks: ...") truncates the argument and the
# script never starts. So the message is read from a file when one is given.
if ($MessageFile) {
    if (-not (Test-Path -LiteralPath $MessageFile)) {
        Write-Host ('EROARE: fisierul de mesaj nu exista: ' + $MessageFile)
        exit 2
    }
    $Message = Get-Content -LiteralPath $MessageFile -Raw
}
if (-not $Message) {
    Write-Host 'EROARE: nu ai dat nici -Message, nici -MessageFile.'
    exit 2
}

$oauth = Get-OAuthToken
if (-not $oauth) {
    Write-Host 'ATENTIE: token OAuth absent - pasii interni nu pot fi cititi, deci trezirea nu poate fi masurata.'
}

Write-Host ('=== SESSIUNE ' + $SessionId + ' ===')
$before = Measure-Session $key $oauth $SessionId
Show 'INAINTE' $before

if ($Message) {
    Write-Host ''
    Write-Host 'TRIMITE sendMessage...'
    $body = @{ prompt = $Message } | ConvertTo-Json -Depth 5
    $tmp = Join-Path $env:TEMP ('jules-wake-' + [guid]::NewGuid().ToString('N') + '.json')
    try {
        [System.IO.File]::WriteAllText($tmp, $body, (New-Object System.Text.UTF8Encoding($false)))
        Invoke-RestMethod -Uri ('https://jules.googleapis.com/v1alpha/sessions/' + $SessionId + ':sendMessage') -Headers @{ 'X-Goog-Api-Key' = $key; 'Content-Type' = 'application/json' } -Method Post -Body ([System.IO.File]::ReadAllBytes($tmp)) -TimeoutSec 60 | Out-Null
        Write-Host '  sendMessage: trimis'
    } catch {
        Write-Host ('  sendMessage: EROARE - ' + $_.Exception.Message)
    }
}

if ($StepId) {
    Write-Host 'TRIMITE interact...'
    $obody = @{
        userActivity = @{
            feedbackGiven = @{ feedback = $Message; feedbackId = [Guid]::NewGuid().ToString().ToUpper() }
            activityStepId = $StepId
        }
    } | ConvertTo-Json -Depth 6
    $otmp = Join-Path $env:TEMP ('jules-wake-i-' + [guid]::NewGuid().ToString('N') + '.json')
    try {
        [System.IO.File]::WriteAllText($otmp, $obody, (New-Object System.Text.UTF8Encoding($false)))
        Invoke-RestMethod -Uri ('https://aida.googleapis.com/v1/swebot/tasks/' + $SessionId + ':interact') -Headers @{ Authorization = ('Bearer ' + $oauth); 'Content-Type' = 'application/json' } -Method Post -Body ([System.IO.File]::ReadAllBytes($otmp)) -TimeoutSec 60 | Out-Null
        Write-Host '  interact: trimis'
    } catch {
        Write-Host ('  interact: EROARE - ' + $_.Exception.Message)
    }
}

Write-Host ''
Write-Host ('astept ' + $WaitSeconds + 's ...')
$woke = $false
$deadline = (Get-Date).AddSeconds($WaitSeconds)
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 15
    $now = Measure-Session $key $oauth $SessionId
    Show (Get-Date -Format 'HH:mm:ss') $now
    if ($now.DevBox -gt $before.DevBox) {
        Write-Host ''
        Write-Host '*** TREZIT: a aparut un devBoxStarted nou. Agentul a preluat mesajul. ***'
        $woke = $true
        break
    }
    if ($now.State -ne 'AWAITING_USER_FEEDBACK' -and $now.State -ne 'NU A RASPUNS') {
        Write-Host ''
        Write-Host ('*** STARE SCHIMBATA: ' + $now.State + ' ***')
        $woke = $true
        break
    }
}

if (-not $woke) {
    Write-Host ''
    Write-Host 'VERDICT: nu s-a trezit. Pasul intalnirii ramane fara devBoxStarted nou.'
}
exit 0
