# Spec: Suite-Wide Public Release Polish

**Traces to:** [intent.md](intent.md)
**Status:** Draft
**Revision:** 1

## Requirements

### R1 — Legal & Governance Baseline (All 8 Repos)

| Repo        | LICENSE | CODE_OF_CONDUCT | SECURITY.md | FUNDING.yml |
| ----------- | ------- | --------------- | ----------- | ----------- |
| fawkes      | ✅      | ❌ ADD          | ❌ ADD      | ❌ ADD      |
| uFawkesObs  | ✅      | ✅              | ✅          | ✅ ENHANCE  |
| uFawkesPipe | ✅      | ✅              | ✅          | ✅ ENHANCE  |
| uFawkesDevX | ✅      | ❌ ADD          | ✅          | ❌ ADD      |
| ufawkesdora | ✅      | ❌ ADD          | ❌ ADD      | ❌ ADD      |
| ufawkessec  | ❌ ADD  | ❌ ADD          | ❌ ADD      | ❌ ADD      |
| uFawkesAI   | ✅      | ❌ ADD          | ✅ VERIFY   | ✅ ENHANCE  |
| uFawkes.dev | ✅      | ❌ ADD          | ❌ ADD      | ✅ ENHANCE  |

**R1.1 CODE_OF_CONDUCT:** Contributor Covenant v2.1 (https://www.contributor-covenant.org/version/2/1/code_of_conduct/) with project-specific Enforcement section referencing GitHub Security Advisories and maintainer contact.

**R1.2 SECURITY.md:** Based on uFawkesObs template — Supported Versions table, private reporting via GitHub Security Advisories, Response SLA (ack 2 days, triage 5 days, status updates 7 days, Critical/High remediation 7 days).

**R1.3 FUNDING.yml:** Standard template with github + commented platforms:

```yaml
github: [paruff]
# patreon: your-handle
# open_collective: your-collective
# ko_fi: your-handle
# tidelift: your-org
# community_bridge: your-project
```

**R1.4 LICENSE:** ufawkessec needs MIT LICENSE (copy from uFawkesAI).

### R2 — Release Automation: release-please.yml (All 8 Repos)

**R2.1 Standard workflow:** Use release-please (Google's automated release tool) configured for:

- Conventional Commits
- package.json version bump (or pyproject.toml / Cargo.toml / go.mod where applicable)
- CHANGELOG.md generation (Keep a Changelog format)
- GitHub Release creation on tag push
- Manifest file: `.release-please-manifest.json` (auto-managed)

**R2.2 Migration:**

- uFawkesObs, uFawkesPipe, uFawkesDevX: verify existing release-please.yml is current
- ufawkesdora: replace custom release.yml with release-please
- fawkes, ufawkessec, uFawkesAI, uFawkes.dev: add release-please.yml

**R2.3 Permissions:** `contents: write`, `pull-requests: write` (for release PR), `id-token: write` (for provenance if needed)

### R3 — PR & Issue Templates (All Repos)

**R3.1 PR Template:** Each repo has `.github/PULL_REQUEST_TEMPLATE.md` with:

- Repo-specific architecture checks (no cross-repo artifacts)
- Standard checklist: CI passes, <400 lines, no secrets, docs updated
- AI-assisted review block (optional but recommended)

**R3.2 uFawkesAI PR Template Fix (Priority):**
Replace Firebase/TypeScript architecture checks with uFawkesAI checks:

- No secrets/credentials in changed files
- No modifications to AGENTS.md (edit source, not symlinks)
- No `--no-verify` or hook bypasses
- Changes to `docs/ai-sdlc/**/` include intent → spec → plan chain
- `npm run verify` passes locally before requesting review
- Symlinks (CLAUDE.md, .cursorrules, .github/copilot-instructions.md) still point to AGENTS.md

**R3.3 Issue Templates:** Minimum set per repo:

- `bug_report.yml` — structured bug report
- `feature.yml` — feature request with acceptance criteria
- `security.yml` — or use GitHub Security Advisories (documented in SECURITY.md)

### R4 — Documentation Cleanup

**R4.1 uFawkesAI (High Priority):**

- README.md: Remove excessive badges, tighten copy, verify quick-start works
- docs/PROMPT_LIBRARY.md: Verify all prompts tested, remove speculative ones
- docs/AI_POLICY.md: Add header note "This file is a template. When adopting uFawkesAI, replace all `[PLACEHOLDER]` markers with your project's actual policy."
- docs/TEAM_ARCHETYPE.md: Replace `[PLACEHOLDER]` examples with "Your team fills this in" guidance
- docs/VALUE_STREAM_MAP.md: Replace `[PLACEHOLDER]` cells with sensible defaults ("—" / "TBD by team") + note
- docs/DEVEX_LOG.md: Remove placeholder row, keep headers
- docs/RUNBOOKS.md: Replace `[PLACEHOLDER]` with uFawkesAI-specific examples

**R4.2 Cross-Repo AI Slop Removal:**
Run detection across all repos' README.md and key docs for phrases:
"As an AI", "I cannot", "I don't have", "Here is", "Below is", "This comprehensive", "In today's", "delve", "tapestry", "landscape"

**R4.3 Placeholder Clarity:** All `[PLACEHOLDER]` markers in template repos (uFawkesAI, uFawkes.dev) have clear guidance that they are template features for consumers to fill.

### R5 — CHANGELOG Consistency

All repos follow Keep a Changelog + SemVer:

- Unreleased section at top
- Version headers match git tags (vX.Y.Z)
- Categories: Added, Changed, Deprecated, Removed, Fixed, Security

### R6 — Verification Gates

**R6.1 Per-Repo Verification:** Each repo has a `verify` script/command:

- uFawkesAI: `npm run verify` (check-agents, check-ai-stance, check-dora-vocabulary, check-harness-parity, run-unit-tests)
- uFawkesObs/uFawkesPipe/uFawkesDevX: `make verify` or equivalent
- fawkes: `make verify`
- ufawkesdora/ufawkessec: `make verify` or script

**R6.2 Artifact Chain:** All repos run `scripts/check-artifact-chain.sh origin/main` on PRs with their own `.artifact-chain-paths`.

**R6.3 Suite Verification:** Single command validates all 8 repos.

## Acceptance Criteria

| AC    | Requirement                                                     | Test Method                                                                                                 |
| ----- | --------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| AC-01 | All 8 repos have CODE_OF_CONDUCT.md (Contributor Covenant v2.1) | `grep -r "Contributor Covenant" */CODE_OF_CONDUCT.md`                                                       |
| AC-02 | All 8 repos have SECURITY.md with SLAs                          | `grep -r "2 business days" */SECURITY.md`                                                                   |
| AC-03 | All 8 repos have FUNDING.yml with 6+ platforms                  | `grep -c "github:\|patreon:\|open_collective:\|ko_fi:\|tidelift:\|community_bridge:" */.github/FUNDING.yml` |
| AC-04 | All 8 repos have release-please.yml                             | `ls */.github/workflows/release-please.yml`                                                                 |
| AC-05 | uFawkesAI PR template has no Firebase/TS checks                 | `! grep -q "Firebase\|src/types" uFawkesAI/.github/PULL_REQUEST_TEMPLATE.md`                                |
| AC-06 | uFawkesAI PR template has uFawkesAI checks                      | `grep -q "AGENTS.md\|artifact-chain\|verify" uFawkesAI/.github/PULL_REQUEST_TEMPLATE.md`                    |
| AC-07 | No AI slop phrases in key docs                                  | Detection grep returns empty                                                                                |
| AC-08 | All CHANGELOG.md follow Keep a Changelog format                 | Visual audit + `grep -c "## \[.*\]" */CHANGELOG.md`                                                         |
| AC-09 | `git tag vX.Y.Z` triggers release-please in all repos           | Test tag push in each repo (dry-run)                                                                        |
| AC-10 | Suite verification passes                                       | `for repo in ...; do cd $repo && npm run verify; make verify; done`                                         |

## Non-Functional Requirements

- **NFR-01:** No runtime code changes — documentation, config, workflows only
- **NFR-02:** Each repo's changes independently reviewable and mergeable
- **NFR-03:** No breaking changes to existing CI/CD — release-please adds automation alongside existing
- **NFR-04:** Total effort ≤ 2 hours per repo (documentation-focused)
- **NFR-05:** Changes compatible with uFawkesAI template inheritance (symlinks, AGENTS.md)

## Dependencies

- uFawkesAI changes must not break template sync to other repos
- release-please.yml must work with each repo's version file location
- SECURITY.md must reference each repo's actual Security Advisories settings
