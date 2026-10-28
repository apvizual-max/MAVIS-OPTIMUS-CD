# jules-session-diag.ps1 - shows exactly why a Jules session is blocked.
#
# WHY THIS EXISTS:
#   Measured 2026-10-28: session sessions/3384046284391976636 (MAVIS-OPTIMUS-CD)
#   answered every door we have - POST :sendMessage three times and
#   POST :interact on the pending step - and the state still reads
#   AWAITING_USER_FEEDBACK. The answers ARE recorded (4 userActivity steps in
#   the internal task), so the door is not the problem: the WAIT is.
#
#   Guessing at a third door without knowing what the wait actually is is
#   how the session stayed blocked. This script prints the real structure:
#   the internal task status, every activity step with its index, the kind of
#   activity it carries, and whether it waits for a user response. Then the
#   blocked wait can be compared with a session that DID release.
#
#   It prints, it does not write. It is a measuring instrument, not a repair.
#
# ASCII ONLY: executed by Windows PowerShell 5.1.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\jules-session-diag.ps1 -SessionId 3384046284391976636
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\jules-session-diag.ps1 -SessionId 3384046284391976636 -CompareWith 13310849418551960504

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SessionId,
    [string]$CompareWith = '',
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
        if (-not ('JulesCred' -as [type])) {
            Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class JulesCred {
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
        if (-not [JulesCred]::CredRead($credName, 1, 0, [ref]$ptr)) { return '' }
        if ($ptr -eq [IntPtr]::Zero) { return '' }
        $c = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ptr, [type][JulesCred+CREDENTIAL])
        $bytes = New-Object byte[] $c.CredentialBlobSize
        [System.Runtime.InteropServices.Marshal]::Copy($c.CredentialBlob, $bytes, 0, $c.CredentialBlobSize) | Out-Null
        [JulesCred]::CredFree($ptr)
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

function Get-FieldNames($obj) {
    if (-not $obj) { return '' }
    return (($obj.PSObject.Properties | ForEach-Object { $_.Name }) -join ',')
}

function Show-Session([string]$key, [string]$oauth, [string]$sessionId) {
    Write-Host ''
    Write-Host ('==========================================================')
    Write-Host ('SESSION ' + $sessionId)
    Write-Host ('==========================================================')

    $sessionName = 'sessions/' + $sessionId

    # --- public state ---
    try {
        $s = Invoke-RestMethod -Uri ('https://jules.googleapis.com/v1alpha/' + $sessionName) -Headers @{ 'X-Goog-Api-Key' = $key } -Method Get -TimeoutSec 60
        Write-Host ('public state : ' + [string]$s.state)
        Write-Host ('public fields: ' + (Get-FieldNames $s))
        if ($s.sourceContext -and $s.sourceContext.source) {
            Write-Host ('source       : ' + [string]$s.sourceContext.source)
        }
        if ($s.createTime) { Write-Host ('created      : ' + [string]$s.createTime) }
        if ($s.updateTime) { Write-Host ('updated      : ' + [string]$s.updateTime) }
    } catch {
        Write-Host ('public state : NU A RASPUNS - ' + $_.Exception.Message)
    }

    # --- public activities ---
    try {
        $r = Invoke-RestMethod -Uri ('https://jules.googleapis.com/v1alpha/' + $sessionName + '/activities?pageSize=100') -Headers @{ 'X-Goog-Api-Key' = $key } -Method Get -TimeoutSec 60
        $acts = @($r.activities)
        Write-Host ('public activities: ' + $acts.Count)
        for ($i = 0; $i -lt $acts.Count; $i++) {
            $a = $acts[$i]
            $kind = '?'
            $txt = ''
            if ($a.agentMessaged) {
                $kind = 'agentMessaged'
                $txt = ([string]$a.agentMessaged.agentMessage)
            } elseif ($a.userMessaged) {
                $kind = 'userMessaged'
                $txt = ([string]$a.userMessaged.userMessage)
            } elseif ($a.planApproved) {
                $kind = 'planApproved'
            } elseif ($a.planGenerated) {
                $kind = 'planGenerated'
            }
            $txt = ($txt -replace '\s+', ' ')
            if ($txt.Length -gt 150) { $txt = $txt.Substring(0, 150) + '...' }
            Write-Host ('  [' + $i + '] ' + $kind + ' :: ' + $txt)
        }
    } catch {
        Write-Host ('public activities: NU A RASPUNS - ' + $_.Exception.Message)
    }

    if (-not $oauth) {
        Write-Host 'internal task: SKIP (fara token OAuth)'
        return
    }

    # --- internal task (aida) ---
    try {
        $d = Invoke-RestMethod -Uri ('https://aida.googleapis.com/v1/swebot/tasks/' + $sessionId) -Headers @{ Authorization = ('Bearer ' + $oauth) } -Method Get -TimeoutSec 60
        Write-Host ('internal taskStatus : ' + [string]$d.task.taskStatus)
        Write-Host ('internal fields     : ' + (Get-FieldNames $d.task))
        if ($d.task.swebotStatus) { Write-Host ('internal swebot     : ' + [string]$d.task.swebotStatus) }
        if ($d.task.plan) { Write-Host ('plan fields         : ' + (Get-FieldNames $d.task.plan)) }
        $steps = @($d.task.activitySteps)
        Write-Host ('internal steps     : ' + $steps.Count)
        for ($i = 0; $i -lt $steps.Count; $i++) {
            $st = $steps[$i]
            $id = [string]$st.id
            $status = [string]$st.status
            $waits = 'no'
            $kind = '-'
            $detail = ''
            if ($st.agentActivity -and $st.agentActivity.agentMessaged) {
                $m = $st.agentActivity.agentMessaged
                $kind = 'agentMessaged'
                if ($m.requiresUserResponse -eq $true) { $waits = 'YES' }
                $detail = ([string]$m.text)
            } elseif ($st.agentActivity -and $st.agentActivity.agentPlanGenerated) {
                $kind = 'planGenerated'
            }
            if ($st.userActivity) {
                $kind = 'userActivity'
                if ($st.userActivity.feedbackGiven) {
                    $detail = 'feedbackGiven id=' + [string]$st.userActivity.feedbackGiven.feedbackId
                } elseif ($st.userActivity.userMessaged) {
                    $detail = 'userMessaged'
                }
            }
            $detail = ($detail -replace '\s+', ' ')
            if ($detail.Length -gt 130) { $detail = $detail.Substring(0, 130) + '...' }
            Write-Host ('  [' + $i + '] id=' + $id.Substring(0, 8) + ' status=' + $status + ' kind=' + $kind + ' waitsForUser=' + $waits + ' :: ' + $detail)
            if ($st.agentActivity) {
                Write-Host ('        agentActivity fields: ' + (Get-FieldNames $st.agentActivity))
            }
            if ($st.userActivity) {
                Write-Host ('        userActivity fields : ' + (Get-FieldNames $st.userActivity))
            }
        }
    } catch {
        Write-Host ('internal task: NU A RASPUNS - ' + $_.Exception.Message)
    }
}

$key = Get-ApiKey $SecretsFile
if (-not $key) {
    Write-Host ('EROARE: cheia Jules nu a fost gasita in ' + $SecretsFile)
    exit 2
}
$oauth = Get-OAuthToken
if (-not $oauth) {
    Write-Host 'ATENTIE: token OAuth absent (credentialul jules-cli:default lipseste sau expira).'
}

Show-Session $key $oauth $SessionId
if ($CompareWith) {
    Show-Session $key $oauth $CompareWith
}
exit 0
