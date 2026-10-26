. "$PSScriptRoot\jules-guard.ps1"

$headers = Get-JulesAuthHeader
$id = "18356220654205495654"
$url = "https://aida.googleapis.com/v1/swebot/tasks/$id"
$res = Invoke-JulesApiGet -Uri $url
$t = $res.task

Write-Host "Task $id activities count: $($t.activitySteps.Count)"
if ($t.activitySteps.Count -gt 0) {
    $last = $t.activitySteps[-1]
    Write-Host "Last activity step:"
    $last | ConvertTo-Json -Depth 5 | Write-Host
}
