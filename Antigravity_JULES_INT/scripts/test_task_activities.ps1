. "$PSScriptRoot\jules-guard.ps1"

$headers = Get-JulesAuthHeader
$taskId = "6108565468928089477"
$url = "https://aida.googleapis.com/v1/swebot/tasks/$taskId/activities"

try {
    $res = Invoke-JulesApiGet -Uri $url
    Write-Host "Activities count: $($res.activities.Count)"
    if ($res.activities.Count -gt 0) {
        $last = $res.activities[-1]
        Write-Host "Last activity:"
        $last | ConvertTo-Json -Depth 4 | Write-Host
    }
} catch {
    Write-Host "Error: $_"
}
