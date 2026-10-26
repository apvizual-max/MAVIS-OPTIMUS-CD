. "$PSScriptRoot\test_cred.ps1"

$headers = @{
    "Authorization" = "Bearer $($parsed.access_token)"
    "Content-Type" = "application/json"
}

$res = Invoke-RestMethod -Uri "https://aida.googleapis.com/v1/swebot/tasks" -Method Get -Headers $headers
$tasks = $res.tasks

Write-Host "Total Jules tasks in cloud: $($tasks.Count)"

# Identify tasks that are completed and have isAwaitingReview = true
# These are tasks whose code has already been merged or completed, but Jules web UI still displays "Ready for review"
$awaitingReviewCompleted = $tasks | Where-Object { 
    $_.swebotTaskStatus -eq "SWEBOT_TASK_STATUS_COMPLETED" -and $_.isAwaitingReview -eq $true 
}

Write-Host "Tasks completed in cloud but awaiting review on Web UI: $($awaitingReviewCompleted.Count)"
