# probe-false-zero.ps1
# Proves that the Jules measurement scripts CAN fail.
#
# THE DEFECT THIS GUARDS AGAINST - measured 2026-10-27:
#   check_awaiting_count.ps1 called GET /v1/swebot/tasks with an expired
#   access_token. The API answered 401 Unauthorized. The script had no
#   error handling, so $res stayed $null, $res.tasks stayed $null, and
#   $tasks.Count printed 0. The report said "Total Jules tasks in cloud: 0"
#   about a call that never succeeded. A reader would have taken that zero
#   for a fact about the fleet.
#
# THE PROBE RUNS THE SAME SCRIPT TWICE, IN OPPOSITE DIRECTIONS:
#   PROBE 1 - with a deliberately invalid token.
#             MUST exit non-zero.
#             MUST NOT print a task count.
#             MUST name the cause of the failure.
#   PROBE 2 - with the real stored token.
#             MUST exit zero.
#             MUST print a task count.
#
# A gate that only runs in one direction is not a gate. If this probe ever
# reports PASS while a bad token is in play, the measurement layer is
# lying again.
#
# ASCII ONLY: executed by Windows PowerShell 5.1.

$ErrorActionPreference = 'Continue'

$target = Join-Path $PSScriptRoot 'check_awaiting_count.ps1'
if (-not (Test-Path -LiteralPath $target)) {
    Write-Host ('FAIL target missing: ' + $target)
    exit 2
}

$problems = 0

Write-Host 'PROBE 1: an invalid token must produce a loud failure'
$env:JULES_TOKEN_OVERRIDE = 'invalid-token-for-the-false-zero-probe'
$out1 = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $target 2>&1 | Out-String
$code1 = $LASTEXITCODE
$env:JULES_TOKEN_OVERRIDE = ''

if ($code1 -eq 0) {
    Write-Host 'FAIL PROBE 1: the script exited 0 with an invalid token.'
    $problems++
} else {
    Write-Host ('OK   PROBE 1: the script exited ' + $code1 + ' with an invalid token.')
}

if ($out1 -match 'Total Jules tasks in cloud:\s*(\d+)') {
    Write-Host ('FAIL PROBE 1: the script printed a task count (' + $Matches[1] + ') from a call that failed.')
    $problems++
} else {
    Write-Host 'OK   PROBE 1: no task count was printed from a failed call.'
}

if ($out1 -match 'Jules API GET failed') {
    Write-Host 'OK   PROBE 1: the failure named its cause.'
} else {
    Write-Host 'FAIL PROBE 1: the failure did not name its cause.'
    $problems++
}

Write-Host 'PROBE 2: the real token must produce a real count'
$out2 = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $target 2>&1 | Out-String
$code2 = $LASTEXITCODE

if ($code2 -ne 0) {
    Write-Host ('FAIL PROBE 2: the script exited ' + $code2 + ' with a valid token.')
    $problems++
} else {
    Write-Host 'OK   PROBE 2: the script exited 0 with a valid token.'
}

if ($out2 -match 'Total Jules tasks in cloud:\s*(\d+)') {
    Write-Host ('OK   PROBE 2: the script reported ' + $Matches[1] + ' tasks.')
} else {
    Write-Host 'FAIL PROBE 2: the script did not report a task count.'
    $problems++
}

Write-Host ('PROBLEMS=' + $problems)
exit $problems
