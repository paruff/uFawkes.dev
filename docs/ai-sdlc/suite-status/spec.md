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

## UX: update process, audiences and views

### When the page updates

| Trigger                         | Why                                                               |
| ------------------------------- | ----------------------------------------------------------------- |
| Daily, 06:00 UTC (scheduled)    | Catches drift nobody touched: an expired tag, a closed blocker    |
| Every merge to `main`           | `deploy.yml` already rebuilds on push, so plan edits show at once |
| On demand (`workflow_dispatch`) | Before a release decision or a stakeholder review                 |
| Locally (`make status`)         | A developer's terminal view; it publishes nothing                 |

The page always says when it was checked and links to the run, so a reader
can tell fresh data from stale.

### Two audiences, two questions

| Audience                        | Their question                                                   | What answers it, in reading order                                                         |
| ------------------------------- | ---------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| **Product owner / stakeholder** | "Are we on track for the next release? What's in the way? When?" | The headline sentence, the release timeline, blockers, the pace estimate                  |
| **Developer / agent**           | "What's failing, why, and what do I pick up next?"               | The AC table with failure detail and run links, then the "ready to pick up" list by route |

The product owner's answer sits at the top, and the developer's detail
follows it. Both read the same data, so they never see two versions of the
truth.

### Page structure, following the site's Why → What → How → Proof → Next

```
┌──────────────────────────────────────────────────────────────────────┐
│ Suite status                              checked 06:00 UTC · run ↗  │ Why: one line
│ Is the uFawkes suite ready to ship its next release?                 │
├──────────────────────────────────────────────────────────────────────┤
│ NEXT MILESTONE: uFawkesAI v2.0.0                                     │ What: plain-
│ 3 of 9 acceptance checks pass · 5 of 18 issues done · 1 blocker      │ language headline
│ About 4 weeks at the current pace (estimate)                         │
├──────────────────────────────────────────────────────────────────────┤
│ ● AI 2.0 ── ○ Dojo 0.2 ── ○ Obs 1.0 ── ○ Pipe 2.0 ── ○ DevX ── ○ fawkes │ How far: timeline
├──────────────────────────────────────────────────────────────────────┤
│ [card] uFawkesAI v2.0.0                       NEXT                   │ How much: one card
│   Acceptance  ███░░░░░░  3 / 9                                       │ per release
│   Issues      █████░░░░  5 / 18                                      │
│   Blocker: uFawkesAI#111 devcontainer image can't be pinned ↗        │
│   Work: 6 goal · 7 Nemotron · 5 Flash                                │
│ [card] Dojo 0.2 ... (collapsed one-liners once shipped)              │
├──────────────────────────────────────────────────────────────────────┤
│ Acceptance checks: uFawkesAI v2.0.0                                  │ Proof: real check
│  ✗ FAIL    AC-AI-01  Image can be pinned   "manifest unknown" ↗      │ results, not claims
│  ✓ PASS    AC-AI-03  Contract written down                           │
│  … MANUAL  AC-AI-02  Template run           evidence pending         │
├──────────────────────────────────────────────────────────────────────┤
│ Progress over time  [burn-up: total vs done]  + one-sentence summary │
├──────────────────────────────────────────────────────────────────────┤
│ Ready to pick up (next release, unassigned)                          │ Next: the action
│  goal      uFawkesAI#111  Publish the image with SemVer tags ↗       │
│  Nemotron  uFawkesAI#28   Placeholder audit CI check ↗               │
│  Flash     …                                                         │
│ Full board: Project #7 ↗                                             │
└──────────────────────────────────────────────────────────────────────┘
```

At 640px and below, the timeline stacks vertically, the cards go to one
column, and the AC table becomes a list (status, id, title, then detail on
its own line).

### Visual rules (from the site's visual-design skill)

- **Cards:** white, `1px solid #e5e7eb`, 8px radius, 24px padding (16px on
  mobile). The next-release card gets the green accent border.
- **Status is never color alone.** Each status carries a symbol and a word.
  Contrast was measured on 2026-10-01, not assumed:

  | Badge    | Text on background     | Contrast | WCAG AA (normal text) |
  | -------- | ---------------------- | -------- | --------------------- |
  | ✓ PASS   | `#15803d` on `#dcfce7` | 4.57:1   | Pass                  |
  | ✗ FAIL   | `#b91c1c` on `#fee2e2` | 5.30:1   | Pass                  |
  | … MANUAL | `#4b5563` on `#f3f4f6` | 6.87:1   | Pass                  |

  Don't use the brand green `#16a34a` for badge or body text: it measures
  3.30:1 on white and 3.00:1 on `#dcfce7`, below AA. (The site's
  visual-design skill lists it as 4.7:1; that figure is wrong. See the
  concern below.)

- **Progress bars:** an 8px track in `#e5e7eb` with a `#16a34a` fill (a
  graphic, so 3:1 is enough under WCAG 1.4.11), and
  the "3 / 9" text always beside the bar, never only inside it.
- **Burn-up:** an inline SVG with total (dashed, muted) and done (green).
  The summary sentence under it is the text alternative.
- **Spacing:** multiples of 8px, 960px content width, with the canonical
  767px and 640px breakpoints.

### Copy rules (from the site's content-strategy skill)

- **Plain and specific:** "3 of 9 acceptance checks pass", not "30%
  complete" or "on track!".
- **Honest about uncertainty:** "About 4 weeks at the current pace
  (estimate)". With too little data, it says "Not enough completed work yet
  to estimate."
- **Failures shown as facts, with the error and a link:** never softened,
  and never hidden behind a "details" toggle for the next release.
- **Unique meta description:** "Live release status for the uFawkes suite:
  acceptance checks, open work and blockers, re-checked daily."

### Validate with real readers

Before PR 3 is built, show the wireframe to one product-owner reader (you)
and one developer reader. Each answers their own question from the
wireframe alone, within 30 seconds. After launch, run the site's `ux-audit`
protocol on `/status/`.

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

| ID           | Criterion                                                                              | Verification                                                      |
| ------------ | -------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| AC-STATUS-01 | Every AC in `suite-release/spec.md` is in `acceptance.yml`, and vice versa             | The drift check fails a PR that adds a spec AC without an entry   |
| AC-STATUS-02 | `make status` runs locally and in CI and produces JSON matching R3                     | A schema check on the output, in CI                               |
| AC-STATUS-03 | A failing AC shows red on the page; a broken script fails the workflow                 | Two test PRs: one breaks an AC, one breaks the script             |
| AC-STATUS-04 | `/status/` updates daily without a commit to `main`                                    | Two consecutive scheduled runs; `git log main` has no bot commits |
| AC-STATUS-05 | The page shows the next milestone, both progress bars, blockers and a burn-up          | Screenshot at desktop, 767px and 640px                            |
| AC-STATUS-06 | The page passes the site's existing accessibility job                                  | `Accessibility Testing` check green                               |
| AC-STATUS-07 | A product owner and a developer each answer their question from the page in 30 seconds | Wireframe test before PR 3; `ux-audit` after launch               |

## Concerns

- **Public red checks.** That's intended, and it serves credibility. If you'd
  rather keep it private until AI 2.0 ships, add `noindex` and leave it out
  of the nav for now. One line either way.
- **Manual ACs** (clean-host transcripts, real runs) can't be automated by
  design. The page shows them as "manual: evidence pending" until a link
  lands in `acceptance.yml`, so they're never silently counted as passing.
- **Site-wide contrast bug, found while specifying this page:** the brand
  green `#16a34a` is 3.30:1 against white, and white button text on it is
  also 3.30:1. Both fail AA for normal text, which affects every primary
  CTA on ufawkes.dev. `#15803d` measures 5.02:1 with white text. This
  belongs in its own issue (route G: it's a brand decision), and the
  visual-design skill's "4.7:1" figure needs correcting.
