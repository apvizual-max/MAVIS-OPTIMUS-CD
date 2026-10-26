. "$PSScriptRoot\test_cred.ps1"

$headers = @{
    "Authorization" = "Bearer $($parsed.access_token)"
    "Content-Type" = "application/json"
}

$res = Invoke-RestMethod -Uri "https://aida.googleapis.com/v1/swebot/tasks" -Method Get -Headers $headers
$tasks = $res.tasks

$awaiting = $tasks | Where-Object { 
    $_.swebotTaskStatus -eq "SWEBOT_TASK_STATUS_COMPLETED" -and $_.isAwaitingReview -eq $true 
}

$batch = $awaiting | Select-Object -First 10 | ForEach-Object { $_.id }
Write-Host "Batch count to delete: $($batch.Count)"

$body = @{
    "taskIds" = $batch
} | ConvertTo-Json -Depth 3

$url = "https://aida.googleapis.com/v1/swebot/tasks:delete"
$delRes = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
Write-Host "Batch delete response:"
$delRes | ConvertTo-Json -Depth 3 | Write-Host
