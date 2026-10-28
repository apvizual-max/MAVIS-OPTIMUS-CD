$exePath = "$env:LOCALAPPDATA\Temp\jules_tmp\jules.exe"
$bytes = [System.IO.File]::ReadAllBytes($exePath)
$text = [System.Text.Encoding]::ASCII.GetString($bytes)
$snippet = $text.Substring(15256300, 300)
$clean = $snippet -replace '[^\x20-\x7E]', ' | '
Write-Host $clean
