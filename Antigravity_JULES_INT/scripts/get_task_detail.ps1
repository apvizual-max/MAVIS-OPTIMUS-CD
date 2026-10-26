. "$PSScriptRoot\jules-guard.ps1"

$headers = Get-JulesAuthHeader
$taskId = "13857061048335159909"
$url = "https://aida.googleapis.com/v1/swebot/tasks/$taskId"

try {
    $res = Invoke-JulesApiGet -Uri $url
    Write-Host "Task Details for ${taskId}:"
    $res | ConvertTo-Json -Depth 6 | Write-Host
} catch {
    Write-Host "Error: $_"
}
