---
name: antigravity-gmail-optimus-cd
description: Triage and archive Optimus CD notifications in Gmail.
author: apviz, Antigravity
platforms: [windows]
---

# Gmail Continuous Development Triage Skill (`Optimus CD`)

## Overview & Sovereign Doctrine
This skill governs the automated scanning, categorization, marking as read, and archiving of all incoming notifications related to Continuous Development (Jules Cloud actions, GitHub pull requests, commits, and fleet events) in `apvizual@gmail.com`.
It enforces the doctrine: **Logic • Reason • Strategy**.

Every action taken by Jules or on GitHub triggers an email. Without automated intervention, the user's primary inbox suffers catastrophic notification fatigue.
When commanded to handle email, Antigravity (and Mavis in MiniMax Code) ensures that all CD notifications are verified as implemented, labeled **`Optimus CD`** (`Label_35`), categorized into **`CATEGORY_UPDATES`**, marked as read (`UNREAD` removed), and removed from **`INBOX`** and **`SPAM`**.

---

## Recognized Trigger Phrases (Mode B Autonomous Run)
Whenever the user mentions any of the following triggers (or semantic equivalents):
- `"ocupă-te de email"`
- `"triază emailurile"`
- `"curăță inbox-ul de mail"`
- `"verifică notificările pe email"`
- `"marchează mailurile Optimus CD"`
- `"aliniază email"`

The agent must immediately execute the complete Gmail Triage routine without intermediate prompts.

---

## Core Invariants for Email Management

1. **Dedicated Label Assignment (`Optimus CD`):**
   - Every matching email must receive the user's sovereign CD label: **`Optimus CD`** (internal ID: `Label_35`).
2. **Category Isolation (`CATEGORY_UPDATES`):**
   - All notifications are routed away from the Primary tab into the Updates tab (`CATEGORY_UPDATES`), keeping personal and business communications pristine.
3. **Primary Inbox Zero Invariant:**
   - No CD notifications may linger in the primary `INBOX` or in `SPAM`. The label `INBOX` must be revoked from all matching threads.
4. **Mark as Read Verification:**
   - Matching emails are verified as implemented, and the `UNREAD` label is stripped.
5. **Exhaustive Sweep with Pagination (`maxResults: 500`):**
   - Standard queries return partial pages. The agent must loop with `maxResults: 500` until `listGmailMessages` returns exactly **0 messages**.
6. **Permanent Filter Shield:**
   - Active Gmail filter `ANe1Bmh4apfrWZA0T6Dx1Ha8qm8sLNXnDWtPevfLsJ8QCQ` is permanently registered to intercept all future inbound messages.

---

## Google Notebooks (NotebookLM) Integration
The email notification triage system has a dedicated notebook on Google Notebooks (formerly NotebookLM) maintained for continuous development:
- **Notebook Name:** `Optimus CD — Email Telemetry & Communication Digests`
- **Usage:** Antigravity and Mavis query and update this notebook to analyze email frequency patterns, commit notification digests, error report spikes, and communication alerts.
- **Reference URL/Context:** Configured in `E:\Google\GDrive\GDrive-Second_Brain_PKMS\02_Areas\02-2-AI-SOT\CASA\OPTIMUS - Prime\Optimus_CD (by Jules)\docs\NOTEBOOKS_INDEX.md`.

---

## Tooling & API Specification (`google-workspace` MCP)

### 1. Account Identity
- **Account Parameter:** `account: "apvizual"` (required in all MCP tool calls).

### 2. Search & Discovery Query
- **Tool:** `call_mcp_tool(ServerName="google-workspace", ToolName="listGmailMessages", Arguments={ account: "apvizual", maxResults: 500, query: "(from:github.com OR from:jules OR subject:Jules OR subject:GitHub OR \"apvizual-max\") (is:unread OR label:inbox)" })`
- **Logic:** Matches any email originating from GitHub or Jules, or referencing Jules, GitHub, or `apvizual-max`, that is either unread or currently in the inbox.

### 3. Batch Labeling
- **Tool:** `call_mcp_tool(ServerName="google-workspace", ToolName="batchAddGmailLabels", Arguments={ account: "apvizual", ids: [...ids], labelIds: ["Label_35", "CATEGORY_UPDATES"] })`
- **Capacity:** Supports up to 1,000 message IDs per single call.

### 4. Batch Archiving & Unreading
- **Tool:** `call_mcp_tool(ServerName="google-workspace", ToolName="batchRemoveGmailLabels", Arguments={ account: "apvizual", ids: [...ids], labelIds: ["UNREAD", "INBOX"] })`
- **Capacity:** Supports up to 1,000 message IDs per single call.

### 5. Permanent Filter Definition
- **Filter ID:** `ANe1Bmh4apfrWZA0T6Dx1Ha8qm8sLNXnDWtPevfLsJ8QCQ`
- **Query Criteria:** `from:(notifications@github.com OR *jules*) OR subject:(Jules OR GitHub OR "apvizual-max")`
- **Actions:** Add `Label_35`, Add `CATEGORY_UPDATES`, Remove `INBOX`, Exclude from `SPAM`.

---

## Operating Procedure (Step-by-Step Gmail Run)

1. **Pasul 1 — Interogare Mesaje Active:**
   - Apelează `listGmailMessages` cu query-ul canonic și `maxResults: 500`.
   - Verifică dacă există mesaje care necesită triaj.
2. **Pasul 2 — Verificare Implementare:**
   - Verifică rapid sumarul mesajelor pentru a confirma că PR-urile și taskurile Jules la care fac referire au fost deja procesate de engine.
3. **Pasul 3 — Etichetare & Arhivare în Masă:**
   - Adaugă etichetele `Label_35` (`Optimus CD`) și `CATEGORY_UPDATES` pe toate ID-urile returnate via `batchAddGmailLabels`.
   - Elimină etichetele `UNREAD` și `INBOX` via `batchRemoveGmailLabels`.
4. **Pasul 4 — Buclă Paginare:**
   - Re-apelează `listGmailMessages`. Dacă mai există mesaje, repetă pașii 2 și 3 până când interogarea returnează exact **0 mesaje**.
5. **Pasul 5 — Confirmare Filtru Permanent:**
   - Verifică existența filtrului `ANe1Bmh4apfrWZA0T6Dx1Ha8qm8sLNXnDWtPevfLsJ8QCQ` pentru a garanta menținerea stării de Inbox Zero în fundal.
