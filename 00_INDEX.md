# 00_INDEX — 02_Areas/02-2-AI-SOT/CASA/OPTIMUS - Prime/Optimus_CD (by Jules)

> Index generat automat de `02_Areas/02-2-AI-SOT/02-2-4-AI-Kit/AI-Kit_manual/build-index.ps1` și `align-index.ps1`.
> **Actualizare manuală 2026-10-27:** generatorul (`build-index.ps1` / `align-index.ps1`) nu mai există pe disk
> la calea documentată, iar arborele s-a schimbat după ultima generare. Indexul a fost refăcut manual,
> cu cifre măsurate pe disk. La revenirea generatorului, următoarea rulare va suprascrie acest fișier.

**11 fișiere · 61 KB · 14 subfoldere**

> Generat automat de `02_Areas/02-2-AI-SOT/02-2-1-AI-Kit/AI-Kit_manual/build-index.ps1` și `align-index.ps1`. Nu edita manual — rulează scriptul din nou.
> Randul **De ce e aici** de mai sus, daca exista, se pastreaza la fiecare regenerare.

## Ce e aici

Cele mai frecvente două extensii sunt `.md` (8 din 11 fișiere) și `.git` (1 din 11 fișiere). 14 rafturi copil (primele trei după nume: `_Handoffs`, `config`, `docs`); cel mai mare element din folder e `transcripts` (2 MB)

## Cuvinte cheie

`Optimus_CD (by Jules)` · `transcripts` · `.md` · `.git` · `logs`

## Subfoldere

_Fiecare raft e legat la indexul lui. Un index care nu e legat nu e în arbore._

- [`_Handoffs`](<_Handoffs/00_INDEX.md>) — 11 fișiere · 0 subfoldere
- [`config`](<config/00_INDEX.md>) — 3 fișiere · 0 subfoldere
- [`docs`](<docs/00_INDEX.md>) — 16 fișiere · 3 subfoldere
- [`history_archive`](<history_archive/00_INDEX.md>) — 1 fișiere · 0 subfoldere
- [`logs`](<logs/00_INDEX.md>) — 10 fișiere · 0 subfoldere
- [`plugins`](<plugins/00_INDEX.md>) — 0 fișiere · 1 subfoldere
- [`reports`](<reports/00_INDEX.md>) — 3 fișiere · 0 subfoldere
- [`scripts`](<scripts/00_INDEX.md>) — 52 fișiere · 0 subfoldere
- [`skills`](<skills/00_INDEX.md>) — 0 fișiere · 4 subfoldere
- [`state`](<state/00_INDEX.md>) — 1 fișiere · 0 subfoldere
- [`templates`](<templates/00_INDEX.md>) — 1 fișiere · 0 subfoldere
- [`transcripts`](<transcripts/00_INDEX.md>) — 2 fișiere · 1 subfoldere
- [`work`](<work/00_INDEX.md>) — 0 fișiere · 0 subfoldere
- [`workflows`](<workflows/00_INDEX.md>) — 2 fișiere · 0 subfoldere

## Fișiere

| Fișier | Dimensiune | Modificat |
|---|---|---|
| `.git` | 37 B | 2026-10-26 |
| `.gitignore` | 515 B | 2026-10-24 |
| `desktop.ini` | 33 B | 2026-10-27 |
| `DOCTRINA-CD.md` | 8 KB | 2026-10-24 |
| `DOCTRINA-JULES.md` | 5 KB | 2026-10-24 |
| `HANDOFF-CD.md` | 12 KB | 2026-10-24 |
| `PRIMING-CD.md` | 10 KB | 2026-10-24 |
| `README (2).md` | 7 KB | 2026-10-24 |
| `README (3).md` | 6 KB | 2026-10-26 |
| `README.md` | 12 KB | 2026-10-27 |
| `README_SYSTEM_TOPOLOGY_AND_AGENT_GUIDELINES.md` | 0 B | 2026-10-27 |

Proiectul **Optimus CD (by Jules)** — sistemul de Continuous Development al stației OPTIMUS PRIME.

Rădăcina conține 7 fișiere de documentație și 8 subfoldere. Cel mai mare element este `JULES - Optimus CD`

(9401 fișiere, 82,2 MB), din care `work/` și `state/` sunt artefacte de lucru și nu intră în istoria git.

---

Aceasta este o invariantă de pe această mașină, nu o convenție de naming.

- **Worktree (fișierele proiectului):** `E:\Google\GDrive\GDrive-Second_Brain_PKMS\02_Areas\02-2-AI-SOT\CASA\OPTIMUS - Prime\Optimus_CD (by Jules)`

  — în interiorul arborelui sincronizat de Google Drive, deci fiecare scriere ajunge în cloud.

- **GIT_DIR (toate obiectele, refs, hooks, index):** `E:\Google\GitData-Optimus-CD`

  — în afara arborelui cloud, pe aceeași partiție fizică `E:`.

- **Puntea dintre ele:** fișierul `.git` din rădăcina proiectului, 37 de octeți, conține o singură linie:

  `gitdir: E:/Google/GitData-Optimus-CD`

Motivul: git scrie continuu în `objects/`, `index` și `refs/`. Dacă GIT_DIR ar fi în arborele Google Drive,

fiecare operație git ar produce fișiere de lock și re-scrieri pe o cale care se sincronizează cu norul —

surse clasice de corupție de index și de "dirty" permanent.

Consecință practică: **toate operațiile git se rulează din rădăcina proiectului** și folosesc automat

GIT_DIR-ul separat. `git rev-parse --git-dir` întoarce `E:/Google/GitData-Optimus-CD`.

Hook-ul de push trăiește în arborele versionat: `core.hooksPath = scripts/git-hooks` (relativ, rezolvat la rădăcina arborelui), adică `scripts/git-hooks/pre-push`. Fiind urmărit de git, un `git clean` nu-l poate șterge și poate fi restaurat din istoric.

Măsurat 2026-10-28: când hook-ul era o copie într-un director din afara arborelui, a dispărut de pe disk, poarta a murit în tăcime (git sare hook-urile inexistente) și două push-uri au trecut fără niciun consum de acord. Azi poarta are și un control care o verifică: `jules-selfcheck.ps1` → `poarta-push` (fișierul există) și `proba-poarta` (hook-ul real refuză fără acord, permite cu acord și consumă martorul).

Poarta de push (`pre-push`) consumă un singur acord, marcat prin fisierul `PUSH-ACORD` din GIT_DIR.

