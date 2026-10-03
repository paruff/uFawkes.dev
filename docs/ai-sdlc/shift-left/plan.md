# Plan: Shift the suite left, and know when it isn't

**Traces to:** [`spec.md`](spec.md) → [`intent.md`](intent.md) | **Status:** In progress | **Revision:** 2

Small PRs, each mergeable alone. Measure first, because the stage budgets in
the spec are guesses until we've timed the real hooks.

**Progress:** A1–A3 done (full unit run 33 s → 14 s); A4 is spec revision 2; A1's first run is [`baseline.md`](baseline.md).
`unit-tests` is 60–80% of pre-commit in every repo, so before phase B:
A2 runs only the test suites a commit affects (all of them in CI and at pre-push),
A3 runs the suites in parallel, and A4 revises the spec from the baseline.

## Order of work

| Phase | What                                                                                                                                                  | Route | Why that route                                      |
| ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ----- | --------------------------------------------------- |
| A1    | `scripts/shift-left-audit.sh` (read-only): the matrix of check × repo, plus a per-hook timing. Its first run is the baseline                          | U     | Bounded; the spec gives the output                  |
| A2    | The `unit-tests` hook passes the staged files; `run-unit-tests.sh` maps them to the suites they affect, and every suite must be mapped                | U     | One hook keeps A3's parallel run useful             |
| A3    | `scripts/run-unit-tests.sh` runs its suites in parallel (33 s → ~15 s in the baseline)                                                                | U     | Suites already use their own temp dirs              |
| A4    | Revise the spec's budgets and stages from the baseline (decision 2)                                                                                   | G     | Owner decision                                      |
| B1    | `scripts/require-tool.sh`, and convert every `language: system` hook to use it or to a pinned `python`/`node` hook (R4, AC-SHIFT-02)                  | U     | Mechanical once the wrapper exists                  |
| B2    | `scripts/doctor.sh`, the stamp hook, `make doctor`, and the fault-injection suite (R5, AC-SHIFT-01, AC-SHIFT-07)                                      | G     | Design: what each check inspects, and the scenarios |
| B3    | New hooks in the template: actionlint, check-jsonschema, semgrep (pinned), unit tests at pre-push, Trivy with a table (R2, R8, AC-SHIFT-04, -05, -08) | U     | Bounded, after the semgrep offline decision         |
| B4    | CI parity job and `.shift-left.yml` (R3, AC-SHIFT-03)                                                                                                 | G     | Design of the config format and the parity rules    |
| B5    | Devcontainer: `postCreateCommand` runs install then doctor; bake the tools into the image (R6, extends AC-AI-09)                                      | G     | Touches the image and its publish path              |
| B6    | Agent-loop gate: a `Stop` hook runs the commit-stage hooks on the agent's changed files and blocks on failure (R9, AC-SHIFT-10)                       | G     | Harness config, shared by every contributor         |
| B7    | `shift-left-fix` skill: sort a failure log into mechanical or needs-judgment, fix the first, rerun the hook (R10, AC-SHIFT-11)                        | G     | The limits on what it may change need care          |
| C1-6  | Adopt B in each of the six repos: copy, write its `.shift-left.yml`, record its type-check decision                                                   | U ×6  | One repo each, with a written spec                  |
| D1    | The daily fleet audit workflow, `_data/shift_left.json`, and the `/status/` matrix panel (R6, AC-SHIFT-06)                                            | G     | Secrets, the deploy path, and issue creation        |
| D2    | Issue-on-regression: open or update one `shift-left-drift` issue per repo, close on recovery                                                          | G     | Quiet-by-default logic needs care                   |
| E1    | Make the hook job, `Artifact Chain` and the parity job required checks (R7)                                                                           | G     | A ruleset change; owner-only, and only once green   |
| F1-n  | Type checking per language: decide the tool per repo, then add the hook (R2). One decision issue per repo, then an implementation issue               | G → U | The owner picks the tool; the wiring is mechanical  |

**Decisions needed before phase B** (each is a short issue, route G):

1. **Semgrep and the network.** Vendor the ruleset file so the hook works
   offline, or run semgrep online-only at pre-push. The spec leans towards
   vendoring, so a commit on a train still works.
2. ~~**Stage budgets.**~~ Settled by A4 (spec revision 2): 10 seconds at
   pre-commit, 60 seconds at pre-push, each stage run once.
3. **Where the `SessionStart` doctor lives.** In each repo's committed
   `.claude/settings.json` (so every contributor and agent gets it), or in your
   user settings (just you). The repo is the better default.
4. **Type-check tools per repo.** Which repos have which language, and which
   checker: mypy or pyright, `tsc`, `go vet` and staticcheck.

## Verification Strategy

| Criterion   | How it's proven                                                                                                       | Test type   | Command / CI job                                       |
| ----------- | --------------------------------------------------------------------------------------------------------------------- | ----------- | ------------------------------------------------------ |
| AC-SHIFT-01 | Remove a hook stage in a throwaway repo; the doctor exits 1 and names the fix                                         | unit        | `bash scripts/test-doctor.sh` (scenario)               |
| AC-SHIFT-02 | Unset a tool; the hook fails. With `SHIFT_LEFT_ALLOW_MISSING`, it prints `SKIPPED`                                    | unit        | `bash scripts/test-doctor.sh` (scenario)               |
| AC-SHIFT-03 | Add a hook to the config only; the parity check fails                                                                 | unit        | `bash scripts/test-doctor.sh` (scenario)               |
| AC-SHIFT-04 | The audit matrix shows every required cell present or as a recorded decision                                          | integration | `scripts/shift-left-audit.sh`, reviewed per phase      |
| AC-SHIFT-05 | A seeded semgrep violation fails identically locally and in CI                                                        | integration | A throwaway PR with a seeded violation                 |
| AC-SHIFT-06 | Two scheduled audit runs; a seeded regression opens exactly one issue, and fixing it closes it                        | live-system | `gh run list -w shift-left-audit.yml`, `gh issue list` |
| AC-SHIFT-07 | The full fault-injection suite: uninstalled stage, deleted script, missing tool, removed CI job, hook missing from CI | unit        | `bash scripts/test-doctor.sh`, run in CI               |
| AC-SHIFT-08 | A seeded vulnerable dependency: the log table names it                                                                | integration | A throwaway PR in a repo with a scanner                |
| AC-SHIFT-09 | Per-stage timings within 10 s and 60 s in every repo                                                                  | integration | `make shift-left-audit ARGS=--time`, per phase         |
| AC-SHIFT-10 | An agent edit that breaks a lint: the `Stop` hook blocks and shows the failure                                        | integration | A scripted session in a throwaway repo                 |
| AC-SHIFT-11 | Seeded lint, format and failing-test failures: the first two are fixed and rerun green, the test is handed off        | integration | The skill run against a seeded log                     |

## Risks

| Risk                                                       | Mitigation                                                                                    |
| ---------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| Hooks get slow and people bypass them                      | Phase A1 times every hook first; anything over budget moves one stage right, with a note      |
| The doctor reports false problems and gets ignored         | `--quiet` mode; fault-injection tests prove each check fires only on its fault                |
| A hook runs the test harness under git's environment       | Already fixed in the artifact-chain test (`unset GIT_*`); doctor scenarios use the same guard |
| Fleet issues become noise                                  | Regression-only, one per repo, auto-closing                                                   |
| A required check blocks every merge if it is red on `main` | Phase E waits for it to be green on `main` and on several PRs first                           |
| Tools missing on a laptop                                  | Bake them into the devcontainer image; the doctor prints install hints elsewhere              |
