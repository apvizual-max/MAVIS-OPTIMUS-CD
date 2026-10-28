# jules-create-probe.ps1 - finds which part of the session payload trips
# the server's "Precondition check failed".
#
# WHY THIS EXISTS:
#   Measured 2026-10-29: after the local action was deployed to the fleet,
#   11 of 13 runs created a real Jules session, and 2 runs answered HTTP 400
#   "Precondition check failed" (FAILED_PRECONDITION) - on pkms-vault-automation
#   (push) and hermes-local-backup (manual). The runs were green, so the
#   failure was invisible in the run list; only the response body carried it.
#
#   The server does not say WHICH precondition. So the payload is varied one
#   field at a time and the HTTP code of each answer is read. That is the
#   difference between guessing a fix and knowing which field is wrong.
#
#   It creates real Jules sessions, which is exactly what the workflow does -
#   and it stops at the first variant that succeeds, so it costs one session
#   per attempt, not one per variant.
#
# ASCII ONLY: executed by Windows PowerShell 5.1.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Repo,
    [string]$Branch = 'main',
    [string]$Prompt = 'Test de precondition. Nu modifica nimic.',
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

function Try-Create([string]$key, [hashtable]$payload, [string]$label) {
    $body = $payload | ConvertTo-Json -Depth 8
    $tmp = Join-Path $env:TEMP ('jules-create-' + [guid]::NewGuid().ToString('N') + '.json')
    try {
        [System.IO.File]::WriteAllText($tmp, $body, (New-Object System.Text.UTF8Encoding($false)))
        $resp = Invoke-WebRequest -Uri 'https://jules.googleapis.com/v1alpha/sessions' -Headers @{ 'X-Goog-Api-Key' = $key; 'Content-Type' = 'application/json' } -Method Post -Body ([System.IO.File]::ReadAllBytes($tmp)) -TimeoutSec 60 -UseBasicParsing
        $name = ''
        try { $name = [string](($resp.Content | ConvertFrom-Json).name) } catch { }
        Write-Host ('  ' + $label.PadRight(52) + 'HTTP ' + [int]$resp.StatusCode + '  ' + $name)
        return [int]$resp.StatusCode
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
        $short = ($text -replace '\s+', ' ')
        if ($short.Length -gt 200) { $short = $short.Substring(0, 200) }
        Write-Host ('  ' + $label.PadRight(52) + 'HTTP ' + $code + '  ' + $short)
        return $code
    }
}

$key = Get-ApiKey $SecretsFile
if (-not $key) { Write-Host 'EROARE: cheia Jules nu a fost gasita.'; exit 2 }

Write-Host ('=== precondition probe pentru ' + $Repo + ' (branch ' + $Branch + ') ===')

# The exact payload the local action sends.
$v1 = @{
    prompt = $Prompt
    sourceContext = @{
        source = ('sources/github/' + $Repo)
        githubRepoContext = @{ startingBranch = $Branch }
    }
    requirePlanApproval = $false
    automationMode = 'AUTO_CREATE_PR'
}
$r = Try-Create $key $v1 'exact ca actiunea locala'
if ($r -ge 200 -and $r -lt 300) { Write-Host '  OK: payload-ul exact merge.'; exit 0 }

# Variant 2: no automationMode / no requirePlanApproval.
$v2 = @{
    prompt = $Prompt
    sourceContext = @{
        source = ('sources/github/' + $Repo)
        githubRepoContext = @{ startingBranch = $Branch }
    }
}
$r = Try-Create $key $v2 'fara automationMode si requirePlanApproval'
if ($r -ge 200 -and $r -lt 300) { Write-Host '  OK: automationMode/requirePlanApproval sunt cauza.'; exit 0 }

# Variant 3: sourceContext without the branch.
$v3 = @{
    prompt = $Prompt
    sourceContext = @{ source = ('sources/github/' + $Repo) }
}
$r = Try-Create $key $v3 'fara githubRepoContext'
if ($r -ge 200 -and $r -lt 300) { Write-Host '  OK: githubRepoContext (rama) este cauza.'; exit 0 }

# Variant 4: no sourceContext at all.
$v4 = @{ prompt = $Prompt }
$r = Try-Create $key $v4 'fara sourceContext'
if ($r -ge 200 -and $r -lt 300) { Write-Host '  OK: sourceContext este cauza.'; exit 0 }

Write-Host ''
Write-Host 'Niciun payload nu a trecut. Precondition-ul este in afara payload-ului.'
exit 1
