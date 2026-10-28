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
    [string[]]$Exclude = @('apvizual-max/MAVIS-CLOUD', 'apvizual-max/MAVIS-OPTIMUS-CD'),
    [string]$WorkflowSource = '',
    [string]$ActionSource = '',
    [string]$SecretsFile = 'E:\--- System Secrets\JULES - APIs.md',
    [switch]$Apply,
    [switch]$IncludeExcluded
)

$ErrorActionPreference = 'Continue'
$script:report = @()
# How many commits this run actually created. Each commit is a push, each
# push starts the "Invoke Jules" workflow, each workflow run creates one
# Jules session. So this counter IS the number of Jules sessions spent.
$script:commits = 0

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

# MEASURED 2026-10-28: a byte comparison, not a string comparison.
# The GitHub contents API returns "content" as base64 WITH line breaks
# (it wraps at 60 chars), so comparing it to the local base64 as text
# never matches and the installer would rewrite an identical file on
# every run. The whitespace is stripped and the bytes are compared.
function Test-SameBytes([byte[]]$a, [byte[]]$b) {
    if ($null -eq $a -or $null -eq $b) { return $false }
    if ($a.Length -ne $b.Length) { return $false }
    for ($i = 0; $i -lt $a.Length; $i++) {
        if ($a[$i] -ne $b[$i]) { return $false }
    }
    return $true
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

# The workflow calls a LOCAL action at .github/actions/jules. A local action is
# read from the workspace, so it has to exist in the repository - a workflow
# that references a missing local action fails in 8 seconds with "Can't find
# 'action.yml', 'action.yaml' or 'Dockerfile' under .../.github/actions/jules".
# MEASURED 2026-10-28 on the fleet: 4 runs failed on this mechanism with
# "/usr/bin/jq: Argument list too long" (exit 126), which killed the step
# BEFORE Jules was ever invoked - the upstream action hands the prompt to jq
# as a command line argument, and Linux caps one argument at 128 KiB
# (MAX_ARG_STRLEN). The local action reads the prompt from a FILE
# (jq --rawfile), so the size is not a cliff. The action file therefore ships
# with the workflow, as one unit.
if (-not $ActionSource) {
    $ActionSource = Join-Path $PSScriptRoot '..\.github\actions\jules\action.yaml'
}
if (-not (Test-Path -LiteralPath $ActionSource)) {
    Say ('EROARE: actiunea locala sursa nu exista: ' + $ActionSource)
    exit 2
}
$actionBytes = [System.IO.File]::ReadAllBytes($ActionSource)
$actionB64 = [Convert]::ToBase64String($actionBytes)

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

# One commit, several files, through the Git Data API.
#
# MEASURED 2026-10-29: the contents API creates ONE COMMIT PER FILE. Two files
# = two commits = two pushes = two workflow runs = two Jules sessions per
# repository. The fleet deploy at 22:57 produced 18 runs in 52 seconds and 13
# sessions, most of them for content that had not changed at all.
#
# The Git Data API writes blobs, a tree and a commit explicitly, so both files
# land in ONE commit - one push, one event.
#
# And that commit is self-quenching: the new workflow has no push trigger, so
# a push that CONTAINS the new workflow starts no run at all. The deploy
# spends zero Jules sessions. That is the difference between a deploy that
# floods and a deploy that does not.
function Write-FilesOneCommit([string]$repo, [string]$branch, [array]$files) {
    # $files: array of @{ Path = '...'; B64 = '...' }
    $res = [PSCustomObject]@{ Ok = $false; Error = ''; Commit = ''; Files = 0 }

    $headRaw = & gh api "repos/$repo/git/ref/heads/$branch" 2>&1
    if ($LASTEXITCODE -ne 0) {
        $res.Error = ('nu pot citi ref-ul ' + $branch + ': ' + (($headRaw | Out-String).Trim()))
        return $res
    }
    $headSha = ''
    try { $headSha = [string](($headRaw | ConvertFrom-Json).object.sha) } catch { $headSha = '' }
    if (-not $headSha) {
        $res.Error = 'ref-ul nu a returnat un sha'
        return $res
    }

    $commitRaw = & gh api "repos/$repo/git/commits/$headSha" 2>&1
    if ($LASTEXITCODE -ne 0) {
        $res.Error = ('nu pot citi commitul de baza: ' + (($commitRaw | Out-String).Trim()))
        return $res
    }
    $baseTree = ''
    try { $baseTree = [string](($commitRaw | ConvertFrom-Json).tree.sha) } catch { $baseTree = '' }
    if (-not $baseTree) {
        $res.Error = 'commitul de baza nu a returnat un tree'
        return $res
    }

    $treeEntries = @()
    foreach ($f in $files) {
        $blob = Send-JsonFile $repo 'git/blobs' 'POST' @{ content = $f.B64; encoding = 'base64' }
        $sha = ''
        if ($blob.Code -eq 0) { try { $sha = [string](($blob.Out | ConvertFrom-Json).sha) } catch { $sha = '' } }
        if (-not $sha) {
            $res.Error = ('blobul pentru ' + $f.Path + ' a esuat: ' + $blob.Out)
            return $res
        }
        $treeEntries += @{ path = $f.Path; mode = '100644'; type = 'blob'; sha = $sha }
    }

    $treeRes = Send-JsonFile $repo 'git/trees' 'POST' @{ base_tree = $baseTree; tree = $treeEntries }
    $treeSha = ''
    if ($treeRes.Code -eq 0) { try { $treeSha = [string](($treeRes.Out | ConvertFrom-Json).sha) } catch { $treeSha = '' } }
    if (-not $treeSha) {
        $res.Error = ('tree-ul a esuat: ' + $treeRes.Out)
        return $res
    }

    $commitRes = Send-JsonFile $repo 'git/commits' 'POST' @{ message = 'CD: mecanism general Jules - plafon 15 taskuri, activare la cerere'; tree = $treeSha; parents = @($headSha) }
    $commitSha = ''
    if ($commitRes.Code -eq 0) { try { $commitSha = [string](($commitRes.Out | ConvertFrom-Json).sha) } catch { $commitSha = '' } }
    if (-not $commitSha) {
        $res.Error = ('commitul a esuat: ' + $commitRes.Out)
        return $res
    }

    $refRes = Send-JsonFile $repo ('git/refs/heads/' + $branch) 'PATCH' @{ sha = $commitSha; force = $false }
    if ($refRes.Code -ne 0) {
        $res.Error = ('ref-ul nu a fost actualizat: ' + $refRes.Out)
        return $res
    }

    $res.Ok = $true
    $res.Commit = $commitSha
    $res.Files = $files.Count
    return $res
}

foreach ($repo in $Repos) {
    if (-not $IncludeExcluded -and ($Exclude -contains $repo)) {
        $why = 'exclus intentionat'
        if ($repo -eq 'apvizual-max/MAVIS-CLOUD') { $why = 'lucra lui Jules este in curs pe acest repo' }
        if ($repo -eq 'apvizual-max/MAVIS-OPTIMUS-CD') {
            # MEASURED 2026-10-29: writing the mechanism into the repository that
            # HOLDS the mechanism makes the installer fight the push. The
            # contents API creates a commit on origin/main, so the next local
            # push is rejected as a non-fast-forward - measured on
            # 98b80d7..b2d44fe. The CD ships its own workflow and action
            # through its own git push, which is the single source of truth.
            $why = 'sursa unica - fisierele ajung pe remote prin push-ul propriu'
        }
        Skip $repo 'repository' $why
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

    # 2 + 3) the LOCAL action and the workflow, in ONE commit.
    #
    # Two measured facts forced this shape:
    #
    # (a) ORDER, measured 2026-10-28 on hermes-local-backup: the workflow
    # landed first (run 40783868698) and the push it triggered failed in 8
    # seconds with "Can't find 'action.yml', 'action.yaml' or 'Dockerfile'
    # under .../.github/actions/jules" - the local action was not in the
    # repository yet. A local action is read FROM THE WORKSPACE, so it has
    # to exist before the workflow that references it runs.
    #
    # (b) ONE COMMIT, measured 2026-10-29: the contents API creates one
    # commit PER FILE. Two files = two commits = two pushes = two workflow
    # runs = two Jules sessions per repository. The fleet deploy at 22:57
    # produced 18 runs in 52 seconds and 13 sessions, most of them for
    # content that had not changed. Writing both files in one commit
    # through the Git Data API gives one push and one event - and since
    # the new workflow has NO push trigger, that push starts no run at
    # all. The deploy becomes self-quenching: zero Jules sessions.
    #
    # (c) IDEMPOTENCE: a file whose bytes are already identical is not
    # written at all. Zero change means zero commit, zero run, zero
    # session - and the concurrent ceiling stops being an accident.
    $actionPath = 'contents/.github/actions/jules/action.yaml'
    $actionExisting = & gh api "repos/$repo/$actionPath" 2>$null
    $actionSame = $false
    $actionExists = $false
    if ($actionExisting) {
        try {
            $actionJson = $actionExisting | ConvertFrom-Json
            $actionExists = [bool]$actionJson.sha
            if ($actionJson.content) {
                $actionRemoteBytes = [Convert]::FromBase64String(([string]$actionJson.content -replace '\s', ''))
                $actionSame = (Test-SameBytes $actionRemoteBytes $actionBytes)
            }
        } catch { $actionSame = $false }
    }

    $workflowPath = 'contents/.github/workflows/jules.yml'
    $workflowExisting = & gh api "repos/$repo/$workflowPath" 2>$null
    $workflowSame = $false
    $workflowExists = $false
    if ($workflowExisting) {
        try {
            $wfJson = $workflowExisting | ConvertFrom-Json
            $workflowExists = [bool]$wfJson.sha
            if ($wfJson.content) {
                $wfRemoteBytes = [Convert]::FromBase64String(([string]$wfJson.content -replace '\s', ''))
                $workflowSame = (Test-SameBytes $wfRemoteBytes $workflowBytes)
            }
        } catch { $workflowSame = $false }
    }

    $filesToWrite = @()
    if (-not $actionSame) { $filesToWrite += @{ Path = '.github/actions/jules/action.yaml'; B64 = $actionB64 } }
    if (-not $workflowSame) { $filesToWrite += @{ Path = '.github/workflows/jules.yml'; B64 = $workflowB64 } }

    if ($filesToWrite.Count -eq 0) {
        Skip $repo 'mecanism' 'identic - 0 commit, 0 run, 0 sesiune Jules'
    } elseif (-not $Apply) {
        $parts = @()
        if (-not $actionSame) { $parts += $(if ($actionExists) { 'actiune(locala)' } else { 'actiune(noua)' }) }
        if (-not $workflowSame) { $parts += $(if ($workflowExists) { 'workflow' } else { 'workflow(nou)' }) }
        Skip $repo 'mecanism' ('ar fi scris ' + ($parts -join ' + ') + ' intr-un singur commit (dry-run)')
    } else {
        $res = Write-FilesOneCommit -Repo $repo -Branch $branch -Files $filesToWrite
        if ($res.Ok) {
            Ok $repo 'mecanism' ('1 commit, ' + $res.Files + ' fisier(e)')
            $script:commits = $script:commits + 1
        } else {
            Fail $repo 'mecanism' ('eroare: ' + $res.Error)
        }
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
if ($Apply) {
    Say ('Commituri create: ' + $script:commits + ' (un commit = o push = un eveniment)')
    Say ('Sesiuni Jules consumate de acest deploy: 0 - workflow-ul nou nu are trigger pe push, deci niciun commit nou nu porneste un run.')
}
$script:report | ForEach-Object { Write-Output $_ }
if (-not $Apply) {
    Say ''
    Say 'DRY-RUN. Nicio scriere nu a fost facuta. Ruleaza din nou cu -Apply.'
}
exit 0
