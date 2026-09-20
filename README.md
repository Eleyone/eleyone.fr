# eleyone.fr

This is the repository of my portfolio site. It is also the case study of its own construction, written the way the site writes its client cases — because you are more likely here to judge how I work than to read my CV.

I am Arnaud Grousset, "Eleyone", a senior backend developer (PHP, Symfony), based in France.

## Context

I needed a portfolio for a job search that runs until April 2027, permanent or freelance, in France and abroad. Two kinds of readers: a recruiter who skims for thirty seconds, and a tech lead who wants to know whether the claims hold. The site is bilingual — French at the root, English under `/en/` — because part of the audience is not French.

Its content is six client cases, reformulated. The raw material behind them is confidential, and none of it is published.

## The problem

Every portfolio claims judgment. Claims are cheap, and a tech lead knows it. What I sell is not the ability to execute a ticket — it is deciding what to build, what to refuse, and what will cost more than it returns. That cannot be asserted in a bullet list; it has to be shown on something the reader can inspect.

So the site had to be an instance of the thing it claims. It also had to survive me: one maintainer, content editable without touching code, nothing to keep alive at three in the morning.

## The easy solution, and why I dropped it

There were four obvious routes, and I took none of them.

**A ready-made portfolio theme, filled in.** The fastest by a wide margin. But then the only skill on display is my ability to fill in a form, and the technical choices — the ones I am asking to be hired for — belong to someone else.

**A LinkedIn profile and a PDF.** Free, and already where recruiters look. But nothing there can be inspected. A tech lead cannot read *how* I work from a list of achievements; they can only decide whether to believe it.

**A React or Next application.** The 2026 default. A build toolchain, a dependency tree to keep patched, and a client-side runtime — to render text that is identical for every visitor and changes a few times a year.

**My own stack: PHP and Symfony.** This is the one worth explaining, because it is the one I would have enjoyed most. I am at ease in Symfony; I would have shipped quickly and well. Symfony brings a database, an ORM, a security layer, a service container, migrations. This site has no database, no accounts, no business logic, no personalisation — it serves pages that are the same for everyone. Choosing it here would have been choosing my own comfort and calling it engineering, then maintaining a runtime and a dependency tree for years to serve static HTML.

That last one is the whole point. The judgment worth paying for is the judgment that goes against your own habits, and the site had to demonstrate it on itself before claiming it about anything else.

## What I decided

- **A static site generator, Hugo**, a single binary with no dependency tree. Version, archive and SHA-256 are declared in exactly one file, [`tools.env`](tools.env); my machine, both CIs and the image all read it. Nothing pins a version anywhere else.
- **Content is data.** Markdown files and data files carry the content; templates only assemble it. Changing a case never means touching code. The contract every case file follows is [`docs/format-cas.md`](docs/format-cas.md).
- **Both languages are complete.** English is a full version, not a subset, and a script refuses any file that exists in one language and not the other.
- **No JavaScript, no third-party resource, no web font.** Targets: WCAG 2.2 AA, "good" Core Web Vitals on mobile, and a per-page budget — 50 kB of HTML, 200 kB for the whole page, at most ten loaded resources and eight hundred elements. All enforced by scripts rather than by a browser toolchain.
- **Diagrams as source.** D2 files, one shared structure per diagram with per-language labels, SVGs committed and regenerated in CI, which fails on any difference.
- **Checks are shell scripts, not a toolchain**, and they run identically everywhere: the same [`scripts/ci/checks-job.sh`](scripts/ci/checks-job.sh) runs on my machine, on the private forge and on this mirror, inside one container image pinned by digest. A check that only runs in CI is a check you discover the day it breaks.
- **The framing is public.** Brief, PRD, architecture and stories live in this repository, and they were written before the code. If you want to know why something is the way it is, the decision is written down, dated, with the alternative it displaced.
- **Every pull request is reviewed by an LLM from a different vendor than the one that wrote the code**, in a temporary export of the reviewed commit — no `.git`, no environment file, no private directory. The reviewer cannot reach what it must not read.

## What pushed back

**Private sources had already reached the git history.** Early on, the raw client material lived in the working tree, and it entered the history before any guard existed. I found it before this repository was published on GitHub, rewrote the history, and then wrote the guard I should have written first. It has three layers: a local pre-commit hook, a `pre-receive` hook on the forge — the authority, because the mirror pushes from the server — and a full-history audit in CI. It refuses forbidden paths and a list of forbidden strings that is never committed anywhere, and it reports a location, never the matched content.

The lesson cost more than the fix: **a control that only lives in CI arrives after publication.** The mirror pushes at every push, and a commit stays reachable by its SHA even after a force push. So anything that must never slip through lives in the server hook, not in a workflow. The private directory is named here — `docs/private/` — because naming it is not a leak; it is a separate, separately-hosted repository that never enters this history.

**Failing loudly in shell is harder than it looks.** One rule — no error passes in silence — took four review rounds on a single script, because `grep` returning 1 means "nothing found" and 2 means "broken", because `|| true` swallows both, and because `exit` inside a pipeline or a process substitution leaves only its own subshell. The checks now share three wrappers that tell "nothing found" apart from "could not read", and the trap is written down in [`docs/procedures/shell-scripts.md`](docs/procedures/shell-scripts.md) with every form it took.

**The environment lies until you run in it.** The first real execution of the shared checks job inside the pinned image found two divergences my machine could never have shown: BusyBox `find` has no `-printf`, which the test runner uses, and `xmllint` returns a different exit code for "no node matched" depending on the libxml2 version. Then the CI, which runs as root, failed three test cases that made a file unreadable with `chmod 000` — root reads it anyway. Those cases now say so and count themselves as skipped, out loud, rather than quietly passing.

## Outcome

The site is **not online yet**: the first release ships the base — home page as CV, about, contact, legal pages and the first cases — and the remaining cases follow one at a time. What exists today is the machinery, and it is what this repository is worth looking at for:

- both CIs run the same checks job, in the same pinned image, as the same script I run locally;
- the checks that exist so far live in [`scripts/checks/`](scripts/checks/) — FR/EN parity, content and front-matter rules, HTML and accessibility, internal links and orphan pages, weight and element budget;
- the public/private guard runs at three layers and has refused what it was written for;
- every story since the first has a written record: its spec review, the decisions taken, the findings refused and why.

Measured page weight and Core Web Vitals will be published in [`docs/measures/`](docs/measures/) after the first deployment.

## Where to look

| What | Where |
| --- | --- |
| The checks, one entry point | [`scripts/check.sh`](scripts/check.sh) |
| The checks themselves | [`scripts/checks/`](scripts/checks/) |
| The full list of checks, including those not written yet | [architecture, "Liste des contrôles"](_bmad-output/planning-artifacts/architecture/architecture-eleyone.fr-2026-09-13/ARCHITECTURE-SPINE.md) |
| The shared job that runs them in the pinned image | [`scripts/ci/checks-job.sh`](scripts/ci/checks-job.sh) |
| Workflows | [`.github/workflows/checks.yaml`](.github/workflows/checks.yaml) (public mirror, checks only), [`.gitea/workflows/checks.yaml`](.gitea/workflows/checks.yaml) (main forge) |
| Public runs | [Actions](https://github.com/Eleyone/eleyone.fr/actions) |
| Architecture | [ARCHITECTURE-SPINE.md](_bmad-output/planning-artifacts/architecture/architecture-eleyone.fr-2026-09-13/ARCHITECTURE-SPINE.md) |
| Framing artefacts | [brief](_bmad-output/planning-artifacts/briefs/brief-eleyone.fr-2026-09-13/brief.md), [PRD](_bmad-output/planning-artifacts/prds/prd-eleyone.fr-2026-09-13/prd.md), [backlog](_bmad-output/planning-artifacts/epics.md), [stories and their reviews](_bmad-output/implementation-artifacts/) |
| The contract every case file follows | [`docs/format-cas.md`](docs/format-cas.md) |
| How the scripts are written and tested | [`docs/procedures/`](docs/procedures/) |
| Measures, after the first deployment | [`docs/measures/`](docs/measures/) |
| Rules the agents work under | [`AGENTS.md`](AGENTS.md) |
| Bilingual diagrams, spike | [`experiment/d2-bilingue`](https://github.com/Eleyone/eleyone.fr/tree/experiment/d2-bilingue) |
| Design explorations | [`design/dossier-architecture`](https://github.com/Eleyone/eleyone.fr/tree/design/dossier-architecture), [`design/suisse`](https://github.com/Eleyone/eleyone.fr/tree/design/suisse) |

The planning documents are in French; the site exists in French and English; identifiers, file names and front-matter keys are in English.

## How this repository is worked

Linear history, no merge commits.

- Work happens on a branch cut from `dev`, named `feat/*`, `fix/*`, `chore/*` or `docs/*`, and comes back into `dev` as a **squash**.
- A release brings `dev` into `main` by **fast-forward**, never a merge commit, and is tagged `vX.Y.Z` on `main`.
- A production fix branches from `main` as `hotfix/*`, returns to `main` fast-forward, and `dev` is then rebased onto `main` — never cherry-picked, because a copied commit breaks the next fast-forward.
- Nothing merges without: a non-blocking cross-vendor review report on the head commit, the public/private guard passing on the whole history, green CI, and a sprint status consistent with the story.

`main` is the default branch here and is never rewritten. This repository is a **mirror**: the main forge is private, and only the mirror identity can write here. The tooling named above for releases and hotfixes is built in a later epic; what is written here is the rule it will follow.
