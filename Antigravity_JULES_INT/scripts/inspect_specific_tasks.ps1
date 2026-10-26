. "$PSScriptRoot\test_cred.ps1"

$headers = @{
    "Authorization" = "Bearer $($parsed.access_token)"
    "Content-Type" = "application/json"
}

$taskIds = @("12796110786565823238", "18356220654205495654")

foreach ($id in $taskIds) {
    Write-Host "`n=================== TASK $id ==================="
    $url = "https://aida.googleapis.com/v1/swebot/tasks/$id"
    $res = Invoke-JulesApiGet -Uri $url
    $t = $res.task
    Write-Host "Title: $($t.suggestedTitle)"
    Write-Host "Status: $($t.taskStatus) / $($t.swebotTaskStatus)"
    Write-Host "AwaitingReview: $($t.isAwaitingReview)"
    Write-Host "HasCodeChanges: $($t.hasCodeChanges)"
    if ($t.inProgressWork) {
        Write-Host "InProgressWork: $($t.inProgressWork | ConvertTo-Json -Depth 3)"
    }
    if ($t.outputs) {
        Write-Host "Outputs: $($t.outputs | ConvertTo-Json -Depth 3)"
    }
}
