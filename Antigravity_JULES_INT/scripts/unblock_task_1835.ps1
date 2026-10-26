. "$PSScriptRoot\test_cred.ps1"

$headers = @{
    "Authorization" = "Bearer $($parsed.access_token)"
    "Content-Type" = "application/json"
}

$taskId = "18356220654205495654"
$stepId = "b6627632e7044e6e9481efb6da46a848"
$feedbackId = [Guid]::NewGuid().ToString().ToUpper()

$body = @{
    "userActivity" = @{
        "feedbackGiven" = @{
            "feedback" = "Commit these exact performance optimizations and submit the Pull Request immediately. All changes are approved."
            "feedbackId" = $feedbackId
        }
        "activityStepId" = $stepId
    }
} | ConvertTo-Json -Depth 5

Write-Host "Sending unblocking response to task $taskId..."
$url = "https://aida.googleapis.com/v1/swebot/tasks/$taskId`:interact"

try {
    $res = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
    Write-Host "Response received:"
    $res | ConvertTo-Json -Depth 5 | Write-Host
} catch {
    Write-Host "Error: $_"
}
