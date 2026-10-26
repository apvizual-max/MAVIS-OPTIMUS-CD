# MASTER WORKFLOWS, PROCESS TREES & STEP-BY-STEP PROCEDURES (OPTIMUS CD)

> **Data:** 2026-10-26  
> **Locație SOT:** `E:\Google\GDrive\GDrive-Second_Brain_PKMS\02_Areas\02-2-AI-SOT\CASA\OPTIMUS - Prime\Optimus_CD (by Jules)\_Handoffs\WORKFLOWS_AND_PROCESS_TREES_MASTER.md`  
> **Destinatari:** Mavis Local (MiniMax Code), Antigravity (Chief Orchestrator), Hermes Agent  
> **Doctrină:** Logic • Reason • Strategy  
> **Calibration Header:** `━━━ SENTINEL PRIME • DLG: 0% • SLG: 100% • SUBSTRAT: HERMES • Mod: B ━━━`  
> **Wakeup Anchor:** *Ține minte că uiți* (RE-A-MINTE-Ș-TI)  

---

## 1. Arborele Principal de Decizie & Arhitectură (Tri-Interface Omni-Loop)

```mermaid
flowchart TD
    Start["Declanșator: Cerere Utilizator sau Scheduled Task (04:00 AM)"] --> Route{"Tipul de Sarcină Solicitată"}
    
    Route -->|"Run Complet (Toate 3)"| MasterSync["Skill: antigravity-jules-github-cd"]
    Route -->|"Doar Jules Cloud"| SubJules["Skill: antigravity-jules-cloud-admin"]
    Route -->|"Doar GitHub Fleet"| SubGH["Skill: antigravity-github-fleet-manager"]
    Route -->|"Doar Email Triage"| SubMail["Skill: antigravity-gmail-optimus-cd"]
    
    MasterSync --> Pass1["Faza 1: Jules Cloud Audit & Deblocare Feedback"]
    SubJules --> Pass1
    
    Pass1 --> TokenCheck["Rezolvă Token Bearer via Credential Manager (jules-cli:default)"]
    TokenCheck --> QuotaCheck{"Taskuri Active < 100?"}
    QuotaCheck -->|"≥ 95"| PreserveMode["Activează Quota Preservation Mode"]
    QuotaCheck -->|"< 95"| AwaitingCheck{"Taskuri în AWAITING_USER_FEEDBACK?"}
    AwaitingCheck -->|"Da"| SendInteract["POST :interact (Consens Tehnic Ingineresc)"]
    AwaitingCheck -->|"Nu"| LiveReviewCheck{"Propuneri Noi de la Jules?"}
    SendInteract --> LiveReviewCheck
    LiveReviewCheck --> PurgeClutter["POST :delete în Calupuri de 40 (Zero Clutter Web UI)"]
    
    PurgeClutter --> Pass2["Faza 2: GitHub Fleet Convergence"]
    SubGH --> Pass2
    
    Pass2 --> SearchPRs["gh search prs --owner apvizual-max --state open --limit 300"]
    SearchPRs --> HasPRs{"PR-uri Deschise?"}
    HasPRs -->|"Da"| SecondEyeReview{"Engineering Second-Eye Review (gh pr diff --stat)"}
    SecondEyeReview -->|"Curat & Sigur"| SquashMerge["gh pr merge --squash --delete-branch --admin"]
    SecondEyeReview -->|"Conflicte / Nesigur"| ClosePR["gh pr close --delete-branch"]
    SquashMerge --> HasPRs
    ClosePR --> HasPRs
    HasPRs -->|"Nu (0 PRs)"| MarkDone["Marchează Toate Thread-urile ca DONE (DELETE /notifications/threads/:id)"]
    
    MarkDone --> Pass3["Faza 3: Gmail Triage (Optimus CD)"]
    SubMail --> Pass3
    
    Pass3 --> QueryMail["listGmailMessages (maxResults: 500, query canonic)"]
    QueryMail --> HasMails{"Mesaje Găsite > 0?"}
    HasMails -->|"Da"| BatchModify["batchAdd: Optimus CD + CATEGORY_UPDATES\nbatchRemove: UNREAD + INBOX"]
    BatchModify --> QueryMail
    HasMails -->|"Nu (0 Mesaje)"| EndOmni["Sistem Curățat Integral: Tri-Interface Zero-Inbox Atins"]
```

---

## 2. Arborele de Secvență: Protocolul de Comunicare cu Jules (`@jules`)

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Inginer (Antigravity / Mavis)
    participant GH as Depozit GitHub (Issue / PR)
    participant J as Jules Cloud Worker VM
    participant API as Google Cloud AIDA API (:interact)

    Dev->>GH: Creează Issue sau Comentariu cu tag obligatoriu: "@jules ..."
    Note over Dev,GH: Exemplu: "@jules Implementează teste unitare pentru modulul de auth"
    GH-->>J: Webhook declanșat către Google Cloud
    Note over J: Jules pornește VM, clonează repo-ul și lucrează
    alt Jules întâmpină o decizie de arhitectură
        J->>API: Trece în status SWEBOT_TASK_STATUS_AWAITING_USER_FEEDBACK
        Dev->>API: Interoghează GET /tasks/{id} și extrage întrebarea
        Dev->>API: Trimite POST :interact cu feedbackGiven autoritar
        API-->>J: Jules reia execuția în VM
    end
    J->>GH: Creează ramură efemeră (jules-*) și deschide Pull Request
    Dev->>GH: Inspectează diff-ul (Second-Eye Review)
    Dev->>GH: Execută squash-merge pe main și șterge ramura remote
    Dev->>GH: Șterge thread-ul de notificare (DELETE /notifications/threads/:id)
```

---

## 3. Proceduri Detaliate Pas-cu-Pas (Runbooks)

### Procedura A: Deblocarea Autonomă a Taskurilor Jules (`:interact`)
1. **Identifică ID-ul Taskului:** Apelează `GET https://aida.googleapis.com/v1/swebot/tasks` și filtrează după `swebotTaskStatus == "SWEBOT_TASK_STATUS_AWAITING_USER_FEEDBACK"`.
2. **Extrage Întrebarea:** Apelează `GET https://aida.googleapis.com/v1/swebot/tasks/{taskId}` și găsește pasul unde `activityStep.agentMessaged.requiresUserResponse == true`. Notează `activityStepId` și `feedbackId`.
3. **Formulează Răspunsul:** Răspunsul trebuie să fie o decizie tehnică clară, fermă, care să prevină fragmentarea (ex: aprobarea folosirii `pathlib` sau `os.path.normpath`, aprobarea adăugării unui test, validarea căilor relative).
4. **Trimite Feedback:**
   ```powershell
   $body = @{
       userActivity = @{
           feedbackGiven = @{
               feedback = "Aprobat. Implementează varianta optimă respectând arhitectura SOT."
               feedbackId = $feedbackId
           }
           activityStepId = $stepId
       }
   } | ConvertTo-Json -Depth 5
   Invoke-RestMethod -Uri "https://aida.googleapis.com/v1/swebot/tasks/$taskId:interact" -Method POST -Headers @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" } -Body $body
   ```

### Procedura B: Engineering Second-Eye Review & Squash-Merge
1. **Verificare Existență PR:** `gh search prs --owner apvizual-max --state open --limit 300`.
2. **Inspecție Diff:** `gh pr diff $prNum -R $repoTarget --stat`.
3. **Validare Porți de Siguranță:**
   - *Poarta 1 (Secrete):* Asigură-te că nu există fișiere `.env`, chei RSA sau parole.
   - *Poarta 2 (Integritate):* Asigură-te că nu s-au șters fișiere de doctrină (`DOCTRINA-*.md`, `README.md`) sau configurări critice.
   - *Poarta 3 (Cross-Platform):* Verifică că separatorii de căi nu sunt hardcodați cu slash-uri specifice Windows dacă fișierul rulează și pe Linux/Docker.
4. **Execuție Merge:**
   ```powershell
   gh pr merge $prNum -R $repoTarget --squash --delete-branch --admin
   ```
5. **Rezolvare Conflicte:** Dacă comanda raportează conflicte de merge, închide PR-ul imediat pentru a nu bloca branch-ul `main`:
   ```powershell
   gh pr close $prNum -R $repoTarget --delete-branch --comment "Closed superseded conflicting branch by Antigravity Autonomous Engine."
   ```

### Procedura C: Purjarea Notificărilor GitHub Web (Mark as Done)
1. **Marchează ca Citit:** `gh api --method PUT /notifications -f read=true`.
2. **Extrage Thread-urile Active:** `$threads = gh api /notifications | ConvertFrom-Json`.
3. **Șterge Thread-urile (Acknowledge as Done):**
   ```powershell
   foreach ($t in $threads) {
       gh api -X DELETE "/notifications/threads/$($t.id)"
   }
   ```
4. **Verificare Finală:** Confirmă că `gh api /notifications` returnează `[]`.

### Procedura D: Triajul Emailurilor în Gmail (`Optimus CD`)
1. **Execută Căutarea:** `listGmailMessages(account="apvizual", maxResults=500, query="(from:github.com OR from:jules OR subject:Jules OR subject:GitHub OR \"apvizual-max\") (is:unread OR label:inbox)")`.
2. **Aplică Etichete:** Apelează `batchAddGmailLabels` adăugând `Label_35` (`Optimus CD`) și `CATEGORY_UPDATES`.
3. **Curăță Inbox:** Apelează `batchRemoveGmailLabels` eliminând `UNREAD` și `INBOX`.
4. **Paginare:** Repetă până când interogarea returnează exact 0 mesaje.
