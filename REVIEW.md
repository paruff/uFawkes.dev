# REVIEW.md

Apply the suite rules in [uFawkesAI REVIEW.md](https://github.com/paruff/uFawkesAI/blob/main/REVIEW.md):
severity, what to flag (verification, validation, security), what to skip, the
output and the board move. This file adds only what is specific to this repo.

## Checks the PR must paste

- `make validate` (pre-commit, every hook)
- `make build`, with a non-empty `_site/`
- `make design-check` when `DESIGN.md` or `design/tokens.json` changes
- `npx @google/design.md@0.4.0 lint DESIGN.md` when `DESIGN.md` changes: 0 errors, 0 warnings

## UI

[`DESIGN.md`](DESIGN.md) is the suite design system. Changes to it or to
`design/tokens.json` need the owner.

## Repo rules

The hard constraints in [`AGENTS.md`](AGENTS.md) §2 (stack), §5 (Liquid) and
§6 (CSS) are Critical if broken: a new npm, plugin or framework, a disallowed
Liquid tag, or a reordered `main.css`.
