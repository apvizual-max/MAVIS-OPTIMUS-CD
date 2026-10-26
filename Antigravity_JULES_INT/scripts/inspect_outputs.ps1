. "$PSScriptRoot\test_cred.ps1"

$headers = @{
    "Authorization" = "Bearer $($parsed.access_token)"
    "Content-Type" = "application/json"
}

$taskId = "13857061048335159909"
$url = "https://aida.googleapis.com/v1/swebot/tasks/$taskId"
$res = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
$t = $res.task
foreach ($p in $t.psobject.Properties) {
    if ($p.Name -ne "activitySteps" -and $p.Name -ne "description") {
        $val = $p.Value
        if ($val -is [string] -and $val.Length -gt 100) {
            $val = $val.Substring(0, 100) + "..."
        }
        Write-Host "$($p.Name): $val"
    }
}
