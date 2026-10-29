<#
.SYNOPSIS
    Antigravity Sovereign Dual-Interface Continuous Development & Autonomous Sync Daemon
    Orchestrates Google Jules Cloud API and GitHub API (account: apvizual-max)
    Enforces Zero-Inbox, Single-Branch Invariant, Quota Preservation, and Autonomous Task Resolution.

.DESCRIPTION
    Pass 1: Jules Task Discovery, OPEN-capacity Audit (15 concurrent slots),
    and delegation of the autonomous answers to jules-autopilot.ps1
    Pass 2: Audits, squash-merges, prunes branches, and cleans all open GitHub PRs & notifications
    Pass 3: Purges lingering "Ready for review" completed tasks from Jules cloud dashboard
    Pass 4: Single-Branch Invariant sweep (orphan ephemeral branches); the full forensic execution is logged to SOVEREIGN_MAINTENANCE_LOG.md
#>

[CmdletBinding()]
param(
    [string]$RepoOwner = "apvizual-max",
    [switch]$Silent = $false
)

$ErrorActionPreference = "Continue"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$logDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'reports'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = Join-Path $logDir "SOVEREIGN_MAINTENANCE_LOG.md"

# MEASURED 2026-10-29: Add-Content opens the log without a write share, so a
# concurrent reader (or a second writer) makes the write fail with "The
# process cannot access the file because it is being used by another process"
# - and the entry is LOST. Measured on this repo: the 02:34 run lost 2 lines
# that way (the Pass 3 and Pass 4 headers). A journal write must never kill
# the run it describes, and it must never disappear silently. It retries,
# counts the loss and reports it at the end. Same idiom as jules-lib.ps1 and
# run-jules-daily-logged.ps1.
$script:LogWriteFailures = 0
function Write-LogLine([string]$entry) {
    $written = $false
    for ($attempt = 1; $attempt -le 5 -and -not $written; $attempt++) {
        try {
            Add-Content -LiteralPath $logFile -Value $entry -Encoding UTF8 -ErrorAction Stop
            $written = $true
        } catch {
            Start-Sleep -Milliseconds (250 * [math]::Pow(2, $attempt - 1))
        }
    }
    if (-not $written) { $script:LogWriteFailures++ }
}

function Log-Message([string]$msg) {
    $entry = "[$(Get-Date -Format 'HH:mm:ss')] $msg"
    if (-not $Silent) { Write-Host $entry }
    Write-LogLine $entry
}

Write-LogLine "`n## Sync Execution: $timestamp"
Log-Message "=== Starting Antigravity Sovereign Dual-Interface Sync ==="

# ==========================================
# CREDENTIAL HELPER (Windows Credential Manager)
# ==========================================
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class NativeCredManager {
    [DllImport("Advapi32.dll", EntryPoint = "CredReadW", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool CredRead(string target, int type, int reservedFlag, out IntPtr credentialPtr);

    [DllImport("Advapi32.dll", SetLastError = true)]
    public static extern void CredFree(IntPtr cred);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct CREDENTIAL {
        public int Flags;
        public int Type;
        public string TargetName;
        public string Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public int CredentialBlobSize;
        public IntPtr CredentialBlob;
        public int Persist;
        public int AttributeCount;
        public IntPtr Attributes;
        public string TargetAlias;
        public string UserName;
    }

    public static string GetPassword(string target) {
        IntPtr credPtr;
        if (CredRead(target, 1, 0, out credPtr)) {
            CREDENTIAL cred = (CREDENTIAL)Marshal.PtrToStructure(credPtr, typeof(CREDENTIAL));
            byte[] passwordBytes = new byte[cred.CredentialBlobSize];
            Marshal.Copy(cred.CredentialBlob, passwordBytes, 0, cred.CredentialBlobSize);
            CredFree(credPtr);
            return Encoding.UTF8.GetString(passwordBytes);
        }
        return null;
    }
}
"@ -ErrorAction SilentlyContinue

function Refresh-JulesToken {
    Log-Message "Triggering automated Jules OAuth token refresh via CLI..."
    try {
        cmd.exe /c "jules.cmd remote list --repo 2>nul" | Out-Null
    } catch { }
}

function Get-JulesToken {
    $tokenJson = [NativeCredManager]::GetPassword("jules-cli:default")
    if ($tokenJson) {
        try {
            $parsed = ConvertFrom-Json $tokenJson
            if ($parsed.token.access_token) {
# Check expiration if available
                if ($parsed.token.expiry) {
                    $exp = [DateTime]::Parse($parsed.token.expiry)
                    if ((Get-Date) -ge $exp) {
                        Refresh-JulesToken
                        return Get-JulesToken
                    }
                }
                return $parsed.token.access_token
            }
            if ($parsed.access_token) {
                if ($parsed.expiry) {
                    $exp = [DateTime]::Parse($parsed.expiry)
                    if ((Get-Date) -ge $exp) {
                        Refresh-JulesToken
                        return Get-JulesToken
                    }
                }
                return $parsed.access_token
            }
        } catch { }
    }
    return $null
}

$julesToken = Get-JulesToken
if (-not $julesToken) {
    Refresh-JulesToken
    $julesToken = Get-JulesToken
}

$julesHeaders = @{}
if ($julesToken) {
    $julesHeaders = @{
        "Authorization" = "Bearer $julesToken"
        "Content-Type" = "application/json"
    }
    Log-Message "Jules Cloud OAuth token loaded successfully."
} else {
    Log-Message "WARNING: Jules OAuth token not found in Windows Credential Manager."
}

# ==========================================
# PASS 1: JULES TASK AUDIT, QUOTA & UNBLOCK
# ==========================================
Log-Message "--- PASS 1: Jules Task Discovery, Quota Audit & Autonomous Feedback ---"
if ($julesToken) {
    try {
        $taskRes = $null
        try {
            $taskRes = Invoke-RestMethod -Uri "https://aida.googleapis.com/v1/swebot/tasks" -Method Get -Headers $julesHeaders
        } catch {
            if ($_.Exception.Response.StatusCode -eq [System.Net.HttpStatusCode]::Unauthorized) {
                Log-Message "Received 401 Unauthorized. Auto-refreshing OAuth token..."
                Refresh-JulesToken
                $julesToken = Get-JulesToken
                $julesHeaders["Authorization"] = "Bearer $julesToken"
                $taskRes = Invoke-RestMethod -Uri "https://aida.googleapis.com/v1/swebot/tasks" -Method Get -Headers $julesHeaders
            } else {
                throw $_
            }
        }

        $tasks = $taskRes.tasks
        $totalTaskCount = if ($tasks) { $tasks.Count } else { 0 }

        # MEASURED 2026-10-29 (Popy's rule): Jules holds at most 15 tasks at
        # the same time. Beyond that he starts failing and stops answering.
        #
        # The old model here was WRONG in a way that caused the flood: it
        # compared the number of ALL tasks (including every COMPLETED one,
        # which never goes away) against a quota of 100. So the headroom
        # always looked huge and the daemon kept dispatching - while the
        # real limit was 15 OPEN tasks. On this account there were 17 open
        # sessions before the correction: over the limit, which is exactly
        # when Jules goes silent.
        #
        # The capacity that matters is the OPEN one.
        $maxOpenTasks = 15
        $inProgress = @($tasks | Where-Object { $_.swebotTaskStatus -eq "SWEBOT_TASK_STATUS_IN_PROGRESS" -or $_.taskStatus -eq "IN_PROGRESS" }).Count
        $awaitingFeedbackCount = @($tasks | Where-Object { $_.swebotTaskStatus -eq "SWEBOT_TASK_STATUS_AWAITING_USER_FEEDBACK" -or $_.taskStatus -eq "AWAITING_USER_FEEDBACK" }).Count
        $openTaskCount = $inProgress + $awaitingFeedbackCount
        $headroom = [Math]::Max(0, $maxOpenTasks - $openTaskCount)

        $awaitingReview = @($tasks | Where-Object { $_.isAwaitingReview -eq $true }).Count
        $completedCount = @($tasks | Where-Object { $_.swebotTaskStatus -eq "SWEBOT_TASK_STATUS_COMPLETED" -or $_.taskStatus -eq "COMPLETED" }).Count

        Log-Message "Jules Cloud Capacity Audit: $openTaskCount OPEN tasks (In-Progress: $inProgress | Awaiting Feedback: $awaitingFeedbackCount) of $maxOpenTasks concurrent slots. Headroom: $headroom."
        Log-Message "Historical totals: $totalTaskCount tasks ever created, $completedCount completed, $awaitingReview awaiting review."

        if ($openTaskCount -ge $maxOpenTasks) {
            Log-Message "CONCURRENT CEILING REACHED ($openTaskCount/$maxOpenTasks open tasks). Entering Quota Preservation Mode."
            Log-Message "Strategy: No new tasks will be dispatched. Focusing exclusively on driving in-progress tasks to completion, approving feedback, merging PRs, and purging completed tasks."
        } else {
            Log-Message "Capacity is healthy ($headroom slots available for dispatch)."
        }

        $awaitingFeedback = $tasks | Where-Object { 
            $_.swebotTaskStatus -eq "SWEBOT_TASK_STATUS_AWAITING_USER_FEEDBACK" -or $_.taskStatus -eq "AWAITING_USER_FEEDBACK" 
        }

        if ($awaitingFeedback.Count -gt 0) {
            # MEASURED 2026-10-29: the answer that used to be sent from here
            # ("Approved. Proceed with the proposed improvements...") was
            # MEASURED NOT to release the agent. Session 3384046284391976636
            # received four such answers and stayed blocked through all four:
            # the real release is a NEW devBoxStarted step, and a bare
            # approval does not produce one. The answer has to carry the
            # SUBSTANCE of the question before the approval.
            #
            # So the daemon does not answer any more. It delegates to
            # jules-autopilot.ps1 - the instrument that was MEASURED to work:
            # substance-first answer, :interact before :sendMessage, and a
            # guard on devBoxStarted instead of the lagging public state.
            # One instrument answers, so the weak duplicate cannot undo the
            # good one.
            #
            # The autopilot also EXCLUDES MAVIS-CLOUD by default, which is
            # what we want: Jules works there and we do not touch it.
            $autopilot = Join-Path $PSScriptRoot 'jules-autopilot.ps1'
            if (Test-Path -LiteralPath $autopilot) {
                Log-Message "Delegating autonomous answers to jules-autopilot.ps1 ($($awaitingFeedback.Count) tasks awaiting feedback). MAVIS-CLOUD is excluded there by default."
                try {
                    $apOut = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $autopilot -Apply 2>&1 | Out-String
                    $apCode = $LASTEXITCODE
                    if ($apOut) { Log-Message ("jules-autopilot.ps1: " + $apOut.Trim()) }
                    if ($apCode -ne 0) { Log-Message "jules-autopilot.ps1 reported exit code $apCode - answers may be incomplete." }
                } catch {
                    Log-Message "Delegation to jules-autopilot.ps1 failed: $_"
                }
            } else {
                Log-Message "jules-autopilot.ps1 not found - no answers sent (a bare approval does not release the agent; MEASURED 2026-10-28)."
            }
        } else {
            Log-Message "Zero Jules tasks awaiting user feedback. All tasks running or resolved."
        }
    } catch {
        Log-Message "Pass 1 Jules query exception: $_"
    }
}

# ==========================================
# PASS 2: GITHUB PULL REQUESTS & NOTIFICATIONS
# ==========================================
Log-Message "--- PASS 2: GitHub PR Convergence & Single-Branch Enforcement ---"
try {
    $loopCount = 0
    $maxLoops = 5
    do {
        $loopCount++
        $openPrsRaw = gh search prs --owner $RepoOwner --state open --limit 300 --json repository,number,title,author,url 2>$null
        $openPrs = if ($openPrsRaw) { ConvertFrom-Json $openPrsRaw } else { @() }
        
        if ($openPrs.Count -gt 0) {
            Log-Message "[Pass 2 - Batch $loopCount] Open PRs detected on GitHub: $($openPrs.Count)"
            foreach ($pr in $openPrs) {
                $rName = $pr.repository.name
                $prNum = $pr.number
                $repoTarget = "$RepoOwner/$rName"
                Log-Message "Auditing & Processing $repoTarget PR #$prNum ('$($pr.title)')..."

# Engineering Second-Eye: Inspect diff summary
                $diffSummary = gh pr diff $prNum -R $repoTarget --stat 2>$null
                if ($diffSummary) {
                    $firstLine = ($diffSummary -split "`n")[0]
                    Log-Message "  Diff summary: $firstLine"
                }

# Attempt squash merge
                $mergeSuccess = $false
                try {
                    $out = gh pr merge $prNum -R $repoTarget --squash --delete-branch --admin 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Log-Message "  PR #$prNum verified, squash-merged, and branch deleted cleanly."
                        $mergeSuccess = $true
                    }
                } catch { }

# If conflict or no-op, close superseded PR
                if (-not $mergeSuccess) {
                    Log-Message "  PR #$prNum has conflicts or is a no-op. Closing superseded PR..."
                    gh pr close $prNum -R $repoTarget --delete-branch --comment "Closed superseded conflicting/no-op branch by Antigravity Autonomous Engine." 2>&1 | Out-Null
                    Log-Message "  PR #$prNum closed and feature branch deleted."
                }
            }
        } else {
            Log-Message "Zero open PRs on GitHub. Fleet is 100% clean."
            break
        }
    } while ($openPrs.Count -gt 0 -and $loopCount -lt $maxLoops)

# Clear GitHub notifications badge and mark threads as DONE
    Log-Message "Clearing GitHub notifications and marking threads as DONE..."
    gh api --method PUT /notifications 2>&1 | Out-Null
    
# Exhaustively mark all notification threads as DONE (removes from GitHub web inbox)
    $doneRound = 0
    do {
        $doneRound++
        $threadRaw = gh api "/notifications?all=true&per_page=100" 2>$null
        $threads = if ($threadRaw) { ConvertFrom-Json $threadRaw } else { @() }
        if ($threads.Count -eq 0) { break }
        
        Log-Message "  [Notif Batch $doneRound] Marking $($threads.Count) notification threads as DONE..."
        foreach ($th in $threads) {
            gh api -X DELETE "/notifications/threads/$($th.id)" 2>$null | Out-Null
        }
    } while ($threads.Count -gt 0 -and $doneRound -lt 10)

    $remainingNotifs = (gh api "/notifications?all=true" 2>$null | ConvertFrom-Json).Count
    Log-Message "GitHub notification threads remaining in inbox: $remainingNotifs"
} catch {
    Log-Message "Pass 2 GitHub exception: $_"
}

# ==========================================
# PASS 3: JULES DASHBOARD HYGIENE & PURGE
# ==========================================
Log-Message "--- PASS 3: Jules Web UI Dashboard Hygiene ---"
if ($julesToken) {
    try {
        $verifyRes = Invoke-RestMethod -Uri "https://aida.googleapis.com/v1/swebot/tasks" -Method Get -Headers $julesHeaders
        $allTasks = $verifyRes.tasks

# Find completed tasks lingering with isAwaitingReview = true, or completed/failed clutter
        $tasksToPurge = $allTasks | Where-Object { 
            ($_.isAwaitingReview -eq $true) -or 
            ($_.swebotTaskStatus -eq "SWEBOT_TASK_STATUS_COMPLETED") -or 
            ($_.taskStatus -eq "COMPLETED")
        }

        if ($tasksToPurge.Count -gt 0) {
            Log-Message "Found $($tasksToPurge.Count) completed/review tasks on Jules UI. Purging in batches..."
            $chunkSize = 40
            $ids = $tasksToPurge | ForEach-Object { $_.id }
            for ($i = 0; $i -lt $ids.Count; $i += $chunkSize) {
                $currentChunk = $ids[$i..([Math]::Min($i + $chunkSize - 1, $ids.Count - 1))]
                $body = @{ "taskIds" = $currentChunk } | ConvertTo-Json -Depth 3
                $delUrl = "https://aida.googleapis.com/v1/swebot/tasks:delete"
                Invoke-RestMethod -Uri $delUrl -Method Post -Headers $julesHeaders -Body $body | Out-Null
            }
            Log-Message "All lingering completed tasks purged from Jules dashboard."
        } else {
            Log-Message "Zero lingering completed/review tasks on Jules dashboard."
        }
    } catch {
        Log-Message "Pass 3 Jules cleanup exception: $_"
    }
}

# ==========================================
# PASS 4: SINGLE-BRANCH INVARIANT SWEEP
# ==========================================
Log-Message "--- PASS 4: Single-Branch Invariant sweep (orphan ephemeral branches) ---"
$sweepScript = Join-Path $PSScriptRoot 'sweep-orphan-branches.ps1'
if (Test-Path -LiteralPath $sweepScript) {
    try {
        $sweepOut = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $sweepScript -Apply 2>&1 | Out-String
        $sweepCode = $LASTEXITCODE
        $sweepText = $sweepOut.Trim()
        if ($sweepText) { Log-Message $sweepText }
        if ($sweepCode -ne 0) {
            Log-Message "Pass 4 sweep reported exit code $sweepCode - invariant not fully restored."
        }
    } catch {
        Log-Message "Pass 4 sweep exception: $_"
    }
} else {
    Log-Message "Pass 4 sweep skipped: sweep-orphan-branches.ps1 not found."
}

Log-Message "=== Antigravity Sovereign Dual-Interface Sync Finished Successfully ==="
Write-LogLine "`n---\n"
if ($script:LogWriteFailures -gt 0) {
    Write-Host ('LOG WRITE FAILURES: ' + $script:LogWriteFailures + ' - ' + $logFile)
}
