# Agent reference — roster, structure, conventions, URLs

Moved out of `AGENTS.md` (#98) so the always-loaded policy stays short.
`AGENTS.md` keeps the stack, hard rules and commit format; everything below is
look-up material to read when a task needs it.

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
