# WORKFLOWS — buclele CD, programate și manuale

> Ce rulează, când, cu ce ieșire, și cine deține decizia.
> Toate stările de mai jos sunt **măsurate pe 2026-10-24**.

---

## 1. Buclele programate pe această mașină

Măsurat cu `Get-ScheduledTask` pe 2026-10-24:

| Task | Ora | Ultima rulare | `LastTaskResult` | Următoarea | Rol |
|---|---|---|---|---|---|
| `MavisSyncBridge` | **08:30** | 2026-10-23 08:30:01 | **0** | 2026-10-24 08:30 | **CI** — puntea Local↔Cloud |
| `JulesDailyLoop` | **09:00** | 2026-10-23 09:00:01 | **0** | 2026-10-24 09:00 | **CD** — bucla Jules |

`LastTaskResult = 0` înseamnă **rulare reușită**. Nu „a început".

**Live Review-ul nocturn (03:00) nu e un task Windows** — e un cron de
GitHub Actions, în `workflows/verify.yml`, cu `schedule: cron '0 3 * * *'`
și `workflow_dispatch`. **Interzis pe `on: push`.**

---

## 2. `JulesDailyLoop` — bucla CD zilnică

```
09:00  Task Scheduler
         |
         v
       run-jules-daily-logged.ps1
         |  1. LOG DATAT   -> logs/jules-daily-YYYY-MM-DD.log, cu timestamp
         |  2. RULEAZA     -> jules-daily.ps1
         |  3. HALT&REPORT -> dacă exit nenul: se oprește, scrie ce a găsit
         v
       jules-daily.ps1
         |  1. citește registru + ledger de cotă
         |  2. rotează axa per repo (respectă plafonul de 3 PR-uri deschise)
         |  3. dispatch: creează issue + eticheta `jules`
         |  4. triage: verdict măsurat pe fiecare PR deschis
         |  5. scrie raportul zilnic
         v
       docs/daily/jules-daily-YYYY-MM-DD.md
```

### Interdicțiile absolute ale wrapperului

Nu `reset --hard`. Nu `checkout` forțat. Nu `clean`. Nu force-push. Nu
merge automat.

> **Bucla trimite taskuri și citește propuneri. Decizia de merge rămâne a
> lui Popy, prin R0.** Interzicerea e în cod, nu în intenție — pentru că o
> interdicție stată doar în intenție se uită la prima rulare nesupravegheată.

---

## 3. `MavisSyncBridge` — puntea (aparține CI)

```
08:30  Task Scheduler
         |
         v
       run-sync-logged.ps1 -> mavis-sync.ps1
         |  PAS1_CLOUD: git pull din MAVIS-CLOUD, compară SHA-urile
         |  PAS2_LOCAL: git status; dacă e curat, nimic de comitat
         |  FINAL: cloud=<sha> local=<sha> impingere=NEEXECUTATA
         v
       logs/mavis-sync-YYYY-MM-DD.log
```

**Măsurat, rularea din 2026-10-23:**

```
PAS1_CLOUD|exit_pull=0|local_inainte=2cc9e89|local_dupa=3f2aceb|remote=3f2aceb0|schimbat=True
PAS2_LOCAL|status=curat|nimic de comitat
FINAL|cloud=3f2aceb|local=f5fb3f3|impingere=NEEXECUTATA|poarta_R0=ramane_la_Popy
Cod de iesire al puntii: 0
```

Trei lucruri se citesc aici, în ordine:

1. `exit_pull=0` și `local_dupa == remote` → **puntea e vie**, fără divergență.
2. `PAS2_LOCAL|status=curat` → nimic necomitat în arborele de lucru.
3. `impingere=NEEXECUTATA|poarta_R0=ramane_la_Popy` → **push-ul e blocat
   corect.** Puntea nu împinge.

---

## 4. GitHub Actions în repo-urile țintă

### `jules.yml` — declanșarea

| | |
|---|---|
| **Trigger** | eticheta `jules` pusă pe un issue |
| **Ce face** | transmite corpul issue-ului în prompt, împreună cu `JULES-CONTEXT.md` |
| **Nu** | nu rulează pe `push`; nu pune secrete în Environment variables |

### `verify.yml` — verificarea nocturnă

| | |
|---|---|
| **Trigger** | `schedule: cron '0 3 * * *'` + `workflow_dispatch` |
| **Ce face** | rulează cele verificări reale ale repo-ului |
| **Nu** | **nu** rulează pe `push` |

**Cele 7 verificări** (moștenite din MAVIS-CLOUD, extinse):

1. niciun secret în commit
2. JSON-uri valide
3. sintaxă JavaScript
4. sintaxă Python
5. build-ul proiectului reușește
6. regulile de business
7. puntea e vie

**Regula de ieșire:** dacă un repo nu poate fi măsurat, titlul devine
**„MĂSURĂTURĂ INCOMPLETĂ"** și ieșirea e `2`.

> Un senzor mort care raportează sănătate e mai prost decât un senzor care
> lipsește.

---

## 5. Fluxuri manuale

| Flux | Comandă | Când |
|---|---|---|
| Poarta platformei | `powershell -NoProfile -File scripts\jules-selfcheck.ps1` | înainte de orice rulare |
| Poarta pre-commit | `powershell -NoProfile -File scripts\jules-scan-staged.ps1` | automat, la fiecare `git add` + commit |
| Plan de instalare | `powershell -NoProfile -File scripts\jules-install.ps1 -Repo <R>` | când vrei puntea Jules într-un repo |
| Instalare efectivă | `… -Repo <R> -Apply` | **R0** — scrie pe GitHub |
| Dispatch | `powershell -NoProfile -File scripts\jules-dispatch.ps1 -Repo <R> -Axis <A>` | după triaj, ca să se consume cota |
| Verificare unui PR | `powershell -NoProfile -File scripts\jules-verify.ps1 -Repo <R> -Pr <N>` | la nevoie |
| Triaj | `powershell -NoProfile -File scripts\jules-triage.ps1 -MaxVerify 40` | zilnic, după dispatch |
| Adaptare | `powershell -NoProfile -File scripts\jules-adapt.ps1 -Repo <R> -Pr <N>` | pentru un verdict ADAPT |
| Bucla completă | `powershell -NoProfile -File scripts\jules-daily.ps1` | rulare manuală |

---

## 6. Curățenia zilnică

| Ce | Cum | De ce |
|---|---|---|
| Logurile cresc cu fiecare rulare | `logs/` e versionat | doveză |
| `state/verify/` acumulează JSON-uri brute | ignorat de git | e rezultat brut, nu sursă |
| `state/tmp/` acumulează probe | ignorat de git | scratch de măsurare |
| `work/` acumulează clone | ignorat de git | se regenerează |

**Nimic nu se șterge definitiv.** Dacă un raport e consumat, se mută în
`docs/arhiva/` — nu se șterge. Ștergerea definitivă e interzisă; singura
opțiune e Trash recuperabil (`mavis-trash.cmd --`).
