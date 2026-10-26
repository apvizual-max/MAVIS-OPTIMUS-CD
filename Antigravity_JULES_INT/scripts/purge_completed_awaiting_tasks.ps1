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

Write-Host "Remaining awaiting review completed tasks: $($awaiting.Count)"

$chunkSize = 40
$ids = $awaiting | ForEach-Object { $_.id }

for ($i = 0; $i -lt $ids.Count; $i += $chunkSize) {
    $currentChunk = $ids[$i..([Math]::Min($i + $chunkSize - 1, $ids.Count - 1))]
    Write-Host "Deleting chunk from index $i to $($i + $currentChunk.Count - 1) (Count: $($currentChunk.Count))..."
    
    $body = @{
        "taskIds" = $currentChunk
    } | ConvertTo-Json -Depth 3

    $url = "https://aida.googleapis.com/v1/swebot/tasks:delete"
    try {
        $delRes = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
        Write-Host "Chunk deleted successfully."
    } catch {
        Write-Host "Chunk deletion failed: $_"
    }
}

Write-Host "Purge complete. Verifying new task list..."
$verifyRes = Invoke-RestMethod -Uri "https://aida.googleapis.com/v1/swebot/tasks" -Method Get -Headers $headers
$remainingAwaiting = $verifyRes.tasks | Where-Object { 
    $_.swebotTaskStatus -eq "SWEBOT_TASK_STATUS_COMPLETED" -and $_.isAwaitingReview -eq $true 
}
Write-Host "Final remaining awaiting review tasks: $($remainingAwaiting.Count)"
Write-Host "Total tasks left in Jules cloud: $($verifyRes.tasks.Count)"
