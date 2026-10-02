# uFawkes.dev — Universal Agentic Handoff Prompt

> Paste this entire document at the start of any new session with Claude Code,
> OpenCode, GitHub Copilot Coding Agent, Gemini CLI, Cursor, or any other
> agentic coding tool. It gives the agent complete, verified context to
> continue work without re-reading the whole repo.

---

## 1. Project identity

| Key          | Value                                                                                        |
| ------------ | -------------------------------------------------------------------------------------------- |
| Site         | https://ufawkes.dev                                                                          |
| Repo         | https://github.com/paruff/uFawkes.dev                                                        |
| Branch model | `main` is prod — every merge auto-deploys via GitHub Pages                                   |
| Maintainer   | @paruff (Phil Ruff)                                                                          |
| Purpose      | Public marketing + education site for the uFawkes open-source platform engineering ecosystem |

---

## 2. Tech stack (hard constraints — do not deviate)

```
Generator : Jekyll 4.4.1 (GitHub Pages whitelist)
Theme     : minima (overridden via _layouts/, _includes/)
Plugins   : jekyll-feed only — NO others
CSS       : Vanilla CSS in assets/css/main.css (BEM naming, append-only)
JS        : Vanilla JS only — assets/js/nav.js — NO npm/webpack/bundler
Templating: Liquid (Jekyll-flavored) — whitelisted filters only
Deployment: GitHub Pages from main root — no build step needed locally
Commands  : make serve  →  bundle exec jekyll serve --livereload
            make build  →  bundle exec jekyll build
```

**Never introduce:** npm, webpack, Vite, Tailwind, SCSS, CSS custom properties,
React, Astro, Vue, Jekyll plugins not on the GitHub Pages whitelist, or any
server-side logic.

---

## 2b. Agent roster & tool configuration

### Architecture decision

Custom agents and reusable skills live at `~/.config/opencode/` (global),
not in this repo. This makes them reusable across all uFawkes repos
(ufawkesobs, ufawkespipe, etc.). Only project-specific permission overrides
and MCP config live in `.opencode/opencode.json`.

Run `./consolidate-agents.sh --dry-run` to preview the migration.
Run `./consolidate-agents.sh` to execute it.

### Primary agents (Tab to switch in OpenCode)

| Agent            | Mode    | Purpose                           |
| ---------------- | ------- | --------------------------------- |
| build (built-in) | primary | Default — full file + bash access |
| plan (built-in)  | primary | Analysis only — no edits          |

### Custom subagents (@ mention)

| Agent         | File                                         | Purpose                                                   | Key permissions                      |
| ------------- | -------------------------------------------- | --------------------------------------------------------- | ------------------------------------ |
| ux            | `~/.config/opencode/agents/ux.md`            | Audit live pages, define IA, wireframes, content strategy | webfetch: allow, edit: deny          |
| ui            | `~/.config/opencode/agents/ui.md`            | Visual specs — typography, layout, component styling      | read: allow, edit: deny              |
| design-system | `~/.config/opencode/agents/design-system.md` | Token definitions, pattern library, DS compliance         | read: allow, edit: deny              |
| planning      | `~/.config/opencode/agents/planning.md`      | Prioritize issues, update `.opencode/plans/plan.md`       | edit: `.opencode/plans/plan.md` only |
| review        | `~/.config/opencode/agents/review.md`        | Validate builds — read-only, no edits                     | bash: make build only                |
| build         | built-in                                     | Default — full file + bash access                         | all tools enabled                    |
| build-pages   | `~/.config/opencode/agents/build-pages.md`   | Implement Jekyll/CSS/Liquid changes — one file per task   | edit: allow, bash: make build        |
| infra         | `~/.config/opencode/agents/infra.md`         | GitHub Pages, \_config.yml, Gemfile, opencode.json        | bash: allow                          |

### Skills (auto-discovered — no linking required)

Skills live at `~/.config/opencode/skills/`. Agents load them on demand.
Permission overrides in `.opencode/opencode.json` (tailwind-tokens: deny, astro-components: deny).

| Skill                      | Used by           | Purpose                                                                          |
| -------------------------- | ----------------- | -------------------------------------------------------------------------------- |
| `jekyll-site-conventions`  | ALL agents        | Hard constraints: stack, plugins, CSS rules, Liquid safety, commit format        |
| `ux-audit`                 | ux, planning      | Audit protocol: what to check, severity ranking (P0–P3), output format           |
| `accessibility-workflow`   | ux, ui, review    | Three-phase: audit → remediate → verify. WCAG AA rules + CSS patterns            |
| `visual-design`            | ui, design-system | Typography scale, spacing rhythm, color tokens, component visual rules           |
| `component-workflow`       | ui, build         | Component anatomy → spec → Jekyll/Liquid integration patterns                    |
| `responsive-layout`        | ui, build         | Canonical breakpoints (767px/640px), grid patterns, touch targets                |
| `design-system-workflow`   | design-system     | Token lifecycle, pattern library, compliance checking. PR 3 deferred             |
| `content-strategy`         | ux, planning      | Narrative framework (Why→What→How→Proof→Next), tone, CTA copy, trust signals     |
| `cross-agent-coordination` | planning, all     | Handoff protocol, dependency sequencing, parallel task rules                     |
| `planning-workflow`        | planning          | P0–P3 prioritization, sprint sequencing, success criteria                        |
| `code-quality`             | review, build     | Liquid/HTML/CSS linting rules, build quality gates                               |
| `issue-format`             | planning          | Section 8 table format, Section 12 handoff, GitHub issue template, commit format |

### Consolidated from 29 → 12 skills

The original 29 skills were too granular and two conflicted with the Jekyll stack.
See `.opencode-skill-audit.log` after running `consolidate-agents.sh` for the
full old→new mapping.

Deleted: `tailwind-tokens` (contradicts vanilla CSS), `astro-components`
(contradicts Jekyll).

### MCP servers (configured in `.opencode/opencode.json`)

| Server         | URL                                     | Purpose                                    |
| -------------- | --------------------------------------- | ------------------------------------------ |
| GitHub MCP     | `https://api.githubcopilot.com/mcp/`    | Planning agent reads/creates GitHub issues |
| Playwright MCP | `npx @playwright/mcp@latest --headless` | UX agent takes screenshots of live site    |

### Recommended workflow per issue

```
1. @ux        → audit relevant live page → ranked findings (P0–P3)
2. plan       → read findings → propose exact file + line changes
3. @review    → confirm no constraint violations before edit
4. build      → implement ONE file → run make build → report
5. @review    → approve or block with exact finding
6. build      → commit: fix(scope): description (#N)
7. @planning  → mark ✅ in `.opencode/plans/plan.md`, update Handoff
```

---

## 3. Repo structure (canonical)

```
uFawkes.dev/
├── AGENTS.md                    ← this file
├── consolidate-agents.sh        ← migration script
├── .opencode/
│   ├── opencode.json            ← permissions + MCP config (project-specific)
│   └── plans/plan.md            ← issue tracker and handoff state
├── _config.yml
├── _data/
│   ├── navigation.yml
│   └── maintainer.yml
├── _includes/
│   ├── header.html
│   └── guide-meta.html          ← planned (issue #7)
├── _layouts/
│   ├── default.html
│   ├── home.html
│   ├── post.html
│   └── stack.html
├── _posts/
│   └── 2026-05-11-why-im-building-*.md
├── assets/
│   ├── css/main.css             ← ALL styles — single file, append-only
│   └── js/nav.js
├── blog/index.md
├── {obs,pipe,dora,sec,devx}/index.md
├── learn/
│   ├── index.md
│   ├── dora-primer.html
│   ├── ai-capabilities.html
│   └── observability-primer.html
├── docs/
│   └── PR_STANDARD.md            ← Conventional Commits rules, PR standards
├── index.md
├── CNAME                        ← ufawkes.dev
├── Gemfile
└── Makefile

Global (not in this repo):
~/.config/opencode/
├── agents/
│   ├── ux.md
│   ├── ui.md
│   ├── design-system.md
│   ├── planning.md
│   ├── review.md
│   ├── build-pages.md
│   └── infra.md
└── skills/
    ├── jekyll-site-conventions/SKILL.md
    ├── ux-audit/SKILL.md
    ├── accessibility-workflow/SKILL.md
    ├── visual-design/SKILL.md
    ├── component-workflow/SKILL.md
    ├── responsive-layout/SKILL.md
    ├── design-system-workflow/SKILL.md
    ├── content-strategy/SKILL.md
    ├── cross-agent-coordination/SKILL.md
    ├── planning-workflow/SKILL.md
    ├── code-quality/SKILL.md
    └── issue-format/SKILL.md
```

---

## 3b. Context Files

| File                              | Why                                                        |
| --------------------------------- | ---------------------------------------------------------- |
| `docs/PR_STANDARD.md`             | Conventional Commits rules, branch naming, CI requirements |
| `docs/ci-pipeline-master-plan.md` | CI pipeline architecture and rollout plan                  |
| `docs/ci-pipeline-phase1.md`      | Phase 1 implementation details                             |
| `docs/ci-pipeline-status.md`      | Current CI pipeline status                                 |

---

## 4. Front matter conventions

### General pages

```yaml
---
layout: default
title: Page Title
description: "Page-specific meta — NOT the global tagline"
permalink: /path/
---
```

### Stack pages

```yaml
---
layout: stack
title: uFawkesObs
stack_name: Obs
hero: "Prometheus + Grafana + AI observability. 60 seconds to running."
summary: "One-line summary for cards"
coming_soon: false
repo_url: https://github.com/paruff/ufawkesobs
repo_name: ufawkesobs
screenshot_placeholder: false
features:
  - DORA dashboards wired to delivery signals
quick_start:
  - step: git clone https://github.com/paruff/ufawkesobs.git
  - step: cd ufawkesobs
  - step: docker compose up -d
compose_with:
  - url: /pipe/
    name: uFawkesPipe
    description: Add CI/CD orchestration
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

---

## 5. Liquid rules

- Internal links in templates: `{{ '/obs/' | relative_url }}`
- Internal links in markdown: plain `/obs/`
- Pages: trailing slash. Learn guides: `.html` extension
- External links: `rel="noopener noreferrer" target="_blank"`
- Allowed filters: `relative_url`, `absolute_url`, `url_encode`, `date`, `markdownify`, `strip_html`, `truncate`, `slugify`
- Never: `{% unless %}`, `{% case %}`, multi-variable assign chains
- Always verify included files exist before referencing

---

## 6. CSS conventions

- Single file: `assets/css/main.css` — **append only, never reorder**
- BEM: `.block`, `.block__element`, `.block--modifier`
- Breakpoints: `767px` (tablet), `640px` (mobile) — canonical, never invent others
- Brand: Flame `#f06300` (identity, marks) | Action: Indigo `#4f46e5` | Pass/live: green `#15803d` | Text primary: `#111827` | Border: `#e5e7eb` | Bg subtle: `#f9fafb`. Full palette, contrast floors and rules: `DESIGN.md` and `design/tokens.json`. `#16a34a` fails text contrast (3.3:1); don't use it for text or buttons
- Spacing: multiples of 8px
- No CSS variables — hex values directly until design-system token migration

---

## 7. Navigation structure

```yaml
- title: Stacks
  dropdown: true
  items:
    - title: "👁️ Obs"
      url: /obs/
    - title: "🔁 Pipe"
      url: /pipe/
    - title: "📈 DORA"
      url: /dora/
    - title: "🛡️ Sec"
      url: /sec/
    - title: "🧭 DevX"
      url: /devx/
- title: Learn
  url: /learn/
- title: Blog
  url: /blog/
- title: "🟢 Dojo"
  url: https://paruff.github.io/uFawkesDojo/
  external: true
```

---

## 8. Issue status tracker

See `.opencode/plans/plan.md` — issue tracker, priorities, and handoff state live there.
The planning agent (`@planning`) reads and updates this file.

---

## 9. Agentic working rules

### Per-task discipline

- **One file per task** — never combine edits to multiple files in one instruction
- **Verify before staging** — run `make build` after every file change
- **Exact text matching** — quote the exact string to find including whitespace
- **Await review** — Build agent proposes; Review agent approves; Build commits
- **Never swallow a build/check error** — if `make build` or any validation step fails, surface the actual error rather than catching and continuing; a silently-caught failure looks identical to a clean pass and hides real breakage

### Liquid safety

- Never add `{% unless %}`, `{% case %}`, or multi-variable assign chains
- Verify included files exist before referencing
- Run `make build` after any Liquid change; confirm output is not empty

### CSS safety

- Append only — never reorder or restructure `main.css`
- One blank line between rule blocks
- Run `make build` and visually check affected pages after appending

### Front matter safety

- Preserve ALL existing front matter keys on any page you edit
- Only add new keys — never remove unless explicitly instructed AND verified unused

### Commit format

```
fix(scope): description (#issue-number)
```

Valid scopes: `index` `obs` `pipe` `dora` `sec` `devx` `learn` `css` `nav` `includes` `agents` `skills` `infra` `docs`

---

## 10. GitOps working rules

All uFawkes repos follow GitOps methodology. **No exceptions.**

### Branch → Validate → Commit → PR

```bash
# 1. Branch
git checkout -b {type}/{scope}-{short-description}

# 2. Implement changes

# 3. Validate
make validate    # or: pre-commit run --all-files

# 4. Commit
git add {file}
git commit -m "{type}({scope}): {description}"

# 5. Push & PR
git push -u origin {branch}
gh pr create
```

### Branch naming

- `fix/css-hero-alignment`
- `feat/dora-dashboards`
- `chore/pre-commit-setup`
- `docs/update-readme`
- `ci/add-security-scanning`

### Constrained commit types

- `fix` — bug fix
- `feat` — new feature
- `chore` — maintenance, config, tooling
- `docs` — documentation only
- `style` — formatting, no code change
- `refactor` — restructuring without behavior change
- `test` — adding/fixing tests
- `ci` — CI/CD changes

### Hard rules

- **NEVER** commit directly to main
- **NEVER** skip pre-commit hooks (`--no-verify` is forbidden)
- **NEVER** force push to main
- **ALWAYS** create a PR for review (even solo — audit trail)
- **ALWAYS** run `make validate` before pushing
- ONE file per commit (except bulk config additions)

### Branch protection (via Rulesets API)

All repos require:

- PR to merge to main
- Status check `Validate` must pass
- No force pushes to main
- Linear history enforced

### Deployment Lifecycle Gates

#### Main CI guard

Every PR targeting `main` must pass `main-ci-guard.yml` before merge.
This workflow calls the reusable guard from `paruff/ufawkespipe` and enforces
branch protection policies, status checks, and merge readiness validation.

#### Observability built-in

Every CI job must include `job-start` and `job-finish` timestamp steps:

- `job-start` at the **first step** of the job
- `job-finish` at the **last step** of the job (with `if: always()`)
- Each emits ISO 8601 UTC timestamps, along with `sha`, `workflow`, and `job`
  metadata for traceability

These timestamps feed DORA metric collection and pipeline observability.

---

## 11. Agent launch commands

### OpenCode (recommended)

```bash
opencode                                    # launch TUI
Tab                                         # switch Build ↔ Plan
@ux "audit https://ufawkes.dev/obs/"        # invoke UX subagent
@planning "update plan.md"                  # invoke planning subagent
@review "check issue #6 obs/index.md"      # invoke review subagent
```

### Claude Code

```bash
claude --model claude-sonnet-4-6
# /model to switch interactively
```

### GitHub Copilot Coding Agent

Governed by `.copilotinstructions.md`. Assign GitHub issues directly from the Issues UI.

### Gemini CLI

```bash
gemini
# /read AGENTS.md then paste task
```

---

## 12. Key URLs

| Page                 | URL                                                 |
| -------------------- | --------------------------------------------------- |
| Homepage             | https://ufawkes.dev                                 |
| Obs                  | https://ufawkes.dev/obs/                            |
| Pipe                 | https://ufawkes.dev/pipe/                           |
| DORA                 | https://ufawkes.dev/dora/                           |
| Sec                  | https://ufawkes.dev/sec/                            |
| DevX                 | https://ufawkes.dev/devx/                           |
| Learn hub            | https://ufawkes.dev/learn/                          |
| DORA Primer          | https://ufawkes.dev/learn/dora-primer.html          |
| AI Capabilities      | https://ufawkes.dev/learn/ai-capabilities.html      |
| Observability Primer | https://ufawkes.dev/learn/observability-primer.html |
| Blog                 | https://ufawkes.dev/blog/                           |
| Fawkes Dojo          | https://paruff.github.io/uFawkesDojo/               |
| GitHub Sponsors      | https://github.com/sponsors/paruff                  |
| Email form (Tally)   | https://tally.so/embed/ODbbpR                       |

---

## 13. What to do next

```
[ ] Current branch: main
[ ] Last completed: PR 7 — GitOps Migration (Phases 0-2 + branch protection)
[ ] In progress: none
[ ] Blockers: none
[ ] Next task: GitOps agent (Phase 4) — create opencode GitOps agent
[ ] PR 4 plan: .opencode/plans/pr4-plan.md
[ ] Current suite status (machine-readable, refreshed daily): https://ufawkes.dev/status/suite_status.json — read it instead of re-querying Project #7
[ ] Suite release plan: docs/ai-sdlc/suite-release/ (docs/roadmap.md is retired)
[ ] GitOps plan: .opencode/plans/gitops-migration.md
```

---

_Last updated: 2026-06-06_
_Update `.opencode/plans/plan.md` before every handoff._
