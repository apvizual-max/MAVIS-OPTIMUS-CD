# fleet-branch-invariant.ps1
# Measures the Single-Branch Invariant across the whole GitHub fleet.
#
# THE INVARIANT (from the CD doctrine):
#   Every repository in the apvizual-max fleet keeps EXACTLY ONE remote
#   branch - the default one. Branch names created by Jules (jules-*),
#   Palette (palette/*), Sentinel (sentinel/*) or Bolt (bolt/*) are
#   ephemeral: after the PR is merged, the branch is deleted immediately.
#   No repository is allowed to accumulate stale branches.
#
# WHY THIS IS A SCRIPT AND NOT A CLAIM:
#   The handoff documents state "exactly 1 branch per repo" as a verified
#   metric. Measured 2026-10-27, it was false: 7 ephemeral branches were
#   still alive across 4 repositories, on PRs that had all been merged.
#   A metric that is written down but never measured is a claim, not a
#   measurement. This script measures it and fails loudly when it is
#   broken.
#
# This script only READS. It never deletes anything.
# The deletion counterpart is sweep-orphan-branches.ps1.
#
# EXIT CODES:
#   0 = invariant holds on every repository
#   1 = at least one repository carries more than the default branch
#   2 = the fleet could not be measured at all
#
# ASCII ONLY: executed by Windows PowerShell 5.1.

$ErrorActionPreference = 'Continue'
$Owner = 'apvizual-max'

$repos = @(gh repo list $Owner --limit 60 --json name 2>$null | ConvertFrom-Json | ForEach-Object { $_.name })
if (-not $repos -or $repos.Count -eq 0) {
    Write-Host 'EROARE: flota nu a putut fi citita de pe GitHub.'
    exit 2
}

Write-Host ('Flota masurata: ' + $repos.Count + ' repo-uri pe ' + $Owner)
Write-Host ''

$violations = 0
$measured = 0

foreach ($repo in $repos) {
    $default = gh api "repos/$Owner/$repo" --jq '.default_branch' 2>$null
    if (-not $default) {
        Write-Host ('SKIP  ' + $repo + ' - ramura implicita nu a putut fi citita')
        continue
    }
    $branches = @(gh api "repos/$Owner/$repo/branches" --jq '.[].name' 2>$null)
    if (-not $branches) {
        Write-Host ('SKIP  ' + $repo + ' - ramurile nu au putut fi citite')
        continue
    }
    $measured++
    $extra = @($branches | Where-Object { $_ -ne $default })
    if ($extra.Count -eq 0) {
        Write-Host ('OK    ' + $repo + ' - 1 ramura (' + $default + ')')
    } else {
        $violations++
        Write-Host ('FAIL  ' + $repo + ' - ' + $branches.Count + ' ramuri; implicita=' + $default + '; efemere=' + ($extra -join ', '))
    }
}

Write-Host ''
Write-Host ('REPO-URI MASURATE: ' + $measured + ' / ' + $repos.Count)
Write-Host ('VIOLARI: ' + $violations)

if ($violations -gt 0) {
    Write-Host 'Invariantul ramurii unice este violat. Ruleaza sweep-orphan-branches.ps1.'
    exit 1
}
exit 0
