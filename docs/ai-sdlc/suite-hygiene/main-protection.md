# The suite's main-protection standard

**Status:** Proposed, for the owner's decision | **Read from GitHub:** 2026-10-06 |
**Traces to:** shift-left [spec](../shift-left/spec.md) R7 and D7, [plan](../shift-left/plan.md) E1,
suite-release phase 0 (issues [#99](https://github.com/paruff/uFawkes.dev/issues/99),
[#147](https://github.com/paruff/uFawkes.dev/issues/147))

Ruleset and repository settings are owner-only, and an agent never bypasses
branch protection (AI_STANCE.md). This page is what to apply and what differs.

**Where the old standard went wrong.** The GitOps migration plan
(`.opencode/plans/gitops-migration.md`, Phase 3) specified: a pull request, a
status check named `Validate`, no force pushes, and `required_linear_history`.
`CLAUDE.md` §10 repeated that. The rulesets that were actually created have no
linear-history rule, and no repo has a check named `Validate`. Each repo got its own
checks as its CI grew. So the stated standard was never the real one. This replaces it,
and `CLAUDE.md` §10 now points here.

## The standard

One ruleset per repo, named **`main-protection`**, targeting the default branch
(`~DEFAULT_BRANCH`), enforcement `active`, **no bypass actors**:

| Rule                      | Setting                                                                                       | Why                                                                |
| ------------------------- | --------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| `deletion`                | on                                                                                            | `main` can't be deleted                                            |
| `non_fast_forward`        | on                                                                                            | No force pushes                                                    |
| `required_linear_history` | on                                                                                            | Matches squash-only merging (decision 1)                           |
| `pull_request`            | 0 approvals, dismiss stale reviews on push, no code-owner review, no thread rule              | One maintainer: the PR is the audit trail, the checks are the gate |
| `required_status_checks`  | the **hook job** and **`🔗 Artifact Chain`**, plus what the repo already requires; not strict | Spec R7: a red hook run, or a PR with no AI-SDLC plan, can't merge |

Repository settings, the same in all seven:

| Setting                | Value                     | Why                                                                                             |
| ---------------------- | ------------------------- | ----------------------------------------------------------------------------------------------- |
| Merge methods          | **squash only**           | One conventional-commit title per PR; `Merge pull request #N` titles fail the `commit-msg` hook |
| Delete branch on merge | **on**                    | Also makes GitHub retarget a stacked PR to `main` when its base merges (see delta 3)            |
| Allow auto-merge       | on (optional)             | Lets a chain of PRs merge itself in order once its checks pass                                  |
| CODEOWNERS             | `.github/CODEOWNERS` only | GitHub reads `.github/` first; a second copy at the root is ignored and drifts                  |

Check names are exact, emoji included. A reusable-workflow call appears as `<caller job> / <job>`.

### The check names, per repo

| Repo        | Hook job                               | Artifact Chain                          | Already required: keep                                                   |
| ----------- | -------------------------------------- | --------------------------------------- | ------------------------------------------------------------------------ |
| uFawkes.dev | `Pre-flight / Pre-flight Checks`       | `🔗 Artifact Chain`                     |                                                                          |
| uFawkesAI   | `✈️ Pre-flight / Pre-flight Checks`    | `🔗 Artifact Chain / 🔗 Artifact Chain` | `✅ CI Complete`, `🧪 Agent config evals`                                |
| uFawkesObs  | `Pre-flight / Pre-flight Checks`       | `🔗 Artifact Chain`                     | `Security`, `Integration Tests`, `🛡️ Main CI Health / 🛡️ Main CI Health` |
| uFawkesPipe | `Pre-flight / Pre-flight Checks`       | `🔗 Artifact Chain`                     |                                                                          |
| uFawkesDevX | `Pre-flight / Pre-flight Checks`       | `🔗 Artifact Chain`                     |                                                                          |
| uFawkesDojo | `Pre-commit hooks / Pre-flight Checks` | `🔗 Artifact Chain`                     | `commit-lint`, `markdownlint`                                            |
| fawkes      | `Pre-commit · Base`                    | `🔗 Artifact Chain`                     |                                                                          |

A skipped required check counts as passing, so fawkes's conditional layers
(`Pre-commit · Language`, `· Tool`, `· Platform`) stay out: `Base` always runs and holds the parity check.

## What each repo has today (read 2026-10-06)

| Repo        | Rulesets                                                                | Required checks                                         | Linear | `deletion` | Admin bypass | Delete branch on merge | Merge methods         |
| ----------- | ----------------------------------------------------------------------- | ------------------------------------------------------- | :----: | :--------: | :----------: | :--------------------: | --------------------- |
| uFawkes.dev | `main-protection`, plus `Block force pushes` and `validate`, both inert | Pre-flight                                              |   no   | inert only |   **yes**    |           no           | squash, merge, rebase |
| uFawkesAI   | `main` and `main-protection`, overlapping                               | Pre-flight, CI Complete, Agent evals                    |   no   |    yes     |      no      |           no           | all three             |
| uFawkesObs  | `main-protection`, plus classic branch protection                       | Security, Integration Tests, Main CI Health, Pre-flight |   no   |     no     |      no      |           no           | all three             |
| uFawkesPipe | `main-protection`                                                       | Pre-flight                                              |   no   |     no     |      no      |           no           | all three             |
| uFawkesDevX | `main-protection`                                                       | Pre-flight                                              |   no   |     no     |      no      |           no           | all three             |
| uFawkesDojo | `main protection` (no hyphen)                                           | Pre-flight, commit-lint, markdownlint, Artifact Chain   |   no   |    yes     |      no      |           no           | all three             |
| fawkes      | `main-protection`                                                       | **none**                                                |   no   |     no     |      no      |           no           | all three             |

The same in all seven: `non_fast_forward` on; a pull request required with 0 approvals and stale reviews dismissed; checks not strict.

## The deltas, and how to resolve each

Ordered by risk. "Settings" is the repo's Settings page; "Rules" is Settings → Rules → Rulesets.

1. **fawkes requires no checks.** A red hook run doesn't block a merge (the doctor's D7 reports it).
   _Resolve:_ once paruff/fawkes#2219 and its follow-up adoption PR are on `main`, add `Pre-commit · Base`
   and `🔗 Artifact Chain` to its `main-protection`.
2. **Artifact Chain is required only in Dojo.** It runs on every PR to `main` in six repos (not
   path-filtered) and as a `workflow_call` in uFawkesAI, so requiring it can't leave a PR waiting for a check
   that never reports. _Resolve:_ add it to the other six (table above).
3. **Delete branch on merge is off everywhere, and stacked PRs have stranded work.** With it off, a PR stacked
   on another stays pointed at the first branch after that one merges, so merging it lands the work on a dead
   branch, not `main`. That happened in fawkes (#2204–#2206), uFawkesObs (#616) and uFawkesAI (#191), and was
   caught in time in uFawkes.dev (#145). Each adoption had to be re-landed from `main`. _Resolve:_ turn it on in
   all seven (Settings → General → "Automatically delete head branches"). Until then, retarget a stacked PR to
   `main` before merging it.
4. **Linear history isn't enforced anywhere**, though the old standard said so. uFawkes.dev's own history is
   merge commits. _Resolve:_ decision 1 below, then add `required_linear_history` and set merge methods to squash only.
5. **uFawkesObs has classic branch protection on top of its ruleset**, requiring **1 approving review**
   while every ruleset requires 0, plus strict checks. It only works because admins aren't enforced.
   _Resolve:_ delete the classic rule (Settings → Branches); the ruleset covers it.
6. **uFawkes.dev has two inert rulesets** (`Block force pushes`, `validate`): their `include` is empty, so they
   match no branch, and `validate` requires nothing. _Resolve:_ delete both; `main-protection` already blocks force pushes.
7. **uFawkes.dev lets repository admins bypass pull-request rules**, the only repo that does. It lets you skip
   your own checks. _Resolve:_ decision 2 below.
8. **uFawkesAI has two overlapping rulesets** (`main` on the default branch, `main-protection` on
   `refs/heads/main`), each holding part of the rules. _Resolve:_ merge them into one `main-protection` with the
   union of their rules, then delete `main`.
9. **Dojo's ruleset is named `main protection`** (no hyphen), and has `deletion`, which the others lack.
   _Resolve:_ rename it, and add `deletion` to the other six.
10. **Duplicate CODEOWNERS** (root and `.github/`) in uFawkes.dev, uFawkesAI and fawkes. _Resolve:_ delete the
    root copy after checking it matches `.github/CODEOWNERS`.

### Decisions I need from you

1. **Merge method:** squash only (recommended; it's what the old standard intended), or keep merge commits.
   Squash makes `required_linear_history` true and removes the `Merge pull request` titles the commit-msg hook rejects.
2. **Admin bypass on uFawkes.dev:** remove it (recommended; the other six have none), or keep it as your
   emergency exit. Pre-flight already has an `emergency-bypass` input for a logged exception.
3. **`required_linear_history`:** on with decision 1, or off.

## Applying a ruleset

`main-protection.ruleset.json` is the standard with an empty check list. For a repo that already has a
ruleset, update it with `PUT`; otherwise create it with `POST`:

```bash
REPO=uFawkesPipe
CHECKS='["Pre-flight / Pre-flight Checks","🔗 Artifact Chain"]'   # the table above, plus the repo's existing ones
jq --argjson c "$CHECKS" '.rules |= map(if .type=="required_status_checks"
     then .parameters.required_status_checks = ($c | map({context: .})) else . end)' \
  docs/ai-sdlc/suite-hygiene/main-protection.ruleset.json > /tmp/ruleset.json
gh api repos/paruff/$REPO/rulesets --jq '.[] | "\(.id) \(.name)"'           # find the id, if one exists
gh api -X PUT  repos/paruff/$REPO/rulesets/<id> --input /tmp/ruleset.json    # update it
# gh api -X POST repos/paruff/$REPO/rulesets       --input /tmp/ruleset.json  # or create it
```

Afterwards, run `bash scripts/shift-left.sh doctor` in the repo (D7), and compare
`gh api repos/paruff/$REPO/rulesets` with the tables above. A re-runnable audit of all seven is tracked in the
Suite hygiene goal.
