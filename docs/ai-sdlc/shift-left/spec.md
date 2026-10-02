# Spec: Shift the suite left, and know when it isn't

**Traces to:** [`intent.md`](intent.md) | **Status:** Draft | **Revision:** 1

## Requirements

**R1. Stages and budgets.** A check runs at the earliest stage whose budget
it fits. A check that exceeds its budget moves one stage right, never off.

| Stage      | Budget                                  | What runs                                                                                                                                                    |
| ---------- | --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| commit-msg | under 1 second                          | Conventional Commits: the subject's description is 1 to 72 characters, the same regex CI uses                                                                |
| pre-commit | 10 seconds, on changed files only       | Format and lint, shellcheck, **actionlint**, yamllint, markdownlint, secrets (gitleaks), **config schemas** (dependabot, workflows, catalog), **type check** |
| pre-push   | 3 minutes, on changed and affected code | **Unit tests**, **SAST** (semgrep), dependency and IaC scan (Trivy), policy tests (conftest)                                                                 |
| CI         | no budget                               | The same hooks via the same command, plus what needs infrastructure: integration, container scan, end-to-end, CodeQL                                         |

**R2. The catalog, and today's gaps.** Counted from each repo's hook config
on 2026-10-02 (seven repos):

| Check                   | Tool                                                      | Stage      | Hooks today                    | What it would have caught                              |
| ----------------------- | --------------------------------------------------------- | ---------- | ------------------------------ | ------------------------------------------------------ |
| GitHub Actions lint     | actionlint                                                | pre-commit | **0 of 7**                     | Workflow typos before a red run                        |
| Config schema           | check-jsonschema (dependabot.yml, workflows)              | pre-commit | **0 of 7**                     | fawkes's invalid Dependabot group, live for 5 weeks    |
| SAST                    | semgrep, pinned, same ruleset as CI                       | pre-push   | **0 of 7** (CI-only in 1)      | Dependabot `cooldown`, found only after pushing        |
| Type check              | mypy or pyright; `tsc --noEmit`; `go vet` and staticcheck | pre-commit | **0 of 7**                     | Type errors found in review instead of at the keyboard |
| Dependency and IaC scan | Trivy (table output), conftest, kubeconform               | pre-push   | 2 per repo, tool-dependent     | DevX's silent failure (see R8)                         |
| Unit tests              | the repo's runner                                         | pre-push   | 6 of 7 (fawkes: none)          | Regressions before they reach CI                       |
| Commit-msg convention   | `scripts/commit-msg.sh`                                   | commit-msg | defined in 7, installed in few | The 73-character title                                 |

Type checking is a per-repo decision, not a rule: it applies where the repo
has Python, TypeScript or Go, and not to a Jekyll site.

**R3. The same command locally and in CI.** CI runs `pre-commit run
--all-files --show-diff-on-failure` (and the same with `--hook-stage
pre-push`), so a hook added to the config runs in CI with no workflow edit.
A hook may be excluded from CI only by an entry in `.shift-left.yml`:

```yaml
local-only: # runs on a laptop, not in CI
  - id: shift-left-stamp
    reason: records that hooks ran; meaningless in CI
ci-only: # needs infrastructure a laptop lacks
  - id: integration-tests
    reason: needs the compose stack
```

The parity check (D6) fails a PR when a configured hook is in neither CI nor
`.shift-left.yml`.

**R4. No silent passes.** `scripts/require-tool.sh <tool> [min-version]`
wraps every `language: system` hook. A missing or too-old tool exits 1.
The only way past it is `SHIFT_LEFT_ALLOW_MISSING=<tool>`, which prints a
loud `SKIPPED (tool missing): <tool>` line and is listed in the doctor
report. Hooks prefer `language: python` or `node` with pinned dependencies,
which pre-commit installs itself, over `system`.

**R5. The doctor.** `scripts/doctor.sh`, run as `make doctor`. One line per
check with a fix command, exit 1 on any failure, and `--quiet` prints only
problems (so it can run unattended without noise).

| ID  | Checks                                                                                                                           |
| --- | -------------------------------------------------------------------------------------------------------------------------------- |
| D1  | Every hook stage the config defines is installed in `.git/hooks` and managed by pre-commit                                       |
| D2  | Every local hook's `entry` resolves: the script exists and is executable, or the system tool is on `PATH` at its minimum version |
| D3  | `pre-commit` is installed and meets `minimum_pre_commit_version`                                                                 |
| D4  | The config validates and the hook environments are installed                                                                     |
| D5  | Each stage has run since the last commit: a stamp file per stage, written by a tiny always-run hook                              |
| D6  | CI parity (R3): every hook ID is run by CI or listed in `.shift-left.yml`                                                        |
| D7  | The CI jobs from R3 are required checks in the ruleset (skipped, with a note, when `gh` isn't authenticated)                     |

The doctor is self-tested with fault injection, in the style of
`test-artifact-chain.sh`: each scenario breaks one thing in a throwaway repo
and asserts the right check fails (AC-SHIFT-07).

**R6. Three alert surfaces.**

- **Local.** The devcontainer's `postCreateCommand` runs `pre-commit install`
  then the doctor. A Claude Code `SessionStart` hook runs `doctor --quiet`,
  silent when healthy. `make doctor` on demand. A hook can't detect that
  hooks aren't installed, so the local alert has to come from something that
  isn't a git hook.
- **Pull request.** The parity job (D6) fails the PR.
- **Fleet.** `scripts/shift-left-audit.sh` in uFawkes.dev reads all seven
  repos through `gh api`: hook config, hook types, the CI hook job and its
  last result on `main`, required checks, and Dependabot validity. It writes
  `_data/shift_left.json`. A daily workflow runs it, shows the matrix on
  `/status/` (extending the status dashboard), and on a **regression** opens
  or updates one issue per repo labeled `shift-left-drift`, closing it when
  the repo is healthy again. No regression, no issue.

**R7. Required checks.** Once green on `main` and on several PRs, the
ruleset requires the hook job, `Artifact Chain` and the parity job in every
repo.

**R8. Findings must be readable.** A scanner that writes SARIF also prints a
human-readable table of HIGH and CRITICAL findings in the log. A red scan
that can't be diagnosed from its log fails this requirement.

## Acceptance criteria

| ID          | Criterion                                                                                                                           | Verification                                                                        |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| AC-SHIFT-01 | One command installs every hook stage the config defines, and the doctor fails when a stage is missing                              | Fault-injection scenario: remove `commit-msg`, the doctor exits 1 with the fix      |
| AC-SHIFT-02 | No hook passes when its tool is missing, in CI or locally, unless explicitly allowed and reported                                   | Scenario: unset the tool, the hook fails; with the allow variable it prints SKIPPED |
| AC-SHIFT-03 | Every configured hook runs in CI or is listed with a reason; drift fails the PR                                                     | Scenario: add a hook to the config only, the parity check fails                     |
| AC-SHIFT-04 | actionlint, config-schema, SAST and unit-test hooks exist in all seven repos; type check wherever the repo has the language         | The audit matrix shows each cell as present or as a recorded decision               |
| AC-SHIFT-05 | The semgrep hook uses the same pinned version and ruleset as CI                                                                     | Same finding locally and in CI on a seeded violation                                |
| AC-SHIFT-06 | The fleet audit runs daily, publishes the matrix to `/status/`, and files one issue per regressed repo within 24 hours              | Two scheduled runs; a seeded regression opens one issue, fixing it closes it        |
| AC-SHIFT-07 | A deliberately broken setup is detected: uninstalled stage, deleted hook script, missing tool, removed CI job, hook missing from CI | Fault-injection suite in a throwaway repo, run in CI                                |
| AC-SHIFT-08 | A failing scanner shows its HIGH and CRITICAL findings in the log                                                                   | Seed a vulnerable dependency; the log table names it                                |

## Concerns

- **Speed.** The 3-minute pre-push budget is a guess. Measure first (Phase A)
  and move anything over budget one stage right, with a note.
- **Tools on the laptop.** Semgrep, actionlint, Trivy, gitleaks and
  shellcheck must be installed. The devcontainer image should bake them
  (this extends AC-AI-09); outside it, the doctor prints install hints.
- **Semgrep parity.** `p/ci` is fetched from a registry. A hook that needs
  the network at commit time will be disabled by the first person on a
  plane. Decide between a vendored ruleset file and an online-only pre-push.
- **Noise.** Fleet issues fire on regression only, once per repo, and close
  themselves. An alert that cries wolf gets muted, and a muted alert is the
  problem this spec exists to solve.
- **Type checking is a decision per repo**, tracked as its own issues so the
  owner chooses the tool.
