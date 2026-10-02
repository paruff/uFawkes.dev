# Spec: uFawkes Suite Release

**Traces to:** [`intent.md`](intent.md) | **Status:** Draft | **Revision:** 4

This file defines _what "released" means_ for each of the seven repos. The
order and phases are in [`plan.md`](plan.md), and live status is in
[Project #7](https://github.com/users/paruff/projects/7).

## 1. Documentation requirements per repo

Every repo follows uFawkesAI's `intent → spec → plan` convention, scaled
to the size of the work:

| Level                | Documents                                                                                                 | Where                     |
| -------------------- | --------------------------------------------------------------------------------------------------------- | ------------------------- |
| **Suite**            | intent, spec, plan                                                                                        | this folder               |
| **Product (repo)**   | `INTENT.md`: what it is and isn't, users, direction. Lasting design is in `docs/ARCHITECTURE.md` and ADRs | repo root                 |
| **Release**          | intent, spec (with the semver contract), plan. Required before the version tag                            | `docs/ai-sdlc/vX.Y.Z/`    |
| **Feature or unit**  | `intent.md` always; `spec.md` when it has acceptance criteria; `plan.md` when it changes code             | `docs/ai-sdlc/<feature>/` |
| **Bug fix or chore** | The issue is the intent and the regression test is the spec. No folder                                    | the issue and PR          |

Each level links to the one above it: a feature's intent names its
release, and a release's intent names this plan. Each `spec.md` has a
`## Design` section. AC-SUITE-03 makes this enforceable.

| Repo            | `INTENT.md`                                                     | Release docs                                    | Remaining doc cleanup                                                                                             |
| --------------- | --------------------------------------------------------------- | ----------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **uFawkes.dev** | ✅                                                              | `docs/ai-sdlc/suite-release/` (this folder)     | Add `/ai/` and `/fawkes/` pages to the nav; retire `/dora/` (ufawkesdora archived) and `/sec/` (merged into Pipe) |
| **uFawkesAI**   | ❌ (corrected 2026-10-01: only `docs/ai-sdlc/intent.md` exists) | `docs/ai-sdlc/v2.0.0/` ❌                       | Close #36 (superseded by this folder)                                                                             |
| **uFawkesDojo** | ✅                                                              | `docs/ai-sdlc/compose-curriculum/` ✅; `0.2` ❌ | Rebase `compose-curriculum/plan.md` on the new order: Dojo `0.2` before any stack lab                             |
| **uFawkesObs**  | ✅                                                              | `docs/ai-sdlc/v1.0.0/` ✅                       | #534 (dead uFawkesRes panels, `TBD` SQL in the tier table)                                                        |
| **uFawkesPipe** | ✅                                                              | `docs/ai-sdlc/v2.0.0/` ❌                       | Consolidate the 3 spec files, 2 design files and `plan-for-the-day.md`                                            |
| **uFawkesDevX** | ✅                                                              | `docs/ai-sdlc/v0.1.0/` ❌                       | Move root `specification.md`/`design.md`/`plan.md` in; remove uFawkesRes references                               |
| **fawkes**      | ❌                                                              | `docs/ai-sdlc/tracer-bullet-alpha/` ❌          | Mark `ADR-004 jenkins 4 ci` superseded by ADR-036                                                                 |

## 2. Release acceptance criteria

Every criterion names its evidence. "Real run" means a transcript or CI log
from an actual execution, linked from the release notes, never a described
or simulated one.

### Suite-wide

#### AC-SUITE-01: No public claim is contradicted by a repo

- **Expected:** No public doc in the seven repos presents Jenkins, uFawkesRes,
  ufawkesdora, ufawkessec or "four key metrics" as current
- **Verification:** `grep -rniE "jenkins|ufawkesres|four key metrics"` across
  the public docs returns only historical, superseded or explicitly labeled
  mentions
- **Gate for:** every announcement (it's re-checked before each one)
- **Scoped recheck 2026-10-02, public entry points only** (each repo's README
  and INTENT, and the ufawkes.dev pages): 12 lines matched with no qualifier
  on the line. Reading each in context, **7 were real false claims** (uFawkesDORA
  and uFawkesSec listed as live or planned repos, Jenkins listed as a fawkes
  component, and fawkes's "four key metrics automated from day one") in
  uFawkesAI, uFawkesPipe and fawkes. They are fixed in uFawkesAI#143,
  uFawkesPipe#116 and fawkes#2185. The other 5 were already labelled
  ("not Jenkins", "stale", a deprecation footnote, or a criterion's own name).
  ufawkes.dev itself had none left after #81. All three merged and `main` was re-scanned on 2026-10-02: no real violation
  remains. **Owner decision, 2026-10-02: this gate means public entry points, so
  AC-SUITE-01 is met for Phase 0.** The wider count below is handled in each
  repo's own phase and re-checked before each announcement.
- **Full count 2026-10-02, beyond this gate's scope:** Counting lines that name a retired term
  with no qualifier (deprecated, historical, merged, formerly and similar)
  on each repo's `main`, excluding the suite plan folders and ADRs. Each
  repo's debt belongs to its own phase:

  | Repo        | Lines | Mostly                                     | Fixed in                                      |
  | ----------- | ----- | ------------------------------------------ | --------------------------------------------- |
  | uFawkes.dev | 35    | Internal planning docs; one live claim     | Phase 0 (live claim fixed in #81)             |
  | uFawkesAI   | 43    | uFawkesDORA and uFawkesSec mentions        | Phase 1                                       |
  | uFawkesObs  | 147   | Jenkins (61), uFawkesDORA (66), uFawkesRes | Phase 3 (#534 covers the dead Res panels)     |
  | uFawkesPipe | 79    | uFawkesSec (41), uFawkesRes (24), Jenkins  | Phase 4                                       |
  | uFawkesDevX | 58    | uFawkesRes in design, plan and spec files  | Phase 0 (live docs in DevX #69); Phase 5 rest |
  | uFawkesDojo | 162   | Jenkins (147), "four key metrics" (13)     | Phase 2 (#19, Jenkins labeling)               |
  | fawkes      | 859   | Jenkins (824), "four key metrics" (19)     | Phase 6                                       |

  The count is a ceiling, not a verdict: each line still needs reading to
  decide whether it is a live claim. The only live false claim found on
  ufawkes.dev itself was Obs's "Jenkins integration" (fixed in #81).

#### AC-SUITE-02: Every tracked issue is routed

- **Expected:** Every open issue on Project #7 carries exactly one routing
  label: `goal` (Claude Code), `model:nemotron-3-ultra` or
  `model:mimo-v2.6-flash` (OpenCode). The rubric is in `plan.md`
- **Verification:** A Project view filtered to items with none of the three
  labels is empty
- **Gate for:** Phase 0

#### AC-SUITE-03: Every repo follows, and enforces, the document levels

- **Expected:** All seven repos have a root `INTENT.md`. Each runs
  uFawkesAI's artifact-chain check in CI, configured with its own code
  paths (the template assumes `src/`, but these repos keep code in Jekyll
  files, Compose stacks, scripts and Kubernetes manifests). Each has a
  `docs/ai-sdlc/vX.Y.Z/` folder before it tags `vX.Y.Z`
- **Verification:** the root-file check passes in every repo, the
  artifact-chain job runs on each repo's PRs, and the release gate's
  checklist links the release folder
- **Met 2026-10-02:** all seven repos have a root `INTENT.md` and run the
  check on their PRs with their own paths (verified on each repo's `main`).
  Not yet a required check
- **Gate for:** each repo's next release tag

#### AC-SITE-01: The site lists all seven repos and the matrix is current

- **Expected:** ufawkes.dev has a page for each stack, uFawkesAI and fawkes,
  plus the Dojo link. `/compatibility/` lists every released version and
  what it was verified with ("standalone" is valid). It includes the
  devcontainer image version each stack was tested in
- **Verification:** Page live; updated in the same release that changes it

### Release 1 — uFawkesAI `v2.0.0`

#### AC-AI-01: The devcontainer image can be pinned

- **Expected:** A `v2.0.0` tag publishes `ghcr.io/paruff/ufawkesai-devcontainer:2.0.0`
  and `:2.0`, signed. Its digest is in the GitHub Release
- **Verification:** `docker manifest inspect` succeeds from an
  unauthenticated machine, and `cosign verify` passes using the documented
  steps (#111)

#### AC-AI-02: The template works from "Use this template"

- **Scenario:** A new repo created from the template, opened in the `2.0.0`
  devcontainer
- **Expected:** Each of the four documented agent harnesses starts. The
  `intent → spec → plan` flow produces files the plan command accepts.
  The placeholder audit finds nothing unfilled (#28), and `make validate`
  passes
- **Verification:** Real run transcript

#### AC-AI-03: The 2.0 contract and upgrade path are written down

- **Expected:** `docs/ai-sdlc/v2.0.0/spec.md` states the contract (see
  `intent.md`, Still open #1) and an upgrade note from 1.x that covers the
  npm package rename and the removed gitops variant
- **Verification:** Linked from the release notes

#### AC-AI-04: Capability claims match what ships

- **Expected:** The README has two maps. The first is the harness anatomy:
  each of the six components (instructions, tools/MCP, sandbox,
  orchestration and model routing, hooks, observability) names the file or
  tool in the template or image that provides it, or says "not provided".
  The second maps each feature to the DORA AI capability it supports.
  A third map lists the playbook's six stages, each marked provided,
  partial or not provided, with the file that provides it. None of the
  three maps claims anything that isn't in the image or template. The
  README and `docs/ai-sdlc/README.md` cite the playbook and the paper as
  upstream references
- **Verification:** Every claimed tool appears in the image's tool list or
  the template's tree

#### AC-AI-05: Every suite repo pins the image

- **Expected:** All seven repos' `.devcontainer/devcontainer.json` use
  `:2.0.0` or a digest, not `:latest`
- **Verification:** `grep -r ufawkesai-devcontainer` across the suite shows
  no `:latest`
- **Lands:** within one week after the release; it doesn't block the tag

#### AC-AI-07: Tests and evals both gate merges

- **Expected:** The unit tests and the agent evals
  (`.agents/evals/`, `scripts/run-evals.sh`) are required checks on
  `main`. The evals also run on a schedule and on every change to rule
  files, skills or hooks, as the playbook prescribes. Each eval task has an
  explicit rubric that scores task success,
  tool use and trajectory compliance against `baseline.json`. A template
  repo inherits both. Per the paper, without both, the practice is still
  vibe coding
- **Verification:** Branch protection lists the eval job; a deliberately
  broken rule file fails it in a test PR

#### AC-AI-09: One hook gate, run the same way everywhere

- **Expected:** `.pre-commit-config.yaml` is the only hook definition. It
  runs locally (hooks pre-installed in the devcontainer image) and in the
  Pre-flight workflow, which is a required check in every suite repo.
  pre-commit.ci is retired: it duplicated Pre-flight, its skip list drifted
  on template syncs, and it couldn't run the suite's own `jq`-based hooks.
  A monthly workflow opens a `pre-commit autoupdate` PR
- **Verification:** no `ci:` block in any suite repo's config; branch
  protection lists Pre-flight; the devcontainer runs
  `pre-commit run --all-files` offline on first open

#### AC-AI-06: Delivery events reach uFawkesObs, or the claim goes

- **Expected:** The `dora-events` emitter works from a checkout as well as
  in CI, and a real event is queryable in uFawkesObs's Loki with the LogQL
  documented ([`dora-events-portability`](https://github.com/paruff/uFawkesAI/blob/main/docs/ai-sdlc/dora-events-portability/intent.md),
  GAP-01..03). If that isn't verified by the tag, the README and
  `docs/UFAWKES_INTEGRATION.md` stop claiming uFawkesAI feeds uFawkesObs
- **Verification:** Real run, recorded as a uFawkesAI ↔ uFawkesObs row in
  the compatibility matrix

#### AC-AI-08: The CDE's developer experience is measured, not asserted

Derived from the DevEx evidence in `docs/research-foundation.md` (DevEx
2023/2024, SPACE, Google's build-latency and onboarding studies, METR and
Google's AI RCTs).

- **Feedback loops:** CI measures cold start (image pull to ready) and warm
  start (container restart to ready) for the image on every release. The
  release notes publish both. A regression of more than 10% fails the
  release; Google found every latency improvement helps, so there's no
  fixed target
- **Cognitive load:** one entry point ("Reopen in Container", or one `make`
  target), one config source for all four harnesses (harness parity check
  passes), and a static rule file of one page or less, per the playbook
- **Flow:** `postCreateCommand` never prompts. Every failure prints the fix
- **Outcomes, not just speed:** the Dojo "Start here" lab records time from
  "Use this template" to first merged PR, plus a three-question survey
  (ease, confidence, would-recommend). That covers three SPACE dimensions:
  efficiency, satisfaction and performance
- **No unmeasured productivity claims.** The README states no speedup
  percentage. Perceived and measured time can diverge by about 40 points
  (METR)
- **Verification:** the benchmark job's output in the release notes, plus
  the first cohort's lab results in `dojo-feedback.md`

### Release 2 — uFawkesDojo `0.2`

#### AC-DOJO-01: The curriculum is accurate

- **Expected:** Five DORA metrics everywhere (#19). Every module that still
  teaches Jenkins says so at the top and names the replacement module's
  release. Every lab, video or community link that doesn't exist is either
  removed or labeled "not built yet"
- **Verification:** `grep` for "four key", unlabeled "Jenkins" and
  `[VIDEO PLACEHOLDER]` returns nothing unlabeled

#### AC-DOJO-02: The "Start here" lab is real

- **Expected:** A first lab clones a template-generated repo pinned to
  uFawkesAI `v2.0.0`, opens the devcontainer, and walks through one
  `intent → spec → plan` cycle. A `validate.sh` checks the result
- **Verification:** Real run transcript in the lab's PR, and
  `content-integrity.yml` passes

#### AC-DOJO-03: The authoring guide covers the evidence for self-paced learning

`docs/module-authoring-guide.md` already exists and already covers the
"run it for real" rule, worked examples, short theory blocks, retrieval
questions, spacing boundaries, immediate feedback and badges. Dojo `0.2`
extends it, without rewriting it, to close the gaps against _Make It Stick_
(Brown, Roediger & McDaniel, 2014) and the research on self-paced online
learning:

- **Expected:**
  - **Cumulative, spaced retrieval:** each module opens with recall
    questions from earlier modules, not only its own
  - **Interleaving:** later belts mix problem types rather than practising
    one tool at a time
  - **Fading:** worked examples fade into open practice as belts advance
    (the expertise-reversal effect)
  - **Calibration:** learners predict before a lab and compare afterwards,
    to counter illusions of competence
  - **Self-regulation supports:** time estimates, a plan-your-sessions
    prompt and visible progress. Self-paced online courses lose most
    learners without these
  - **Citations corrected:** Crissman (2006) is a dissertation reporting
    d ≈ 0.57. The PR template links the guide
- **Verification:** each new item cites its source in the guide; Dojo
  `0.2`'s "Start here" lab passes the extended checklist

#### AC-DOJO-04: Each later release ships its lab, built from its plan

- **Expected:** Dojo `0.3`–`0.6` each add the lab for the stack released
  alongside it, pinned to that tag (`git clone --branch vX.Y.Z`). The
  stack's announcement links to it. Each lab follows uFawkesAI's
  [`dojo-handoff.md`](https://github.com/paruff/uFawkesAI/blob/main/docs/ai-sdlc/dojo-handoff.md) mapping: one exercise step per
  row of the release plan's Verification Strategy, one `record_test` per
  spec AC in `validate.sh`, and a provenance header naming the source
  `docs/ai-sdlc/<release>/` and commit
- **Verification:** Same-week Dojo release; the announcement contains the
  lab link; `validate.sh` check names match the release spec's AC ids

### Release 3 — uFawkesObs `v1.0.0`

#### AC-OBS-01: Installs cleanly from its README

- **Scenario:** A clean Linux host and a clean macOS host, with only Docker
  20.10+ and Compose v2
- **Expected:** The README Quick Start alone brings every service to
  healthy, and every default dashboard panel shows data. No "datasource not
  found" errors (#534)
- **Verification:** Real run transcripts on both hosts

#### AC-OBS-02: No open release blockers

- **Expected:** The `v1.0.0` milestone has zero open `release-blocker`
  issues. #534 joins it
- **Verification:** The Project's Blockers view

#### AC-OBS-03: The contract is written down

- **Status:** ✅ `docs/ai-sdlc/v1.0.0/` exists. Verify it states the
  contract in `intent.md` and the 0.4.x upgrade note before the tag

#### AC-OBS-04: Announced everywhere, consistently

- **Expected:** The GitHub Release, the ufawkes.dev Obs page, a dev.to post
  and a LinkedIn post all show the same version and link to the same notes
  and the Dojo `0.3` lab. uFawkesAI's `release` agent produces them
- **Verification:** All four URLs recorded on the release's Project item

### Release 4 — uFawkesPipe `v2.0.0`

#### AC-PIPE-01: Claims only what works

- **Expected:** `build-image` is either a real CNB build that produces an
  image or removed from the README's features. The release notes explain
  the jump from 1.x beta to `v2.0.0`
- **Verification:** A real pipeline run on a sample repo. The `notify-obs`
  step is verified against a released Obs version, recorded in the matrix

### Release 5 — uFawkesDevX `v0.1.0`

#### AC-DEVX-01: Runs without uFawkesRes

- **Expected:** An ADR records the #57 decision. `make up` brings up Coder
  and Backstage against storage defined inside the documented setup
- **Verification:** Clean-host run transcript

### Release 6 — fawkes Tracer Bullet Alpha

#### AC-FAWKES-01: Commit to staging works in one clean run

- **Expected:** #1804's scope passes end to end in one continuous run: push
  → build → scan → GitOps PR → ArgoCD sync to staging (#1858)
- **Verification:** One CI run plus ArgoCD sync history, linked

#### AC-FAWKES-02: Two DORA metrics are queryable

- **Expected:** Deployment frequency and lead time for changes, both for the
  tracer-bullet service, show in Grafana from native PromQL (#1572, #1919).
  Grafana can query its own Prometheus (#2130)
- **Verification:** Screenshot plus the PromQL behind each panel

#### AC-FAWKES-03: No known P0 security issues

- **Expected:** #2004 (extract-zip) and #1797 (`CHANGE_ME_*` credentials)
  are closed
- **Verification:** Both issues closed with linked PRs

#### AC-FAWKES-04: Public claims are scoped to Alpha

- **Expected:** fawkes's README says what Alpha proves and lists Beta and
  Production as not yet built. ADR-004 is marked superseded
- **Verification:** AC-SUITE-01 grep, plus a README review

## 3. Out of scope

New stack features, fawkes Beta/Production (the Valkey, SSO and
cloud-readiness gaps that would make fawkes uFawkesRes's full successor are
tracked in `plan.md` Phase 6, not gated), and Dojo modules for stacks that
haven't released yet. The Dojo's `compose-curriculum` spec governs module
content within this ordering.
