. "$PSScriptRoot\jules-guard.ps1"

$headers = Get-JulesAuthHeader
$res = Invoke-JulesApiGet -Uri "https://aida.googleapis.com/v1/swebot/tasks"
$tasks = $res.tasks

Write-Host "Remaining tasks in Jules cloud: $($tasks.Count)"
foreach ($t in $tasks) {
    Write-Host "ID: $($t.id) | Status: '$($t.taskStatus)' | SwebotStatus: '$($t.swebotTaskStatus)' | AwaitingReview: $($t.isAwaitingReview) | Repo: $($t.sourceId)"
    Write-Host "   Title: $($t.suggestedTitle)"
}
