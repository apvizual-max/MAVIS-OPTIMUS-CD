$prs = gh search prs --owner apvizual-max --state open --json repository,number,title,author,url,isDraft | ConvertFrom-Json
Write-Host "Total Open PRs on GitHub: $($prs.Count)"
foreach ($pr in $prs) {
    Write-Host "Repo: $($pr.repository.name) | PR #$($pr.number) | Author: $($pr.author.login) | Title: $($pr.title)"
}
