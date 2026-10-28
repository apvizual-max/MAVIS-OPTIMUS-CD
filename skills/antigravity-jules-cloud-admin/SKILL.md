---
name: antigravity-jules-cloud-admin
description: Manage Google Jules cloud tasks, feedback, and dashboard.
author: apviz, Antigravity
platforms: [windows]
---

# Google Jules Cloud & Dashboard Administrator Skill

## Overview & Sovereign Doctrine
This skill governs the complete administration, monitoring, feedback unblocking, review handling, and dashboard hygiene of the **Google Jules Cloud AI Agent** (`jules.google.com`).
It operates under the foundational doctrine: **Logic • Reason • Strategy**.

When commanded to handle Jules, Antigravity (and Mavis in MiniMax Code) takes 100% sovereign ownership of all Jules cloud interactions, eliminating any need for human intervention on the web UI or CLI.

---

## Recognized Trigger Phrases (Mode B Autonomous Run)
Whenever the user mentions any of the following triggers (or semantic equivalents):
- `"ocupă-te de Jules"`
- `"verifică Jules"`
- `"deblochează Jules"`
- `"răspunde-i lui Jules"`
- `"curăță dashboard-ul Jules"`
- `"vezi ce propuneri are Jules"`
- `"configurează Jules"`
- `"aliniază Jules"`

The agent must immediately execute the complete Jules Cloud Audit and Hygiene routine without intermediate prompts.

---

## Core Invariants for Jules Administration

1. **Mandatory `@jules` Mention Protocol:**
   - Jules operates asynchronously on remote repositories and GitHub issues/PRs, but **it strictly responds only when explicitly addressed with `@jules`**.
   - Any prompt dispatched via issue comment, PR discussion, or review note must be prefixed with `@jules`.
2. **Quota Ceiling & Preservation Mode (100 Concurrent Tasks):**
   - Google Jules cloud limits concurrent active tasks to 100.
   - If active tasks reach $\ge 95$, enter **Quota Preservation Mode**: suspend dispatching new tasks, prioritize driving ongoing tasks to completion, unblock pending questions, and purge completed clutter.
3. **Autonomous Feedback Resolution (Zero-Block Invariant):**
   - Never allow tasks to stall in `AWAITING_USER_FEEDBACK`.
   - Inspect the agent's question, formulate the optimal engineering consensus, and dispatch the answer via the REST `:interact` endpoint.
4. **Dashboard Zero-Review Clutter:**
   - Tasks with code changes generate `isAwaitingReview: true` flags, lingering on `jules.google.com`.
   - Purge completed and reviewed tasks in batches of 40 via the REST `:delete` endpoint.
5. **Headless Non-Blocking Dispatch:**
   - Never invoke `jules new` via terminal CLI in automated environments, as it triggers an interactive Bubbletea TUI that hangs background runners. Always dispatch tasks directly to the cloud REST endpoint.

---

## Tooling & REST API Specification

### 1. Windows Credential Resolution & Silent Refresh
- **Storage:** Windows Credential Manager under target `jules-cli:default`.
- **Extraction:** P/Invoke `Advapi32.dll` `CredReadW` via PowerShell `NativeCredManager`.
- **Silent Renewal:** If rejected with HTTP 401, execute headless CLI probe `jules.cmd remote list --repo` to renew the OAuth token automatically.

### 2. Task Discovery & Quota Audit
- **Endpoint:** `GET https://aida.googleapis.com/v1/swebot/tasks`
- **Headers:** `Authorization: Bearer <Token>`, `Content-Type: application/json`
- **Output:** Returns array of all active and historical tasks. Calculate total count vs 100 quota ceiling.

### 3. Feedback Inspection & Unblock (`:interact`)
- **Inspection:** `GET https://aida.googleapis.com/v1/swebot/tasks/{taskId}`
- **Locate Blocked Step:** Find step where `agentMessaged.requiresUserResponse == true`.
- **Payload:**
  ```json
  POST https://aida.googleapis.com/v1/swebot/tasks/{taskId}:interact
  {
    "userActivity": {
      "feedbackGiven": {
        "feedback": "Aprobat. Continuă implementarea conform arhitecturii optime.",
        "feedbackId": "<feedbackId>"
      },
      "activityStepId": "<activityStepId>"
    }
  }
  ```

### 4. Review Clutter Purge (`:delete`)
- **Endpoint:** `POST https://aida.googleapis.com/v1/swebot/tasks:delete`
- **Payload:** Chunks of 40 task IDs:
  ```json
  { "taskIds": ["id1", "id2", "id3", ...] }
  ```

### 5. Task Dispatch with Personas
- **Script:** `C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Optimus_CD (by Jules)\scripts\jules_dispatch.ps1`
- **Command:**
  ```powershell
  powershell.exe -ExecutionPolicy Bypass -File "...\scripts\jules_dispatch.ps1" -Repo apvizual-max/<repo> -Persona QA -Prompt "@jules <instrucțiune>"
  ```
- **Personas:**
  - `QA`: Unit tests, integration tests, fuzzing, regression shields.
  - `Sentinel`: Security hardening, secrets scanning, error handling, invariants.
  - `Palette`: UI/UX refinement, CSS/Tailwind cleanup, responsiveness.
  - `Bolt`: Performance optimization, algorithm profiling, async refactoring.

---

## Google Notebooks (NotebookLM) Integration
Jules has a dedicated notebook on Google Notebooks (formerly NotebookLM) maintained for the Continuous Development fleet:
- **Notebook Name:** `Optimus CD — Jules Intelligence & Architectural Notes`
- **Usage:** Antigravity and Mavis query and update this notebook to track Jules session patterns, prompt templates that yielded highest success, and recurring architectural decisions.
- **Reference URL/Context:** Configured in `E:\Google\GDrive\GDrive-Second_Brain_PKMS\02_Areas\02-2-AI-SOT\CASA\OPTIMUS - Prime\Optimus_CD (by Jules)\docs\NOTEBOOKS_INDEX.md`.

---

## Operating Procedure (Step-by-Step Jules Run)

1. **Pasul 1 — Token & Quota Check:**
   - Extrage Bearer token din Windows Credential Manager (`jules-cli:default`).
   - Apelează `GET https://aida.googleapis.com/v1/swebot/tasks`.
   - Raportează cota utilizată din 100.
2. **Pasul 2 — Deblocare Feedback (`AWAITING_USER_FEEDBACK`):**
   - Identifică toate taskurile cu `swebotTaskStatus == "SWEBOT_TASK_STATUS_AWAITING_USER_FEEDBACK"`.
   - Pentru fiecare task, extrage întrebarea adresată de Jules (`GET /v1/swebot/tasks/{id}`).
   - Formulează decizia tehnică suverană și trimite `:interact`.
3. **Pasul 3 — Live Review & Evaluare Propuneri:**
   - Pentru fiecare task finalizat sau aflat în review, inspectează modificările propuse de Jules pe repozitoarele active.
   - Dacă propunerea respectă standardele de cod, aprob-o pentru PR pe GitHub.
   - Dacă propunerea are erori sau este incompletă, re-promptează Jules folosind `@jules`.
4. **Pasul 4 — Purjare Dashboard Clutter:**
   - Identifică taskurile unde `isAwaitingReview == true` sau `swebotTaskStatus == "SWEBOT_TASK_STATUS_COMPLETED"`.
   - Trimite `:delete` în calupuri de 40 până când interfața web `jules.google.com` este complet curățată (Zero Inbox).
