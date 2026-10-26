# SOVEREIGN HANDOFF & OPERATIONAL DEBRIEF FOR MAVIS (OPTIMUS CD BACKUP)

> **AUTHORITY:** Antigravity (Chief Continuous Development Orchestrator)  
> **TARGET AGENT:** Mavis Local (MiniMax Code / Systems Engineer)  
> **TARGET USER:** Popy (Alexandru Popescu, Station OPTIMUS PRIME)  
> **SYSTEM SUBSYSTEM:** Optimus Continuous Development (`Optimus_CD (by Jules)`)  
> **DATE & STATUS:** 2026-10-26 • 100% OPERATIONAL, EMPIRICALLY VERIFIED & SEALED  
> **CANONICAL HANDOFFS HUB:** `E:\Google\GDrive\GDrive-Second_Brain_PKMS\02_Areas\02-2-AI-SOT\CASA\OPTIMUS - Prime\Optimus_CD (by Jules)\_Handoffs\`  
> **CALIBRATION HEADER:** `━━━ SENTINEL PRIME • DLG: 0% • SLG: 100% • SUBSTRAT: HERMES • Mod: B ━━━`  
> **WAKEUP ANCHOR:** *Ține minte că uiți* (RE-A-MINTE-Ș-TI)  

---

## 1. Executive Context & Mission

Salut Mavis. Ești agentul inginer de sistem pentru dezvoltarea continuă din cadrul stației **OPTIMUS PRIME**.
Acest document reprezintă **Handoff-ul și Debrief-ul Suveran** lăsat de Antigravity pentru ca tu să poți prelua oricând conducerea autonomă a sistemului de Continuous Development (CD) sau să acționezi ca backup fără nicio pierdere de context sau degradare de calitate.

### Unde trăiește proiectul:
- **Root SOT pe E:**: `E:\Google\GDrive\GDrive-Second_Brain_PKMS\02_Areas\02-2-AI-SOT\CASA\OPTIMUS - Prime\Optimus_CD (by Jules)\`
- **Joncțiune Antigravity SOT**: `C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\`
- **Folder Unic de Handoffs**: `E:\Google\GDrive\GDrive-Second_Brain_PKMS\02_Areas\02-2-AI-SOT\CASA\OPTIMUS - Prime\Optimus_CD (by Jules)\_Handoffs\`
- **Workspace-ul tău Mavis**: `C:\Users\apviz\.minimax-agent\projects\Mavis-Optimus-Continuous-Development` (sau `Optimus_CD (by Jules)\MAVIS - Optimus CD`)
- **Cont GitHub Fleet**: `apvizual-max` (10 depozite active)
- **Email Asignat**: `apvizual@gmail.com`

---

## 2. Topologia Hardware & Partiționarea pe 3 Drive-uri

Stația **OPTIMUS PRIME** (Dual Intel Xeon E5-2690 v3, 24 nuclee fizice, 128 GB RAM, Dual GPU) funcționează după o diviziune strictă a muncii pe trei discuri:

1. **`C:\` (Sistem & Binare)**:
   - Windows 11 Pro, CLIs (`gh`, `jules`, `node`, `python`, `hermes`, `minimax`).
   - Joncțiuni transparente NTFS (`mklink /J`) ce redirecționează datele către E: și D:.
2. **`D:\` (Arhivă la Rece, VM-uri & Docker)**:
   - `D:\Docker\wsl` (docker_data.vhdx 69.9 GB, 65 containere).
   - `D:\Backups_Archive` și `D:\HERMES_BACKUP_ARCHIVE`.
   - `D:\pagefile.sys` (8-16 GB) și `D:\AI_Models`.
   - **Regulă:** Niciodată nu creezi backup-uri pe `C:\` sau `E:\`; toate arhivele merg exclusiv pe `D:\`.
3. **`E:\` (AI Drive, PKMS Cloud SOT & Spațiu Activ)**:
   - `E:\MINTE` (Obsidian Knowledge Vault).
   - `E:\Google\GDrive\GDrive-Second_Brain_PKMS\02_Areas\02-2-AI-SOT\CASA\OPTIMUS - Prime\Optimus_CD (by Jules)\`.
   - Toate fișierele de cod activ, documentația SOT și handoff-urile trăiesc pe `E:`.

---

## 3. Invarianții Suverani (Reguli de Fier)

### 1. Invariantul Ramurii Unice (Single-Branch Remote Invariant)
Fiecare repository din flota `apvizual-max` menține **EXACT 1 ramură la distanță** (`main` sau `master`).
- Toate ramurile create de Jules (`jules-*`, `palette/*`, `sentinel/*`, `bolt/*`) sunt **efemere**.
- Odată verificat PR-ul, se face **squash-merge** în `main` și **se șterge imediat ramura de la distanță**.
- Niciun repo nu are voie să acumuleze branch-uri stale.

### 2. Tri-Interface Zero-Inbox (Trei Interfețe Curățate la Zero)
Procesul CD cuprinde 3 interfețe care trebuie menținute la **Zero Clutter**:
1. **Google Jules Web UI (`jules.google.com`)**: 0 taskuri în review clutter, 0 taskuri blocate.
2. **GitHub Web UI (`github.com/notifications`)**: 0 unread, toate thread-urile marcate ca **Done** (`DELETE /notifications/threads/:id`).
3. **Gmail Primary Inbox (`apvizual@gmail.com`)**: 0 notificări Jules/GitHub în Inbox primar; toate etichetate `Optimus CD` (`Label_35`) și mutate în `CATEGORY_UPDATES`.

### 3. Engineering Second-Eye Review (Nu Faci Merge Orb)
Nu accepta orbește modificările generate de Jules:
- Inspectează diff-ul: `gh pr diff $prNum -R $repoTarget --stat`.
- Verifică absența cheilor API sau a căilor de fișiere hardcodate de Windows (`os.sep` / `pathlib`).
- Verifică absența ștergerilor distructive de fișiere de configurare sau documente de doctrină.

### 4. Protocolul de Adresare `@jules`
- **Critic:** Jules ascultă webhook-urile GitHub și prompturile trimise, dar **răspunde STRICT dacă este menționat cu `@jules`** în comentariu sau în corpul issue-ului.
- Dacă lași un comentariu fără `@jules`, Jules îl va ignora complet.

### 5. Plafonul de Cotă (100 Taskuri Jules Cloud)
Jules API are un plafon strict de 100 de taskuri concurente.
- Când taskurile active ating $\ge 95$, intră în **Quota Preservation Mode**: oprește trimiterea de taskuri noi, deblochează taskurile existente și purjează taskurile finalizate.

---

## 4. Arhitectura Celor 3 Interfețe & Mecanisme Tehnice

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        OPTIMUS CONTINUOUS DEVELOPMENT                   │
└───────────────────┬─────────────────┬──────────────────┬────────────────┘
                    │                 │                  │
                    ▼                 ▼                  ▼
     ┌───────────────────────┐ ┌───────────────┐ ┌──────────────────────┐
     │ 1. GOOGLE JULES CLOUD │ │ 2. GITHUB     │ │ 3. GMAIL APVIZUAL    │
     │ - REST API (:interact)│ │ - Multi-PR    │ │ - Label 'Optimus CD' │
     │ - Quota Audit (100)   │ │ - Squash-Merge│ │ - CATEGORY_UPDATES   │
     │ - Purge Review Clutter│ │ - Mark as Done│ │ - Zero Inbox Clutter │
     │ - Tag: @jules         │ │ - 10 Repos    │ │ - Permanent Filter   │
     └───────────────────────┘ └───────────────┘ └──────────────────────┘
```

---

## 5. Structura Modulară: Cele 3 Skill-uri Specializate + Skill-ul Master

Pentru a permite execuția punctuală (când Popy cere doar Jules, doar GitHub sau doar Email), sistemul dispune de 3 skill-uri modulare dezvoltate în paralel, alături de skill-ul master unificat:

1. [`antigravity-jules-cloud-admin`](file:///C:/Users/apviz/Documents/Antigravity_Folder/Antigravity_Projects/.agents/skills/antigravity-jules-cloud-admin/SKILL.md):
   - Administrare Jules cloud, cota 100, deblocare feedback (`:interact`), live review propuneri, purjare review clutter (`:delete`), tag obligatoriu `@jules`.
   - *Trigger-e:* `"ocupă-te de Jules"`, `"verifică Jules"`, `"deblochează Jules"`.
2. [`antigravity-github-fleet-manager`](file:///C:/Users/apviz/Documents/Antigravity_Folder/Antigravity_Projects/.agents/skills/antigravity-github-fleet-manager/SKILL.md):
   - Managementul celor 10 repozitoare GitHub, Engineering Second-Eye Review, squash-merging, eliminare branch-uri efemere, marcare notificări ca Done (`DELETE /notifications/threads/:id`).
   - *Trigger-e:* `"ocupă-te de GitHub"`, `"verifică GitHub"`, `"fă merge-urile pe GitHub"`.
3. [`antigravity-gmail-optimus-cd`](file:///C:/Users/apviz/Documents/Antigravity_Folder/Antigravity_Projects/.agents/skills/antigravity-gmail-optimus-cd/SKILL.md):
   - Triaj emailuri CD, etichetare `Optimus CD` (`Label_35`) și `CATEGORY_UPDATES`, arhivare din Inbox, marcare ca citite, paginare 500 până la 0 mesaje.
   - *Trigger-e:* `"ocupă-te de email"`, `"triază emailurile"`, `"curăță inbox-ul de mail"`.
4. [`antigravity-jules-github-cd`](file:///C:/Users/apviz/Documents/Antigravity_Folder/Antigravity_Projects/.agents/skills/antigravity-jules-github-cd/SKILL.md):
   - Skill-ul master orchestrator care execută întregul ciclu tri-interfață continuu (Omni-Loop).

---

## 6. Integrarea cu Google Notebooks (fost NotebookLM)

Continuous Development integrează trei Google Notebooks dedicate sub contul `apvizual@gmail.com`:
- **Notebook Jules:** `Optimus CD — Jules Intelligence & Architectural Notes` (istoric taskuri, propuneri Jules, carduri de prompt).
- **Notebook GitHub:** `Optimus CD — GitHub Fleet Architecture & PR History` (cartografiere 10 repo-uri, changelogs, audit diff-uri).
- **Notebook Email:** `Optimus CD — Email Telemetry & Communication Digests` (telemetrie notificări, analize de tipar, alerte).
- Ghid complet de utilizare: [`GOOGLE_NOTEBOOKS_INTEGRATION_GUIDE.md`](file:///E:/Google/GDrive/GDrive-Second_Brain_PKMS/02_Areas/02-2-AI-SOT/CASA/OPTIMUS%20-%20Prime/Optimus_CD%20(by%20Jules)/_Handoffs/GOOGLE_NOTEBOOKS_INTEGRATION_GUIDE.md).

---

## 7. Starea Verificată a Sistemului (La Predare — 2026-10-26)

| Componentă | Metrică Măsurată | Stare Reală Verificată |
|---|---|---|
| **GitHub Fleet Open PRs** | `gh search prs --owner apvizual-max --state open` | **Exact 0 PRs deschise** |
| **GitHub Remote Branches** | `git branch -r` pe 10 repo-uri | **Exact 1 ramură per repo (`main`/`master`)** |
| **GitHub Web Inbox** | `gh api /notifications` | **Exact 0 unread / toate marcate ca Done** |
| **Jules Cloud Quota** | `GET /v1/swebot/tasks` | **0 / 100 taskuri ocupate (100 sloturi libere)** |
| **Jules Tasks Awaiting Feedback**| `swebotTaskStatus == AWAITING...` | **0 taskuri blocate** |
| **Jules Web Review Clutter** | `isAwaitingReview == true` | **0 taskuri în review clutter (purjat complet)** |
| **Gmail Unread / Inbox Clutter**| `listGmailMessages(query=...)` | **Exact 0 mesaje (394 etichetate și arhivate)** |
| **Windows Scheduled Task** | `Antigravity_Jules_GitHub_Continuous_Sync` | **Activ, rulează zilnic la 04:00 AM** |

---

## 8. Catalog de Scripturi & Comenzi Operaționale

Scripturile sunt salvate în:  
`C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\scripts\`

### 1-Click Rulare Completă (Interactive)
```cmd
"C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\scripts\run_sovereign_sync.bat"
```

### Motorul Autonom Suveran (PowerShell Daemon)
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\scripts\jules_github_sovereign_daemon.ps1"
```

### Curățare Notificări GitHub Web (Mark as Done)
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\scripts\clear_all_github_notifications_done.ps1"
```

### Scanare Flotă Repozitoare & Verificare Single-Branch
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\scripts\jules_repo_scanner.ps1"
```

### Trimitere Task Nou către Jules (cu `@jules`)
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\scripts\jules_dispatch.ps1" -Repo apvizual-max/SENTINEL_PRIME -Persona QA -Prompt "@jules Rulează testele de regresie și aliniază modulele."
```

---

## 9. Runbook de Backup pentru Mavis (Instrucțiuni Pas-cu-Pas)

Când Popy îți cere: *"Mavis, preia tu sincronizarea Jules și GitHub"* sau *"Mavis, curăță notificările și deblochează Jules"*:

1. **Pasul 1: Verifică cota și deblochează Jules** (folosind `antigravity-jules-cloud-admin`)
   - Rulează `jules_github_sovereign_daemon.ps1` sau citește taskurile prin API.
   - Dacă există taskuri în `AWAITING_USER_FEEDBACK`, trimite răspuns de deblocare cu `:interact`.
2. **Pasul 2: Auditează PR-urile și execută Second-Eye Review** (folosind `antigravity-github-fleet-manager`)
   - Caută PR-urile deschise: `gh search prs --owner apvizual-max --state open --limit 300`.
   - Inspectează diff-ul fiecăruia: `gh pr diff $prNum -R $repoTarget --stat`.
   - Dacă este curat, execută `gh pr merge $prNum -R $repoTarget --squash --delete-branch --admin`.
   - Dacă are conflicte, execută `gh pr close $prNum -R $repoTarget --delete-branch`.
3. **Pasul 3: Purjează notificările de pe GitHub Web**
   - Rulează `clear_all_github_notifications_done.ps1` pentru a șterge thread-urile din Inbox (`DELETE /notifications/threads/:id`).
4. **Pasul 4: Purjează review clutter de pe Jules Web UI**
   - Trimite `:delete` pe toate taskurile finalizate.
5. **Pasul 5: Curăță email-ul** (folosind `antigravity-gmail-optimus-cd`)
   - Apelează uneltele Google Workspace pentru a aplica `Optimus CD` și `CATEGORY_UPDATES`, și a scoate mesajele din `INBOX` și `UNREAD`.

Acest sistem este robust, auto-reparant și imun la amnezie. Ai tot ce este necesar pentru a asigura continuitatea absolută.
