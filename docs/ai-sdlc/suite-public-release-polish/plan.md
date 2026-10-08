# Plan: Suite-Wide Public Release Polish

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring all 7 uFawkes/fawkes suite repos to a consistent public release baseline: governance files, release automation, clean docs, repo-specific templates.

**Architecture:** Cross-repo governance/documentation/automation plan. Tasks grouped by category (Legal, Release, Docs, Templates) and ordered so foundational items land first. Each repo gets consistent baseline; changes are independently reviewable per repo.

**Tech Stack:** Markdown, YAML (GitHub Actions/workflows), Bash, GitHub repository settings.

**Spec:** [spec.md](spec.md) — implements public release best practices from Johns Hopkins OSPO, Syracuse University, CNCF project templates.

> **Scope note (2026-10-08):** `ufawkesdora` and `ufawkessec` are archived —
> both were retired and merged into uFawkesObs and uFawkesPipe. They are
> dropped from Phase 2, Task 4.2 and Phase 5 below. Nothing is released or
> polished for them.

---

## Global Constraints

- MIT license standard — no changes
- `[PLACEHOLDER]` in uFawkesAI/docs/ are template features — keep but document
- `AGENTS.md` / `AI_STANCE.md` in uFawkesAI are canonical AI policy
- SemVer + Keep a Changelog — maintain format
- CI Quality Gate (`✅ CI Complete` or equivalent) required in all repos
- **No runtime code changes** — config, docs, workflows only

---

## Review Focus

| Input / Condition                     | Expected Behavior                                              |
| ------------------------------------- | -------------------------------------------------------------- |
| New adopter uses any repo as template | Clean docs, no AI slop, clear governance, working release flow |
| Maintainer cuts release in any repo   | `git tag vX.Y.Z` → automated GitHub Release with notes         |
| Security team audits any repo         | Finds current SECURITY.md with SLAs and private reporting      |
| Community member checks any repo      | Finds Contributor Covenant v2.1 CODE_OF_CONDUCT                |
| Contributor opens PR in any repo      | Template has repo-relevant checks (no cross-repo artifacts)    |

---

## Phase 1: Legal & Governance (All 7 Repos — Parallelizable)

### Task 1.1: Add CODE_OF_CONDUCT.md to 6 Missing Repos

**Repos:** fawkes, uFawkesDevX, uFawkesAI, uFawkes.dev

**Files per repo:**

- Create: `CODE_OF_CONDUCT.md` (root)

**Interfaces:**

- Consumes: None
- Produces: Governance baseline

- [ ] **Step 1: Write failing test**

```bash
for repo in fawkes uFawkesObs uFawkesPipe uFawkesDevX uFawkesDojo uFawkesAI uFawkes.dev; do
  test -f "/Users/philruff/projects/github/paruff/$repo/CODE_OF_CONDUCT.md" \
    && grep -q "Contributor Covenant" "/Users/philruff/projects/github/paruff/$repo/CODE_OF_CONDUCT.md" \
    && grep -q "v2.1" "/Users/philruff/projects/github/paruff/$repo/CODE_OF_CONDUCT.md" \
    || echo "FAIL: $repo"
done
```

- [ ] **Step 2: Create CODE_OF_CONDUCT.md in each repo**
      Use Contributor Covenant v2.1 from https://www.contributor-covenant.org/version/2/1/code_of_conduct/
      Add Enforcement section referencing GitHub Security Advisories and repo's SECURITY.md.

- [ ] **Step 3: Verify all pass** (re-run Step 1 test → all PASS)

- [ ] **Step 4: Commit per repo**

```bash
git -C /Users/philruff/projects/github/paruff/<repo> add CODE_OF_CONDUCT.md
git -C /Users/philruff/projects/github/paruff/<repo> commit -m "governance: add Contributor Covenant v2.1 code of conduct"
```

---

### Task 1.2: Add SECURITY.md to 3 Missing Repos

**Repos:** fawkes, uFawkesAI (verify), uFawkes.dev

**Files per repo:**

- Create/Verify: `SECURITY.md` (root)

**Interfaces:**

- Consumes: uFawkesObs SECURITY.md as canonical template
- Produces: Security reporting standard

- [ ] **Step 1: Extract canonical SECURITY.md from uFawkesObs**

```bash
cat /Users/philruff/projects/github/paruff/uFawkesObs/SECURITY.md
```

- [ ] **Step 2: Create SECURITY.md in missing repos** (adapt maintainer contact per repo)

- [ ] **Step 3: Verify uFawkesAI SECURITY.md matches standard**; update if needed

- [ ] **Step 4: Commit per repo**

---

### Task 1.3: Add/Enhance FUNDING.yml in All 7 Repos

**Repos missing:** fawkes, uFawkesDevX (2)
**Repos minimal:** uFawkesObs, uFawkesPipe, uFawkesAI, uFawkes.dev (4)

**Files per repo:**

- Create/Modify: `.github/FUNDING.yml`

- [ ] **Step 1: Create standard template**

```yaml
# These are supported funding model platforms
github: [paruff]
# patreon: your-handle
# open_collective: your-collective
# ko_fi: your-handle
# tidelift: your-org
# community_bridge: your-project
```

- [ ] **Step 2: Apply to all 7 repos**

- [ ] **Step 3: Verify and commit per repo**

---

## Phase 2: Release Automation (All 7 Repos — Parallelizable)

### Task 2.1: Standardize on release-please.yml

**Current (verified 2026-10-08):** the earlier line here said "release-please in uFawkesObs,
uFawkesPipe, uFawkesDevX (3); none in fawkes, uFawkesAI, uFawkes.dev" — **that was wrong on both
counts**, and the real defect was different from what the plan assumed:

- `.github/workflows/release-please.yml` is **present in all 7**, and is functionally identical to
  the uFawkesPipe canonical in **fawkes, uFawkesAI, uFawkes.dev** (uFawkesObs diverges deliberately:
  `workflow_run` gate on its post-merge acceptance run, plus source-tarball attach — documented in
  the canonical file's own header comment). So Step 2's "apply the workflow" was already satisfied.
- The actual gap was **`release-please-config.json`**: missing in **uFawkesAI, uFawkes.dev,
  uFawkesDojo** (uFawkesDojo was also absent from every repo count in this section). release-please
  action v5 always fetches both files, so every run failed with
  `Missing required manifest config: release-please-config.json`.

| State                | Repos                                                                 | Evidence                                                  |
| -------------------- | --------------------------------------------------------------------- | --------------------------------------------------------- |
| Working (green runs) | fawkes, uFawkesObs, uFawkesPipe, uFawkesDevX (4)                      | last 6 runs each `success`                                |
| Failing every run    | uFawkesAI (4 fails), uFawkes.dev (5 fails), uFawkesDojo (2 fails) (3) | `release-please failed: Missing required manifest config` |

**Files per repo:**

- Create/Modify: `.github/workflows/release-please.yml`
- Auto-generated: `.release-please-manifest.json`

**Interfaces:**

- Consumes: package.json (or pyproject.toml/Cargo.toml/go.mod), CHANGELOG.md
- Produces: Automated GitHub Release on version tag

- [x] **Step 1: Extract canonical release-please.yml from uFawkesPipe**

```bash
cat /Users/philruff/projects/github/paruff/uFawkesPipe/.github/workflows/release-please.yml
```

- [x] **Step 2: Add the missing `release-please-config.json` to uFawkesAI, uFawkes.dev, uFawkesDojo**
      — this, not the workflow file, was the defect. All three already had a canonical workflow, so
      no workflow change was needed. The added config is **byte-identical** to uFawkesDevX's
      (`release-type: simple`, `prerelease: false`, `bump-minor-pre-major` /
      `bump-patch-for-minor-pre-major: true`, suite-standard changelog-sections).
      PRs: `uFawkesAI#215`, `uFawkes.dev#174`, `uFawkesDojo#100`.

      The four working repos keep their deliberate policy differences — no change:
      `fawkes` `prerelease: true, prerelease-type: alpha`; `uFawkesObs` `prerelease: true`;
      `uFawkesPipe` `bump-*-pre-major: false`.

- [x] **Step 3: Verify uFawkesObs, uFawkesPipe, uFawkesDevX configs are current** — all three have
      config + manifest and their runs are green. uFawkesObs's `workflow_run` divergence is
      intentional and documented in the canonical header. The only advisory difference: uFawkesDevX
      omits Pipe's "Check for RELEASE_PLEASE_TOKEN" warning step — its `has_token` output is
      referenced nowhere downstream in any of the 7 workflows, so it is cosmetic only.

- [ ] **Step 4: Test each repo** (dry-run with `release-please` CLI or push test tag to fork) —
      **not run; owner action.** The definitive test is the first post-merge workflow run per repo,
      which is observable on Actions.

- [x] **Step 5: Commit per repo** — the 4 working repos needed no commit; the 3 fixes are in the
      PRs named in Step 2.

---

### Task 2.2: CHANGELOG.md Format Consistency

**Repos:** All 7

- [x] **Step 1: Audit all CHANGELOG.md** for Keep a Changelog + SemVer compliance —
      all 7 have `# Changelog` + Keep a Changelog/SemVer attribution + a SemVer version heading.
      **Deviations found (Step 2 still open):** - `uFawkesPipe` — no `## [Unreleased]` section (the other 6 have one). - `uFawkes.dev` — newest heading `0.1.0` but manifest is `1.0.0`, and the repo has **0 tags**. - `uFawkesDojo` — newest heading `0.2.0` but manifest is `0.1.0`; its 2 tags are bare
      (`0.1.0-alpha.1`, `0.2.0`), not `v`-prefixed like the rest of the suite.
- [ ] **Step 2: Fix deviations** (Unreleased section, version headers, categories)
- [ ] **Step 3: Commit per repo**

---

## Phase 3: PR & Issue Templates (All Repos)

### Task 3.1: Fix uFawkesAI PR Template (Priority — Blocks AI Agent Reviews)

**Repo:** uFawkesAI

**Files:**

- Modify: `.github/PULL_REQUEST_TEMPLATE.md`

- [x] **Step 1: Write failing test** — already passes on `main` (verified 2026-10-08):

```bash
! grep -q "Firebase\|src/types/index.ts\|screens/\|components/" .github/PULL_REQUEST_TEMPLATE.md \
&& grep -q "AGENTS.md\|AI_STANCE.md\|artifact-chain\|ci-quality\|preflight\|verify" .github/PULL_REQUEST_TEMPLATE.md
```

- [x] **Step 2: Rewrite Architecture check section** with uFawkesAI checks:
  - [x] No secrets or credentials in changed files
  - [x] No modifications to AGENTS.md (edit source, not symlinks)
  - [x] No `--no-verify` or hook bypasses
  - [x] Changes to `docs/ai-sdlc/**/` include intent → spec → plan chain
  - [x] `npm run verify` passes locally before requesting review
  - [x] Symlinks (CLAUDE.md, .cursorrules, .github/copilot-instructions.md) still point to AGENTS.md

- [x] **Step 3: Verify test passes** — passes (this repo has a root `package.json` **with** a
      `verify` script, so the checklist line is runnable here; it is only unrunnable elsewhere —
      see Task 3.2).

- [x] **Step 4: Commit** — landed earlier as `uFawkesAI#212`.

---

### Task 3.2: Audit & Fix PR Templates in Other Repos

**Repos:** fawkes, uFawkesObs, uFawkesPipe, uFawkesDevX, uFawkes.dev, uFawkesDojo

- [x] **Step 1: Inventory all PR templates and their architecture checks** — all 7 repos have a
      root `.github/PULL_REQUEST_TEMPLATE.md`. Cross-repo artifact scan (`npm run verify`,
      `Firebase`, `src/types/index.ts`, `screens/`, `components/`) found exactly one offender:
      **uFawkesDevX**.
- [x] **Step 2: Replace template artifacts** with repo-specific checks — `uFawkesDevX` had two
      `npm run verify` lines but **no root `package.json`** (only nested ones), so the command
      failed with _"no such script"_; it had been copied from uFawkesAI, which does have it.
      Replaced with `pre-commit run --all-files` (its `.pre-commit-config.yaml` runs yamllint,
      markdownlint, ruff, gitleaks, shellcheck, terraform, actionlint and the artifact-chain hooks)
      and `make test-unit` (its Makefile's offline target). PR: `uFawkesDevX#111`.
- [x] **Step 3: Add missing PR templates** (use uFawkesAI fixed template as base, adapt) — none
      missing; every repo already had one.
- [x] **Step 4: Commit per repo** — only uFawkesDevX needed a commit.

---

### Task 3.3: Add Missing Issue Templates

**Standard set:** bug_report.yml, feature.yml, security.yml (or GitHub Security Advisories)

- [x] **Step 1: Inventory issue templates per repo** — standard set now present in all 7. Deviations
      found: **uFawkesObs** had no security template (fixed below); **needs-triage / security /
      area:unknown / epic / planning / feature / priority:medium** and friends were declared in
      templates but exist in **no** repo, so GitHub silently never applied them.
- [x] **Step 2: Add missing templates** (base from uFawkesAI/.github/ISSUE_TEMPLATE/) —
      added `uFawkesObs/.github/ISSUE_TEMPLATE/security.yml` (redirects to private reporting; declares
      no labels, since no suite repo has a `security` label). Also removed every dangling label
      reference across all 7 repos — **no functional change**, GitHub was already skipping them.
      PRs: `fawkes#2237`, `uFawkesAI#215`, `uFawkesObs#629`, `uFawkesPipe#163`, `uFawkesDevX#111`,
      `uFawkes.dev#174`, `uFawkesDojo#100`.
- [x] **Step 3: Commit per repo**
- [ ] **Follow-up (found, not yet fixed):** `uFawkesPipe` and `uFawkes.dev` each ship **both**
      `bug_report.md` and `bug_report.yml`, so the issue chooser shows two competing "Bug Report"
      entries. Also, 5 of 7 repos have no `.github/ISSUE_TEMPLATE/config.yml`, so blank issues stay
      enabled. Both are outside the original task wording — flagged for a decision.

---

## Phase 4: Documentation Cleanup (uFawkesAI Priority, Then Cross-Repo)

### Task 4.1: Clean uFawkesAI Docs (AI Slop & Placeholder Clarity)

**Repo:** uFawkesAI

**Files:** README.md, docs/PROMPT_LIBRARY.md, docs/AI_POLICY.md, docs/TEAM_ARCHETYPE.md, docs/VALUE_STREAM_MAP.md, docs/DEVEX_LOG.md, docs/RUNBOOKS.md

- [x] **Step 1: Write failing test** (no AI slop phrases)

```bash
! grep -r "As an AI\|I cannot\|I don't have\|Here is\|Below is\|This comprehensive\|In today's\|delve\|tapestry\|landscape" README.md docs/PROMPT_LIBRARY.md docs/AI_POLICY.md docs/TEAM_ARCHETYPE.md docs/VALUE_STREAM_MAP.md docs/DEVEX_LOG.md docs/RUNBOOKS.md 2>/dev/null
```

- [x] **Step 2: Clean each file per spec:** — done in `paruff/uFawkesAI#214`
  - **README.md:** Remove excessive badges (keep License, DORA AI, uFawkes Family, Works with). Tighten copy. Verify quick-start works.
  - **PROMPT_LIBRARY.md:** Verify prompts tested. Remove speculative. Clarify `{{PLACEHOLDERS}}` for consumers.
  - **AI_POLICY.md:** Add header: "This file is a template. When adopting uFawkesAI, replace all `[PLACEHOLDER]` markers with your project's actual policy."
  - **TEAM_ARCHETYPE.md:** Replace `[PLACEHOLDER]` examples with "Your team fills this in" guidance.
  - **VALUE_STREAM_MAP.md:** Replace `[PLACEHOLDER]` with defaults ("—", "TBD by team") + note.
  - **DEVEX_LOG.md:** Remove placeholder row. Keep headers.
  - **RUNBOOKS.md:** Replace `[PLACEHOLDER]` with uFawkesAI examples (devcontainer release, tag-based publish).

- [x] **Step 3: Verify test passes**

- [x] **Step 4: Commit** — branch `docs/phase4-public-docs-cleanup`, 7 files / 206 lines; 23/23 checks green

---

### Task 4.2: Cross-Repo AI Slop Removal & Placeholder Clarity

**Repos:** fawkes, uFawkesObs, uFawkesPipe, uFawkesDevX, uFawkes.dev, uFawkesDojo

- [x] **Step 1: Run detection** across all README.md and key docs — clean. Every phrase match is a
      legitimate use, not slop: "CNCF landscape" / "competitive landscape" (fawkes), a persona quote
      (fawkes), "I cannot confirm" as a spec sourcing caveat (uFawkesObs), and this plan's own grep
      pattern (uFawkes.dev). No `[PLACEHOLDER]` / `[PROJECT NAME]` markers in public docs.
      **uFawkesDojo added here** (it was omitted from the original list despite the Goal's "all 7"):
      same detection run over its `README.md` + `docs/` — clean, no slop and no placeholder markers.
- [x] **Step 2: Remove template artifacts** (generic "your project" language, non-repo badges) —
      nothing to remove. No README renders a non-repo badge; the only `your-org/your-repo` strings sit
      inside ```markdown fences as adopter copy-paste snippets. Every `make` target named in the five
      READMEs exists in its Makefile, and every file the READMEs reference resolves.
- [ ] **Step 3: Verify quick-start works** on fresh clone for each repo — **BLOCKED (agent
      environment): no Docker available, and fawkes additionally needs a k3d cluster.** The static
      substitute above passed; the live `make up` / `make dev-up` run remains an owner action.
- [x] **Step 4: Commit per repo** — N/A, detection found no changes to make

---

## Phase 5: Cross-Repo Verification & Release

### Task 5.1: Full Suite Verification

- [ ] **Step 1: Run verification in each repo**

```bash
for repo in fawkes uFawkesObs uFawkesPipe uFawkesDevX uFawkesDojo uFawkesAI uFawkes.dev; do
  cd /Users/philruff/projects/github/paruff/$repo
  echo "=== $repo ==="
  [ -f package.json ] && npm run verify 2>/dev/null || true
  [ -f Makefile ] && make verify 2>/dev/null || true
  [ -f scripts/check-artifact-chain.sh ] && bash scripts/check-artifact-chain.sh origin/main 2>/dev/null || true
  pre-commit run --all-files 2>/dev/null || true
done
```

> **Note (verified 2026-10-08):** `uFawkesDojo` was missing from this loop and from every repo
> count below; added so the loop matches the Goal's "all 7". Also, `npm run verify` only exists in
> **uFawkesAI** — the other 6 have no root `package.json`, so that line is a silent no-op there
> (same defect that made the old `uFawkesDevX` PR template unrunnable, see Task 3.2).

- [ ] **Step 2: Create test PR in each repo** → verify CI passes (`✅ CI Complete`)

---

### Task 5.2: Coordinated Suite Release (Human Decision)

- [ ] **Step 1: Prepare release notes** per repo from CHANGELOG.md
- [ ] **Step 2: Tag all repos** (version bumps per SemVer):
  - fawkes: next version
  - uFawkesObs: next version
  - uFawkesPipe: next version
  - uFawkesDevX: next version
  - uFawkesAI: v2.1.0
  - uFawkes.dev: next version — **resolve first:** manifest is `1.0.0`, CHANGELOG's newest section is
    `0.1.0`, and the repo has 0 tags (three different answers)
  - uFawkesDojo: next version — **resolve first:** manifest is `0.1.0`, CHANGELOG's newest section is
    `0.2.0`, and its 2 tags are bare (`0.1.0-alpha.1`, `0.2.0`) rather than `v`-prefixed like the
    rest of the suite
- [ ] **Step 3: Verify release-please creates GitHub Releases** in all repos
- [ ] **Step 4: Update uFawkesAI/docs/CHANGELOG.md** with suite release note

---

## Self-Review

**1. Spec coverage:** All spec requirements (R1–R6, AC-01–AC-10) map to tasks:

- R1 → Tasks 1.1, 1.2, 1.3, 1.4
- R2 → Tasks 2.1, 2.2
- R3 → Tasks 3.1, 3.2, 3.3
- R4 → Tasks 4.1, 4.2
- R5 → Task 2.2
- R6 → Task 5.1

**2. Step scan:** Each task has testable deliverables per repo. No "TBD" lines.

**3. Type consistency:** N/A — no code interfaces across tasks.

**4. Review Focus:** Each Review Focus item maps to acceptance criteria in tasks.

**5. Proportion:** 7 repos × ~15 deliverables = ~120 file changes in ~400 lines — appropriate for cross-repo governance plan.

---

## Execution Handoff

**Plan complete and saved to `docs/ai-sdlc/suite-public-release-polish/plan.md`.**

**Recommended approach: Subagent-driven**, because:

- 7 repos × multiple tasks = high parallelizability
- Each repo's changes independent (no cross-repo code interfaces)
- Fresh reviewer per repo catches repo-specific issues
- Tasks 1.1–1.4, 2.1, 3.2–3.3, 4.2 can run in parallel across repos

**Alternative: Native** if you prefer single-context execution with one final review.

**Which approach?**
