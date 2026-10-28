# POLITICA LIVE REVIEW + JULES

> Politica de integrare continuă a CD. **Nu se schimbă fără R0.**
> O parte din acest text a fost mutată din `docs/CI-POLICY.md` al repo-ului
> CI — acolo amesteca CD și CI. Vezi `docs/ARHITECTURA-CI-CD.md` §6.

---

## 1. Live Review

### 1.1 Poziția în sistem

**NICIODATĂ pe push. NICIODATĂ la comit. Doar după ce serverul a confirmat,
și doar o dată pe zi sau la cerere.**

```
1. măsoară    HEAD local, server prin git ls-remote, comituri neîmpinse
2. decide     sub prag? nu se atinge nimic
3. push       git push PUR — fără LiveReview, fără review, fără poartă
4. verifică   git ls-remote; SHA server == SHA HEAD
5. review     LiveReview — DOAR ACUM, pe ce e deja pe GitHub
```

### 1.2 De ce

Live Review verifică codul care **pleacă de la mașină și ajunge pe
GitHub**. Deci se declanșează la push, pe ce tocmai a ajuns.

**Rolul lui e să raporteze, nu să oprească.** `--range` e read-only: nu
atinge comiturile, nu scrie atestări, nu poate bloca nimic.

### 1.3 Trigger

| | |
|---|---|
| **Nu** | `on: push` — arde cotele și pune o poartă în calea lui Popy |
| **Da** | `workflow_dispatch` — la cerere explicită |
| **Da** | `schedule: cron '0 3 * * *'` — o dată pe zi, noaptea |

Măsurat: `MAVIS-CLOUD\.github\workflows\verify.yml` implementează deja
exact asta, cu 7 verificări reale. **Îl folosim ca template.**

### 1.4 Cele două căi

| | Calea 1 | Calea 2 |
|---|---|---|
| Când | totul funcționează | limită de cont, rate limit, LRC căzut |
| Push | identic | **identic** |
| Review | după push | **nu** |
| Mesaj de eroare pentru Popy | niciunul | **niciunul** |

**Un review lipsă nu e un push eșuat** și nu apare ca unul în panoul lui.

Măsurat pe un push real: contul a răspuns negativ, scriptul a intrat în
calea 2, pushul a rămas confirmat, **zero mesaje de eroare**.

---

## 2. Jules

### 2.1 Ce este

Auditor de cod asincron, secundar, de nivel înalt. Google AI Pro.
**100 de cereri pe zi, maxim 5 repo-uri.**

### 2.2 Rol

**Nu** verifică fiecare virgulă la fiecare push — pentru asta n-are rost și
arde cota. E apelat **la cerere sau pe sarcini dedicate**, când un modul
s-a stabilit și merită un audit de profunzime.

### 2.3 Ce știm, și cât de bine

| Element | Stare |
|---|---|
| Repo conectat | ✅ |
| Suggestions BETA | ✅ pornit |
| Network access | ✅ |
| Knowledge → Memories | **NECUNOSUT** — documente contradictorii |
| Environment → Setup script | **NECUNOSUT** — la fel |
| Environment variables | **NECUNOSUT** — la fel |
| Consum | 0/100 sesiuni |

**Nu se raportează verde până nu se măsură în panoul Jules.**

### 2.4 Ce a găsit deja, și e corect

Jules a raportat, corect: blocaje de I/O async în buclă, apeluri
secvențiale în `kit.js` și `email-sort.js`, lipsă de escaping în
`cv-mutator.js`, import nefolosit, și **zero teste automate**.

Concluzia lui Cloud, și e cea corectă: **nu e suficient să-l atașez —
trebuie făcut să prindă ce eu uit.**

### 2.5 Secrete

**Nu se pun secrete în Environment variables** din repo. Cheile stau în
managerul de secrete și nu ajung în istoric. `git log` e citibil de oricine
are acces.

---

## 3. Workflow-ul de verificare — cele 7 verificări

Moștenit din MAVIS-CLOUD, extins pentru OPTIMUS:

1. **niciun secret în commit**
2. JSON-uri valide
3. sintaxă JavaScript
4. sintaxă Python
5. build-ul proiectului reușește
6. regulile de business (ex: șabloanele nu conțin nume de firmă)
7. puntea e vie (mesajul pentru celălalt agent)

Toate în `on: schedule` + `on: workflow_dispatch`. **Niciuna pe push.**

### Regula de ieșire

Dacă un repo nu poate fi măsurat, titlul devine **„MĂSURĂTURĂ
INCOMPLETĂ"** și ieșirea e `2`.

Un senzor mort care raportează sănătate e mai prost decât un senzor care
lipsește.

---

## 4. Cota, și de ce nu e blocajul

Cota e **100 de taskuri pe zi**. Platforma arde cel mult `maxTasksPerDay`
(15 = 5 repo-uri × 3 axe). Restul rămâne rezervă pentru refactorizări mari,
unde sandbox-ul lui Jules chiar contează.

**Cota nu e blocajul curent. Blocajul e backlog-ul:** 99 de PR-uri
deschise, cu plafonul `maxOpenPrsPerRepo` = 3. Cota e aproape
nefolosită; PR-urile stau în așteptare.

**Taskurile sunt la nivel de sistem**, nu la nivel de virgulă: o țintă
măsurată, un test, un PR.

---

## 5. Secretul `JULES_API_KEY`

Nu poate fi citit de pe GitHub — e singurul pas pe care îl poate face doar
Popy:

```
gh secret set JULES_API_KEY -R apvizual-max/MAVIS-OPTIMUS-CD
```

**Măsurat 2026-10-24:** secretul e prezent doar în `MAVIS-CLOUD`. În
`MAVIS-OPTIMUS-CI`, `OPTIMUS-Backbone`, `pkms-vault-automation` și
`SENTINEL_PRIME` lipsește (`gh secret list` → gol).

Fără el, calea automată nu se declanșează în acel repo. **Calea web a lui
Jules rămâne deschisă** — de aceea apar PR-uri fără etichetă, workflow
sau secret.
