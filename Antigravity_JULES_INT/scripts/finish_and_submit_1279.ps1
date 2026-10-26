. "$PSScriptRoot\test_cred.ps1"

$headers = @{
    "Authorization" = "Bearer $($parsed.access_token)"
    "Content-Type" = "application/json"
}

$taskId = "12796110786565823238"
$stepId = "8a0b5c6f86ce42f5816095e04c4de1f4"
$feedbackId = [Guid]::NewGuid().ToString().ToUpper()

$instruction = "Do NOT implement the SSRF guards in this task. Commit the existing path resolution and test suite fixes immediately and submit the Pull Request now. We will create a separate dedicated task for the SSRF guards."

$body = @{
    "userActivity" = @{
        "feedbackGiven" = @{
            "feedback" = $instruction
            "feedbackId" = $feedbackId
        }
        "activityStepId" = $stepId
    }
} | ConvertTo-Json -Depth 5

Write-Host "Sending instruction to Jules task $taskId..."
$url = "https://aida.googleapis.com/v1/swebot/tasks/$taskId`:interact"

try {
    $res = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
    Write-Host "Successfully delivered instruction to Jules to finalize and submit PR."
    $res | ConvertTo-Json -Depth 5 | Write-Host
} catch {
    Write-Host "Error sending instruction: $_"
}
