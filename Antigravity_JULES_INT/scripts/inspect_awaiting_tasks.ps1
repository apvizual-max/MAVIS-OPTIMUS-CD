. "$PSScriptRoot\test_cred.ps1"

$headers = @{
    "Authorization" = "Bearer $($parsed.access_token)"
    "Content-Type" = "application/json"
}

$res = Invoke-JulesApiGet -Uri "https://aida.googleapis.com/v1/swebot/tasks"
$tasks = $res.tasks

Write-Host "Total tasks: $($tasks.Count)"

$awaiting = $tasks | Where-Object { $_.isAwaitingReview -eq $true }
Write-Host "Tasks with isAwaitingReview = true: $($awaiting.Count)"

Write-Host "`nTask Status Breakdown:"
$tasks | Group-Object swebotTaskStatus | ForEach-Object {
    Write-Host "$($_.Name): $($_.Count)"
}

Write-Host "`nTaskStatus (enum) Breakdown:"
$tasks | Group-Object taskStatus | ForEach-Object {
    Write-Host "$($_.Name): $($_.Count)"
}

if ($awaiting.Count -gt 0) {
    Write-Host "`nSample awaiting review task:"
    $sample = $awaiting[0]
    $sample | ConvertTo-Json -Depth 3 | Write-Host
}
