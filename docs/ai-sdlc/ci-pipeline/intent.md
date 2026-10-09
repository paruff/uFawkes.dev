# Intent: One deterministic pipeline for the seven suite repos

**Owner:** @paruff | **Created:** 2026-10-09 | **Status:** Draft

**Plan:** [`docs/ci-pipeline-master-plan.md`](../../ci-pipeline-master-plan.md)
(June 2026, revised 2026-10-09 to match this intent).

## Problem

The master plan's goal still holds: every pipeline run that finishes green
should have produced a verified, production-ready artifact. But the plan
was written for a suite that no longer exists, and the pipeline it built
can't promise the same answer twice.

**The suite changed.** The plan audits eight repos, including `ufawkesdora`
and `ufawkessec`, which are archived, and leaves out uFawkesDojo, which
ships labs. It says uFawkesAI has "no artifact". uFawkesAI is now the
artifact the other six are built from: the template, and the CDE images
(`fawkes-core`, `fawkes-space-ai`, `fawkes-space`) every repo's devcontainer
pins by digest. And it predates shift-left, which moved the commit-msg,
pre-commit and pre-push stages, and CI's copy of them, into their own spec.

**The pipeline isn't deterministic.** Counted on 2026-10-09 across the seven
repos:

| What                             | Found                                                                                                                                                        |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| uFawkesPipe's reusable workflows | Called at **four** different commits; uFawkes.dev and fawkes also run their own copies of `reusable-build`, `reusable-lint` and `reusable-security-scanning` |
| Toolchain in CI                  | Only uFawkesAI's CI runs in the CDE image. Every other repo installs tools on the runner, so CI and the devcontainer can run different versions              |
| Steps that can't fail            | 19 `continue-on-error: true` (uFawkes.dev 4, Obs 2, Pipe 4, fawkes 9), including the security scans in uFawkes.dev#132                                       |
| Pre-push stage in CI             | Runs only through Pipe's preflight, which three repos call at different commits                                                                              |
| CDE image pin                    | Six repos on `2.0.0-rc.3`, Dojo on `2.0.0`                                                                                                                   |
| Third-party actions              | All pinned by commit SHA (already met)                                                                                                                       |

So the same commit can get a different verdict on a different day, or in a
different repo, and a green check can mean a step that never ran.

## Desired outcome

1. **Same inputs, same verdict.** Every input to a run is pinned: actions,
   reusable workflows, container images, tools and dependencies. Rerunning a
   commit gives the same result, and a laptop in the devcontainer gives the
   same result as CI.
2. **One pipeline, versioned once.** uFawkesPipe owns the reusable
   workflows. All seven repos call them at one suite release, and move to
   the next one together.
3. **One CI image, usable without GitHub.** CI's hook stages run in
   uFawkesPipe's `ufawkes-ci` image, pinned by digest, which also runs on
   a laptop (`pipe-ci`, offline) when the local environment is limited or
   GitHub is down. It's built on the `fawkes-core` of the same uFawkesAI
   release the devcontainers use, so laptop and CI share one toolchain. The
   CDE images themselves stay development images.
4. **No silent passes.** A gate fails or passes; it never reports green
   without having run. Exceptions are written down with a reason.
5. **Each repo type produces its artifact and its evidence.** A site, a lab
   set, a Compose stack, a Kubernetes platform, and uFawkesAI's template and
   images each have a definition of "production ready" the pipeline checks.

## Decisions already made

- **Seven repos:** uFawkes.dev, uFawkesAI, uFawkesObs, uFawkesPipe,
  uFawkesDevX, uFawkesDojo, fawkes. `ufawkesdora` and `ufawkessec` are
  archived and out of scope.
- **Shift-left owns the hook stages.** commit-msg, pre-commit, pre-push and
  CI's rerun of them follow [`shift-left/spec.md`](../shift-left/spec.md)
  (R1 stages and budgets, R3 same command, R4 no silent passes, the parity
  check). This intent doesn't redefine them; it builds the rest of the
  pipeline on top.
- **Branch protection** follows
  [`suite-hygiene/main-protection.md`](../suite-hygiene/main-protection.md).
- **The CI image is uFawkesPipe's `ufawkes-ci`**, per its approved spec
  ([`ci-runner-image/spec.md`](https://github.com/paruff/uFawkesPipe/blob/main/docs/ci-runner-image/spec.md),
  2026-10-06), not `fawkes-space` or `fawkes-core`.
- **The next CDE release comes first.** The work that moves the
  devcontainers to uFawkesAI's next `fawkes-space` (the AI-DLC release,
  uFawkesAI#218) is a dependency: `ufawkes-ci` is built on that release's
  `fawkes-core`.
- **GitHub Actions** stays the CI system. Woodpecker is what uFawkesPipe
  ships for users, not what the suite runs on.

## Out of scope

- Moving the suite's own CI to Woodpecker or Tekton.
- New test suites. This intent wires existing ones into the right gate.
- Branch-protection changes. Those are the owner's (main-protection.md).
