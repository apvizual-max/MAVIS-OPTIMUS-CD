. "$PSScriptRoot\test_cred.ps1"

$headers = @{
    "Authorization" = "Bearer $($parsed.access_token)"
    "Content-Type" = "application/json"
}

$res = Invoke-RestMethod -Uri "https://aida.googleapis.com/v1/swebot/tasks" -Method Get -Headers $headers
$found = $res.tasks | Where-Object { $_.id -eq "5038156450376238516" }
if ($found) {
    Write-Host "Task still found in task list!"
} else {
    Write-Host "SUCCESS: Task 5038156450376238516 was permanently removed from task list!"
}
