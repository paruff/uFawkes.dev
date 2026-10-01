# Intent: Suite status dashboard

**Owner:** @paruff | **Created:** 2026-10-01 | **Status:** Draft

## Problem

The suite release plan (`docs/ai-sdlc/suite-release/`) defines what
"released" means for each repo as acceptance criteria (ACs), and Project #7
tracks the issues. But nobody can see, at a glance:

- which ACs pass **today**, re-checked rather than remembered
- how far each release is from its gate: ACs passing, issues done, blockers
- which release is next, and how much work stands between now and it
- whether the pace is enough, or the next milestone keeps slipping

Today the answer takes an hour of `gh` queries and reading. Earlier on
2026-10-01, four uFawkesObs issues showed "In Progress" on the board while
already closed. The plan and the board drift, and nothing re-checks them.

## Desired outcome

One command, `make status`, run daily by CI and on demand locally:

1. Runs every automatable AC check in the suite release spec and records
   pass, fail or manual for each.
2. Reads Project #7 for issue progress per release, blockers, and the
   routing split (`goal`, Nemotron, Flash).
3. Publishes a visual `/status/` page on ufawkes.dev: where we are, how
   much is left, and which milestone is next.

## Users

- **@paruff**, deciding what to work on next and whether a release is ready.
- **Agents** (Claude Code, OpenCode), which read the same JSON instead of
  re-deriving status each session.
- **The public:** a live, honest progress view serves the credibility goal.
  A red check shown openly is more credible than a claim nobody can check.

## Constraints

- uFawkes.dev's stack: Jekyll, Liquid, vanilla CSS. No npm, no JS
  framework, no Jekyll plugins.
- No commits to `main` from automation. The site deploys through a Pages
  workflow, so generated data goes into the build, not into git.
- Never swallow a failure. A failing AC is data and shows red; a broken
  check script fails the workflow.

## Where it lives, and why not DevX first

The status of the **whole suite** is suite-level work, so it belongs in
uFawkes.dev, the suite tracking repo. uFawkesDevX (Backstage) is the right
long-term home for an internal developer view, but it isn't released until
Phase 5. Building the dashboard there would block it behind the work it's
meant to track.

So: **v1** is a static page on ufawkes.dev. **v2**, after uFawkesDevX
`v0.1.0`, has DevX and uFawkesObs consume the same published JSON (a
Backstage card, a Grafana panel). That dogfoods the suite on its own
delivery.

## Out of scope

- Per-repo CI health dashboards (each repo's Actions tab covers that).
- The suite's own DORA metrics (uFawkesObs territory; a v2 candidate).
- Editing issues or the board from the dashboard. It's read-only.
