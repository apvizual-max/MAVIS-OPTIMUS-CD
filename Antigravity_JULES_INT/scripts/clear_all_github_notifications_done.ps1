# Clear all GitHub notifications by marking every thread as DONE (DELETE /notifications/threads/:id)
$maxRounds = 10
$round = 0

do {
    $round++
    $raw = gh api "/notifications?all=true&per_page=100" 2>$null
    if (-not $raw) { break }
    $threads = ConvertFrom-Json $raw
    if ($threads.Count -eq 0) { break }
    
    Write-Host "[Round $round] Marking $($threads.Count) notification threads as DONE..."
    foreach ($th in $threads) {
        $id = $th.id
        gh api -X DELETE "/notifications/threads/$id" 2>$null | Out-Null
    }
} while ($threads.Count -gt 0 -and $round -lt $maxRounds)

$remaining = (gh api "/notifications?all=true" 2>$null | ConvertFrom-Json).Count
Write-Host "Remaining notification threads: $remaining"
