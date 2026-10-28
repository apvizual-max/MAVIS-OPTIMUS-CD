# SPEC-CD — specificația sistemului Continuous Development

> Ce e sistemul, exact. Fiecare afirmație de aici e **măsurată** pe
> 2026-10-24 sau e marcată explicit ca **NECUNOSUT**.
> Data și metoda: `docs/STARE-CD.md`.

---

## 1. Definiție

**CD (Continuous Development)** este bucla prin care o propunere scrisă de un
agent extern (Google Jules) devine cod verificabil pe mașina lui Popy, cu un
verdict măsurat, și abia apoi — cu acordul explicit al lui Popy — cod
împins în `main`.

```
    PROPOZERIE              VERIFICARE              VERDICT              DECIZIE
  Jules scrie PR  ->  Local ruleaza testele  ->  ACCEPT/ADAPT/  ->  Popy: R0
  (sandbox Google)     (aici, acum, pe disc)     UNVERIFIED/REJECT      (push+merge)
```

**Autoritatea e Local, mereu.** Jules propune. Local evaluează, corectează,
extinde și decide. Merge-ul e o decizie a lui Popy, nu a automatului.

---

## 2. Componentele

| # | Componentă | Rol | Stare |
|---|---|---|---|
| C1 | `jules-dispatch.ps1` | Trimite un task de nivel de sistem: creează issue + eticheta `jules` | ✅ măsurat |
| C2 | `jules-verify.ps1` | Verifică **fizic** un PR: clonează, face checkout, rulează testele **aici** | ✅ măsurat |
| C3 | `jules-triage.ps1` | Triază toate PR-urile deschise și scrie verdictul în `docs/triage/` | ✅ măsurat |
| C4 | `jules-adapt.ps1` | Măsoară o propunere și scrie raportul de adaptare (5 secțiuni canonice) | ✅ măsurat |
| C5 | `jules-daily.ps1` | Bucla zilnică: rotație axe → dispatch → triaj → raport | ✅ măsurat |
| C6 | `jules-install.ps1` | Montează puntea Jules într-un repo: etichetă + workflow + context + secret | ✅ măsurat |
| C7 | `jules-selfcheck.ps1` | Poarta platformei: ASCII pur, parse, cod de ieșire, 5 probe de falsificare | ✅ măsurat |
| C8 | `jules-scan-staged.ps1` | Poarta pre-commit: citește **index-ul**, nu arborele de lucru | ✅ măsurat |
| C9 | `jules-lib.ps1` | Biblioteca comună: `gh`, registru, arbore, ledger de cotă, semnături de eșec | ✅ măsurat |
| C10 | `run-jules-daily-logged.ps1` | Wrapper: log datat + HALT&REPORT + interdicții absolute | ✅ măsurat |
| C11 | `workflows/jules.yml` | Declanșarea automată: eticheta → issue → Jules | ✅ măsurat |
| C12 | `workflows/verify.yml` | Verificarea nocturnă cu porți reale | ✅ măsurat |
| C13 | `config/repos.json` | Registrul repo-urilor: ramură, etichetă, workflow, secret, comenzi | ✅ măsurat |
| C14 | `config/jules-context.md` | **Contextul canonic** pe care îl primește Jules la fiecare task | ✅ măsurat |
| C15 | `config/task-cards.md` | Cardul de task pentru fiecare axă | ✅ măsurat |
| C16 | Task Windows `JulesDailyLoop` | Rulează bucla zilnică la 09:00 | ✅ măsurat |

---

## 3. Contracte de date

### 3.1 Canalul de context

**Corpul issue-ului este canalul.** Jules nu are memorie și nu accesează
interfața noastră. Workflow-ul transmite corpul issue-ului în prompt.

Consecință: **regulile și invariantele noastre călătoresc în corpul
task-ului.** `config/jules-context.md` e sursa unică; `jules-dispatch.ps1`
îl injectează; la destinație ajunge ca `JULES-CONTEXT.md` în rădăcina
repo-ului.

> **Nu se copiază manual contextul.** O copie manuală e o copie care se
> învechinește, iar Jules va citi regula veche cu toată autoritatea
> sistemului.

### 3.2 Registrul repo-urilor

`config/repos.json` conține, per repo: ramură, vizibilitate, dacă e
triat, dacă primește taskuri, starea cozii Jules (etichetă / workflow /
secret / PR-uri deschise), și comenzile de verificare.

**Câmpul `openPrs` e măsurat, nu estimat.** Se citește din API-ul GitHub la
data măsurătorii (`measuredAt`).

### 3.3 Formatul verdictului

Raportul de adaptare are **5 secțiuni canonice**, obligatorii:

```
Ce am schimbat          <- din diff-ul real (API GitHub)
Cum am verificat        <- din comenzi rulate efectiv pe această mașină
De ce                   <- judecata lui Local
Ce NU am facut si de ce <- judecata lui Local
Riscuri                 <- judecata lui Local
```

**Scriitorul și cititorul împart aceeași cale**, prin
`Get-AdaptReportPath` / `Get-AdaptReportState`. Motivul „raport absent" și
motivul „raport incomplet" sunt **distincte** — măsurat: o variantă
interogase body-ul PR-ului în loc de raportul local și a taxat toate cele
99 de rânduri cu „report incomplete", inclusiv cele 12 cu raport complet.

---

## 4. Coduri de ieșire și verdicte

### 4.1 Verdictele de triaj

| Verdict | Verificare | Semnificație |
|---|---|---|
| `ACCEPT` | `PASS` | trece toate porțile, e complet, e corect |
| `ADAPT` | `PASS` | substanța e bună, forma sau raportul trebuie refăcute |
| `UNVERIFIED` | `UNVERIFIED` | nu s-a putut măsura → **niciun verdict nu e posibil** |
| `UNVERIFIED` | `NOT_ATTRIBUTABLE` | măsurat, dar eșecul nu aparține propunerii |
| `REJECT` | `FAIL` | încălcare de politică **sau** eșec verificabil, imputabil și reproductibil |

**`REJECT` nu se emite niciodată dintr-un singur exit code.** Vezi
`DOCTRINA-CD.md` §9.

### 4.2 Codurile de ieșire ale verificării

| Cod | Semnificație |
|---|---|
| `0` | toate comenzile de verificare au trecut |
| `1` | o comandă a picat, **reproductibil**, și nu e pe bază → imputabil |
| `2` | verificarea nu a putut rula (fără clonă, fără comenzi, checkout eșuat) |
| `3` | eșecul nu s-a repetat, sau exista deja pe bază → **măsurat, neatribuibil** |

**Codul `3` e cel mai important din tabel.** Fără el, triajul ar taxa
propuneri pentru defecte care le aveau înainte de ele.

### 4.3 Codurile de ieșire ale porților

| Cod | Semnificație |
|---|---|
| `0` | nimic blocat |
| `1` | cel puțin un `BLOCK` |
| `2` | poarta nu a putut citi index-ul |

---

## 5. Bugetul și cotele

| Parametru | Valoare | Unde stă |
|---|---|---|
| Cota Jules | **100 taskuri/zi** | contul Google AI Pro |
| `maxTasksPerDay` | 15 | `config/repos.json` → `defaults` |
| `maxOpenPrsPerRepo` | 3 | `config/repos.json` → `defaults` |
| `maxVerifyPerRepoPerRun` | 5 | `config/repos.json` → `defaults` |
| Axe | `performance` · `design` · `security` | rotație per repo |

**Cota nu e blocajul curent.** Blocajul e **backlog-ul**: 99 de PR-uri
deschise, cu plafonul de 3 PR-uri deschise pe repo. Cota arde cel mult 15
taskuri/zi; restul rămâne rezervă pentru refactorizări mari, unde sandbox-ul
lui Jules chiar contează.

**Taskurile sunt la nivel de sistem**, nu la nivel de virgulă: o țintă
măsurată, un test, un PR.

---

## 6. Porțile — contract

| Poartă | Când rulează | Ce poate face | Ce **nu** poate face |
|---|---|---|---|
| `jules-selfcheck.ps1` | înainte de orice rulare a platformei | oprește platforma dacă e coruptă | nu emite verdicte despre propuneri |
| `jules-scan-staged.ps1` | pre-commit, pe **index** | blochează secrete, email necanonic, brand interzis, căi de date personale | nu modifică nimic, nu aprobă |
| `jules-verify.ps1` | per PR, în triaj | blochează **doar** dacă eșecul e reproductibil și absent de pe bază | nu poate taxa pe eșecuri preexistente |
| `verify.yml` (GitHub) | nocturn / manual | raportează starea | **niciodată** pe `on: push` |

> **O poartă care doar observă poate fi permisă să blocheze. O poartă care
> acuză trebuie să dovedească imputabilitatea.** Altfel eșuează în direcția
> greșită — și acolo costul e tăcut și repetat.

---

## 7. Invariantele conținutului

Verificate de `jules-scan-staged.ps1` la fiecare commit:

| Invariantă | Acțiune |
|---|---|
| Email canonic unic | `apvizual@gmail.com` (+ domeniu intern `ap-id.ro`) |
| Brand interzis | „Creafac" — corect: **Ducray** |
| Căi de date personale | fragmente interzise în cale |
| Secrete | tipare de chei, tokenuri, chei private |
| Telefon | doar `WARN`, pentru că e decizia de politică a lui Popy |

Regula emailului e o **comparație**, nu o căutare a unei adrese greșite
 cunoscute: fiecare adresă găsită trebuie să fie cea canonică. O poartă
care caută o adresă greșită cunoscută nu poate prinde următoarea adresă
greșită — și se declanșează chiar pe fișierul care declară regula.

---

## 8. Limitele cunoscute

| Limită | Stare | Efect |
|---|---|---|
| `JULES_API_KEY` absent din 4 repo-uri | **necesită Popy** | calea automată nu se declanșează în ele |
| `pytest` absent pe mașină | măsurat | instrument lipsă → `NO_MEASUREMENT`, nu PASS fals |
| `core.longpaths` necesar pentru pkms | măsurat | fără el, măsurătoarea raportează 1227 ștergeri false |
| Fișiere cu nume lung în istoricul public al CI | **necorectat** | redresarea cere force-push → interzis fără R0 explicit |
| Panel `build-hub.py` cu căi Windows hardcodate | necorectat | panoul nu rulează în cloud |
| 3 din 5 repo-uri descărcate lipsesc din `_GitHub-Main_Repos-Local` | necorectat | nu e blocant: triajul lucrează pe clonă proaspătă |

**Nicio limită din tabel nu blochează CD.** Se raportează, nu se ascunde.
