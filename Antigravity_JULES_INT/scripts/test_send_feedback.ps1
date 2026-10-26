. "$PSScriptRoot\test_cred.ps1"

$headers = @{
    "Authorization" = "Bearer $($parsed.access_token)"
    "Content-Type" = "application/json"
}

$taskId = "12796110786565823238"
$stepId = "6fafed377a704d619a748f39d8b9bb3b"
$feedbackId = [Guid]::NewGuid().ToString().ToUpper()

$body = @{
    "userActivity" = @{
        "feedbackGiven" = @{
            "feedback" = "Proceed with Option 3: Improve path canonicalization and traversal guards in self_modify_engine.py and prime_bridge_server.py using os.path.abspath and os.path.normpath. Ensure test_suite.py passes cleanly and create the Pull Request."
            "feedbackId" = $feedbackId
        }
        "activityStepId" = $stepId
    }
} | ConvertTo-Json -Depth 5

Write-Host "Sending interaction payload to task $taskId..."
$url = "https://aida.googleapis.com/v1/swebot/tasks/$taskId`:interact"

try {
    $res = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
    Write-Host "Response received:"
    $res | ConvertTo-Json -Depth 5 | Write-Host
} catch {
    Write-Host "Error: $_"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Host "Error details: $($reader.ReadToEnd())"
    }
}
