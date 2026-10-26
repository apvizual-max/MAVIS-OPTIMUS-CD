---
name: antigravity-jules-github-cd
description: Orchestrate Jules, GitHub, and Gmail Continuous Development.
author: apviz, Antigravity
platforms: [windows]
---

# Antigravity Jules GitHub Continuous Development (CD) Orchestrator

## Overview & Sovereign Doctrine
This skill orchestrates the tri-interface Continuous Development (CD) lifecycle across **Google Jules Cloud** (REST API & Web UI), **GitHub** (`gh` CLI & REST API), and **Gmail** (`google-workspace` API) under the sovereign command of **Antigravity**. It enforces the foundational doctrine: **Logic • Reason • Strategy**.

Antigravity operates as the chief executive orchestrator for the `apvizual-max` GitHub fleet and the overarching project `Optimus_CD (by Jules)` located at:
`E:\Google\GDrive\GDrive-Second_Brain_PKMS\02_Areas\02-2-AI-SOT\CASA\OPTIMUS - Prime\Optimus_CD (by Jules)`.

The user must never suffer cognitive overload from manual PR reviews, Jules dashboard question prompts, notification noise, or email clutter. Antigravity takes full, autonomous ownership of task triage, engineering second-eye verification, merging, branch pruning, email categorization, and UI hygiene.

---

## Recognized Trigger Phrases (Mode B Autonomous Run)
Whenever the user mentions any of the following triggers (or semantic equivalents):
- `"hai să aliniem jules github"`
- `"hai să vedem ce e acolo"`
- `"hai să le rezolvăm"`
- `"Antigravity fix jules and github"`
- `"hai să rezolvăm jules și github"`
- `"aliniază jules și github"`
- `"Jules a mai făcut niște lucrări"`
- `"vezi ce a făcut Jules"`

Antigravity must **immediately** execute the full Tri-Interface Continuous Sync without stopping for intermediate prompts or reviews.

---

## Core Invariants

1. **Single-Branch Remote Invariant:** Every repository under `apvizual-max` maintains only **1 active remote branch** (`main` or `master`). All ephemeral Jules branches (`jules-*`, `palette/*`, `sentinel/*`, `bolt/*`) are squash-merged into `main`, and remote feature branches are deleted immediately.
2. **Zero-Inbox & Zero-Review Clutter:** Neither GitHub Web Inbox, nor Jules web UI dashboard, nor Gmail primary inbox may hold unreviewed or blocked items. Antigravity acts as the autonomous reviewer and decision-maker.
3. **Engineering Second-Eye Review:** Antigravity does not merge blindly. Every PR diff is evaluated as lead engineer / systems administrator: verifying code safety, absence of credential leakage, absence of destructive deletions, and cross-platform compatibility.
4. **Mandatory `@jules` Mention Protocol:** Jules operates asynchronously on remote repositories and GitHub issues/PRs, but **it strictly responds only when explicitly addressed with `@jules`**. When communicating with Jules via issue comments, PR discussions, or dispatch prompts, always prefix the instruction with `@jules`.
5. **Autonomous Feedback Dispatch:** When Jules enters `AWAITING_USER_FEEDBACK`, Antigravity inspects the question, formulates the authoritative consensus decision, and dispatches it via `:interact` API.
6. **Quota & Rate-Limit Preservation:** The cloud platform imposes a quota ceiling of 100 concurrent tasks. If active tasks reach $\ge 95$, Antigravity enters Quota Preservation Mode (halts new task dispatches, focuses on unblocking existing conversations, squash-merging PRs, and purging completed tasks).
7. **Exhaustive GitHub Notification Clearance (Mark as Done):** Marking notifications as read (`PUT /notifications`) is insufficient for the GitHub Web UI. Antigravity must mark every notification thread as **Done** (`DELETE /notifications/threads/:id`), completely emptying the GitHub Web Inbox.
8. **Exhaustive Email Routing & Tagging (`Optimus CD`):** All notification emails related to Jules, GitHub, and continuous development are assigned the label `Optimus CD` (`Label_35`), categorized under `CATEGORY_UPDATES`, marked as read (`UNREAD` removed), archived from primary `INBOX`, and shielded from `SPAM`. Triage must paginate until 0 matching messages remain.
9. **Three-Drive Partitioning Compliance:** System binaries live on `C:\`, archives/VMs/pagefile on `D:\`, and active AI SOT / GDrive cloud sync on `E:\`. All operations respect NTFS directory junctions.

---

## Tooling & Script Catalog
Located at: `C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\scripts\`

| Script / Component | Purpose | Native Tool Syntax |
|---|---|---|
| `jules_github_sovereign_daemon.ps1` | Master Multi-Interface Autonomous Sync Engine | `terminal` / `powershell.exe -ExecutionPolicy Bypass -File "...\scripts\jules_github_sovereign_daemon.ps1"` |
| `run_sovereign_sync.bat` | 1-Click Interactive Batch Runner | `terminal` / `"...\scripts\run_sovereign_sync.bat"` |
| `start_sovereign_sync_silent.vbs` | Silent WScript wrapper for background scheduling | `terminal` / `wscript.exe "...\scripts\start_sovereign_sync_silent.vbs"` |
| `jules_repo_scanner.ps1` | Comprehensive 10-repo auditor (PRs, branches, ledgers) | `terminal` / `powershell.exe -ExecutionPolicy Bypass -File "...\scripts\jules_repo_scanner.ps1"` |
| `jules_dispatch.ps1` | Standardized task dispatcher to Jules Cloud REST API | `terminal` / `powershell.exe -ExecutionPolicy Bypass -File "...\scripts\jules_dispatch.ps1" -Repo apvizual-max/<name> -Persona QA -Task "..."` |
| `clear_all_github_notifications_done.ps1`| Exhaustively clears all GitHub notification threads as Done | `terminal` / `powershell.exe -ExecutionPolicy Bypass -File "...\scripts\clear_all_github_notifications_done.ps1"` |
| `google-workspace` MCP | Gmail label management, search, batch modify & filtering | `call_mcp_tool` (`listGmailMessages`, `batchAddGmailLabels`, `batchRemoveGmailLabels`) |

---

## Detailed Operating Procedures

### 1. Tri-Interface Continuous Synchronization Loop

#### Pass 1: Jules Discovery, Quota Audit & Feedback Unblock
1. **OAuth Token Resolution & Auto-Refresh:**
   - Retrieve stored OAuth Bearer token from Windows Credential Manager (`jules-cli:default`) using P/Invoke `NativeCredManager`.
   - If missing, expired, or rejected with `401 Unauthorized`, execute headless CLI probe `jules.cmd remote list --repo` to renew the token silently.
2. **Quota & Capacity Audit:**
   - Query `GET https://aida.googleapis.com/v1/swebot/tasks`.
   - Compute total cloud tasks vs 100 ceiling.
   - If tasks $\ge 95$, activate Quota Preservation Mode (block new dispatches; prioritize finishing running tasks).
3. **Autonomous Feedback Resolution:**
   - Filter tasks with `swebotTaskStatus == "SWEBOT_TASK_STATUS_AWAITING_USER_FEEDBACK"`.
   - Fetch detailed task steps (`GET /v1/swebot/tasks/{id}`).
   - Locate the latest step where `agentMessaged.requiresUserResponse == true`.
   - Formulate authoritative consensus (approving security enhancements, path canonicalization, cross-platform fixes, or test additions).
   - Dispatch `POST https://aida.googleapis.com/v1/swebot/tasks/{id}:interact` with `{ "userActivity": { "feedbackGiven": { "feedback": "...", "feedbackId": "..." }, "activityStepId": "..." } }`.

#### Pass 2: GitHub PR Convergence & Engineering Second-Eye Review
1. **Fleet PR Audit:**
   - Search open PRs in a loop until 0 remain: `gh search prs --owner apvizual-max --state open --limit 300 --json repository,number,title,author,url`.
2. **Engineering Review & Squash-Merge:**
   - Inspect PR changes: verify that modifications are clean, do not commit sensitive keys, and do not destructively alter core files (`gh pr diff $prNum -R $repoTarget --stat`).
   - Execute `gh pr merge $prNum -R $repoTarget --squash --delete-branch --admin`.
   - If merge fails due to merge conflict or empty diff (no-op), close the superseded PR: `gh pr close $prNum -R $repoTarget --delete-branch --comment "Closed superseded conflicting branch by Antigravity Autonomous Engine."`.
3. **Notification Zero (Mark as Done):**
   - Mark all notifications as read: `gh api --method PUT /notifications -f read=true`.
   - Exhaustively mark every notification thread as **Done**:
     ```powershell
     gh api -X DELETE "/notifications/threads/$id"
     ```
   - Verify unread count is 0: `gh api notifications --jq 'length'`.

#### Pass 3: Jules Web UI Dashboard Hygiene & Purge
1. **Clutter Identification:**
   - Re-query tasks from Jules cloud API.
   - Identify tasks where `isAwaitingReview == true` or `swebotTaskStatus == "SWEBOT_TASK_STATUS_COMPLETED"`.
2. **Batch Purge:**
   - Collect task IDs and delete in batches of 40: `POST https://aida.googleapis.com/v1/swebot/tasks:delete` with `{ "taskIds": [...] }`.
   - Verify that 0 tasks remain in "Ready for review", keeping the web UI clean.

#### Pass 4: Gmail Triage & Routing (`Optimus CD`)
1. **Exhaustive Querying:**
   - Retrieve all matching messages using `listGmailMessages` with `maxResults: 500`:
     `query: '(from:github.com OR from:jules OR subject:Jules OR subject:GitHub OR "apvizual-max") (is:unread OR label:inbox)'`.
   - Paginate until `listGmailMessages` returns 0 messages.
2. **Batch Labeling & Archiving:**
   - Apply labels: `Label_35` (`Optimus CD`) and `CATEGORY_UPDATES` via `batchAddGmailLabels`.
   - Remove labels: `UNREAD` (mark as read) and `INBOX` (archive from primary inbox) via `batchRemoveGmailLabels`.
3. **Filter Persistence:**
   - Maintain active Gmail filter `ANe1Bmh4apfrWZA0T6Dx1Ha8qm8sLNXnDWtPevfLsJ8QCQ` ensuring all future incoming notifications automatically bypass the inbox and receive `Optimus CD` + `CATEGORY_UPDATES`.

---

## Pitfalls & Solutions

- **Pitfall 1: Interactive Bubbletea CLI Hangs in Background Tasks**  
  *Root Cause:* Running `jules new` invokes an interactive Bubbletea terminal UI that blocks indefinitely when stdin/stdout are redirected.  
  *Solution:* Never call `jules new` via CLI; always dispatch tasks directly to the cloud REST endpoint `POST https://aida.googleapis.com/v1/swebot/tasks`.

- **Pitfall 2: Ephemeral OAuth Callback Link Misidentification**  
  *Root Cause:* URLs like `http://127.0.0.1:52656/callback?code=...` appear in browser history and seem to be lost local projects.  
  *Solution:* Recognize that `jules login` creates an ephemeral local HTTP loopback server to receive the authorization code. It is an auth completion landing page, not a missing project.

- **Pitfall 3: Jules Web UI "Ready for review" Accumulation**  
  *Root Cause:* Jules flags every task that creates a branch with `isAwaitingReview: true`. These tasks linger indefinitely on the web dashboard.  
  *Solution:* Batch-delete completed tasks via `POST https://aida.googleapis.com/v1/swebot/tasks:delete` with `{ "taskIds": [...] }` after PRs are merged.

- **Pitfall 4: Jules Task Stalling on `AWAITING_USER_FEEDBACK`**  
  *Root Cause:* Jules pauses when it needs architectural confirmation before creating a PR.  
  *Solution:* Extract the OAuth token from Windows Credential Manager (`jules-cli:default`) and POST an unblocking response to `https://aida.googleapis.com/v1/swebot/tasks/{id}:interact`.

- **Pitfall 5: Jules Missing Instructions without `@jules` Tag**  
  *Root Cause:* Posting a comment or issue on GitHub without `@jules` does not trigger the Jules GitHub App webhook listener.  
  *Solution:* Always prefix any instruction or review comment intended for Jules with `@jules` (e.g. `@jules please update the test suite`).

- **Pitfall 6: GitHub GraphQL `"mergeable": "UNKNOWN"` False Rejection**  
  *Root Cause:* GitHub's API frequently returns `"mergeable": "UNKNOWN"` while calculating background mergeability, causing scripts checking for `"MERGEABLE"` to skip valid PRs.  
  *Solution:* Attempt `gh pr merge --squash --delete-branch --admin` directly. If mergeable, GitHub executes successfully (exit code 0); if genuine conflicts exist, catch the error and execute `gh pr close --delete-branch`.

- **Pitfall 7: Email Influx Cluttering Primary Inbox**  
  *Root Cause:* High-frequency Jules commits and PR notifications flood the primary Gmail inbox, overwhelming the user.  
  *Solution:* Filter and route all CD notifications to `CATEGORY_UPDATES` with label `Optimus CD`, removing `INBOX` and marking as read automatically. Paginate with `maxResults: 500` until 0 matching messages remain.

- **Pitfall 8: GitHub Web Inbox Retaining "Read" Notifications**  
  *Root Cause:* Running `PUT /notifications` marks notifications as read, but GitHub Web UI keeps them in the Inbox view until they are explicitly marked as "Done".  
  *Solution:* Invoke `DELETE /notifications/threads/:thread_id` on all active notification threads to acknowledge and remove them from the GitHub Inbox view.

---

## Modular Sub-Skills Architecture
To prevent cognitive overload and allow fine-grained autonomous intervention, the master Continuous Development engine delegates to three specialized sub-skills when individual tasks are requested:

1. [`antigravity-jules-cloud-admin`](file:///C:/Users/apviz/Documents/Antigravity_Folder/Antigravity_Projects/Antigravity_JULES_INT/skills/antigravity-jules-cloud-admin/SKILL.md): Dedicated strictly to Jules cloud tasks, feedback deblocking (`:interact`), proposal reviews, quota preservation, and web dashboard purge (`:delete`).
   - *Targeted Triggers:* `"ocupă-te de Jules"`, `"verifică Jules"`, `"deblochează Jules"`, `"răspunde-i lui Jules"`, `"curăță dashboard-ul Jules"`.
2. [`antigravity-github-fleet-manager`](file:///C:/Users/apviz/Documents/Antigravity_Folder/Antigravity_Projects/Antigravity_JULES_INT/skills/antigravity-github-fleet-manager/SKILL.md): Dedicated strictly to the 10-repo GitHub fleet, Engineering Second-Eye PR reviews, squash-merging, single-branch invariant enforcement, and Web Inbox Zero (`DELETE /notifications/threads/:id`).
   - *Targeted Triggers:* `"ocupă-te de GitHub"`, `"verifică GitHub"`, `"fă merge-urile pe GitHub"`, `"curăță inbox-ul GitHub"`.
3. [`antigravity-gmail-optimus-cd`](file:///C:/Users/apviz/Documents/Antigravity_Folder/Antigravity_Projects/Antigravity_JULES_INT/skills/antigravity-gmail-optimus-cd/SKILL.md): Dedicated strictly to triaging notification emails in `apvizual@gmail.com`, applying `Optimus CD` (`Label_35`) and `CATEGORY_UPDATES`, unreading, and archiving from Inbox.
   - *Targeted Triggers:* `"ocupă-te de email"`, `"triază emailurile"`, `"curăță inbox-ul de mail"`, `"marchează mailurile Optimus CD"`.

---

## Google Notebooks (NotebookLM) Fleet Integration
The Continuous Development subsystem maintains three dedicated notebooks on Google Notebooks (formerly NotebookLM) accessible by both Antigravity and Mavis:
1. **Jules Cloud Intelligence Notebook:** Session histories, architectural proposal reviews, and successful prompt engineering cards.
2. **GitHub Fleet Architecture Notebook:** Repository schemas, commit changelogs, PR diff audits, and branch governance registers.
3. **Email Telemetry & Digest Notebook:** Notification volume metrics, error alert logs, and triage patterns.
- **Reference Index:** `E:\Google\GDrive\GDrive-Second_Brain_PKMS\02_Areas\02-2-AI-SOT\CASA\OPTIMUS - Prime\Optimus_CD (by Jules)\docs\NOTEBOOKS_INDEX.md`.
