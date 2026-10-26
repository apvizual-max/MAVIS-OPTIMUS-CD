# Workflows & Process Trees: Jules ↔ GitHub ↔ Gmail Continuous Development

**Document Version:** 2.0  
**Location:** `C:\Users\apviz\Documents\Antigravity_Folder\Antigravity_Projects\Antigravity_JULES_INT\docs\WORKFLOWS_AND_PROCESS_TREES.md`  

---

## 1. Tri-Interface Continuous Development Lifecycle

```mermaid
flowchart TD
    Start["User Trigger or Scheduled Timer"] --> Pass1["Pass 1: Jules Cloud Audit"]
    
    subgraph P1["Pass 1: Jules Cloud (REST API)"]
        Pass1 --> AuthCheck["Resolve Token via Windows Credential Manager"]
        AuthCheck --> QuotaCheck{"Quota Ceiling < 100?"}
        QuotaCheck -->|"≥ 95"| QuotaPreserve["Activate Quota Preservation Mode"]
        QuotaCheck -->|"< 95"| CheckFeedback{"Tasks Awaiting Feedback?"}
        CheckFeedback -->|"Yes"| UnblockTasks["Fetch Question & POST :interact Decision"]
        CheckFeedback -->|"No"| JulesDone["Jules Cloud Unblocked & Running"]
    end
    
    JulesDone --> Pass2["Pass 2: GitHub Fleet Convergence"]
    
    subgraph P2["Pass 2: GitHub Fleet (gh CLI & API)"]
        Pass2 --> PRSearch["Query Open PRs Across 10 Repositories"]
        PRSearch --> HasPRs{"Open PRs Found?"}
        HasPRs -->|"Yes"| SecondEyeReview{"Engineering Second-Eye Review"}
        SecondEyeReview -->|"Safe & Clean Diff"| SquashMerge["gh pr merge --squash --delete-branch --admin"]
        SecondEyeReview -->|"Conflict / Destructive / Invalid"| CloseSuperseded["gh pr close --delete-branch"]
        SquashMerge --> HasPRs
        CloseSuperseded --> HasPRs
        HasPRs -->|"No (0 PRs)"| MarkDone["Mark All Notification Threads as Done (DELETE /notifications/threads/:id)"]
    end
    
    MarkDone --> Pass3["Pass 3: Jules Web UI Hygiene"]
    
    subgraph P3["Pass 3: Jules Web Dashboard Purge"]
        Pass3 --> FindClutter["Query Tasks where isAwaitingReview == true"]
        FindClutter --> HasClutter{"Clutter Found?"}
        HasClutter -->|"Yes"| BatchPurge["POST /v1/swebot/tasks:delete in Chunks of 40"]
        HasClutter -->|"No"| WebClean["Jules Web Dashboard Zero-Inbox"]
    end
    
    WebClean --> Pass4["Pass 4: Gmail Triage & Routing"]
    
    subgraph P4["Pass 4: Gmail Triage (google-workspace)"]
        Pass4 --> QueryEmails["listGmailMessages (maxResults: 500)"]
        QueryEmails --> CheckEmails{"Matching Messages > 0?"}
        CheckEmails -->|"Yes"| BatchApply["batchAdd: Optimus CD + CATEGORY_UPDATES\nbatchRemove: UNREAD + INBOX"]
        BatchApply --> QueryEmails
        CheckEmails -->|"No"| GmailClean["Primary Inbox Zero Achieved"]
    end
    
    GmailClean --> EndSync["Continuous Development Cycle Complete (All 3 Zero-Inbox)"]
```

---

## 2. The Verification & Quality Assurance Gate (Engineering Second-Eye Review)

```mermaid
flowchart TD
    Detect["Open Pull Request Detected"] --> CheckConflict{"Mergeable State?"}
    
    CheckConflict -->|"CONFLICT / DIRTY"| ConflictAction["Close PR & Delete Stale Ephemeral Branch"]
    CheckConflict -->|"CLEAN / UNKNOWN"| DiffStat["gh pr diff --stat"]
    
    DiffStat --> SecScan{"Security & Secrets Scan"}
    SecScan -->|"Credentials or Keys Exposed"| SecAlert["REJECT: Close PR & Alert"]
    SecScan -->|"Clean"| CodeHealth{"Destructive Deletions Check"}
    
    CodeHealth -->|"Core Architecture Deleted"| RejectDestructive["REJECT: Close PR & Log Violation"]
    CodeHealth -->|"Valid Code Addition/Fix"| Ratify["Ratify for Squash-Merge into main"]
    
    Ratify --> ExecuteMerge["Execute Squash-Merge & Delete Remote Branch"]
```

---

## 3. Mandatory `@jules` Trigger & Interaction Flow

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Developer / Antigravity
    participant GH as GitHub (Issue / PR / Commit)
    participant J as Jules Cloud Agent
    participant Repo as Remote Repository (main)

    Dev->>GH: Post Issue / Comment with mandatory '@jules' tag
    Note over Dev,GH: Example: "@jules Please refactor auth error handling"
    GH-->>J: Webhook fired to Jules Cloud Agent
    Note over J: Jules starts VM sandbox & analyzes repo
    J->>GH: Pushes branch 'jules-refactor-auth' & opens PR
    alt Jules needs clarification
        J->>Dev: Enters AWAITING_USER_FEEDBACK
        Dev->>J: POST :interact with authoritative consensus
        J->>GH: Resumes work & updates PR
    end
    Dev->>GH: Engineering Second-Eye Review (diff verification)
    Dev->>Repo: Squash-merges PR into main & deletes ephemeral branch
    Dev->>GH: Marks notification thread as Done
```

---

## 4. Multi-Agent Ecosystem Handoff Tree

```mermaid
flowchart LR
    AG["Antigravity (Lead Orchestrator)"] -->|"Writes Handoff & Ledger"| HandoffDir["_project_Optimus_CD_Handoffs/"]
    HandoffDir -->|"Ingests Status & Runbooks"| Mavis["Mavis (MiniMax Backup Agent)"]
    Mavis -->|"Executes Continuous Sync"| Fleet["apvizual-max Fleet"]
    AG -->|"Executes Continuous Sync"| Fleet
    Fleet -->|"Produces PRs & Events"| Jules["Jules (Cloud Worker)"]
    Jules -->|"Tagged via @jules"| AG
    Jules -->|"Tagged via @jules"| Mavis
```
