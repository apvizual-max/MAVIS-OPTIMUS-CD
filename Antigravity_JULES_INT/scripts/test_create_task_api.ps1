. "$PSScriptRoot\test_cred.ps1"

$headers = @{
    "Authorization" = "Bearer $($parsed.access_token)"
    "Content-Type" = "application/json"
}

$prompt = @"
You are "Sentinel" 🛡️ - a security-focused agent who protects our systems from vulnerabilities.
Task Directive:
Implement strict SSRF protection across HTTP fetch endpoints in 07_BACKBONE/mcp/web_tools_server.py and survey_build.py:
1. Block non-routable IPs (169.254.169.254, 127.0.0.1, localhost) and private subnet ranges.
2. Safely parse URLs and validate resolved IP before connecting.
3. Add unit tests in test_suite.py verifying SSRF rejection.

Requirements:
- Mitigate potential security risks (SSRF, unvalidated URL fetches).
- Ensure zero secrets or sensitive keys are committed.
"@

$body = @{
    "description" = $prompt
    "sourceId" = "github/apvizual-max/SENTINEL_PRIME"
} | ConvertTo-Json -Depth 5

Write-Host "Calling POST https://aida.googleapis.com/v1/swebot/tasks with sourceId..."
$url = "https://aida.googleapis.com/v1/swebot/tasks"

try {
    $res = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body
    Write-Host "TASK CREATED SUCCESSFULLY!"
    Write-Host "New Task ID: $($res.id)"
    Write-Host "Status: $($res.taskStatus) / $($res.swebotTaskStatus)"
    $res | ConvertTo-Json -Depth 3 | Write-Host
} catch {
    Write-Host "Error: $_"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        Write-Host "Response body: $($reader.ReadToEnd())"
    }
}
