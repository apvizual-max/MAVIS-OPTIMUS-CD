# AGENTS.md — Optimus CD (by Jules)

Acest fișier e pentru **orice agent** care lucrează în repo, inclusiv Jules
(care primește contextul complet prin `JULES-CONTEXT.md`). Nu e o documentație
de proiect — e **contractul de lucru**.

## 1. Cine decidește

- **Mavis Local** e autoritatea supremă. Citește propunerea, o verifică
  fizic, și decide ce se contopește în `main`.
- **Tu propui. Local decide.** Deschizi pull request. **Nu împingi niciodată
  direct pe `main`.**

## 2. Surse canonice (citește-le înainte de orice lucru)

| Fișier | Ce aduce |
|---|---|
| [`JULES-CONTEXT.md`](JULES-CONTEXT.md) | regulile, invariantele, formatul obligatoriu de raport |
| [`PRIMING-CD.md`](PRIMING-CD.md) | pasul de pornire, poarta de push, cum se verifică |
| [`00_INDEX.md`](00_INDEX.md) | topologia arborelui, unde stă GIT_DIR, cum se rulează poarta |
| [`docs/`](docs) | documentația de proiect și rapoartele zilnice |
| [`config/jules-context.md`](config/jules-context.md) | **sursa unică** a contextului injectat în issue-uri |

`JULES-CONTEXT.md` e generat din `config/jules-context.md` de
`scripts/jules-install.ps1`. **Nu edita `JULES-CONTEXT.md` direct** — editează
sursa și regenerează.

## 3. Regulile care nu se negociază (rezumat; canonul e în `JULES-CONTEXT.md`)

1. **Nu inventa.** Dacă nu e în repo, în issue sau în cod, spune că nu e.
2. **Nu șterge definitiv.** Trash da, `delete` nu. Arhivează prin `git mv` în
   `docs/arhiva/`.
3. **Nu împinge pe `main`.** Pull request, întotdeauna.
4. **Nu ceri parole, tokenuri sau coduri MFA.** Dacă un pas cere un secret,
   scrie în raport ce secret lipsește și te oprești acolo.
5. **Nu publici și nu deployezi**, fără cerere explicită în issue.
6. **Nu trimite nimic în numele lui Popy** — nici email, nici mesaj, nici
   comentari care să pară venit de la el.
7. **Nu schimbi ramura implicită.** Lucrezi pe ramura cerută.
8. **Măsoară înainte să declari.** „E gata" înseamnă „Popy poate să vadă".

## 4. Invariantele tehnice ale acestui repo

- **Scripturile `.ps1` sunt ASCII pur, fără BOM.** Parserul Windows
  PowerShell 5.1 citește greșit un fișier cu byte-uri peste 0x7F și fără BOM:
  arată bine în editor și pica în execuție.
- **Un script nu amestecă `Write-Output` cu codul de ieșire.** `$c = Main`
  capturează și liniile tipărite; `exit $c` iese cu 0 chiar când `Main` a
  întors 3. Un control care nu poate pica nu e control.
- **Poarta rulează înainte de orice altceva:**
  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts/jules-selfcheck.ps1
  ```
  Acceptare: `FILES=<n> PROBLEMS=0` și `EXIT=0`. `UNKNOWN>0` se raportează,
  nu se presupune. Dacă `PROBLEMS>0`, platforma e coruptă și nu ai ce măsura.
- **Secretele nu intră în istoric.** Scanul pre-push e obligatoriu; în istoricul
  public al acestui repo au fost deja 0 blob-uri cu tipar de cheie.
- **Git merge-uri oarbe nu.** O revizie de tip *second-eye* înainte de merge.

## 5. Cum verifici

Rulează comenzile de verificare în ordine și raportează ieșirea **exact**,
inclusiv codul de ieșire. Dacă o verificare pică, **nu continua**: livrează ce
ai și spune care verificare a picat și de ce. Un PR care pică e util. Un PR
care minte e vătămător.

## 6. Formatul raportului (obligatoriu)

```markdown
## Ce am schimbat
- <fișier> — <o linie>

## De ce
<motivul, cu referire la taskul inițial>

## Cum am verificat
<comanda> → <ieșirea reală, cu cifre>

## Ce NU am făcut și de ce
<limite atinse, lucruri lăsate neterminate>

## Riscuri
<ce ar putea să se rupă>
```

## 7. Dacă nu ai destul context

Nu bloca. Fă lucrul care **nu depinde** de contextul lipsă, notează în raport
ce ai presupus și ce ai verificat, și lasă restul pentru o sarcină următoare.
Un PR parțial, corect și marcat, bate un PR complet inventat.
