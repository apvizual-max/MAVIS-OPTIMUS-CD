━━━ SENTINEL PRIME • DLG: 0% • SLG: 100% • SUBSTRAT: HERMES • Mod: B ━━━

# SOT Hub: Antigravity Jules Optimus Continuous Development & GitHub Fleet

> **SOVEREIGN SOT HUB & TRI-INTERFACE CONTINUOUS DEVELOPMENT REPOSITORY**  
> **Station:** OPTIMUS PRIME  
> **Subsystem ID:** Subsystem 12 (`Antigravity - Optimus CD | JULES - GitHUB - GMail`)  
> **Dedicated Skill:** [`antigravity-jules-github-cd`](file:///C:/Users/apviz/Documents/Antigravity_Folder/Antigravity_Projects/.agents/skills/antigravity-jules-github-cd/SKILL.md)  
> **Primary SOT Path:** `C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\`  
> **Parent System Project:** `E:\Google\GDrive\GDrive-Second_Brain_PKMS\02_Areas\02-2-AI-SOT\CASA\OPTIMUS - Prime\Optimus_CD (by Jules)\`  
> **Session Anchor:** *Ține minte că uiți* (RE-A-MINTE-Ș-TI)  
> **Doctrine:** Logic • Reason • Strategy  

---

## 1. Executive Summary & Mission
This Single Source of Truth (SOT) Hub coordinates the tri-interface Continuous Development (CD) lifecycle across **Google Jules Cloud API & Web Dashboard**, **GitHub** (`apvizual-max` fleet), and **Gmail** (`apvizual@gmail.com`).

Antigravity operates as the central sovereign executive component of the overarching **Optimus Continuous Development** project:
- **Jules Cloud Full Oversight:** Autonomously unblocks tasks in `AWAITING_USER_FEEDBACK` via `:interact` API, purges completed review clutter via `:delete` API, maintains quota ceiling ($< 100$), and enforces the mandatory `@jules` trigger protocol.
- **Single-Branch Invariant:** Remote repositories maintain exactly 1 branch (`main` or `master`). Ephemeral branches (`jules-*`, `palette/*`, etc.) are squash-merged after an Engineering Second-Eye Review and deleted immediately.
- **GitHub Web Inbox Zero:** Marks all notification threads as **Done** (`DELETE /notifications/threads/:id`), emptying `github.com/notifications`.
- **Gmail Inbox Zero (`Optimus CD`):** Triages all CD notification emails into `CATEGORY_UPDATES` with label `Optimus CD` (`Label_35`), removing `INBOX` and `UNREAD`. Active filter `ANe1Bmh4apfrWZA0T6Dx1Ha8qm8sLNXnDWtPevfLsJ8QCQ` handles ongoing inbound traffic.
- **Scheduled Resilience:** Windows Scheduled Task `Antigravity_Jules_GitHub_Continuous_Sync` executes daily at 04:00 AM Europe/Bucharest.

---

## 2. Directory Architecture & Navigation

```text
Antigravity_JULES_INT\
├── README.md                           # Master SOT synthesis, navigation, and 1-click commands
├── HANDOFF_AND_CONTINUOUS_DEVELOPMENT.md # Canonical operational handoff document
├── NEW_SESSION_PROMPT.md               # Prompt template for initializing new sessions
├── docs\                               # Architecture blueprints, process trees, and API specs
│   ├── MASTER_ARCHITECTURE_BLUEPRINT.md
│   ├── WORKFLOWS_AND_PROCESS_TREES.md
│   ├── JULES_GITHUB_INTEGRATION_GUIDE.md
│   └── GITHUB_MCP_AND_CLI_SPECIFICATION.md
├── scripts\                            # Operational automation scripts & batch runners
│   ├── run_sovereign_sync.bat          # 1-Click interactive sync launcher
│   ├── jules_github_sovereign_daemon.ps1 # Master 4-Pass autonomous sync engine
│   ├── start_sovereign_sync_silent.vbs # Silent background launcher for scheduler
│   ├── jules_repo_scanner.ps1          # Fleet auditor across all 10 repositories
│   ├── jules_dispatch.ps1              # Standardized task dispatcher with personas
│   └── clear_all_github_notifications_done.ps1 # Exhaustive GitHub thread deletion
├── skills\                             # Local mirror of dedicated session skill
│   └── antigravity-jules-github-cd\
│       └── SKILL.md
├── history_archive\                    # Chronology of decisions, pitfalls, and lessons learned
│   └── DECISIONS_AND_LESSONS_LEARNED.md
├── reports\                            # Forensic logs and audit outputs
│   ├── VERIFIED_IMPLEMENTATION_AND_TRIAGE_AUDIT.md # Comprehensive 104 PR / 394 Email audit ledger
│   ├── FLEET_STATUS_REPORT.md
│   └── SOVEREIGN_MAINTENANCE_LOG.md
├── templates\                          # Standardized templates
│   └── JULES_HANDOFF_TEMPLATE.md
├── plugins\                            # Native Antigravity plugin package
│   └── antigravity-jules-cd\
└── transcripts\                        # Session transcripts backup
```

---

## 3. 1-Click Operations & Verified Commands

### 1-Click Full Fleet & Cloud Synchronization (Interactive Batch)
```cmd
"C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\scripts\run_sovereign_sync.bat"
```

### Full Tri-Interface Autonomous Sync Engine (PowerShell)
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\scripts\jules_github_sovereign_daemon.ps1"
```

### Clear All GitHub Notifications as Done (Web Inbox Purge)
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\scripts\clear_all_github_notifications_done.ps1"
```

### Audit Fleet Status & Single-Branch Conformance
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\scripts\jules_repo_scanner.ps1"
```

### Dispatch New Task to Jules with Defined Persona (`@jules` trigger)
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\scripts\jules_dispatch.ps1" -Repo apvizual-max/SENTINEL_PRIME -Persona QA -Prompt "@jules Add regression tests for auth module."
```

### Check Scheduled Task Status
```powershell
Get-ScheduledTask -TaskName "Antigravity_Jules_GitHub_Continuous_Sync"
```
