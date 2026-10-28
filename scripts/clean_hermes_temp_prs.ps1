$prs = @(5, 4, 3, 2)
foreach ($pr in $prs) {
    Write-Host "Attempting merge on hermes-agent-temp PR #$pr..."
    try {
        gh pr merge $pr -R apvizual-max/hermes-agent-temp --squash --delete-branch --admin
        Write-Host "Merged PR #$pr."
    } catch {
        Write-Host "Merge failed, closing PR #$pr..."
        gh pr close $pr -R apvizual-max/hermes-agent-temp --delete-branch --comment "Closed obsolete dependabot PR to clean workspace."
    }
}
