. "$PSScriptRoot\test_cred.ps1"

if (-not $parsed.access_token) {
    Write-Host "No access token."
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $($parsed.access_token)"
    "Content-Type" = "application/json"
}

try {
    $res = Invoke-RestMethod -Uri "https://aida.googleapis.com/v1/swebot/tasks" -Method Get -Headers $headers
    Write-Host "Tasks response received!"
    $tasks = $res.tasks
    Write-Host "Count of tasks: $($tasks.Count)"
    if ($tasks.Count -gt 0) {
        $first = $tasks[0]
        Write-Host "First task sample fields: $($first | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name)"
        Write-Host "First task ID: $($first.id)"
        Write-Host "First task status: $($first.status)"
        Write-Host "First task title: $($first.title)"
    }
} catch {
    Write-Host "API call failed: $_"
}
