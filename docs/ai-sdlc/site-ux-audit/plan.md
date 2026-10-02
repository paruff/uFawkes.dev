# Plan: Site UX audit fixes

**Traces to:** [`intent.md`](intent.md) | **Status:** Draft | **Revision:** 1

One PR. Every change is CSS, a layout or a front matter edit, apart from the
status JSON path and the deploy step.

## Order of work

| #   | Change                                                                                 | Files                                                       |
| --- | -------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| 1   | Inline desktop navigation; shorter nav labels                                          | `assets/css/main.css`, `_data/navigation.yml`               |
| 2   | Stop mobile overflow (grid `minmax(0, 1fr)`, wrapping commands, scrolling tables)      | `assets/css/main.css`                                       |
| 3   | One `<h1>` on the home page; quick start first on stack pages                          | `_layouts/home.html`, `_layouts/stack.html`                 |
| 4   | Page titles and the blog description                                                   | `blog/index.md`, `learn/index.md`, `compatibility/index.md` |
| 5   | AA contrast for the active and Dojo nav links                                          | `assets/css/main.css`                                       |
| 6   | Ship the status JSON with the build; a failed status step must not block a push deploy | `scripts/suite-status.sh`, `.github/workflows/deploy.yml`   |

## Verification Strategy

| Criterion                                           | How it's proven                                                           | Test type   | Command / CI job                              |
| --------------------------------------------------- | ------------------------------------------------------------------------- | ----------- | --------------------------------------------- |
| Desktop nav is visible at 1280px and 800px          | Nav links have opacity 1 and a toggle with `display: none`                | live-system | Playwright against a local build              |
| No horizontal scroll at 390px on the four pages     | `scrollWidth <= innerWidth` on each page                                  | live-system | Playwright against a local build              |
| Exactly one `<h1>` on every page                    | Count `h1` elements on all 11 pages                                       | live-system | Playwright against a local build              |
| Mobile menu still opens                             | Click the toggle at 390px; the nav has opacity 1                          | live-system | Playwright against a local build              |
| Titles and the blog description are page-specific   | Read `document.title` and the meta description on each page               | live-system | Playwright against a local build              |
| Status JSON is served next to the page              | `make status` then `jekyll build` leaves `_site/status/suite_status.json` | integration | `scripts/suite-status.sh`, `jekyll`           |
| Status unit tests still pass                        | The offline suite                                                         | unit        | `scripts/run-unit-tests.sh`                   |
| Build, lint and accessibility checks pass on the PR | CI                                                                        | integration | `Build Site`, `Lint`, `Accessibility Testing` |

## Risks

| Risk                                                            | Mitigation                                           |
| --------------------------------------------------------------- | ---------------------------------------------------- |
| Eleven links do not fit on one row between 768px and 1000px     | The nav wraps to two rows; checked at 800px          |
| `continue-on-error` hides a broken status step on a push deploy | The step stays red and a warning annotation names it |
