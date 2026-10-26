# sweep-orphan-branches.ps1
# Removes the ephemeral branches that the PR flow left behind.
#
# ROOT CAUSE, measured 2026-10-27:
#   jules_github_sovereign_daemon.ps1 deletes a feature branch when IT
#   merges the PR ("gh pr merge --squash --delete-branch") or closes it
#   ("gh pr close --delete-branch"). A PR that was merged somewhere else
#   - by hand, by the web UI, by another agent - never passes through the
#   daemon, so its branch survives. On 2026-10-27 seven such branches were
#   alive across four repositories, all of them on PRs that had been
#   merged. The invariant was broken and nothing was measuring it.
#   This script closes that hole, and fleet-branch-invariant.ps1 measures
#   the result.
#
# THE DELETION RULE - deliberately narrow:
#   A branch is deleted only when every pull request that ever used it is
#   in state MERGED. A merged PR means the work is already in the default
#   branch, so the branch holds nothing that is not already saved.
#
#   A branch whose PRs were only CLOSED, never merged, is NOT deleted.
#   Its content was never integrated, so this script cannot prove that
#   deleting it loses nothing. Such branches are reported for a human or
#   an agent to review.
#
# USAGE:
#   powershell -NoProfile -File sweep-orphan-branches.ps1          (dry run)
#   powershell -NoProfile -File sweep-orphan-branches.ps1 -Apply   (delete)
#
# EXIT CODES:
#   0 = nothing left to delete, or the dry run found only safe candidates
#   1 = a candidate could not be deleted
#   2 = the fleet could not be measured at all
#
# ASCII ONLY: executed by Windows PowerShell 5.1.

param(
    [switch]$Apply
)

$ErrorActionPreference = 'Continue'
$Owner = 'apvizual-max'

if (-not $Apply) {
    Write-Host 'MOD: DRY-RUN. Nicio ramura nu va fi stearsa. Foloseste -Apply pentru stergere.'
} else {
    Write-Host 'MOD: APPLY. Ramurile orfane cu PR-uri MERGED vor fi sterse.'
}
Write-Host ''

$repos = @(gh repo list $Owner --limit 60 --json name 2>$null | ConvertFrom-Json | ForEach-Object { $_.name })
if (-not $repos -or $repos.Count -eq 0) {
    Write-Host 'EROARE: flota nu a putut fi citita de pe GitHub.'
    exit 2
}

$deleted = 0
$needsReview = 0
$failed = 0

foreach ($repo in $repos) {
    $default = gh api "repos/$Owner/$repo" --jq '.default_branch' 2>$null
    if (-not $default) { continue }

    $branches = @(gh api "repos/$Owner/$repo/branches" --jq '.[].name' 2>$null)
    foreach ($branch in @($branches | Where-Object { $_ -ne $default })) {

        $prs = @(gh pr list -R "$Owner/$repo" --state all --head $branch --json number,state,title 2>$null | ConvertFrom-Json)
        if ($prs.Count -eq 0) {
            Write-Host ('INFO  ' + $repo + ' / ' + $branch + ' - niciun PR gasit. Nu se atinge.')
            $needsReview++
            continue
        }

        $merged = @($prs | Where-Object { $_.state -eq 'MERGED' })
        $notMerged = @($prs | Where-Object { $_.state -ne 'MERGED' })

        if ($merged.Count -eq 0) {
            Write-Host ('INFO  ' + $repo + ' / ' + $branch + ' - PR-uri inchise fara merge (' + $notMerged.Count + '). Continutul nu este demonstrat in ' + $default + '. Nu se atinge.')
            $needsReview++
            continue
        }

        if ($notMerged.Count -gt 0) {
            Write-Host ('INFO  ' + $repo + ' / ' + $branch + ' - are ' + $merged.Count + ' PR-uri MERGED si ' + $notMerged.Count + ' ne-merge-uite. Se trateaza ca needs-review.')
            $needsReview++
            continue
        }

        if (-not $Apply) {
            Write-Host ('DRY   ' + $repo + ' / ' + $branch + ' - toti PR-urile sunt MERGED. Stergibil.')
            $deleted++
            continue
        }

        $enc = [uri]::EscapeDataString($branch)
        gh api -X DELETE "repos/$Owner/$repo/git/refs/heads/$enc" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host ('STERS ' + $repo + ' / ' + $branch + ' - ' + $merged.Count + ' PR-uri MERGED, continutul este deja in ' + $default + '.')
            $deleted++
        } else {
            Write-Host ('FECA  ' + $repo + ' / ' + $branch + ' - stergerea a esuat.')
            $failed++
        }
    }
}

Write-Host ''
Write-Host ('RAMURI STERSE: ' + $deleted)
Write-Host ('RAMURI NECESITA REVIZIE: ' + $needsReview)
Write-Host ('STERGERI ESUATE: ' + $failed)

if ($failed -gt 0) { exit 1 }
exit 0
