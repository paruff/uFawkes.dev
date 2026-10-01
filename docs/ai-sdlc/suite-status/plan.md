# Plan: Suite status dashboard

**Traces to:** [`spec.md`](spec.md) → [`intent.md`](intent.md) |
**Status:** Draft | **Revision:** 1

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

## Verification Strategy

| Criterion    | How it's proven                                               | Test type   | Command / CI job                         |
| ------------ | ------------------------------------------------------------- | ----------- | ---------------------------------------- |
| AC-STATUS-01 | Drift check fails on a spec AC with no `acceptance.yml` entry | unit        | `make status-check-drift` in Pre-flight  |
| AC-STATUS-02 | JSON validates against the R3 shape                           | unit        | `make status && jq -e` schema assertions |
| AC-STATUS-03 | Broken AC → red; broken script → failed run                   | integration | Two throwaway PRs                        |
| AC-STATUS-04 | Two scheduled runs update the page; no bot commits on `main`  | live-system | `gh run list -w deploy.yml`, `git log`   |
| AC-STATUS-05 | Page renders at three widths                                  | live-system | Playwright screenshots                   |
| AC-STATUS-06 | Accessibility job passes                                      | integration | `Accessibility Testing` check            |

## Risks

| Risk                                                      | Mitigation                                                                    |
| --------------------------------------------------------- | ----------------------------------------------------------------------------- |
| The PAT expires and the page silently goes stale          | The staleness banner after 36h; the scheduled run fails loudly on auth errors |
| Slow or flaky AC checks (registry, network) make it noisy | A 60s timeout per check; a timeout shows as "fail: timed out", not a crash    |
| `acceptance.yml` drifts from `spec.md`                    | The drift check gates PRs (AC-STATUS-01)                                      |
| The pace estimate is read as a promise                    | Labeled "estimate"; hidden when there's too little data                       |
