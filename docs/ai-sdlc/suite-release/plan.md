# Plan: uFawkes Suite Release

**Traces to:** [`spec.md`](spec.md) → [`intent.md`](intent.md) |
**Status:** Draft | **Revision:** 1

The plan is gate-driven, not date-driven: each phase starts when the
previous phase's gate passes. Phases 0 and 1 can overlap. Releases within a
phase follow uFawkesAI's weekly cadence. If an increment is shippable on
Thursday, ship it.

## Where this plan lives, and how it syncs with GitHub

Each place is the source of truth for one kind of information:

| What                                                                  | Where                                                           | Why there                                                                                    |
| --------------------------------------------------------------------- | --------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Goals, decisions, release bars, sequence                              | This folder (`uFawkes.dev/docs/ai-sdlc/suite-release/`)         | ufawkes.dev is already the suite's public hub, and this replaces the stale `docs/roadmap.md` |
| Live task status across repos                                         | One user-level GitHub Project: **"uFawkes Suite Release"**      | Projects can span repos; milestones can't                                                    |
| Per-release scope within a repo                                       | A milestone per release in each repo (e.g. uFawkesObs `v1.0.0`) | Keeps issues where the code changes; the Project aggregates the milestones                   |
| Suite-wide issues (the compatibility matrix, the roadmap replacement) | Issues in uFawkes.dev                                           | Work that belongs to no single stack                                                         |

**Rules that keep the plan and the Project in sync:**

- **This doc never lists individual tasks** beyond the phase checklists
  below. It links to Project views instead. Two task lists drift, so one of
  them has to not exist.
- **Project fields:**
  - `Release` (single-select): Obs 1.0, Pipe stable, DevX 0.1, Dojo compose, Suite hygiene
  - `Phase` (0–4)
  - `Status`
- **Project views:** by Release, by Repo, and "Blockers"
  (`label:release-blocker`).
- **Standardize the `release-blocker` label across all six repos.**
  uFawkesObs already uses it.
- **Add items** by milestone with `gh project item-add`, or with the
  Project's built-in auto-add workflow if you use it. An agent can do this
  as part of opening each issue.
- **Post-release:** uFawkesAI's release agent already files a
  `measure: track DORA metrics for vX` issue. Add it to the Project so
  outcomes stay visible after the release ships.
- **fawkes's existing 16 milestones stay untouched.** Only its ADR-004
  follow-up joins the Project.

## Phase 0 — Suite hygiene (gate: AC-SUITE-01)

Small, parallel work. Most items are one PR each.

- [ ] Create the GitHub Project, the fields above, and `v1.0.0`-style
      milestones in uFawkesObs, uFawkesPipe and uFawkesDevX
- [ ] Standardize the `release-blocker` label across the repos
- [ ] uFawkes.dev: replace `docs/roadmap.md` with a pointer to this folder;
      add `INTENT.md`
- [ ] fawkes: add an ADR that supersedes `ADR-004 jenkins 4 ci` (Tekton)
- [ ] uFawkesDevX: remove uFawkesRes references from `README.md` and
      `ARCHITECTURE.md` (this pairs with AC-DEVX-01, but the doc fix ships
      now)
- [ ] uFawkesDojo: rename `intent.md` → `INTENT.md`; retitle the
      `0.1.0-alpha.1` release; move the integration spec into
      `docs/ai-sdlc/compose-curriculum/`
- [ ] uFawkesPipe, uFawkesDevX: add repo-level `INTENT.md` (uFawkesObs's is
      the model)
- [ ] uFawkesAI: align the `plan` skill's expected filenames with the
      agents (`spec.md`/`plan.md`)

## Phase 1 — uFawkesObs v1.0.0 + announcement (gate: AC-OBS-01..04, AC-SITE-01)

This is the critical path. It's the first stable release and the first
public announcement, so everything the announcement links to has to hold up.

1. Write `uFawkesObs/docs/ai-sdlc/v1.0.0/{intent,spec,plan}.md`. The spec
   states the decided contract: service names, ports and `.env` variables
   are covered; UIDs and metric names are not.
2. Triage the six candidate blockers in AC-OBS-02 into the `v1.0.0`
   milestone. Blocker vs. post-1.0 is your call. #381 is already labeled.
3. Fix the blockers. Cut `v1.0.0-rc.1` through the existing release-please
   flow.
4. Run the clean-host install test on Linux and macOS (AC-OBS-01) against
   the rc. Paste the real transcripts.
5. Build the compatibility-matrix page on ufawkes.dev (AC-SITE-01). At 1.0
   it may list only uFawkesObs, marked "standalone".
6. Merge the release-please PR for `v1.0.0`, then run uFawkesAI's `release`
   agent. It produces the GitHub Release, the ufawkes.dev page update, a
   dev.to draft and a LinkedIn draft (AC-OBS-04). You review and publish
   the posts.
7. The release agent files the `measure:` issue. Set it to track GitHub
   stars/forks, and issues or PRs from anyone other than @paruff.

## Phase 2 — uFawkesPipe first stable (gate: AC-PIPE-01)

1. Consolidate the duplicate spec/design/plan files into
   `docs/ai-sdlc/v2.0.0/`. `v2.0.0` is the first stable release, per
   `intent.md`.
2. Make `build-image` real, or drop it from the README's claims.
3. Do a real pipeline run on a sample app. Release, then announce with
   the same release-agent flow.
4. Update the compatibility matrix: which Obs version Pipe's `notify-obs`
   step was verified against.

## Phase 3 — uFawkesDevX v0.1.0 (gate: AC-DEVX-01)

1. Decide and record (as an ADR) the Postgres source that replaces
   uFawkesRes.
2. Move the root spec/design/plan into `docs/ai-sdlc/v0.1.0/`.
3. Run a clean-host test, then cut the first release through its existing
   `release-please.yml`. Ship it as a beta, not a stable 1.0.

## Phase 4 — uFawkesDojo curriculum follows releases

Each Dojo lab targets a _released, pinned_ stack version, never `main`.
Labs follow release order (decided 2026-09-27):

1. **uFawkesObs lab**, right after Obs 1.0. It gives new adopters a guided
   path, and it's a second announcement.
2. **uFawkesPipe → Yellow Belt**, after Pipe v2.0.0.
3. **uFawkesDevX → White Belt**, after DevX v0.1.0.

The Dojo's own `compose-curriculum` spec proposed belt order (White Belt
first). Update it to match this order when it moves into
`docs/ai-sdlc/compose-curriculum/` (Phase 0).

## Verification Strategy

| Criterion   | Evidence                                             | Collected in            |
| ----------- | ---------------------------------------------------- | ----------------------- |
| AC-SUITE-01 | grep across public docs shows no contradicted claims | Phase 0 PRs             |
| AC-OBS-01   | Real clean-host transcripts (Linux + macOS)          | Release notes           |
| AC-OBS-02   | `v1.0.0` milestone: 0 open `release-blocker`         | Project "Blockers" view |
| AC-OBS-03   | `docs/ai-sdlc/v1.0.0/spec.md` in uFawkesObs          | Release notes link      |
| AC-OBS-04   | Four live URLs, same version                         | Obs 1.0 Project item    |
| AC-PIPE-01  | Real pipeline run output                             | Release notes           |
| AC-DEVX-01  | Clean-host transcript without uFawkesRes             | Release notes           |
| AC-SITE-01  | Matrix page live                                     | ufawkes.dev             |

## Risks

| Risk                                                                        | Mitigation                                                                                                              |
| --------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| The announcement links readers to docs that still contradict each other     | Phase 0 gates the announcement (AC-SUITE-01)                                                                            |
| #381 (GitOps deploy broken) means the "real host" deploy path isn't working | It's already labeled a blocker; fix it or explicitly scope GitOps deploy out of the 1.0 contract                        |
| 1.0 ships without a stated contract, so "stable" can't be broken or honored | AC-OBS-03 is required, not optional                                                                                     |
| The plan and the Project drift apart                                        | This doc holds no task lists; the Project holds no decisions                                                            |
| A solo maintainer across seven repos                                        | Phases are sequential, Phase 0 items are small, and release mechanics already exist (release-please, the release agent) |
