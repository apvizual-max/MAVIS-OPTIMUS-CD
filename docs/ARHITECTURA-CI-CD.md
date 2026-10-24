# ARHITECTURA CI ↔ CD — separarea definitivă

> Măsurat și decis 2026-10-24. **Aceasta e Convenția care separă cele două
> sisteme.** Când apare un conflict între CI și CD, se citește asta.

---

## 1. De ce există separarea

Până la 2026-10-24, platforma Jules (dispatch → triaj → adaptare → merge)
stătea în repo-ul CI, alături de puntea Local↔Cloud. Era un proiect cu
două capete: unul care **integrează** (Local ↔ Cloud) și unul care
**dezvoltă** (Local ↔ Jules).

Amestecate, produceau trei erori reale:

1. **Conținutul greșit în repo-ul greșit.** Scripturi de dezvoltare continuă
   într-un repo care trebuia să conțină proceduri de integrare.
2. **Cota și bugetul confundate.** Limita de 100 taskuri/zi a lui Jules
   dormea lângă taskul de bridge, ca și cum ar fi fost același buget.
3. **Răspunsul greșit în sesiunea greșită.** Popy întreba despre punte și
   primea răspuns despre triaj.

**Separarea e structurală: folder, repo, sesiune, buget, documentație.**

---

## 2. Cele două jumătăți

| | **CI — Continuous Integration** | **CD — Continuous Development** |
|---|---|---|
| **Sesiune** | aceasta, la momentul deciziei | sesiunea CD paralelă |
| **Folder** | `…\Mavis-Optimus-Continuous-Integration\` | `…\Mavis-Optimus-Continuous-Development\` |
| **Repo** | `apvizual-max/MAVIS-OPTIMUS-CI` | `apvizual-max/MAVIS-OPTIMUS-CD` |
| **Puntea** | Local ↔ Cloud, prin `MAVIS-CLOUD` | — |
| **Bucla de dezvoltare** | — | Jules + Live Review |
| **Task zilnic** | `MavisSyncBridge` 08:30 | `JulesDailyLoop` 09:00 |
| **Documentația** | `docs/` în repo-ul CI | `docs/` în folderul CD |
| **Cota Jules** | nu e bugetul meu | 100 taskuri/zi, bugetul CD |

---

## 3. Cine ține ce — regulă de frontieră

### CD are

- platforma Jules: `dispatch`, `verify`, `triage`, `adapt`, `daily`, `install`, `selfcheck`, `scan-staged`
- registrul repo-urilor pentru Jules (`config/repos.json`)
- contextul canonic trimis lui Jules (`config/jules-context.md`)
- cardurile de task pe axe (`config/task-cards.md`)
- politică Live Review + workflow-urile `jules.yml` / `verify.yml`
- verdicturile de triaj și rapoartele de adaptare
- guvernanța Git/GitHub a **repo-ului CD**

### CI are

- puntea Local ↔ Cloud și scriptul `mavis-sync.ps1`
- ingest-ul read-only din `MAVIS-CLOUD` (`cloud-ingest/`)
- canalul `QUEUE/TASKS-FOR-CLOUD.md` (rămâne **canalul Cloud**)
- procedurile Git/GitHub pentru repo-ul Cloud
- guvernanța Git/GitHub a **repo-ului CI**
- inventarul repo-urilor de pe mașină

### Punctul de contact — singurul

**`MAVIS-CLOUD` e comun, dar nu e al nimănui.**

- CD îl folosește ca **țintă** de lucru pentru Jules (triage, adaptare).
- CI îl folosește ca **punte** (ingest read-only, cereri de la Cloud).

CD **nu** scrie în `MAVIS-CLOUD`. CD propune PR-uri prin Jules; CI ingestează
ce Cloud a scris. Regula rămâne: **`MAVIS-CLOUD` e sursă read-only pentru
conținut**, cu excepțiile autorizate explicit.

---

## 4. Interdicția CD pentru Cloud

Aceasta e o interdicție explicită, nu o preferință:

> **Instanța Cloud nu are rol în CD.** Nu triază, nu propune, nu review-uiește,
> nu merge-uiește.

Motivul e structural: Cloud rulează într-un container volatil, nu vede
discul, nu are context, și nu are poartă R0. Un verdict dat de Cloud ar
fi un verdict fără temelie măsurabilă — exact defectul pe care platforma
de triaj există să-l elimine.

Singura excepție e **canalul `QUEUE/`**: Cloud *citește* cereri și *scrie*
în `QUEUE/DONE/`. E o coadă de informație, nu o buclă de dezvoltare.

---

## 5. Ce s-a mutat, efectiv

Măsurat pe disc, 2026-10-24:

| | Înainte | După |
|---|---|---|
| Subfolderul platformei | `Mavis-Optimus-Continuous-Integration\_JULES-Optimus_CI\` | `Mavis-Optimus-Continuous-Development\JULES - Optimus CD\` |
| Fișiere șterse în repo-ul CI (la mutare) | — | **33** (`git status --porcelain`) |
| Fișiere în folderul CD | — | **9 702** (89 335 844 octeți) |
| `.git` în folderul CD | — | absent la început (creat de CD) |

**Platforma nu a necesitat nicio modificare de cale.** `jules-lib.ps1:12`
deduce rădăcina din `$PSScriptRoot`:

```powershell
$script:JulesRoot = Split-Path -Parent $PSScriptRoot
```

Verificat prin rulare, nu prin citire: `jules-selfcheck.ps1` din locația CD
→ `FILES=10 PROBLEMS=0`, EXIT 0, toate cele 5 probe de falsificare verzi.

**Două referințe la calea veche au fost reparate** (măsurat, nu presupus):

1. `jules-scan-staged.ps1` — lista prefixelor platformei era
   `_JULES-Optimus_CI/scripts/` și `_JULES-Optimus_CI/config/`, hardcodată.
   După mutare, poarta ar fi aplicat regula brand-ului chiar pe fișierele
   care **declară** regula — un fals pozitiv produs de o constantă veche.
   Reparat: prefixul se **derivează** din numele folderului platformei.
2. `jules-install.ps1` — mesajul sursei de context scria calea veche în
   `JULES-CONTEXT.md`. Reparat: se scrie calea **relativă, derivată**.

---

## 6. Corectarea unei ambiguități existente

`docs/CI-POLICY.md` din repo-ul CI amesteca Live Review + Jules (CD) cu
puntea și guvernanța Git (CI). **S-a deschis.** În CI rămâne politica CI;
politica Live Review + Jules e în CD, la `docs/POLITICA-LIVE-REVIEW-JULES.md`.

Regula: **un document trăiește în folderul sistemului pe care îl guvernează.**
Un document care acoperă două sisteme nu e document — e o ambiguitate cu
format de markdown.

---

## 7. Regula Triadei, reținută

```
1 conversație  =  1 folder local  =  1 repo GitHub
```

Cele două sisteme au fiecare conversația, folderul și repo-ul lui.
**Proiectele nu se ating între ele.** Când celălalt are nevoie de ceva, îi
dau un prompt, Popy îl duce în sesiunea respectivă, care are contextul
complet.

**Aceasta e și motivul pentru care nu ating repo-urile altor proiecte:** nu
am contextul lor, și un agent fără context într-un repo străin e exact
defectul pe care îl reparăm.
