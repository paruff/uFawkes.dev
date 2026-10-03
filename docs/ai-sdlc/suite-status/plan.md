# Plan: Suite status dashboard

**Traces to:** [`spec.md`](spec.md) → [`intent.md`](intent.md) |
**Status:** Implemented in code, awaiting owner steps | **Revision:** 2

Five small PRs, each independently mergeable. It can run in parallel with
the suite release's Phase 1, and it's most useful if it lands early.

## Order of work

| #   | PR                                                                                                                 | Route | Why that route                                  |
| --- | ------------------------------------------------------------------------------------------------------------------ | ----- | ----------------------------------------------- |
| 1   | `acceptance.yml` for every suite-release AC, plus the drift check against `spec.md` (AC-STATUS-01)                 | G     | Deciding which ACs can be automated is judgment |
| 2   | `scripts/suite-status.sh` + `make status`: AC checks, Project #7 query, JSON, terminal summary (AC-STATUS-02, -03) | U     | Bounded; the spec gives the contract            |
| 2b  | Wireframe review: one product owner and one developer answer their question from it (AC-STATUS-07)                 | G     | Needs real readers; it gates PR 3               |
| 3   | `/status/` page: Liquid + CSS cards, bars, AC table, SVG burn-up, staleness banner (AC-STATUS-05, -06)             | U     | Bounded; follows site conventions               |
| 4   | `deploy.yml`: daily schedule, `SUITE_STATUS_TOKEN`, JSON into the Pages artifact (AC-STATUS-04)                    | G     | Secrets and the deploy path                     |
| 5   | Nav link, `AGENTS.md` pointer to the JSON (R6), link from `suite-release/plan.md`                                  | F     | Mechanical                                      |

**You do one step by hand:** create the fine-grained PAT (read-only,
`read:project` on your Projects) and save it as the `SUITE_STATUS_TOKEN`
repository secret. That's an account action I can't take for you.

## v2, after uFawkesDevX `v0.1.0` (not scheduled yet)

- **uFawkesDevX:** a Backstage "Suite release" card that reads
  `/status/suite_status.json`. That's the internal developer view you
  described.
- **uFawkesObs:** a Grafana panel (JSON datasource) with AC pass rate and
  burn-up over time, next to the suite's own DORA metrics.
- Both reuse the JSON contract unchanged. If either needs a new field, it's
  added to R3 first.

## Accuracy upgrades (2026-10-03)

The first version counted a manual criterion as passing if its evidence field
held any URL, and automated 6 of 27 criteria. Owner request: "as complete
accurate data as possible", with 30 days as the stale limit.

- **Tier 1: evidence is verified, not trusted.** A link must resolve, a PR must
  be merged, an issue closed, and the evidence must be at most 30 days old,
  else `stale`. A lookup that fails is `stale`, never `pass`. AC-SUITE-01, -02,
  -03, AC-DOJO-01 and AC-OBS-02 are fully machine-checkable, so they run as
  commands (`scripts/checks/`).
- **Tier 2: live systems.** `live-checks.yml` names the workflows that start a
  real stack; the page shows each one's latest run on `main` (pass, stale, fail
  with the failed steps, or none). Obs's three acceptance workflows and fawkes's
  kind-cluster E2E already existed; Pipe, DevX, Dojo and AI have none, tracked in
  uFawkesPipe#125, uFawkesDevX#88, uFawkesDojo#55 and uFawkesAI#160.
- **Still manual by nature:** the criteria that need a real run or a human
  judgment (16 today). They show "evidence pending" until evidence exists, and
  are then verified and aged like any other.
- **Not done:** per-scenario results from the acceptance suites (the page shows
  the suite's pass or fail, not each test).

## Verification Strategy

| Criterion    | How it's proven                                                | Test type   | Command / CI job                                         |
| ------------ | -------------------------------------------------------------- | ----------- | -------------------------------------------------------- |
| AC-STATUS-01 | Drift check fails on a spec AC with no `acceptance.yml` entry  | unit        | `make status-check-drift` in Pre-flight                  |
| AC-STATUS-02 | JSON validates against the R3 shape                            | unit        | `make status && jq -e` schema assertions                 |
| AC-STATUS-03 | Broken AC → red; broken script → failed run                    | integration | Two throwaway PRs                                        |
| AC-STATUS-04 | Two scheduled runs update the page; no bot commits on `main`   | live-system | `gh run list -w deploy.yml`, `git log`                   |
| AC-STATUS-05 | Page renders at three widths                                   | live-system | Playwright screenshots                                   |
| AC-STATUS-06 | Accessibility job passes                                       | integration | `Accessibility Testing` check                            |
| AC-STATUS-08 | A dead link, unmerged PR or evidence over 30 days old is stale | unit        | `scripts/test-suite-status.sh` (stubbed `gh` and `curl`) |
| AC-STATUS-09 | Machine-checkable criteria run as commands and name what fails | unit + live | The same tests, plus `make status` against GitHub        |

## Risks

| Risk                                                      | Mitigation                                                                    |
| --------------------------------------------------------- | ----------------------------------------------------------------------------- |
| The PAT expires and the page silently goes stale          | The staleness banner after 36h; the scheduled run fails loudly on auth errors |
| Slow or flaky AC checks (registry, network) make it noisy | A 60s timeout per check; a timeout shows as "fail: timed out", not a crash    |
| `acceptance.yml` drifts from `spec.md`                    | The drift check gates PRs (AC-STATUS-01)                                      |
| The pace estimate is read as a promise                    | Labeled "estimate"; hidden when there's too little data                       |

## Implementation status

Verified, as of 2026-10-03:

- **Offline:** the drift check, the R3 JSON shape, the pace and burn-up
  arithmetic, the failing-AC and broken-script behavior, evidence verification
  and every machine check (`scripts/test-suite-status.sh`, part of the unit
  tests that run in Pre-flight). The page builds and renders without
  horizontal scroll at 1100, 767 and 640px.
- **Live:** the Project #7 query and all machine checks run against GitHub
  (`make status` takes about 30 seconds). The `SUITE_STATUS_TOKEN` secret exists
  and the scheduled deploy of 2026-10-03 ran the status step successfully.
- **Not verified:** AC-STATUS-03's two throwaway PRs, the `Accessibility
Testing` check for the new sections (AC-STATUS-06), and the wireframe review
  with real readers (AC-STATUS-07).
