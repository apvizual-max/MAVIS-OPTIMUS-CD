# alignment-run.ps1
# The tri-interface alignment run for Optimus_CD.
#
#   Leg 1  JULES   - the ceiling is measured, and one session is dispatched
#                    ONLY if there is room inside it.
#   Leg 2  GITHUB  - the mechanism's own state is measured on the remote:
#                    triggers, the ceiling guard, the secret, the Actions
#                    permissions, the label, the open pull requests.
#   Leg 3  GMAIL   - the grant is measured, the filters are counted, and the
#                    CD notification family is triaged.
#
# WHY THIS IS A SCRIPT AND NOT A SEQUENCE OF COMMANDS
# It was executed by hand once (2026-10-29) as a sequence of throwaway
# scripts in the temp directory. A procedure that lives in %TEMP% is a
# procedure that is lost at the end of the session, and the next person
# repeats it - including its mistakes. The mistakes worth remembering:
#   - a query that returns the first page only is NOT the whole set (the
#     project's own history says so: "Calling it once leaves hundreds of
#     messages unprocessed");
#   - the ceiling is measured on OPEN sessions, not on everything ever
#     created;
#   - a ceiling that cannot be measured is not treated as "there is room".
#
# Usage:
#   powershell -NoProfile -File alignment-run.ps1                 (measure)
#   powershell -NoProfile -File alignment-run.ps1 -Apply         (dispatch + triage)
#   powershell -NoProfile -File alignment-run.ps1 -SkipGmail
#
# Exit codes:
#   0 = the run completed; the report says what it found
#   1 = at least one leg could not be measured
#   2 = the run could not start (missing prompt or missing tool)
#
# ASCII ONLY: executed by Windows PowerShell 5.1.

[CmdletBinding()]
param(
    [string]$Repo = 'apvizual-max/MAVIS-OPTIMUS-CD',
    [int]$MaxOpen = 15,
    [string]$PromptFile = '',
    [switch]$Apply,
    [switch]$SkipGmail,
    [switch]$SkipJules
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'jules-lib.ps1')

$script:problems = 0
$script:notes = @()

function Line([string]$t) { Write-Output $t }

function Note([string]$t) {
    $script:notes += $t
    Line ('  NOTE: ' + $t)
}

function Problem([string]$t) {
    $script:problems = $script:problems + 1
    Line ('  PROBLEM: ' + $t)
}

if (-not $PromptFile) { $PromptFile = Join-Path $PSScriptRoot 'alignment-prompt.txt' }
if (-not (Test-Path -LiteralPath $PromptFile)) {
    Line ('EROARE: promptul de aliniere nu exista: ' + $PromptFile)
    exit 2
}

Line ('=== ALIGNMENT RUN - ' + $Repo + ' ===')
Line ('Mod: ' + $(if ($Apply) { 'APPLY (dispatch + triage)' } else { 'MEASURE (nimic nu se modifica)' }))
Line ('Plafon Jules: ' + $MaxOpen + ' taskuri deschise simultan')
Line ''

# ---------------------------------------------------------------------------
# LEG 1 - JULES
# ---------------------------------------------------------------------------
Line '--- PICIOR 1: JULES ---'
if ($SkipJules) {
    Line '  sarit (-SkipJules)'
} else {
    $budget = Test-JulesConcurrencyBudget -MaxOpen $MaxOpen
    if (-not $budget.Measured) {
        Problem ('nu pot masura plafonul Jules: ' + $budget.Error + ' - nu se trimite nimic')
    } else {
        Line ('  sesiuni deschise: ' + $budget.Open + '/' + $budget.Max + '  (total sesiuni pe cont: ' + $budget.Total + ')')
        if (-not $budget.Fits) {
            Line ('  plafon ATINS - nu se creeaza sesiune. Cererea ramane in asteptare.')
            Note ('plafonul de ' + $budget.Max + ' este plin (' + $budget.Open + ' deschise); eliberarea se face de un task terminat')
        } else {
            $wfRaw = & gh api ('repos/' + $Repo + '/contents/.github/workflows/jules.yml') 2>$null
            if (-not $wfRaw) {
                Problem ('workflow-ul nu exista pe remote: .github/workflows/jules.yml')
            } else {
                $wfText = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(([string]((($wfRaw -join "`n") | ConvertFrom-Json).content) -replace '\s', '')))
                $hasDispatch = [bool]($wfText -match '(?m)^\s{0,2}workflow_dispatch:')
                if (-not $hasDispatch) {
                    Problem ('workflow-ul nu are workflow_dispatch - nu exista cale de activare explicita')
                } elseif (-not $Apply) {
                    Line ('  DRY-RUN: s-ar fi trimis workflow_dispatch cu promptul de aliniere (room for 1)')
                } else {
                    $prompt = [System.IO.File]::ReadAllText($PromptFile, [System.Text.Encoding]::UTF8)
                    $out = & gh workflow run jules.yml -R $Repo -f ('sarcina=' + $prompt) 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Line ('  sesiune de aliniere trimisa: ' + (($out | Out-String).Trim()))
                    } else {
                        Problem ('gh workflow run a picat: ' + (($out | Out-String).Trim()))
                    }
                }
            }
        }
    }
}
Line ''

# ---------------------------------------------------------------------------
# LEG 2 - GITHUB
# ---------------------------------------------------------------------------
Line '--- PICIOR 2: GITHUB ---'
$wfRaw = & gh api ('repos/' + $Repo + '/contents/.github/workflows/jules.yml') 2>$null
$acRaw = & gh api ('repos/' + $Repo + '/contents/.github/actions/jules/action.yaml') 2>$null
if (-not $wfRaw) {
    Problem ('workflow lipsa pe remote: .github/workflows/jules.yml')
} else {
    $wfText = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(([string]((($wfRaw -join "`n") | ConvertFrom-Json).content) -replace '\s', '')))
    $hasPush = [bool]($wfText -match '(?m)^\s{0,2}push:')
    $hasSched = [bool]($wfText -match '(?m)^\s{0,2}schedule:')
    $hasDispatch = [bool]($wfText -match '(?m)^\s{0,2}workflow_dispatch:')
    $hasLabel = [bool]($wfText -match '(?m)^\s{0,2}issues:')
    $hasComment = [bool]($wfText -match '(?m)^\s{0,2}issue_comment:')
    Line ('  triggers: push=' + $hasPush + ' schedule=' + $hasSched + ' dispatch=' + $hasDispatch + ' issues=' + $hasLabel + ' comment=' + $hasComment)
    if ($hasPush) { Problem ('workflow-ul are trigger pe push - Jules ar primi fiecare push') }
    if ($hasSched) { Problem ('workflow-ul are cron - flood pe toata flota in acelasi minut') }
    if (-not $hasDispatch) { Problem ('workflow-ul nu are workflow_dispatch') }
}
if (-not $acRaw) {
    Problem ('actiunea locala lipsa pe remote: .github/actions/jules/action.yaml')
} else {
    $acText = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(([string]((($acRaw -join "`n") | ConvertFrom-Json).content) -replace '\s', '')))
    $hasCap = [bool]($acText -match 'max_concurrent_sessions')
    Line ('  plafon in actiunea locala: ' + $hasCap)
    if (-not $hasCap) { Problem ('actiunea locala nu are gardul de plafon') }
}
$secRaw = & gh api ('repos/' + $Repo + '/actions/secrets') 2>$null
$secretNames = @()
if ($secRaw) { try { $secretNames = @((($secRaw -join "`n") | ConvertFrom-Json).secrets | ForEach-Object { $_.name }) } catch { $secretNames = @() } }
Line ('  secrete: ' + $(if ($secretNames.Count -gt 0) { $secretNames -join ', ' } else { '(niciunul)' }))
if ($secretNames -notcontains 'JULES_API_KEY') { Problem ('JULES_API_KEY lipseste pe acest repo') }
$permRaw = & gh api ('repos/' + $Repo + '/actions/permissions/workflow') 2>$null
if ($permRaw) {
    try {
        $perm = ($permRaw -join "`n") | ConvertFrom-Json
        Line ('  permisiuni actions: ' + $perm.default_workflow_permissions)
        if ($perm.default_workflow_permissions -ne 'write') { Problem ('permisiunile actions nu sunt write') }
    } catch { Problem ('permisiunile actions nu au putut fi citite') }
} else { Problem ('permisiunile actions nu au putut fi citite') }
$labRaw = & gh api ('repos/' + $Repo + '/labels') 2>$null
$hasJulesLabel = $false
if ($labRaw) { try { $hasJulesLabel = [bool](@((($labRaw -join "`n") | ConvertFrom-Json) | Where-Object { $_.name -eq 'jules' })) } catch { $hasJulesLabel = $false } }
Line ('  eticheta jules: ' + $hasJulesLabel)
if (-not $hasJulesLabel) { Problem ('eticheta jules lipseste') }
$prRaw = & gh pr list -R $Repo --state open --limit 20 --json number,title,author 2>$null
if ($prRaw) {
    $prs = @(($prRaw -join "`n") | ConvertFrom-Json)
    Line ('  pull request-uri deschise: ' + $prs.Count)
    foreach ($p in $prs) { Line ('    #' + $p.number + '  ' + $p.author.login + '  ' + $p.title) }
} else { Problem ('pull request-urile nu au putut fi citite') }
Line ''

# ---------------------------------------------------------------------------
# LEG 3 - GMAIL
# ---------------------------------------------------------------------------
Line '--- PICIOR 3: GMAIL ---'
if ($SkipGmail) {
    Line '  sarit (-SkipGmail)'
} else {
    $gmailScript = Join-Path $PSScriptRoot 'alignment-gmail.js'
    if (-not (Test-Path -LiteralPath $gmailScript)) {
        Problem ('alignment-gmail.js lipseste: ' + $gmailScript)
    } else {
        $args = @($gmailScript, '--measure')
        if ($Apply) { $args = @($gmailScript, '--triage') }
        $gOut = & node @args 2>&1
        $gCode = $LASTEXITCODE
        foreach ($l in @($gOut)) { Line ('  ' + [string]$l) }
        if ($gCode -eq 2) { Problem ('piciorul Gmail nu poate fi masurat (grant indisponibil)') }
    }
}
Line ''

# ---------------------------------------------------------------------------
# VERDICT
# ---------------------------------------------------------------------------
Line '=== REZULTAT ==='
Line ('  probleme masurate: ' + $script:problems)
foreach ($n in $script:notes) { Line ('  nota: ' + $n) }
if ($script:problems -eq 0) {
    Line '  VERDICT: alinierea este completa pe cele trei interfete.'
    exit 0
}
Line '  VERDICT: exista probleme masurate - vezi lista de mai sus.'
exit 1
