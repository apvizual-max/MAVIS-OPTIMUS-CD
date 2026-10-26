. "$PSScriptRoot\test_cred.ps1"

$headers = @{
    "Authorization" = "Bearer $($parsed.access_token)"
    "Content-Type" = "application/json"
}

$id = "12796110786565823238"
$url = "https://aida.googleapis.com/v1/swebot/tasks/$id"
$res = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
$t = $res.task
Write-Host "New status for ${id}: $($t.taskStatus) / $($t.swebotTaskStatus)"
