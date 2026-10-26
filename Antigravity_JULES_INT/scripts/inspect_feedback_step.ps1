. "$PSScriptRoot\test_cred.ps1"

$headers = @{
    "Authorization" = "Bearer $($parsed.access_token)"
    "Content-Type" = "application/json"
}

$id = "12796110786565823238"
$url = "https://aida.googleapis.com/v1/swebot/tasks/$id"
$res = Invoke-JulesApiGet -Uri $url
$t = $res.task

Write-Host "Activity steps count: $($t.activitySteps.Count)"
if ($t.activitySteps.Count -gt 0) {
    for ($i = [Math]::Max(0, $t.activitySteps.Count - 3); $i -lt $t.activitySteps.Count; $i++) {
        Write-Host "`n--- Step $i ---"
        $t.activitySteps[$i] | ConvertTo-Json -Depth 5 | Write-Host
    }
}
