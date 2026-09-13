## What this repository is

Working directory for **eleyone.fr**, the professional portfolio site of Arnaud ("Eleyone"), a senior PHP/Symfony backend developer. The site is a portfolio and online CV for recruiters, for permanent roles as well as freelance missions, in France and abroad, before April 2027.

**There is no application code yet.** The repository holds a BMAD v6.12 skill installation and the project's configuration. The site is meant to be produced through the BMAD planning chain (brief → PRD → architecture → stories), not improvised. Planning artifacts will land in `_bmad-output/`; nothing has been planned or built yet.

Git repository. The remote is a self-hosted server (the self-hosted forge), meant to be mirrored to a **public GitHub repository** that the site links to as proof of how it was framed and built. Treat everything committed as public. `/home/eleyone/Workspace/eleyone` is a symlink to `/mnt/wsl/HDD_1/Workspace/eleyone`; both working directories are the same files.

## Public / private boundary

`docs/private/` is gitignored by this repository and never enters its history. It holds the raw source content, the party-mode memory, and `forbidden-patterns.txt`. A fresh clone does not contain it.

`docs/private/` is its own nested git repository, pushed to a separate private repo on the self-hosted forge that must never be mirrored. Commit private changes there explicitly (`git -C docs/private commit`), never through a hook. `git clean -ffdx` in this repository deletes the nested repo; a single `-f` spares it.

- Never commit anything from `docs/private/`, and never copy personal details from it into tracked files: pay or day-rate expectations, location and relocation constraints, interview self-assessment, names of relatives.
- `scripts/check-private.sh` enforces this. It rejects forbidden paths, plus the strings listed in `docs/private/forbidden-patterns.txt`. Enable the local hook once per clone with `git config core.hooksPath .githooks`. Audit the full history with `scripts/check-private.sh history`, and run it before any push to GitHub: a commit pushed there stays reachable by SHA even after a force push.
- The mirror pushes from the server, so the same script should run there as a `pre-receive` hook.
- Public planning artifacts cite the published site pages, not the raw cases.

## Source content and the rule that governs it

`docs/private/context/` holds the canonical content the site is built from. The `*:Zone.Identifier` files are Windows download artifacts and are ignored.

- `noyau-narratif-v1.md` — positioning, tone, what Arnaud sells (judgment, not execution), what he refuses (management, product owner), candidate titles and pitches. This is the source of voice.
- `contexte-candidat-condense.md` — condensed summary of the six client cases plus recurring traits.
- `cas-client-01` … `cas-client-06` — the full cases. Each follows the same section shape: contexte, le problème, la solution facile et pourquoi pas, ce que j'ai fait/décidé, ce qui a résisté, résultat, ce que ça montre de moi, then "Matériel vivant" (diagrams/videos/snippets still to produce) and "Les deux dialectes" (a CTO-facing and a business-owner-facing retelling). The raw cases are not published; only their reformulation on the site is.
- `prompt-init-site-bmad.md` — the original site brief. Several of its statements are superseded by the decisions below.
- `prompt-evaluation-offre-v2.md` — a standalone prompt for evaluating job offers. Unrelated to building the site, and strictly private.

**Never invent cases, figures, clients, or technologies that are not in these files.** Site content is a minimal reformulation of them. Bracketed placeholders in the cases stay unfilled — they are pending, not gaps to close.

## Decisions taken (2026-09-13)

These supersede the original brief. The validated project brief is in `_bmad-output/planning-artifacts/briefs/`; the PRD draft is in `_bmad-output/planning-artifacts/prds/`.

- **Purpose and brand:** eleyone.fr is Arnaud's portfolio and CV. "Ton Pote le Geek" already exists and is only mentioned or linked, not developed on this site.
- **Languages:** French and English, both complete. English is a full version aimed at international recruiters, not a subset.
- **Generator:** Hugo (native multilingual, single binary, no dependency tree). Build output is served by an nginx container on existing Docker infrastructure behind a reverse proxy.
- **URLs:** French at the domain root, English under `/en/`. No automatic redirect based on browser language.
- **Diagrams:** D2, one shared `structure.d2` per diagram plus `fr.d2`/`en.d2` label entry points, ELK layout, rendered with `--omit-version`. SVGs are committed and CI regenerates them and fails on any diff; the D2 version is pinned. See the `experiment/d2-bilingue` branch.
- **Chiliz cases (02, 03, 04):** one page, one "Contexte mission" box per section. Each case is its own file; the page assembles them (`group: chiliz`) and must render with only the published sections.
- **Videos:** plain links to unlisted YouTube videos. No iframe, no cookie banner.
- **No small-business offer page:** the presentation mentions the automation side activity with a link to Ton Pote le Geek; case 01 was done under it.
- **Quality targets:** zero JavaScript in v1 where possible, WCAG 2.2 AA, Core Web Vitals "good" thresholds on mobile, a per-page weight budget. Checked with scripts rather than Chrome/Node tooling.
- **Planned live material** is invisible in production and shown only in the draft build.
- **Release:** a base (home, about, contact, legal pages, featured cases 01, 02, 05) first, then the remaining cases one at a time.
- **CI and hosting:** the main forge is a private Gitea on a homelab (x86_64 Actions runners), separate from the production server that will serve the site. The homelab can go down at any time; it is never exposed publicly. Gitea runs checks, pull requests, image build and deployment. GitHub is the public mirror and runs **checks only**: no image build, no deployment. How to share the same check scripts between both CIs is an open architecture task. The public/private guard also belongs in a Gitea pre-receive hook.
- **Repository:** public on GitHub, including BMAD planning artifacts, because showing the framing process is part of the point. No private files, no raw cases.
- **Tooling:** the right tool for the job. Plain scripts rather than heavy tooling in CI or build images; no Symfony or React for a static site.

Pilot case: `content/cases/case-02-chiliz.{fr,en}.md` follows `docs/format-cas.md` and is the architecture's test fixture. The stack vocabulary lives in `data/stack.yaml`.

Unchanged constraints: static site, Markdown content editable without touching code, no database, no backend to maintain, sober and readable design, simplicity over everything. Out of scope for v1: blog, client area, contact form, advanced analytics.

## BMAD workflow

Skills are installed in `.claude/skills/`, with mirrored copies in `.agent/skills/` and `.agents/skills/` for other agent runtimes. Invoke them as slash commands (`/bmad-help` recommends the next one). The expected chain for this project: Analyst brief → PM PRD (v1 then v1.1) → Architect (repo layout, Docker nginx build pipeline, Markdown and D2 naming conventions) → small stories delivered one at a time.

Arnaud's stated preference: before each story, restate your understanding and ask questions. He would rather field one question too many than redo a page.

### Configuration

Config is a four-layer TOML merge. `_bmad/config.toml` and `_bmad/config.user.toml` are installer-managed and regenerated on every install — never edit them. Durable overrides go in `_bmad/custom/config.toml` (team) or `_bmad/custom/config.user.toml` (personal, gitignored); per-skill overrides go in `_bmad/custom/<skill-name>.toml`. The installer never touches those.

Key values: project `eleyone.fr`, user `Eleyone`, output folder `_bmad-output/`, planning artifacts in `_bmad-output/planning-artifacts/`, implementation artifacts in `_bmad-output/implementation-artifacts/`, project knowledge in `docs/`, skill level `intermediate`. `_bmad/custom/bmad-party-mode.toml` moves party-mode memory and keepsakes into `docs/private/party-mode/`.

**Language:** talk to Arnaud in French. Planning documents are written in French too (`document_output_language` is overridden to French in `_bmad/custom/config.toml`). Code is in English: identifiers, front matter keys, file and directory names. Site content exists in French and English.

**Case content format:** `docs/format-cas.md` is the contract every case file follows: one file per case per language, English front matter keys, fixed FR/EN headings, `[TODO: …]` markers for anything missing.

### Scripts

Python helpers run through `uv` (a `.venv` with Python 3.14 is present). Run each from the exact path written in the skill, never assume co-location.

```bash
uv run _bmad/scripts/resolve_config.py --project-root .          # merged config as JSON
uv run _bmad/scripts/resolve_customization.py --skill <skill-root> --project-root . --key workflow
uv run _bmad/scripts/memlog.py append --workspace <ws> --type decision --text "<one-line gist>"
scripts/check-private.sh history                                 # audit history for private content
```

`memlog.py` is the only sanctioned writer for `.memlog.md`, a workflow run's append-only memory and audit trail. Anything not logged there is lost when a session resumes.
