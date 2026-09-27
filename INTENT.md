# INTENT — Read This Before Touching Anything

**uFawkes.dev** is the public face and planning hub of the uFawkes suite. It
holds the marketing site at [ufawkes.dev](https://ufawkes.dev) (Jekyll,
deployed to GitHub Pages from `main`) and the suite-wide release plan.

## The one thing to know

Every claim this site makes has to be true of the repos it links to. The
uFawkesObs v1.0.0 announcement sends readers here and then to the stacks,
so a page that describes a feature a stack doesn't have hurts credibility
more than an empty page does. If a stack page and that stack's README
disagree, the README wins. Fix the page.

## What it holds

| Thing                                          | Where                                                                       |
| ---------------------------------------------- | --------------------------------------------------------------------------- |
| Stack pages, blog, learn guides                | The Jekyll site (`_posts/`, stack pages, `_data/navigation.yml`)            |
| Suite release plan: goals, decisions, sequence | [`docs/ai-sdlc/suite-release/`](docs/ai-sdlc/suite-release/)                |
| Live status across all repos                   | [uFawkes Suite Release Project](https://github.com/users/paruff/projects/7) |
| Research foundation                            | [`docs/research-foundation.md`](docs/research-foundation.md)                |
| What happened to the old roadmap's goals       | [`docs/roadmap.md`](docs/roadmap.md)                                        |

## What "done" means here

- **Planning follows uFawkesAI's chain:** `docs/ai-sdlc/<feature>/intent.md`
  → `spec.md` (requirements and design) → `plan.md` (sequence and
  verification).
- **Plan docs hold decisions, not status.** Status lives in issues and the
  Project; a task list in a doc drifts.
- **A page describes what a _released_ stack version actually does.**
  Update it through the uFawkesAI `release` agent on each release, not
  ahead of one.

## Explicit non-goals

- **Hosting any stack.** The stacks live in their own repos.
- **Its own roadmap separate from the suite plan.** There's one plan, in
  `docs/ai-sdlc/suite-release/`.
- **Planning `fawkes`.** It's the Kubernetes graduation track, with its own
  roadmap and milestones.
