# Shift-left baseline (phase A1)

**Traces to:** [`plan.md`](plan.md) A1 → [`spec.md`](spec.md) R1, R2, R4 |
**Measured:** 2026-10-03, on one macOS laptop (12 cores), from each repo's `main`

Produced by `make shift-left-audit` (the matrix) and
`make shift-left-audit ARGS=--time` (the timings). Rerun both to compare.

## The matrix

```text
repo         actionlint  schema  sast  types  dep-iac     unit        commit-msg  system
uFawkes.dev  -           -       -     ok     pre-commit  pre-commit  ok          9
uFawkesAI    -           -       -     -      pre-commit  pre-commit  ok          8
uFawkesObs   -           -       -     ok     pre-commit  pre-commit  ok          9
uFawkesPipe  -           -       -     ok     pre-commit  pre-commit  ok          9
uFawkesDevX  -           -       -     ok     pre-commit  pre-commit  ok          9
uFawkesDojo  -           -       -     ok     pre-commit  pre-commit  ok          9
fawkes       -           -       -     ok     pre-commit  -           ok          9
```

- **actionlint, schema, SAST: 0 of 7**, as R2 counted.
- **types `ok` is misleading.** It is `golangci-lint` from the shared template,
  present whether or not the repo has Go. The per-repo type-check decision
  (phase F) still stands.
- **dep-iac** is `kubeconform`/`kubeval` at pre-commit. No repo has Trivy or
  semgrep as a hook.
- **unit tests run at pre-commit** in six repos, not pre-push as the catalog
  says. `fawkes` has none.
- **8–9 `language: system` hooks per repo.** Each is a silent-pass risk (R4),
  and two were caught passing silently on this run (below).

## Timings

All-files runs, so an upper bound: a real commit runs only the hooks whose
`files:` match the change. "Whole stage" is one `pre-commit run --all-files
--hook-stage <stage>`, what a person waits for.

| Repo        | pre-commit, whole stage | of which `unit-tests` | pre-push, whole stage |
| ----------- | ----------------------: | --------------------: | --------------------: |
| uFawkes.dev |                  40.5 s |                33.1 s |                42.1 s |
| uFawkesAI   |                  60.6 s |                48.4 s |                62.1 s |
| uFawkesObs  |                  39.3 s |                31.4 s |                40.2 s |
| uFawkesPipe |                  33.0 s |                26.0 s |                34.7 s |
| uFawkesDevX |                  29.9 s |                23.8 s |                31.2 s |
| uFawkesDojo |                  31.1 s |                27.4 s |                32.6 s |
| fawkes      |   ~303 s (sum of hooks) |                     — |        none installed |

Budgets (R1): pre-commit 10 s, pre-push 180 s.

## Findings

1. **`unit-tests` is 60–80% of pre-commit** in every repo that has it. These
   are integration tests of shell scripts (real git repos, scripts run as
   subprocesses, stubbed `gh`), offline and hermetic. The scripts under test
   are fast (`check-artifact-chain.sh`: 0.07 s); the cost is starting
   processes, ~6–13 ms each here and ~80 ms for `python3`, at 2–13% CPU.
   The seven suites run one after another: 33 s in sequence, ~15 s if parallel.
2. **pre-push repeats pre-commit.** The only pre-push hook,
   `pre-push-validation`, reruns every pre-commit hook over all files, so a
   push pays the pre-commit stage again.
3. **Silent passes, live.** `kubeval` and `kustomize-validate` reported
   **pass** in `fawkes` with neither tool installed. `requirements-pin-check`
   cannot fail at all: its last line passes `exit` to `echo` as text.
4. **`fawkes` is an outlier.** `terraform_validate` took 201 s (provider
   downloads on `terraform init`), `shellcheck` 26 s, `markdownlint` 13 s.
   Its pre-push stage isn't installed (`default_install_hook_types` lacks it).
5. **Failures here are partly this laptop.** `terraform_tfsec`,
   `argocd-validate`, `mkdocs-validate` and `ruff-format` failed in `fawkes`;
   `tfsec`, `helm`, `kustomize` and the kube validators are not installed.
   That is itself the R4 case: the result depends on the machine.

## What it means for the budgets (decision 2)

Without `unit-tests`, pre-commit is 6–12 s per repo over all files, near the
10 s budget and well under it for a typical changed-files commit. So the
10 s pre-commit budget holds **if** unit tests leave the every-commit path.
Next, in order:

1. One hook per test suite, each with its own `files:`, so a commit runs only
   the suites its change affects; the full run moves to pre-push.
2. Run the suites in parallel (33 s → ~15 s).
3. Revise the spec with these numbers and the layered-gate model (commit
   gate seconds, push gate about a minute, CI as backstop).

Deferred: caching test results by content hash. It is fast, but a missed input
gives a stale pass; per-suite `files:` gets most of the gain without that risk.
