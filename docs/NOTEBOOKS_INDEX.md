# NOTEBOOKS INDEX — Google Notebooks (NotebookLM) for Optimus CD

> **Măsurat 2026-10-28** (nu documentat, citit de pe server): 36 notebook-uri pe contul
> `apvizual@gmail.com`. Cele care ne privesc, cu id-ul real și numărul real de surse.
> **Cont Google asignat:** `apvizual@gmail.com`
> **Platformă:** Google Notebooks (fost NotebookLM)
> **Destinatari:** Antigravity, Mavis Local (MiniMax Code), Hermes Agent
> **Acces:** `scripts/ask-jules-notebook.mjs` (client MCP stdio, în acest repo) → `--list`,
> `--ask "întrebarea" --notebook JULES`

---

## 1. Notebook-urile reale (măsurate)

| # | Nume Notebook | id | Surse | Actualizat | Rol |
|---|---|---|---|---|---|
| 1 | **`JULES`** | `f7ea4298-8604-4df3-ab3f-a6d634d4cbc6` | **182** | 12 Oct 2026 | Baza de cunoștințe despre Jules: integrarea cu GitHub, contractul cu Mavis Local, regulile fluxului, istoricul deciziilor. **Asta e „Jules Notebook" pe care îl folosește Mavis Local pentru planificare și verificare finală.** |
| 2 | `LIVEReview` | `85f0b620-ca40-4a84-9f0f-998a9fe1e049` | 2 | 12 Oct 2026 | Notări despre poarta de review LiveReview (commit-time) |
| 3 | `Gmail` | `fd9d444e-614f-4cd2-b6a2-58749a85678b` | 2 | 12 Oct 2026 | Notări despre interfața Gmail (eticheta `Label_35`, Inbox Zero) |

> **Corectură de adevăr (2026-10-28).** Versiunea anterioară a acestui index lista trei
> notebook-uri cu nume de tip „Optimus CD — …" care **nu există** pe cont. Un index care
> numește lucruri inexistente nu e documentație, e ficțiune utilă. Cele de mai sus sunt
> cele citite de pe server.

---

## 2. Cum se interoghează

```powershell
# lista notebook-urilor (read-only)
node scripts/ask-jules-notebook.mjs --list

# întrebare adresată notebook-ului JULES (deschide sesiunea Chrome, durează ~1-2 min)
node scripts/ask-jules-notebook.mjs --notebook JULES --ask "Ce reguli are fluxul Jules pe push?"
```

Ieșirea e **raw**, fără interpretare: dacă stramosul e gol, așa și se raportează.

## 3. Ce ține acest strat (și ce NU ține)

- **Ține:** baza de cunoștințe *cloud* a lui Jules — 182 de surse, menținută în afara
  acestui repo.
- **NU ține:** contextul pe care Jules îl primește la activare. Acela trăiește în
  repo, în `JULES-CONTEXT.md` și `AGENTS.md` — fiindcă Jules rulează într-o mașină
  cloud și **nu poate citi `E:\`**. Un document care nu e în repo nu ajunge la el.
  De aceea `config/jules-context.md` e sursa unică și se injectează în fiecare task.
- **Accesul la notebook este local, nu al lui Jules.** Contul de notebook e al
  mașinii; Jules cloud nu are sesiunea Google aici. Deci: Mavis Local consultă
  notebook-ul, Jules primește contextul prin repo.

## 4. Regula de actualizare

Când se schimbă ceva în notebook-uri, **remeasurează** cu `--list` și scrie cifrele
așa cum le dai. Nu completa cu nume din memorie.
