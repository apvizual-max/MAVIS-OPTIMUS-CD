$exePath = "$env:LOCALAPPDATA\Temp\jules_tmp\jules.exe"
$bytes = [System.IO.File]::ReadAllBytes($exePath)
$text = [System.Text.Encoding]::ASCII.GetString($bytes)
$idx = $text.IndexOf("CreateTask")
while ($idx -ge 0) {
    $snippet = $text.Substring([Math]::Max(0, $idx - 50), 150)
    $clean = $snippet -replace '[^\x20-\x7E]', ' | '
    Write-Host "Found CreateTask at ${idx}: $clean"
    $idx = $text.IndexOf("CreateTask", $idx + 10)
}
