# probe-install-fixture.ps1
# Proves that jules-install.ps1 can still REFUSE a repo that does not exist.
#
# WHY THIS IS A SEPARATE FILE AND NOT AN INLINE STRING:
# The probe used to be an inline string inside jules-selfcheck.ps1, and its
# "missing repo" fixture was the literal MAVIS-OPTIMUS-CD - a real repo that
# was declared in the registry but did not exist on GitHub yet. On
# 2026-10-28 that repo was created, the premise DECAYED, and the gate
# failed for the wrong reason: the installer was RIGHT and the probe was
# STALE. A probe whose fixture can stop being true is not a probe, it is a
# date.
#
# WHAT IT MEASURES NOW - both directions, with a fixture that cannot decay:
#   a) a repo that is IN the registry but NOT on GitHub -> exit 7,
#      REPO_EXISTS=no  (a plan for a repo that does not exist is fiction)
#   b) a repo that is in the registry AND on GitHub    -> exit 0,
#      REPO_EXISTS=yes
#
# HOW: it builds an ISOLATED copy of the platform under state/tmp/ with its
# own registry, and puts a GUID-named fixture in it. A GUID cannot exist on
# GitHub, so the premise holds forever. The real registry is never touched.
#
# OUTPUT (stdout, always exit 0 - the caller reads the verdict):
#   PROBE_INSTALL_OK
#   PROBE_INSTALL_BAD <reason>
#   PROBE_INSTALL_UNKNOWN <reason>
#
# ASCII ONLY: executed by Windows PowerShell 5.1.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

$root = Split-Path -Parent $PSScriptRoot
$isoRoot = Join-Path $root 'state\tmp\install-probe-platform'

function Emit([string]$text) {
    [Console]::Out.WriteLine($text)
}

try {
    if (Test-Path -LiteralPath $isoRoot) {
        Remove-Item -LiteralPath $isoRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path (Join-Path $isoRoot 'scripts') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $isoRoot 'config') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $isoRoot 'workflows') -Force | Out-Null

    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'jules-lib.ps1') -Destination (Join-Path $isoRoot 'scripts\jules-lib.ps1') -Force
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'jules-install.ps1') -Destination (Join-Path $isoRoot 'scripts\jules-install.ps1') -Force
    Copy-Item -LiteralPath (Join-Path $root 'workflows\jules.yml') -Destination (Join-Path $isoRoot 'workflows\jules.yml') -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath (Join-Path $root 'workflows\verify.yml') -Destination (Join-Path $isoRoot 'workflows\verify.yml') -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath (Join-Path $root 'config\jules-context.md') -Destination (Join-Path $isoRoot 'config\jules-context.md') -Force -ErrorAction SilentlyContinue

    $reg = Get-Content -LiteralPath (Join-Path $root 'config\repos.json') -Raw | ConvertFrom-Json
    $fixture = 'mavis-probe-missing-' + [guid]::NewGuid().ToString('N')
    $entry = [pscustomobject]@{
        name = $fixture
        remote = ('https://github.com/apvizual-max/' + $fixture)
        branch = 'main'
        private = $true
        triage = $false
        dispatch = $false
        jules = [pscustomobject]@{ label = $false; workflow = $false; secret = $false; openPrs = 0; measuredAt = '2026-10-28' }
        verify = [pscustomobject]@{ mode = 'auto'; autoDetect = $true; commands = @() }
        notes = 'probe fixture - declared in the registry, impossible on GitHub'
    }
    $reg.repos = @($reg.repos) + @($entry)
    $reg | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $isoRoot 'config\repos.json') -Encoding UTF8

    $installer = Join-Path $isoRoot 'scripts\jules-install.ps1'
    $logDir = Join-Path $isoRoot 'logs'

    $a = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer -Repo $fixture -LogDir $logDir 2>&1 | Out-String
    $codeA = $LASTEXITCODE
    $b = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer -Repo 'MAVIS-CLOUD' -LogDir $logDir 2>&1 | Out-String
    $codeB = $LASTEXITCODE

    if ($codeA -eq 2 -and $codeB -eq 2) {
        Emit 'PROBE_INSTALL_UNKNOWN gh unavailable'
        exit 0
    }
    if ($codeA -ne 7) {
        Emit ('PROBE_INSTALL_BAD a: a missing repo was not refused, exit ' + $codeA)
        exit 0
    }
    if ($a -notmatch 'REPO_EXISTS=no') {
        Emit 'PROBE_INSTALL_BAD a: the report did not say REPO_EXISTS=no'
        exit 0
    }
    if ($codeB -ne 0) {
        Emit ('PROBE_INSTALL_BAD b: an existing repo was refused, exit ' + $codeB)
        exit 0
    }
    if ($b -notmatch 'REPO_EXISTS=yes') {
        Emit 'PROBE_INSTALL_BAD b: the report did not say REPO_EXISTS=yes'
        exit 0
    }
    Emit 'PROBE_INSTALL_OK'
    exit 0
} catch {
    Emit ('PROBE_INSTALL_UNKNOWN ' + $_.Exception.Message)
    exit 0
}
