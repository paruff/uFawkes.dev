# Plan: uFawkes Suite Release

**Traces to:** [`spec.md`](spec.md) → [`intent.md`](intent.md) |
**Status:** Draft | **Revision:** 4 (status as of 2026-10-17)

The plan is gate-driven, not date-driven. Each release starts its tag when
the previous release's gate passes, but work for later releases can run
earlier whenever it doesn't depend on an unreleased version. Releases follow
uFawkesAI's weekly cadence: if an increment is shippable on Thursday, ship
it.

## Status, 2026-10-17

Collected from `scripts/suite-status.sh` against Project #7,
`make live-checks`, `scripts/check-branch-protection.sh`, each repo's GitHub
Releases, and live probes of a running uFawkesObs and uFawkesDevX on a macOS
Docker Desktop host (4 vCPU, 8 GB).

### Where each release stands

| #   | Release                           | Tagged                                    | Gate on the board                     | Real state                                                                                                                                                                                                                       |
| --- | --------------------------------- | ----------------------------------------- | ------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0   | Suite hygiene                     | n/a                                       | 4/4 ACs pass, 37/37 issues            | Done. Board drift fixed 2026-10-17                                                                                                                                                                                               |
| 1   | uFawkesAI `v2.0.0`                | `v2.0.0`, 2026-10-14                      | 9/9 ACs pass                          | **Shipped.** All seven repos pin `fawkes-space:2.0.0@sha256:def9302d…`, and the pin issues are closed. `v2.1.0` is in a Release Please PR (#216). Left on the board: shift-left follow-ups uFawkesPipe#145, #155 and fawkes#2227 |
| 2   | uFawkesDojo `0.2`                 | `0.2.0`, 2026-10-07                       | 3/3 ACs pass, 11/11 issues            | **Shipped.** Rolling AC-DOJO-04 now sits under `Dojo labs`                                                                                                                                                                       |
| 3   | uFawkesObs `v1.0.0`               | `v1.0.0`, 2026-10-14                      | 2/4 ACs pass (AC-OBS-01, -04 pending) | **Next release. Tagged before its gate passed.** No clean-host transcript, goal #600 open, and a default install isn't clean (uFawkesObs#670, #671). Finish as `v1.0.1`                                                          |
| 4   | uFawkesPipe `v2.0.0`              | latest `v1.16.0-beta.1`                   | 0/1 AC                                | Release-defining work not started: #121, #122, #123, #125 open                                                                                                                                                                   |
| 5   | uFawkesDevX first verified stable | `v1.0.0`…`v1.2.0` stable since 2026-10-03 | 0/1 AC (`DevX stable`)                | **1.x accepted 2026-10-17.** #57 decided (ADR-0001, PR #119), and the stack runs with no database service. Needs a clean-host transcript (AC-DEVX-01)                                                                            |
| 6   | fawkes Tracer Bullet α            | latest `v0.3.163`, 2026-10-07             | 1 AC fail (AC-FAWKES-03), 1/15 issues | No movement since 10-07. P0 security issues fawkes#2004 and #1797 are open                                                                                                                                                       |

### Live findings (what a real run showed)

1. **A default uFawkesObs install raises about 27 alerts on a healthy stack.**
   A stack running for 17 hours from `main` (`ba2bfc7`, 12 commits after
   `v1.0.0`) had every container at `RestartCount=0`, yet:
   - `UFawkesObsContainerRestarting` fires for all eight services.
     `process_start_time_seconds` wobbles by ±1 s under the Docker Desktop VM
     clock, and `changes()` counts each wobble as a restart.
   - `ServiceDown{job="dora-api"}` fires because `prometheus.yaml` always
     scrapes `dora-api:8088`, even though its own comment says "dora profile
     only". That down target also drives `SLOBurnRateFast/Medium/Slow`.
   - About 15 `*Absent` rules fire with no data, including
     `PrometheusStorageAlmostFullAbsent`, which is an `absent()` over
     `prometheus_tsdb_retention_limit_bytes`. That metric isn't exported unless a
     size retention is set.
   - Loki and Tempo `/ready` return 503 ("Ingester not ready") after 17 hours,
     while both still answer queries.

   The `dora-api` scrape and the `absent()` rules are in the `v1.0.0` tag.
   This contradicts the "installs cleanly" bar (AC-OBS-01).

2. **uFawkesObs `ci-chaos-nightly` has failed every night since 2026-10-10**
   (before the `v1.0.0` tag). The failure is
   `test_obschaos002`: "Expected all 11 targets UP, got 10". This is probably
   the same always-scraped `dora-api` target. Not yet confirmed.
3. **uFawkesDevX runs without uFawkesRes.** Gateway, Backstage, Coder and
   score-service are all healthy, with no database service in `compose.yaml`.
   This is partial evidence for AC-DEVX-01. It is not a clean-host transcript,
   because the run is from a working clone on a feature branch.
4. **ufawkes.dev contradicts itself (AC-SUITE-01).** `/compatibility/` lists
   uFawkesDevX as "None yet, heading to v0.1.0", while `/devx/` says `v1.2.0`. It
   also lists fawkes on `fawkes-space:2.0.0-rc.3`, while fawkes pins `2.0.0`.
5. **Scheduled checks:** 12 of 15 are green. The three that aren't: Obs
   chaos nightly (above); fawkes `golden-path-acceptance-tests`, which is red
   weekly since at least 2026-09-21 with "No cluster configured", a setup gap
   rather than a test failure; and uFawkesAI `pre-commit-autoupdate`, which
   has never run (it is monthly).
6. **Main protection:** the original seven pass. The three golden-path repos
   still have all three departures each (no ruleset, not squash-only, delete
   branch on merge off). uFawkesAI also has classic protection on top of its
   ruleset.
7. **Suite mode (#70) has started but has not been measured.** Only
   `obs-alone-idle.csv` (2026-10-15) exists, and uFawkesPipe isn't running.

### Done on 2026-10-17

- **DevX version line decided (owner): accept 1.x.** The `DevX 0.1` release
  is renamed `DevX stable` in `acceptance.yml`, `spec.md` and the Project #7
  `Release` field (option id kept, so all 13 items stay assigned). The first 1.x
  release that passes AC-DEVX-01 is the "first verified stable" one.
  `/compatibility/` now shows DevX `v1.2.0` as "released, not yet verified on a
  clean host", and fawkes on `fawkes-space:2.0.0`.
- **Status model:** the rolling AC-DOJO-04 moved to the `Dojo labs` release, at
  the end of `acceptance.yml`. "Next release" now reads **Obs 1.0**, and Dojo
  0.2 shows 3/3.
- **`make status` runs.** `.PHONY` stops the `status/` directory from making the
  target look up to date, and the target falls back to `gh auth token`.
- **Board sweep:** closed uFawkesObs#599, uFawkesPipe#119, uFawkesDevX#80,
  fawkes#2187 and uFawkesDevX#84, each with its evidence. Set uFawkes.dev#61,
  uFawkes.dev#94 and uFawkesDevX#98 to _Done_. Filed
  [uFawkesObs#670](https://github.com/paruff/uFawkesObs/issues/670) (alert
  noise) and [uFawkesObs#671](https://github.com/paruff/uFawkesObs/issues/671)
  (chaos nightly) as `release-blocker` items on Obs 1.0.

### Next steps, in order

1. **Close Obs `v1.0.0` properly as `v1.0.1`** (`goal`, Claude Code). Fix
   uFawkesObs#670, one PR per rule group. Confirm the chaos nightly goes green
   (uFawkesObs#671). Run the clean-host transcripts on Linux and macOS
   (AC-OBS-01), announce (AC-OBS-04), and close #600.
2. **uFawkesPipe `v2.0.0`** (Phase 4). Decide #122 (`build-image`) first.
   Then do the real pipeline run, #123, against Obs `v1.0.1` and not `v1.0.0`.
3. **uFawkesDevX first verified stable:** produce a clean-host transcript of
   the latest 1.x (AC-DEVX-01), record it as evidence in `acceptance.yml`, and
   change the `/compatibility/` status to "Verified".
4. **fawkes:** fawkes#2004 and #1797 (P0, Claude Code only) are the only items
   that move AC-FAWKES-03. Separately, either give
   `golden-path-acceptance-tests` a cluster or remove it from its schedule, so
   the red is real.
5. **Suite mode (#70):** run the full procedure once Pipe is running alongside
   Obs and DevX.
6. **Golden-path repos:** apply the `main-protection` ruleset and squash-only
   merges (an owner action, per the main-protection standard), then add root
   `INTENT.md` files so that AC-SUITE-01 and AC-SUITE-03 widen to ten.

## Where this plan lives, and how it syncs with GitHub

| What                                     | Where                                                                                               |
| ---------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Goals, decisions, release bars, sequence | This folder                                                                                         |
| Live task status across all seven repos  | [Project #7, "uFawkes Suite Release"](https://github.com/users/paruff/projects/7)                   |
| Live release status page                 | [ufawkes.dev/status](https://ufawkes.dev/status/), built daily from `acceptance.yml` and Project #7 |
| Per-release scope within a repo          | A milestone per release (e.g. uFawkesAI `v2.0.0`)                                                   |
| One parent issue per release             | A `goal` issue in the releasing repo; its tasks are sub-issues                                      |
| Suite-wide work                          | Issues in uFawkes.dev                                                                               |

**Sync rules:**

- **This doc lists no individual tasks.** Two task lists drift. The tasks
  are issues on Project #7 (the proposed issues were created on 2026-10-02).
- **Project `Release` field options:** Suite hygiene, AI 2.0, Dojo 0.2,
  Obs 1.0, Pipe 2.0, DevX 0.1, fawkes Alpha, Dojo labs. Add the three new
  ones (AI 2.0, Dojo 0.2, fawkes Alpha) and rename "Dojo compose" to "Dojo
  labs".
- **Labels in all seven repos:** `release-blocker`, `goal`, `claude-code`,
  `opencode`, `model:mimo-v2.6-flash`, `model:nemotron-3-ultra`,
  `model:claude-opus-5.5`. uFawkesAI, uFawkesDevX and fawkes are missing
  some. uFawkesDevX's `model:lite` and `model:strong` map to flash and
  ultra, then get deleted.
- **fawkes's 16 milestones stay.** Only the Alpha-epic children and its
  P0/P1 security issues join Project #7.
- **Post-release:** the `release` agent files a `measure:` issue. Add it to
  the Project. It tracks the adoption signals plus the playbook's leading
  indicators where the repo emits them: intent-to-merge time, first-pass CI
  success rate, and eval pass rate.

### The board: statuses, gates and moves

Every suite repo's `AGENTS.md` links here and holds the two board commands.

| Status          | Means                                                                                  | Moved here by                           |
| --------------- | -------------------------------------------------------------------------------------- | --------------------------------------- |
| Backlog         | Not ready, or its release is gated                                                     | "Item added" workflow; anyone           |
| Ready for agent | Has a routing label, a plan link and an exit criterion, and its release is not Blocked | Owner, or Claude Code on a `goal`       |
| In Progress     | Claimed. Move it here **before** starting, so no one else picks it                     | Whoever starts it                       |
| Needs human     | Waits on the owner: a decision, a PR to review and merge, or work only a human can do  | The agent, when it asks or opens the PR |
| Blocked         | Can't move until something named in the issue happens                                  | Anyone, with a comment naming it        |
| Done            | Closed or merged                                                                       | Built-in workflows                      |

`In Progress` and `Done` keep these exact names: `scripts/suite-status.sh`
matches them.

**Gate** says which approval a _Needs human_ item waits on. Read it only with
that status.

| Gate          | The owner is asked to                                       |
| ------------- | ----------------------------------------------------------- |
| intent        | Approve `docs/ai-sdlc/<feature>/intent.md`                  |
| spec          | Approve the spec and its acceptance criteria                |
| plan          | Approve the plan, or answer a `Decision:` question          |
| PR review     | Review the PR against `REVIEW.md`                           |
| merge/release | Merge, or tag the release once its acceptance criteria pass |

**Lifecycle.** Pick with command 1 in `AGENTS.md`, or the owner points you at
an issue. Move it to _In Progress_, then branch. The PR body says
`Closes #<n>` and pastes the checks named in the repo's `REVIEW.md`; then move
the issue to _Needs human_ with Gate _PR review_. Changes requested: back to
_In Progress_. Stuck: _Blocked_, with a comment naming the blocker. The owner
merges; the issue closes and the board sets _Done_.

**Decisions for the owner.** A question only the owner can answer is an issue:
title `Decision: …`, label `question`, assigned to `paruff`, the "Decision for
the owner" template, then _Needs human_ with the gate it holds. The owner
answers in the issue and closes it. Whoever applies the answer records it
where it belongs (intent, spec, plan, `DESIGN.md`) with a link to the issue.
Docs keep no question lists.

**Copilot.** It reads `AGENTS.md`, so it can run the commands above, but it
can't move items on this private board. Whoever assigns an issue to `@copilot`
moves it to _In Progress_; its PR shows up in the owner's queue.

## Conventions reused from uFawkesAI (linked, not copied)

uFawkesAI is the template every repo is built from, so its process docs
ship into each repo. Copying them here would create a second copy that
drifts. This plan links to them instead. Upstream, both follow [The AI-Native SDLC Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook) (Claxton, Anthropic, 2026-08-21); uFawkesAI's
`docs/ai-sdlc/README.md` should say so (AC-AI-04).

- [`docs/ai-sdlc/README.md`](https://github.com/paruff/uFawkesAI/blob/main/docs/ai-sdlc/README.md): the `intent → spec → plan`
  chain and the CI artifact-chain gate. Every per-release folder this plan
  asks for follows it.
- [`docs/ai-sdlc/dojo-handoff.md`](https://github.com/paruff/uFawkesAI/blob/main/docs/ai-sdlc/dojo-handoff.md): how a release's
  plan becomes a Dojo lab, and how lab feedback (`dojo-feedback.md`)
  becomes the next `intent` issue within one sprint. Every Dojo lab in
  Phases 2–6 is built this way (AC-DOJO-04). The loop's health metric, time
  from `intent` issue to merged intent, becomes a suite signal next to
  stars and outside PRs.

## Who does what: the routing rubric

Every issue gets exactly one routing label (AC-SUITE-02). Pick the first row
that matches.

This is the paper's "intelligent model routing" applied to the suite. In
its terms, Claude Code on a `goal` is **conductor** mode: real-time
direction where judgment and live verification matter. OpenCode on a
labeled task is **orchestrator** mode: a well-specified task handed off
and reviewed later. One deliberate deviation: the paper routes code review
to smaller models. Here, Claude Code reviews every OpenCode PR, because the
free models' errors are the "80% problem" kind that look right and pass
basic checks.

| Label                                 | Runs in                                   | Use it when the issue…                                                                                                                                                                                                       |
| ------------------------------------- | ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `goal` + `claude-code`                | Claude Code (Opus 5.5)                    | is a release, a decision or ADR, touches more than one repo, is security-sensitive, has an unknown root cause, or needs a real run to verify it (clean-host install, k8s, a lab transcript). Parent issues are always `goal` |
| `opencode` + `model:nemotron-3-ultra` | OpenCode, `nemotron-3-ultra-free`         | is bounded to one repo, comes with a written spec or acceptance criteria, and needs reasoning across several files: a module rewrite, a test migration, doc consolidation, a known-target CI change                          |
| `opencode` + `model:mimo-v2.6-flash`  | OpenCode, `opencode/mimo-v2.6-flash-free` | is mechanical: one file or a grep-and-replace, a rename, links, front matter, labels. One command proves it's done                                                                                                           |

**Guardrails for the free models:**

- **Never route secrets, credentials or security fixes to OpenCode.** Free
  tiers may retain prompts. These are always `goal`.
- **Escalate, don't retry.** A flash task that fails `make validate` twice
  moves to Nemotron. A Nemotron task that fails twice, or turns out to need
  a decision, becomes a `goal` child for Claude Code.
- **Claude Code reviews every OpenCode PR before merge.** The PR has to link
  its issue and paste the validation output.
- **Write the issue for the model.** OpenCode issues name the exact files,
  the acceptance check, and what not to touch. If you can't write that
  down, it's a `goal`.

## Phase 0 — Suite hygiene (gate: AC-SUITE-01 recheck, AC-SUITE-02, AC-SUITE-03)

Phase 0 is complete (rechecked 2026-10-09, below). Status on 2026-10-02,
verified against each repo's `main`:

- **AC-SUITE-02: met.** All 96 open issues on Project #7 carry exactly one
  routing label.
- **AC-SUITE-03: met.** All seven repos have a root `INTENT.md` and run the
  artifact-chain check on their PRs with their own code paths (uFawkesAI:
  `scripts/`, `images/`, `templates/`), skipping Dependabot's bumps. It is not
  yet a required check (#99), and a Release Please run fails in two repos for
  a reason not yet found (#100).
- **AC-SUITE-01: met.** The owner decided on 2026-10-02 that this gate covers
  **public entry points** (each repo's README and INTENT, and the site pages).
  The scoped recheck found 7 real false claims, all fixed and merged, and the 5
  lines still matching are labelled in context. The wider count (about 1,380
  lines across docs, tests and planning files) belongs to Phases 2 to 6 and is
  re-checked before each announcement.

**Recheck, 2026-10-09 ([#176](https://github.com/paruff/uFawkes.dev/issues/176)).**
The 10-02 result did not hold: the shift-left rollout added issues after it, and
`/status/` showed AC-SUITE-02 failing. An audit of the board against GitHub found:

- **AC-SUITE-02 failed.** uFawkes.dev#153 had no routing label (now `goal`; it
  waits on the owner's sign-off, since it adds a plugin to the governed
  `.opencode/plugins/`). fawkes#2222 was done but open: its two PRs (#2219,
  #2223) are on `main`, and it is closed.
- **The board disagreed with GitHub.** uFawkesDevX#55 was closed but _In
  Progress_. uFawkesDojo#42–52 were open (reopened after the 2026-10-06
  curriculum audit) but _Done_. Both are fixed. The status build counts a
  _Done_ item as done whether or not it is open, which hid the Dojo drift.
- **Eleven open release-blocker, security or P0 issues were not on the board**,
  so no check could see them: uFawkes.dev#132 and #147, uFawkesDevX#98 and #102,
  uFawkesObs#617 and #619, uFawkesPipe#145, uFawkesDojo#73, fawkes#684, #1569
  and #1715. They are on it now, routed and given a release. Six stale May-era
  issues (uFawkesAI#32 and #33, uFawkesPipe#6, uFawkesDevX#8 to #10) were closed
  as not planned.
- **Shift-left follow-ups moved to AI 2.0** so they don't hold this gate open:
  uFawkesPipe#155, uFawkesDevX#99 and fawkes#2227. (The status page listed
  uFawkesDevX#99 as likely done. It is not: the matched PR, #101, added `tsc`,
  not mypy.)
- **Result:** all four Suite hygiene ACs pass on the live board (a status build
  run on 2026-10-09 against Project #7).
- **Kept from recurring:** the status build now lists, in `suite_status.json`
  under `hygiene`, items that are _Done_ but open, closed but not _Done_, and
  open `release-blocker` or security issues that are not on the board, and
  prints a warning for each. It flags and does not fail.

The checklist:

- [x] Labels and Project field options above (done 2026-10-02: the routing
      labels exist in all seven repos; `Release` has AI 2.0, Dojo 0.2, fawkes
      Alpha, and "Dojo labs")
- [x] Create the issues from the draft, add them to Project #7, and relabel
      existing issues per the rubric (done 2026-10-02, after the owner approved
      the draft: 62 issues created plus 2 follow-ups, 29 existing issues
      routed or placed, the duplicates closed; AC-SUITE-02 met with all 96
      open issues on Project #7 carrying exactly one routing label). The
      draft is deleted. Left for the owner: uFawkesAI#31 (close after
      checking `.mcp.json` covers it) and uFawkes.dev#65 (kept on `goal`: it
      touches every stack README, and the rubric sends multi-repo work to
      `goal`, though the draft said Nemotron)
- [x] fawkes: mark ADR-004 superseded by ADR-036 (done on `main` since
      2026-09-16)
- [x] uFawkesDevX: remove uFawkesRes references from public docs (uFawkesDevX#69
      merged; the Backstage catalog entity and its tests remain, a follow-up)
- [x] Document levels (AC-SUITE-03), met 2026-10-02: root `INTENT.md` in all
      seven repos; the template's artifact-chain check has a per-repo
      code-path setting (uFawkesAI#137); every repo runs it on its PRs with its
      own `.artifact-chain-paths`. Not yet a required check
- [x] Archive ufawkessec (uFawkes.dev #68) and uFawkesRes (done 2026-10-02;
      their READMEs name the successor first, fawkes as a partial one for Res)
- [x] uFawkes.dev: retire `/dora/` and `/sec/`, add `/ai/` and `/fawkes/`
      stubs to the nav (#80 merged; the two old pages were already pointer
      pages outside the nav)

## Phase 1 — uFawkesAI `v2.0.0` (gate: AC-AI-01..04, AC-AI-06..09, AC-SITE-01)

**Shipped 2026-10-14.** All ACs pass and all seven repos pin the image (step 8).

1. Write `uFawkesAI/docs/ai-sdlc/v2.0.0/{intent,spec,plan}.md`. Settle the
   contract (`intent.md`, Still open #1).
2. Fix the image publish path (#111). Retire the `image-v*` and
   `*-devcontainer` tags.
3. Add the placeholder audit (#28). (#90, the `plan` skill filenames, closed
   2026-10-01: the file it targeted was removed.)
   Move the root-level v1 `intent/spec/plan.md` into its own feature folder.
   Finish `dora-events-portability` and verify an event in uFawkesObs's
   Loki, or drop the claim (AC-AI-06).
4. Add the cold/warm start benchmark (AC-AI-08) and record its first
   baseline on `v2.0.0-rc.1`. Ground `docs/ai-sdlc/devsecops-image/` (the
   CDE's own spec) in the DevEx section of the research library.
5. Retire pre-commit.ci (AC-AI-09): pre-bake the hook environments into
   the image, make Pre-flight required, add the autoupdate workflow, and
   sync the change to every repo.
   The follow-on, running every feasible check earlier and alerting when
   one isn't installed or doesn't run, is planned in
   [`docs/ai-sdlc/shift-left/`](../shift-left/plan.md).
6. Run the "Use this template" test (AC-AI-02) on `v2.0.0-rc.1`.
7. Tag `v2.0.0`, then run the `release` agent: GitHub Release with the image
   digest, the ufawkes.dev `/ai/` page, and dev.to and LinkedIn drafts.
8. Within a week, pin every suite repo to `:2.0.0` (AC-AI-05).

## Phase 2 — uFawkesDojo `0.2` (gate: AC-DOJO-01..03)

**Shipped 2026-10-07 as `0.2.0`.** AC-DOJO-01..03 pass. Steps 4–5 (learn-guide
alignment, the "now learn it" post) are not verified here.

1. The accuracy pass: five metrics (#19), Jenkins labeling, and removing or
   labeling unbuilt labs, videos and links.
2. Extend the existing module-authoring guide (AC-DOJO-03).
3. Build the "Start here" uFawkesAI lab and run it for real.
4. Update `docs/ai-sdlc/compose-curriculum/plan.md` to this order, and align
   ufawkes.dev's learn guides (uFawkes.dev #67).
5. Release `0.2`. Announce it with uFawkesAI's follow-up post: "now learn
   it".

## Phase 3 — uFawkesObs `v1.0.0` + Dojo `0.3` (gate: AC-OBS-01..04, AC-DOJO-04)

**Tagged 2026-10-14 with steps 2–3 undone.** No clean-host transcript yet,
Brown Belt 13–16 (uFawkesDojo#42–45) are still open, and a default install raises
false alerts (see Status). Finish this phase as `v1.0.1`.

1. Fix #534 (blocker). Cut a fresh rc.
2. Run clean-host tests on Linux and macOS against the rc.
3. Dojo Phase A: re-pin the Module 2 lab to `v1.0.0`, then Brown Belt
   Modules 13–16, one PR each.
4. Tag `v1.0.0`. Run the `release` agent; the posts link to the Dojo lab
   (uFawkes.dev #66 covers screenshots).

## Phase 4 — uFawkesPipe `v2.0.0` + Dojo `0.4` (gate: AC-PIPE-01)

1. Consolidate the spec and design files into `docs/ai-sdlc/v2.0.0/`.
2. Decide on `build-image`: make it real or drop the claim.
3. Do a real pipeline run on a sample repo, with `notify-obs` pointed at Obs
   `v1.0.0`.
4. Dojo Phase B: Yellow Belt Modules 5–8 move to Woodpecker, which retires
   the Jenkins content.
5. Release and announce.

## Phase 5 — uFawkesDevX first verified stable (1.x) + Dojo `0.5` (gate: AC-DEVX-01)

**Steps 1–2 done** (#57 closed 2026-10-16, ADR-0001, PR #119). **Version line
decided 2026-10-17: accept 1.x.** Release Please has published stable
`v1.0.0`–`v1.2.0`, so this phase's release is the first 1.x release that passes
AC-DEVX-01 (the "first verified stable", the `DevX stable` release on the
board). Step 3 moves the docs into `docs/ai-sdlc/<that version>/`, and step 4 no
longer says "release as a beta".

1. Decide #57 and record an ADR. The issue proposes SQLite for
   `score-service` and Backstage, and Coder's built-in Postgres.
2. Implement the decision, one component per PR.
3. Move the root spec, design and plan into `docs/ai-sdlc/v0.1.0/`.
4. Run a clean-host test. Release as a beta.
5. Dojo Phase C: White Belt Modules 1, 3 and 4 move to uFawkesDevX.
6. Define suite mode (uFawkes.dev #70) now that all three stacks have
   released.

## Phase 6 — fawkes Tracer Bullet Alpha + Dojo `0.6` (gate: AC-FAWKES-01..04)

fawkes work runs in parallel with Phases 1–5. Only the release waits.

1. Close the P0 security issues first (#2004, #1797). These are Claude Code
   only.
2. Root-cause Grafana's datasource (#2130), then make DORA queryable
   (#1572, #1919).
3. Set up the tunnel (#1856) and do one continuous gitops-promote run
   (#1858).
4. Scope the README to Alpha. Write `docs/ai-sdlc/tracer-bullet-alpha/`.
5. Dojo Phase D: Green Belt graduation framing ("why Kubernetes now"),
   Tekton references.
6. Release, announce, and add fawkes to the matrix as the graduation path.

### After Alpha: becoming uFawkesRes's successor (tracked, not promised)

These are not part of the Alpha gate, and no date is promised. uFawkesRes is
deprecated and its README names fawkes as a _partial_ successor. fawkes
already covers two of uFawkesRes's four roles: shared PostgreSQL (CloudNativePG,
`platform/apps/postgresql`) and ingress (`ingress-nginx`). Closing the
gap means three upgrades:

1. **Valkey caching.** A shared cache service on the cluster. Nothing ships
   today outside the deferred apps.
2. **Broad SSO.** One sign-in across the platform's apps, filling the role
   Authelia had. Nothing ships today outside the deferred apps. This is
   security-sensitive, so a decision (ADR) comes first.
3. **Upgrade from pre-alpha Kubernetes.** Today local k3d evaluation works
   and cloud production doesn't (`v0.3.95`). The path from there to a
   cloud-capable Beta needs defining before anything depends on it.

Until these land, the Docker Compose stacks don't gain a successor from
fawkes: uFawkesDevX's database question stays on uFawkesDevX#57. When an
item lands, update the table in uFawkesRes's README, which then names fawkes
without the "partial".

## Verification Strategy

| Criterion        | Evidence                                          | Collected in              |
| ---------------- | ------------------------------------------------- | ------------------------- |
| AC-SUITE-01      | Grep across public docs                           | Before every announcement |
| AC-SUITE-02      | Empty "unrouted" Project view                     | Phase 0                   |
| AC-SITE-01       | Seven repos on the site, matrix current           | Every release             |
| AC-AI-01..05     | Manifest + cosign output, template run transcript | uFawkesAI release notes   |
| AC-DOJO-01..04   | Grep, lab transcripts, same-week releases         | Dojo release notes        |
| AC-OBS-01..04    | Clean-host transcripts, four live URLs            | Obs release notes         |
| AC-PIPE-01       | Real pipeline run output                          | Pipe release notes        |
| AC-DEVX-01       | ADR plus clean-host transcript                    | DevX release notes        |
| AC-FAWKES-01..04 | CI run, Grafana panels, closed security issues    | fawkes release notes      |

### Suite membership (Revision 4, 2026-10-08)

The suite is ten repos: the original seven plus `java-fawkes-path`,
`python-fawkes-path` and `python-fawkes-path-gitops`, recorded in
[`intent.md`](intent.md). Both read-only audits default to all ten, so
membership is verified by running them:

| Check            | Command                              | Expected                                                                                           |
| ---------------- | ------------------------------------ | -------------------------------------------------------------------------------------------------- |
| Shift-left hooks | `make shift-left-audit`              | exit 0; the original seven `ok` on every column, the three new repos `n/a` plus a "no config" note |
| Main protection  | `scripts/check-branch-protection.sh` | exit 0; today exit 1 with nine departures, all three per new repo, which is the gap to close       |

`AC-SUITE-01` and `AC-SUITE-03` still cover the original seven only — both
need a root `INTENT.md` (and AC-SUITE-03 the artifact chain), which none of
the three new repos has. They widen to ten in the same change that adds
those files.

## Risks

| Risk                                                                    | Mitigation                                                                                                            |
| ----------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| Obs's rc goes stale while it waits behind uFawkesAI and the Dojo        | Phase 1 is small (mostly #111 and docs). If AI slips more than two weeks, ship Obs first and don't re-argue the order |
| Free models produce plausible but wrong content (especially curriculum) | The "run it for real" rule, Claude Code review on every OpenCode PR, and escalation after two failures                |
| A secret or credential ends up in a free-tier prompt                    | Security and credential issues are always `goal`                                                                      |
| fawkes's 43 issues swamp the suite Project                              | Only Alpha-epic children and P0 security issues join it                                                               |
| One maintainer across seven repos                                       | One `goal` in flight at a time in Claude Code; OpenCode tasks run in parallel underneath it                           |
| The plan and the Project drift apart                                    | This doc holds no task list; the tasks are issues on Project #7                                                       |
