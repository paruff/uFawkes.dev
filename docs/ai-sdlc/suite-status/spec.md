# Spec: Suite status dashboard

**Traces to:** [`intent.md`](intent.md) | **Status:** Draft | **Revision:** 1

## Requirements

**R1. Machine-readable acceptance criteria.**
`docs/ai-sdlc/suite-release/acceptance.yml` lists every AC in the suite
release spec:

```yaml
- id: AC-AI-01
  release: AI 2.0 # matches a Project #7 "Release" option
  title: The devcontainer image can be pinned
  check: command # command | manual
  run: docker manifest inspect ghcr.io/paruff/ufawkesai-devcontainer:2.0.0
  evidence: "" # manual ACs: link to the transcript, run or PR
```

`spec.md` stays the human source. A check fails if any `#### AC-` heading
in `suite-release/spec.md` has no entry in `acceptance.yml`, or the other
way round, so the two can't drift.

**R2. One command.** `make status` runs `scripts/suite-status.sh`, which:

- runs each `check: command` AC with a 60-second timeout and records pass
  or fail, with the first lines of output on a failure
- counts a `check: manual` AC as passing only if `evidence` is a URL
- queries Project #7 (GraphQL) for each item's release, status, labels and
  `closedAt`
- writes `_data/suite_status.json` (R3) and prints a terminal summary

It exits non-zero only when the **script** breaks (bad YAML, API error). A
failing AC is a result, not a script error.

**R3. Data contract, `_data/suite_status.json`:**

```json
{
  "generated_at": "2026-10-02T06:00:00Z",
  "run_url": "https://github.com/paruff/uFawkes.dev/actions/runs/...",
  "next_release": "AI 2.0",
  "releases": [
    {
      "name": "AI 2.0",
      "order": 1,
      "acs": { "pass": 3, "fail": 4, "manual_pending": 2, "total": 9 },
      "issues": { "done": 5, "in_progress": 2, "todo": 11, "total": 18 },
      "blockers": [{ "repo": "uFawkesAI", "number": 111, "title": "..." }],
      "routing": { "goal": 6, "nemotron": 7, "flash": 5 },
      "pace": { "closed_last_28d": 8, "weeks_to_done_estimate": 3.5 },
      "ac_results": [
        { "id": "AC-AI-01", "status": "fail", "detail": "manifest unknown" }
      ]
    }
  ],
  "burnup": [{ "date": "2026-09-27", "done": 10, "total": 48 }]
}
```

- **Next release:** the first release, in the plan's order, whose ACs
  aren't all passing.
- **Burn-up:** recomputed every run from issue `createdAt` and `closedAt`,
  so no history file is stored or committed.
- **Pace estimate:** `remaining issues ÷ (issues closed in the last 28 days
÷ 4)`, labeled as an estimate on the page. No estimate is shown when
  fewer than three issues closed in the window.

**R4. The `/status/` page.** One Jekyll page rendered from the JSON with
Liquid and vanilla CSS (BEM, appended to `main.css`):

- **Header:** "Next milestone: AI 2.0". ACs passing x/y, issues done x/y,
  open blockers, an estimate in weeks, and "checked 06:00 UTC · run log".
- **One card per release,** in plan order: two progress bars (ACs, issues),
  a blocker list linking to GitHub, and the routing split. Completed
  releases collapse to one line.
- **AC table** for the next release: id, title, pass/fail/manual, detail.
- **Burn-up chart:** an inline SVG polyline built by Liquid from `burnup`.
  No chart library.
- **Staleness:** if `generated_at` is over 36 hours old, a banner says the
  data is stale.
- Accessible: status is never shown by color alone (text labels too), bars
  have text values, and the layout holds at the canonical 767px and 640px
  breakpoints.

**R5. Daily run, no commits.** `deploy.yml` gains
`schedule: cron '0 6 * * *'` and runs `make status` before `jekyll build`.
The JSON goes into that build's Pages artifact, and is also published as
`/status/suite_status.json` so agents and v2 consumers can fetch it.

**R6. Agents read it.** `AGENTS.md` points agents to
`https://ufawkes.dev/status/suite_status.json` for current status, instead
of re-querying.

## Design

- **Bash, `gh` and `jq`:** all three are on GitHub's runners and in the
  devcontainer. No new runtime.
- **Auth:** reading a user-level Project v2 needs a token with
  `read:project`, which the default `GITHUB_TOKEN` lacks. A fine-grained
  PAT is stored as the `SUITE_STATUS_TOKEN` secret, read-only.
- **Check scripts stay small.** Most `run:` lines are one command (`grep`,
  `docker manifest inspect`, `gh api`). Anything longer goes in
  `scripts/checks/<ac-id>.sh`.
- **No `{% unless %}` or `{% case %}`** (site rule). Status classes come
  from the JSON value directly: `status-card--{{ ac.status }}`.

## Acceptance criteria

| ID           | Criterion                                                                     | Verification                                                      |
| ------------ | ----------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| AC-STATUS-01 | Every AC in `suite-release/spec.md` is in `acceptance.yml`, and vice versa    | The drift check fails a PR that adds a spec AC without an entry   |
| AC-STATUS-02 | `make status` runs locally and in CI and produces JSON matching R3            | A schema check on the output, in CI                               |
| AC-STATUS-03 | A failing AC shows red on the page; a broken script fails the workflow        | Two test PRs: one breaks an AC, one breaks the script             |
| AC-STATUS-04 | `/status/` updates daily without a commit to `main`                           | Two consecutive scheduled runs; `git log main` has no bot commits |
| AC-STATUS-05 | The page shows the next milestone, both progress bars, blockers and a burn-up | Screenshot at desktop, 767px and 640px                            |
| AC-STATUS-06 | The page passes the site's existing accessibility job                         | `Accessibility Testing` check green                               |

## Concerns

- **Public red checks.** That's intended, and it serves credibility. If you'd
  rather keep it private until AI 2.0 ships, add `noindex` and leave it out
  of the nav for now. One line either way.
- **Manual ACs** (clean-host transcripts, real runs) can't be automated by
  design. The page shows them as "manual: evidence pending" until a link
  lands in `acceptance.yml`, so they're never silently counted as passing.
