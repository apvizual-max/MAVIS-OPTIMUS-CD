# MAPARE-FOLDERE — unde stă tot

> Nimic nu se mută din alte proiecte. Totul e **prin referință**, ca nimic
> să nu se piardă dacă o cale se schimbă.
> Măsurat pe disc 2026-10-24.

---

## 1. Folderul CD — rădăcina

```
C:\Users\apviz\.minimax-agent\projects\Mavis-Optimus-Continuous-Development\
├── .gitignore                     artefacte de lucru, nu surse
├── README.md                      punct de intrare, cold-boot
├── DOCTRINA-CD.md                 cum lucrez
├── HANDOFF-CD.md                  promptul de transfer către sesiunea CD
├── PRIMING-CD.md                  secvența de pornire a instanței CD
├── docs\
│   ├── ARHITECTURA-CI-CD.md       convenția care separă CI de CD
│   ├── SPEC-CD.md                 specificația sistemului
│   ├── MAPARE-PROCES.md           cine face ce, cu ce intrare și ieșire
│   ├── MAPARE-FOLDERE.md          acest fișier
│   ├── WORKFLOWS.md               buclele zilnice și programate
│   ├── PROTOCOALE.md              contractele între componente
│   ├── INVENTAR-REPO-URI.md       repo-urile, măsurate
│   ├── STARE-CD.md                starea măsurată acum
│   ├── POLITICA-LIVE-REVIEW-JULES.md
│   └── POLITICA-LIVE-REVIEW-JULES.md
└── JULES - Optimus CD\            platforma executabilă
    ├── scripts\                   10 scripturi, ASCII pur
    ├── config\                    registru + context canonic + carduri
    ├── workflows\                 jules.yml + verify.yml
    ├── docs\                      STATE-JULES.md + adaptari\ + daily\ + triage\
    ├── logs\                      log datat al fiecărei rulări
    ├── state\                     IGNORAT de git
    ├── work\                      IGNORAT de git
    └── _GitHub-Main_Repos-Local-Temp\  IGNORAT de git
```

**Fără duplicare.** Documentația platformei Jules (`STATE-JULES.md`,
`adaptari\`, `daily\`, `triage\`) stă **doar** în
`JULES - Optimus CD\docs\`, unde platforma o produce. `docs\` de la rădăcina
CD descrie **sistemul CD**, nu platforma. Copierea în două locuri ar
produce două versiuni care se decalibrează — iar cea veche ar fi citită
de un agent nou fără să știe care e adevărată.

> Aceeași regulă ca în `docs/ARHITECTURA-CI-CD.md` §6: **un document
> trăiește în folderul sistemului pe care îl guvernează.**

---

## 2. Ce se urmărește în git, și ce nu

Măsurat pe disc, 2026-10-24:

| Folder | Fișiere | Octeți | În git? | De ce |
|---|---:|---:|---|---|
| `JULES - Optimus CD/config/` | 3 | 14 598 | **da** | sursă: registru, context, carduri |
| `JULES - Optimus CD/scripts/` | 10 | 143 364 | **da** | sursă: platforma |
| `JULES - Optimus CD/workflows/` | 2 | 9 542 | **da** | sursă: declanșare + verificare |
| `JULES - Optimus CD/docs/` | 19 | 343 163 | **da** | sursă: verdicturi, adaptări, rapoarte |
| `JULES - Optimus CD/logs/` | 9 | 716 638 | **da** | doveză: log datat al rulărilor |
| `JULES - Optimus CD/state/` | 2 149 | 12 234 910 | **nu** | verdicturi brute + probe de scratch |
| `JULES - Optimus CD/work/` | 7 185 | 72 655 133 | **nu** | clone locale + draft-uri |
| `_GitHub-Main_Repos-Local-Temp/` | 323 | 3 207 874 | **nu** | repo-uri descărcate |
| **Total folder CD** | **9 702** | **89 335 844** | — | — |

**Cele trei foldere ignorate sunt 9 657 de fișiere și 88 de MB** — clone și
artefacte. Nu intră în istorie. Nu se șterg: se regenerază.

---

## 3. Platforma — hartă pe scripte

| Script | Rol | Ieșire |
|---|---|---|
| `jules-lib.ps1` | bibliotecă: `gh`, registru, arbore, cotă, semnături de eșec | — |
| `jules-dispatch.ps1` | trimite un task (issue + etichetă) | issue GitHub |
| `jules-verify.ps1` | verifică fizic un PR | verdict + JSON în `state/verify/` |
| `jules-triage.ps1` | triază toate PR-urile deschise | `docs/triage/triage-*.md` + `.json` |
| `jules-adapt.ps1` | măsoară o propunere, scrie raportul de adaptare | `docs/adaptari/adapt-*.md` |
| `jules-daily.ps1` | bucla zilnică: dispatch + triaj + raport | `docs/daily/jules-daily-*.md` |
| `jules-install.ps1` | montează puntea Jules într-un repo | etichetă + workflow + context |
| `jules-selfcheck.ps1` | poarta platformei, cu 5 probe de falsificare | `FILES=10 PROBLEMS=0` |
| `jules-scan-staged.ps1` | poarta pre-commit, pe index | `BLOCKS` / `WARNS` / `SCAN_OK` |
| `run-jules-daily-logged.ps1` | wrapper: log datat + HALT&REPORT | log + cod de ieșire |

**Toate 10 sunt ASCII pur** (0 octeți peste `0x7F`). Se rulează cu
`powershell -NoProfile -File`. `pwsh` **nu** e instalat pe această mașină.

---

## 4. Dependențe din afara proiectului

| Ce | Unde | Ce se întâmplă dacă lipsește |
|---|---|---|
| Doctrina de bază | `C:\Users\apviz\.minimax\agents\mavis\memory\MEMORY.md` + `SENTINEL_OPERATIONAL_DOCTRINE.md` | se citește din repo, nu din memorie |
| Skillurile vii | `C:\Users\apviz\.minimax\agents\mavis\skills\` | nu blochează; se citesc dacă există |
| `gh` CLI | PATH | `Assert-Gh` întoarce fals → cod 2, bucla nu rulează |
| `git` | PATH | idem |
| `python` | PATH | runnerul de teste Python nu rulează → `NO_MEASUREMENT` |
| `pytest` | **absent pe această mașină** | măsurat: `python -m pytest` → exit 1, „No module named pytest" |

---

## 5. Cele 2 repo-uri GitHub și clonele lor locale

| Repo | Vizibilitate | Ramură | Rol |
|---|---|---|---|
| `apvizual-max/MAVIS-CLOUD` | **public** | `main` | puntea Local↔Cloud + ținta de lucru a lui Jules |
| `apvizual-max/MAVIS-OPTIMUS-CD` | **public** (se creează la priming) | `main` | **acest proiect** — SOT CD |
| `apvizual-max/MAVIS-OPTIMUS-CI` | **public** | `main` | SOT CI — **nu se atinge din CD** |

**Regula:** CD atinge doar repo-ul CD. `MAVIS-CLOUD` e țintă de lucru
(triage, adaptare) — nu se scrie în el direct.

---

## 6. Ce NU se atinge

- **Repo-urile altor proiecte.** Nu măsoară, nu hook-uiește, nu configurează.
- **`SENTINEL_PRIME`** — privat, substratul doctrinei. Se *triază* (3 PR-uri
  deschise), dar **nu** primește taskuri noi.
- **Instanța Cloud** — zero rol în CD.
- **Orice fișier din Vault** (`D:\Alex_Knowlege_Vault`) — zero scanări brute
  pe cele ~52 000 de fișiere; navigare exclusiv prin Cotor.
- **Fișierele istoricului public al CI** — redresarea cere force-push →
  interzis fără R0 explicit.
