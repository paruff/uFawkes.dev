# Plan: uFawkes Suite Release

**Traces to:** [`spec.md`](spec.md) → [`intent.md`](intent.md) |
**Status:** Draft | **Revision:** 3

The plan is gate-driven, not date-driven. Each release starts its tag when
the previous release's gate passes, but work for later releases can run
earlier whenever it doesn't depend on an unreleased version. Releases follow
uFawkesAI's weekly cadence: if an increment is shippable on Thursday, ship
it.

## Where this plan lives, and how it syncs with GitHub

| What                                     | Where                                                                             |
| ---------------------------------------- | --------------------------------------------------------------------------------- |
| Goals, decisions, release bars, sequence | This folder                                                                       |
| Live task status across all seven repos  | [Project #7, "uFawkes Suite Release"](https://github.com/users/paruff/projects/7) |
| Per-release scope within a repo          | A milestone per release (e.g. uFawkesAI `v2.0.0`)                                 |
| One parent issue per release             | A `goal` issue in the releasing repo; its tasks are sub-issues                    |
| Suite-wide work                          | Issues in uFawkes.dev                                                             |

**Sync rules:**

- **This doc lists no individual tasks.** Two task lists drift.
  [`issues-draft.md`](issues-draft.md) holds the proposed issues until
  they're created, then it's deleted.
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

## Phase 0 — Suite hygiene (gate: AC-SUITE-01 recheck, AC-SUITE-02)

Mostly done in revision 1. What's left:

- [ ] Labels and Project field options above
- [ ] Create the issues in [`issues-draft.md`](issues-draft.md), add them to
      Project #7, and relabel existing issues per the rubric
- [ ] fawkes: mark ADR-004 superseded by ADR-036
- [ ] uFawkesDevX: remove uFawkesRes references from public docs
- [ ] Archive ufawkessec (uFawkes.dev #68) and uFawkesRes; their READMEs
      point to the successor first
- [ ] uFawkes.dev: retire `/dora/` and `/sec/`, add `/ai/` and `/fawkes/`
      stubs to the nav

## Phase 1 — uFawkesAI `v2.0.0` (gate: AC-AI-01..04, AC-AI-06..09, AC-SITE-01)

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
6. Run the "Use this template" test (AC-AI-02) on `v2.0.0-rc.1`.
7. Tag `v2.0.0`, then run the `release` agent: GitHub Release with the image
   digest, the ufawkes.dev `/ai/` page, and dev.to and LinkedIn drafts.
8. Within a week, pin every suite repo to `:2.0.0` (AC-AI-05).

## Phase 2 — uFawkesDojo `0.2` (gate: AC-DOJO-01..03)

Accuracy work (steps 1–2) can start now. Step 3 needs uFawkesAI `v2.0.0`.

1. The accuracy pass: five metrics (#19), Jenkins labeling, and removing or
   labeling unbuilt labs, videos and links.
2. Extend the existing module-authoring guide (AC-DOJO-03).
3. Build the "Start here" uFawkesAI lab and run it for real.
4. Update `docs/ai-sdlc/compose-curriculum/plan.md` to this order, and align
   ufawkes.dev's learn guides (uFawkes.dev #67).
5. Release `0.2`. Announce it with uFawkesAI's follow-up post: "now learn
   it".

## Phase 3 — uFawkesObs `v1.0.0` + Dojo `0.3` (gate: AC-OBS-01..04, AC-DOJO-04)

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

## Phase 5 — uFawkesDevX `v0.1.0` + Dojo `0.5` (gate: AC-DEVX-01)

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

## Risks

| Risk                                                                    | Mitigation                                                                                                            |
| ----------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| Obs's rc goes stale while it waits behind uFawkesAI and the Dojo        | Phase 1 is small (mostly #111 and docs). If AI slips more than two weeks, ship Obs first and don't re-argue the order |
| Free models produce plausible but wrong content (especially curriculum) | The "run it for real" rule, Claude Code review on every OpenCode PR, and escalation after two failures                |
| A secret or credential ends up in a free-tier prompt                    | Security and credential issues are always `goal`                                                                      |
| fawkes's 43 issues swamp the suite Project                              | Only Alpha-epic children and P0 security issues join it                                                               |
| One maintainer across seven repos                                       | One `goal` in flight at a time in Claude Code; OpenCode tasks run in parallel underneath it                           |
| The plan and the Project drift apart                                    | This doc holds no task list; `issues-draft.md` is deleted once the issues exist                                       |
