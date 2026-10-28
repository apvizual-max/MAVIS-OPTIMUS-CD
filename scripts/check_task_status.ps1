. "$PSScriptRoot\jules-guard.ps1"

$headers = Get-JulesAuthHeader
$id = "12796110786565823238"
$url = "https://aida.googleapis.com/v1/swebot/tasks/$id"
$res = Invoke-JulesApiGet -Uri $url
$t = $res.task
Write-Host "New status for ${id}: $($t.taskStatus) / $($t.swebotTaskStatus)"
