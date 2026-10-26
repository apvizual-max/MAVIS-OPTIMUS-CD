. "$PSScriptRoot\test_cred.ps1"

$headers = @{
    "Authorization" = "Bearer $($parsed.access_token)"
    "Content-Type" = "application/json"
}

$taskId = "6108565468928089477"
$url = "https://aida.googleapis.com/v1/swebot/tasks/$taskId/activities"

try {
    $res = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
    Write-Host "Activities count: $($res.activities.Count)"
    if ($res.activities.Count -gt 0) {
        $last = $res.activities[-1]
        Write-Host "Last activity:"
        $last | ConvertTo-Json -Depth 4 | Write-Host
    }
} catch {
    Write-Host "Error: $_"
}
