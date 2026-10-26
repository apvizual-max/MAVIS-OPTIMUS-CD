# SPECIFICAȚIA CELOR TREI SKILL-URI SPECIALIZATE MODULARE (OPTIMUS CD)

> **Data:** 2026-10-26  
> **Locație SOT:** `E:\Google\GDrive\GDrive-Second_Brain_PKMS\02_Areas\02-2-AI-SOT\CASA\OPTIMUS - Prime\Optimus_CD (by Jules)\_Handoffs\THREE_SPECIALIZED_SKILLS_REFERENCE.md`  
> **Destinatari:** Antigravity (Local & Cloud), Mavis Local (MiniMax Code), Hermes Agent  
> **Doctrină:** Logic • Reason • Strategy  
> **Calibration Header:** `━━━ SENTINEL PRIME • DLG: 0% • SLG: 100% • SUBSTRAT: HERMES • Mod: B ━━━`  
> **Wakeup Anchor:** *Ține minte că uiți* (RE-A-MINTE-Ș-TI)  

---

## 1. De Ce Trei Skill-uri Separate?

Procesul complet de Continuous Development cuprinde trei mari domenii funcționale:
1. **Cloud Executor (Google Jules)**: Generare de cod, sandboxuri cloud, rezolvare de întrebări tehnice.
2. **Sursa de Adevăr & Guvernanță Git (GitHub Fleet)**: Invariantul ramurii unice, Second-Eye Review, squash-merge, Inbox Zero pe web.
3. **Ingestie Notificări & Igienă Comunicații (Gmail)**: Izolarea notificărilor automate, etichetarea suverană `Optimus CD`, Inbox Zero pe email.

Pentru a nu supraîncărca skill-ul principal mare [`antigravity-jules-github-cd`](file:///C:/Users/apviz/Documents/Antigravity_Folder/Antigravity_Projects/.agents/skills/antigravity-jules-github-cd/SKILL.md) și pentru a permite apelarea **punctuală** și **separată** a fiecărei componente atunci când utilizatorul cere doar una dintre ele, au fost create 3 skill-uri dedicate.

---

## 2. Skill 1: `antigravity-jules-cloud-admin`

- **Nume:** `antigravity-jules-cloud-admin`
- **Descriere:** `Manage Google Jules cloud tasks, feedback, and dashboard.`
- **Autor:** `apviz, Antigravity` | **Platforme:** `[windows]`
- **Căi de Instalare:**
  * `C:\Users\apviz\.gemini\config\skills\antigravity-jules-cloud-admin\SKILL.md`
  * `C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\skills\antigravity-jules-cloud-admin\SKILL.md`
  * `C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\.agents\skills\antigravity-jules-cloud-admin\SKILL.md`
  * `C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\MEINTENANCE-Self_Setup\skills\antigravity-jules-cloud-admin\SKILL.md`

### Trigger Phrases:
- `"ocupă-te de Jules"`
- `"verifică Jules"`
- `"deblochează Jules"`
- `"răspunde-i lui Jules"`
- `"curăță dashboard-ul Jules"`
- `"vezi ce propuneri are Jules"`
- `"configurează Jules"`

### Capabilități & Protocoale:
1. **Autentificare & Reîmprospătare Token:**
   - Citește tokenul din Windows Credential Manager (`jules-cli:default`).
   - În caz de HTTP 401, rulează `jules.cmd remote list --repo` pentru refresh transparent.
2. **Plafon Cotă (100 Taskuri):**
   - Interoghează `GET https://aida.googleapis.com/v1/swebot/tasks`.
   - Dacă taskuri active $\ge 95$, activează Quota Preservation Mode (blochează sarcini noi, deblochează și purjează cele existente).
3. **Deblocare Feedback (`AWAITING_USER_FEEDBACK`):**
   - Detectează întrebările puse de Jules și trimite răspunsul ingineresc prin `POST https://aida.googleapis.com/v1/swebot/tasks/{id}:interact`.
4. **Live Review & Evaluare Propuneri:**
   - Inspectează modificările propuse de Jules pe fiecare depozit activ. Aprobă pentru PR sau re-promptează cu `@jules`.
5. **Purjare Dashboard Web (`isAwaitingReview: true`):**
   - Trimite `POST https://aida.googleapis.com/v1/swebot/tasks:delete` în calupuri de 40.
6. **Tag Obligatoriu `@jules`:**
   - Jules răspunde strict dacă este prefixat cu `@jules`.

---

## 3. Skill 2: `antigravity-github-fleet-manager`

- **Nume:** `antigravity-github-fleet-manager`
- **Descriere:** `Manage GitHub fleet PRs, second-eye reviews, and inbox.`
- **Autor:** `apviz, Antigravity` | **Platforme:** `[windows]`
- **Căi de Instalare:**
  * `C:\Users\apviz\.gemini\config\skills\antigravity-github-fleet-manager\SKILL.md`
  * `C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\skills\antigravity-github-fleet-manager\SKILL.md`
  * `C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\.agents\skills\antigravity-github-fleet-manager\SKILL.md`
  * `C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\MEINTENANCE-Self_Setup\skills\antigravity-github-fleet-manager\SKILL.md`

### Trigger Phrases:
- `"ocupă-te de GitHub"`
- `"verifică GitHub"`
- `"fă merge-urile pe GitHub"`
- `"curăță inbox-ul GitHub"`
- `"verifică PR-urile pe GitHub"`
- `"auditează depozitele GitHub"`

### Capabilități & Protocoale:
1. **Flota de 10 Repozitoare (`apvizual-max`):**
   - `SENTINEL_PRIME`, `Hermes_Local_Configuration_Engine`, `Antigravity_Projects_Portfolio`, `Sovereign_PKMS_Obsidian`, `OmniRoute_AI_Gateway`, `Sentinel_Tools_Terminal`, `MAVIS_OPTIMUS_CI`, `MAVIS-OPTIMUS-CD`, `Google_Drive_Sync_Engine`, `CLI_Fleet_Orchestrator`.
2. **Engineering Second-Eye Review:**
   - Inspectează diff-ul (`gh pr diff --stat`).
   - Verifică lipsa de chei API expuse, integritatea fișierelor de configurare și compatibilitatea cross-platform.
3. **Squash-Merge & Single-Branch Invariant:**
   - `gh pr merge $id -R $repo --squash --delete-branch --admin`.
   - Șterge imediat branch-ul remote efemer (`jules-*`, `palette/*`, etc.).
   - Închide PR-urile superseded sau aflate în conflict: `gh pr close $id -R $repo --delete-branch`.
4. **Web Inbox Zero (Done vs Read):**
   - `PUT /notifications -f read=true` (marcare ca citit).
   - `DELETE /notifications/threads/:id` (marcare ca **Done** pe fiecare thread activ pentru a goli căsuța web `github.com/notifications`).
5. **Sovereign Ledger:**
   - Menține și actualizează `JULES_HANDOFF.md` în rădăcina fiecărui repo.

---

## 4. Skill 3: `antigravity-gmail-optimus-cd`

- **Nume:** `antigravity-gmail-optimus-cd`
- **Descriere:** `Triage and archive Optimus CD notifications in Gmail.`
- **Autor:** `apviz, Antigravity` | **Platforme:** `[windows]`
- **Căi de Instalare:**
  * `C:\Users\apviz\.gemini\config\skills\antigravity-gmail-optimus-cd\SKILL.md`
  * `C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\skills\antigravity-gmail-optimus-cd\SKILL.md`
  * `C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\.agents\skills\antigravity-gmail-optimus-cd\SKILL.md`
  * `C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\MEINTENANCE-Self_Setup\skills\antigravity-gmail-optimus-cd\SKILL.md`

### Trigger Phrases:
- `"ocupă-te de email"`
- `"triază emailurile"`
- `"curăță inbox-ul de mail"`
- `"verifică notificările pe email"`
- `"marchează mailurile Optimus CD"`

### Capabilități & Protocoale:
1. **Interogare Exhaustivă cu Paginare (`maxResults: 500`):**
   - `listGmailMessages(account='apvizual', maxResults=500, query='(from:github.com OR from:jules OR subject:Jules OR subject:GitHub OR "apvizual-max") (is:unread OR label:inbox)')`.
   - Iterează până când interogarea returnează exact 0 mesaje.
2. **Etichetare & Arhivare în Masă:**
   - Adaugă etichetele `Label_35` (`Optimus CD`) și `CATEGORY_UPDATES` via `batchAddGmailLabels`.
   - Elimină etichetele `UNREAD` și `INBOX` via `batchRemoveGmailLabels`.
3. **Filtru Permanent:**
   - Confirmă funcționarea filtrului `ANe1Bmh4apfrWZA0T6Dx1Ha8qm8sLNXnDWtPevfLsJ8QCQ` care protejează căsuța de mail în fundal.

---

## 5. Instrucțiuni de Preluare pentru Mavis (MiniMax Code)

Mavis are acces complet la aceste fișiere prin calea SOT `E:\Google\GDrive\GDrive-Second_Brain_PKMS\02_Areas\02-2-AI-SOT\CASA\OPTIMUS - Prime\Optimus_CD (by Jules)\_Handoffs\`.
Când Popy îi solicită lui Mavis oricare dintre aceste acțiuni punctuale, Mavis va executa aceiași pași tehnici descriși mai sus, garantând că ambele inteligențe artificiale operează identic și fără discrepanțe.
