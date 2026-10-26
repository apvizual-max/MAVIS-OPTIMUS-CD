. "$PSScriptRoot\jules-guard.ps1"

$headers = Get-JulesAuthHeader

try {
    $res = Invoke-JulesApiGet -Uri "https://aida.googleapis.com/v1/swebot/tasks"
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
