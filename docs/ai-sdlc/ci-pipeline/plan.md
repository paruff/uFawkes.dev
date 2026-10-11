# Plan: Remove silent passes from the CI gates (ci-pipeline R5)

**Traces to:** [`spec.md`](spec.md) R5 and AC-3 | **Status:** In progress | **Revision:** 1

Implements [paruff/uFawkes.dev#180](https://github.com/paruff/uFawkes.dev/issues/180):
no gate step can pass without having run. The overall plan is
[`docs/ci-pipeline-master-plan.md`](../../ci-pipeline-master-plan.md); this file
covers the first step, one PR per repo.

## What counts

A **gate** is a step whose failure means the thing it checks is wrong: a
scan, a test, a hook, a signature check, a coverage threshold. A gate must
fail the job itself: no `continue-on-error: true`, no `|| true`, and no
pipe (`| tee`) that replaces its exit status with another command's.

Not gates, and left alone: cleanup (`docker rm`, `kill`), diagnostics that
run after a failure (`kubectl get ... || true`), PR comments (they fail on
fork PRs), and commands that fail on purpose to generate telemetry. A step
that reports and must not block is named `(informational)` and listed in
`.pipeline.yml`.

## Changes

| Repo        | PR              | Gate steps fixed                                                         |
| ----------- | --------------- | ------------------------------------------------------------------------ |
| uFawkes.dev | #184            | Secret scan, Python and Node dependency scans; pa11y (see below)         |
| uFawkesPipe | uFawkesPipe#167 | Gitleaks, dependency scans, coverage gate, `pip install` in `ci-quality` |
| uFawkesObs  | uFawkesObs#631  | Chaos nightly (step and closing check), agent guardrail eval             |
| fawkes      | fawkes#2239     | Dependency scans, Gitleaks, `cosign verify`, four pre-commit stages      |

**Removing the tolerance showed two gates here had never run:**

- `gitleaks/gitleaks-action` failed on every PR ("failed to scan Git
  repository: stderr is not empty") and `continue-on-error` hid it. Replaced
  by the pinned, checksum-verified binary on full history, as uFawkesPipe
  does.
- The pa11y step ran `pa11y` but installed only `pa11y-ci` (exit 127), then
  passed `--chromeLaunchConfig`, which pa11y 10 rejects (exit 1). The
  `except: print(0)` counted both as zero errors. Fixed, and the first real
  run found one failure: minima's blockquote grey (`#828282`, 3.84:1) on
  `/learn/`, fixed with the `textMuted` token (`#4b5563`).

## Verification Strategy

| Check                  | How it is proven                                                                                                                                                            | Command / CI job                                                              |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Gates fail             | Each repo's PR CI is green with the gates live, or red for a real finding that the PR fixes                                                                                 | `gh pr checks` on #184, uFawkesPipe#167, uFawkesObs#631, fawkes#2239          |
| Secret scan runs       | The job log shows gitleaks scanning history, not an action error                                                                                                            | uFawkes.dev `Security Scanning / Security Scanning`                           |
| pa11y works both ways  | A clean page exits 0 with 0 errors; a page with a missing alt and low contrast exits 2 with 4                                                                               | Run locally with `pa11y@10.0.0 --config pa11y.json`, before and after the fix |
| Contrast fixed         | `/learn/` reports 0 pa11y errors after the CSS change                                                                                                                       | Local `jekyll build` + pa11y; CI `Accessibility Testing`                      |
| No silent pass remains | A scan of each repo's workflows finds no `continue-on-error: true` or gate-ending `\|\| true` outside the lists above                                                       | The determinism audit (uFawkes.dev#179), or `grep` until it exists            |
| Audit logic            | An offline test with fixture workflows covers each column (Pipe refs, local copies, CI image, release match, unpinned, silent), the `informational:` exemption and the JSON | `bash scripts/test-ci-determinism-audit.sh` (also in `run-unit-tests.sh`)     |
| Audit matches reality  | A live run against the seven repos reproduces the 2026-10-09 `continue-on-error` counts (Obs 2, Pipe 4, fawkes 9), or explains each difference                              | `bash scripts/ci-determinism-audit.sh`                                        |
| Matrix is published    | The deploy builds and `/status/` renders the CI determinism section and `ci_determinism.json`                                                                               | `make build`; the `CI determinism audit` step in `deploy.yml`                 |
| Lint                   | Workflows parse and lint                                                                                                                                                    | `actionlint`; `pre-commit run --all-files`                                    |

## Risks

- **A caller goes red where a finding was hidden.** That is the intended
  effect; the PR text for each repo names what could turn red.
- **`cosign verify` in fawkes could not be tested here** (no signing job
  ran). Its identity regexp is the riskiest line; check it with a manual
  run of the signing callers before relying on it.
- **Reusable changes need a Pipe release** (#165) before callers pinned to
  older SHAs see them.
