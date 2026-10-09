# Intent: uFawkes Suite Release

**Owner:** @paruff | **Created:** 2026-09-27 | **Revised:** 2026-10-08 |
**Status:** Draft | **Revision:** 4

## The suite repos

Revision 4 adds the three golden-path repos, so the suite is ten. Nothing in
this document's goals or acceptance criteria has been widened yet — the
criteria still describe the original seven, and the new repos meet none of
AC-SUITE-03's conditions (root `INTENT.md`, artifact chain).

### Original seven (as of 2026-10-01)

| Repo                                                 | Role                                                                                                                                                           | Today (2026-10-01)                                                                  |
| ---------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| [uFawkes.dev](https://github.com/paruff/uFawkes.dev) | Public website and suite tracking repo. Holds this plan, the compatibility matrix and Project #7                                                               | Live; nav lists no uFawkesAI or fawkes page                                         |
| [uFawkesAI](https://github.com/paruff/uFawkesAI)     | Golden-path template for the AI-native SDLC: `intent → spec → plan`, agents, skills, DORA AI capabilities, and the shared devcontainer CDE every repo now uses | `v1.0.0` (June); 236 commits unreleased; devcontainer image can't be pinned (#111)  |
| [uFawkesObs](https://github.com/paruff/uFawkesObs)   | Small-team starter observability plane (Docker Compose)                                                                                                        | `v1.0.0-rc.1` / `v1.0.1-rc.1` cut; `v1.0.0` milestone closed                        |
| [uFawkesPipe](https://github.com/paruff/uFawkesPipe) | Small-team starter CI/CD plane (Woodpecker, Docker Compose)                                                                                                    | `v1.7.4-beta.1`; `build-image` still a placeholder                                  |
| [uFawkesDevX](https://github.com/paruff/uFawkesDevX) | Small-team starter developer-experience plane (Coder, Backstage, Docker Compose)                                                                               | Unreleased; blocked on the uFawkesRes database decision (#57)                       |
| [fawkes](https://github.com/paruff/fawkes)           | Full Kubernetes internal developer platform: multiple planes and golden paths that move a team through the DORA performance tiers. The graduation target       | `v0.3.154` pre-releases; Tracer Bullet Alpha (#1804) not yet passing                |
| [uFawkesDojo](https://github.com/paruff/uFawkesDojo) | Learning platform for both the small-team stacks and the full platform                                                                                         | `0.1.0-alpha.1`; 19 of 20 modules have no runnable lab; Yellow Belt teaches Jenkins |

### Golden-path repos (joined 2026-10-08)

These exist to prove the fawkes pipeline against real, disposable services
rather than to be installed by a user. Phase 1 governance (license, code of
conduct, security policy, funding) landed in each repo's own PR on
2026-10-08; this records them as suite members.

| Repo                                                                             | Role                                                                                                                                                                      | Today (2026-10-08)                                                                                                                                 |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| [java-fawkes-path](https://github.com/paruff/java-fawkes-path)                   | Java/Spring Boot golden path (fawkes#2032): proves the build, scan, sign, push and GitOps-promotion path for JVM services                                                 | Unreleased; no root `INTENT.md`; no ruleset on `main`; README still advertises a Jenkins pipeline while `.github/workflows/ci.yml` runs on Actions |
| [python-fawkes-path](https://github.com/paruff/python-fawkes-path)               | Deliberately minimal FastAPI service — not a product feature. Exists so the fawkes CI/CD/observability machinery can be validated end to end against a real, tiny example | Unreleased; no root `INTENT.md`; no ruleset on `main`; `README.md` trips MD022 (headings without surrounding blank lines)                          |
| [python-fawkes-path-gitops](https://github.com/paruff/python-fawkes-path-gitops) | ArgoCD-synced desired-state manifests for `python-fawkes-path`. The image tag is written by that repo's pipeline via PR, never by hand                                    | Unreleased; no root `INTENT.md`; no ruleset on `main`; no workflows of its own                                                                     |

## Problem

Revision 1 (2026-09-27) planned five releases and left uFawkesAI and fawkes
out. Since then:

- **Suite hygiene mostly landed.** `docs/roadmap.md` is retired, every
  stack has an `INTENT.md`, fawkes has ADR-036 (Tekton), the Dojo has
  `docs/ai-sdlc/compose-curriculum/`, and Project #7 tracks 48 items.
- **uFawkesAI became the foundation, not a finished template.** Every repo
  now builds on its devcontainer image, but the image has only a `:latest`
  tag, so consumers can't pin it (#111). The package rename and the removal
  of the gitops variant are breaking changes that haven't been released.
- **The Dojo is the suite's onboarding path, and it isn't accurate.** It
  teaches four DORA metrics and Jenkins, and it describes labs that were
  never run. Users reach it before they reach any stack.
- **fawkes is where a team graduates to, but it has no release bar.** It has
  43 open issues and no public statement of what works end to end.

## Goals

1. **External adoption.** Small-to-medium teams (3–15 engineers) can install
   a stack from its README, or learn it from the Dojo, and succeed without
   help.
2. **Portfolio/credibility.** The suite reads as one coherent,
   research-backed platform engineering story across ufawkes.dev, LinkedIn
   and dev.to, and no public claim is contradicted by a repo.
3. **Cheap, safe execution.** Claude Code owns the goals: decisions,
   releases, security, and anything that needs a real run to verify.
   Bounded tasks go to OpenCode on free models (MiMo V2.6 Flash, Nemotron 3
   Ultra), so a solo maintainer can move seven repos.

## Framing (adopted 2026-10-01)

Two external references anchor the suite's story. Both are cited, never
copied into the repos.

**From [The AI-Native SDLC Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook) (Claxton, Anthropic, 2026-08-21)**, the process model uFawkesAI's convention already follows:

- **Six stages: Plan, Design, Build, Test, Deploy, Maintain.** Each one
  commits an artifact the next stage reads: `intent.md` → `spec.md` →
  `plan.md` → PR → review findings → incident record. "The chain of commits
  is also the audit trail."
- **Human gates stay human.** "The agent may act up to the production gate
  and cannot pass it." uFawkesAI implements this across four harnesses,
  not only Claude Code. That's its difference from the playbook.
- **Measure leading and lagging indicators.** Leading: time from intent to
  merged PR, first-pass CI success rate, eval pass rate. Lagging: DORA. The
  playbook lists the older four DORA metrics; the suite uses DORA's five.
- **Stage 6 closes the loop.** A metric breach (CI failure rate, post-deploy
  5xx) produces an `intent.md` that re-enters at Plan. That's the natural
  integration between uFawkesObs, uFawkesPipe and uFawkesAI. It's recorded
  as direction for after this plan, not a release gate (no new features).

\*\*From Osmani, Saboo & Kartakis, _The New SDLC With Vibe Coding: From ad-hoc prompting to Agentic Engineering_ (May 2026):

- **Agent = Model + Harness.** The harness is everything around the model:
  instructions and rule files, tools and MCP servers, the sandbox,
  orchestration and model routing, hooks, and observability. Most agent
  failures are harness failures, not model failures. **uFawkesAI is a
  harness**: it ships all six components as a template and a devcontainer.
  That's the one-line pitch for `v2.0.0`.
- **Vibe coding → agentic engineering is a spectrum,** and the difference is
  verification: tests for the deterministic parts and evals for the agent's
  behaviour. The suite tells the same story at two scales. uFawkesAI moves a
  developer along the agentic-engineering spectrum. The stacks and then
  fawkes move a team along the DORA performance tiers. The Dojo teaches
  both.
- **"Set the bar at the eval, not the demo."** This is the plan's existing
  "real run" rule, and it applies to agent behaviour as well as installs.

## Decisions

### Release order (decided 2026-10-01)

| #   | Release                                        | Why this position                                                                                              |
| --- | ---------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| 1   | **uFawkesAI `v2.0.0`**: AI-native SDLC + CDE   | Every other repo depends on its devcontainer and its `intent → spec → plan` convention. Ship it pinnable first |
| 2   | **uFawkesDojo `0.2`**: accurate + "Start here" | Moved earlier. Gives users a correct learning path from day one, starting with the uFawkesAI CDE               |
| 3   | **uFawkesObs `v1.0.0`**: first stable stack    | Its rc is already out. Ships after the Dojo is accurate so the announcement can link to a lab                  |
| 4   | **uFawkesPipe `v2.0.0`**: first stable         | `v2.0.0` signals "the real one" after the 1.x beta line                                                        |
| 5   | **uFawkesDevX `v0.1.0`**: beta                 | Needs the uFawkesRes replacement first                                                                         |
| 6   | **fawkes Tracer Bullet Alpha**                 | The graduation target. Released when epic #1804 passes end to end                                              |

**uFawkes.dev is continuous.** It ships with every release: the
compatibility-matrix row, the stack page, and the announcement.

**The Dojo ships alongside every release after `0.2`.** Each stack release
adds one Dojo lab pinned to that release (`0.3` Obs, `0.4` Pipe, `0.5`
DevX, `0.6` fawkes graduation). The Dojo stops trailing and becomes the
thread that connects the announcements.

### Kept from revision 1

- **Each repo versions independently** on uFawkesAI's weekly "one new thing"
  cadence. The matrix on ufawkes.dev states which versions are verified
  together.
- **uFawkesObs `v1.0.0` contract:** semver covers compose service names,
  published ports and documented `.env.example` variables. Datasource UIDs,
  dashboard UIDs and DORA metric names may change in a minor release, and
  the release notes must say so.
- **Adoption signals:** GitHub stars/forks, and issues or PRs from anyone
  other than @paruff, tracked in each release's `measure:` issue.
- **uFawkesRes is deprecated, fawkes uses Tekton, uFawkesPipe uses
  Woodpecker, ufawkessec is merged into uFawkesPipe, and ufawkesdora is
  archived.**

### Changed from revision 1

- **uFawkesAI is in scope** as release 1. It ships as `v2.0.0` because the
  package rename and the gitops-variant removal break consumers.
- **fawkes is in scope** as release 6, gated on Tracer Bullet Alpha. Its 16
  milestones stay. Only its P0/P1 and Alpha-epic issues join Project #7.
- **The Dojo moves from last to second.**

## Non-goals

- A coordinated "suite version" that gates every repo on the slowest one.
- New stack features. Each release ships what exists. When a feature's
  claim doesn't hold, the claim is removed; the feature isn't rushed in.
- fawkes Beta or Production phases (#1805, #1806), and re-planning fawkes's
  own milestones.
- A full Dojo rewrite. Modules move one at a time, behind the stack release
  they teach.

## Release decisions (answered 2026-10-01)

1. **uFawkesAI `v2.0.0` promises a CDE aligned with the AI-native SDLC as
   DORA, Anthropic and Google research describe it.** Semver covers the
   devcontainer image name and tags, the `docs/ai-sdlc/<feature>/` layout
   and file names, and the npm package name. Agent prompt text, default
   model routing and skill internals are not covered. "Aligned" is
   checkable: AC-AI-04 maps the release to the DORA AI capabilities, the
   playbook's six stages and the harness anatomy, and AC-AI-08 holds the
   CDE to the developer-experience evidence in
   [`docs/research-foundation.md`](../../research-foundation.md).
2. **fawkes ships Tracer Bullet Alpha as `v0.4.0`.**
3. **If uFawkesAI slips, uFawkesObs ships first.** The only real slip risk
   is #111: the signed image publish path has never run for a tag.

## Still open

- **Target dates.** The plan stays gate-driven until you set any.
