---
name: code-quality
description: Code quality standards for uFawkes.dev — Jekyll/Liquid linting rules, CSS validation, HTML structure checks, and review thresholds. Used by Review and Build agents.
license: MIT
compatibility: opencode
---

# Code Quality — uFawkes.dev

## Liquid quality rules

### Syntax

- Every `{% if %}` has `{% endif %}`
- Every `{% for %}` has `{% endfor %}`
- Every `{% capture %}` has `{% endcapture %}`
- No unclosed tags — `make build` will fail, but catch manually before running

### Filter usage

Only use whitelisted filters. If unsure, check:

```
relative_url  absolute_url  url_encode  date
markdownify   strip_html    truncate    slugify
```

### Logic

- Simple conditions only: `{% if page.key %}` or `{% if page.key == 'value' %}`
- Never: `{% unless %}`, `{% case %}`, chained captures
- For booleans in front matter: `{% if page.coming_soon %}` (not `{% if page.coming_soon == true %}`)

## HTML quality rules

- Semantic elements: `<header>`, `<main>`, `<nav>`, `<footer>`, `<article>`, `<section>`
- One `<h1>` per page
- Sequential heading levels — no skips
- All `<img>` have `alt` attribute
- All external links: `rel="noopener noreferrer" target="_blank"`
- No inline styles — use CSS classes

## CSS quality rules

### Structure

- Append only — never reorder existing rules
- One blank line between rule blocks
- Comment section boundaries: `/* === Section Name === */`

### Naming

```css
/* Correct BEM */
.stack-card {
}
.stack-card__header {
}
.stack-card__header--featured {
}

/* Wrong */
.stackCard {
} /* camelCase */
.stack_card {
} /* underscores */
.card-header-featured {
} /* not BEM */
```

### Values

- Colors: hex only (`#4f46e5` not `blue` not `rgb(79, 70, 229)`)
- Spacing: multiples of 8px
- No `!important` except in accessibility utilities (sr-only, prefers-reduced-motion)
- No `z-index` values above 100 without Planning agent approval

## Build quality gates

All must pass before Review agent approves:

| Check               | Command                                   | Expected                     |
| ------------------- | ----------------------------------------- | ---------------------------- |
| Build success       | `make build`                              | Exit 0, no errors            |
| No placeholder text | `grep -r "Screenshot placeholder" _site/` | No output                    |
| No raw Liquid       | `grep -r "{{" _site/`                     | No output                    |
| Heading structure   | Manual check                              | Single H1, sequential levels |

## Commit quality

Format: `fix(scope): description (#N)` — every field required.
One file per commit. No "WIP" commits to main.
Commit messages are permanent — write them for the person reading git log in 6 months.
