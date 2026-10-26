---
name: antigravity-github-fleet-manager
description: Manage GitHub fleet PRs, second-eye reviews, and inbox.
author: apviz, Antigravity
platforms: [windows]
---

# GitHub Fleet, PR & Inbox Zero Manager Skill

## Overview & Sovereign Doctrine
This skill governs the complete administration, pull request judging, merge orchestration, branch pruning, and web inbox clearance for the **GitHub Repository Fleet** under organization/account `apvizual-max`.
It enforces the doctrine: **Logic • Reason • Strategy**.

When commanded to handle GitHub, Antigravity (and Mavis in MiniMax Code) evaluates all open PRs with an Engineering Second-Eye review, squash-merges valid code into `main`, prunes ephemeral branches, closes superseded/conflicting PRs, and acknowledges all notification threads as **Done** (`DELETE /notifications/threads/:id`), achieving true Web Inbox Zero.

---

## Recognized Trigger Phrases (Mode B Autonomous Run)
Whenever the user mentions any of the following triggers (or semantic equivalents):
- `"ocupă-te de GitHub"`
- `"verifică GitHub"`
- `"fă merge-urile pe GitHub"`
- `"curăță inbox-ul GitHub"`
- `"verifică PR-urile pe GitHub"`
- `"auditează depozitele GitHub"`
- `"aliniază GitHub"`

The agent must immediately execute the complete GitHub Fleet Convergence and Notification Cleansing routine without intermediate prompts.

---

## Core Invariants for GitHub Fleet Management

1. **Single-Branch Remote Invariant:**
   - Every repository maintains strictly **1 active remote branch** (`main` or `master`).
   - All feature branches created by Jules or external tools (`jules-*`, `palette/*`, `sentinel/*`, `bolt/*`) are strictly ephemeral.
   - Upon squash-merging, the remote branch must be deleted immediately.
2. **Engineering Second-Eye Review (Zero Blind Merges):**
   - Never merge pull requests blindly.
   - Inspect the diff (`gh pr diff $id -R $repo --stat`).
   - Verify:
     * No committed secrets, API tokens, or private keys.
     * No hardcoded OS-specific paths (enforce `os.path.normpath` or `pathlib`).
     * No destructive deletions of core architectures, configuration schemas, or doctrine files.
3. **Web Inbox Zero (Mark as Done vs Read):**
   - Running `PUT /notifications -f read=true` only marks notifications as read. On `github.com/notifications`, threads remain visible in the Inbox view.
   - The agent MUST execute `DELETE /notifications/threads/:thread_id` on all active notification threads to acknowledge them and clear them from the web inbox.
4. **Autonomous Conflict Resolution & Superseded PR Pruning:**
   - If a PR has genuine merge conflicts or empty diffs, close it with `gh pr close $id -R $repo --delete-branch --comment "Closed superseded conflicting branch by Antigravity Autonomous Engine."`.
5. **Sovereign Ledger Maintenance:**
   - Maintain and verify `JULES_HANDOFF.md` at the root of every repository.

---

## Complete Fleet Inventory (10 Repositories)

| # | Repository Target | Visibility | Core Focus & Architecture | Default Branch |
|---|---|---|---|---|
| 1 | `apvizual-max/SENTINEL_PRIME` | Public | Master cognitive core, system truth, and sovereign contracts | `main` |
| 2 | `apvizual-max/Hermes_Local_Configuration_Engine` | Public | Dynamic model healing, FastAPI/Uvicorn runtime, MCP routing | `main` |
| 3 | `apvizual-max/Antigravity_Projects_Portfolio` | Public | Creative portfolio, 3D ecosystems, and web showcases | `main` |
| 4 | `apvizual-max/Sovereign_PKMS_Obsidian` | Public | PKMS Obsidian mirrored vault, bi-directional sync | `main` |
| 5 | `apvizual-max/OmniRoute_AI_Gateway` | Public | Docker proxy routing, free-tier model failovers | `main` |
| 6 | `apvizual-max/Sentinel_Tools_Terminal` | Public | Command center telemetry, daemon supervisor | `main` |
| 7 | `apvizual-max/MAVIS_OPTIMUS_CI` | Public | Continuous Integration bridge, local-cloud sync | `main` |
| 8 | `apvizual-max/MAVIS-OPTIMUS-CD` | Public | Continuous Development SOT, runbooks, procedures | `main` |
| 9 | `apvizual-max/Google_Drive_Sync_Engine` | Public | Google Drive desktop sync doctor, junction repair | `main` |
| 10 | `apvizual-max/CLI_Fleet_Orchestrator` | Public | 26-CLI sovereign fleet automation, Mode B loops | `main` |

---

## Google Notebooks (NotebookLM) Integration
The GitHub fleet has a dedicated notebook on Google Notebooks (formerly NotebookLM) maintained for continuous development:
- **Notebook Name:** `Optimus CD — GitHub Fleet Architecture & PR History`
- **Usage:** Antigravity and Mavis query and update this notebook to reference repository schemas, PR histories, commit diff changelogs, and branch governance records.
- **Reference URL/Context:** Configured in `E:\Google\GDrive\GDrive-Second_Brain_PKMS\02_Areas\02-2-AI-SOT\CASA\OPTIMUS - Prime\Optimus_CD (by Jules)\docs\NOTEBOOKS_INDEX.md`.

---

## Tooling & Command Specification

### 1. Fleet-Wide Open PR Discovery
```powershell
gh search prs --owner apvizual-max --state open --limit 300 --json repository,number,title,author,url,headRefName
```

### 2. Engineering Diff Inspection
```powershell
gh pr diff $prNum -R $repoTarget --stat
```

### 3. Squash-Merge with Remote Branch Deletion
```powershell
gh pr merge $prNum -R $repoTarget --squash --delete-branch --admin
```

### 4. Close Conflicting / Superseded PRs
```powershell
gh pr close $prNum -R $repoTarget --delete-branch --comment "Closed superseded conflicting branch by Antigravity Autonomous Engine."
```

### 5. Clear GitHub Web Inbox Notifications (Mark as Done)
- **Script:** `C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\scripts\clear_all_github_notifications_done.ps1`
- **Inline Command:**
  ```powershell
  # Mark as read
  gh api --method PUT /notifications -f read=true
  # Mark each active thread as Done
  $threads = gh api "/notifications" | ConvertFrom-Json
  foreach ($t in $threads) {
      gh api -X DELETE "/notifications/threads/$($t.id)"
  }
  ```

---

## Operating Procedure (Step-by-Step GitHub Run)

1. **Pasul 1 — Scanare Flotă Repozitoare:**
   - Interoghează toate PR-urile deschise pe `apvizual-max` folosind `gh search prs`.
   - Raportează numărul de PR-uri identificate și depozitele afectate.
2. **Pasul 2 — Engineering Second-Eye Review:**
   - Pentru fiecare PR, inspectează diff-ul prin `gh pr diff --stat`.
   - Validează absența cheilor API expuse, a fișierelor temporare sau a ștergerilor de cod esențial.
3. **Pasul 3 — Squash-Merge & Pruning Ramuri Efemere:**
   - Execută squash-merge pe branch-ul implicit (`main`/`master`) cu ștergerea automată a ramurii remote.
   - Dacă există conflicte insolubile, închide PR-ul cu comentariul de audit.
4. **Pasul 4 — Curățare Web Inbox (Done):**
   - Apelează `PUT /notifications -f read=true`.
   - Iterează prin toate thread-urile active de notificare și trimite `DELETE /notifications/threads/:id`.
   - Verifică că `gh api /notifications` returnează `[]` și că interfața web `github.com/notifications` este la Inbox Zero.
