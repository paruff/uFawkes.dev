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
- **Tier 2: live systems.** `docs/ai-sdlc/suite-release/live-checks.yml`
  names the suite's scheduled workflows and flags which ones start a real
  stack; the page shows each one's latest run on `main` (pass, stale, fail
  with the failed steps, running or none). Obs's three acceptance workflows and
  fawkes's kind-cluster E2E already existed; Dojo's Live Acceptance (Nightly)
  shipped in uFawkesDojo#55. Pipe and DevX still have no scheduled workflows
  (uFawkesPipe#125, uFawkesDevX#88); an AI acceptance-stack workflow is
  uFawkesAI#160.
- **Still manual by nature:** the criteria that need a real run or a human
  judgment (16 today). They show "evidence pending" until evidence exists, and
  are then verified and aged like any other.
- **Not done:** per-scenario results from the acceptance suites (the page shows
  the suite's pass or fail, not each test).

## Truth check (2026-10-04)

Owner report: the page showed AI 2.0 and Dojo 0.2 well behind where the work
was. The board matched GitHub exactly; the gaps were upstream of the page.

- **Merged work, unclosed issues.** PRs referenced issues without a closing
  keyword (or closed them from another repo), so the issues stayed open. Each
  release now lists its open issues that a merged PR references as **"done but
  not closed?"**, from the issues' cross-reference and connected-PR events.
  Release umbrellas (`goal: release …` titles) are left out: many PRs reference
  them and the release closes them. The `goal` _label_ is model routing, not an
  umbrella. Verified by `scripts/test-suite-status.sh` and a live run.
- **A renamed image.** AC-AI-01 and AC-AI-05 checked `ufawkesai-devcontainer`;
  the image is now `fawkes-space`. AC-AI-05 requires the released
  `fawkes-space:2.0.0` (not a pre-release), so it fails until 2.0.0 ships.

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

### Verification for the status page fixes (dark bars, ID wrapping, empty issues)

| Criterion                                                                | How it's proven                                                                                    | Test type   | Command / CI job                      |
| ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------- | ----------- | ------------------------------------- |
| An empty progress bar is not light in dark mode                          | Read the computed track colour at 1100px and 390px in dark mode: `rgb(55, 65, 81)`, not `#e5e7eb`  | live-system | Playwright against a local build      |
| The check ID does not wrap mid-word                                      | `white-space: nowrap` on `.status-table__id`, checked in the same run                              | live-system | Playwright against a local build      |
| A release with no tracked issues says so instead of showing an empty bar | Screenshot of the local build, where four releases have none                                       | live-system | Playwright against a local build      |
| The blocker label and the done line are legible in dark mode             | Dark overrides use `#f87171` and `#4ade80` (6.58:1 and 10.44:1 on Night, from `make design-check`) | unit        | `bash scripts/check-design-tokens.sh` |
| No page scrolls sideways                                                 | `scrollWidth` equals `innerWidth` at 1100 and 390px                                                | live-system | Playwright against a local build      |
| CSS stays append-only                                                    | `git diff --numstat assets/css/main.css` shows no deleted lines                                    | unit        | `git diff --numstat`                  |

Not covered: the data in these screenshots comes from the real acceptance
checks run locally plus the fixture issue list, not from Project #7.

### Verification for the status page redesign

| Criterion                                                                           | How it's proven                                                                                                | Test type   | Command / CI job                 |
| ----------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- | ----------- | -------------------------------- |
| The verdict is the first thing under the title and says ready, waiting or not ready | Screenshot of the local build (light, dark, 390px): the verdict card, ring and three counts sit above the list | live-system | Playwright against a local build |
| The ring and bars show pass, fail, stale and awaiting evidence separately           | Same screenshots: AI 2.0 shows 3 failing and 6 awaiting evidence as separate segments                          | live-system | Playwright against a local build |
| No text is below its contrast floor, in light and dark                              | The text-node contrast walk on `/status/` in both schemes: 0 failing combinations                              | live-system | Playwright against a local build |
| No horizontal scroll at 1100px and 390px                                            | `scrollWidth` equals `innerWidth`                                                                              | live-system | Playwright against a local build |
| Motion respects `prefers-reduced-motion` and settles                                | Animations sit inside `prefers-reduced-motion: no-preference`; screenshots taken after 1.5s show full bars     | live-system | Playwright against a local build |
| Every colour has a symbol and a word beside it                                      | Verdict (✗ / ⏱ / ✓), pills, badges and the legend read without colour                                          | unit        | Review of `status/index.html`    |
| CSS stays append-only                                                               | `git diff --numstat assets/css/main.css` shows no deleted lines                                                | unit        | `git diff --numstat`             |

Not covered: the contrast walk reads the nearest solid background, so text
on the verdict card's gradient is measured against the page behind it (the
gradient runs between two neighbouring neutrals, so the error is small but
not zero). The data is the real acceptance checks run locally plus the
fixture issue list, not live Project #7. No real readers have tried the new
layout (AC-STATUS-07 is still open).
