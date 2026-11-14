# Plan: uFawkes Suite Release

**Traces to:** [`spec.md`](spec.md) → [`intent.md`](intent.md) |
**Status:** Draft | **Revision:** 6 (status as of 2026-11-09; audit findings added 2026-11-13)

The plan is gate-driven, not date-driven. Each release starts its tag when
the previous release's gate passes, but work for later releases can run
earlier whenever it doesn't depend on an unreleased version. Releases follow
uFawkesAI's weekly cadence: if an increment is shippable on Thursday, ship
it.

**Names used here.** The suite has ten repos: the **seven product repos**
(uFawkes.dev, uFawkesAI, uFawkesObs, uFawkesPipe, uFawkesDevX, uFawkesDojo,
fawkes) and the **three golden-path repos** (`java-fawkes-path`,
`python-fawkes-path`, `python-fawkes-path-gitops`). "The seven repos" always
means the product repos. Each release has one name, the Project #7 `Release`
option (`Obs 1.0`, `Pipe 2.0`, `DevX stable`, `fawkes Alpha`, ...); a version
(`v1.0.1`) names a tag inside it. Issue links are always `owner/repo#N`.

## Status, 2026-11-09

Collected from `scripts/suite-status.sh` against Project #7 (the
`/status/` page, generated 2026-11-09 06:25 UTC), `make live-checks`, and each
repo's GitHub Releases.

### Where each release stands

| #   | Release       | Latest tag             | Real state                                                                                                                                                                 |
| --- | ------------- | ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0   | Suite hygiene | n/a                    | **Done.** paruff/uFawkes.dev#155 and paruff/uFawkes.dev#176 closed. AC-SUITE-01/-03 went red when uFawkesAI dropped its root `INTENT.md`; paruff/uFawkesAI#281 restored it |
| 1   | AI 2.0        | `v2.2.0`, 2026-10-22   | **Shipped** (`v2.0.0` 2026-10-14, goal paruff/uFawkesAI#145 closed). Repos pin `fawkes-space:<version>@sha256:…`. Next is uFawkesAI's own `v2.3.0` plan                    |
| 2   | Dojo 0.2      | `0.2.0`, 2026-10-07    | **Shipped** (goal paruff/uFawkesDojo#11 closed). The rolling AC-DOJO-04 sits under `Dojo labs`                                                                             |
| 3   | Obs 1.0       | `v1.0.1`, 2026-10-18   | **Next release.** The alert fix (paruff/uFawkesObs#675) shipped in `v1.0.1`. Left: AC-OBS-01 evidence, AC-OBS-04 (needs the Dojo 0.3 lab), goal paruff/uFawkesObs#600      |
| 4   | Pipe 2.0      | `v1.16.0-beta.1`       | Not started: paruff/uFawkesPipe#121, paruff/uFawkesPipe#122, paruff/uFawkesPipe#123, paruff/uFawkesPipe#125 open. Goal paruff/uFawkesPipe#120                              |
| 5   | DevX stable   | `v1.2.0`, 2026-10-17   | 1.x accepted 2026-10-17 (ADR-0001). Needs a clean-host transcript (AC-DEVX-01), goal paruff/uFawkesDevX#146                                                                |
| 6   | fawkes Alpha  | `v0.3.163`, 2026-10-07 | AC-FAWKES-03 fails: paruff/fawkes#2004 and paruff/fawkes#1797 are open. Goal paruff/fawkes#1804                                                                            |

A release counts as shipped when every `goal:` issue in it is closed. The
status build then keeps its manual evidence as recorded instead of ageing it
past 30 days, so a shipped release can't turn the page red again on age alone.
A dead link still turns it red.

### Open findings from the live runs

1. **Obs: the default install was noisy; fixed.** About 27 alerts fired on a
   healthy stack (paruff/uFawkesObs#670). The fix follows
   [`uFawkesObs/docs/ai-sdlc/healthy-default-alerts/plan.md`](https://github.com/paruff/uFawkesObs/blob/main/docs/ai-sdlc/healthy-default-alerts/plan.md)
   and shipped in `v1.0.1`. Fresh-clone runs on Linux and macOS show 0 alerts
   after 30 min (comments on paruff/uFawkesObs#670). The chaos nightly (paruff/uFawkesObs#671)
   has been green every night since. Both issues meet their "done means" and
   wait to be closed.
2. **uFawkesAI's image build is red** (`build-cde-space-image.yml`, Trivy
   gate). `make live-checks` shows it; it doesn't block a suite release.
3. **The compatibility matrix fell behind the releases.** It listed uFawkesAI
   `v2.0.0` and uFawkesObs `v1.0.0` after `v2.2.0` and `v1.0.1` shipped.
   AC-SUITE-01 looks for retired names and couldn't see this, so AC-SITE-01
   now runs `scripts/checks/ac-site-01.sh`, which compares each row with the
   repo's newest GitHub Release. The matrix is updated.
4. **Suite mode (paruff/uFawkes.dev#70) is not measured.** Only
   `obs-alone-idle.csv` exists. It needs a 16 GB host (the documented one
   has 8 GB) and a Pipe that runs without uFawkesRes.

### Open findings from the 2026-11-13 audit

A read of all seven repos at `main`. Nothing was run, so each line is what
the files say, not a live observation. Each repo has one `goal` issue and its
tasks are that issue's sub-issues; none carries a `Release` yet, which is the
owner's call.

| Finding                                                                                                                                                                                        | Goal                   |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------- |
| Only deployment frequency is fed by real pipelines. Lead time has no input, only successful deployments are sent, and uFawkesObs's written contract disagrees with its schema files            | paruff/uFawkesObs#719  |
| `notify-obs` sends `status: success` only and no lead-time fields. The schema mirror is stale (paruff/uFawkesPipe#218), and `docs/pipeline-contract.md` documents fields the generator ignores | paruff/uFawkesPipe#223 |
| The emitter's test validates against a local schema that uFawkesObs rejects. Six repos carry an older copy of the emitter that no workflow calls                                               | paruff/uFawkesAI#291   |
| Every golden-path `.fawkespipe.yml` breaks uFawkesPipe's contract. The README, tests and catalog still describe Postgres, Jenkins and uFawkesSec                                               | paruff/uFawkesDevX#153 |
| The uFawkesObs labs match their stack. The uFawkesDevX and uFawkesPipe labs don't, and nothing checks a lab's commands against the tag it pins                                                 | paruff/uFawkesDojo#127 |
| Alpha's Grafana ships copies of uFawkesObs dashboards that nothing in fawkes feeds. The design system departs from the tokens                                                                  | paruff/fawkes#2314     |
| Stack pages disagree with the compatibility matrix, `/dora/` and `/sec/` show a live badge, and `make design-check` doesn't read `main.css`. New criteria: AC-SUITE-04 and AC-SITE-02          | paruff/uFawkes.dev#236 |

### Next steps, in order

1. **Finish Obs 1.0** (goal paruff/uFawkesObs#600, Claude Code).
   - Close paruff/uFawkesObs#670 and paruff/uFawkesObs#671 with their evidence. AC-OBS-02 then
     passes.
   - AC-OBS-01: the owner decides whether the two paruff/uFawkesObs#670 transcripts count as
     clean-host runs (fresh clones, but on working machines). If yes, record a
     comment on paruff/uFawkesObs#600 that links both as `evidence` in `acceptance.yml`. If not,
     the owner reruns them on clean hosts; only a human can.
     For later releases, give uFawkesObs a `live-acceptance.yml` like
     uFawkesDevX's (`make up` on a fresh Linux runner on every release); its
     run link is then the Linux half.
   - AC-OBS-04 needs the Dojo 0.3 lab: Brown Belt Modules 13–16,
     paruff/uFawkesDojo#42, paruff/uFawkesDojo#43, paruff/uFawkesDojo#44 and paruff/uFawkesDojo#45 (OpenCode). Add a `Blocked by` line naming them to
     paruff/uFawkesObs#600's body. If they aren't merged when everything else
     passes, file `Decision: announce Obs 1.0 before its Dojo lab?` and wait.
   - paruff/uFawkesObs#502 (SLO burn-rate rework) stays _Blocked_ until paruff/uFawkesObs#600
     closes, because it edits the same rules.
   - paruff/uFawkesObs#182 (rollback drill) is on `Obs 1.0` but not a
     `release-blocker`: it doesn't gate the release.
   - Run the `release` agent for the announcement.
2. **Pipe 2.0** (goal paruff/uFawkesPipe#120). The steps are in Phase 4.
3. **DevX stable** (goal paruff/uFawkesDevX#146): a clean-host transcript of
   the latest 1.x (AC-DEVX-01), recorded as evidence in `acceptance.yml`. Then
   `/compatibility/` says "Verified".
4. **fawkes Alpha** (goal paruff/fawkes#1804). Only paruff/fawkes#2004 and
   paruff/fawkes#1797 move AC-FAWKES-03 (Claude Code only). paruff/fawkes#1909: give the
   weekly `golden-path-acceptance-tests` a cluster, or take it off the
   schedule, so its red means something.
5. **Suite mode** (paruff/uFawkes.dev#70): after Pipe 2.0, on a 16 GB host,
   with the commands in [`suite-mode.md`](suite-mode.md).
6. **Golden-path repos** (owner): apply the `main-protection` ruleset and
   squash-only merges per
   [`main-protection.md`](../suite-hygiene/main-protection.md), then add root
   `INTENT.md` files so AC-SUITE-01 and AC-SUITE-03 widen to ten.

### When a release goes wrong

- **A tag that fails an AC after it ships** gets a `release-blocker` issue
  on its release. The fix ships as the next patch tag. Tags are never deleted
  or moved.
- **A release tagged before its gate passed** is labelled "released, not yet
  verified" on `/compatibility/` until its ACs pass (Obs `v1.0.0` was one).
- **Alert changes** show, in the PR, that `ServiceDown` still fires on
  `docker stop`, so a quieter default never hides a real outage.
- **A failed release workflow** (no image, no notes): fix forward and rerun
  it. Don't retag by hand.

## Where this plan lives, and how it syncs with GitHub

| What                                     | Where                                                                                               |
| ---------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Goals, decisions, release bars, sequence | This folder                                                                                         |
| Live task status across the seven repos  | [Project #7, "uFawkes Suite Release"](https://github.com/users/paruff/projects/7)                   |
| Live release status page                 | [ufawkes.dev/status](https://ufawkes.dev/status/), built daily from `acceptance.yml` and Project #7 |
| One parent issue per release             | A `goal:` issue in the releasing repo; its tasks are sub-issues                                     |
| Suite-wide work                          | Issues in uFawkes.dev                                                                               |

**Sync rules:**

- **This doc lists no individual tasks.** Two task lists drift. The tasks
  are issues on Project #7.
- **The `Release` field is the scope.** uFawkesObs and most repos have no
  milestones; a release's issues are the Project #7 items with that
  `Release` value.
- **Routing labels** (`goal`, `claude-code`, `opencode`,
  `model:mimo-v2.6-flash`, `model:nemotron-3-ultra`, `model:claude-opus-5.5`)
  and `release-blocker` exist in all seven repos.
- **fawkes's milestones stay.** Only Alpha-epic children and fawkes's
  security issues join Project #7.
- **Post-release:** the `release` agent files a `measure:` issue and adds it
  to the Project. It tracks adoption plus the playbook's leading indicators
  where the repo emits them: intent-to-merge time, first-pass CI success rate,
  and eval pass rate.

### The board: statuses, gates and moves

Every suite repo's `AGENTS.md` links here and holds the two board commands:
command 1 lists the next _Ready for agent_ item for a routing label, command
2 lists _Needs human_ items with their Gate.

| Status          | Means                                                                                  | Moved here by                           |
| --------------- | -------------------------------------------------------------------------------------- | --------------------------------------- |
| Backlog         | Not ready, or its release is gated                                                     | "Item added" workflow; anyone           |
| Ready for agent | Has a routing label, a plan link and an exit criterion, and its release is not Blocked | Owner, or Claude Code on a `goal`       |
| In Progress     | Claimed. Move it here **before** starting, so no one else picks it                     | Whoever starts it                       |
| Needs human     | Waits on the owner: a decision, a PR to review and merge, or work only a human can do  | The agent, when it asks or opens the PR |
| Blocked         | Can't move until something named in the issue happens                                  | Anyone, with a `Blocked by` line        |
| Done            | Closed or merged                                                                       | Built-in workflows                      |

`In Progress` and `Done` keep these exact names: `scripts/suite-status.sh`
matches them. `scripts/setup-suite-board.sh` created these fields;
keep it to rebuild the board. `make status` reads the board, so its token
needs the `read:project` scope (`gh auth refresh -s read:project`).

**Order.** Command 1 sorts by `Priority` (P0 first), then issue number. An
item with no Priority sorts last; set one when an item must jump the queue.

**Gate** says which approval a _Needs human_ item waits on. Read it only with
that status. No Gate means work only a human can do (real secrets, a live host).

| Gate          | The owner is asked to                                       |
| ------------- | ----------------------------------------------------------- |
| intent        | Approve `docs/ai-sdlc/<feature>/intent.md`                  |
| spec          | Approve the spec and its acceptance criteria                |
| plan          | Approve the plan, or answer a `Decision:` question          |
| PR review     | Review the PR against `REVIEW.md`                           |
| merge/release | Merge, or tag the release once its acceptance criteria pass |

**Lifecycle.** Pick with command 1, or take the issue the owner points you at.
Move it to _In Progress_, then branch. The PR body says `Closes
owner/repo#N` and pastes the checks named in the repo's `REVIEW.md`; then move
the issue to _Needs human_ with Gate _PR review_. Changes requested: back to
_In Progress_. Stuck: _Blocked_, with a line `Blocked by owner/repo#N` in the
issue body. The owner merges; the issue closes and the board sets _Done_. An
_In Progress_ item with no commit or comment for 7 days goes back to _Ready
for agent_.

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
ship into each repo. This plan links to them instead of copying them. Both
follow [The AI-Native SDLC Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook)
(Claxton, Anthropic, 2026-08-21), called "the playbook" below.

- [`docs/ai-sdlc/README.md`](https://github.com/paruff/uFawkesAI/blob/main/docs/ai-sdlc/README.md):
  the `intent → spec → plan` chain and the CI artifact-chain gate. Every
  per-release folder this plan asks for follows it.
- [`docs/ai-sdlc/dojo-handoff.md` at `v2.1.0`](https://github.com/paruff/uFawkesAI/blob/v2.1.0/docs/ai-sdlc/dojo-handoff.md):
  how a release's plan becomes a Dojo lab, and how lab feedback becomes the
  next `intent` issue. paruff/uFawkesAI#251 removed it from the template's
  `main`; the suite keeps the `v2.1.0` version, and every Dojo lab in
  Phases 3–6 follows it (AC-DOJO-04).

## Who does what: the routing rubric

Every issue gets exactly one routing label (AC-SUITE-02). Pick the first row
that matches.

This is the playbook's "model routing" applied to the suite. Claude Code on a
`goal` works with the owner in real time, where judgment and live
verification matter. OpenCode on a labelled task takes a fully specified task
and is reviewed afterwards. One deliberate change from the playbook, which
routes code review to smaller models: here Claude Code reviews every OpenCode
PR, because free models make mistakes that look right and pass basic checks.

| Label                                 | Runs in                                             | Use it when the issue…                                                                                                                                                                                                              |
| ------------------------------------- | --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `goal` + `claude-code`                | Claude Code (Opus 5.5)                              | is a release, a decision or ADR, touches more than one repo, is security-sensitive, has an unknown root cause, or needs a real run to verify it (clean-host install, Kubernetes, a lab transcript). Parent issues are always `goal` |
| `opencode` + `model:nemotron-3-ultra` | OpenCode, `nemotron-3-ultra-free` ("Nemotron")      | is bounded to one repo, has a written spec or acceptance criteria, and needs reasoning across several files: a module rewrite, a test migration, doc consolidation, a known-target CI change                                        |
| `opencode` + `model:mimo-v2.6-flash`  | OpenCode, `opencode/mimo-v2.6-flash-free` ("flash") | is mechanical: one file or a grep-and-replace, a rename, links, front matter, labels. One command proves it's done                                                                                                                  |

**Guardrails for the free models:**

- **Never route secrets, credentials or security fixes to OpenCode.** Free
  tiers may retain prompts. These are always `goal`.
- **Escalate, don't retry.** A flash task that fails `make validate` twice
  moves to Nemotron. A Nemotron task that fails twice, or turns out to need
  a decision, becomes a `goal` child for Claude Code.
- **Claude Code reviews every OpenCode PR before merge.** The PR links its
  issue and pastes the validation output.
- **Write the issue for the model.** OpenCode issues name the exact files,
  the acceptance check, and what not to touch. If you can't write that
  down, it's a `goal`.

**Priorities.** P0 is a security hole or a broken release gate; P1 blocks the
next release; P2 is planned work for a later release; P3 is "when there's
time". AC-FAWKES-03's "P0 security issues" are exactly paruff/fawkes#2004 and
paruff/fawkes#1797.

## Phase 0 — Suite hygiene (gate: AC-SUITE-01, AC-SUITE-02, AC-SUITE-03, AC-SITE-01)

**Done.** Met on 2026-10-02 and rechecked on 2026-10-09
(paruff/uFawkes.dev#155, paruff/uFawkes.dev#176): every open issue on Project #7 carries one
routing label; the seven repos have a root `INTENT.md` and run the artifact
chain with their own code paths; no public entry point (each repo's README and
INTENT, and the site) presents a retired name as current. The owner scoped
AC-SUITE-01 to those entry points on 2026-10-02; wider docs are rechecked
before each announcement. ufawkessec and uFawkesRes are archived
(paruff/uFawkes.dev#68).

The status build lists board drift under `hygiene` in `suite_status.json`:
items _Done_ but open, closed but not _Done_, and open `release-blocker` or
security issues not on the board. It warns and doesn't fail.

## Phase 1 — AI 2.0, uFawkesAI `v2.0.0` (gate: AC-AI-01..09)

**Shipped 2026-10-14.** Goal paruff/uFawkesAI#145 is closed, every AC passed
at release, and the repos pin the image by digest (AC-AI-05). uFawkesAI has
since shipped `v2.2.0`; its next work is in uFawkesAI's own
[`v2.3.0` plan](https://github.com/paruff/uFawkesAI/blob/main/docs/ai-sdlc/v2.3.0/plan.md),
outside this suite plan.

## Phase 2 — Dojo 0.2 (gate: AC-DOJO-01..03)

**Shipped 2026-10-07 as `0.2.0`.** Goal paruff/uFawkesDojo#11 is closed.

## Phase 3 — Obs 1.0 + Dojo `0.3` (gate: AC-OBS-01..04, AC-DOJO-04)

`v1.0.0` was tagged 2026-10-14 before its gate passed; `v1.0.1`
(2026-10-18) carries the alert fix. The release finishes as `v1.0.x`; the
contract stays in uFawkesObs `docs/ai-sdlc/v1.0.0/`. Remaining steps are
Next step 1 above:

1. Close paruff/uFawkesObs#670 and paruff/uFawkesObs#671 (AC-OBS-02).
2. Record the clean-host transcripts (AC-OBS-01).
3. Dojo 0.3: Brown Belt Modules 13–16 (paruff/uFawkesDojo#42 to paruff/uFawkesDojo#45), one PR
   each, pinned to `v1.0.1`.
4. Announce with the `release` agent; the posts link to the Dojo lab
   (AC-OBS-04). Close paruff/uFawkesObs#600.

## Phase 4 — Pipe 2.0 + Dojo `0.4` (gate: AC-PIPE-01)

uFawkesPipe's own plan for this release is
[`docs/ai-sdlc/suite-pipeline-release/plan.md`](https://github.com/paruff/uFawkesPipe/blob/main/docs/ai-sdlc/suite-pipeline-release/plan.md).
In order:

1. paruff/uFawkesPipe#121: consolidate the specs and designs into
   `docs/ai-sdlc/v2.0.0/` (OpenCode).
2. paruff/uFawkesPipe#122 (owner decision; retitle it `Decision: …`): make
   `build-image` real, or drop the claim.
3. paruff/uFawkesPipe#125: nightly live acceptance (OpenCode).
4. paruff/uFawkesPipe#123: a real pipeline run on a sample repo, with
   `notify-obs` pointed at Obs `v1.0.1`. `notify-obs` reads four Woodpecker
   secrets (`otel_endpoint`, `otel_headers`, `dora_ingestion_url`,
   `dora_api_key`); a human sets them.
5. Dojo 0.4: Yellow Belt Modules 5–8 move to Woodpecker, which retires the
   Jenkins content.
6. Release and announce. Close paruff/uFawkesPipe#120.

## Phase 5 — DevX stable + Dojo `0.5` (gate: AC-DEVX-01)

The database question is decided (paruff/uFawkesDevX#57, ADR-0001): the
stack runs with no database service. Release Please has published stable
`v1.0.0`–`v1.2.0`, so this release is the first 1.x tag that passes
AC-DEVX-01.

1. A clean-host transcript of the latest 1.x (paruff/uFawkesDevX#146).
   uFawkesDevX's `live-acceptance.yml` runs `make up` on a fresh Linux runner
   on every release; its run link is the Linux half of the evidence.
2. Move the root spec, design and plan into `docs/ai-sdlc/<that version>/`.
3. Dojo 0.5: White Belt Modules 1, 3 and 4 move to uFawkesDevX.
4. Suite mode (paruff/uFawkes.dev#70), once Pipe 2.0 has shipped.

## Phase 6 — fawkes Alpha + Dojo `0.6` (gate: AC-FAWKES-01..04)

fawkes work runs in parallel with Phases 3–5. Only the release waits. The
Alpha items on Project #7, in order:

1. Security, Claude Code only: paruff/fawkes#2004 and paruff/fawkes#1797 (the gate's P0
   pair), then paruff/fawkes#684 (purge secrets from history), paruff/fawkes#1715 (design-system
   toolchain vulnerabilities) and paruff/fawkes#1569 (Terraform remote state). Only the
   first two gate Alpha.
2. Root-cause Grafana's datasource (paruff/fawkes#2130), then make DORA
   queryable (paruff/fawkes#1572, paruff/fawkes#1919, paruff/fawkes#1948).
3. Set up the tunnel (paruff/fawkes#1856) and do one continuous
   gitops-promote run (paruff/fawkes#1858). Alerting to chat: paruff/fawkes#1857.
4. paruff/fawkes#1909: a cluster for `golden-path-acceptance-tests`, or off
   the schedule.
5. Scope the README to Alpha and write `docs/ai-sdlc/tracer-bullet-alpha/`
   (paruff/fawkes#1808, the golden path itself).
6. Dojo 0.6: Green Belt graduation ("why Kubernetes now") and Tekton.
7. Release, announce, and add fawkes to the matrix as the graduation path.
   Close paruff/fawkes#1804.

### After Alpha: becoming uFawkesRes's successor (tracked, not promised)

These are not part of the Alpha gate, and no date is promised. uFawkesRes is
archived and its README names fawkes as a _partial_ successor. fawkes
already covers two of uFawkesRes's four roles: shared PostgreSQL (CloudNativePG,
`platform/apps/postgresql`) and ingress (`ingress-nginx`). Closing the gap
takes three upgrades:

1. **Valkey caching.** A shared cache service on the cluster.
2. **Single sign-on** across the platform's apps, the role Authelia had.
   Security-sensitive, so an ADR comes first.
3. **Beyond pre-alpha Kubernetes.** Local k3d evaluation works; cloud
   production doesn't (`v0.3.95`). The path to a cloud-capable Beta needs
   defining before anything depends on it.

When one lands, update the table in uFawkesRes's README.

## Verification Strategy

| Criterion        | Evidence                                       | Collected in            |
| ---------------- | ---------------------------------------------- | ----------------------- |
| AC-SUITE-01      | `scripts/checks/ac-suite-01.sh`                | Daily status build      |
| AC-SUITE-02      | `scripts/checks/ac-suite-02.sh`                | Daily status build      |
| AC-SUITE-03      | `scripts/checks/ac-suite-03.sh`                | Daily status build      |
| AC-SITE-01       | `scripts/checks/ac-site-01.sh`                 | Daily status build      |
| AC-SUITE-04      | paruff/uFawkes.dev#232, then `ac-suite-04.sh`  | Daily status build      |
| AC-SITE-02       | paruff/uFawkes.dev#233, then `ac-site-01.sh`   | Daily status build      |
| AC-AI-01..09     | Manifest and cosign output, template run       | uFawkesAI release notes |
| AC-DOJO-01..04   | Grep, lab transcripts, same-week releases      | Dojo release notes      |
| AC-OBS-01..04    | Clean-host transcripts, four live URLs         | Obs release notes       |
| AC-PIPE-01       | Real pipeline run output                       | Pipe release notes      |
| AC-DEVX-01       | ADR plus clean-host transcript                 | DevX release notes      |
| AC-FAWKES-01..04 | CI run, Grafana panels, closed security issues | fawkes release notes    |

Manual evidence is a link: a merged PR, a closed issue, an issue comment
(dated by the comment, for pasted transcripts) or a run URL with an
`evidence_date`. It goes stale after 30 days unless its release has shipped.

### Make commands

Run in uFawkes.dev. The first two are the gate for every PR here; the audits
read all the suite repos and change nothing.

| Command                     | Proves                                                        | Needs                       |
| --------------------------- | ------------------------------------------------------------- | --------------------------- |
| `make validate`             | Every pre-commit hook passes on every file                    | Nothing                     |
| `make build`                | The Jekyll site builds                                        | Bundler                     |
| `make status-check-drift`   | `spec.md` and `acceptance.yml` name the same criteria         | Nothing                     |
| `make design-check`         | Every design token pair meets its contrast floor              | Nothing                     |
| `make status`               | The acceptance checks run and write `_data/suite_status.json` | A token with `read:project` |
| `make shift-left-audit`     | PI-5 across the suite                                         | `gh`, signed in             |
| `make ci-determinism-audit` | PI-1 to PI-4 across the suite                                 | `gh`, signed in             |
| `make live-checks`          | The latest run of every scheduled workflow in the suite       | `gh`, signed in             |
| `make doctor`               | This clone's hooks are installed and its tools are present    | Nothing                     |

### Suite membership

Recorded in [`intent.md`](intent.md) (Revision 4). Both read-only audits
cover all ten repos:

| Check            | Command                              | Expected                                                                                                |
| ---------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------------- |
| Shift-left hooks | `make shift-left-audit`              | exit 0; the seven repos `ok` on every column, the three golden-path repos `n/a` plus a "no config" note |
| Main protection  | `scripts/check-branch-protection.sh` | exit 0 once Next step 6 is done; until then exit 1 with three departures per golden-path repo           |

AC-SUITE-01 and AC-SUITE-03 cover the seven repos. They widen to ten in the
same change that gives the golden-path repos a root `INTENT.md` and the
artifact chain.

## Risks

| Risk                                                                    | Mitigation                                                                                             |
| ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| A release is tagged before its gate passes                              | "When a release goes wrong": label it "released, not yet verified" and finish it with patch tags       |
| Free models produce plausible but wrong content (especially curriculum) | The "run it for real" rule, Claude Code review on every OpenCode PR, and escalation after two failures |
| A secret or credential ends up in a free-tier prompt                    | Security and credential issues are always `goal`                                                       |
| fawkes's issues swamp the suite Project                                 | Only Alpha-epic children and fawkes's security issues join it                                          |
| One maintainer across seven repos                                       | One `goal` in flight at a time in Claude Code; OpenCode tasks run in parallel underneath it            |
| The plan and the Project drift apart                                    | This doc holds no task list; the status build flags board drift daily                                  |
