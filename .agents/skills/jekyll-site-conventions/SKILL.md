---
name: jekyll-site-conventions
description: Hard constraints for uFawkes.dev — Jekyll stack, GitHub Pages limits, Liquid safety rules, CSS conventions, front matter patterns, and commit format. Load this skill before any implementation task.
license: MIT
compatibility: opencode
---

# Jekyll Site Conventions — uFawkes.dev

## Stack (never deviate)

| Layer      | Value                                                           |
| ---------- | --------------------------------------------------------------- |
| Generator  | Jekyll 4.4.1                                                    |
| Theme      | minima (overridden via `_layouts/`, `_includes/`)               |
| Plugins    | `jekyll-feed` ONLY — no others                                  |
| CSS        | Vanilla CSS in `assets/css/main.css` — BEM naming — append-only |
| JS         | Vanilla JS only in `assets/js/nav.js`                           |
| Templating | Liquid (Jekyll-flavored) — whitelisted filters only             |
| Deployment | GitHub Pages from `main` root — no build step                   |

**Never introduce:** npm, webpack, Vite, Tailwind, SCSS build pipeline, CSS custom properties (variables), React, Astro, Vue, Jekyll plugins not on GitHub Pages whitelist, or any server-side logic.

## Build commands

```bash
make serve    # bundle exec jekyll serve --livereload
make build    # bundle exec jekyll build
```

Run `make build` after **every** file change. If it fails, revert and report.

## Liquid safety rules

### Allowed filters only

```
relative_url    absolute_url    url_encode
date            markdownify     strip_html
truncate        slugify
```

### Never use

- `{% unless %}` — confuses small models, use `{% if %}` with negation
- `{% case %}` — use chained `{% elsif %}` instead
- Multi-variable assign chains
- Invented filter names

### Include safety

- Always verify the included file exists before referencing it
- After adding any `{% include %}`, run `make build` and confirm output is not empty at that location

## CSS conventions

### File

- Single file: `assets/css/main.css`
- **Append new rules at the END only** — never reorder or restructure existing rules

### Naming

- BEM strictly: `.block`, `.block__element`, `.block--modifier`
- No camelCase, no underscores in class names, no utility classes

### Breakpoints (canonical — do not invent others)

```css
@media (max-width: 767px) {
  /* tablet */
}
@media (max-width: 640px) {
  /* mobile */
}
```

### Brand tokens (use hex directly — no CSS variables yet)

```
#4f46e5   Indigo — links, focus rings, secondary buttons, Dojo accent
#f06300   Flame — brand/identity: marks, favicon, accents, and the primary button fill with a #061723 label (never as text)
#15803d   green — pass / live status only
(full palette and contrast rules: DESIGN.md, design/tokens.json)
#111827   text primary — headings
#374151   text secondary — body
#6b7280   text muted — metadata, captions
#e5e7eb   border default — cards, dividers
#ffffff   background default
#f9fafb   background subtle — section backgrounds
```

### Spacing

- All spacing in multiples of 8px
- No arbitrary pixel values

## Front matter conventions

### General pages

```yaml
---
layout: default # or home, post, stack
title: Page Title
description: "Page-specific meta description — NOT the global tagline"
permalink: /path/ # only when overriding Jekyll default
---
```

### Stack pages (required keys)

```yaml
---
layout: stack
title: uFawkesObs
stack_name: Obs
hero: "One-line hero text."
summary: "One-line summary for cards"
coming_soon: false
repo_url: https://github.com/paruff/ufawkes-obs
repo_name: ufawkes-obs
screenshot_placeholder: false
features:
  - Feature one
quick_start:
  - step: git clone ...
compose_with:
  - url: /pipe/
    name: uFawkesPipe
    description: Short description
---
```

### Blog posts

```yaml
---
layout: post
title: "Post title"
date: YYYY-MM-DD
permalink: /blog/slug/
excerpt: "One-sentence excerpt."
---
```

### Learn guides (.html extension, not .md)

```yaml
---
layout: default
title: "Guide Title"
description: "Guide-specific meta description"
read_time: 5
next_guide_url: /learn/next-guide.html
next_guide_title: Next Guide Title
---
```

### Front matter safety rules

- **Preserve ALL existing keys** on any page you edit
- Only add new keys — never remove unless explicitly instructed AND verified unused
- `description` must be page-specific — never the global tagline

## URL patterns

| Page type      | Pattern                                     | Example                   |
| -------------- | ------------------------------------------- | ------------------------- |
| Stack pages    | trailing slash                              | `/obs/`                   |
| Learn guides   | `.html` extension                           | `/learn/dora-primer.html` |
| Blog posts     | trailing slash                              | `/blog/slug/`             |
| External links | `rel="noopener noreferrer" target="_blank"` |                           |

## Internal links

- In Liquid templates/includes: use `{{ '/obs/' | relative_url }}`
- In markdown content: use plain absolute paths `/obs/`
- Never mix these — pick the right one for the context

## Commit format

```
fix(scope): description (#issue-number)
```

Valid scopes: `index` `obs` `pipe` `dora` `sec` `devx` `learn` `css` `nav` `includes` `agents` `skills` `infra`

One logical change per commit. Never bundle unrelated files.

## Repo structure

```
uFawkes.dev/
├── AGENTS.md
├── _config.yml
├── _data/navigation.yml
├── _data/maintainer.yml
├── _includes/header.html
├── _layouts/{default,home,post,stack}.html
├── _posts/
├── assets/css/main.css      ← ALL styles, append-only
├── assets/js/nav.js
├── blog/index.md
├── {obs,pipe,dora,sec,devx}/index.md
├── learn/{index.md,dora-primer.html,ai-capabilities.html,observability-primer.html}
├── index.md
├── CNAME
├── Gemfile
└── Makefile
```
