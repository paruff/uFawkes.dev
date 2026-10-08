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

## Phase 2: Release Automation (All 6 Repos — Parallelizable)

### Task 2.1: Standardize on release-please.yml

**Current:** release-please in uFawkesObs, uFawkesPipe, uFawkesDevX (3); none in fawkes, uFawkesAI, uFawkes.dev (3)

**Files per repo:**

- Create/Modify: `.github/workflows/release-please.yml`
- Auto-generated: `.release-please-manifest.json`

**Interfaces:**

- Consumes: package.json (or pyproject.toml/Cargo.toml/go.mod), CHANGELOG.md
- Produces: Automated GitHub Release on version tag

- [ ] **Step 1: Extract canonical release-please.yml from uFawkesPipe**

```bash
cat /Users/philruff/projects/github/paruff/uFawkesPipe/.github/workflows/release-please.yml
```

- [ ] **Step 2: Apply to fawkes, uFawkesAI, uFawkes.dev**
      Adapt version file path per repo:
- Node: `package.json`
- Python: `pyproject.toml` or `setup.py`
- Go: `go.mod`
- Rust: `Cargo.toml`

- [ ] **Step 3: Verify uFawkesObs, uFawkesPipe, uFawkesDevX configs are current**

- [ ] **Step 4: Test each repo** (dry-run with `release-please` CLI or push test tag to fork)

- [ ] **Step 5: Commit per repo**

---

### Task 2.2: CHANGELOG.md Format Consistency

**Repos:** All 8

- [ ] **Step 1: Audit all CHANGELOG.md** for Keep a Changelog + SemVer compliance
- [ ] **Step 2: Fix deviations** (Unreleased section, version headers, categories)
- [ ] **Step 3: Commit per repo**

---

## Phase 3: PR & Issue Templates (All Repos)

### Task 3.1: Fix uFawkesAI PR Template (Priority — Blocks AI Agent Reviews)

**Repo:** uFawkesAI

**Files:**

- Modify: `.github/PULL_REQUEST_TEMPLATE.md`

- [ ] **Step 1: Write failing test**

```bash
! grep -q "Firebase\|src/types/index.ts\|screens/\|components/" .github/PULL_REQUEST_TEMPLATE.md \
&& grep -q "AGENTS.md\|AI_STANCE.md\|artifact-chain\|ci-quality\|preflight\|verify" .github/PULL_REQUEST_TEMPLATE.md
```

- [ ] **Step 2: Rewrite Architecture check section** with uFawkesAI checks:
  - [ ] No secrets or credentials in changed files
  - [ ] No modifications to AGENTS.md (edit source, not symlinks)
  - [ ] No `--no-verify` or hook bypasses
  - [ ] Changes to `docs/ai-sdlc/**/` include intent → spec → plan chain
  - [ ] `npm run verify` passes locally before requesting review
  - [ ] Symlinks (CLAUDE.md, .cursorrules, .github/copilot-instructions.md) still point to AGENTS.md

- [ ] **Step 3: Verify test passes**

- [ ] **Step 4: Commit**

---

### Task 3.2: Audit & Fix PR Templates in Other Repos

**Repos:** fawkes, uFawkesObs, uFawkesPipe, uFawkesDevX, uFawkes.dev

- [ ] **Step 1: Inventory all PR templates and their architecture checks**
- [ ] **Step 2: Replace template artifacts** with repo-specific checks
- [ ] **Step 3: Add missing PR templates** (use uFawkesAI fixed template as base, adapt)
- [ ] **Step 4: Commit per repo**

---

### Task 3.3: Add Missing Issue Templates

**Standard set:** bug_report.yml, feature.yml, security.yml (or GitHub Security Advisories)

- [ ] **Step 1: Inventory issue templates per repo**
- [ ] **Step 2: Add missing templates** (base from uFawkesAI/.github/ISSUE_TEMPLATE/)
- [ ] **Step 3: Commit per repo**

---

## Phase 4: Documentation Cleanup (uFawkesAI Priority, Then Cross-Repo)

### Task 4.1: Clean uFawkesAI Docs (AI Slop & Placeholder Clarity)

**Repo:** uFawkesAI

**Files:** README.md, docs/PROMPT_LIBRARY.md, docs/AI_POLICY.md, docs/TEAM_ARCHETYPE.md, docs/VALUE_STREAM_MAP.md, docs/DEVEX_LOG.md, docs/RUNBOOKS.md

- [ ] **Step 1: Write failing test** (no AI slop phrases)

```bash
! grep -r "As an AI\|I cannot\|I don't have\|Here is\|Below is\|This comprehensive\|In today's\|delve\|tapestry\|landscape" README.md docs/PROMPT_LIBRARY.md docs/AI_POLICY.md docs/TEAM_ARCHETYPE.md docs/VALUE_STREAM_MAP.md docs/DEVEX_LOG.md docs/RUNBOOKS.md 2>/dev/null
```

- [ ] **Step 2: Clean each file per spec:**
  - **README.md:** Remove excessive badges (keep License, DORA AI, uFawkes Family, Works with). Tighten copy. Verify quick-start works.
  - **PROMPT_LIBRARY.md:** Verify prompts tested. Remove speculative. Clarify `{{PLACEHOLDERS}}` for consumers.
  - **AI_POLICY.md:** Add header: "This file is a template. When adopting uFawkesAI, replace all `[PLACEHOLDER]` markers with your project's actual policy."
  - **TEAM_ARCHETYPE.md:** Replace `[PLACEHOLDER]` examples with "Your team fills this in" guidance.
  - **VALUE_STREAM_MAP.md:** Replace `[PLACEHOLDER]` with defaults ("—", "TBD by team") + note.
  - **DEVEX_LOG.md:** Remove placeholder row. Keep headers.
  - **RUNBOOKS.md:** Replace `[PLACEHOLDER]` with uFawkesAI examples (devcontainer release, tag-based publish).

- [ ] **Step 3: Verify test passes**

- [ ] **Step 4: Commit**

---

### Task 4.2: Cross-Repo AI Slop Removal & Placeholder Clarity

**Repos:** fawkes, uFawkesObs, uFawkesPipe, uFawkesDevX, uFawkes.dev

- [ ] **Step 1: Run detection** across all README.md and key docs
- [ ] **Step 2: Remove template artifacts** (generic "your project" language, non-repo badges)
- [ ] **Step 3: Verify quick-start works** on fresh clone for each repo
- [ ] **Step 4: Commit per repo**

---

## Phase 5: Cross-Repo Verification & Release

### Task 5.1: Full Suite Verification

- [ ] **Step 1: Run verification in each repo**

```bash
for repo in fawkes uFawkesObs uFawkesPipe uFawkesDevX uFawkesAI uFawkes.dev; do
  cd /Users/philruff/projects/github/paruff/$repo
  echo "=== $repo ==="
  [ -f package.json ] && npm run verify 2>/dev/null || true
  [ -f Makefile ] && make verify 2>/dev/null || true
  [ -f scripts/check-artifact-chain.sh ] && bash scripts/check-artifact-chain.sh origin/main 2>/dev/null || true
  pre-commit run --all-files 2>/dev/null || true
done
```

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
  - uFawkes.dev: next version
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
