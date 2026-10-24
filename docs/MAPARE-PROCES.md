# MAPARE-PROCES — cine face ce, cu ce intrare și ce ieșire

> Fluxul complet CD, de la intenție la cod împins. Fiecare pas are
> **intrare**, **ieșire**, **poartă** și **cine deține decizia**.

---

## 1. Fluxul principal — de la task la merge

```
  [1] LOCAL: jules-daily.ps1
      |  citește config/repos.json + ledger de cotă
      |  rotește axa (performance / design / security) per repo
      v
  [2] LOCAL: jules-dispatch.ps1
      |  creează issue cu eticheta `jules`
      |  corpul issue-ului = contextul canonic (config/jules-context.md)
      |  PRIMEȘTE R0?  NU — issue-ul e o propunere, nu o scriere în main
      v
  [3] GITHUB: eticheta `jules` declanșează .github/workflows/jules.yml
      |
      v
  [4] JULES (sandbox Google)
      |  citește AGENTS.md + JULES-CONTEXT.md + corpul issue-ului
      |  lucrează, deschide PR
      v
  [5] LOCAL: jules-triage.ps1
      |  pentru fiecare PR deschis:
      |    Test-DiffPolicy      -> secrete / brand / email / căi personale
      |    jules-verify.ps1     -> clone + checkout + RULARE REAL a testelor
      |    Get-AdaptReportState -> raportul local, nu body-ul PR-ului
      |    Compare-JulesFailureSets -> imputabil / preexistent / mixt
      v
  [6] VERDICT: ACCEPT | ADAPT | UNVERIFIED | REJECT
      |  verdictul e un verdict. NU e un merge.
      v
  [7] LOCAL: jules-adapt.ps1 (numai pentru ADAPT)
      |  scrie raportul de adaptare: 5 secțiuni canonice
      |  Ce am schimbat / Cum am verificat / De ce / Ce NU am facut / Riscuri
      v
  [8] POPY: R0
      |  UN SINGUR R0: push + merge
      v
  [9] LOCAL: git push (prin poarta R0) -> main
```

---

## 2. Pașii, detaliat

### [1] Bucla zilnică — `jules-daily.ps1`

| | |
|---|---|
| **Intră** | `config/repos.json`, ledger de cotă `state/quota-YYYY-MM-DD.json`, PR-uri deschise (API GitHub) |
| **Ieșire** | issue-uri noi, raport zilnic `docs/daily/jules-daily-YYYY-MM-DD.md`, log `logs/jules-daily-YYYY-MM-DD.log` |
| **Poartă** | plafon `maxOpenPrsPerRepo` = 3, plafon `maxTasksPerDay` = 15, plafon `maxVerifyPerRepoPerRun` = 5 |
| **Decizie** | automată — nu cere R0 |
| **Task** | `JulesDailyLoop`, zilnic la **09:00**, măsurat `lastResult=0` |

### [2] Dispatch — `jules-dispatch.ps1`

| | |
|---|---|
| **Intră** | `-Repo`, `-Axis`, `config/jules-context.md`, `config/task-cards.md` |
| **Ieșire** | issue GitHub cu eticheta `jules` |
| **Poartă** | `-DryRun` afișează planul fără scriere; eticheta `jules` trebuie să existe |
| **Decizie** | automată |
| **Notă** | **crearea unui issue nu e push.** Push-ul e doar pe `main`. |

### [3] Workflow-ul de declanșare — `jules.yml`

Citește eticheta, transmite corpul issue-ului în prompt. **Nu** rulează pe
`push`. **Nu** are secrete în Environment variables — cheia stă în
secret manager.

### [4] Jules

Sandbox Google. Nu are acces la discul lui Popy, nu are memorie, nu
accesează interfața noastră. **De aceea contextul trebuie să călătorească
în corpul task-ului.**

### [5] Triajul — `jules-triage.ps1`

| | |
|---|---|
| **Intră** | PR-urile deschise de `app/google-labs-jules` pe repo-urile din registru |
| **Ieșire** | `docs/triage/triage-YYYY-MM-DD.md` + `.json` (câte un rând per PR) |
| **Poartă** | `Test-DiffPolicy` → `jules-verify.ps1` → `Get-AdaptReportState` → comparația semnăturilor |
| **Decizie** | automată — **dar verdictul nu e merge** |

### [6] Verdictul

Vezi `docs/SPEC-CD.md` §4.1. **Regula de aur:** o poartă care acuză
trebuie să dovedească imputabilitatea.

### [7] Adaptarea — `jules-adapt.ps1`

| | |
|---|---|
| **Intră** | `-Repo`, `-Pr` |
| **Ieșire** | `docs/adaptari/adapt-<REPO>-pr<N>.md` cu 5 secțiuni canonice |
| **Poartă** | checkout verificat (ramură + SHA + fișiere proprii), guard `origin`, conflict scan cu celelalte PR-uri deschise |
| **Decizie** | automată pentru **măsurătoarea**; judecata rămâne a lui Local |

### [8] R0 — singurul punct unde omul intră

**Popy nu e în buclă.** Nu vede issue-uri, nu verifică PR-uri, nu
aprobă pași. Singurul său act e R0-ul de push/merge. Dacă neîmpinsele
ajung la **50**, alerta apare la fiecare răspuns până dă R0.

### [9] Push

Prin poarta existentă (`scripts\git-autopush.ps1 -Acord` în proiectul
părinte), nu prin `git push` direct. **Verificarea e `git ls-remote`**, nu
codul de ieșire: `git` scrie progresul pe stderr și poate arunca o eroare
roșie chiar când a mers bine.

---

## 3. Bucla Live Review — separată, nocturnă

```
  [L1] 03:00 (cron) sau la cerere
  [L2] măsoară: HEAD local, server prin git ls-remote, comituri neîmpinse
  [L3] sub prag? -> nu se atinge nimic
  [L4] push (dacă a fost dat R0) -> git ls-remote, SHA server == SHA HEAD
  [L5] DOAR ACUM: Live Review pe ce e deja pe GitHub
```

**Interzis absolut:** `on: push`. Live Review verifică codul care **pleacă
de la mașină și ajunge pe GitHub**; declanșat la push, ar pune o poartă
în calea lui Popy și ar arde cotele.

**Rolul lui e să raporteze, nu să oprească.** `--range` e read-only.

**Calea 2** (limită de cont, rate limit, LRC căzut): pushul e **identic**,
review-ul nu se rulează, iar **mesajul de eroare pentru Popy e niciunul**.
Măsurat pe un push real: contul a răspuns negativ, scriptul a intrat în
calea 2, pushul a rămas confirmat.

---

## 4. Puntea Local ↔ Cloud — aparține CI, nu CD

Menționată aici doar ca **punct de contact**:

```
  Cloud (container volatil)          Local (mașina lui Popy)
       |  git push automat                     |
       |---------------------------------------->|
       |                            git pull (MavisSyncBridge 08:30)
       |<----------------------------------------|
       |  git pull                              | commit pe main
                                                 | push DOAR cu R0
```

**CD nu rulează puntea și nu scrie în `MAVIS-CLOUD`.** CD doar *triază* PR-uri
ale repo-ului Cloud și propune adaptări.

---

## 5. Decizii, și cine le ia — tabelul autorității

| Decizie | Cine | R0? |
|---|---|---|
| Ce axă se rotește azi | automat | nu |
| Ce propunere e acceptabilă | Local, măsurat | nu |
| Cum se corectează o propunere | Local | nu |
| Ce intră în `main` în repo-ul CD | Local, automat (commit) | nu |
| Ce ajunge pe GitHub | Local, **poarta R0** | **da** |
| Crearea repo-ului CD | Popy | **da** |
| Punerea secretului `JULES_API_KEY` | Popy | **da** |
| Redresarea istoricului public (force-push) | Popy | **da** |
| Ștergerea definitivă a oricărui lucru | — | **interzisă** |
