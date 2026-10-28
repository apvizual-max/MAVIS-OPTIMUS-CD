---
name: antigravity-jules-github-cd
description: Sovereign Antigravity ↔ Google Jules ↔ GitHub Continuous Development (CD) orchestrator. Automates dual-interface synchronization (Jules cloud API + GitHub API), unblocks awaiting-feedback tasks, squash-merges PRs, enforces Single-Branch Invariant, clears notifications, purges Jules web UI review clutter, and manages scheduled autonomous background sync.
---

# Antigravity Jules GitHub Continuous Development (CD) Orchestrator

## Overview & Doctrine
This skill bridges **Google Jules** (cloud coding agent API) and **GitHub** (`gh` CLI / API) under the sovereign executive command of **Antigravity**.
It enforces the doctrine of: **Logic • Reason • Strategy**.

### Fundamental Invariants:
1. **Single-Branch Remote Invariant:** Only 1 active remote branch (`main` or `master`) is permitted. All feature branches (`jules-*`, `palette/*`, `sentinel/*`, `bolt/*`) are squash-merged and deleted immediately.
2. **Zero-Inbox & Zero-Review Clutter:** Neither GitHub nor Jules web UI may hold unreviewed or blocked items. Antigravity acts as the autonomous reviewer and decision-maker.
3. **Autonomous Feedback Dispatch:** When Jules enters `AWAITING_USER_FEEDBACK`, Antigravity inspects the prompt, formulates the engineering decision, and dispatches it via `:interact` API.
4. **Scheduled Background Resilience:** The scheduled task `Antigravity_Jules_GitHub_Continuous_Sync` executes daily, ensuring both interfaces remain completely clear.

---

## Tooling & Script Catalog
Located at: `C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\scripts\`

| Script | Purpose | Execution |
|---|---|---|
| `jules_github_sovereign_daemon.ps1` | Master 3-Pass Dual-Interface Autonomous Sync Engine | `powershell.exe -ExecutionPolicy Bypass -File "...\scripts\jules_github_sovereign_daemon.ps1"` |
| `start_sovereign_sync_silent.vbs` | Silent WScript wrapper for background scheduling | `wscript.exe "...\scripts\start_sovereign_sync_silent.vbs"` |
| `jules_repo_scanner.ps1` | Comprehensive 10-repo auditor (PRs, branches, ledgers) | `powershell.exe -ExecutionPolicy Bypass -File "...\scripts\jules_repo_scanner.ps1"` |
| `jules_dispatch.ps1` | Standardized task dispatcher to Jules CLI with personas | `powershell.exe -ExecutionPolicy Bypass -File "...\scripts\jules_dispatch.ps1" -Repo apvizual-max/<name> -Persona QA -Prompt "..."` |
