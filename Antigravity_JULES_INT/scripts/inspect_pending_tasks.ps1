. "$PSScriptRoot\test_cred.ps1"

$headers = @{
    "Authorization" = "Bearer $($parsed.access_token)"
    "Content-Type" = "application/json"
}

$res = Invoke-JulesApiGet -Uri "https://aida.googleapis.com/v1/swebot/tasks"
$tasks = $res.tasks

$nonCompleted = $tasks | Where-Object { $_.swebotTaskStatus -ne "SWEBOT_TASK_STATUS_COMPLETED" -or [string]::IsNullOrEmpty($_.taskStatus) -or $_.taskStatus -ne "COMPLETED" }

Write-Host "Count of non-completed / pending tasks: $($nonCompleted.Count)"
foreach ($t in $nonCompleted) {
    Write-Host "ID: $($t.id) | Status: '$($t.taskStatus)' | SwebotStatus: '$($t.swebotTaskStatus)' | AwaitingReview: $($t.isAwaitingReview) | Repo: $($t.sourceId)"
    Write-Host "   Title/Desc snippet: $(if ($t.suggestedTitle) { $t.suggestedTitle } else { ($t.description -split "`n")[0] })"
}
