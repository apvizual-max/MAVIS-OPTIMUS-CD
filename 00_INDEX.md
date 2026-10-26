# 00_INDEX — 02_Areas/02-2-AI-SOT/02-2-7-AI-Optimus_CD/Mavis-Optimus-Continuous-Development

**7 fișiere · 8 subfoldere**

> Index generat automat de `02_Areas/02-2-AI-SOT/02-2-4-AI-Kit/AI-Kit_manual/build-index.ps1` și `align-index.ps1`.
> **Actualizare manuală 2026-10-27:** generatorul (`build-index.ps1` / `align-index.ps1`) nu mai există pe disk
> la calea documentată, iar arborele s-a schimbat după ultima generare. Indexul a fost refăcut manual,
> cu cifre măsurate pe disk. La revenirea generatorului, următoarea rulare va suprascrie acest fișier.

## Ce e aici

Proiectul **Optimus CD (by Jules)** — sistemul de Continuous Development al stației OPTIMUS PRIME.
Rădăcina conține 7 fișiere de documentație și 8 subfoldere. Cel mai mare element este `JULES - Optimus CD`
(9401 fișiere, 82,2 MB), din care `work/` și `state/` sunt artefacte de lucru și nu intră în istoria git.

## Cuvinte cheie

`Optimus_CD` · `Jules` · `GitHub Fleet` · `Gmail` · `Continuous Development` · `Antigravity` · `Mavis`

## Subfoldere

_Fiecare raft e legat la indexul lui. Un index care nu e legat nu e în arbore._

| Raft | Conținut | Fișiere |
|---|---|---|
| [`Antigravity_JULES_INT`](<Antigravity_JULES_INT/README.md>) | Materialul operațional Antigravity: 40 scripturi CD, 4 skill-uri, rapoarte, transcripturi | 64 |
| [`JULES - Optimus CD`](<JULES - Optimus CD/00_INDEX.md>) | Platforma CD și registrul de lucru al lui Jules (config, docs, logs, scripts, workflows) | 9401 |
| [`_Handoffs`](<_Handoffs/00_INDEX_HANDOFFS.md>) | **Folderul unic de handoff** al ecosistemului CD — 9 documente canonice | 9 |
| [`_docs`](<_docs/00_INDEX.md>) | Documentația SOT originală (mutată din `docs/` la 2026-10-25) | 10 |
| [`docs`](<docs/NOTEBOOKS_INDEX.md>) | Indexul celor 3 Google Notebooks (fost NotebookLM) | 1 |
| [`state`](<state/00_INDEX.md>) | Artefacte de lucru — ignorate de git | 55 |
| [`_GitHub-Main_Repos-Local-Temp`](<_GitHub-Main_Repos-Local-Temp/00_INDEX.md>) | Clone locale de repo-uri — ignorate de git | 28887 |
| `MAVIS - Optimus CD` | Rezervat pentru spațiul de lucru Mavis — gol la 2026-10-27 | 0 |

## Fișiere

| Fișier | Dimensiune | Modificat |
|---|---|---|
| `.gitignore` | 515 B | 2026-10-24 |
| `DOCTRINA-CD.md` | 8 KB | 2026-10-24 |
| `HANDOFF-CD.md` | 12 KB | 2026-10-24 |
| `PRIMING-CD.md` | 10 KB | 2026-10-24 |
| `README.md` | 6 KB | 2026-10-24 |
| `README_SYSTEM_TOPOLOGY_AND_AGENT_GUIDELINES.md` | 14 KB | 2026-10-26 |

---

## Separarea fisierelor git de fisierele proiectului

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

Hook-urile sunt și ele în afara arborelui cloud: `core.hooksPath = C:/Users/apviz/.minimax-agent/projects/scripts/git-hooks`.
Poarta de push (`pre-push`) consumă un singur acord, marcat prin fisierul `PUSH-ACORD` din GIT_DIR.
