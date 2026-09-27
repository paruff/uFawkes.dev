# Spec: uFawkes Suite Release

**Traces to:** [`intent.md`](intent.md) | **Status:** Draft | **Revision:** 1

This file defines _what "released" means_ for each repo. The order and
tasks are in [`plan.md`](plan.md), and live status is in the GitHub Project
(see plan).

## 1. Documentation requirements per repo

uFawkesAI's convention has two layers:

- A **repo-level `INTENT.md`** says what the repo is and isn't. It's the
  "read this before touching anything" file uFawkesObs already has.
- **Per-release docs** live in `docs/ai-sdlc/<release>/` as `intent.md` →
  `spec.md` → `plan.md`.

There is no separate `design.md`. Per uFawkesAI's
[`docs/ai-sdlc/README.md`](https://github.com/paruff/uFawkesAI/blob/main/docs/ai-sdlc/README.md),
`spec.md` carries "requirements, design, policy constraints, and concerns",
so each spec has a `## Design` section. ADRs plus `docs/ARCHITECTURE.md`
record lasting decisions. Root-level `design.md` / `specification.md` /
`plan.md` files are pre-convention and get consolidated. (Revision 1 wrongly
said the design goes in `plan.md`; corrected 2026-09-27.)

| Repo            | Repo `INTENT.md`                                                               | Release docs needed                               | Design lives in                                                          | Doc cleanup                                                                                                                                         |
| --------------- | ------------------------------------------------------------------------------ | ------------------------------------------------- | ------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| **uFawkesObs**  | ✅ exists                                                                      | `docs/ai-sdlc/v1.0.0/` (spec = the 1.0 bar below) | ✅ 7 ADRs + `ARCHITECTURE.md`                                            | None blocking                                                                                                                                       |
| **uFawkesPipe** | ❌ needed                                                                      | `docs/ai-sdlc/<first-stable>/`                    | `docs/ARCHITECTURE.md` + new ADRs                                        | Consolidate 3 spec files (`specification.md`, `docs/specification.md`, `docs/product/spec.md`), 2 design files, `plan-for-the-day.md`               |
| **uFawkesDevX** | ❌ needed                                                                      | `docs/ai-sdlc/v0.1.0/`                            | `ARCHITECTURE.md` + ADR for the Postgres source that replaces uFawkesRes | Move root `specification.md`/`design.md`/`plan.md` into `docs/ai-sdlc/`; remove uFawkesRes references                                               |
| **uFawkesDojo** | ⚠️ `intent.md` exists (lowercase); rename to `INTENT.md` for suite consistency | `docs/ai-sdlc/compose-curriculum/`                | n/a (curriculum)                                                         | Move `docs/uFawkes-suite-integration-spec.md` into that folder; retitle the `0.1.0-alpha.1` release ("4 metrics baseline" is stale — DORA has five) |
| **uFawkes.dev** | ❌ needed                                                                      | `docs/ai-sdlc/suite-release/` (this folder)       | n/a                                                                      | Replace `docs/roadmap.md` with a pointer here; add a compatibility-matrix page                                                                      |
| **uFawkesAI**   | ✅ (template)                                                                  | None for this plan (already v1.0.0)               | ✅                                                                       | Minor: `plan` skill expects `specification.md`/`design.md`, but agents write `spec.md`/`plan.md`. Align the names                                   |
| **fawkes**      | Optional (own track)                                                           | None for this plan                                | ✅ ADRs                                                                  | Add an ADR that supersedes `ADR-004 jenkins 4 ci` (Tekton)                                                                                          |

## 2. Release acceptance criteria

### AC-SUITE-01: No public claim is contradicted by a repo

- **Scenario:** Before the uFawkesObs v1.0.0 announcement goes out
- **Expected:** `docs/roadmap.md` (this repo), uFawkesDevX's docs,
  fawkes's ADR-004 and Dojo's release title no longer contradict the facts
  in `intent.md` (Woodpecker, Tekton, uFawkesRes deprecated, five DORA
  metrics)
- **Verification:** `grep -ri "jenkins\|uFawkesRes"` across the suite's
  public docs returns only historical or superseded mentions
- **Priority:** Required. This is the credibility goal; the announcement
  links readers to these docs.

### AC-OBS-01: uFawkesObs v1.0.0 installs cleanly from its README

- **Scenario:** A clean Linux host and a clean macOS host, each with only
  Docker 20.10+ and Compose v2
- **Action:** Follow the README Quick Start verbatim (`make init && make up`,
  `./scripts/wait-healthy.sh`)
- **Expected:** All services healthy, and Grafana at `:3000` shows the
  default dashboards with data
- **Must not:** Need any step that isn't in the README
- **Verification:** Transcript of a real run on each host, linked from the
  release notes
- **Priority:** Required (adoption goal)

### AC-OBS-02: No open release blockers

- **Expected:** The `v1.0.0` milestone has zero open issues labeled
  `release-blocker`. Candidates as of 2026-09-27, to triage:
  - #381 GitOps deploy broken: SSH host key mismatch (already labeled
    `release-blocker`)
  - #469 alertmanager: 42 HIGH/CRITICAL fixable CVEs
  - #473 alertmanager templates glob matches nothing
  - #470 CI validates Tempo 2.4.1, but the stack runs 2.10.5
  - #393 deploy (compose restart) failed
  - #182 live rollback drill (labeled `late-beta`)
- **Verification:** Milestone view in the GitHub Project
- **Priority:** Required

### AC-OBS-03: The 1.0 public contract is written down

- **Expected:** `docs/ai-sdlc/v1.0.0/spec.md` in uFawkesObs states the
  contract decided in `intent.md`. Semver covers compose service names,
  published ports, and `.env.example` variables. It explicitly excludes
  datasource UIDs, dashboard UIDs and DORA metric names. The doc also
  includes an upgrade note from 0.4.x.
- **Verification:** The doc exists and is linked from the release notes
- **Priority:** Required. "Stable" means nothing without a stated contract.

### AC-OBS-04: Announced everywhere, consistently

- **Expected:** GitHub Release `v1.0.0`, the ufawkes.dev Obs page, a dev.to
  post and a LinkedIn post are all live. All link to the same release
  notes and show the same version. They're produced by uFawkesAI's
  `release` agent.
- **Verification:** All four URLs recorded on the release's Project item
- **Priority:** Required (credibility goal)

### AC-PIPE-01: First stable uFawkesPipe release claims only what works

- **Expected:** The `build-image` step is either implemented (CNB build
  producing an image) or removed from the README's feature claims. It
  ships as `v2.0.0`, and the release notes explain the jump from the 1.x
  beta line.
- **Verification:** A real pipeline run on a sample repo, with output
  linked
- **Priority:** Required before any "stable" label

### AC-DEVX-01: uFawkesDevX v0.1.0 runs without uFawkesRes

- **Expected:** `make up` brings up Coder and Backstage against a Postgres
  source defined inside the documented setup, not the deprecated
  uFawkesRes
- **Verification:** A clean-host run transcript
- **Priority:** Required for first release

### AC-SITE-01: Compatibility matrix exists

- **Expected:** A ufawkes.dev page lists each stack's current release and
  which other stack versions it has been verified with. "Standalone only"
  is a valid entry.
- **Verification:** Page live; updated by the release agent on each release
- **Priority:** Required by uFawkesObs v1.0.0 (even if it lists only Obs)

## 3. Out of scope

fawkes releases, new stack features, and Dojo curriculum rewrites beyond
what `plan.md` sequences. The Dojo's own `compose-curriculum` spec governs
those.
