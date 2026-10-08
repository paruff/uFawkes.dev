# uFawkes.dev — Plan

> Project identity, stack, and conventions: see `AGENTS.md`
> Current branch: `main`

---

## Issue status tracker

### PR 1 — Trust & conversion (index.md)

| #   | Issue                                                                                 | Status  | Notes                                       |
| --- | ------------------------------------------------------------------------------------- | ------- | ------------------------------------------- |
| 1   | Fix double H1 — change `# uFawkes` to `<span class="sr-only">uFawkes</span>`          | ✅ Done | index.md line 1 after front matter          |
| 2   | Move email form below fold; add `## Try it now` docker compose CTA above Stack Family | ✅ Done | index.md structural reorder                 |
| 3   | Remove `## Social proof` zero-star badges; replace with maintainer bio line           | ✅ Done | index.md                                    |
| 4   | Fix raw badge alt text in Stack Family headings                                       | ✅ Done | index.md — replace with plain `/obs/` paths |
| 5   | Add Fawkes Dojo callout div between Stack Family and DORA AI Capabilities             | ✅ Done | index.md + assets/css/main.css              |
| 9   | Replace 5× "GitHub repo coming soon" with single consolidated notice + notify link    | ✅ Done | index.md — Stack Family section             |
| 10  | Add visible primary CTA button above the fold ("See the stacks ↓")                    | ✅ Done | index.md + assets/css/main.css              |
| 11  | Rename "Posts" section → "From the blog"                                              | ✅ Done | index.md                                    |
| 12  | DORA AI Capabilities — add one-sentence description to each of 7 items                | ✅ Done | index.md                                    |

### PR 2 — Content quality (stack pages + learn guides)

| #   | Issue                                                                                                                     | Status  | Notes                                                      |
| --- | ------------------------------------------------------------------------------------------------------------------------- | ------- | ---------------------------------------------------------- |
| 6   | Remove `## Screenshot placeholder` text from all five stack pages                                                         | ✅ Done | obs/ pipe/ dora/ sec/ devx/ index.md — one file per commit |
| 7   | Add `read_time` + `next_guide_url/title` to learn guides; create `_includes/guide-meta.html`; fix cross-link URL patterns | ✅ Done | learn/\*.html + new include                                |
| 8   | Fix per-page `description` meta on all stack pages (currently shows global tagline)                                       | ✅ Done | obs/ pipe/ dora/ sec/ devx/ front matter                   |

### PR 3 — Design system — Sprint 3 (dark mode fixes) complete

| #   | Issue                                                                                                                      | Status  | Notes               |
| --- | -------------------------------------------------------------------------------------------------------------------------- | ------- | ------------------- |
| S1  | Sprint 3: Fix broken dark-mode nesting, add cta-button--secondary light mode, dojo-callout dark mode, guide-meta dark link | ✅ Done | assets/css/main.css |
| S2  | Sprint 3: Fix DORA badge from live→coming-soon                                                                             | ✅ Done | dora/index.md       |
| S3  | Sprint 3: Navigation redesign — larger hit area, hover/focus states                                                        | ✅ Done | assets/css/main.css |

### PR 4 — Design System: Foundation, Components & Content (see `pr4-plan.md` for full audit + sprint breakdown)

6 sprints covering 28 issues (3 P0, 6 P1, 12 P2, 7 P3).

| Sprint | Theme                                             | Issues                       | Key files                                                                       |
| ------ | ------------------------------------------------- | ---------------------------- | ------------------------------------------------------------------------------- |
| 1      | Foundation: typography, borders, 3 P0 fixes       | P0a-c, P2a, P2f, P2j, P2b    | ✅ Done — `_layouts/home.html`, `_layouts/default.html`, `index.md`, `main.css` |
| 2      | Component styling: cards, code, badges, focus     | P2c, P2d, P2e, P1f, P2k, P3e | ✅ Done — `main.css`                                                            |
| 3      | Navigation: breadcrumbs, favicon, 404, nav polish | P1d, P1e, P2h, P2i, P3b, P3f | ✅ Done — `404.html`, `_includes/breadcrumbs.html`, `main.css`, `header.html`   |
| 4      | Content: blog expansion, DORA mapping             | P1b, P2g, P3a, P3d           | ✅ Done — `_posts/*.md`, `index.md`, `main.css`                                 |
| 5      | Dark mode polish, stack differentiation           | P2l, P3c, P3g                | ✅ Done — `main.css`, `_layouts/stack.html`, all stack `index.md`               |
| 6      | Screenshots & trust signals                       | P1a, P2                      | Stack pages + `assets/images/`                                                  |

### PR 7 — GitOps Migration (all repos)

| #   | Issue                                                        | Status         | Notes                                                         |
| --- | ------------------------------------------------------------ | -------------- | ------------------------------------------------------------- |
| G1  | Create `.gitops-templates/` in fawkes                        | 🔄 In progress | pre-commit, ci.yml, dependabot, CODEOWNERS, Makefile, configs |
| G2  | Initialize uFawkesDORA, uFawkesSec, uFawkesDevX with GitOps  | ⬜ Not started | Fresh repos — GitOps from day 1                               |
| G3  | Migrate uFawkesObs — add pre-commit, CODEOWNERS, dependabot  | ⬜ Not started | Keep existing 10 workflows                                    |
| G4  | Migrate uFawkesPipe — rename ci.yml → lint, add GitOps       | ⬜ Not started | Rename existing workflow descriptively                        |
| G5  | Migrate uFawkesAI — add pre-commit, CODEOWNERS               | ⬜ Not started | Keep existing 5 workflows                                     |
| G6  | Migrate uFawkes.dev — add pre-commit, CODEOWNERS, dependabot | ⬜ Not started | Keep existing 3 workflows                                     |
| G7  | Apply branch protection Rulesets (all 8 repos)               | ⬜ Not started | PR required, status check `Validate`                          |
| G8  | Create opencode GitOps agent + update AGENTS.md              | ⬜ Not started | Enforce branch → validate → PR workflow                       |

### PR 5 — Agent & skill infrastructure (can run parallel)

| #   | Issue                                                                            | Status         | Notes                                |
| --- | -------------------------------------------------------------------------------- | -------------- | ------------------------------------ |
| D   | Run consolidate-agents.sh — migrate agents to ~/.config/opencode/agents/         | ⬜ Not started | Repo root → run script               |
| E   | Install 12 consolidated skills to ~/.config/opencode/skills/                     | ⬜ Not started | Run script — verify report           |
| F   | Verify opencode.json written correctly — deny tailwind-tokens + astro-components | ⬜ Not started | .opencode/opencode.json              |
| G   | Delete old .opencode/agents/ and .opencode/skills/ after verification            | ⬜ Not started | Only after D+E confirmed working     |
| H   | Add playwright MCP — test UX agent screenshot of live site                       | ⬜ Not started | Requires Node + npx                  |
| I   | Add GitHub MCP — test planning agent creating a test issue                       | ⬜ Not started | Requires GitHub Copilot subscription |

### PR 6 — Product Suite Roadmap & Research Integration

| #   | Issue                                                            | Status  | Notes                                              |
| --- | ---------------------------------------------------------------- | ------- | -------------------------------------------------- |
| R1  | Create `fawkes/ROADMAP.md` — comprehensive product suite roadmap | ✅ Done | `.opencode/plans/roadmap.md` (ready to move)       |
| R2  | Create `uFawkesDORA` repo with description, topics               | ✅ Done | GitHub repo created, 8 topics added                |
| R3  | Create `uFawkesSec` repo with description, topics                | ✅ Done | GitHub repo created, 7 topics added                |
| R4  | Fix `uFawkesObs` — add description, topics                       | ✅ Done | Description + 8 topics added                       |
| R5  | Fix `uFawkesDevX` — add description, topics                      | ✅ Done | Description + 7 topics added                       |
| R6  | Update homepage — correct 7 DORA AI Capabilities from research   | ✅ Done | index.md updated with research-backed capabilities |
| R7  | Update homepage — research citations section                     | ✅ Done | Added DORA, CNCF, SPACE research links             |
| R8  | Update stack pages — live badges for DORA/Sec/DevX               | ✅ Done | All stack pages show "Live" badges                 |
| R9  | Update stack pages — real GitHub repo URLs                       | ✅ Done | All stack pages link to real repos                 |
| R10 | Add "Roadmap" link to navigation                                 | ✅ Done | \_data/navigation.yml updated                      |
| R11 | Add research section CSS                                         | ✅ Done | assets/css/main.css updated                        |
| R12 | Add cross-repo README links                                      | ✅ Done | All 7 repos + fawkes updated                       |

---

## Handoff

```
[ ] Current branch: main
[ ] Last completed: PR 6 — Product Suite Roadmap & Research Integration
[ ] In progress: CI Pipeline (PR #109 on ci/phase2-build-security)
[ ] Blockers: none
[ ] Next task: Commit reordered pipeline + new reusable workflows to PR #109
[ ] PR 4 plan: .opencode/plans/pr4-plan.md
[ ] Product roadmap: docs/roadmap.md
[ ] GitOps plan: .opencode/plans/gitops-migration.md
[ ] CI Pipeline plan: fawkes/docs/ci-pipeline-master-plan.md (5-gate architecture)
[ ] CI Pipeline status: fawkes/docs/ci-pipeline-status.md
```

### Branch cleanup — 2026-10-08 (all seven repos)

| Metric                              | Value                                                                                                                                                                                            |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Remote branches before → after      | 894 → 26 approved survivors (14 KEEP + 12 STRANDED)                                                                                                                                              |
| Remote branches deleted             | 868 (864 AUTO + 4 JUNK), 0 push failures, 0 guard refusals                                                                                                                                       |
| Local branches deleted (this clone) | 53 (safe-mode `git branch -d`)                                                                                                                                                                   |
| Stranded preserved                  | 11 draft PRs opened (uFawkes.dev #164/#165, uFawkesAI #200/#201, uFawkesObs #626, uFawkesPipe #159, uFawkesDevX #106, fawkes #2232/#2233, uFawkesDojo #93/#94)                                   |
| Exception                           | fawkes `platform-status` — stranded, no draft PR possible (no history in common with main); branch kept                                                                                          |
| Prevention                          | `delete_branch_on_merge=true` enabled on all 7 repos                                                                                                                                             |
| Evidence                            | `/tmp/opencode/branch-triage/` — `cleanup-log-2026-10-08.md`, per-repo TSV/table, `baseline.txt`                                                                                                 |
| Plan                                | `.opencode/plans/branch-cleanup-plan.md`                                                                                                                                                         |
| Open follow-ups                     | 12 local branches remain: 9 squash-landed (`-D` candidates, evidence in TSV), 1 worktree-held (`feat/status-live-checks`), 2 genuinely unmerged (`docs/suite-hygiene-standard`, `sync-4-agents`) |
| Note                                | uFawkesAI had parallel session activity during cleanup; post-triage branches were never in the delete set and were untouched                                                                     |

---

_Last updated: 2026-10-08_
