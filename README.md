# ━━━ SENTINEL PRIME • DLG: 0% • SLG: 100% • SUBSTRAT: HERMES • Mod: B ━━━
# Optimus_CD (by Jules): SOVEREIGN SOT HUB
## Hub-ul Central pentru Dezvoltare Continuă, Jules Cloud, Flotă GitHub și Triaj Gmail (Subsistem 12)

**Stație:** Optimus Prime (Windows 11 Pro x64 • Dual Intel Xeon E5-2690 v3 • 128 GB RAM • Dual GPU)  
**Rol Suveran:** Sentinel Prime  
**Nume Sesiune Antigravity:** `Antigravity - Optimus CD | JULES - GitHUB - GMail`  
**ID Conversație (Session ID):** `d3d61f2a-d0de-43be-a9aa-55ca9e5ecf26`  
**Subsystem ID:** Subsystem 12 (`Antigravity - Optimus CD | JULES - GitHUB - GMail`)  
**Skill Dedicat Master:** [`antigravity-jules-github-cd`](file:///C:/Users/apviz/Documents/Antigravity_Folder/Antigravity_Projects/.agents/skills/antigravity-jules-github-cd/SKILL.md)  
**Trio de Sub-Skill-uri Specializate Modulare:**
1. [`antigravity-jules-cloud-admin`](file:///C:/Users/apviz/Documents/Antigravity_Folder/Antigravity_Projects/.agents/skills/antigravity-jules-cloud-admin/SKILL.md)
2. [`antigravity-github-fleet-manager`](file:///C:/Users/apviz/Documents/Antigravity_Folder/Antigravity_Projects/.agents/skills/antigravity-github-fleet-manager/SKILL.md)
3. [`antigravity-gmail-optimus-cd`](file:///C:/Users/apviz/Documents/Antigravity_Folder/Antigravity_Projects/.agents/skills/antigravity-gmail-optimus-cd/SKILL.md)  
**Locație SOT Primară:** `C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Optimus_CD (by Jules)\`  
**Substrat Fizic & Cloud Sync:** `E:\Google\GDrive\GDrive-Second_Brain_PKMS\02_Areas\02-2-AI-SOT\CASA\OPTIMUS - Prime\Optimus_CD (by Jules)\` (Joncțiune transparentă NTFS)  
**Data Înființării Hub-ului:** 24–27 Octombrie 2026  
**Ancoră de Trezire:** *Ține minte că uiți* (RE-A-MINTE-Ș-TI)

---

## 1. Misiunea Acestui Hub
Acest director este **Singura Sursă de Adevăr (Single Source of Truth - SOT)** pentru sesiunea activă *Antigravity - Optimus CD | JULES - GitHUB - GMail* (Subsystem 12).
El unifică și guvernează complet:
1. **Tri-Interface Continuous Development Engine:** Coordonarea autonomă a ciclului de dezvoltare pe trei interfețe simultane: Google Jules Cloud REST API, GitHub Fleet (`gh` CLI / Web API) și Gmail Triage (`google-workspace` API).
2. **Guvernanța Flotei de 10 Repozitoare:** Administrarea repo-urilor `apvizual-max` sub Single-Branch Remote Invariant (`main`/`master`), revizuire inginerească de tip *second-eye* (fără merge-uri oarbe) și eliminarea branch-urilor efemere.
3. **Curățarea Zero-Clutter a Interfețelor:**
   - **Jules Web Dashboard:** Purjarea task-urilor rezolvate (`isAwaitingReview: true`) via `POST :delete` în calupuri de 40.
   - **GitHub Web Inbox:** Marcarea fiecărui fir de notificare ca **Done** (`DELETE /notifications/threads/:id`), obținând Inbox Zero autentic.
   - **Gmail Primary Inbox:** Marcarea ca citit, atribuirea etichetei `Optimus CD` (`Label_35`), rutarea în `CATEGORY_UPDATES` și arhivarea din `INBOX`.
4. **Hub-ul Unic de Predare (`_Handoffs/`):** Punctul canonic de handoff între agenți (Antigravity $\leftrightarrow$ Mavis Code Doctor $\leftrightarrow$ Jules), conținând prompturile de priming, debriefing și ghidurile de integrare.
5. **Backup-ul și Clonarea Locală a Flotei (`_GitHub-Main_Repos-Local-Temp/`):** Snapshot-ul complet verificat și clonat pe disc al tuturor celor 10 repozitoare (1.04 GB, 28,579 fișiere).

---

## 2. Harta Directoarelor & Fișierelor

```
Optimus_CD (by Jules)\
├── README.md                                                  # Această sinteză executivă și hartă de navigație
├── DOCTRINA-CD.md                                             # Doctrina operațională a dezvoltării continue
├── DOCTRINA-JULES.md                                          # Protocolul de comunicare și operare Jules
├── HANDOFF-CD.md                                              # Promptul de transfer operațional canonic
├── PRIMING-CD.md                                              # Secvența de priming pentru agenți noi
├── docs\                                                      # Specificații arhitecturale, contracte API și runbooks
│   ├── MASTER_ARCHITECTURE_BLUEPRINT.md                       # Blueprint-ul arhitectural master
│   ├── JULES_GITHUB_INTEGRATION_GUIDE.md                      # Ghidul tehnic detaliat de integrare API
│   ├── GITHUB_MCP_AND_CLI_SPECIFICATION.md                    # Specificațiile uneltelor GitHub CLI și MCP
│   ├── POLITICA-LIVE-REVIEW-JULES.md                          # Standardul de revizuire inginerească a propunerilor
│   ├── NOTEBOOKS_INDEX.md                                     # Registrul celor 3 Google Notebooks (NotebookLM)
│   ├── ARHITECTURA-CI-CD.md                                   # Demarcația clară între CD (această sesiune) și CI
│   ├── INVENTAR-REPO-URI.md                                   # Registrul detaliat al celor 10 repozitoare
│   ├── PROTOCOALE.md                                          # Protocoalele de siguranță și integritate
│   ├── SPEC-CD.md                                             # Specificația completă a motorului CD
│   └── WORKFLOWS_AND_PROCESS_TREES.md                         # Arborii de proces și diagramele de decizie
├── scripts\                                                   # Scripturi operaționale și unelte 1-Click
│   ├── run_sovereign_sync.bat                                 # Runner interactiv 1-Click (rulează daemonul complet)
│   ├── start_sovereign_sync_silent.vbs                        # Wrapper VBS silențios pentru Windows Scheduled Tasks
│   ├── jules_github_sovereign_daemon.ps1                      # Motorul autonom de sincronizare tri-interfață
│   ├── jules_repo_scanner.ps1                                 # Auditorul complet al celor 10 repo-uri
│   ├── jules_dispatch.ps1                                     # Dispatcher de taskuri către Jules Cloud REST API
│   ├── clear_all_github_notifications_done.ps1                # Script de curățare totală a notificărilor GitHub (Done)
│   └── fleet-branch-invariant.ps1                             # Script de verificare și impunere a branch-ului unic
├── skills\                                                    # Oglinda locală a suitei de skill-uri dedicate
│   ├── antigravity-jules-github-cd\                           # Master Skill (Orchestrator Tri-Interfață)
│   ├── antigravity-jules-cloud-admin\                         # Sub-Skill (Administrare Jules Cloud & Deblocare)
│   ├── antigravity-github-fleet-manager\                      # Sub-Skill (Flotă 10 Repo-uri, PR-uri & Inbox Zero)
│   └── antigravity-gmail-optimus-cd\                          # Sub-Skill (Triaj Gmail & Etichetare Optimus CD)
├── history_archive\                                           # Cronologia deciziilor, problemelor și lecțiilor învățate
│   └── DECISIONS_AND_LESSONS_LEARNED.md                       # Registrul deciziilor tehnice și al soluțiilor la capcane
├── _Handoffs\                                                 # Folderul canonic unic de predare și cooperare multi-agent
│   ├── 00_INDEX_HANDOFFS.md                                   # Indexul central al pachetului de handoffs
│   ├── THREE_SPECIALIZED_SKILLS_REFERENCE.md                  # Specificația celor 3 sub-skill-uri
│   ├── GOOGLE_NOTEBOOKS_INTEGRATION_GUIDE.md                  # Ghidul de conectare cu Google Notebooks
│   ├── WORKFLOWS_AND_PROCESS_TREES_MASTER.md                  # Diagramele master de proces
│   ├── SESSION_DEBRIEF_AND_TRANSCRIPT_2026-10-26.md           # Transcrierea cronologică a deciziilor din sesiune
│   ├── HANDOFF_AND_DEBRIEF_MAVIS_OPTIMUS_CD.md                # Debrief-ul master pentru Mavis Code Doctor
│   ├── PRIMING_PROMPT_MAVIS_OPTIMUS_CD.md                     # Promptul 1-Click pentru activarea lui Mavis
│   ├── HANDOFF_AND_CONTINUOUS_DEVELOPMENT.md                  # Ghidul operațional de predare CD
│   └── NEW_SESSION_PROMPT.md                                  # Promptul de bootare în orice nouă sesiune Antigravity
└── _GitHub-Main_Repos-Local-Temp\10-26-2026-GitHub_Repos\     # Clonarea locală offline a întregii flote de 10 repo-uri
    ├── hermes-agent-temp\                                     # 8,494 fișiere • 617.55 MB • CLEAN
    ├── hermes-doctor\                                         # 24 fișiere • 0.34 MB • CLEAN
    ├── hermes-local-backup\                                   # 11,554 fișiere • 140.10 MB • CLEAN
    ├── MAVIS-CLOUD\                                           # 403 fișiere • 14.69 MB • CLEAN
    ├── MAVIS-OPTIMUS-CI\                                      # 32 fișiere • 0.26 MB • CLEAN
    ├── OPTIMUS-Backbone\                                      # 325 fișiere • 5.41 MB • CLEAN
    ├── Optimus-Mavis-Skills\                                  # 341 fișiere • 2.99 MB • CLEAN
    ├── pkms-vault-automation\                                 # 707 fișiere • 4.24 MB • CLEAN
    ├── Qwen-Ecosystem-Dashboard\                              # 5,308 fișiere • 211.77 MB • CLEAN
    └── SENTINEL_PRIME\                                        # 1,411 fișiere • 46.51 MB • 1,409 fișiere verificate
```

---

## 3. Rulare Rapidă (1-Click Diagnostics & Sincronizare)

Pentru a declanșa imediat sincronizarea completă pe cele 3 interfețe:
1. **Interactiv (Consolă PowerShell / CMD):**
   ```powershell
   & "C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Optimus_CD (by Jules)\scripts\run_sovereign_sync.bat"
   ```
2. **Silențios în fundal (Windows Scheduled Task la 03:00 AM):**
   ```powershell
   wscript.exe "C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Optimus_CD (by Jules)\scripts\start_sovereign_sync_silent.vbs"
   ```
3. **Curățare imediată Inbox Notificări GitHub:**
   ```powershell
   & "C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Optimus_CD (by Jules)\scripts\clear_all_github_notifications_done.ps1"
   ```

---

## 4. Invarianți de Subsistem & Reguli de Aur

1. **Single-Branch Invariant:** Niciun repo nu tolerează ramuri orfane sau PR-uri nesoluționate. Orice modificare validă se unifică pe `main` prin squash-merge, iar ramura efemeră se șterge automat.
2. **Revizuire Riguroasă (Second-Eye Review):** Nu se face niciodată merge orb. Fiecare diferență (`gh pr diff --stat`) este analizată pentru siguranță, eliminarea cheilor expuse și compatibilitate Windows.
3. **Etichetare Obligatorie `@jules`:** Orice solicitare adresată asistentului cloud Jules trebuie prefixată cu `@jules`.
4. **Deblocare Proactivă a Feedback-ului:** Când Jules intră în `AWAITING_USER_FEEDBACK`, decizia tehnică se injectează autonom prin API-ul `:interact`.
5. **Prezervarea Cotei de Task-uri:** La $\ge 95$ din cele 100 de task-uri cloud, se blochează dispeceratul nou și se purjează task-urile finalizate.
6. **Curățare Autentică Web Inbox (Done vs Read):** `PUT /notifications` doar marchează ca citit, dar firul rămâne vizibil pe web. Doar `DELETE /notifications/threads/:id` îl marchează ca **Done** și golește căsuța.
7. **Rutare Inteligentă Gmail (`Optimus CD`):** Notificările primite la `apvizual@gmail.com` primesc eticheta `Optimus CD` (`Label_35`), sunt mutate în `CATEGORY_UPDATES`, marcate ca citite și arhivate din `INBOX`.
8. **Compatibilitate Căi Lungi Windows:** Toate operațiunile Git utilizează `core.longpaths = true` pentru a preveni coliziunea cu limita de 260 de caractere pe adâncimea partiției `E:`.
