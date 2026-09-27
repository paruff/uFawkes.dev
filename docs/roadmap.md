# uFawkes Roadmap (retired — see the suite release plan)

This roadmap (last updated 2026-08-15) was replaced on 2026-09-27. Where
things live now:

| Need                                                                       | Go to                                                                          |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Goals, decisions, release sequence                                         | [`docs/ai-sdlc/suite-release/`](ai-sdlc/suite-release/) (intent → spec → plan) |
| Live status across all repos                                               | [uFawkes Suite Release Project](https://github.com/users/paruff/projects/7)    |
| Research foundation (DORA, CNCF, SPACE; capability and archetype mappings) | [`docs/research-foundation.md`](research-foundation.md)                        |

The old file was indented four spaces throughout, so it rendered as one
code block. Its full text is in git history (`git log -p -- docs/roadmap.md`).

## What happened to each roadmap goal

Every goal was given one of four outcomes: **tracked** (it has an issue),
**done**, **superseded** (by the suite plan or a later decision), or
**open, not filed** (still true, but not chosen for filing on 2026-09-27).

### Phase 0 — Foundation

| #         | Goal                                                          | Outcome                                                                                                                                           |
| --------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| 0.1       | Create `fawkes/ROADMAP.md`                                    | Done                                                                                                                                              |
| 0.2       | Create uFawkesDORA                                            | Superseded: merged into uFawkesObs; `ufawkesdora` is archived                                                                                     |
| 0.3, 0.16 | Create, then consolidate, uFawkesSec                          | Merged into uFawkesPipe. The archival is **tracked**: #68                                                                                         |
| 0.4–0.8   | Repo descriptions, cross-links, stack pages, Roadmap nav link | Done. The nav link now points at the suite plan instead of `fawkes/ROADMAP.md`.                                                                   |
| 0.9       | GitHub Sponsors                                               | **Tracked:** #63                                                                                                                                  |
| 0.10–0.13 | GitOps templates, migration, branch-protection rulesets       | Done for 6 of 7 repos (verified 2026-09-27: ruleset, pre-commit, Dependabot, CODEOWNERS). uFawkesDojo's gap is **tracked**: paruff/uFawkesDojo#20 |
| 0.14      | opencode GitOps agent (migration Phase 4)                     | **Tracked:** #64                                                                                                                                  |
| 0.15      | Consolidate uFawkesDORA into uFawkesObs                       | Done: repo archived; `/dora/` and `/sec/` pages retired 2026-08-15                                                                                |

### Phase 1 — Stack parity and DORA integration

| Goal                                                                | Outcome                                                                                                                                                                                                    |
| ------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Each stack runnable in under 60s, with DORA dashboards and emission | Superseded by the per-release acceptance criteria in the suite plan (e.g. uFawkesObs v1.0.0: clean-machine install, paruff/uFawkesObs#494). The Pipe row's "Jenkins" was wrong; uFawkesPipe is Woodpecker. |

### Phase 2 — Dojo

| Goal                                                                               | Outcome                                                                                                                                                      |
| ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Dojo repo live, 3+ modules                                                         | Done: 20 modules, 2 runnable labs                                                                                                                            |
| 100+ learners                                                                      | Superseded by the suite's adoption measure: stars and forks, plus outside issues and PRs                                                                     |
| Restructure around the DORA AI Capabilities Model; capability maturity assessments | Superseded: the Dojo's direction is Compose-first, following release order (paruff/uFawkesDojo `docs/ai-sdlc/compose-curriculum/`). Revisit if still wanted. |
| Paid cohorts and certification                                                     | Superseded: certification isn't built and is no longer claimed on the Dojo site (paruff/uFawkesDojo#18)                                                      |

### Phase 3 — Research integration

| Goal                                                   | Outcome          |
| ------------------------------------------------------ | ---------------- |
| Research cited in every stack README; quarterly review | **Tracked:** #65 |

### Impact on uFawkes.dev

| Item                                                                     | Outcome                                                                                                        |
| ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------- |
| Real stack screenshots; blog launch posts                                | **Tracked:** #66 (part of the uFawkesObs v1.0.0 release)                                                       |
| Learn guides aligned with the Dojo                                       | **Tracked:** #67                                                                                               |
| `AGENTS.md` references uFawkesAI patterns                                | **Open, not filed.** Checked 2026-09-27: `AGENTS.md` has no uFawkesAI reference. File an issue if you want it. |
| Stack page content, DORA AI capability section, DORA/Sec page retirement | Done                                                                                                           |

### Open questions from the old roadmap

| Question                                              | Outcome                                                                                                                     |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Backstage in DevX, or something lighter?              | Resolved: uFawkesDevX uses Backstage                                                                                        |
| Sec tooling: OPA/Rego or Kyverno?                     | Resolved: uFawkesPipe uses a Conftest/Rego `policy-check` step                                                              |
| Dojo community model                                  | Resolved for now: GitHub Issues. Mattermost references were removed (paruff/uFawkesDojo#18), and Discussions isn't enabled. |
| uFawkesAI scope: templates only, or an agent runtime? | **Open, not filed.** This is a product decision for @paruff.                                                                |
