$exePath = "$env:LOCALAPPDATA\Temp\jules_tmp\jules.exe"
$bytes = [System.IO.File]::ReadAllBytes($exePath)
$text = [System.Text.Encoding]::ASCII.GetString($bytes)
$idx = $text.IndexOf("type:.eq.jules-cli/flow.CreateTaskRequest")
if ($idx -ge 0) {
    $snippet = $text.Substring([Math]::Max(0, $idx - 100), 400)
    $clean = $snippet -replace '[^\x20-\x7E]', ' | '
    Write-Host $clean
}
