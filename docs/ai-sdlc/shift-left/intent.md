# Intent: Shift the suite left, and know when it isn't

**Owner:** @paruff | **Created:** 2026-10-02 | **Status:** Draft

## Problem

The suite already has the right checks. What it doesn't have is any way to
know whether a check is actually running. In one week, replacing
pre-commit.ci surfaced nine ways a check can exist on paper and do nothing:

| #   | What was found                                                                                                                              | Effect                                                               |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| 1   | The `commit-msg` and `pre-push` hooks were defined in six repos but not installed in most clones                                            | A 73-character commit title reached `main`                           |
| 2   | uFawkes.dev's commit-msg hook pointed at `scripts/commit-msg.sh`, a file that was never added                                               | The hook could never run                                             |
| 3   | The `mkdocs-validate` hook prints a warning and **passes** when `mkdocs` is missing, and failed on a machine whose `mkdocs` lacked a plugin | "Green" on machines where it doesn't run; red on others              |
| 4   | Dojo's commit-msg hook read the whole message, not the subject                                                                              | Rejected every commit with a body; disagreed with CI                 |
| 5   | The vendored `test-artifact-chain.sh` inherited git's hook environment                                                                      | Rewrote the real index and switched branches under a hook            |
| 6   | The artifact-chain scripts were copied into six repos, but no workflow ran them                                                             | A check that never ran, for months                                   |
| 7   | fawkes's `dependabot.yml` was invalid for five weeks                                                                                        | Dependabot's pip updates failed silently; nothing validates the file |
| 8   | DevX's Trivy scan fails, writes SARIF only, and prints no findings                                                                          | A red check nobody can diagnose from the log                         |
| 9   | Semgrep ran only in CI; its `dependabot-missing-cooldown` rule is in no local hook                                                          | Found after pushing, not before                                      |

Underneath that, all seven repos carry the same hook set, and **none has an
actionlint, type-checking or SAST hook**. Those checks run in CI or not at
all, so the feedback loop is a push, a wait and a red X.

## Desired outcome

1. **Shift left.** Every check that can run on a laptop in the time a
   developer will tolerate does, at the earliest stage that makes sense
   (commit-msg, pre-commit, pre-push), and CI runs _the same command_.
2. **No silent passes.** A configured check that isn't installed, can't find
   its tool, or didn't run is a loud failure, never a green tick.
3. **Alert on drift.** One command tells a developer what's missing in their
   clone. A scheduled audit tells the owner what's missing across the whole
   suite, and files an issue when a repo regresses.

## Users

- **Developers and agents** (you, Claude Code, OpenCode), who want a problem
  caught in seconds on their machine and the same verdict in CI.
- **The owner**, who wants one place that says which repos have which checks,
  where they run, and where they've stopped.

## Constraints

- **Speed budgets.** A check that makes commits slow gets disabled by the
  people it was meant to help. Each stage has a budget (see the spec).
- **Same command locally and in CI.** Parity is the point. Two copies of a
  check drift, as pre-commit.ci's skip list did.
- **Languages are per repo.** A type checker is added where the language has
  one (Python, TypeScript, Go), not imposed on a Jekyll site.
- **Alerts must not leak secrets** and must be quiet when nothing is wrong.
- No new always-on service. GitHub Actions, git hooks and `gh` only.

## Where it lives

The template (uFawkesAI) owns the standard hook set, the doctor script and
the parity check, and the other six repos adopt them, as they did the
artifact-chain check. The fleet-wide audit and its alerting live in
uFawkes.dev, next to the status dashboard it feeds.

## Out of scope

- Writing new tests. This is about making existing tests run earlier.
- Replacing CI. Integration, container and end-to-end tests stay in CI.
- Per-language linter tuning (rule choices inside ruff or eslint).
