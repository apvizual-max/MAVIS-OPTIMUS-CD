. "$PSScriptRoot\test_cred.ps1"

$headers = @{
    "Authorization" = "Bearer $($parsed.access_token)"
    "Content-Type" = "application/json"
}

# Task 5038156450376238516 is an old Palette task on SENTINEL_PRIME from 12 hours ago
$taskId = "5038156450376238516"
$body = @{
    "taskIds" = @($taskId)
} | ConvertTo-Json -Depth 3

Write-Host "Calling https://aida.googleapis.com/v1/swebot/tasks:delete for task $taskId..."
$url = "https://aida.googleapis.com/v1/swebot/tasks:delete"

try {
    $res = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
    Write-Host "Response received:"
    $res | ConvertTo-Json -Depth 3 | Write-Host
} catch {
    Write-Host "Error: $_"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Host "Details: $($reader.ReadToEnd())"
    }
}
