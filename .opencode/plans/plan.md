# uFawkes.dev — Plan

> Project identity, stack, and conventions: see `AGENTS.md`

---

## Status lives on Project #7

This file is no longer a tracker. What is next, and what waits on a human, is
on [Project #7](https://github.com/users/paruff/projects/7): run the two
commands in `AGENTS.md` §8. The old PR tables (PR 1 to PR 7) are in git
history; the rows still open on 2026-10-24 map as follows.

| Old row                                        | Now                                                                   |
| ---------------------------------------------- | --------------------------------------------------------------------- |
| PR 4 sprint 6: screenshots and trust signals   | #66 (closed)                                                          |
| PR 7 G1 to G7: GitOps templates and migration  | #12 (closed); the standard is `docs/ai-sdlc/suite-hygiene/`           |
| PR 7 G8: opencode GitOps agent                 | #64 (open)                                                            |
| PR 5 D to I: local agent, skill and MCP setup  | No issue yet: local OpenCode setup, open one if it is still wanted    |

## History

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

_Last updated: 2026-10-24_
