# JULES_HANDOFF.md — MAVIS-OPTIMUS-CD

Jurnalul suveran al acestui repo. **Orice merge, închidere sau predare între agenți
se adaugă aici.** Cine vine după altcineva citește mai întâi acest fișier.

## Formatul unei intrări (obligatoriu)

- **Timestamp** (ISO 8601)
- **PR** — număr și titlu
- **Acțiune** — `Squash-merged` / `Closed superseded` / altceva, explicit
- **Sferă** — fișiere modificate sau domeniul schimbărilor
- **Următorul pas** — pentru agenții următori (Antigravity, Hermes, Qwen, Jules)

## Regiile care nu se negociază

- **O singură ramură activă pe remote** (`main`). Ramura de lucru a lui Jules e
  efemeră: se șterge imediat după squash-merge.
- **Local decide, Jules propune.** Jules deschide PR; Local verifică și decide.
- **Nimic nu se contopește fără intrare aici.**
- **Măsoară înainte să declari.** O intrare fără cifre măsurate e o amintire, nu
  un registru.
- **Jules ține cel mult 15 taskuri simultane.** Peste asta începe să dea erori
  și tace. Măsurat: contul avea **17 sesiuni deschise** înainte de corecție.
- **Jules se activează la cerere explicită, nu la fiecare push.** Cele trei
  căi sunt `workflow_dispatch`, un comentariu `@jules` și un issue cu eticheta
  `jules`. Triggerul pe `push` și cronul săptămânal au fost **scoase** pe
  2026-10-29 — nu se reiau fără cerere explicită a lui Popy.
- **Plafonul se pune în punctul unde se creează resursa**, adică în
  `.github/actions/jules` (singurul loc unde se creează o sesiune). Un plafon
  pus în trigger se ocolește.

## Jurnal

| Timestamp | PR | Acțiune | Sferă | Următorul pas |
|---|---|---|---|---|
| 2026-10-28T19:13:43Z | — | secret `JULES_API_KEY` pus pe repo | credential pentru activarea automată | fără secret, calea automată nu se poate declanșa |
| 2026-10-28T19:20:37Z | — | run `Invoke Jules` pe push, `success` | workflow nou: push + `@jules` + etichetă | sesiunea `sessions/1125356074750950447` IN_PROGRESS; PR așteptat |
| 2026-10-28T19:26:44Z | — | mecanismul generalinstalat pe flotă (11 repo-uri) | eticheta `jules`, workflow, secret, permisiuni Actions=write | MAVIS-CLOUD exclus (lucra lui Jules e în curs); se face după ce termină |
| 2026-10-28T19:29:20Z | — | `workflow_dispatch` pe MAVIS-OPTIMUS-CI, `success` | dovadă că mecanismul e general, nu doar pe CD | sesiunea `sessions/14442616009068725339` IN_PROGRESS |
| 2026-10-28T23:40:12Z | — | `db0680a` push prin poartă cu R0 | **corectarea cerută de Popy**: triggerul pe `push` și cronul săptămânal scoase; plafonul de 15 taskuri deschise implementat în `.github/actions/jules`, plus `jules-lib.ps1`, `jules-dispatch.ps1` și daemonul | Jules se activează DOAR la cerere: `workflow_dispatch`, `@jules`, eticheta `jules` |
| 2026-10-28T23:48:30Z | — | mecanismul redepus pe flotă: 10 repo-uri × **1 commit** | installerul scrie ambele fișiere într-un singur commit (Git Data API) și nu scrie nimic dacă octeții sunt identici | măsurat: **0 runuri Jules pornite** de acest deploy (înainte: 18 runuri în 52 s → 13 sesiuni) |
| 2026-10-28T23:50:18Z | — | run de aliniere pe Optimus_CD, `workflow_dispatch` | piciorul Jules: buget măsurat **6/15**, sesiune `sessions/5402382992082227353` creată (HTTP 200) | verdictul vine din sesiune; ceilalți doi picioi se măsoară cu `scripts/alignment-run.ps1` |
| 2026-10-28T23:52:10Z | — | stratul `google-layer` local refăcut 16/16 (94.186 octeți) | fusese golit; sura canonică (repo `Mavis-Google_Access`) era intactă | notebook-ul și piciorul Gmail au fost **dezarmate** până la refacere |
| 2026-10-28T23:55:40Z | — | `ca404c5` push prin poartă cu R0 | `scripts/restore-google-layer.ps1` — refacerea stratului, cu verificare pe disc (număr de fișiere + total de octeți) | dacă stratul dispare din nou: `powershell -NoProfile -File scripts\restore-google-layer.ps1 -Apply` |
| 2026-10-29T00:10:22Z | — | `2ff81bb` push prin poartă cu R0 | `scripts/alignment-run.ps1` + `alignment-gmail.js` + `alignment-prompt.txt` — procedura de aliniere devine instrument de repo, nu scripturi temporare | următoarea aliniere: `powershell -NoProfile -File scripts\alignment-run.ps1 -Apply`; **`skills/antigravity-gmail-optimus-cd/SKILL.md` conține același literal de e-mail și ar pica la propria poartă la următoarea editare — lărgirea domeniilor permise îi aparține lui Popy** |
