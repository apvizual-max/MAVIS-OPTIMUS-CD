$exePath = "$env:LOCALAPPDATA\Temp\jules_tmp\jules.exe"
$bytes = [System.IO.File]::ReadAllBytes($exePath)
$text = [System.Text.Encoding]::ASCII.GetString($bytes)
$idx = $text.IndexOf("CreateCliTask")
while ($idx -ge 0) {
    $snippet = $text.Substring([Math]::Max(0, $idx - 50), 150)
    $clean = $snippet -replace '[^\x20-\x7E]', ' | '
    Write-Host "At ${idx}: $clean"
    $idx = $text.IndexOf("CreateCliTask", $idx + 13)
}
