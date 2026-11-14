# Spec: uFawkes Suite Release

**Traces to:** [`intent.md`](intent.md) | **Status:** Draft | **Revision:** 6

This file defines _what "released" means_ for each of the seven product repos
(a release is the first version that passes its criteria; see `intent.md`,
"What counts as a release"). The
order and phases are in [`plan.md`](plan.md), and live status is in
[Project #7](https://github.com/users/paruff/projects/7).

## 1. Documentation requirements per repo

Every repo follows uFawkesAI's `intent → spec → plan` convention, scaled
to the size of the work:

| Level                | Documents                                                                                                 | Where                     |
| -------------------- | --------------------------------------------------------------------------------------------------------- | ------------------------- |
| **Suite**            | intent, spec, plan                                                                                        | this folder               |
| **Product (repo)**   | `INTENT.md`: what it is and isn't, users, direction. Lasting design is in `docs/ARCHITECTURE.md` and ADRs | repo root                 |
| **Release**          | intent, spec (with the semver contract), plan. Required before the version is marked verified             | `docs/ai-sdlc/vX.Y.Z/`    |
| **Feature or unit**  | `intent.md` always; `spec.md` when it has acceptance criteria; `plan.md` when it changes code             | `docs/ai-sdlc/<feature>/` |
| **Bug fix or chore** | The issue is the intent and the regression test is the spec. No folder                                    | the issue and PR          |

Each level links to the one above it: a feature's intent names its
release, and a release's intent names this plan. Each `spec.md` has a
`## Design` section. AC-SUITE-03 makes this enforceable.

Every release `spec.md` also has these two sections, and every release
`plan.md` has the third:

| Section                                              | In        | Holds                                                                                                                                                 |
| ---------------------------------------------------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `## Interfaces`                                      | `spec.md` | The repo's rows from "Cross-repo interface contracts" below, by link, plus anything it provides that isn't suite-wide. A repo with none says so       |
| `## Pipeline invariants`                             | `spec.md` | A link to "Pipeline invariants" below, then the repo's own invariants and each departure from the suite list, with the issue that closes it           |
| `### Make commands` under `## Verification Strategy` | `plan.md` | One row per command: what it proves and what it needs (nothing, Docker, a running stack, a cluster). Only targets that exist in the repo's `Makefile` |

The suite lists below are the single copy. A repo's spec links to its rows
and doesn't restate them, so a contract changes in one place.

### Cross-repo interface contracts

A contract is anything one suite repo reads from another. Changing one
without its consumers is a breaking change for the provider's release.

| Contract                                                                                                                               | Provider    | Consumers                                                                                                                                                           | Defined in (provider repo)                                                                                                                   | How a consumer pins it                                                                                                                                                                                         |
| -------------------------------------------------------------------------------------------------------------------------------------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Reusable workflows: the inputs and outputs of `reusable-*.yml`                                                                         | uFawkesPipe | all six other repos                                                                                                                                                 | `README.md`, "Reusable workflows"; each file's `workflow_call` block                                                                         | 40-character commit SHA plus a `# vX.Y.Z` comment; one release across the suite, moved by `scripts/suite-bump.sh`                                                                                              |
| `ufawkes-ci` CI job image                                                                                                              | uFawkesPipe | all seven repos                                                                                                                                                     | `images/ci/`                                                                                                                                 | `ghcr.io/paruff/ufawkes-ci@sha256:…`; a tag alone is rejected                                                                                                                                                  |
| `.fawkespipe.yml` pipeline contract                                                                                                    | uFawkesPipe | uFawkesDevX golden-path templates; any application repo                                                                                                             | `docs/pipeline-contract.md`                                                                                                                  | The uFawkesPipe release tag the generator ran from                                                                                                                                                             |
| Pipeline trigger from uFawkesDevX's Score service (`PIPELINE_WEBHOOK_URL`)                                                             | uFawkesPipe | uFawkesDevX                                                                                                                                                         | **Not defined.** uFawkesDevX's `.env.example` calls the URL and payload provisional (paruff/uFawkesPipe#217)                                 | Unset by default; AC-PIPE-01 and AC-DEVX-01 don't depend on it                                                                                                                                                 |
| `fawkes-space` devcontainer image                                                                                                      | uFawkesAI   | the six other repos                                                                                                                                                 | `docs/ai-sdlc/v2.0.0/spec.md` (AC-AI-01, AC-AI-05)                                                                                           | `fawkes-space:X.Y.Z@sha256:…` in `.devcontainer/`                                                                                                                                                              |
| Template files: the artifact-chain workflow and script, `.pre-commit-config.yaml` base, `AGENTS.md` conventions                        | uFawkesAI   | the six other repos                                                                                                                                                 | `docs/ai-sdlc/README.md`                                                                                                                     | Copied from a uFawkesAI release; `.artifact-chain-paths` is per repo and never overwritten                                                                                                                     |
| DORA event ingestion: endpoints, event types, required fields                                                                          | uFawkesObs  | uFawkesPipe (`notify-obs`). uFawkesAI's `dora-events` emitter writes a log line to Loki (AC-AI-06) and doesn't post to `/event`, so it isn't a consumer of this row | `dora/events/*.schema.json`; `docs/CONTRACTS.md` §1 describes them. uFawkesPipe mirrors the schemas in `contracts/dora-events/*.schema.json` | A released uFawkesObs version, recorded in the compatibility matrix. No copy is synced automatically: on 2026-11-13 uFawkesPipe's mirror and uFawkesAI's test copy both differed from uFawkesObs (AC-SUITE-04) |
| OTLP receivers (`4317` gRPC, `4318` HTTP) and metric routing                                                                           | uFawkesObs  | uFawkesPipe                                                                                                                                                         | `docs/CONTRACTS.md` §2                                                                                                                       | A released uFawkesObs version                                                                                                                                                                                  |
| Compose surface: services, published ports, `.env.example` variables                                                                   | uFawkesObs  | uFawkesDojo labs; suite mode ([`suite-mode.md`](suite-mode.md))                                                                                                     | `docs/ai-sdlc/v1.0.0/spec.md`, "Public contract" and "Semver rules"                                                                          | The release tag                                                                                                                                                                                                |
| Release tags of each stack                                                                                                             | each stack  | uFawkesDojo (a lab's `**Runs against**` line and its clone step)                                                                                                    | The repo's GitHub Releases                                                                                                                   | `--branch vX.Y.Z`; never `main` (Dojo AC-003, AC-006, AC-007)                                                                                                                                                  |
| Files on `main` that the status checks read: `INTENT.md`, `README.md`, `.github/workflows/artifact-chain.yml`, `.artifact-chain-paths` | each repo   | uFawkes.dev (`scripts/checks/`)                                                                                                                                     | §2, AC-SUITE-01 and AC-SUITE-03                                                                                                              | Read from `main` daily; a rename fails the status build                                                                                                                                                        |

### Pipeline invariants

These hold on every suite repo's `main`. Each names the check that proves it,
so none rests on a reviewer noticing.

| #     | Invariant                                                                                                                                                                                                               | Proven by                                                           |
| ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| PI-1  | Every `uses:` of an action or a reusable workflow outside the repo pins a 40-character commit SHA, and every image pins `@sha256`                                                                                       | `make ci-determinism-audit`, column `unpinned`                      |
| PI-2  | Every repo calls uFawkesPipe's reusables at one release, and keeps no local copy of one                                                                                                                                 | `make ci-determinism-audit`, columns `pipe_refs` and `local_copies` |
| PI-3  | The hook job runs in `ufawkes-ci` at one digest across the suite, built on the uFawkesAI release the devcontainer pins                                                                                                  | `make ci-determinism-audit`, columns `ci_image` and `release_match` |
| PI-4  | No step fails silently: no `continue-on-error: true` or `\|\| true` unless `.pipeline.yml` lists it under `informational:`                                                                                              | `make ci-determinism-audit`, column `silent`                        |
| PI-5  | `.pre-commit-config.yaml` is the only hook definition, and CI runs it as a required check (AC-AI-09)                                                                                                                    | `make shift-left-audit`                                             |
| PI-6  | `main` has the `main-protection` ruleset: a pull request, no force push, no deletion, linear history, and the hook job and `🔗 Artifact Chain` as required checks ([the standard](../suite-hygiene/main-protection.md)) | `scripts/check-branch-protection.sh`                                |
| PI-7  | The repo has its own `.artifact-chain-paths`, so the artifact chain checks the repo's real code paths                                                                                                                   | `scripts/checks/ac-suite-03.sh`                                     |
| PI-8  | Every PR to `main` passes `main-ci-guard.yml`                                                                                                                                                                           | No check yet (paruff/uFawkes.dev#228)                               |
| PI-9  | Every CI job starts with a `job-start` step and ends with a `job-finish` step that runs `if: always()`                                                                                                                  | No check yet (paruff/uFawkes.dev#228)                               |
| PI-10 | Release Please cuts every release tag. An agent never merges, never pushes to `main` and never passes `--no-verify`                                                                                                     | PI-6; the `commit-msg` hook                                         |

The audits print a matrix and exit non-zero only when the script itself
breaks, so a column that isn't `ok` is the failure to act on.

**Known departures, read from each repo's `main` on 2026-11-13.** The audits
above don't cover these yet:

- **PI-3:** uFawkesAI pins a different `ufawkes-ci` digest from the other six
  repos (paruff/uFawkesAI#289).
- **PI-8:** uFawkesDojo has no `main-ci-guard.yml` (paruff/uFawkesDojo#126).
  uFawkesAI's guard is a local script, not uFawkesPipe's reusable
  (paruff/uFawkesAI#289). uFawkesDevX's guard watches `ci.yml`, not the
  pipeline that runs the reusables (paruff/uFawkesDevX#152).
- **PI-9:** jobs without both stamps in uFawkesObs (11 of its 16 workflow files
  have neither, paruff/uFawkesObs#720), fawkes (paruff/fawkes#2313), uFawkesAI
  (paruff/uFawkesAI#289), uFawkesDojo (paruff/uFawkesDojo#126) and uFawkesDevX
  (paruff/uFawkesDevX#152). The stamps are log lines that nothing reads; what
  consumes them is decided with paruff/uFawkes.dev#228.

### Make verification commands

`make validate` is each repo's local gate. It runs at least
`pre-commit run --all-files`, needs no running stack or cluster, and exits
non-zero on any failure. `make test` runs the tests that need nothing running.
`make doctor` reports whether the clone's hooks are live. Checks that need a
stack or a cluster get their own targets, named in the repo's release plan.
Until a repo's `make validate` meets this, its plan names the command that
does the same job.

| Repo            | `INTENT.md`                                                     | Release docs                                    | Remaining doc cleanup                                                                                             |
| --------------- | --------------------------------------------------------------- | ----------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **uFawkes.dev** | ✅                                                              | `docs/ai-sdlc/suite-release/` (this folder)     | Add `/ai/` and `/fawkes/` pages to the nav; retire `/dora/` (ufawkesdora archived) and `/sec/` (merged into Pipe) |
| **uFawkesAI**   | ❌ (corrected 2026-10-01: only `docs/ai-sdlc/intent.md` exists) | `docs/ai-sdlc/v2.0.0/` ❌                       | Close paruff/uFawkesAI#36 (superseded by this folder)                                                             |
| **uFawkesDojo** | ✅                                                              | `docs/ai-sdlc/compose-curriculum/` ✅; `0.2` ❌ | Rebase `compose-curriculum/plan.md` on the new order: Dojo `0.2` before any stack lab                             |
| **uFawkesObs**  | ✅                                                              | `docs/ai-sdlc/v1.0.0/` ✅                       | paruff/uFawkesObs#534 (dead uFawkesRes panels, `TBD` SQL in the tier table)                                       |
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
- **Scope (owner decision, 2026-10-02):** public entry points: each repo's
  README and INTENT, and the ufawkes.dev pages
- **Verification:** `bash scripts/checks/ac-suite-01.sh` returns only
  historical, superseded or explicitly labelled mentions
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

  | Repo        | Lines | Mostly                                     | Fixed in                                                   |
  | ----------- | ----- | ------------------------------------------ | ---------------------------------------------------------- |
  | uFawkes.dev | 35    | Internal planning docs; one live claim     | Phase 0 (live claim fixed in #81)                          |
  | uFawkesAI   | 43    | uFawkesDORA and uFawkesSec mentions        | Phase 1                                                    |
  | uFawkesObs  | 147   | Jenkins (61), uFawkesDORA (66), uFawkesRes | Phase 3 (paruff/uFawkesObs#534 covers the dead Res panels) |
  | uFawkesPipe | 79    | uFawkesSec (41), uFawkesRes (24), Jenkins  | Phase 4                                                    |
  | uFawkesDevX | 58    | uFawkesRes in design, plan and spec files  | Phase 0 (live docs in paruff/uFawkesDevX#69); Phase 5 rest |
  | uFawkesDojo | 162   | Jenkins (147), "four key metrics" (13)     | Phase 2 (paruff/uFawkesDojo#19, Jenkins labeling)          |
  | fawkes      | 859   | Jenkins (824), "four key metrics" (19)     | Phase 6                                                    |

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
  `docs/ai-sdlc/vX.Y.Z/` folder before `vX.Y.Z` is marked verified
- **Verification:** the root-file check passes in every repo, the
  artifact-chain job runs on each repo's PRs, and the release gate's
  checklist links the release folder
- **Gate for:** each repo's next verified release

#### AC-SITE-01: The site lists all seven repos and the matrix is current

- **Expected:** ufawkes.dev has a page for each stack, uFawkesAI and fawkes,
  plus the Dojo link. `/compatibility/` lists every released version and
  what it was verified with ("standalone" is valid). It includes the
  devcontainer image version each stack was tested in
- **Verification:** `scripts/checks/ac-site-01.sh`: the pages exist and each
  matrix row's release is the repo's newest GitHub Release

#### AC-SUITE-04: Every copy of a DORA event schema matches uFawkesObs

- **Expected:** Each DORA event schema a suite repo keeps (uFawkesPipe's
  `contracts/dora-events/`, and the `scripts/testdata/` copy beside each
  `emit-dora-event.sh`) has the same properties and `required` list as
  uFawkesObs's `dora/events/*.schema.json` at the release it names
- **Must not:** Validate an event against a local copy that uFawkesObs would
  reject
- **Verification:** `bash scripts/checks/ac-suite-04.sh`. The script doesn't
  exist yet (paruff/uFawkes.dev#232); until it does, the evidence is that
  issue, closed
- **Gate for:** none. Rolling, like AC-DOJO-04: it is listed last in
  `acceptance.yml` so it never holds "Next release"
- **Read 2026-11-13:** uFawkesPipe's deployment schema lacks
  `first_commit_at` and `pr_merged_at`. uFawkesAI's copy requires
  `deployment_intent`, which uFawkesObs's schema doesn't define and so
  rejects

#### AC-SITE-02: Each stack page states the version the matrix states

- **Expected:** A version named on a stack page (`/obs/`, `/pipe/`, `/devx/`,
  `/ai/`, `/fawkes/`) equals that repo's row in `/compatibility/`. A page for
  a retired stack (`/dora/`, `/sec/`) redirects, or carries no live badge and
  no empty Quick start card
- **Verification:** `scripts/checks/ac-site-01.sh`, extended to read each
  page's version (paruff/uFawkes.dev#233); until then, that issue, closed
- **Gate for:** none. Rolling, listed last in `acceptance.yml`
- **Read 2026-11-13:** `/fawkes/` says `v0.3.95` (matrix: `v0.3.163`), `/ai/`
  says `v2.0.0` (matrix: `v2.2.0`), `/obs/` says `v1.0.0` (matrix: `v1.0.1`)

### Release 1 — uFawkesAI `v2.0.0`

#### AC-AI-01: The devcontainer image can be pinned

> Image renamed 2026-10-03 (owner decision, uFawkesAI `docs/ai-sdlc/v2.0.0/intent.md`):
> `ufawkesai-devcontainer` → `fawkes-space`. Neither old name was ever publicly pullable.

- **Expected:** A `v2.0.0` tag publishes `ghcr.io/paruff/fawkes-space:2.0.0`
  and `:2.0`, signed. Its digest is in the GitHub Release
- **Verification:** `docker manifest inspect` succeeds from an
  unauthenticated machine, and `cosign verify` passes using the documented
  steps (paruff/uFawkesAI#111)

#### AC-AI-02: The template works from "Use this template"

- **Scenario:** A new repo created from the template, opened in the `2.0.0`
  devcontainer
- **Expected:** Each of the four documented agent harnesses starts. The
  `intent → spec → plan` flow produces files the plan command accepts.
  The placeholder audit finds nothing unfilled (paruff/uFawkesAI#28), and `make validate`
  passes
- **Verification:** Real run transcript

#### AC-AI-03: The 2.0 contract and upgrade path are written down

- **Expected:** `docs/ai-sdlc/v2.0.0/spec.md` states the contract (see
  `intent.md`, "Release decisions", item 1) and an upgrade note from 1.x that covers the
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

- **Expected:** All seven repos' `.devcontainer/devcontainer.json` pin
  `fawkes-space` by digest (any tag plus `@sha256:`), or to `:2.0.0`; never
  `:latest`
- **Verification:** `bash scripts/checks/ac-ai-05.sh` (greps each repo for
  `fawkes-space`) passes
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
  runs locally (pre-commit and the baseline tools pre-installed in the
  devcontainer image; remote hook environments download once, on first run) and in the
  Pre-flight workflow, which is a required check in every suite repo.
  pre-commit.ci is retired: it duplicated Pre-flight, its skip list drifted
  on template syncs, and it couldn't run the suite's own `jq`-based hooks.
  A monthly workflow opens a `pre-commit autoupdate` PR
- **Verification:** no `ci:` block in any suite repo's config; branch
  protection lists Pre-flight; the devcontainer runs
  `pre-commit run --all-files` as `dev` (offline-on-first-open dropped by the
  owner on 2026-10-03: a one-time hook download is accepted)

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

- **Expected:** Five DORA metrics everywhere (paruff/uFawkesDojo#19). Every module that still
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

Rolling, tracked under the `Dojo labs` release (moved off `Dojo 0.2` on
2026-10-17 so it no longer holds "Next release" after `0.2.0` shipped).

- **Expected:** Dojo `0.3`–`0.6` each add the lab for the stack released
  alongside it, pinned to that tag (`git clone --branch vX.Y.Z`). The
  stack's announcement links to it. Each lab follows uFawkesAI's
  [`dojo-handoff.md`](https://github.com/paruff/uFawkesAI/blob/v2.1.0/docs/ai-sdlc/dojo-handoff.md) mapping
  as of `v2.1.0` (paruff/uFawkesAI#251 removed it from the template's `main`;
  the suite keeps that version): one exercise step per
  row of the release plan's Verification Strategy, one `record_test` per
  spec AC in `validate.sh`, and a provenance header naming the source
  `docs/ai-sdlc/<release>/` and commit
- **Verification:** Same-week Dojo release; the announcement contains the
  lab link; `validate.sh` check names match the release spec's AC ids

### Release 3 — uFawkesObs 1.x (first verified stable)

#### AC-OBS-01: Installs cleanly from its README

- **Scenario:** A clean Linux host and a clean macOS host, with only Docker
  20.10+ and Compose v2
- **Expected:** The README Quick Start alone brings every service to
  healthy, and every default dashboard panel shows data. No "datasource not
  found" errors (paruff/uFawkesObs#534)
- **Verification:** Real run transcripts on both hosts

#### AC-OBS-02: No open release blockers

- **Expected:** No open issue in Project #7's `Obs 1.0` release carries the
  `release-blocker` label. uFawkesObs has no milestones; the board release is
  the scope, and it covers the `v1.0.x` patches that finish this release
- **Verification:** `scripts/checks/ac-obs-02.sh`, run by the status build

#### AC-OBS-03: The contract is written down

- **Expected:** uFawkesObs `docs/ai-sdlc/v1.0.0/` states the semver contract
  and the 0.4.x upgrade note
- **Verification:** the folder's `intent.md` is on `main`, and the verified
  release's notes link it

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

### Release 5 — uFawkesDevX first verified stable (1.x)

The planned `v0.1.0` beta was dropped on 2026-10-17: Release Please had
already published stable 1.x. The first 1.x release that passes AC-DEVX-01 is
this release; until then, public pages call DevX unverified.

#### AC-DEVX-01: Runs without uFawkesRes

- **Expected:** An ADR records the paruff/uFawkesDevX#57 decision. `make up` brings up Coder
  and Backstage against storage defined inside the documented setup
- **Verification:** Clean-host run transcript

### Release 6 — fawkes Tracer Bullet Alpha

#### AC-FAWKES-01: Commit to staging works in one clean run

- **Expected:** paruff/fawkes#1804's scope passes end to end in one continuous run: push
  → build → scan → GitOps PR → ArgoCD sync to staging (paruff/fawkes#1858)
- **Verification:** One CI run plus ArgoCD sync history, linked

#### AC-FAWKES-02: Two DORA metrics are queryable

- **Expected:** Deployment frequency and lead time for changes, both for the
  tracer-bullet service, show in Grafana from native PromQL (paruff/fawkes#1572, paruff/fawkes#1919).
  Grafana can query its own Prometheus (#2130)
- **Verification:** Screenshot plus the PromQL behind each panel

#### AC-FAWKES-03: No known P0 security issues

- **Expected:** fawkes#2004 (extract-zip) and fawkes#1797 (`CHANGE_ME_*`
  credentials) are closed
- **Verification:** Both issues closed with linked PRs

#### AC-FAWKES-04: Public claims are scoped to Alpha

- **Expected:** fawkes's README says what Alpha proves and lists Beta and
  Production as not yet built. ADR-004 is marked superseded (done: ADR-036)
- **Verification:** AC-SUITE-01 grep, plus a README review

## 3. Out of scope

New stack features, fawkes Beta/Production (the Valkey, SSO and
cloud-readiness gaps that would make fawkes uFawkesRes's full successor are
tracked in `plan.md` Phase 6, not gated), and Dojo modules for stacks that
haven't released yet. The Dojo's `compose-curriculum` spec governs module
content within this ordering.
