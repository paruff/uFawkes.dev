# Intent: uFawkes Suite Release

**Owner:** @paruff | **Created:** 2026-09-27 | **Status:** Draft

## Problem

The uFawkes suite has seven repos, each built quickly and independently, and
they have drifted apart:

- **Maturity doesn't match version numbers.** uFawkesPipe is at
  `v1.7.1-beta.1` but has never cut a stable release, and its own README
  lists the `build-image` step as a placeholder. uFawkesObs, the most mature
  stack (7 ADRs, release-please, acceptance CI), is at `v0.4.2-beta.1`.
- **Public docs contradict each other.** `docs/roadmap.md` in this repo
  still describes uFawkesPipe as Jenkins-based (it's Woodpecker).
  uFawkesDevX still documents a dependency on the deprecated uFawkesRes.
  fawkes still has `ADR-004 jenkins 4 ci` with no ADR superseding it (Fawkes
  moved to Tekton).
- **No suite-level plan or tracking exists.** There is no cross-repo board,
  and only fawkes uses milestones. Around 86 issues are open across the suite
  with no shared view of what blocks a release.
- **uFawkesAI (v1.0.0) defines an `intent → spec → plan` convention**
  (`docs/ai-sdlc/<feature>/`), but no other repo follows it yet.

## Goals (decided 2026-09-27)

1. **External adoption.** Small-to-medium teams (3–15 engineers, per
   uFawkesObs's own positioning) can install a stack from its README and
   succeed without help.
2. **Portfolio/credibility.** The suite reads as one coherent,
   research-backed platform engineering story across ufawkes.dev, LinkedIn
   and dev.to, with no public claim contradicted by the repos.

## Decisions already made

- **uFawkesObs ships first, as `v1.0.0` stable**, announced on LinkedIn,
  ufawkes.dev and dev.to. uFawkesAI's release agent already drafts all three.
- **Each repo versions independently.** It follows uFawkesAI's weekly
  "one new thing" cadence. A compatibility matrix on ufawkes.dev states
  which versions have been verified together.
- **This plan lives here** (`uFawkes.dev/docs/ai-sdlc/suite-release/`) and
  replaces `docs/roadmap.md` as the suite's planning source. A user-level
  GitHub Project tracks live status across all repos.
- **fawkes is on its own track.** It is the Kubernetes graduation target,
  not a suite-tier peer. Only its stale public claims (ADR-004) are in scope.
- **uFawkesRes is deprecated; Jenkins is gone from Fawkes (Tekton);
  uFawkesPipe is Woodpecker.**

## Non-goals

- A coordinated "suite version" that gates every repo on the slowest one.
- Re-planning fawkes's own roadmap or its 16 existing milestones.
- New features in any stack. This plan releases what exists; it doesn't
  add scope.

## Release decisions (answered 2026-09-27)

1. **uFawkesObs v1.0.0 public contract:** semver covers compose service
   names, published ports, and documented `.env.example` variables. A
   breaking change to any of these needs v2.0.0. Not covered: Grafana
   datasource UIDs, dashboard UIDs, and DORA metric names. They may change
   in a minor release, and the release notes must say so.
2. **uFawkesPipe versioning:** `v2.0.0` is its first stable release. That
   signals "this is the real one" after the 1.x beta line, and the release
   notes say why the major version jumped.
3. **Adoption signals:** GitHub stars/forks, and issues or PRs from anyone
   other than @paruff. The post-release `measure:` issue tracks both.
4. **Dojo ordering:** follow release order. Ship a uFawkesObs lab first,
   then Pipe (Yellow Belt), then DevX (White Belt).

## Still open

- **Target date for uFawkesObs v1.0.0**, if you want one. Until then the
  plan is gate-driven, not date-driven.
