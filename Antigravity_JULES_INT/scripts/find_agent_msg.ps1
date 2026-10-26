. "$PSScriptRoot\jules-guard.ps1"

$headers = Get-JulesAuthHeader
$id = "12796110786565823238"
$url = "https://aida.googleapis.com/v1/swebot/tasks/$id"
$res = Invoke-JulesApiGet -Uri $url
$t = $res.task

for ($i = $t.activitySteps.Count - 1; $i -ge 0; $i--) {
    $step = $t.activitySteps[$i]
    if ($step.agentActivity.agentMessaged) {
        Write-Host "Found agentMessaged at step index ${i}:"
        Write-Host "Step ID: $($step.id)"
        Write-Host "RequiresResponse: $($step.agentActivity.agentMessaged.requiresUserResponse)"
        Write-Host "Text: $($step.agentActivity.agentMessaged.text)"
        break
    }
}
