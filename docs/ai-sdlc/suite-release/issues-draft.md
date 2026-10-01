# Draft issues for revision 2 (review, then delete)

**Traces to:** [`plan.md`](plan.md) | **Drafted:** 2026-10-01

Routing labels: **G** = `goal` + `claude-code` (Claude Code, Opus 5.5) ·
**U** = `opencode` + `model:nemotron-3-ultra` · **F** = `opencode` +
`model:mimo-v2.6-flash`. **NEW** = create it; **#n** = relabel or retitle
an existing issue; **close** = close with a comment pointing here.

Once these exist on Project #7, delete this file.

## Phase 0 — Suite hygiene

| Repo        | Issue | Title                                                                                       | Route | Notes                                                              |
| ----------- | ----- | ------------------------------------------------------------------------------------------- | ----- | ------------------------------------------------------------------ |
| uFawkes.dev | NEW   | chore(suite): routing labels + Project #7 release options for revision 2                    | G     | Claude Code does this when the issues are created                  |
| uFawkes.dev | NEW   | feat(nav): add `/ai/` and `/fawkes/` pages; replace `/dora/` and `/sec/` with pointer pages | U     | No plugins (jekyll-feed only): pointer pages link to the successor |
| uFawkes.dev | #68   | chore: archive ufawkessec (merged into uFawkesPipe)                                         | G     | Retitle to include uFawkesRes. Archiving is owner-only             |
| fawkes      | NEW   | docs(adr): mark ADR-004 (Jenkins) superseded by ADR-036 (Tekton)                            | F     | One file, a status line and a link                                 |
| uFawkesDevX | NEW   | docs: remove uFawkesRes references from README, VISION, docs/quickstart, CONTRACTS          | F     | grep-and-replace; `make validate`                                  |
| uFawkesPipe | #9    | GITOPS-001                                                                                  | close | Duplicate; GitOps is done suite-wide (PR 7)                        |
| uFawkesDevX | #13   | GITOPS-001                                                                                  | close | Same                                                               |
| uFawkesPipe | #8    | DY-007 Sponsors                                                                             | close | Duplicate of uFawkes.dev #63                                       |
| uFawkesAI   | #36   | AI-015 UFAWKES_FAMILY_ROADMAP                                                               | close | Superseded by this folder; link it from the README                 |

## Phase 1 — uFawkesAI `v2.0.0`

| Repo        | Issue         | Title                                                                                                                                    | Route | Notes                                                       |
| ----------- | ------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ----- | ----------------------------------------------------------- |
| uFawkesAI   | NEW           | **goal: release uFawkesAI v2.0.0 — AI-native SDLC template + pinnable CDE devcontainer**                                                 | G     | Parent. AC-AI-01..05. Milestone `v2.0.0`                    |
| uFawkesAI   | NEW           | docs(ai-sdlc): v2.0.0 intent, spec (contract), plan + 1.x upgrade note                                                                   | G     | The contract is a decision                                  |
| uFawkesAI   | #111          | Publish ufawkesai-devcontainer with SemVer tags                                                                                          | G     | Signing and a publish path; `release-blocker`               |
| uFawkesAI   | #90           | fix(plan skill): align expected filenames                                                                                                | U     | Spec is in the issue                                        |
| uFawkesAI   | #28           | AI-007 PLACEHOLDER_AUDIT CI check                                                                                                        | U     | One workflow + one script                                   |
| uFawkesAI   | NEW           | docs(readme): harness-anatomy, DORA AI capability and playbook six-stage maps; cite the playbook + paper upstream; claim only what ships | U     | AC-AI-04; Claude Code reviews the claims                    |
| uFawkesAI   | NEW           | ci: make agent evals a required check, run on rule/skill/hook changes and on a schedule; per-task rubrics                                | G     | AC-AI-07; changes branch protection                         |
| uFawkesAI   | NEW           | ci(image): cold/warm start benchmark per release; fail on >10% regression; publish in release notes                                      | U     | AC-AI-08; the script and thresholds are given in the issue  |
| uFawkesAI   | NEW           | docs(ai-sdlc/devsecops-image): ground the CDE spec in the DevEx research (feedback, cognitive load, flow); one-page rule-file budget     | G     | AC-AI-08; design judgment                                   |
| uFawkesAI   | NEW           | test: "Use this template" run in the 2.0.0-rc devcontainer, all four harnesses                                                           | G     | Real run (AC-AI-02)                                         |
| uFawkes.dev | NEW           | feat(ai): `/ai/` stack page + compatibility row for uFawkesAI v2.0.0                                                                     | U     | After the tag                                               |
| all 7       | NEW           | chore(devcontainer): pin `ufawkesai-devcontainer:2.0.0` (one issue per repo)                                                             | F     | AC-AI-05; one-line change each                              |
| uFawkesAI   | NEW           | docs(ai-sdlc): move root-level v1 intent/spec/plan into `docs/ai-sdlc/dual-harness-template/`; update README links                       | F     | `git mv` + link fixes; the artifact-chain check must pass   |
| uFawkesAI   | NEW           | docs(ai-sdlc): spec + plan for `dora-events-portability` (GAP-01..03)                                                                    | G     | Intent exists; due 2026-10-04                               |
| uFawkesAI   | NEW           | fix(dora-events): declare test deps (GAP-01); emitter works outside CI (GAP-02)                                                          | U     | After the spec; exact files are in the intent               |
| uFawkesAI   | NEW           | test(dora-events): real event queryable in uFawkesObs Loki, LogQL documented (GAP-03)                                                    | G     | Real cross-repo run; AC-AI-06                               |
| uFawkesAI   | #31           | AI-010 MCP configuration                                                                                                                 | close | Verify `.mcp.json` covers it, then close                    |
| uFawkesAI   | #30           | AI-009 DOJO_LEARNING_PATH                                                                                                                | F     | Becomes a link to the Dojo "Start here" lab (after Phase 2) |
| uFawkesAI   | #32, #33, #34 | archetype playbook, Discussions, Codespaces                                                                                              | —     | Out of 2.0. Priority P3, no Release value                   |

## Phase 2 — uFawkesDojo `0.2`

| Repo        | Issue | Title                                                                                                                | Route | Notes                                                                                                |
| ----------- | ----- | -------------------------------------------------------------------------------------------------------------------- | ----- | ---------------------------------------------------------------------------------------------------- |
| uFawkesDojo | #11   | Retitle: **goal: release Dojo 0.2 — accurate curriculum + uFawkesAI "Start here" lab**                               | G     | Reuse #11 as the parent. AC-DOJO-01..03                                                              |
| uFawkesDojo | #19   | docs: four → five DORA metrics                                                                                       | U     | Needs judgment in context, not just replace                                                          |
| uFawkesDojo | NEW   | docs: label Jenkins modules (5–8) "replaced in Dojo 0.4" at the top                                                  | F     | Banner text given in the issue                                                                       |
| uFawkesDojo | NEW   | docs: remove or label unbuilt labs, `[VIDEO PLACEHOLDER]`s and Mattermost links                                      | F     | List of files from #11's table                                                                       |
| uFawkesDojo | NEW   | docs: module-authoring guide (pedagogy checklist) + PR template link                                                 | U     | Content is in #11                                                                                    |
| uFawkesDojo | NEW   | lab: white-belt "Start here": uFawkesAI v2.0.0 CDE, a tour of the six harness components, one intent→spec→plan cycle | G     | Must be run for real; records time-to-first-PR + 3-question survey (AC-AI-08); Nemotron may draft it |
| uFawkesDojo | NEW   | content: White Belt primer, "vibe coding to agentic engineering", cites the paper                                    | U     | Theory ≤10 min, then the Start-here lab                                                              |
| uFawkesDojo | NEW   | docs(ai-sdlc): rebase compose-curriculum plan on revision 2's order                                                  | F     | Phases A–D stay, prefixed by 0.2                                                                     |
| uFawkesDojo | NEW   | lab: Module 2 lab-02 drops its dora-events workarounds, adds "see it in Grafana"                                     | U     | After GAP-01..03 land; run by Claude Code                                                            |
| uFawkesDojo | #20   | chore: main-protection ruleset + CODEOWNERS                                                                          | G     | Needs repo-admin API                                                                                 |
| uFawkes.dev | #67   | content: align learn guides with the Dojo                                                                            | U     | Already labeled                                                                                      |

## Phase 3 — uFawkesObs `v1.0.0` + Dojo `0.3`

| Repo        | Issue                        | Title                                                                    | Route | Notes                                                                                                        |
| ----------- | ---------------------------- | ------------------------------------------------------------------------ | ----- | ------------------------------------------------------------------------------------------------------------ |
| uFawkesObs  | NEW                          | **goal: release uFawkesObs v1.0.0 stable**                               | G     | Parent. AC-OBS-01..04                                                                                        |
| uFawkesObs  | #534                         | DORA config drift (dead uFawkesRes panels)                               | U     | Add `release-blocker` + milestone `v1.0.0`. Relabel from Opus: the issue already lists exact files and lines |
| uFawkesObs  | NEW                          | test: clean-host install transcripts, Linux + macOS, against the next rc | G     | Real run                                                                                                     |
| uFawkesDojo | NEW                          | lab: re-pin Module 2 lab-01 to uFawkesObs v1.0.0 and re-run              | G     | Real run (Dojo AC-001)                                                                                       |
| uFawkesDojo | NEW ×4                       | content: Brown Belt Module 13/14/15/16 → uFawkesObs (one issue each)     | U     | Draft by Nemotron; lab run by Claude Code                                                                    |
| uFawkes.dev | #66                          | content: screenshots + launch posts for Obs v1.0.0                       | G     | `release` agent                                                                                              |
| uFawkesObs  | #182, #415, #474, #502, #503 | post-1.0                                                                 | G     | Keep labels; Release = none                                                                                  |
| uFawkesObs  | #416                         | Testcontainers migration                                                 | U     | Already labeled; PR #553 in progress                                                                         |

## Phase 4 — uFawkesPipe `v2.0.0` + Dojo `0.4`

| Repo        | Issue  | Title                                                                                       | Route | Notes                                  |
| ----------- | ------ | ------------------------------------------------------------------------------------------- | ----- | -------------------------------------- |
| uFawkesPipe | NEW    | **goal: release uFawkesPipe v2.0.0 — first stable**                                         | G     | Parent. AC-PIPE-01                     |
| uFawkesPipe | NEW    | docs(ai-sdlc): consolidate 3 specs, 2 designs, plan-for-the-day into `docs/ai-sdlc/v2.0.0/` | U     | No content decisions; merge and dedupe |
| uFawkesPipe | NEW    | decide: `build-image` via CNB, or drop the claim                                            | G     | Decision + ADR                         |
| uFawkesPipe | NEW    | test: real pipeline run on a sample repo with notify-obs → Obs v1.0.0                       | G     | Real run                               |
| uFawkesPipe | #6     | DY-005 Python language pack                                                                 | —     | Post-2.0 (non-goal: new features)      |
| uFawkesDojo | NEW ×4 | content: Yellow Belt Module 5/6/7/8 → uFawkesPipe (Woodpecker)                              | U     | Labs run by Claude Code                |

## Phase 5 — uFawkesDevX `v0.1.0` + Dojo `0.5`

| Repo        | Issue       | Title                                                                               | Route | Notes                                        |
| ----------- | ----------- | ----------------------------------------------------------------------------------- | ----- | -------------------------------------------- |
| uFawkesDevX | NEW         | **goal: release uFawkesDevX v0.1.0 beta**                                           | G     | Parent. AC-DEVX-01                           |
| uFawkesDevX | #57         | decide: database without uFawkesRes                                                 | G     | ADR                                          |
| uFawkesDevX | NEW ×3      | feat: score-service → SQLite / Backstage → better-sqlite3 / Coder built-in Postgres | U     | One per component, after #57; specs from #57 |
| uFawkesDevX | NEW         | docs(ai-sdlc): move root spec/design/plan into `docs/ai-sdlc/v0.1.0/`               | F     | `git mv` plus link fixes                     |
| uFawkesDevX | NEW         | test: clean-host `make up` transcript                                               | G     | Real run                                     |
| uFawkesDevX | #45         | job-name-present workflow check                                                     | F     |                                              |
| uFawkesDevX | #8, #9, #10 | v0.3 items                                                                          | —     | Out of scope                                 |
| uFawkesDojo | NEW ×3      | content: White Belt Module 1/3/4 → uFawkesDevX                                      | U     | Labs run by Claude Code                      |
| uFawkes.dev | #70         | feat(suite): define suite mode + measured requirements                              | G     | Needs all three stacks running together      |

## Phase 6 — fawkes Tracer Bullet Alpha + Dojo `0.6`

| Repo        | Issue        | Title                                                                 | Route | Notes                                             |
| ----------- | ------------ | --------------------------------------------------------------------- | ----- | ------------------------------------------------- |
| fawkes      | #1804        | Retitle: **goal: fawkes Tracer Bullet Alpha release**                 | G     | Parent. AC-FAWKES-01..04. #1808 becomes its child |
| fawkes      | #2004, #1797 | P0 security: extract-zip; CHANGE_ME credentials                       | G     | Never OpenCode                                    |
| fawkes      | #2130        | Grafana can't query its Prometheus (root cause unknown)               | G     | Debugging                                         |
| fawkes      | #1572, #1919 | DORA DF/LT queryable                                                  | G     | Live k8s verification                             |
| fawkes      | #1856, #1858 | tunnel; one continuous gitops-promote run                             | G     | Live infra                                        |
| fawkes      | #1857        | Alertmanager crash-loop → chat                                        | U     | Known target; no secret in the issue              |
| fawkes      | #1948        | docs: CFR methodology in METRICS.md                                   | U     |                                                   |
| fawkes      | NEW          | docs: scope README to Alpha; `docs/ai-sdlc/tracer-bullet-alpha/`      | G     | Public-claims decision                            |
| uFawkesDojo | NEW          | content: Green Belt "why Kubernetes now" + Tekton refs (Modules 9–12) | U     | Can run any time                                  |
| uFawkes.dev | NEW          | feat(fawkes): `/fawkes/` graduation page + matrix row                 | U     | After release                                     |

All other fawkes issues stay on fawkes's own milestones and off Project #7.

## Anytime (uFawkes.dev)

| Issue         | Title                                                                                                                                                                      | Route                |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- |
| #26, #27, #28 | favicon, 404 page, reduced motion                                                                                                                                          | F                    |
| #65           | cite research in each stack README                                                                                                                                         | U                    |
| NEW           | docs(research): add the Osmani et al. (May 2026) paper and the Anthropic AI-Native SDLC Playbook (2026-08-21) to `docs/research-foundation.md` (citations only, no copies) | F                    |
| NEW           | docs(research): verify or remove the 8 rows marked _unverified_ in `research-foundation.md`; check public pages that cite the old archetype names                          | G                    |
| NEW           | chore(agents): cut CLAUDE.md (513 lines of static context) to stack, hard rules, commit format; move the agent roster and URL tables to docs                               | G                    |
| #64           | opencode GitOps agent                                                                                                                                                      | U (already labeled)  |
| #63           | GitHub Sponsors                                                                                                                                                            | G (account settings) |

## After this plan (direction, not gated)

| Repo                   | Title                                                                                            | Route | Notes                                                           |
| ---------------------- | ------------------------------------------------------------------------------------------------ | ----- | --------------------------------------------------------------- |
| uFawkesAI              | intent: Stage 5 review passes, a `REVIEW.md` and an agent PR-review job in the template          | G     | The playbook's Deploy stage; uFawkesAI has no `REVIEW.md` today |
| uFawkesObs + uFawkesAI | intent: Stage 6 loop, a σ-band breach in uFawkesObs opens an `intent` issue in the affected repo | G     | Cross-repo; reuses `dojo-feedback-intent.yml`'s issue format    |

## Totals

About 61 new issues (7 of them one-line devcontainer pins), about 25
relabels or retitles, and 5 closures. The `goal` share is high because each
release needs real runs that only a live, supervised session can verify.
OpenCode carries the content and mechanical volume underneath.
