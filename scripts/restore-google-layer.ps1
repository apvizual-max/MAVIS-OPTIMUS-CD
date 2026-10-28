# restore-google-layer.ps1
# Restores the local copy of the google-layer from its canonical source.
#
# WHY THIS FILE EXISTS
# MEASURED 2026-10-29: the local google-layer directory was found EMPTY -
# 16 files, 94186 bytes, gone - while the canonical source (the
# apvizual-max/Mavis-Google_Access repository, directory google-layer/) was
# intact. The consequence was immediate and silent-ish: the notebook tool
# answered VERDICT=LAYER_MISSING and the Gmail leg of the tri-interface
# Continuous Development was unarmed, because gmail-launcher.js and
# gworkspace-oauth.js live in that layer.
#
# The layer is a CACHE of the remote repository, not the source of truth.
# So it can be restored byte for byte, and the restore is verifiable.
#
# Usage:
#   powershell -NoProfile -File restore-google-layer.ps1            (dry-run)
#   powershell -NoProfile -File restore-google-layer.ps1 -Apply
#
# Exit codes:
#   0 = layer complete (or already complete)
#   1 = restore failed
#   2 = the source could not be read at all
#
# ASCII ONLY: executed by Windows PowerShell 5.1.

[CmdletBinding()]
param(
    [string]$Repo = 'apvizual-max/Mavis-Google_Access',
    [string]$SourceDir = 'google-layer',
    [string]$LayerPath = '',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

function Get-DefaultLayerPath {
    # The path is derived, not hardcoded: the tool that consumes the layer
    # (scripts/ask-jules-notebook.mjs) searches these roots in order.
    $candidates = @(
        (Join-Path $HOME '.minimax-agent\projects\Mavis-Optimus-Dashboard\Mavis-Google_Access\google-layer'),
        (Join-Path $HOME '.minimax-agent\projects\Mavis-Google_Access\google-layer')
    )
    foreach ($c in $candidates) { if (Test-Path -LiteralPath (Split-Path -Parent $c)) { return $c } }
    return $candidates[0]
}

function Get-SourceFiles {
    $raw = (& gh api ("repos/$Repo/contents/$SourceDir") 2>$null) -join "`n"
    if (-not $raw) { return $null }
    $list = $raw | ConvertFrom-Json
    return @($list) | Where-Object { $_.type -eq 'file' }
}

if (-not $LayerPath) { $LayerPath = Get-DefaultLayerPath }
Write-Output ('Sursa canonica : ' + $Repo + ' /' + $SourceDir)
Write-Output ('Destinatie     : ' + $LayerPath)
Write-Output ('Mod            : ' + $(if ($Apply) { 'APPLY' } else { 'DRY-RUN' }))
Write-Output ''

if (-not (Test-Path -LiteralPath (Split-Path -Parent $LayerPath))) {
    Write-Output ('EROARE: parintele destinatiei nu exista: ' + (Split-Path -Parent $LayerPath))
    exit 2
}

$files = Get-SourceFiles
if ($null -eq $files -or $files.Count -eq 0) {
    Write-Output ('EROARE: sura canonica nu a putut fi citita (repo ' + $Repo + ').')
    exit 2
}
Write-Output ('Fisiere la sursa: ' + $files.Count)

# What is missing or different, right now.
$needed = @()
foreach ($f in $files) {
    $target = Join-Path $LayerPath $f.name
    $have = $false
    if (Test-Path -LiteralPath $target) {
        if ((Get-Item -LiteralPath $target).Length -eq [int]$f.size) { $have = $true }
    }
    if (-not $have) { $needed += $f }
}
Write-Output ('Lipsesc sau difera: ' + $needed.Count)
if ($needed.Count -eq 0) {
    Write-Output 'Stratul este complet. Nu se face nimic.'
    exit 0
}
foreach ($f in $needed) { Write-Output ('  - ' + $f.name + '  (' + $f.size + ' octeti)') }

if (-not $Apply) {
    Write-Output ''
    Write-Output 'DRY-RUN. Nicio scriere nu a fost facuta. Ruleaza din nou cu -Apply.'
    exit 0
}

if (-not (Test-Path -LiteralPath $LayerPath)) {
    New-Item -ItemType Directory -Path $LayerPath -Force | Out-Null
}

$ok = 0
$failed = @()
foreach ($f in $needed) {
    try {
        $one = ((& gh api ("repos/$Repo/contents/$SourceDir/" + $f.name) 2>$null) -join "`n") | ConvertFrom-Json
        $bytes = [Convert]::FromBase64String((([string]$one.content) -replace '\s', ''))
        [System.IO.File]::WriteAllBytes((Join-Path $LayerPath $f.name), $bytes)
        $ok++
    } catch {
        $failed += $f.name
    }
}
Write-Output ''
Write-Output ('Restaurate: ' + $ok + ' | esuate: ' + $failed.Count)
foreach ($x in $failed) { Write-Output ('  FAILED: ' + $x) }

# Verify, do not assume: the count and the byte total are read back from disk.
$onDisk = @(Get-ChildItem -LiteralPath $LayerPath -File)
$bytesOnDisk = ($onDisk | Measure-Object -Property Length -Sum).Sum
$bytesSource = 0
foreach ($f in $files) { $bytesSource += [int]$f.size }
Write-Output ('Verificare pe disc: ' + $onDisk.Count + ' fisier(e), ' + $bytesOnDisk + ' octeti (sursa: ' + $files.Count + ', ' + $bytesSource + ')')

if ($failed.Count -gt 0 -or $onDisk.Count -ne $files.Count -or $bytesOnDisk -ne $bytesSource) {
    Write-Output 'Layerul nu este complet dupa refacere.'
    exit 1
}
Write-Output 'Stratul este complet si verificat.'
exit 0
