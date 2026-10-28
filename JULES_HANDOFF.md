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

## Jurnal

| Timestamp | PR | Acțiune | Sferă | Următorul pas |
|---|---|---|---|---|
| 2026-10-28T19:13:43Z | — | secret `JULES_API_KEY` pus pe repo | credential pentru activarea automată | fără secret, calea automată nu se poate declanșa |
| 2026-10-28T19:20:37Z | — | run `Invoke Jules` pe push, `success` | workflow nou: push + `@jules` + etichetă | sesiunea `sessions/1125356074750950447` IN_PROGRESS; PR așteptat |
| 2026-10-28T19:26:44Z | — | mecanismul generalinstalat pe flotă (11 repo-uri) | eticheta `jules`, workflow, secret, permisiuni Actions=write | MAVIS-CLOUD exclus (lucra lui Jules e în curs); se face după ce termină |
| 2026-10-28T19:29:20Z | — | `workflow_dispatch` pe MAVIS-OPTIMUS-CI, `success` | dovadă că mecanismul e general, nu doar pe CD | sesiunea `sessions/14442616009068725339` IN_PROGRESS |
