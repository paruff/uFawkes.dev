# Spec: One deterministic pipeline for the seven suite repos

**Traces to:** [`intent.md`](intent.md) | **Status:** Draft | **Revision:** 1

**Plan:** [`docs/ci-pipeline-master-plan.md`](../../ci-pipeline-master-plan.md)

## Requirements

**R1. The seven repos and their types.**

| Repo        | Type             | Artifact                                                                                                    | Deploys to                                      |
| ----------- | ---------------- | ----------------------------------------------------------------------------------------------------------- | ----------------------------------------------- |
| uFawkes.dev | site             | Jekyll `_site/`                                                                                             | GitHub Pages                                    |
| uFawkesDojo | site + labs      | Jekyll site and lab definitions                                                                             | GitHub Pages; labs run against stack releases   |
| uFawkesObs  | stack            | Docker Compose stack, images pinned by digest                                                               | SSH GitOps                                      |
| uFawkesPipe | stack + pipeline | Docker Compose stack, and the suite's reusable workflows and shift-left hooks                               | Users' CI; the suite calls it at a release (R3) |
| uFawkesDevX | stack            | Docker Compose stack                                                                                        | Manual                                          |
| fawkes      | core             | Kubernetes platform: images, Helm, Terraform                                                                | ArgoCD                                          |
| uFawkesAI   | template + image | The template other repos are made from, and the CDE images `fawkes-core`, `fawkes-space-ai`, `fawkes-space` | GHCR, multi-arch; consumed by digest (R4)       |

`ufawkesdora` and `ufawkessec` are archived: no pipeline, no checks.

**R2. Every input is pinned.** A run's verdict depends only on the commit and
on these pins, which change only through a reviewed PR:

| Input                     | Pinned by                                                               |
| ------------------------- | ----------------------------------------------------------------------- |
| Third-party actions       | Commit SHA, with the version in a comment (met today)                   |
| uFawkesPipe reusables     | One suite release tag's commit SHA, the same in every repo (R3)         |
| Container images in CI    | Digest (`@sha256:`); a tag alone fails                                  |
| The CI toolchain          | The CDE image digest (R4)                                               |
| Tools installed in a step | An exact version and a checksum (the image's `tools.lock.json` pattern) |
| Language dependencies     | A lockfile, with hashes where the ecosystem has them                    |
| Pre-commit hook repos     | A tag or SHA in `.pre-commit-config.yaml` (shift-left)                  |

A scheduled job may use the network to _propose_ new pins (Dependabot, the
image lock bump, pre-commit autoupdate). No gate resolves a version at run
time.

**R3. One pipeline, versioned once.** uFawkesPipe owns every reusable
workflow the suite shares: preflight, lint, security scanning, dependency
review, build, tests, rollback, main CI guard. It publishes them under a
release tag. Every repo calls them at that tag's SHA, and the suite moves to
a new release together (one PR per repo, opened by one bump). A repo keeps
no copy of a Pipe reusable; repo-specific jobs (fawkes's Terraform, Dojo's
lab acceptance, uFawkesAI's image build) stay local and call Pipe's
reusables where one exists.

**R4. The CDE image is CI's toolchain.** CI's hook stages
(`pre-commit run --all-files`, and the same with `--hook-stage pre-push`)
run in a job `container:` set to the uFawkesAI image digest that the repo's
`.devcontainer/devcontainer.json` pins. The two are the same digest; a check
fails when they differ. A tool the image lacks is added to the image
(uFawkesAI), not installed on the runner. Jobs that need Docker or a
cluster (image builds, Compose health, kind/k3d) run on the runner, with
their tools pinned per R2.

**R5. No silent passes.** No gate step has `continue-on-error: true`, ends
in `|| true`, or swallows an exit code. A step that is informational (it
reports but must not block) is listed in `.pipeline.yml` under
`informational:` with a reason, and says so in its step name. This extends
shift-left R4 (no silent passes in hooks) to every CI step.

**R6. The stages, aligned with the hooks.** Each check runs at the earliest
stage it fits (shift-left R1). CI gates 0 and 1 _are_ the hook stages, run
again over all files; gates 2 to 5 are what needs CI.

| Gate                    | Where                  | What runs                                                                                                                                   | Owner of the rule      |
| ----------------------- | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------- |
| commit-msg              | Laptop                 | Conventional Commits subject                                                                                                                | shift-left R1          |
| pre-commit              | Laptop, changed files  | Format, lint, actionlint, schemas, secrets, type check                                                                                      | shift-left R1, R2      |
| pre-push                | Laptop, pushed commits | Unit tests, semgrep, Trivy FS and IaC, conftest                                                                                             | shift-left R1, R2      |
| **0. Preflight**        | CI, in the CDE image   | The pre-commit and pre-push stages over all files; PR size; commit format; parity (every hook runs in CI or is listed in `.shift-left.yml`) | shift-left R3, this R4 |
| **1. CI-only analysis** | CI                     | CodeQL, dependency review                                                                                                                   | this spec              |
| **2. Build**            | CI                     | The repo type's artifact (R7), SBOM, signing, container scan                                                                                | this spec              |
| **3. Verify**           | CI                     | Tests that need infrastructure: integration, Compose health, e2e, lab acceptance, a11y and links                                            | this spec              |
| **4. Deploy readiness** | CI                     | `docker compose config`, `helm template` and kubeconform, `jekyll build`, a rollback target exists                                          | this spec              |
| **5. Deploy**           | CI on `main`           | The deploy, a health check against the deployed thing, rollback on failure                                                                  | this spec              |

Each repo enables the gates that apply in `.pipeline.yml` (the master
plan's schema v2, with `repo-type` from R1).

**R7. Production ready, per type.** A green pipeline on `main` means:

| Type             | Evidence the pipeline produced                                                                                                                                                                                                      |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| site             | `_site/` built from the pinned Ruby and gems; links and a11y (WCAG 2.1 AA) checked; deployed; the live URL answers                                                                                                                  |
| site + labs      | The site as above, and each lab marked runnable passes its acceptance against the stack release it pins                                                                                                                             |
| stack            | `docker compose up` on a clean runner, every service healthy; images pinned by digest; SBOM; no critical CVEs                                                                                                                       |
| stack + pipeline | The stack as above, and its reusables and hooks pass their own tests before a release tag is cut                                                                                                                                    |
| core             | Images built, signed and scanned; Helm renders and kubeconform passes; policy passes; ArgoCD sync healthy after deploy                                                                                                              |
| template + image | Template checks pass (artifact chain, harness parity, evals); each CDE image variant is built for amd64 and arm64, passes `verify-tools.sh`, is scanned, signed with cosign, has an SBOM, and stays inside the start-time benchmark |

**R8. Deterministic artifacts.** Where an artifact is built (images, the
site), the build is reproducible: base images by digest, `SOURCE_DATE_EPOCH`
from the commit, no timestamps or random IDs baked in. A scheduled job
rebuilds the last release of uFawkesAI's images and compares digests; a
mismatch is reported with the layers that differ. This is measured before
it gates: the first runs record what isn't reproducible yet.

**R9. One required check per repo.** Each repo exposes one aggregate check
(`✅ Pipeline Complete`) that needs every enabled gate, plus `🔗 Artifact
Chain`. Branch protection requires those two (main-protection.md).

**R10. The suite can see it.** `scripts/ci-determinism-audit.sh` in
uFawkes.dev reads each repo's workflows and devcontainer through the API and
reports, per repo: the Pipe release it calls (and any second one), local
copies of Pipe reusables, the CI container digest against the devcontainer
digest, unpinned images, and `continue-on-error` or `|| true` on gate steps
not listed as informational. `/status/` shows it as a matrix next to the
shift-left one.

**R11. Observability.** Every job keeps its `job-start` and `job-finish`
timestamp steps (`sha`, `workflow`, `job`), which feed DORA metrics.

## Acceptance criteria

| AC   | Done when                                                                                             | Measured by                       |
| ---- | ----------------------------------------------------------------------------------------------------- | --------------------------------- |
| AC-1 | All seven repos call uFawkesPipe's reusables at one release SHA, and none keeps a copy                | R10 audit                         |
| AC-2 | In all seven repos, CI's hook stages run in the CDE image at the devcontainer's digest                | R10 audit                         |
| AC-3 | Zero gate steps with `continue-on-error: true` or `\|\| true` outside a listed `informational:` entry | R10 audit                         |
| AC-4 | Rerunning the last green `main` run of each repo, unchanged, gives the same verdict                   | One manual rerun per repo, linked |
| AC-5 | Each repo's `.pipeline.yml` declares its R1 type, and its pipeline produces the R7 evidence           | Per-repo release notes            |
| AC-6 | uFawkesAI's reproducibility job runs and its report is published (gating on it is a later decision)   | The scheduled job's summary       |
| AC-7 | Each repo exposes `✅ Pipeline Complete`, and `/status/` shows the R10 matrix                         | `/status/`                        |

## Concerns

- **Running hook stages in the CDE image makes CI pull a large image.** It's
  cached per runner and pinned, so the cost is the cold pull. The image
  benchmark already tracks it; if it's too slow, the `fawkes-core` variant
  (no agent harnesses) is the CI image instead.
- **One suite release of Pipe means a Pipe bug lands everywhere at once.**
  That's the point (one pipeline), and it's why R7 makes Pipe's release
  depend on its own reusables' tests.
- **fawkes's 35 workflows** include several of its own reusables
  (CodeQL, SBOM, signing, policy). Where Pipe has the same reusable, fawkes
  calls Pipe's; where it doesn't, fawkes's stays local or moves to Pipe.
- **Reproducible builds may need upstream fixes** (tools that embed build
  time). R8 measures first and gates later for that reason.
