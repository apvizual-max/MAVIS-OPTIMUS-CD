# STARE-CD — măsurată 2026-10-24

> Fiecare cifră e **măsurată acum**, cu metoda indicată.
> Ce nu e măsurat e marcat **NECUNOSUT**. Nu se raportează memorie.

---

## 1. Folderul CD

Măsurat cu `Get-ChildItem -Recurse -File`:

| | |
|---|---|
| Fișiere | **9 810** |
| Octeți | **89 729 822** |
| Subfolder urmărit în git | `JULES - Optimus CD\` (config, scripts, workflows, docs, logs) |
| Subfoldere ignorate | `state\` · `work\` · `_GitHub-Main_Repos-Local-Temp\` |

**9 657 de fișiere și ~88 MB sunt artefacte de lucru**, nu surse. Nu intră
în istorie, nu se șterg.

## 2. Repo-ul CD local

Măsurat cu `git log`, `git status`, `git ls-files`:

| | |
|---|---|
| Ramură | `main` |
| Commituri | `9518012` · `cb8fcbb` — **la scrierea acestui document**; acesta intră în al treilea |
| Fișiere urmărite | **58** (59 cu acest document) |
| Arbore | **curat** (`DIRTY_LINES=0`) |
| Remote | **nu există încă** → se creează la priming (R0) |
| Config local | `core.autocrlf=false` · `core.eol=native` · `core.longpaths=true` · `core.hooksPath` (poarta de push) |
| `core.hooksPath` global | **gol** ✓ |

## 3. Platforma Jules

### 3.1 Poarta — măsurată din locația CD

```
powershell -NoProfile -File scripts\jules-selfcheck.ps1
→ FILES=10 PROBLEMS=0
→ Toate scripturile sunt curate: ASCII pur, parse fara erori, cod de iesire necontaminat.
→ SELFCHECK_EXIT=0
```

Toate cele 10 scripturi: `nonascii=0`, `parseErrors=0`,
`exitContaminated=false`.

**Cele 5 probe de falsificare, verzi:**

| Probă | Ce falsifică |
|---|---|
| `proba-idiom` | payload pe stdout **și** cod de ieșire 3 (proba eșuează intenționat) |
| `proba-checkout` | poarta respinge director neclonat, ramură greșită, fișier lipsă |
| `proba-runner` | acceptă doar fișierele cu runner real; un fișier pytest-style ar produce un PASS fals |
| `proba-raport` | raportul existent e recunoscut, cel absent nu e inventat; scriitor și cititor au aceeași cale |
| `proba-atribuire` | eșec preexistent → `PREEXISTING`, eșec nou → `ATTRIBUTABLE`, nemaiplicabil → `MIXED` |

### 3.2 Independența de cale — măsurată, nu presupusă

`jules-lib.ps1:12` → `$script:JulesRoot = Split-Path -Parent $PSScriptRoot`.

**Dovadă prin rulare:** poarta selfcheck rulează verde **din locația CD**,
fără nicio modificare de cale în scripturi.

### 3.3 Cele două referințe la calea veche, reparate

| Fișier | Defect | Reparație | Dovadă |
|---|---|---|---|
| `jules-scan-staged.ps1` | prefixul platformei hardcodat `_JULES-Optimus_CI/…` | derivat din numele folderului | scannerul raportează `JULES - Optimus CD/scripts/…` |
| `jules-install.ps1` | calea veche scrisă în `JULES-CONTEXT.md` | cale **relativă**, derivată | mesajul nu mai conține cale absolută |

**De ce conta:** după mutare, poarta ar fi aplicat regula brand-ului
**chiar pe fișierele care o declară** — un fals pozitiv produs de o
constantă veche.

### 3.4 Scannerul pre-commit — măsurat

| Repo | Staged | Scanned | Blocks | Warns | Ieșire |
|---|---:|---:|---:|---:|---|
| CD | 56 | 56 | **0** | **0** | `SCAN_OK`, EXIT 0 |
| CD (al doilea commit) | 2 | 2 | **0** | **0** | `SCAN_OK`, EXIT 0 |
| CI | 40 | 7 | **0** | **0** | `SCAN_OK`, EXIT 0 |

*(În CI, 33 de intrări erau ștergeri, iar ștergerile nu se scanează.)*

## 4. Poarta de push

**Măsurat 2026-10-24:** poarta era **neinstalată** în ambele repo-uri
(`core.hooksPath` absent). **Instalată acum, per repo**:

```
git -C <repo> config core.hooksPath C:/Users/apviz/.minimax-agent/projects/scripts/git-hooks
```

| Verificare | Rezultat |
|---|---|
| `core.hooksPath` global | **gol** ✓ — nu se scurge pe mașină |
| Probe **fără** martor | **exit 1** + mesajul „POARTA: acest repo nu se impinge fara acordul lui Popy" |
| Probe **cu** martor | **exit 0**, martor **consumat** |
| `lrc.exe` (Live Review CLI) | prezent, 26 356 224 octeți |

Probe rulată cu `C:\Program Files\Git\bin\sh.exe` — `sh` nu e pe PATH în
PowerShell, dar hookul e executat de git prin shell-ul propriu.

## 5. GitHub — măsurat

| Repo | Vizibilitate | Ultim push | Workflow-uri | Secrete |
|---|---|---|---|---|
| `MAVIS-CLOUD` | **public** | 2026-10-24T01:14:10Z | `jules.yml`, `verify.yml` | `JULES_API_KEY` |
| `MAVIS-OPTIMUS-CI` | **public** | 2026-10-23T14:35:06Z | **niciunul** (404) | **niciunul** |
| `MAVIS-OPTIMUS-CD` | **nu există** (404) | — | — | — |

**10 repo-uri la `apvizual-max`; 8 publice.** Lista completă:
`docs/INVENTAR-REPO-URI.md`.

**`JULES_API_KEY` e prezent doar în `MAVIS-CLOUD`** — măsurat pe toate cele
6 repo-uri din registru.

## 6. Buclele programate

| Task | Ora | Ultima rulare | `LastTaskResult` | Următoarea |
|---|---|---|---|---|
| `MavisSyncBridge` | 08:30 | 2026-10-23 08:30:01 | **0** | 2026-10-24 08:30 |
| `JulesDailyLoop` | 09:00 | 2026-10-23 09:00:01 | **0** | 2026-10-24 09:00 |

Live Review: cron de GitHub Actions, `0 3 * * *`. **Interzis pe `on: push`.**

## 7. Puntea Local ↔ Cloud — verificată azi

| Verificare | Rezultat |
|---|---|
| `mavis-sync.ps1 -SelfTest` | `POARTA\|TRECUT\|mavis-sync nu contine niciun verb interzis` — **EXIT 0** |
| `run-sync-logged.ps1 -DryRun` | `DryRun: NU ruleaza nimic. Iesire.` — **EXIT 0** |
| Ultima rulare reală (2026-10-23) | `exit_pull=0`, `local_dupa == remote`, `PAS2_LOCAL\|status=curat`, `impingere=NEEXECUTATA` — **EXIT 0** |
| Consecință | **12 loguri consecutive**, 2026-10-12 → 2026-10-23, fără gol |

**Puntea e vie și nu împinge.**

## 8. Bucla Jules — starea triajului

Sursă: `JULES - Optimus CD\docs\triage\triage-2026-10-23.md`, rulare pe
toate cele 99 de PR-uri, `TRIAGE_EXIT=0`.

| Verdict | Verificare | Număr |
|---|---|---:|
| ACCEPT | PASS | **12** |
| ADAPT | PASS | **40** |
| UNVERIFIED | UNVERIFIED | **46** |
| UNVERIFIED | NOT_ATTRIBUTABLE | **1** |
| **REJECT** | FAIL | **0** |

**Per repo:**

| Repo | PR-uri | ACCEPT | ADAPT | UNVERIFIED | NOT_ATTRIBUTABLE | REJECT |
|---|---:|---:|---:|---:|---:|---:|
| MAVIS-CLOUD | 34 | 10 | 23 | 1 | 0 | 0 |
| OPTIMUS-Backbone | 37 | 2 | 17 | 18 | 0 | 0 |
| pkms-vault-automation | 25 | 0 | 0 | 25 | 0 | 0 |
| SENTINEL_PRIME | 3 | 0 | 0 | 3 | 0 | 0 |

`SENTINEL_PRIME#3` → `ATTRIBUTION=PREEXISTING`: toate cele 10 eșecuri
identificate există și pe `main`.

**12 rapoarte de adaptare** în `JULES - Optimus CD\docs\adaptari\`.

**Cota Jules: 100/zi.** Nu e blocajul — blocajul e backlog-ul: 99 PR-uri
deschise, plafon `maxOpenPrsPerRepo` = 3.

## 9. Starea Git a repo-ului CI

| | |
|---|---|
| HEAD | `ce70f3f` — „CI: separarea CI/CD - platforma Jules a plecat in CD; adaug procedurile Git/GitHub si starea masurata" |
| `origin/main` | `d9a186e` |
| **Commituri neîmpinse** | **11** |
| Fișiere urmărite | 33 (era 63) |
| Arbore | **curat** |
| Poarta de push | **instalată** |

## 10. R0-urile deschise

| # | Acțiune | Unde | De ce |
|---|---|---|---|
| **R0-1** | creare repo public `MAVIS-OPTIMUS-CD` + primul push | CD | scriere externă |
| **R0-2** | `JULES_API_KEY` în repo-ul CD | CD | secret write-only |
| **R0-3** | `jules-install.ps1 -Apply` pe CD | CD | scriere pe GitHub |
| **R0-4** | **push** al celor 11 commituri din `MAVIS-OPTIMUS-CI` | CI | scriere pe GitHub |
| **R0-5** | merge-ul celor 12 PR-uri ACCEPT | CD | merge = push |
| R0-6 | corectarea adresei necanonice în 9 fișiere MAVIS-CLOUD | CI | repo public, read-only pt conținut |
| R0-7 | decizia despre istoricul public (force-push) | CI | rescrie istoricul public |
| R0-8 | `JULES_API_KEY` în celelalte 4 repo-uri | CD | secret write-only |
| R0-9 | instalarea `pytest` | — | instalare de software |
| R0-10 | harness de test în pkms | — | scriere într-un repo străin |

**R0-1, R0-2, R0-3 sunt necesare pentru ca sesiunea CD să poată porni.**
R0-4 e singurul care blochează ritmul în CI.
