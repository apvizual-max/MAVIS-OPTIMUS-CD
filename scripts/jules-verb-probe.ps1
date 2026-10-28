# jules-verb-probe.ps1 - reads the FULL error text of the internal API.
#
# WHY THIS EXISTS:
#   Measured 2026-10-28: the CD session 3384046284391976636 took five answers
#   (three :interact, two :sendMessage) and never woke up - the internal task
#   still shows devBox=1 while the released sessions show a NEW devBoxStarted
#   right after the user message. So neither door wakes it.
#
#   The earlier verb probe used a truncated error body, which hid the one
#   thing the server was telling us. Google APIs answer 400 with a full
#   message that names the expected payload ("Invalid JSON payload received.
#   Use ... to ..."). Truncating it to 70 characters threw that away.
#
#   This probe prints the FULL body, and it probes against a task id that
#   cannot exist, so nothing can be mutated while we read the schema.
#
# ASCII ONLY: executed by Windows PowerShell 5.1.

[CmdletBinding()]
param(
    [string]$SessionId = '',
    [string]$SecretsFile = 'E:\--- System Secrets\JULES - APIs.md'
)

$ErrorActionPreference = 'Continue'

function Get-OAuthToken {
    try {
        if (-not ('JulesCred4' -as [type])) {
            Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class JulesCred4 {
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
        if (-not [JulesCred4]::CredRead('jules-cli:default', 1, 0, [ref]$ptr)) { return '' }
        if ($ptr -eq [IntPtr]::Zero) { return '' }
        $c = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptr, [type][JulesCred4+CREDENTIAL])
        $bytes = New-Object byte[] $c.CredentialBlobSize
        [System.Runtime.InteropServices.Marshal]::Copy($c.CredentialBlob, $bytes, 0, $c.CredentialBlobSize) | Out-Null
        [JulesCred4]::CredFree($ptr)
        $parsed = ([System.Text.Encoding]::UTF8.GetString($bytes)) | ConvertFrom-Json
        if ($parsed.token -and $parsed.token.access_token) { return [string]$parsed.token.access_token }
        if ($parsed.access_token) { return [string]$parsed.access_token }
        return ''
    } catch {
        return ''
    }
}

function Invoke-Verb([string]$url, [string]$method, [string]$oauth, [string]$body) {
    try {
        $headers = @{ Authorization = ('Bearer ' + $oauth) }
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

$oauth = Get-OAuthToken
if (-not $oauth) { Write-Host 'EROARE: token OAuth absent.'; exit 2 }

$base = 'https://aida.googleapis.com/v1/swebot/tasks/'
$fake = '0000000000000000000'

Write-Host '=== CORPURI COMPLETE, pe o sarcina inexistenta (nimic nu se modifica) ==='
$tests = @(
    @{ Verb = 'interact'; Body = '{"approved":true}' },
    @{ Verb = 'interact'; Body = '{}' },
    @{ Verb = 'resume';  Body = '{}' },
    @{ Verb = 'resume';  Body = '{"approved":true}' },
    @{ Verb = 'resume';  Body = '{"userActivity":{"feedbackGiven":{"feedback":"x","feedbackId":"00000000-0000-0000-0000-000000000000"},"activityStepId":"00000000"}}' }
)
foreach ($t in $tests) {
    $r = Invoke-Verb ($base + $fake + ':' + $t.Verb) 'POST' $oauth $t.Body
    Write-Host ''
    Write-Host ('--- :' + $t.Verb + '  body=' + $t.Body)
    Write-Host ('    HTTP ' + $r.Code)
    Write-Host ('    ' + $r.Text)
}

Write-Host ''
Write-Host '=== VERBURI PE API-UL PUBLIC (jules.googleapis.com) ==='
$keyFile = $SecretsFile
$key = ''
if (Test-Path -LiteralPath $keyFile) {
    foreach ($line in (Get-Content -LiteralPath $keyFile)) {
        $t = $line.Trim()
        if ($t -and $t -notmatch '^#' -and $t -notmatch '^-{2,}$' -and $t -notmatch '^\w+:' -and $t.Length -ge 30) { $key = $t; break }
    }
}
if (-not $key) { Write-Host 'cheie API absenta'; exit 3 }
$pubVerbs = @('sendMessage', 'approvePlan', 'resume', 'continue', 'cancel', 'respond', 'feedback')
foreach ($v in $pubVerbs) {
    $r = Invoke-Verb ('https://jules.googleapis.com/v1alpha/sessions/' + $fake + ':' + $v) 'POST' $key ('{"prompt":"x"}')
    Write-Host ('  :' + $v.PadRight(14) + 'HTTP ' + $r.Code + '  ' + ($r.Text -replace '\s+', ' '))
}
exit 0
