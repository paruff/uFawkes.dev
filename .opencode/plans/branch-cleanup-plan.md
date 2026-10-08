# Suite Branch Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Delete landed and throwaway branches from all 7 suite repos (remote + local) using machine-checked evidence, while preserving every stranded branch as a draft PR.

**Architecture:** Three phases over ephemeral tooling in `/tmp/opencode/branch-triage/`: a read-only triage script classifies every branch into AUTO / KEEP / STRANDED (JUNK is an annotation on AUTO rows) from git ancestry, patch-id, and PR history; the owner approves the tables; a gated executor deletes only approved rows, re-verifying open PRs at execution time. No suite repo source files are modified.

**Tech Stack:** bash + git (blobless bare clones, `merge-base --is-ancestor`, `git cherry`), authenticated GitHub MCP (PR listing, draft PR creation), GitHub REST API (`delete_branch_on_merge` toggle).

**Spec:** The approved chat design of 2026-10-08 in this session; repo list from `docs/ai-sdlc/suite-release/intent.md` § "The seven repos".

## Global Constraints

- Never delete: the default branch; any branch with an open PR at execution time; keep-list patterns `release*`, `release-please*`, `gh-pages`; any STRANDED row.
- STRANDED = commits not on main (by ancestry or patch-id) AND no merged PR AND no open PR → preserved + draft PR, never deleted.
- All tooling ephemeral in `/tmp/opencode/branch-triage/`; no suite repo file changes, except the `.opencode/plans/` handoff update which commits via a PR per GitOps rules — only after the owner asks for a commit.
- Local deletions use `git branch -d`; `-D` only for rows the owner explicitly reclassifies at the approval gate.
- No deletion runs before the owner approves the Phase 2 tables.
- STRANDED (owner's call, 2026-10-08): keep the branch AND open a draft PR for it.

## Review Focus

- Deleting a branch that has an open PR would close that PR → the executor re-queries open PRs per repo immediately before deleting, never trusting the triage snapshot (Task 6, re-verify step).
- A PR opened between triage and execution (TOCTOU) → same execution-time re-verify gate.
- Squash-merged branches are not ancestors of main → landed signals are PR `merged_at` plus `git cherry` patch-id; ancestry alone is insufficient (Task 3 spot-check).
- Partial deletion on a network failure → executor logs per-branch success/failure and is idempotent; a re-run skips branches already gone (Task 6 log step).
- API rate limits while paging PR histories (fawkes has 250+ branches) → per-repo paging aborts that repo only, with a retry note, never a partial verdict table.
- Accidental deletion of release-automation branches → keep-list is checked inside the executor, not only during triage (Task 6 guard step).

---

### Task 1: Preflight — write-auth probe and baseline snapshot

**Files:**

- Create: `/tmp/opencode/branch-triage/baseline.txt`

**Interfaces:**

- Produces: `baseline.txt` with one line per repo: `<repo> <head-count>` — consumed by Task 7 verification.

- [ ] **Step 1: Create the workspace**

Run: `mkdir -p /tmp/opencode/branch-triage`
Expected: directory exists.

- [ ] **Step 2: Probe write auth**

Run: `git push --dry-run origin :refs/heads/__cleanup_probe__`
Expected: any response that is NOT an authentication error (e.g. `remote: Does not match` / `unable to delete` / `+ ...` dry-run output) = PASS. An `Authentication failed` / `403` / `Permission denied` error = STOP; ask the owner for `GH_TOKEN` or `gh auth login` before continuing.

- [ ] **Step 3: Snapshot baseline head counts**

Run, for each of `uFawkes.dev uFawkesAI uFawkesObs uFawkesPipe uFawkesDevX fawkes uFawkesDojo`:
`git ls-remote --heads https://github.com/paruff/<repo>.git | wc -l`
Expected: 7 counts written to `baseline.txt`; matches the triage-time heads (78/114/293/73/35/254/47 ± drift).

### Task 2: Triage script

**Files:**

- Create: `/tmp/opencode/branch-triage/triage.py`

**Interfaces:**

- Consumes: `git ls-remote`, a blobless bare clone per repo at `/tmp/opencode/branch-triage/<repo>.git`, and the PR list fetched via the GitHub MCP/API.
- Produces: `/tmp/opencode/branch-triage/<repo>.tsv` with columns `branch, last_commit, ahead, ancestor, patch_on_main, open_pr, merged_pr, verdict` and a per-repo markdown table `<repo>.md`.

- [ ] **Step 1: Write the classification script**

Exact rules, first match wins:

1. `KEEP` — branch is the default branch, OR `open_pr=yes`, OR name matches `release*` / `release-please*` / `gh-pages`.
2. `STRANDED` — `ancestor=no` AND `patch_on_main=no` AND `merged_pr=no` AND `open_pr=no`.
3. `AUTO` — `merged_pr=yes` OR `ancestor=yes` OR `patch_on_main=yes`.
4. Annotate AUTO rows matching `scratch/*` or `paruff-patch-1` as `JUNK` (same deletion treatment as AUTO).

Signals: `ancestor` = `git merge-base --is-ancestor <branch> main`; `patch_on_main` = `git cherry main <branch>` has no `+` lines; `open_pr` / `merged_pr` = map built from the repo's PR list (`state=all`, paged, head.ref → state + `merged_at`).

- [ ] **Step 2: Verify on the smallest repo**

Run the script against `uFawkesDevX` (35 heads).
Expected: row count == 35; every row has exactly one verdict; `main` is KEEP; no STRANDED row has `open_pr=yes`.

### Task 3: Run triage across all 7 repos

**Files:**

- Create: `/tmp/opencode/branch-triage/<repo>.tsv`, `<repo>.md`, `summary.md`

- [ ] **Step 1: Run the script per repo**

Expected: 7 TSVs + 7 tables; each table's verdict counts sum to that repo's head count.

- [ ] **Step 2: Spot-check three known uFawkes.dev branches**

`docs/ac-ai-09-evidence` → AUTO (merged PR #163); `scratch/recheck` → AUTO (ancestor); `docs/ci-plan-pipe-woodpecker` → AUTO via `patch_on_main` if its commit was re-landed, otherwise STRANDED.
Expected: verdicts match; any surprise = classification bug, fix before proceeding.

- [ ] **Step 3: Write `summary.md`**

Per repo: counts per verdict + grand totals across the suite.

### Task 4: Owner approval gate

- [ ] **Step 1: Present tables and summary to the owner**

Show per-repo verdict tables with STRANDED rows highlighted.
Expected: owner approves, or moves rows to KEEP / reclassifies; no execution happens in this task.

### Task 5: Open draft PRs for confirmed STRANDED branches

**Interfaces:**

- Produces: draft PR URLs, one per confirmed STRANDED branch, via MCP `github_create_pull_request` (`draft: true`, `base: main`).

- [ ] **Step 1: Create one draft PR per STRANDED branch**

Title: `docs(preserve): stranded branch <repo>:<branch>`; body: triage evidence (ahead count, last commit date, no merged PR).
Expected: PR created per row; count of created PRs == approved STRANDED count; failures logged and reported, never silently skipped.

### Task 6: Gated executor

**Files:**

- Create: `/tmp/opencode/branch-triage/execute.sh`, `/tmp/opencode/branch-triage/cleanup-log-<date>.md`

**Interfaces:**

- Consumes: the owner-approved TSV rows (AUTO + JUNK only).
- Produces: `cleanup-log-<date>.md` lines: `repo, branch, verdict, evidence, timestamp, result`.

- [ ] **Step 1: Write the executor with hard guards**

Per row, before `git push origin --delete <branch>`: re-query that repo's OPEN PRs fresh and refuse if the branch is a head of any; refuse default branch; refuse keep-list patterns; then delete and log. `git branch -d` for matching local branches (`-D` only on explicit owner reclassifications).

- [ ] **Step 2: Dry-run**

Run executor with a `DRY_RUN=1` flag printing planned deletions without pushing.
Expected: planned list matches the approved rows exactly; owner sees it once.

- [ ] **Step 3: Execute**

Run for real. Expected: every planned row logged `deleted` or `refused: <guard>`; re-run is safe (already-deleted rows log `already-gone`).

### Task 7: Verification

- [ ] **Step 1: Recount heads and compare to baseline**

Run: same `ls-remote | wc -l` loop as Task 1 against `baseline.txt`.
Expected: per-repo delta == deleted count; remaining head count == baseline − deleted.

- [ ] **Step 2: Confirm no open PR was lost**

Compare open-PR counts per repo before vs. after (MCP `list_pull_requests state=open`).
Expected: identical counts; any drop = incident, investigate immediately.

### Task 8: Prevention toggle — auto-delete head branches

- [ ] **Step 1: Enable `delete_branch_on_merge` on all 7 repos**

`gh api -X PATCH repos/paruff/<repo> -f delete_branch_on_merge=true` per repo.
Expected: 7 successes. If `gh` is unauthenticated (it currently is), fall back to sending the owner the exact manual toggle path (repo → Settings → General → pull requests) and record completion status.

### Task 9: Handoff record

- [ ] **Step 1: Update `.opencode/plans/plan.md` handoff section**

Record: before/after counts, deletion log path, stranded draft PR links, prevention-toggle status.

- [ ] **Step 2: Commit via PR only if the owner asks**

Branch `docs/branch-cleanup-handoff`, commit `docs(plans): record the suite branch cleanup outcome` — one PR, GitOps rules; never direct to main.
