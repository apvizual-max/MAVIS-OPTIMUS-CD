# INVENTAR REPO-URI — măsurat 2026-10-24

> Metodă: `gh repo list apvizual-max --limit 60 --json name,visibility,pushedAt,defaultBranchRef`
> și `gh api repos/apvizual-max/<R>`.
> **Înlocuiește** inventarul vechi din repo-ul CI (măsurat 2026-10-11/12),
> ale cărui vizibilități au devenit false.

---

## 1. Repo-urile GitHub ale lui Popy

**Toate cele 10, măsurate azi.**

| Repo | Vizibilitate | Ramură | Ultim push | Rol |
|---|---|---|---|---|
| `apvizual-max/MAVIS-CLOUD` | **PUBLIC** | `main` | 2026-10-24T01:14:10Z | **puntea** Local↔Cloud · ținta de lucru a lui Jules |
| `apvizual-max/MAVIS-OPTIMUS-CI` | **PUBLIC** | `main` | 2026-10-23T14:35:06Z | **SOT CI** — proceduri, punte, guvernanță |
| `apvizual-max/MAVIS-OPTIMUS-CD` | **nu există** | — | — | **SOT CD** — se creează la priming (R0) |
| `apvizual-max/OPTIMUS-Backbone` | **PUBLIC** | `main` | 2026-10-23T14:29:06Z | consola OPTIMUS + scripturi Git |
| `apvizual-max/Optimus-Mavis-Skills` | **PUBLIC** | `main` | 2026-10-24T00:17:22Z | skillurile agentului |
| `apvizual-max/pkms-vault-automation` | **PUBLIC** | **`master`** | 2026-10-24T00:19:25Z | menținerea vaultului |
| `apvizual-max/SENTINEL_PRIME` | **PRIVATE** | `main` | 2026-10-24T01:15:51Z | substratul doctrinei |
| `apvizual-max/Qwen-Ecosystem-Dashboard` | **PRIVATE** | `main` | 2026-10-24T00:30:08Z | sistem Qwen |
| `apvizual-max/hermes-doctor` | **PUBLIC** | `main` | 2026-10-23T14:31:44Z | plasa lui Hermes |
| `apvizual-max/hermes-local-backup` | **PUBLIC** | `main` | 2026-10-24T00:28:56Z | backup săptămânal Hermes |
| `apvizual-max/hermes-agent-temp` | **PRIVATE** | `main` | 2026-10-24T01:07:40Z | fork Hermes |

### Corectare față de inventarul vechi (2026-10-11/12)

| Repo | Inventar vechi | **Măsurat azi** |
|---|---|---|
| `Optimus-Mavis-Skills` | privat | **public** |
| `OPTIMUS-Backbone` | privat | **public** |
| `hermes-doctor` | privat | **public** |
| `hermes-agent-temp` | public | **privat** |
| `pkms-vault-automation` | privat | **public** |

> **8 repo-uri din 10 sunt publice.** Conținutul lor e citibil de oricine.
> În `MAVIS-CLOUD` sunt și date personale ale lui Popy — decizia e a lui, dar
> se spune cu voce tare. **Nu se adaugă nimic nou cu date personale în
> repo-uri publice, fără R0.**

---

## 2. Registrul de lucru al lui Jules

Sursă: `JULES - Optimus CD\config\repos.json`, măsurat la 2026-10-22.
Ce e `true` acolo înseamnă că Jules are calea automată completă.

| Repo | Ramură | Vizibilitate | Etichetă `jules` | Workflow | Secret | PR-uri deschise | Triat | Dispatch |
|---|---|---|---|---|---|---:|---|---|
| `MAVIS-CLOUD` | `main` | public | ✅ | ✅ | ✅ | **34** | da | da |
| `OPTIMUS-Backbone` | `main` | public | ❌ | ❌ | ❌ | **37** | da | da |
| `pkms-vault-automation` | **`master`** | public | ❌ | ❌ | ❌ | **25** | da | da |
| `SENTINEL_PRIME` | `main` | **privat** | ❌ | ❌ | ❌ | **3** | da | **nu** |
| `MAVIS-OPTIMUS-CI` | `main` | public | ❌ | ❌ | ❌ | 0 | da | da |
| `Optimus-Mavis-Skills` | `main` | public | ❌ | ❌ | ❌ | 0 | da | da |
| `hermes-doctor` | `main` | public | ❌ | ❌ | ❌ | 0 | **nu** | **nu** |
| `Qwen-Ecosystem-Dashboard` | `main` | privat | ❌ | ❌ | ❌ | 0 | **nu** | **nu** |

**Total PR-uri Jules deschise: 99.**

**62 din cele 99 sunt în repo-uri fără plumbing GitHub** — deci Jules are și
**calea interfeței web**, care produce PR-uri fără etichetă, fără workflow
și fără secret. Platforma folosește calea **automată**, pentru că e
programabilă și trasabilă; calea web rămâne deschisă, iar triajul prinde
PR-urile ei oricum.

`SENTINEL_PRIME` se triază dar **nu** primește taskuri noi: izolarea maximă
a doctrinei cere asta. Decizia poate fi schimbată cu o linie în registru.

---

## 3. Calea locală ↔ repo

| Cale locală | Remote | Stare |
|---|---|---|
| `…\projects\Mavis-Optimus-Continuous-Development\` | `MAVIS-OPTIMUS-CD` (**se creează la priming**) | **SOT CD** |
| `…\projects\Mavis-Optimus-Continuous-Integration\` | `MAVIS-OPTIMUS-CI` | **SOT CI** — nu se atinge din CD |
| `…\projects\Mavis-Optimus-Continuous-Development\JULES - Optimus CD\_GitHub-Main_Repos-Local-Temp\MAVIS-CLOUD\` | `MAVIS-CLOUD` | clonă de lucru, **read-only** |
| `…\projects\Mavis-Optimus-Continuous-Development\JULES - Optimus CD\_GitHub-Main_Repos-Local-Temp\pkms-vault-automation\` | `pkms-vault-automation` | clonă de lucru |
| `…\projects\Mavis-Optimus-Continuous-Development\JULES - Optimus CD\_GitHub-Main_Repos-Local-Temp\SENTINEL_PRIME\` | `SENTINEL_PRIME` | clonă de lucru |
| `…\projects\Mavis-Optimus-Continuous-Development\JULES - Optimus CD\_GitHub-Main_Repos-Local-Temp\OPTIMUS-Backbone\` | `OPTIMUS-Backbone` | clonă de lucru |
| `…\projects\Mavis-Optimus-Continuous-Development\JULES - Optimus CD\_GitHub-Main_Repos-Local-Temp\Optimus-Mavis-Skills\` | `Optimus-Mavis-Skills` | clonă de lucru |
| `…\projects\Mavis-Optimus-Continuous-Development\JULES - Optimus CD\_GitHub-Main_Repos-Local-Temp\MAVIS-OPTIMUS-CI\` | `MAVIS-OPTIMUS-CI` | clonă de lucru |
| `…\projects\Mavis-Optimus-Continuous-Development\JULES - Optimus CD\work\` | — | draft-uri și clone de lucru |

---

## 4. Ce e pe disc, în afara proiectului

| Cale | Ce | Relația cu CD |
|---|---|---|
| `C:\Users\apviz\.minimax\agents\mavis\skills\` | skillurile vii | se citesc; nu se scrie |
| `C:\Users\apviz\.minimax\agents\mavis\memory\MEMORY.md` | memoria agentului | se citește; nu e sursă de adevăr |
| `C:\Users\apviz\.minimax-agent\projects\SENTINEL_PRIME\` | substratul doctrinei | **nu se atinge** |
| `D:\Alex_Knowlege_Vault\` | vaultul (~52 000 fișiere) | **zero scanări brute**; navigare doar prin Cotor |
| `E:\CLAUDE\MINTE\00_KV_SECOND BRAIN\` | Second Brain (Obsidian) | nu se scrie fără R0 |

---

## 5. Zgomot — nu atinge

31 de clone „GitHub backup 2026-10-08" pe `C:` și `D:`; 45 de repo-uri de
ritual în `Temp`; 24 de arhive `CLAUDE_BACKUP_*` pe `E:`.

**Nu sunt periculoase. Sunt zgomot.** Un inventar care le numără ca
probleme pierde semnalul.

**Orice repo care nu e al lui Popy — nu se atinge.** Nici măsurătoare
scriind în el, nici hook, nici config.
