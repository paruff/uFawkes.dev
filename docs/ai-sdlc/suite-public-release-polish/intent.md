# Intent: Suite-Wide Public Release Polish

**Date:** 2026-10-08
**Author:** paruff
**Status:** Draft
**Related:** [suite-release intent](../suite-release/intent.md), [suite-hygiene](../suite-hygiene/main-protection.md)

## Problem Statement

The uFawkes/fawkes suite (13 repos) has inconsistent public release readiness. While individual repos have many best practices in place, systemic gaps exist across the suite:

- **6 of 8 repos lack CODE_OF_CONDUCT.md** (governance baseline)
- **5 of 8 repos lack SECURITY.md** (security reporting standard)
- **4 of 8 repos lack FUNDING.yml** entirely; 4 have minimal (github only)
- **4 of 8 repos have no release automation**; 3 use release-please, 1 custom
- **PR templates contain cross-repo artifacts** (e.g., uFawkesAI has Firebase/TypeScript checks)
- **AI slop and unclear placeholders** in uFawkesAI documentation confuse new adopters

These gaps mean a new adopter clicking "Use this template" on any repo encounters friction: missing governance files, unclear contribution workflows, manual release processes, and misleading templates.

## Desired Outcome

Every repo in the suite meets a consistent public release baseline:

1. **Legal/Governance:** MIT LICENSE, Contributor Covenant v2.1 CODE_OF_CONDUCT, SECURITY.md with SLAs, FUNDING.yml with template platforms
2. **Documentation:** Clean README (quick-start works), no AI slop, placeholders documented as template features, repo-specific PR/issue templates
3. **Release Automation:** release-please.yml in all repos (automated GitHub Releases from conventional commits + CHANGELOG)
4. **Cross-Repo Consistency:** Same baseline files, same workflow patterns, same verification commands

## Success Criteria

- Fresh clone of any repo → `npm run verify` / `make verify` passes → contributor can open PR with correct template
- `git tag vX.Y.Z` → release-please creates GitHub Release with CHANGELOG notes → no manual steps
- Security team finds current SECURITY.md in every repo
- Community finds Contributor Covenant v2.1 in every repo
- No template artifacts (Firebase, generic "your project" language) in any repo's templates

## Scope

**In scope:** All 8 active repos: fawkes, uFawkesObs, uFawkesPipe, uFawkesDevX, ufawkesdora, ufawkessec, uFawkesAI, uFawkes.dev

**Out of scope:** Runtime code changes, architecture changes, new features. This is governance/documentation/automation only.

## Constraints

- MIT license already standard — no changes
- `[PLACEHOLDER]` markers in uFawkesAI/docs/ are intentional template features — keep but document clearly
- `AGENTS.md` / `AI_STANCE.md` in uFawkesAI are canonical AI policy — other repos must not contradict
- SemVer + Keep a Changelog already established — maintain format
- CI Quality Gate (`✅ CI Complete` or equivalent) required in all repos
