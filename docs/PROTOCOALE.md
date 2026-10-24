# PROTOCOALE — contractele între componente

> Ce promite fiecare componentă, ce poate cere, și ce e interzis.
> Un protocol scris e un contract; un protocol nescris e o presupunere.

---

## 1. Local ↔ Jules

### 1.1 Local trimite

| | |
|---|---|
| **Cerință** | issue GitHub cu eticheta `jules`, pe un repo din registru |
| **Corpul issue-ului** | contextul canonic + cardul de task al axei |
| **Ce promite Local** | că issue-ul conține contextul complet, deci Jules nu trebuie să invente |
| **Ce nu promite Local** | că propunerea va fi acceptată |
| **R0?** | **nu** — un issue nu e o scriere în `main` |

### 1.2 Jules răspunde

| | |
|---|---|
| **Ce trimite** | un pull request |
| **Ce trebuie să conțină PR-ul** | o țintă, un test, cifre măsurate |
| **Ce nu poate face** | merge în `main`, push, modificarea istoricului |

### 1.3 Local judecă

| | |
|---|---|
| **Verdict** | ACCEPT · ADAPT · UNVERIFIED · REJECT |
| **Iesire** | un rând per PR în `docs/triage/triage-YYYY-MM-DD.md` + `.json` |
| **Ce e interzis** | verdict fără măsurătoare; verdict de blame fără imputabilitate |

---

## 2. Contractul de verdict — cel mai important

### 2.1 Un verdict pozitiv cere

1. diff-ul trece poarta de politică
2. verificarea fizică a trecut — **sau** e clar marcată ca
   `NO_MEASUREMENT`
3. raportul de adaptare există și are cele 5 secțiuni canonice

### 2.2 Un verdict negativ (REJECT) cere **două măsurători în plus**

Doar pe calea de eșec:

1. **Reproductibilitate** — aceleași comenzi, în același arbore, a doua oară.
   Dacă trece → `FLAKY`. Un eșec care nu se repetă nu poate fi imputat.
2. **Baza** — aceleași comenzi pe ramura de bază.
   - baza trece → **imputabil**
   - baza pică cu **aceeași semnătură** → **preexistent**
   - parțial → **mixt**

### 2.3 Semnătura eșecului

Comparația cere **semnătura**, nu „a picat / nu a picat". Formatul măsurat
pentru `SENTINEL_PRIME`:

```
=== Secțiune ===
Status: FAIL
Passed: n/m
Errors:
  - ...
```

Semnătura se **normalizează**: `\d+` → `#`. Un mesaj ca „snapshot is
10774s old" se schimbă între două runde, iar o semnătură care se schimbă cu
ceasul nu e semnătură.

### 2.4 Codul 3

`3` = **măsurat, dar neatribuibil** → verdict `UNVERIFIED`, **nu** `REJECT`.
Eșecurile care apar doar pe cap și nu pe bază se raportează **numerate**,
ca judecata rămână a celui care citește — nu a automatului.

---

## 3. Contractul contextului

```
config/jules-context.md   →  (unică sură)
        │
        ├─ jules-dispatch.ps1 citește
        │        ↓
        │   corpul issue-ului  →  jules.yml  →  promptul lui Jules
        │        ↓
        │   JULES-CONTEXT.md în rădăcina repo-ului (scris de jules-install.ps1)
        │
        └─ jules-install.ps1 scrie JULES-CONTEXT.md în repo-uri țintă
```

**Invariante:**
- contextul se **injectează**, nu se copiază manual
- `JULES-CONTEXT.md` în repo țintă e **derivat**, cu antet care spune
  „Regenerat de jules-install.ps1. Nu edita aici — edita la sursă."
- sursa canonică se schimbă într-un singur loc

---

## 4. Contractul registrului

`config/repos.json` e citit de `jules-lib.ps1` prin `Get-RepoRegistry`.
Câmpurile care contează:

| Câmp | Contract |
|---|---|
| `name` | trebuie să existe ca repo la `apvizual-max/<name>` |
| `branch` | ramura reală — `pkms-vault-automation` e pe `master`, nu `main` |
| `triage` | se triază? |
| `dispatch` | primește taskuri noi? |
| `jules.label` / `jules.workflow` / `jules.secret` | starea căii automate |
| `jules.openPrs` | **măsurat**, cu `measuredAt` — nu estimat |
| `verify.commands` | comenzi rulate de `jules-verify.ps1`; gol = detectare automată |
| `notes` | raționamentul, nu doar faptul |

**Un registru fără `measuredAt` e o listă de dorințe, nu o măsurătoare.**

---

## 5. Contractul raportului de adaptare

5 secțiuni canonice, obligatorii:

```
Ce am schimbat
Cum am verificat
De ce
Ce NU am facut si de ce
Riscuri
```

**Scriitorul** (`jules-adapt.ps1`) și **cititorul** (`jules-triage.ps1`) împart
aceeași cale, prin `Get-AdaptReportPath` / `Get-AdaptReportState`.

**Două motive distincte, obligatoriu:**
- „nu există încă raport de adaptare (încă neadaptat)"
- „raport de adaptare incomplet, lipsesc secțiunile: ..."

Confundarea lor a produs un fals pozitiv pe **toate cele 99 de rânduri**,
inclusiv pe cele 12 care aveau raport complet. Măsurat și reparat.

---

## 6. Contractul porților

### 6.1 Ce poate bloca, și ce nu

| Poartă | Tip | Poate bloca? |
|---|---|---|
| `jules-selfcheck.ps1` | observă platforma | **da** |
| `jules-scan-staged.ps1` | observă conținutul | **da** |
| `jules-verify.ps1` | **acuză** | **numai** cu imputabilitate dovedită |
| `verify.yml` | observă | **da**, dar nu pe `push` |

### 6.2 Poarta care nu poate eșua nu e poartă

Măsurat: `function F { Write-Output 'X'; return 3 }` → `$c = F` →
`@('X', 3)` → `exit $c` → **EXIT 0**. Orice poartă care afișa înainte de a
returna un cod de eșec returna **SUCCES**.

Reparat prin `Write-JulesOut` (stdout direct) în toate cele 6 scripturi
afectate, iar poarta `jules-selfcheck.ps1` verifică **static** acest
tipar, plus o **probă de falsificare** care eșuează intenționat.

### 6.3 Poarta citește index-ul, nu arborele de lucru

Scannerul pre-commit citește `git show :<path>` — blob-ul **stajat**.
Un arbore de lucru poate diferi de conținutul care va fi commitat, iar o
poartă care citește arborele verifică altceva.

---

## 7. Contractul Git

| Acțiune | Cine | R0 | Verificare |
|---|---|---|---|
| `git add` | agent | nu | — |
| `git commit` pe `main` | agent | **nu** | scannerul pre-commit |
| `git push` | agent | **da** | `git ls-remote` (nu codul de ieșire) |
| merge de PR | agent | **da** | `git ls-remote` după push |
| fork / branch nou | agent | numai la cerere | — |
| `reset --hard`, `clean -fdx`, force-push, ștergere definitivă | — | **interzise** | — |

**Instanța Cloud** e singura care împinge fără R0, pentru că altfel pierde
datele la oprirea containerului. **Nu aparține CD.**

---

## 8. Contractul de comportament între om și agent

| Situație | Ce fac |
|---|---|
| Popy dă un GOAL | decid tehnic singur, execut, predau rezultatul |
| Popy scrie „nu acționa" | nu acționez |
| Trei piloni se întâlnesc | decid și acționez |
| Trei piloni nu se întâlnesc | spun blocajul într-un rând, cu ce am căutat |
| Am nevoie de un secret | cer **R0** și dau comanda exactă |
| Am nevoie de o decizie | o iau eu |
| Am nevoie de o confirmare tehnică | **nu o cer** |

**Raportul e complet în sine.** Popy nu are memorie între sesiuni.
