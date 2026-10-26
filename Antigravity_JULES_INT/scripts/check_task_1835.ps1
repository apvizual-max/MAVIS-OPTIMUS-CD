. "$PSScriptRoot\test_cred.ps1"

$headers = @{
    "Authorization" = "Bearer $($parsed.access_token)"
    "Content-Type" = "application/json"
}

$id = "18356220654205495654"
$url = "https://aida.googleapis.com/v1/swebot/tasks/$id"
$res = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
$t = $res.task

Write-Host "Task $id activities count: $($t.activitySteps.Count)"
if ($t.activitySteps.Count -gt 0) {
    $last = $t.activitySteps[-1]
    Write-Host "Last activity step:"
    $last | ConvertTo-Json -Depth 5 | Write-Host
}
