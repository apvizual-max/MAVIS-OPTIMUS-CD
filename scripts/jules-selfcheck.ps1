# jules-selfcheck.ps1
# The gate that must pass before anything in this platform runs.
#
# Three failures killed this platform before it worked, and all of them were
# invisible until something broke at run time:
#
#   1. A NON-ASCII byte in a .ps1 file. Windows PowerShell 5.1 parses
#      interpolated strings wrongly when the file carries bytes above 0x7F
#      and no BOM. The file "looks fine" in an editor and fails at run time.
#   2. A PARSE error. A stray ')' at the end of a line is enough to make the
#      whole script unusable - and the symptom shows up far from the cause.
#   3. AN EXIT CODE SWALLOWED BY ITS OWN OUTPUT. A script does `$code = Main`
#      and Main prints with Write-Output, so the printed lines become part of
#      Main's return value. Measured on this machine:
#          function F { Write-Output 'X'; return 3 }  ->  $c = F  ->  @('X', 3)
#          exit $c                                     ->  EXIT 0
#      Every gate that printed before returning a failure code returned
#      SUCCESS. A check that cannot fail is not a check.
#
# So the gate checks all four things, for every script:
#   - ASCII pur
#   - parse fara erori
#   - no Write-Output in a script whose exit code comes from a variable
#   - the platform idiom really does deliver the payload AND the exit code
#     (a probe that deliberately fails, so the gate is shown able to fail)
#
# Usage:
#   powershell -NoProfile -File jules-selfcheck.ps1
#
# Exit codes:
#   0 = all scripts clean
#   1 = at least one script has non-ASCII bytes, a parse error, a
#       contaminated exit code, or the idiom probe failed
#
# ASCII ONLY: executed by Windows PowerShell 5.1.

param(
    [string]$ScriptsDir = '',
    [switch]$SkipProbes
)

$ErrorActionPreference = 'Stop'

if (-not $ScriptsDir) {
    $ScriptsDir = $PSScriptRoot
}

if (-not (Test-Path -LiteralPath $ScriptsDir)) {
    Write-Output ('EROARE: director inexistent: ' + $ScriptsDir)
    exit 2
}

$files = @(Get-ChildItem -LiteralPath $ScriptsDir -Filter '*.ps1' -File -ErrorAction SilentlyContinue)
if ($files.Count -eq 0) {
    Write-Output ('EROARE: niciun .ps1 in ' + $ScriptsDir)
    exit 2
}

$problems = 0
$unknown = 0
foreach ($f in $files) {
    $p = $f.FullName
    if (-not (Test-Path -LiteralPath $p)) {
        Write-Output ('FAIL ' + $f.Name + ' - fisier disparit in timpul verificarii')
        $problems++
        continue
    }

    $bytes = [System.IO.File]::ReadAllBytes($p)
    $nonAscii = 0
    $firstBad = -1
    for ($i = 0; $i -lt $bytes.Count; $i++) {
        if ($bytes[$i] -gt 127) {
            $nonAscii++
            if ($firstBad -lt 0) { $firstBad = $i }
        }
    }

    $errs = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($p, [ref]$null, [ref]$errs)
    $parseCount = 0
    if ($errs) { $parseCount = $errs.Count }

    # The exit-code contamination check.
    $raw = [System.IO.File]::ReadAllText($p)
    $exitVar = [regex]::Match($raw, '(?m)^\s*exit\s+\$(\w+)\s*$')
    $exitName = ''
    $contaminated = $false
    if ($exitVar.Success) {
        $exitName = $exitVar.Groups[1].Value
        $fromCall = [regex]::IsMatch($raw, ('(?m)^\s*\$' + $exitName + '\s*=\s*[A-Za-z_][A-Za-z0-9_\-]*\s*$'))
        $usesStream = [regex]::IsMatch($raw, '(?m)^\s*Write-Output\b')
        if ($fromCall -and $usesStream) { $contaminated = $true }
    }

    if ($nonAscii -gt 0 -or $parseCount -gt 0 -or $contaminated) {
        $problems++
        Write-Output ('FAIL ' + $f.Name + ' - bytes=' + $bytes.Count + ' nonascii=' + $nonAscii + ' parseErrors=' + $parseCount + ' exitContaminated=' + $contaminated)
        if ($nonAscii -gt 0) {
            Write-Output ('     primul octet > 0x7F la pozitia ' + $firstBad + ' (offset ' + $firstBad + ')')
        }
        if ($contaminated) {
            Write-Output ('     Write-Output contamineaza variabila de cod de iesire $' + $exitName + ' - foloseste Write-JulesOut')
        }
        if ($errs) {
            foreach ($e in $errs) {
                Write-Output ('     L' + $e.Extent.StartLineNumber + 'C' + $e.Extent.StartColumnNumber + ': ' + $e.Message)
                Write-Output ('        text: [' + $e.Extent.Text + ']')
            }
        }
    } else {
        Write-Output ('OK   ' + $f.Name + ' - bytes=' + $bytes.Count + ' nonascii=0 parseErrors=0 exitContaminated=false')
    }
}

if ($SkipProbes) {
    Write-Output 'NOTA: sondele de platforma au fost sarite (-SkipProbes). Doar verificarile statice au rulat.'
}

# --- The push-gate control -------------------------------------------------
#
# MEASURED 2026-10-28: the pre-push gate file vanished from disk while
# core.hooksPath still pointed at it. Git skips a missing hook SILENTLY, so
# the gate stopped existing and two pushes went through with no accord
# consumed. Nothing reported it. A gate that can die without a sound is not
# a gate, it is a habit.
#
# This control measures the gate of the repository that owns this script:
#   1. resolve the effective hooks dir (core.hooksPath, else <gitdir>/hooks)
#   2. the pre-push file must exist there and carry the marker logic
# A missing file is a PROBLEM - the push path is unguarded - not a warning.
# If the repository cannot be resolved the control reports UNKNOWN: it never
# reports a pass it did not measure.

$gateRepo = ''
$gateHooksPath = ''
$gateDir = ''
$gateFile = ''
try {
    $ErrorActionPreference = 'Continue'
    $rawRepo = & git -C $ScriptsDir rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0 -and $rawRepo) {
        $gateRepo = ([string]($rawRepo | Select-Object -Last 1)).Trim()
    }
    $rawHooks = & git -C $ScriptsDir config --get core.hooksPath 2>$null
    if ($LASTEXITCODE -eq 0 -and $rawHooks) {
        $gateHooksPath = ([string]($rawHooks | Select-Object -Last 1)).Trim()
    }
    $rawGitDir = & git -C $ScriptsDir rev-parse --git-dir 2>$null
    if ($LASTEXITCODE -eq 0 -and $rawGitDir) {
        $gateGitDir = ([string]($rawGitDir | Select-Object -Last 1)).Trim()
    }
} catch {
    $gateRepo = ''
    $gateHooksPath = ''
} finally {
    $ErrorActionPreference = 'Stop'
}

if ($gateHooksPath) {
    $gateDir = $gateHooksPath
    if (-not [System.IO.Path]::IsPathRooted($gateDir)) {
        $gateDir = Join-Path $gateRepo $gateDir
    }
} elseif ($gateGitDir) {
    if ([System.IO.Path]::IsPathRooted($gateGitDir)) {
        $gateDir = Join-Path $gateGitDir 'hooks'
    } else {
        $gateDir = Join-Path $gateRepo (Join-Path $gateGitDir 'hooks')
    }
}

if (-not $gateRepo -or -not $gateDir) {
    $unknown++
    Write-Output 'UNKNOWN poarta-push - repository-ul sau directorul hook-urilor nu a fost rezolvat, poarta nu a putut fi masurata'
} else {
    $gateFile = Join-Path $gateDir 'pre-push'
    if (-not (Test-Path -LiteralPath $gateFile)) {
        $problems++
        Write-Output ('FAIL poarta-push - hook-ul pre-push lipseste la ' + $gateFile + ' - git sareste hook-urile inexistente in SILENT')
    } else {
        $gateRaw = ''
        try { $gateRaw = [System.IO.File]::ReadAllText($gateFile) } catch { $gateRaw = '' }
        if ($gateRaw -notmatch 'PUSH-ACORD') {
            $problems++
            Write-Output ('FAIL poarta-push - hook-ul pre-push de la ' + $gateFile + ' nu contine logica de acord (PUSH-ACORD)')
        } else {
            Write-Output ('OK   poarta-push - hook pre-push prezent si valid la ' + $gateFile)
        }
    }
}

if (-not $SkipProbes) {
# --- The idiom probe -----------------------------------------------------
# A gate that has never been shown able to fail is a gate of unknown quality.
# The probe writes a payload to stdout AND returns a failure code, exactly as
# the platform scripts do. If the payload is lost or the code is swallowed,
# the platform's own contract is broken and the probe says so.
$probeDir = Join-Path (Split-Path -Parent $ScriptsDir) 'state\tmp'
if (-not (Test-Path -LiteralPath $probeDir)) {
    New-Item -ItemType Directory -Path $probeDir -Force | Out-Null
}
$probeFile = Join-Path $probeDir ('selfcheck-probe-' + [guid]::NewGuid().ToString('N') + '.ps1')
$probeLib = Join-Path $ScriptsDir 'jules-lib.ps1'
$libLiteral = $probeLib.Replace("'", "''")
$probeSrc = @(
    '$ErrorActionPreference = ''Stop''',
    ('. ''' + $libLiteral + ''''),
    'function ProbeMain {',
    '    Write-JulesOut ''PROBE_PAYLOAD_OK''',
    '    return 3',
    '}',
    '$code = ProbeMain',
    'exit $code'
) -join "`n"

$probeCode = -1
$probeText = ''
try {
    [System.IO.File]::WriteAllText($probeFile, ($probeSrc + "`n"), (New-Object System.Text.UTF8Encoding($false)))
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $probeOut = & powershell -NoProfile -File $probeFile 2>&1
    $ErrorActionPreference = $prevEap
    $probeCode = $LASTEXITCODE
    if ($null -eq $probeCode) { $probeCode = -1 }
    if ($probeOut) { $probeText = ($probeOut -join "`n") }
} catch {
    $probeText = [string]$_
} finally {
    $ErrorActionPreference = 'Continue'
    if (Test-Path -LiteralPath $probeFile) { Remove-Item -LiteralPath $probeFile -Force -ErrorAction SilentlyContinue }
    $ErrorActionPreference = $prevEap
}

if ($probeCode -ne 3) {
    $problems++
    Write-Output ('FAIL proba-idiom - cod de iesire ' + $probeCode + ', asteptat 3 (payload + cod de esec)')
} elseif ($probeText -notmatch 'PROBE_PAYLOAD_OK') {
    $problems++
    Write-Output 'FAIL proba-idiom - payload absent pe stdout (codul a fost corect, payload-ul nu)'
} else {
    Write-Output ('OK   proba-idiom - payload pe stdout SI cod de iesire ' + $probeCode + ' (proba esueaza intentionat)')
}

# --- The checkout-verification probe --------------------------------------
#
# `gh pr checkout <n> -R <repo>` acts on the repository in the CURRENT
# directory and exits 0 even when that is not the repository named by -R.
# Measured on this machine. That produced a FALSE REJECT: the clone stayed
# on an older branch, the new test file did not exist there, the test
# runner exited 1, and the proposal was called broken.
#
# Test-CheckoutTarget is the gate that prevents it. A gate that has never
# been shown able to fail is a gate of unknown quality, so this probe
# builds a real clone with a real branch and demands that the gate
# REJECTS three wrong situations and ACCEPTS the one right situation:
#
#   a) a directory that is not a clone          -> must reject
#   b) a branch that is not the expected one     -> must reject
#   c) a test file missing from the branch       -> must reject
#   d) the right directory, branch and file      -> must accept
#
# If the gate accepts any of a/b/c, the false-reject path is still open
# and the platform is not trustworthy.
$checkoutProbeFile = Join-Path $probeDir ('checkout-probe-' + [guid]::NewGuid().ToString('N') + '.ps1')
$checkoutProbeSrc = @(
    '$ErrorActionPreference = ''Stop''',
    ('. ''' + $libLiteral + ''''),
    '$scratch = Join-Path (Get-JulesRoot) (''state\tmp\checkout-probe-'' + [guid]::NewGuid().ToString(''N''))',
    'New-Item -ItemType Directory -Path $scratch -Force | Out-Null',
    'try {',
    '    $null = Invoke-Native -Program ''git'' -Arguments @(''init'', ''-q'', $scratch)',
    '    $null = Invoke-Native -Program ''git'' -Arguments @(''-C'', $scratch, ''symbolic-ref'', ''HEAD'', ''refs/heads/probe-branch'')',
    '    [System.IO.File]::WriteAllText((Join-Path $scratch ''probe-file.txt''), ''ok'')',
    '    $null = Invoke-Native -Program ''git'' -Arguments @(''-C'', $scratch, ''-c'', ''user.email=probe@local'', ''-c'', ''user.name=probe'', ''-c'', ''commit.gpgsign=false'', ''add'', ''probe-file.txt'')',
    '    $null = Invoke-Native -Program ''git'' -Arguments @(''-C'', $scratch, ''-c'', ''user.email=probe@local'', ''-c'', ''user.name=probe'', ''-c'', ''commit.gpgsign=false'', ''commit'', ''-q'', ''-m'', ''probe'')',
    '    $sha = (Invoke-Native -Program ''git'' -Arguments @(''-C'', $scratch, ''rev-parse'', ''HEAD'')).Out.Trim()',
    '    $a = Test-CheckoutTarget -Dir (Join-Path $scratch ''not-a-clone'') -ExpectedRef ''probe-branch''',
    '    $b = Test-CheckoutTarget -Dir $scratch -ExpectedRef ''other-branch''',
    '    $c = Test-CheckoutTarget -Dir $scratch -ExpectedRef ''probe-branch'' -OwnPaths @(''missing-file.txt'')',
    '    $d = Test-CheckoutTarget -Dir $scratch -ExpectedRef ''probe-branch'' -OwnPaths @(''probe-file.txt'')',
    '    $e = Test-CheckoutTarget -Dir $scratch -ExpectedRef ''probe-branch'' -ExpectedSha (''deadbeef'' + $sha) -OwnPaths @(''probe-file.txt'')',
    '    if ($a.Ok) { Write-JulesOut ''PROBE_CHECKOUT_BAD a: a non-clone directory was accepted''; exit 0 }',
    '    if ($b.Ok) { Write-JulesOut ''PROBE_CHECKOUT_BAD b: a wrong branch was accepted''; exit 0 }',
    '    if ($c.Ok) { Write-JulesOut ''PROBE_CHECKOUT_BAD c: a missing test file was accepted''; exit 0 }',
    '    if ($e.Ok) { Write-JulesOut ''PROBE_CHECKOUT_BAD e: a wrong commit was accepted''; exit 0 }',
    '    if (-not $d.Ok) { Write-JulesOut (''PROBE_CHECKOUT_BAD d: the correct target was rejected - '' + $d.Reason); exit 0 }',
    '    Write-JulesOut ''PROBE_CHECKOUT_OK''',
    '} finally {',
    '    if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue }',
    '}',
    'exit 0'
) -join "`n"

$checkoutProbeOut = ''
$checkoutProbeCode = -1
try {
    [System.IO.File]::WriteAllText($checkoutProbeFile, ($checkoutProbeSrc + "`n"), (New-Object System.Text.UTF8Encoding($false)))
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $raw = & powershell -NoProfile -File $checkoutProbeFile 2>&1
    $ErrorActionPreference = $prevEap
    $checkoutProbeCode = $LASTEXITCODE
    if ($null -eq $checkoutProbeCode) { $checkoutProbeCode = -1 }
    if ($raw) { $checkoutProbeOut = ($raw -join "`n") }
} catch {
    $checkoutProbeOut = [string]$_
} finally {
    $ErrorActionPreference = 'Continue'
    if (Test-Path -LiteralPath $checkoutProbeFile) { Remove-Item -LiteralPath $checkoutProbeFile -Force -ErrorAction SilentlyContinue }
    $ErrorActionPreference = $prevEap
}

if ($checkoutProbeOut -match 'PROBE_CHECKOUT_OK') {
    Write-Output 'OK   proba-checkout - poarta respinge director neclona, ramura gresita si fisier lipsa; accepta tinta corecta'
} else {
    $problems++
    Write-Output ('FAIL proba-checkout - ' + $checkoutProbeOut.Trim())
}

# --- The python-runner probe ----------------------------------------------
#
# A pytest-style file invoked directly exits 0 after running NOTHING. That
# is a FALSE PASS - it clears a proposal that was never tested, which is
# the most dangerous direction a check can break in.
#
# The standard library fallback is therefore allowed only for a file that
# really has a runner entry point. This probe demands that the gate:
#   a) ACCEPTS a file with a `__main__` block and a runner   -> true
#   b) REJECTS a pytest-style file with no runner entry point -> false
#   c) REJECTS a file that does not exist                     -> false
# If it accepts b, the platform would clear untested proposals.
$runnerProbeFile = Join-Path $probeDir ('runner-probe-' + [guid]::NewGuid().ToString('N') + '.ps1')
$runnerProbeSrc = @(
    '$ErrorActionPreference = ''Stop''',
    ('. ''' + $libLiteral + ''''),
    '$scratch = Join-Path (Get-JulesRoot) (''state\tmp\runner-probe-'' + [guid]::NewGuid().ToString(''N''))',
    'New-Item -ItemType Directory -Path $scratch -Force | Out-Null',
    'try {',
    '    $withRunner = Join-Path $scratch ''with_runner.py''',
    '    [System.IO.File]::WriteAllText($withRunner, "import unittest`nclass T(unittest.TestCase):`n    def test_x(self):`n        self.assertTrue(True)`nif __name__ == ''__main__'':`n    unittest.main()`n")',
    '    $pytestStyle = Join-Path $scratch ''pytest_style.py''',
    '    [System.IO.File]::WriteAllText($pytestStyle, "def test_something():`n    assert True`n")',
    '    $missing = Join-Path $scratch ''not_here.py''',
    '    $a = Test-JulesStdlibRunnable -Path $withRunner',
    '    $b = Test-JulesStdlibRunnable -Path $pytestStyle',
    '    $c = Test-JulesStdlibRunnable -Path $missing',
    '    if (-not $a) { Write-JulesOut ''PROBE_RUNNER_BAD a: a file with a runner was rejected''; exit 0 }',
    '    if ($b) { Write-JulesOut ''PROBE_RUNNER_BAD b: a pytest-style file was accepted - that is a false pass''; exit 0 }',
    '    if ($c) { Write-JulesOut ''PROBE_RUNNER_BAD c: a missing file was accepted''; exit 0 }',
    '    Write-JulesOut ''PROBE_RUNNER_OK''',
    '} finally {',
    '    if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue }',
    '}',
    'exit 0'
) -join "`n"

$runnerProbeOut = ''
try {
    [System.IO.File]::WriteAllText($runnerProbeFile, ($runnerProbeSrc + "`n"), (New-Object System.Text.UTF8Encoding($false)))
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $raw = & powershell -NoProfile -File $runnerProbeFile 2>&1
    $ErrorActionPreference = $prevEap
    if ($raw) { $runnerProbeOut = ($raw -join "`n") }
} catch {
    $runnerProbeOut = [string]$_
} finally {
    $ErrorActionPreference = 'Continue'
    if (Test-Path -LiteralPath $runnerProbeFile) { Remove-Item -LiteralPath $runnerProbeFile -Force -ErrorAction SilentlyContinue }
    $ErrorActionPreference = $prevEap
}

if ($runnerProbeOut -match 'PROBE_RUNNER_OK') {
    Write-Output 'OK   proba-runner - accepta doar fisierele cu runner real; un fisier pytest-style ar produce un PASS fals'
} else {
    $problems++
    Write-Output ('FAIL proba-runner - ' + $runnerProbeOut.Trim())
}

# --- The adaptation-report probe ------------------------------------------
#
# The triage used to look for the canonical report sections in the JULES PR
# BODY. Jules never writes those sections, so the check failed on all 99
# proposals and told Popy that every report was incomplete - including the
# 12 that carry a complete report on disk. The reader has to read the file
# the WRITER produced, and the two have to agree on the path.
#
# This probe demands that the reader/writer pair:
#   a) FINDS a complete report that exists on disk      -> must accept
#   b) REPORTS no report for a PR that has none         -> must not invent one
#   c) AGREES with the writer on the path               -> one source of truth
#   d) NAMES the missing section of a partial report    -> must not pass it
#
# If (a) fails, the false "report incomplete" defect returns for every
# proposal that WAS correctly adapted.
$reportProbeFile = Join-Path $probeDir ('report-probe-' + [guid]::NewGuid().ToString('N') + '.ps1')
$reportProbeSrc = @(
    '$ErrorActionPreference = ''Stop''',
    ('. ''' + $libLiteral + ''''),
    '$fail = 0',
    '$a = Get-AdaptReportState -Repo ''MAVIS-CLOUD'' -Pr ''9''',
    'if (-not $a.Exists) { Write-JulesOut ''PROBE_REPORT_BAD a: an existing report was not found''; exit 0 }',
    'if (-not $a.Complete) { Write-JulesOut (''PROBE_REPORT_BAD a: a complete report was judged incomplete, missing='' + ($a.Missing -join ''|'')); exit 0 }',
    '$b = Get-AdaptReportState -Repo ''MAVIS-CLOUD'' -Pr ''36''',
    'if ($b.Exists) { Write-JulesOut ''PROBE_REPORT_BAD b: a report was invented for a PR that has none''; exit 0 }',
    '$w = Get-AdaptReportPath -Repo ''MAVIS-CLOUD'' -Pr ''9''',
    'if ($w -ne $a.Path) { Write-JulesOut ''PROBE_REPORT_BAD c: reader and writer disagree on the path''; exit 0 }',
    '$tmpDir = Join-Path (Get-JulesRoot) ''state\tmp''',
    '$tmp = Join-Path $tmpDir (''probe-partial-'' + [guid]::NewGuid().ToString(''N'') + ''.md'')',
    '[System.IO.File]::WriteAllText($tmp, "# probe`n## Ce am schimbat`ntext`n")',
    'try {',
    '    $body = [System.IO.File]::ReadAllText($tmp)',
    '    $needed = @(''Ce am schimbat'', ''De ce'', ''Cum am verificat'')',
    '    $missing = @()',
    '    foreach ($n in $needed) { if ($body -notmatch [regex]::Escape($n)) { $missing += $n } }',
    '    if ($missing.Count -ne 2) { Write-JulesOut (''PROBE_REPORT_BAD d: expected 2 missing sections, got '' + $missing.Count); exit 0 }',
    '} finally {',
    '    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }',
    '}',
    'Write-JulesOut ''PROBE_REPORT_OK'''
) -join "`n"

$reportProbeOut = ''
try {
    [System.IO.File]::WriteAllText($reportProbeFile, ($reportProbeSrc + "`n"), (New-Object System.Text.UTF8Encoding($false)))
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $raw = & powershell -NoProfile -File $reportProbeFile 2>&1
    $ErrorActionPreference = $prevEap
    $reportProbeCode = $LASTEXITCODE
    if ($null -eq $reportProbeCode) { $reportProbeCode = -1 }
    if ($raw) { $reportProbeOut = ($raw -join "`n") }
} catch {
    $reportProbeOut = [string]$_
} finally {
    $ErrorActionPreference = 'Continue'
    if (Test-Path -LiteralPath $reportProbeFile) { Remove-Item -LiteralPath $reportProbeFile -Force -ErrorAction SilentlyContinue }
    $ErrorActionPreference = $prevEap
}

if ($reportProbeOut -match 'PROBE_REPORT_OK') {
    Write-Output 'OK   proba-raport - raportul de adaptare existent este recunoscut, cel absent nu e inventat, scriitorul si cititorul au aceeasi cale'
} else {
    $problems++
    Write-Output ('FAIL proba-raport - ' + $reportProbeOut.Trim())
}

# --- The attribution probe -----------------------------------------------
#
# A gate that blames a proposal for a failure that was already there - or
# for a failure that does not reproduce - rejects work that is fine. That
# is the direction a check must never break in.
#
# MEASURED on SENTINEL_PRIME PR #3, same commit 6f0a391b:
#   work/SENTINEL_PRIME  -> 62 passed / 1 failed  (EXIT 1)
#   clean clone           -> 63 passed / 0 failed  (EXIT 0)
# and `test_suite.py` reports 479 passed / 6 failed on the BASE branch too.
#
# This probe demands that the attribution logic:
#   a) NAMES the failing check from a real output
#   b) says ATTRIBUTABLE when the base passed
#   c) says PREEXISTING  when the base failed the same way
#   d) says MIXED        when the base failed only part of it
#   e) says ATTRIBUTABLE when every head failure is new
$attrProbeFile = Join-Path $probeDir ('attr-probe-' + [guid]::NewGuid().ToString('N') + '.ps1')
$attrProbeSrc = @(
    '$ErrorActionPreference = ''Stop''',
    ('. ''' + $libLiteral + ''''),
    '$real = @(',
    '  ''=== BrainAndMonitor ==='',',
    '  ''Status: FAIL'',',
    '  ''Passed: 46/47'',',
    '  ''Errors:'',',
    '  ''  - MCP tools report OK only on a measured handshake: expected OK, got STALE''',
    ') -join "`n"',
    '$sig = @(Get-JulesFailureSignature -Text $real)',
    'if ($sig.Count -eq 0) { Write-JulesOut ''PROBE_ATTR_BAD a: no failing check was named''; exit 0 }',
    'if (-not (@($sig | Where-Object { $_ -like ''STATUS BrainAndMonitor*'' }).Count -ge 1)) { Write-JulesOut ''PROBE_ATTR_BAD a: the failing section was not named''; exit 0 }',
    '$b = Compare-JulesFailureSets -Head @(''A'') -Base @() -BasePassed $true',
    'if ($b -ne ''ATTRIBUTABLE'') { Write-JulesOut (''PROBE_ATTR_BAD b: expected ATTRIBUTABLE, got '' + $b); exit 0 }',
    '$c = Compare-JulesFailureSets -Head @(''A'',''B'') -Base @(''A'',''B'') -BasePassed $false',
    'if ($c -ne ''PREEXISTING'') { Write-JulesOut (''PROBE_ATTR_BAD c: expected PREEXISTING, got '' + $c); exit 0 }',
    '$d = Compare-JulesFailureSets -Head @(''A'',''B'') -Base @(''A'') -BasePassed $false',
    'if ($d -ne ''MIXED'') { Write-JulesOut (''PROBE_ATTR_BAD d: expected MIXED, got '' + $d); exit 0 }',
    '$e = Compare-JulesFailureSets -Head @(''A'') -Base @(''B'') -BasePassed $false',
    'if ($e -ne ''ATTRIBUTABLE'') { Write-JulesOut (''PROBE_ATTR_BAD e: expected ATTRIBUTABLE, got '' + $e); exit 0 }',
    '$vol = @(Get-JulesFailureSignature -Text (''[FAIL] snapshot is 10774s old (bound 600s)'' + "`n" + ''[FAIL] snapshot is 12374s old (bound 600s)''))',
    'if ($vol.Count -ne 1) { Write-JulesOut (''PROBE_ATTR_BAD f: a volatile number made the signature unstable, count='' + $vol.Count); exit 0 }',
    'Write-JulesOut ''PROBE_ATTR_OK'''
) -join "`n"

$attrProbeOut = ''
try {
    [System.IO.File]::WriteAllText($attrProbeFile, ($attrProbeSrc + "`n"), (New-Object System.Text.UTF8Encoding($false)))
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $raw = & powershell -NoProfile -File $attrProbeFile 2>&1
    $ErrorActionPreference = $prevEap
    if ($raw) { $attrProbeOut = ($raw -join "`n") }
} catch {
    $attrProbeOut = [string]$_
} finally {
    $ErrorActionPreference = 'Continue'
    if (Test-Path -LiteralPath $attrProbeFile) { Remove-Item -LiteralPath $attrProbeFile -Force -ErrorAction SilentlyContinue }
    $ErrorActionPreference = $prevEap
}

if ($attrProbeOut -match 'PROBE_ATTR_OK') {
    Write-Output 'OK   proba-atribuire - esecul preexistent e PREEXISTING, cel nou e ATTRIBUTABLE, cel nemaiplicabil e MIXED'
} else {
    $problems++
    Write-Output ('FAIL proba-atribuire - ' + $attrProbeOut.Trim())
}

# --- The backlog-window probe ---------------------------------------------
#
# `gh pr list --limit 50` was the window through which the sovereign gate
# saw the proposals. MEASURED 2026-10-24: MAVIS-CLOUD had 73 open Jules PR,
# so 23 of them were invisible to the gate that is supposed to judge them.
#
# This probe compares the platform's own window against the REST count and
# demands BOTH directions:
#
#   a) the default window must see every open PR   -> must pass
#   b) a deliberately narrow window must be caught   -> must be detected
#
# If gh or the network is unavailable the probe reports UNKNOWN. It never
# reports a pass it did not measure.
$backlogProbeFile = Join-Path $probeDir ('backlog-probe-' + [guid]::NewGuid().ToString('N') + '.ps1')
$backlogProbeSrc = @(
    '$ErrorActionPreference = ''Stop''',
    ('. ''' + $libLiteral + ''''),
    '$repo = ''MAVIS-CLOUD''',
    '$logins = @()',
    '$page = 1',
    'while ($true) {',
    '    $res = Invoke-Native -Program ''gh'' -Arguments @(''api'', (''repos/apvizual-max/'' + $repo + ''/pulls?state=open&per_page=100&page='' + $page))',
    '    if ($res.ExitCode -ne 0) { Write-JulesOut (''PROBE_BACKLOG_UNKNOWN gh api exit '' + $res.ExitCode); exit 0 }',
    '    $arr = @(ConvertFrom-JulesJson -Json $res.Out)',
    '    if ($arr.Count -eq 0) { break }',
    '    foreach ($p in $arr) { $logins += [string]$p.user.login }',
    '    if ($arr.Count -lt 100) { break }',
    '    $page++',
    '}',
    '$api = @($logins | Where-Object { $_ -match ''jules|google-labs'' })',
    'if ($api.Count -eq 0) { Write-JulesOut ''PROBE_BACKLOG_UNKNOWN no open PR to compare''; exit 0 }',
    '$wide = @(Get-JulesPrs -Repo $repo)',
    '$narrow = @(Get-JulesPrs -Repo $repo -Limit 50)',
    'if ($wide.Count -ne $api.Count) { Write-JulesOut (''PROBE_BACKLOG_TRUNCATED wide='' + $wide.Count + '' api='' + $api.Count); exit 0 }',
    'if ($narrow.Count -ge $api.Count) { Write-JulesOut (''PROBE_BACKLOG_NOFALSIFY wide='' + $wide.Count + '' narrow='' + $narrow.Count + '' api='' + $api.Count); exit 0 }',
    'Write-JulesOut (''PROBE_BACKLOG_OK wide='' + $wide.Count + '' narrow='' + $narrow.Count + '' api='' + $api.Count)',
    'exit 0'
) -join "`n"

$backlogProbeOut = ''
try {
    [System.IO.File]::WriteAllText($backlogProbeFile, ($backlogProbeSrc + "`n"), (New-Object System.Text.UTF8Encoding($false)))
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $raw = & powershell -NoProfile -File $backlogProbeFile 2>&1
    $ErrorActionPreference = $prevEap
    if ($raw) { $backlogProbeOut = ($raw -join "`n") }
} catch {
    $backlogProbeOut = [string]$_
} finally {
    $ErrorActionPreference = 'Continue'
    if (Test-Path -LiteralPath $backlogProbeFile) { Remove-Item -LiteralPath $backlogProbeFile -Force -ErrorAction SilentlyContinue }
    $ErrorActionPreference = $prevEap
}

if ($backlogProbeOut -match 'PROBE_BACKLOG_OK') {
    Write-Output ('OK   proba-backlog - fereastra portii acopera tot backlog-ul (' + $backlogProbeOut.Trim() + ')')
} elseif ($backlogProbeOut -match 'PROBE_BACKLOG_TRUNCATED') {
    $problems++
    Write-Output ('FAIL proba-backlog - fereastra portii nu acopera tot backlog-ul (' + $backlogProbeOut.Trim() + ')')
} else {
    $unknown++
    Write-Output ('UNKNOWN proba-backlog - proba nu a putut fi masurata (' + $backlogProbeOut.Trim() + ')')
}

# --- The installer-truth probe -------------------------------------------
#
# The installer used to report a valid PLAN for a repo that does not exist.
# MEASURED 2026-10-24: on MAVIS-OPTIMUS-CD (404 on the API) it printed
# "PLAN: would create/update label jules" and exited 0 - the same report a
# repo whose label is merely missing gets. The priming of the CD session
# runs this installer, so a lying plan there is a broken handover.
#
# This probe demands BOTH directions:
#
#   a) a repo that does NOT exist  -> must be refused (exit 7, REPO_EXISTS=no)
#   b) a repo that DOES exist      -> must produce a plan (exit 0, REPO_EXISTS=yes)
#
# If gh is unavailable the probe reports UNKNOWN. It never reports a pass it
# did not measure.
$installProbeScript = Join-Path $ScriptsDir 'probe-install-fixture.ps1'
$installProbeOut = ''
$prevEap = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $raw = & powershell -NoProfile -File $installProbeScript 2>&1
    if ($raw) { $installProbeOut = ($raw -join "`n") }
} catch {
    $installProbeOut = [string]$_
} finally {
    $ErrorActionPreference = $prevEap
}

if ($installProbeOut -match 'PROBE_INSTALL_OK') {
    Write-Output 'OK   proba-instalare - repo inexistent refuzat (exit 7, REPO_EXISTS=no); repo existent cu plan (exit 0, REPO_EXISTS=yes)'
} elseif ($installProbeOut -match 'PROBE_INSTALL_BAD') {
    $problems++
    Write-Output ('FAIL proba-instalare - ' + $installProbeOut.Trim())
} else {
    $unknown++
    Write-Output ('UNKNOWN proba-instalare - proba nu a putut fi masurata (' + $installProbeOut.Trim() + ')')
}

# --- The push-gate behaviour probe ----------------------------------------
#
# Presence is not behaviour. This probe runs the LIVE hook file twice, inside a
# sandbox git dir, so the real PUSH-ACORD marker of this repository is never
# touched and no push can happen:
#   a) no marker  -> the hook must REFUSE (exit 1)
#   b) marker     -> the hook must ALLOW  (exit 0) and consume it
# If the sandbox or the shell cannot be produced, the probe reports UNKNOWN.

$gateProbeOut = ''
$prevEap = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $shExe = ''
    $gitCmd = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($gitCmd) {
        $gitRoot = Split-Path -Parent (Split-Path -Parent $gitCmd.Source)
        $cand = Join-Path $gitRoot 'bin\sh.exe'
        if (Test-Path -LiteralPath $cand) { $shExe = $cand }
    }
    if (-not $shExe) {
        $cand2 = 'C:\Program Files\Git\bin\sh.exe'
        if (Test-Path -LiteralPath $cand2) { $shExe = $cand2 }
    }
    if (-not $shExe) { throw 'sh.exe nu a fost gasit' }
    if (-not $gateFile) { throw 'fisierul hook nu a fost rezolvat' }

    $sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ('gate-probe-' + [guid]::NewGuid().ToString('N'))
    $fakeGit = Join-Path $sandbox 'fakegit'
    New-Item -ItemType Directory -Force -Path (Join-Path $fakeGit 'objects') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $fakeGit 'refs\heads') | Out-Null
    Set-Content -LiteralPath (Join-Path $fakeGit 'HEAD') -Value 'ref: refs/heads/main' -Encoding ascii
    Set-Content -LiteralPath (Join-Path $fakeGit 'refs\heads\main') -Value ('0' * 40) -Encoding ascii

    $oldGitDir = $env:GIT_DIR
    $env:GIT_DIR = $fakeGit
    try {
        $outA = & $shExe $gateFile 2>&1
        $codeA = $LASTEXITCODE
        $markerPath = Join-Path $fakeGit 'PUSH-ACORD'
        Set-Content -LiteralPath $markerPath -Value 'R0 probe' -Encoding ascii
        $outB = & $shExe $gateFile 2>&1
        $codeB = $LASTEXITCODE
        $markerGone = -not (Test-Path -LiteralPath $markerPath)
    } finally {
        $env:GIT_DIR = $oldGitDir
    }

    if ($codeA -ne 1) {
        $gateProbeOut = 'PROBE_GATE_BAD a: hook-ul nu a refuzat fara acord (exit=' + $codeA + ')'
    } elseif ($codeB -ne 0) {
        $gateProbeOut = 'PROBE_GATE_BAD b: hook-ul nu a permis push-ul cu acord (exit=' + $codeB + ')'
    } elseif (-not $markerGone) {
        $gateProbeOut = 'PROBE_GATE_BAD c: hook-ul nu a consumat acordul'
    } else {
        $gateProbeOut = 'PROBE_GATE_OK'
    }
    Remove-Item -LiteralPath $sandbox -Recurse -Force -ErrorAction SilentlyContinue
} catch {
    $gateProbeOut = 'PROBE_GATE_UNMEASURABLE: ' + [string]$_
} finally {
    $ErrorActionPreference = $prevEap
}

if ($gateProbeOut -match 'PROBE_GATE_OK') {
    Write-Output 'OK   proba-poarta - hook-ul refuza fara acord (exit 1) si permite cu acord (exit 0, acord consumat)'
} elseif ($gateProbeOut -match 'PROBE_GATE_BAD') {
    $problems++
    Write-Output ('FAIL proba-poarta - ' + $gateProbeOut.Trim())
} else {
    $unknown++
    Write-Output ('UNKNOWN proba-poarta - proba nu a putut fi masurata (' + $gateProbeOut.Trim() + ')')
}
}

Write-Output ('FILES=' + $files.Count + ' PROBLEMS=' + $problems + ' UNKNOWN=' + $unknown)
if ($problems -gt 0) {
    Write-Output 'POARTA A BLOCAT. Nimic nu ruleaza pana nu se repara.'
    exit 1
}
if ($unknown -gt 0) {
    Write-Output 'Porta a trecut, dar o proba nu a putut fi masurata. Necunoscutul se raporteaza, nu se presupune.'
}
Write-Output 'Toate scripturile sunt curate: ASCII pur, parse fara erori, cod de iesire necontaminat.'
exit 0
