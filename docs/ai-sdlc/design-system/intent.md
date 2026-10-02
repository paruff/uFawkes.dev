# Intent: One design reference for Fawkes and uFawkes

**Owner:** @paruff | **Created:** 2026-10-02 | **Status:** Draft

## Problem

An inventory of the seven repos on 2026-10-02 found no shared visual
identity:

- the Fawkes phoenix and the uFawkes flame favicon are orange
- ufawkes.dev uses green (`#16a34a`) as its accent, which fails text contrast
  (3.30:1 on white)
- the Fawkes design system (`paruff/fawkes`, `design-system/`) and its MkDocs
  site use indigo (`#6366f1`, and Material's indigo)
- uFawkesDojo and uFawkesDevX's API docs use a violet gradient
  (`#667eea` to `#764ba2`) with no logo or favicon
- uFawkesAI, uFawkesObs and uFawkesPipe have no site, only badges and
  dashboards
- the `fawkes` README points to a logo file (`docs/images/fawkes-logo.png`)
  that does not exist

## Desired outcome

`uFawkes.dev` is the one canonical home for the design reference
(`DESIGN.md`), the machine-readable tokens (`design/tokens.json`, published
at `https://ufawkes.dev/design/tokens.json`) and the marks
(`design/marks/`). Every other repo points to it, and a check keeps the
tokens above their contrast floor.

## Out of scope

- Restyling the other repos. They are proposed, one small PR each, after the
  owner approves the direction.
- A final logo. The flame in `design/marks/flame.svg` is an interim mark.
