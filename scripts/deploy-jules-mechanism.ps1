# deploy-jules-mechanism.ps1
# Installs the "Jules joins the process on every push" mechanism into a set of
# GitHub repositories, from ONE canonical source file.
#
# WHY THIS IS A SCRIPT AND NOT A CLAIM:
#   The mechanism is four things per repository:
#     1. the label 'jules'          -> the trigger for issue-based tasks
#     2. the workflow jules.yml     -> push + @jules comment + label + manual
#     3. the secret JULES_API_KEY  -> the credential Jules authenticates with
#     4. Actions permissions = write -> so the workflow can open PRs and
#                                     comment WITHOUT asking anyone
#   Measured 2026-10-28: on MAVIS-OPTIMUS-CD the workflow ran and SUCCEEDED on
#   the very first push (run 40753440054, event=push) and created a real Jules
#   session (sessions/1125356074750950447, state IN_PROGRESS). The action
#   itself posts requirePlanApproval=false and automationMode=AUTO_CREATE_PR,
#   which is exactly "no human in the loop".
#
# IDEMPOTENT: running it twice changes nothing the second time.
# DRY RUN by default. -Apply performs the writes.
#
# SECURITY: the Jules API key is read from the local secrets file, written to a
# temporary dotenv file OUTSIDE the repository, used through `gh secret set
# -f`, and the temporary file is overwritten with zeros right after use. The
# key never appears in a command line, in a log line, or on disk afterwards.
#
# ASCII ONLY: executed by Windows PowerShell 5.1.
#
# Usage:
#   powershell -NoProfile -File deploy-jules-mechanism.ps1
#   powershell -NoProfile -File deploy-jules-mechanism.ps1 -Apply
#   powershell -NoProfile -File deploy-jules-mechanism.ps1 -Apply -Repos apvizual-max/MAVIS-OPTIMUS-CI
#   powershell -NoProfile -File deploy-jules-mechanism.ps1 -Apply -IncludeExcluded

[CmdletBinding()]
param(
    [string]$Owner = 'apvizual-max',
    [string[]]$Repos = @(),
    [string[]]$Exclude = @('apvizual-max/MAVIS-CLOUD'),
    [string]$WorkflowSource = '',
    [string]$SecretsFile = 'E:\--- System Secrets\JULES - APIs.md',
    [switch]$Apply,
    [switch]$IncludeExcluded
)

$ErrorActionPreference = 'Continue'
$script:report = @()

function Say([string]$t) {
    Write-Output $t
}

function Ok([string]$repo, [string]$what, [string]$detail) {
    $script:report += ('OK   {0,-42} {1,-18} {2}' -f $repo, $what, $detail)
    Say ('OK   ' + $repo.PadRight(42) + ' ' + $what.PadRight(18) + ' ' + $detail)
}

function Skip([string]$repo, [string]$what, [string]$detail) {
    $script:report += ('SKIP {0,-42} {1,-18} {2}' -f $repo, $what, $detail)
    Say ('SKIP ' + $repo.PadRight(42) + ' ' + $what.PadRight(18) + ' ' + $detail)
}

function Fail([string]$repo, [string]$what, [string]$detail) {
    $script:report += ('FAIL {0,-42} {1,-18} {2}' -f $repo, $what, $detail)
    Say ('FAIL ' + $repo.PadRight(42) + ' ' + $what.PadRight(18) + ' ' + $detail)
}

# --- inputs -----------------------------------------------------------------
if (-not $WorkflowSource) {
    $WorkflowSource = Join-Path $PSScriptRoot '..\.github\workflows\jules.yml'
}
if (-not (Test-Path -LiteralPath $WorkflowSource)) {
    Say ('EROARE: workflow-ul sursa nu exista: ' + $WorkflowSource)
    exit 2
}
$workflowBytes = [System.IO.File]::ReadAllBytes($WorkflowSource)
$workflowB64 = [Convert]::ToBase64String($workflowBytes)

if (-not (Test-Path -LiteralPath $SecretsFile)) {
    Say ('EROARE: fisierul de secrete nu exista: ' + $SecretsFile)
    exit 2
}
$julesKey = ''
foreach ($line in (Get-Content -LiteralPath $SecretsFile)) {
    $t = $line.Trim()
    if ($t -and $t -notmatch '^#' -and $t -notmatch '^-{2,}$' -and $t -notmatch '^\w+:' -and $t.Length -ge 30) {
        $julesKey = $t
        break
    }
}
if (-not $julesKey) {
    Say ('EROARE: cheia Jules nu a fost gasita in ' + $SecretsFile)
    exit 2
}

# --- fleet ------------------------------------------------------------------
if (-not $Repos -or $Repos.Count -eq 0) {
    $listRaw = & gh repo list $Owner --limit 60 --json name 2>$null
    if (-not $listRaw) {
        Say 'EROARE: flota nu a putut fi citita de pe GitHub.'
        exit 2
    }
    $Repos = @(($listRaw | ConvertFrom-Json) | ForEach-Object { $Owner + '/' + $_.name })
}
Say ('Flota: ' + $Repos.Count + ' repo-uri | mod: ' + $(if ($Apply) { 'APPLY' } else { 'DRY-RUN' }))
Say ''

$tmpEnv = Join-Path $env:TEMP ('jules-deploy-' + [guid]::NewGuid().ToString('N') + '.env')
$tmpPayload = Join-Path $env:TEMP ('jules-deploy-' + [guid]::NewGuid().ToString('N') + '.json')
$tmpWritten = $false

# MEASURED 2026-10-28: piping a JSON payload into `gh api --input -` from
# Windows PowerShell 5.1 corrupts it - GitHub answers "Problems parsing JSON
# (HTTP 400)". The same payload written to a UTF-8 file WITHOUT BOM and passed
# with `--input <file>` is accepted. Every JSON write in this script goes
# through a file, never through a pipe.
function Send-JsonFile([string]$repo, [string]$path, [string]$method, [hashtable]$body) {
    $json = $body | ConvertTo-Json -Depth 6
    [System.IO.File]::WriteAllText($tmpPayload, $json, (New-Object System.Text.UTF8Encoding($false)))
    $out = & gh api -X $method "repos/$repo/$path" --input $tmpPayload 2>&1
    return @{
        Code = $LASTEXITCODE
        Out  = ($out | Out-String).Trim()
    }
}

foreach ($repo in $Repos) {
    if (-not $IncludeExcluded -and ($Exclude -contains $repo)) {
        Skip $repo 'repository' 'exclus: lucra lui Jules este in curs pe acest repo'
        continue
    }

    # 1) label 'jules'
    $labelsRaw = & gh api "repos/$repo/labels" 2>$null
    $hasLabel = $false
    if ($labelsRaw) {
        $names = @((($labelsRaw | ConvertFrom-Json) | ForEach-Object { $_.name }))
        if ($names -contains 'jules') { $hasLabel = $true }
    }
    if ($hasLabel) {
        Ok $repo 'label-jules' 'exista deja'
    } elseif (-not $Apply) {
        Skip $repo 'label-jules' 'ar fi creata (dry-run)'
    } else {
        $res = Send-JsonFile $repo 'labels' 'POST' @{ name = 'jules'; color = '4B6BFB'; description = 'Trigger for Jules tasks. A label means a live task.' }
        if ($res.Code -eq 0) { Ok $repo 'label-jules' 'creata' } else { Fail $repo 'label-jules' ('eroare: ' + $res.Out) }
    }

    # 2) workflow jules.yml (create or update)
    # The default branch is not always main - pkms-vault-automation uses
    # master. Writing to the wrong branch is a 400, and a workflow sitting on
    # a non-default branch never fires.
    $branch = 'main'
    $repoRaw = & gh api "repos/$repo" 2>$null
    if ($repoRaw) {
        try {
            $db = [string](($repoRaw | ConvertFrom-Json).default_branch)
            if ($db) { $branch = $db }
        } catch {
            $branch = 'main'
        }
    }
    $existing = & gh api "repos/$repo/contents/.github/workflows/jules.yml" 2>$null
    $sha = ''
    if ($existing) {
        try { $sha = [string](($existing | ConvertFrom-Json).sha) } catch { $sha = '' }
    }
    if ($sha) {
        if (-not $Apply) {
            Skip $repo 'workflow' 'exista deja (dry-run: ar fi actualizat)'
        } else {
            $res = Send-JsonFile $repo 'contents/.github/workflows/jules.yml' 'PUT' @{ message = 'CD: mecanism general Jules - push + @jules'; content = $workflowB64; branch = $branch; sha = $sha }
            if ($res.Code -eq 0) { Ok $repo 'workflow' 'actualizat' } else { Fail $repo 'workflow' ('eroare: ' + $res.Out) }
        }
    } elseif (-not $Apply) {
        Skip $repo 'workflow' 'ar fi creat (dry-run)'
    } else {
        $res = Send-JsonFile $repo 'contents/.github/workflows/jules.yml' 'PUT' @{ message = 'CD: mecanism general Jules - push + @jules'; content = $workflowB64; branch = $branch }
        if ($res.Code -eq 0) { Ok $repo 'workflow' 'creat' } else { Fail $repo 'workflow' ('eroare: ' + $res.Out) }
    }

    # 3) secret JULES_API_KEY
    $secretNames = @()
    $secretRaw = & gh api "repos/$repo/actions/secrets" 2>$null
    if ($secretRaw) {
        # MEASURED 2026-10-28: the names live under .secrets, NOT at the top
        # level of the payload. Reading the wrong level reported every
        # repository as "no secret" and would have rewritten a secret that
        # was already there.
        try {
            $secretJson = $secretRaw | ConvertFrom-Json
            $secretNames = @($secretJson.secrets | ForEach-Object { $_.name })
        } catch {
            $secretNames = @()
        }
    }
    if ($secretNames -contains 'JULES_API_KEY') {
        Ok $repo 'secret' 'exista deja'
    } elseif (-not $Apply) {
        Skip $repo 'secret' 'ar fi pus (dry-run)'
    } else {
        if (-not $tmpWritten) {
            [System.IO.File]::WriteAllText($tmpEnv, ('JULES_API_KEY=' + $julesKey), (New-Object System.Text.UTF8Encoding($false)))
            $tmpWritten = $true
        }
        $out = & gh secret set JULES_API_KEY -R $repo -f $tmpEnv 2>&1
        if ($LASTEXITCODE -eq 0) { Ok $repo 'secret' 'pus' } else { Fail $repo 'secret' ('eroare: ' + ($out | Out-String).Trim()) }
    }

    # 4) Actions permissions = write
    if (-not $Apply) {
        Skip $repo 'actions-write' 'ar fi setat (dry-run)'
    } else {
        $out = & gh api -X PUT "repos/$repo/actions/permissions/workflow" -f default_workflow_permissions=write -F can_approve_pull_request_reviews=false 2>&1
        if ($LASTEXITCODE -eq 0) { Ok $repo 'actions-write' 'setat' } else { Fail $repo 'actions-write' ('eroare: ' + ($out | Out-String).Trim()) }
    }
}

# --- cleanup: the secret must not stay on disk --------------------------------
if ($tmpWritten -and (Test-Path -LiteralPath $tmpEnv)) {
    $zeros = '0' * $julesKey.Length
    [System.IO.File]::WriteAllText($tmpEnv, ('JULES_API_KEY=' + $zeros), (New-Object System.Text.UTF8Encoding($false)))
    Say ''
    Say ('Fisierul temporar cu secretul a fost suprascris cu zero: ' + (Split-Path -Leaf $tmpEnv))
}

Say ''
Say ('Raport: ' + $script:report.Count + ' randuri')
$script:report | ForEach-Object { Write-Output $_ }
if (-not $Apply) {
    Say ''
    Say 'DRY-RUN. Nicio scriere nu a fost facuta. Ruleaza din nou cu -Apply.'
}
exit 0
