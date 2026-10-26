. "$PSScriptRoot\test_cred.ps1"

$headers = @{
    "Authorization" = "Bearer $($parsed.access_token)"
    "Content-Type" = "application/json"
}

$id = "12796110786565823238"
$url = "https://aida.googleapis.com/v1/swebot/tasks/$id"
$res = Invoke-JulesApiGet -Uri $url
$t = $res.task

Write-Host "Task $id activities count: $($t.activitySteps.Count)"
Write-Host "Status: $($t.taskStatus) / $($t.swebotTaskStatus)"
if ($t.activitySteps.Count -gt 0) {
    $last = $t.activitySteps[-1]
    Write-Host "Last activity step ID: $($last.id)"
    Write-Host "Created at: $($last.createdAt)"
    $last.agentActivity | ConvertTo-Json -Depth 5 | Write-Host
}
