# Plan: One design reference for Fawkes and uFawkes

**Traces to:** [`intent.md`](intent.md) | **Status:** Draft | **Revision:** 1

## Order of work

| #   | Step                                                                                          | Route | Why that route                                 |
| --- | --------------------------------------------------------------------------------------------- | ----- | ---------------------------------------------- |
| 1   | Inventory the seven repos (done 2026-10-02; results are in `DESIGN.md` section 1)             | G     | Judgment about what each repo needs            |
| 2   | `design/tokens.json`, `design/marks/flame.svg`, the contrast check and `DESIGN.md` (this PR)  | G     | The direction is a design decision             |
| 3   | Apply the tokens to ufawkes.dev: buttons, links, focus, favicon, header mark                  | U     | Bounded once step 2 is merged                  |
| 4   | Pointer PRs in the other six repos (README and `AGENTS.md` line), one repo each               | U ×6  | Mechanical, needs owner approval to touch them |
| 5   | Repos with their own CSS adopt the tokens: Dojo, DevX API docs, then the Fawkes design system | G → U | Dojo and the design system need decisions      |

## Verification Strategy

| Criterion                                                    | How it's proven                                                       | Test type   | Command / CI job                           |
| ------------------------------------------------------------ | --------------------------------------------------------------------- | ----------- | ------------------------------------------ |
| Every token contrast pair meets its floor                    | The check computes WCAG ratios from the hex values                    | unit        | `bash scripts/check-design-tokens.sh`      |
| The check fails when a pair is below the floor or unresolved | Fixture files with a low pair, a missing path, a bad colour, no pairs | unit        | `bash scripts/test-check-design-tokens.sh` |
| The tokens are valid JSON and published                      | `jekyll build` leaves `_site/design/tokens.json`                      | integration | Build Site                                 |
| The flame renders legibly at 16px on light and dark          | Screenshot of the SVG at 16, 32 and 220px on white and Night          | live-system | Playwright against a local build           |
| `DESIGN.md` is formatted and lints                           | Prettier 3.9.9 and markdownlint                                       | unit        | Lint / Format Check, Markdown Lint         |

### Verification for step 3 (apply the tokens to ufawkes.dev)

| Criterion                                                                   | How it's proven                                                                       | Test type   | Command / CI job                 |
| --------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | ----------- | -------------------------------- |
| No text on 10 pages is below its contrast floor, in light and dark mode     | Playwright walks every text node, computes the ratio against its effective background | live-system | Playwright against a local build |
| Buttons, links and focus rings use Indigo, and live badges use the AA green | Screenshots at 1280px in light and dark; `.badge--live` is `#15803d`, not `#16a34a`   | live-system | Playwright against a local build |
| The flame is the favicon and the header mark                                | `_site/design/marks/flame.svg` exists and the home page links it twice                | integration | `jekyll build`, Build Site       |
| No page scrolls sideways at 1280, 800 and 390px; each has one `<h1>`        | `scrollWidth <= innerWidth` and an `h1` count on six pages                            | live-system | Playwright against a local build |
| CSS stays append-only                                                       | The diff to `assets/css/main.css` only adds lines                                     | unit        | `git diff --stat` (no deletions) |

## Risks

| Risk                                                             | Mitigation                                                                                          |
| ---------------------------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| The interim flame is mistaken for the final mark                 | It is labelled interim in `DESIGN.md` and in the file's title                                       |
| The token file drifts from the Fawkes design system's own tokens | `DESIGN.md` names the design system as the source for the indigo scale; a generator is a later step |
| Owner disagrees with the proposed colour roles                   | They are in one file; changing a role changes the check, not the code                               |
