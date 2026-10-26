. "$PSScriptRoot\test_cred.ps1"

$headers = @{
    "Authorization" = "Bearer $($parsed.access_token)"
    "Content-Type" = "application/json"
}

$taskId = "13857061048335159909"
$url = "https://aida.googleapis.com/v1/swebot/tasks/$taskId"

try {
    $res = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
    Write-Host "Task Details for ${taskId}:"
    $res | ConvertTo-Json -Depth 6 | Write-Host
} catch {
    Write-Host "Error: $_"
}
