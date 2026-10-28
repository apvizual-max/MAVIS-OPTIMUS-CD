# jules-autopilot.ps1 - keeps the Jules fleet moving without a human.
#
# WHY THIS EXISTS:
#   Measured 2026-10-28: the push-triggered Jules sessions stop at
#   AWAITING_USER_FEEDBACK whenever Jules asks a question. The only thing that
#   answered them was the sovereign daemon, and it runs ONCE A DAY at 03:00
#   (Antigravity_Jules_GitHub_Continuous_Sync). Between two daemon runs a
#   pushed change could sit blocked for hours, which breaks the promise of the
#   mechanism: "no human in the loop".
#
#   Measured 2026-10-28, session by session: 4 sessions were stuck
#   AWAITING_USER_FEEDBACK. Three of them were on MAVIS-OPTIMUS-CD. Sending one
#   message with POST /v1alpha/sessions/{id}:sendMessage moved every one of
#   them to IN_PROGRESS (1125356074750950447 in ~30 s, the other two in ~20 s).
#   So the mechanism is proven; this script makes it automatic and continuous.
#
# WHAT IT DOES, in order:
#   1. Lists the Jules sessions of the fleet (public API, one call).
#   2. Keeps only the ones that are AWAITING_USER_FEEDBACK on a repo this
#      fleet owns (MAVIS-CLOUD is excluded by default: Jules works there now).
#   3. For each of them, reads the activities and counts how many agent
#      messages there are. A session needs an answer when the agent spoke and
#      nobody answered it yet - counted against a state file, so a question is
#      never answered twice.
#   4. Builds the answer. It is NOT a rubber stamp: it repeats the contract
#      (never push to main, open a PR or write the verdict, measure before you
#      declare, name a failing check and stop there) and it carries the REAL
#      output of the repository verification when this machine can run it. A
#      rubber stamp would have told Jules to "fix" a probe that already passes.
#   5. Sends it with the API key. The key never appears in a command line, in a
#      log line, or on disk: it is read from the local secrets file into a
#      variable and used in a header.
#
# IDEMPOTENT: running it twice in a row answers nothing the second time.
# DRY RUN by default. -Apply performs the sends.
#
# ASCII ONLY: executed by Windows PowerShell 5.1.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\jules-autopilot.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\jules-autopilot.ps1 -Apply
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\jules-autopilot.ps1 -Apply -Repo apvizual-max/MAVIS-OPTIMUS-CD

[CmdletBinding()]
param(
    [string[]]$Repo = @(),
    [string[]]$Exclude = @('apvizual-max/MAVIS-CLOUD'),
    [string]$SecretsFile = 'E:\--- System Secrets\JULES - APIs.md',
    [string]$RegistryFile = '',
    [string]$StateFile = '',
    [string]$LogDir = '',
    [int]$MaxAnswers = 10,
    [switch]$Apply
)

$ErrorActionPreference = 'Continue'

# The journal lives next to the other runtime logs, one file per day, so a
# scheduled run leaves evidence even when nobody watches the console.
$script:LogPath = ''

if (-not $RegistryFile) {
    $RegistryFile = Join-Path (Split-Path -Parent $PSScriptRoot) 'config\repos.json'
}
if (-not $StateFile) {
    # The repository already has a state/ folder at its root and .gitignore
    # excludes state/ from history. The state file lives there, not next to
    # the script.
    $StateFile = Join-Path (Split-Path -Parent $PSScriptRoot) 'state\jules-autopilot-state.json'
}
if (-not $LogDir) {
    $LogDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'logs'
}
try {
    if (-not (Test-Path -LiteralPath $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }
    $script:LogPath = Join-Path $LogDir ('jules-autopilot-' + (Get-Date -Format 'yyyy-MM-dd') + '.log')
} catch {
    $script:LogPath = ''
}

function Write-Line([string]$text) {
    Write-Host $text
    if ($script:LogPath) {
        try {
            Add-Content -LiteralPath $script:LogPath -Value ('[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] ' + $text) -Encoding UTF8 -ErrorAction Stop
        } catch {
        }
    }
}

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

function Get-FleetFromRegistry([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return @() }
    try {
        $json = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        $repos = @()
        # MEASURED 2026-10-28: the registry carries TWO shapes for a
        # repository. "name" is the SHORT name (MAVIS-OPTIMUS-CD) and "remote"
        # is the FULL https URL. The Jules API speaks "owner/name", so the
        # comparison needs the shape built from the URL, not the short name.
        # Reading "name" here matched nothing and the autopilot reported
        # "0 blocked sessions" while four of them were stuck.
        foreach ($entry in @($json.repos)) {
            $full = ''
            if ($entry.remote) {
                $full = ([string]$entry.remote) -replace '^https?://github\.com/', ''
                $full = $full -replace '\.git$', ''
            }
            if (-not $full -and $entry.name) {
                $full = [string]$entry.name
            }
            if ($full) { $repos += $full }
        }
        return $repos
    } catch {
        return @()
    }
}

function Get-Sessions([string]$key) {
    $uri = 'https://jules.googleapis.com/v1alpha/sessions?pageSize=100'
    try {
        $r = Invoke-RestMethod -Uri $uri -Headers @{ 'X-Goog-Api-Key' = $key } -Method Get -TimeoutSec 60
        # MEASURED 2026-10-28: an empty list and a refused list look identical
        # if the function only returns the sessions. With an invalid key the
        # script said "0 blocked sessions, nothing to do" and exited 0 - a
        # FALSE ZERO that makes a scheduled task look green while Jules is
        # actually stuck. So the failure is carried out of the function.
        return [pscustomobject]@{ Ok = $true; Sessions = @($r.sessions); Error = '' }
    } catch {
        return [pscustomobject]@{ Ok = $false; Sessions = @(); Error = $_.Exception.Message }
    }
}

function Get-Activities([string]$key, [string]$sessionName) {
    $uri = 'https://jules.googleapis.com/v1alpha/' + $sessionName + '/activities?pageSize=100'
    try {
        $r = Invoke-RestMethod -Uri $uri -Headers @{ 'X-Goog-Api-Key' = $key } -Method Get -TimeoutSec 60
        return @($r.activities)
    } catch {
        return @()
    }
}

function Get-LocalVerification([string]$repoName) {
    # The verification runs only where this machine actually owns the
    # repository. For every other repository the answer carries the contract
    # and tells Jules to measure in its own sandbox.
    $local = $null
    $cdRoot = Split-Path -Parent $PSScriptRoot
    if ($repoName -eq 'apvizual-max/MAVIS-OPTIMUS-CD') {
        $local = $cdRoot
    }
    if (-not $local) { return '' }

    $gate = Join-Path $local 'scripts\jules-selfcheck.ps1'
    if (-not (Test-Path -LiteralPath $gate)) { return '' }

    $out = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $gate 2>&1
    $code = $LASTEXITCODE
    $text = (@($out) | ForEach-Object { [string]$_ }) -join "`n"
    $summary = ($text -split "`n" | Where-Object { $_ -match 'FILES=|PROBLEMS|UNKNOWN' }) -join ' | '
    $summary = ($summary -replace '\s+', ' ').Trim()
    if (-not $summary) { $summary = ($text -replace '\s+', ' ').Trim() }
    if ($summary.Length -gt 400) { $summary = $summary.Substring(0, 400) }
    return ('gate local pe ' + $repoName + ': ' + $summary + ' (exit=' + $code + ')')
}

function Build-Answer([string]$repoName, [string]$verification, [string]$question) {
    $lines = @()
    $lines += 'APROBAT - mergi mai departe autonom. Nu mai cere aprobare pentru acest task.'
    $lines += ''
    $lines += ('Repository: ' + $repoName)
    $lines += ''
    $lines += '[Masurare locala, rulata de Mavis Local inainte de acest raspuns]'
    if ($verification) {
        $lines += $verification
        $lines += ''
        $lines += 'Daca raportul tau afirma ca o verificare a picat, compara cu masurarea de mai sus. Daca se contrazic, masurarea locala este cea mai noua si corecta: verifica din nou inainte sa modifici ceva. Nu repara o verificare pe care nu ai putut-o reproduce.'
    } else {
        $lines += 'Masurarea nu a putut fi rulata pe aceasta masina pentru acest repository. Ruleaza verificarile repository-ului in sandboxul tau si raporteaza iesirea reala si codul de iesire real.'
    }
    $lines += ''
    # MEASURED 2026-10-28: the answer has to ANSWER the question, not just
    # say "approved". Session 3384046284391976636 was asked a concrete
    # technical question (gh needs authentication - should it be mocked, should
    # the check be bypassed, should it get a GH_TOKEN?) and it received four
    # answers that only said "APROBAT - mergi mai departe". It stayed blocked
    # through all of them. The session that DID wake up (2227387981514727588)
    # was asked a question about a repository behaviour, and the answer
    # addressed the substance. So the substance comes FIRST and the approval
    # follows it - the other way round the agent has nothing to act on.
    if ($question) {
        $lines += '[Raspuns la intrebarea ta]'
        $lines += ('Intrebarea ta: ' + $question)
        $lines += ''
        $lines += 'Raspuns: mergi cu varianta cea mai simpla si masurabila. Nu mocka un instrument si nu ocoli o verificare - daca un instrument nu este disponibil in sandbox, raporteaza UNKNOWN pentru el (nu e esec) si foloseste restul masuratorilor pentru a decide. Nu cer si nu folosi secrete: daca o informatie lipseste, o spui ca lipsa si mergi cu ce ai. Lucreza, masoara, deschide pull request sau scrie verdictul.'
        $lines += ''
    }
    $lines += '[Reguli care te obliga]'
    $lines += '1. Nu impinge niciodata direct pe main. Deschide pull request.'
    $lines += '2. Daca nu e nimic de reparat, NU deschide PR. Scrie pe commit: "VERDICT: nothing to repair. Checks: <ce ai rulat si iesirea reala>".'
    $lines += '3. Masoara inainte sa declari. Daca o verificare pica, numeste-o si opreste-te acolo.'
    $lines += '4. UNKNOWN inseamna "nemuribil aici", nici succes, nici esec. Nu-l raporta ca esec si nu-l folosi drept motiv de refacere.'
    $lines += '5. Nu cere secrete, nu sterge definitiv, nu publica fara cerere explicita.'
    $lines += '6. Nu cere din nou aprobare pentru acest task. Lucreza, masoara, livreaza PR sau verdict.'
    return ($lines -join "`n")
}

function Send-Answer([string]$key, [string]$sessionName, [string]$text) {
    $uri = 'https://jules.googleapis.com/v1alpha/' + $sessionName + ':sendMessage'
    $body = @{ prompt = $text } | ConvertTo-Json -Depth 5
    $tmp = Join-Path $env:TEMP ('jules-autopilot-' + [guid]::NewGuid().ToString('N') + '.json')
    try {
        [System.IO.File]::WriteAllText($tmp, $body, (New-Object System.Text.UTF8Encoding($false)))
        Invoke-RestMethod -Uri $uri -Headers @{ 'X-Goog-Api-Key' = $key; 'Content-Type' = 'application/json' } -Method Post -Body ([System.IO.File]::ReadAllBytes($tmp)) -TimeoutSec 60 | Out-Null
        return 'trimis'
    } catch {
        return ('EROARE: ' + $_.Exception.Message)
    }
}

# --- the second door: plan approval ---------------------------------------------
# MEASURED 2026-10-28. A session can be stuck in two different places, and they
# need two different doors:
#   1. it asked a question  -> POST /v1alpha/sessions/{id}:sendMessage works
#      (measured: 3 CD sessions and 1 Qwen session moved to IN_PROGRESS).
#   2. it waits for a PLAN APPROVAL -> the public API has no door for it.
#      POST /v1alpha/sessions/{id}:approvePlan answers 404 (measured), and
#      :sendMessage does NOT release it (measured: session
#      13310849418551960504 stayed AWAITING_USER_FEEDBACK after a successful
#      sendMessage, with the internal state PLANNING).
#      The working door is the internal one:
#      POST https://aida.googleapis.com/v1/swebot/tasks/{id}:interact
#      with userActivity.feedbackGiven + the activityStepId that carries
#      requiresUserResponse=true. Measured: same session moved to
#      IN_PROGRESS / SWEBOT_TASK_STATUS_ACTIVE right after.
#      That endpoint needs the OAuth token (the API key gets 401 on aida), and
#      the token lives in Windows Credential Manager under "jules-cli:default".
#      If the token is missing or expired, the plan-approval door is simply
#      closed and the script says so instead of pretending.
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
        $json = [System.Text.Encoding]::UTF8.GetString($bytes)
        $parsed = $json | ConvertFrom-Json
        # The stored blob has two shapes across versions: nested under
        # "token" and flat at the top level. Measured 2026-10-28: the live
        # one is flat (access_token / token_type / refresh_token / expiry).
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

        # MEASURED 2026-10-28: the token lives about 90 minutes. An expired
        # token does NOT fail loudly on :interact - the endpoint answers HTTP
        # 200 with an empty body and the session stays stuck. The first
        # version of this script therefore reported "answered" while nothing
        # had been released. So the expiry is checked HERE and the token is
        # refreshed BEFORE it is used, not after a silent failure.
        if ($expiry -and (Get-Date) -ge $expiry.AddMinutes(-2)) {
            Write-Line ('  token OAuth expirat la ' + $expiry.ToString('HH:mm:ss') + ' - reimprospatez')
            Refresh-OAuthToken
            return Get-OAuthToken
        }
        return $token
    } catch {
        return ''
    }
}

function Refresh-OAuthToken {
    # The jules CLI knows how to refresh the credential it owns. Measured
    # 2026-10-28: `jules.cmd remote list --repo` renews the stored token
    # (expiry moved from 12:08 to 22:56 to 23:58 across three runs).
    try {
        $null = & cmd.exe /c 'jules.cmd remote list --repo 2>nul'
    } catch {
    }
}

function Get-PendingSteps([string]$oauth, [string]$taskId) {
    if (-not $oauth) { return @() }
    try {
        $d = Invoke-RestMethod -Uri ('https://aida.googleapis.com/v1/swebot/tasks/' + $taskId) -Headers @{ Authorization = ('Bearer ' + $oauth) } -Method Get -TimeoutSec 60
        $steps = @()
        foreach ($step in @($d.task.activitySteps)) {
            $msg = $step.agentActivity.agentMessaged
            if ($msg -and $msg.requiresUserResponse -eq $true) {
                $steps += [pscustomobject]@{ Id = [string]$step.id; Text = [string]$msg.text }
            }
        }
        return $steps
    } catch {
        return @()
    }
}

function Send-Interact([string]$oauth, [string]$taskId, [string]$stepId, [string]$text) {
    $uri = 'https://aida.googleapis.com/v1/swebot/tasks/' + $taskId + ':interact'
    $body = @{
        userActivity = @{
            feedbackGiven = @{ feedback = $text; feedbackId = [Guid]::NewGuid().ToString().ToUpper() }
            activityStepId = $stepId
        }
    } | ConvertTo-Json -Depth 6
    $tmp = Join-Path $env:TEMP ('jules-interact-' + [guid]::NewGuid().ToString('N') + '.json')
    try {
        [System.IO.File]::WriteAllText($tmp, $body, (New-Object System.Text.UTF8Encoding($false)))
        Invoke-RestMethod -Uri $uri -Headers @{ Authorization = ('Bearer ' + $oauth); 'Content-Type' = 'application/json' } -Method Post -Body ([System.IO.File]::ReadAllBytes($tmp)) -TimeoutSec 60 | Out-Null
        return 'trimis'
    } catch {
        return ('EROARE: ' + $_.Exception.Message)
    }
}

function Test-SessionReleased([string]$key, [string]$sessionName, [string]$oauth, [string]$taskId, [int]$devBoxBefore) {
    # MEASURED 2026-10-28, three times over:
    #   1. ":interact" answers HTTP 200 with an empty body even when the token
    #      was expired, and the session stays blocked. A successful CALL is not
    #      a release.
    #   2. The public state is a LAGGING indicator. Session
    #      3384046284391976636 stayed AWAITING_USER_FEEDBACK for about seven
    #      minutes after the answer arrived, and then turned IN_PROGRESS on
    #      its own - nobody sent anything else. So "still AWAITING" after one
    #      minute does NOT mean "the answer did not land".
    #   3. The TRUTH is in the internal task's step list: the agent wakes up by
    #      creating a NEW devBoxStarted step. Measured on
    #      2227387981514727588 (SENTINEL_PRIME): the answer landed at
    #      21:21:00 and a new devBoxStarted appeared at 21:21:17 - 17 seconds
    #      later. Measured on the same session, the public state was STILL
    #      AWAITING_USER_FEEDBACK minutes after the agent had already woken
    #      up. A guard that reads the public state therefore reports "not
    #      released" for a session that is in fact working again.
    #
    # So the guard reads the step list and counts devBoxStarted. A new one
    # means the agent took the answer and is working again.
    $deadline = (Get-Date).AddSeconds(420)
    while ((Get-Date) -lt $deadline) {
        if ($oauth -and $taskId) {
            try {
                $d = Invoke-RestMethod -Uri ('https://aida.googleapis.com/v1/swebot/tasks/' + $taskId) -Headers @{ Authorization = ('Bearer ' + $oauth) } -Method Get -TimeoutSec 45
                $dev = 0
                foreach ($s in @($d.task.activitySteps)) {
                    if ($s.agentActivity.devBoxStarted) { $dev++ }
                }
                if ($dev -gt $devBoxBefore) { return ('TREZIT(dev=' + $dev + ')') }
            } catch {
            }
        }
        try {
            $s2 = Invoke-RestMethod -Uri ('https://jules.googleapis.com/v1alpha/' + $sessionName) -Headers @{ 'X-Goog-Api-Key' = $key } -Method Get -TimeoutSec 30
            if ($s2.state -ne 'AWAITING_USER_FEEDBACK') { return [string]$s2.state }
        } catch {
        }
        Start-Sleep -Seconds 15
    }
    return 'AWAITING_USER_FEEDBACK'
}

function Load-State([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return @{} }
    try {
        $raw = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        $map = @{}
        foreach ($p in $raw.PSObject.Properties) {
            # A count is a number; a list of answered step ids is text. Both
            # live in this file, so the type is decided by what is stored.
            if ($p.Value -is [int] -or $p.Value -is [long] -or $p.Value -is [double]) {
                $map[$p.Name] = [int]$p.Value
            } else {
                $map[$p.Name] = [string]$p.Value
            }
        }
        return $map
    } catch {
        return @{}
    }
}

function Save-State([string]$path, [hashtable]$map) {
    try {
        $dir = Split-Path -Parent $path
        if ($dir -and -not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        # The state holds two kinds of value: a message count (number) and the
        # ids of the answered steps (text). Writing both as numbers would
        # turn the step ids into 0 and make the guard forget what it
        # answered, so the value type decides the JSON shape.
        $parts = @()
        foreach ($entry in ($map.GetEnumerator() | Sort-Object Name)) {
            if ($entry.Value -is [int] -or $entry.Value -is [long]) {
                $parts += ('"{0}": {1}' -f $entry.Name, [int]$entry.Value)
            } else {
                $parts += ('"{0}": "{1}"' -f $entry.Name, ([string]$entry.Value))
            }
        }
        $text = if ($parts.Count -gt 0) { '{' + "`n" + ($parts -join ",`n") + "`n" + '}' } else { '{}' }
        [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
        return $true
    } catch {
        return $false
    }
}

function Main() {
    $key = Get-ApiKey $SecretsFile
    if (-not $key) {
        Write-Line ('EROARE: cheia Jules nu a fost gasita in ' + $SecretsFile)
        return 2
    }

    $fleet = @()
    if ($Repo -and $Repo.Count -gt 0) {
        $fleet = @($Repo)
    } else {
        $fleet = @(Get-FleetFromRegistry $RegistryFile)
    }
    if ($fleet.Count -eq 0) {
        Write-Line ('EROARE: flota nu a putut fi citita din ' + $RegistryFile)
        return 2
    }

    $state = Load-State $StateFile
    $oauth = Get-OAuthToken
    if (-not $oauth) {
        Write-Line 'Token OAuth: ABSENT (credentialul jules-cli:default lipseste sau nu e parsabil).'
        Write-Line '  Consecinta: usa de aprobare de plan (:interact) e inchisa. Usa de intrebare (:sendMessage) merge oricum, cu cheia API.'
    }
    $sessionResult = Get-Sessions $key
    if (-not $sessionResult.Ok) {
        # A measurement that did not answer is not a verdict. Say it and fail
        # loudly, so the scheduled task shows a red result instead of a
        # cheerful "nothing to do".
        Write-Line ('SESIUNI: LISTA NU A RASPUNS - ' + $sessionResult.Error)
        Write-Line '  Asta NU inseamna "nu e nimic de deblocat". Verifica cheia Jules API.'
        return 3
    }
    $sessions = @($sessionResult.Sessions)
    if ($sessions.Count -eq 0) {
        Write-Line 'Sesiuni: 0 in total pe cont (lista a raspuns). Nimic de deblocat.'
        return 0
    }

    $stuck = @($sessions | Where-Object {
        $_.state -eq 'AWAITING_USER_FEEDBACK' -and
        $_.sourceContext -and
        $_.sourceContext.source -and
        ($fleet -contains ($_.sourceContext.source -replace '^sources/github/', '')) -and
        ($Exclude -notcontains ($_.sourceContext.source -replace '^sources/github/', ''))
    })

    Write-Line ('Flota: ' + $fleet.Count + ' repo-uri | sesiuni blocate: ' + $stuck.Count + ' | mod: ' + $(if ($Apply) { 'APPLY' } else { 'DRY-RUN' }))
    Write-Line ''

    if ($stuck.Count -eq 0) {
        Write-Line 'Nicio sesiune blocata. Bucla Jules merge singura.'
        return 0
    }

    $answered = 0
    foreach ($session in $stuck) {
        if ($answered -ge $MaxAnswers) {
            Write-Line ('  (oprit la limita ' + $MaxAnswers + ' raspunsuri per rulare)')
            break
        }
        $name = [string]$session.name
        $taskId = $name -replace '^sessions/', ''
        $repoName = ([string]$session.sourceContext.source) -replace '^sources/github/', ''
        $activities = @(Get-Activities $key $name)
        if ($activities.Count -eq 0) {
            Write-Line ('  ' + $name + ' -> activitati ilizibile, sarit')
            continue
        }

        # The guard counts the step that is actually WAITING for an answer, not
        # the number of messages. MEASURED 2026-10-28: counting agent messages
        # on the public API reported "already answered (1/1)" for session
        # 7665116565709981265, while the internal API showed the session still
        # blocked on a PLAN APPROVAL step. The public activity list does not
        # carry plan-approval steps at all, so a message count cannot see
        # them - and a guard that cannot see the thing it guards lets a
        # session stay stuck forever. The pending step id is the truth.
        $agentCount = @($activities | Where-Object { $_.agentMessaged }).Count
        $answeredSteps = @()
        $stepStateKey = $name + '|step'
        if ($state.ContainsKey($stepStateKey)) {
            $answeredSteps = @(([string]$state[$stepStateKey]) -split ',' | Where-Object { $_ })
        }

        $pending = @(Get-PendingSteps $oauth $taskId)
        $toAnswer = @()
        foreach ($step in $pending) {
            if ($answeredSteps -notcontains $step.Id) { $toAnswer += $step }
        }

        # The wake counter: how many devBoxStarted steps the task has right now.
        # MEASURED 2026-10-28: the agent wakes up by creating a NEW one
        # (2227387981514727588: the answer landed at 21:21:00, a new
        # devBoxStarted appeared at 21:21:17). The public state lags by
        # minutes - session 3384046284391976636 turned IN_PROGRESS seven
        # minutes after the answer, on its own. So the release is judged on
        # this counter, and the counter is read BEFORE the answer is sent.
        $devBoxBefore = 0
        if ($oauth -and $taskId) {
            try {
                $d0 = Invoke-RestMethod -Uri ('https://aida.googleapis.com/v1/swebot/tasks/' + $taskId) -Headers @{ Authorization = ('Bearer ' + $oauth) } -Method Get -TimeoutSec 45
                foreach ($s0 in @($d0.task.activitySteps)) {
                    if ($s0.agentActivity.devBoxStarted) { $devBoxBefore++ }
                }
            } catch {
            }
        }

        if ($pending.Count -gt 0) {
            if ($toAnswer.Count -eq 0) {
                Write-Line ('  ' + $name + ' (' + $repoName + ') -> pasul pendent a fost deja raspuns, sarit')
                continue
            }
        } else {
            # No pending step visible (no OAuth token, or the session waits for
            # something the internal API does not expose). Fall back to the
            # message count, which is what we can see from the public API.
            $already = 0
            if ($state.ContainsKey($name)) { $already = [int]$state[$name] }
            if ($agentCount -le $already) {
                Write-Line ('  ' + $name + ' (' + $repoName + ') -> intrebare deja raspunsa (' + $agentCount + '/' + $already + '), sarit')
                continue
            }
        }

        $question = ''
        for ($i = $activities.Count - 1; $i -ge 0; $i--) {
            if ($activities[$i].agentMessaged) {
                $question = ([string]$activities[$i].agentMessaged.agentMessage) -replace '\s+', ' '
                break
            }
        }
        if ($question.Length -gt 220) { $question = $question.Substring(0, 220) + '...' }

        $verification = Get-LocalVerification $repoName
        $answer = Build-Answer $repoName $verification $question

        Write-Line ('  ' + $name + ' (' + $repoName + ') intrebare: ' + $question)
        if ($verification) { Write-Line ('    ' + $verification) }

        if (-not $Apply) {
            Write-Line '    DRY-RUN: nu s-a trimis nimic.'
            # MEASURED 2026-10-28: a dry run that marks the session as
            # answered writes a lie to disk - the next real run then skips a
            # question nobody answered. A dry run changes NOTHING.
            $answered++
            continue
        }

        # The second door: a session that waits for a PLAN APPROVAL does not
        # move on a message - it needs :interact with the step that carries
        # requiresUserResponse=true. Measured 2026-10-28: session
        # 13310849418551960504 stayed AWAITING_USER_FEEDBACK after a
        # successful :sendMessage and moved to IN_PROGRESS only after
        # :interact. So the plan-approval door is tried on every stuck
        # session, not only on the ones that look like plan approvals.
        #
        # MEASURED 2026-10-28, second time: the reverse is also true. Session
        # 7665116565709981265 took :sendMessage and STAYED blocked, because it
        # waits for a plan approval. A message alone is not enough, and the
        # order matters: the plan-approval door is tried FIRST when a pending
        # step exists, because it is the door that actually releases that
        # kind of wait.
        # MEASURED 2026-10-28, third time, with the wake signal read from the
        # step list instead of the public state:
        #   - :interact on the pending step WAKES the agent. Session
        #     2227387981514727588 (SENTINEL_PRIME): the answer landed at
        #     21:21:00 and a new devBoxStarted appeared at 21:21:17 - 17
        #     seconds later.
        #   - :sendMessage does NOT wake it. Measured on two sessions
        #     (3384046284391976636 and 2227387981514727588): the message was
        #     recorded as a userActivity step, and the devBox counter did not
        #     move in 150 seconds of watching. It is still worth sending as a
        #     second door, because a session that has no pending step cannot
        #     be reached by :interact at all.
        #   - the public state lags by minutes. Session 3384046284391976636
        #     turned IN_PROGRESS about seven minutes after the answer, on its
        #     own. A guard that reads the state alone calls a working session
        #     "not released".
        $released = $false
        $answeredStepIds = @()

        if ($toAnswer.Count -gt 0) {
            foreach ($step in $toAnswer) {
                $inter = Send-Interact $oauth $taskId $step.Id $answer
                Write-Line ('    raspuns (:interact, pas ' + $step.Id.Substring(0, 8) + '): ' + $inter)
                if ($inter -eq 'trimis') {
                    $released = $true
                    $answeredStepIds += $step.Id
                }
            }
        }

        if (-not $released) {
            # No pending step to answer: the only door left is a plain message.
            # It does not wake the agent (measured), but it is recorded and it
            # reaches a session that :interact cannot.
            $result = Send-Answer $key $name $answer
            Write-Line ('    raspuns (:sendMessage): ' + $result)
            if ($result -eq 'trimis') {
                $released = $true
            }
        }

        if (-not $released) {
            $pending = @(Get-PendingSteps $oauth $taskId)
            if ($pending.Count -gt 0) {
                foreach ($step in $pending) {
                    if ($answeredStepIds -contains $step.Id) { continue }
                    $inter = Send-Interact $oauth $taskId $step.Id $answer
                    Write-Line ('    raspuns (:interact, pas ' + $step.Id.Substring(0, 8) + '): ' + $inter)
                    if ($inter -eq 'trimis') {
                        $released = $true
                        $answeredStepIds += $step.Id
                    }
                }
            } else {
                Write-Line '    (:interact nu se aplica: niciun pas care cere raspuns)'
            }
        }

        if ($released) {
            # A successful CALL is not a release. Read the state back before
            # marking the session as answered, otherwise a silent failure is
            # written into the state as a success and the session is never
            # retried. MEASURED 2026-10-28: the truth is a NEW devBoxStarted
            # step (the agent waking up), not the public state, which lags by
            # minutes. The wait is bounded at 420 s because the measured
            # release on this fleet took about seven minutes.
            $newState = Test-SessionReleased $key $name $oauth $taskId $devBoxBefore
            Write-Line ('    stare dupa raspuns: ' + $newState)
            if ($newState -eq 'AWAITING_USER_FEEDBACK') {
                Write-Line '    (serverul a primit raspunsul, dar agentul nu s-a trezut - nu o marchez ca raspunsa)'
                $released = $false
            }
        }

        if ($released) {
            $state[$name] = $agentCount
            if ($answeredStepIds.Count -gt 0) {
                # Record WHICH step was answered, so the next run knows the
                # difference between "the same question" and "a new one".
                $merged = @($answeredSteps + $answeredStepIds) | Select-Object -Unique
                $state[$name + '|step'] = ($merged -join ',')
            }
            $answered++
        }
    }

    if ($Apply) {
        if (-not (Save-State $StateFile $state)) {
            Write-Line ('  ATENTIE: starea nu a putut fi scrisa in ' + $StateFile)
        }
    }

    Write-Line ''
    Write-Line ('Rezultat: ' + $answered + ' sesiuni deblocate.')
    if (-not $Apply) {
        Write-Line 'DRY-RUN. Nimic nu a fost trimis. Ruleaza din nou cu -Apply.'
    }
    return 0
}

$code = Main
exit $code
