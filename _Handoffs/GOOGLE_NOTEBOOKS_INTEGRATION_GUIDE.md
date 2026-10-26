# GHID DE INTEGRARE GOOGLE NOTEBOOKS (FOST NOTEBOOKLM) — OPTIMUS CD

> **Data:** 2026-10-26  
> **Locație SOT:** `E:\Google\GDrive\GDrive-Second_Brain_PKMS\02_Areas\02-2-AI-SOT\CASA\OPTIMUS - Prime\Optimus_CD (by Jules)\_Handoffs\GOOGLE_NOTEBOOKS_INTEGRATION_GUIDE.md`  
> **Destinatari:** Mavis Local (MiniMax Code), Antigravity, Hermes Agent  
> **Doctrină:** Logic • Reason • Strategy  
> **Calibration Header:** `━━━ SENTINEL PRIME • DLG: 0% • SLG: 100% • SUBSTRAT: HERMES • Mod: B ━━━`  
> **Wakeup Anchor:** *Ține minte că uiți* (RE-A-MINTE-Ș-TI)  

---

## 1. Prezentare Generală & Rol în Ecosistem

Pe lângă depozitele locale de fișiere Markdown și API-urile CLI, ecosistemul **Optimus Continuous Development** integrează trei **Google Notebooks** (serviciul Google Notebooks / fost NotebookLM) sub contul `apvizual@gmail.com`.
Aceste notebook-uri funcționează ca baze de cunoștințe semantice RAG de nivel înalt, permițând sintetizarea rapidă a contextului, interogarea istoricului de dezvoltare și analiza deciziilor de arhitectură fără a consuma tokeni locali.

Atât **Antigravity**, cât și **Mavis** au acces și trebuie să interogheze/actualizeze aceste trei notebook-uri.

---

## 2. Cele Trei Google Notebooks Dedicate

```
┌────────────────────────────────────────────────────────────────────────┐
│             GOOGLE NOTEBOOKS (NOTEBOOKLM) CONTINUOUS DEVELOPMENT      │
└───────────────────┬─────────────────┬──────────────────┬───────────────┘
                    │                 │                  │
                    ▼                 ▼                  ▼
     ┌───────────────────────┐ ┌───────────────┐ ┌──────────────────────┐
     │ 1. NOTEBOOK JULES     │ │ 2. NOTEBOOK   │ │ 3. NOTEBOOK EMAIL    │
     │ - Task Proposals      │ │    GITHUB     │ │ - Notif Telemetry    │
     │ - Session Histories   │ │ - Fleet Repos │ │ - CD Digests         │
     │ - Prompt Cards        │ │ - PR Diffs    │ │ - Pattern Analysis   │
     │ - Cloud Architecture  │ │ - Changelogs  │ │ - Triage Metrics     │
     └───────────────────────┘ └───────────────┘ └──────────────────────┘
```

### Notebook 1: `Optimus CD — Jules Intelligence & Architectural Notes`
- **Scop:** Urmărirea continuă a propunerilor generate de Jules pe repozitoarele active, sesiunile de cloud sandbox, cardurile de prompt-uri eficiente și răspunsurile date la întrebările de feedback (`:interact`).
- **Surse Ingestate:**
  * `Antigravity_JULES_INT\docs\JULES_GITHUB_INTEGRATION_GUIDE.md`
  * `Antigravity_JULES_INT\history_archive\DECISIONS_AND_LESSONS_LEARNED.md`
  * Template-urile de feedback și jurnalele de depanare.
- **Utilizare Operațională:**
  * Când Jules propune o refactorizare majoră sau când intră în `AWAITING_USER_FEEDBACK`, interoghează notebook-ul pentru a obține precedentul arhitectural stabilit de Popy și Antigravity.

### Notebook 2: `Optimus CD — GitHub Fleet Architecture & PR History`
- **Scop:** Cartografierea completă a celor 10 repozitoare din contul `apvizual-max`, istoricul pull request-urilor squash-merge-uite, auditul changelog-urilor și politicile ramurii unice (`main`/`master`).
- **Surse Ingestate:**
  * `Antigravity_JULES_INT\docs\MASTER_ARCHITECTURE_BLUEPRINT.md`
  * `Antigravity_JULES_INT\reports\VERIFIED_IMPLEMENTATION_AND_TRIAGE_AUDIT.md`
  * Ledger-ele `JULES_HANDOFF.md` din fiecare depozit.
- **Utilizare Operațională:**
  * Când se execută Engineering Second-Eye Review, notebook-ul este consultat pentru a verifica dacă diff-ul propus nu anulează modificări aprobate anterior.

### Notebook 3: `Optimus CD — Email Telemetry & Communication Digests`
- **Scop:** Analiza fluxului masiv de emailuri de notificare venite de la Jules și GitHub, statistici privind frecvența commit-urilor, alerte de securitate și confirmări de rulare.
- **Surse Ingestate:**
  * Regulile filtrului Gmail `ANe1Bmh4apfrWZA0T6Dx1Ha8qm8sLNXnDWtPevfLsJ8QCQ`.
  * Jurnalele de triaj și rapoartele de Inbox Zero.
- **Utilizare Operațională:**
  * Verificarea corelației între acțiunile Jules/GitHub și alertele sosite pe email, asigurând că nicio eroare de pipeline nu a scăpat netratată.

---

## 3. Acces & Sincronizare pentru Mavis și Antigravity

1. **Protocol de Autentificare:**
   - Ambele notebook-uri sunt legate de contul principal `apvizual@gmail.com`.
   - Accesul se realizează fie prin uneltele MCP dedicate de NotebookLM (dacă serverul MCP local este activat), fie prin exportul periodic al contextelor în fișiere Markdown în folderul `docs/`.
2. **Adăugarea de Surse Noi:**
   - La fiecare ciclu major de Continuous Development (sau săptămânal), raportul forensiv `VERIFIED_IMPLEMENTATION_AND_TRIAGE_AUDIT.md` și noul `WALKTHROUGH` trebuie încărcate ca surse actualizate în cele 3 notebook-uri.
3. **Imunitate la Halucinații:**
   - NotebookLM oferă citări exacte pe baza surselor încărcate. Când Mavis preia rolul de backup, interogarea notebook-urilor îi oferă certitudinea că răspunde conform adevărului istoric al stației OPTIMUS PRIME.
