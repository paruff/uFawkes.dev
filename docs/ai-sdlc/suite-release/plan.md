# Plan: uFawkes Suite Release

**Traces to:** [`spec.md`](spec.md) → [`intent.md`](intent.md) |
**Status:** Draft | **Revision:** 5

The plan is gate-driven, not date-driven. Release Please tags each repo
continuously; a suite release is the first version of a repo that passes its
release's acceptance criteria (`intent.md`, "What counts as a release").
Releases are verified in the order below, but work for later releases runs
earlier whenever it doesn't depend on an unverified version.

This plan holds decisions and sequence, not status. Live status is on
[ufawkes.dev/status](https://ufawkes.dev/status/) and
[Project #7](https://github.com/users/paruff/projects/7); release `goal`
issues carry each release's state.

## Where this plan lives, and how it syncs with GitHub

| What                                     | Where                                                                                               |
| ---------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Goals, decisions, release bars, sequence | This folder                                                                                         |
| Live task status across the seven repos  | [Project #7, "uFawkes Suite Release"](https://github.com/users/paruff/projects/7)                   |
| Live release status page                 | [ufawkes.dev/status](https://ufawkes.dev/status/), built daily from `acceptance.yml` and Project #7 |
| Per-release scope within a repo          | The `Release` field on Project #7; repo milestones are not used                                     |
| One parent issue per release             | A `goal` issue in the releasing repo; its tasks are sub-issues                                      |
| Suite-wide work                          | Issues in uFawkes.dev                                                                               |

**Sync rules:**

- **This doc lists no individual tasks.** Two task lists drift. The tasks
  are issues on Project #7. Steps below name the issue that carries them.
- **Project `Release` field options:** Suite hygiene, AI 2.0, Dojo 0.2,
  Obs 1.0, Pipe 2.0, DevX stable, fawkes Alpha, Dojo labs. Work outside
  these releases (uFawkesAI 2.x after 2.0, fawkes after Alpha) has no
  Release value.
- **Labels in all seven repos:** `release-blocker`, `goal`, `claude-code`,
  `opencode`, `model:mimo-v2.6-flash`, `model:nemotron-3-ultra`,
  `model:claude-opus-5.5`.
- **fawkes's 16 milestones stay.** Only the Alpha-epic children and its
  P0/P1 security issues join Project #7.
- **Post-release:** the `release` agent files a `measure:` issue. Add it to
  the Project. It tracks the adoption signals plus the playbook's leading
  indicators where the repo emits them: intent-to-merge time, first-pass CI
  success rate, and eval pass rate.

### The board: statuses, gates and moves

uFawkes.dev's `AGENTS.md` holds the two board commands (pick the next item,
list what waits on the owner). `scripts/setup-suite-board.sh` created these
statuses and the Gate field on 2026-11-09.

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
that status. No Gate means work only a human can do (real secrets, a live host).

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
`docs/ai-sdlc/README.md` says so (AC-AI-04).

- [`docs/ai-sdlc/README.md`](https://github.com/paruff/uFawkesAI/blob/main/docs/ai-sdlc/README.md): the `intent → spec → plan`
  chain and the CI artifact-chain gate. Every per-release folder this plan
  asks for follows it.
- [`dojo-handoff.md`](https://github.com/paruff/uFawkesAI/blob/2bd6e685faf36c8f38b098ae2e2a2d7bce0f2f04/docs/ai-sdlc/dojo-handoff.md) (removed from uFawkesAI main in uFawkesAI#251;
  linked at its last version until it lands in uFawkesDojo): how a release's
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

## Phase 0 — Suite hygiene (gate: AC-SUITE-01, AC-SUITE-02, AC-SUITE-03)

**Shipped** (goals uFawkes.dev#155 and uFawkes.dev#176 closed). Kept from
the 2026-10-09 recheck: the status build lists, under `hygiene` in
`suite_status.json`, items that are _Done_ but open, closed but not _Done_,
and open `release-blocker` or security issues not on the board, and warns on
each. It flags and does not fail.

## Phase 1 — uFawkesAI `v2.0.0` (gate: AC-AI-01..04, AC-AI-06..09, AC-SITE-01)

**Shipped 2026-10-14** (goal uFawkesAI#145 closed). The steps are in
uFawkesAI `docs/ai-sdlc/v2.0.0/plan.md`. Still open from the release
mechanism: uFawkesAI#252 (tags made by Release Please don't publish the
image), which every later `fawkes-space` tag depends on.

## Phase 2 — uFawkesDojo `0.2` (gate: AC-DOJO-01..03)

**Shipped 2026-10-07 as `0.2.0`** (goal uFawkesDojo#11 closed).

## Phase 3 — uFawkesObs 1.x + Dojo `0.3` (gate: AC-OBS-01..04)

`v1.0.0` was tagged on 2026-10-14 before its criteria passed. This release
is the first 1.x version that passes them. Goal: uFawkesObs#600.

1. Make a default install quiet: uFawkesObs#670, following uFawkesObs
   `docs/ai-sdlc/healthy-default-alerts/plan.md`. uFawkesObs#502 (SLO
   burn-rate alerts) edits the same rules and stays _Blocked_ until then.
2. Confirm the chaos nightly goes green (uFawkesObs#671).
3. Run the README Quick Start on a clean Linux host and a clean macOS host
   against the newest 1.x tag (AC-OBS-01). Record both transcripts in one
   comment on uFawkesObs#600 and link it as the AC's `evidence`.
4. Dojo `0.3`: Brown Belt Modules 13–16 (uFawkesDojo#42–45), pinned to that
   tag. AC-OBS-04 links the lab. If the labs aren't ready when steps 1–3
   pass, open a `Decision:` issue on whether to announce without them.
5. Run the `release` agent, mark the version Verified on `/compatibility/`,
   and close uFawkesObs#600. Then remove `release-as: 1.0.1` from uFawkesObs
   `release-please-config.json`, or later releases stay pinned to 1.0.1.

## Phase 4 — uFawkesPipe `v2.0.0` + Dojo `0.4` (gate: AC-PIPE-01)

Goal: uFawkesPipe#120.

1. Consolidate the remaining spec and design files into
   `docs/ai-sdlc/v2.0.0/` (uFawkesPipe#121; `docs/product/` and the v0.2
   `docs/plan.md` were removed in uFawkesPipe#207).
2. Decide `build-image`: make it real or drop the claim (uFawkesPipe#122,
   _Needs human_).
3. Do a real pipeline run on a sample repo, with `notify-obs` pointed at the
   verified Obs 1.x (uFawkesPipe#123).
4. Add the nightly live acceptance workflow (uFawkesPipe#125).
5. Dojo `0.4`: Yellow Belt Modules 5–8 move to Woodpecker, which retires the
   Jenkins content.
6. Release and announce.

## Phase 5 — uFawkesDevX first verified stable (1.x) + Dojo `0.5` (gate: AC-DEVX-01)

Goal: uFawkesDevX#146. The stack runs with no database service (ADR-0001,
uFawkesDevX#57 closed 2026-10-16).

1. Write `docs/ai-sdlc/<version>/` for the 1.x version being verified (the
   earlier draft is in `docs/ai-sdlc/v0.1.0/`).
2. Run a clean-host transcript of that version (AC-DEVX-01) and link it as
   the AC's `evidence`.
3. Dojo `0.5`: White Belt Modules 1, 3 and 4 move to uFawkesDevX.
4. Mark the version Verified on `/compatibility/` and close uFawkesDevX#146.
5. Suite mode (uFawkes.dev#70): measure it once all three stacks run
   together. Blocked until uFawkesPipe's `compose.suite.yaml` stops joining
   the archived uFawkesRes network; it also needs a host with at least 16 GB.

## Phase 6 — fawkes Tracer Bullet Alpha + Dojo `0.6` (gate: AC-FAWKES-01..04)

Goal: fawkes#1804. fawkes work runs in parallel with Phases 3–5. Only the
release waits.

1. Close the P0 security issues first (fawkes#2004, fawkes#1797). These are
   Claude Code only.
2. Root-cause Grafana's datasource (fawkes#2130), then make DORA queryable
   (fawkes#1572, fawkes#1919).
3. Set up the tunnel (fawkes#1856) and do one continuous gitops-promote run
   (fawkes#1858).
4. Scope the README to Alpha. Write `docs/ai-sdlc/tracer-bullet-alpha/`
   (fawkes#2188).
5. Dojo `0.6`: Green Belt graduation framing ("why Kubernetes now"), Tekton
   references.
6. Release as `v0.4.0`, announce, and add fawkes to the matrix as the
   graduation path.

### After Alpha: becoming uFawkesRes's successor (tracked, not promised)

These are not part of the Alpha gate, and no date is promised. uFawkesRes is
deprecated and its README names fawkes as a _partial_ successor. fawkes
already covers two of uFawkesRes's four roles: shared PostgreSQL (CloudNativePG,
`platform/apps/postgresql`) and ingress (`ingress-nginx`). Closing the
gap means three upgrades:

1. **Valkey caching** (fawkes#2189). A shared cache service on the cluster.
2. **Broad SSO** (fawkes#2190). One sign-in across the platform's apps,
   filling the role Authelia had. This is security-sensitive, so a decision
   (ADR) comes first.
3. **Upgrade from pre-alpha Kubernetes** (fawkes#2191). Local k3d evaluation
   works and cloud production doesn't. The path to a cloud-capable Beta needs
   defining before anything depends on it.

The Docker Compose stacks don't need a successor from fawkes:
uFawkesDevX runs without a database service (ADR-0001). When an item lands,
update the table in uFawkesRes's README, which then names fawkes without the
"partial".

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
| Main protection  | `scripts/check-branch-protection.sh` | exit 0 once the three golden-path repos have the ruleset and squash-only merges (an owner action)  |

`AC-SUITE-01` and `AC-SUITE-03` cover the seven product repos. The
golden-path repos are fawkes-owned fixtures (`intent.md`); they join those
two criteria in the same change that gives each a root `INTENT.md`.

## Risks

| Risk                                                                    | Mitigation                                                                                             |
| ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| Free models produce plausible but wrong content (especially curriculum) | The "run it for real" rule, Claude Code review on every OpenCode PR, and escalation after two failures |
| A secret or credential ends up in a free-tier prompt                    | Security and credential issues are always `goal`                                                       |
| fawkes's issues swamp the suite Project                                 | Only Alpha-epic children and P0 security issues join it                                                |
| One maintainer across ten repos                                         | One `goal` in flight at a time in Claude Code; OpenCode tasks run in parallel underneath it            |
| The plan and the Project drift apart                                    | This doc holds no task list; the tasks are issues on Project #7                                        |
