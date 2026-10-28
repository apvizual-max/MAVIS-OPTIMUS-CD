. "$PSScriptRoot\jules-guard.ps1"

$headers = Get-JulesAuthHeader
$taskId = "13857061048335159909"
$url = "https://aida.googleapis.com/v1/swebot/tasks/$taskId"
$res = Invoke-JulesApiGet -Uri $url
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
