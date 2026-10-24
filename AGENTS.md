# uFawkes.dev — Universal Agentic Handoff Prompt

> Always-loaded policy for every agentic tool (Claude Code, OpenCode, Copilot,
> Gemini, Cursor). Look-up material — agent roster, repo structure, front
> matter, navigation, launch commands, URLs, status — lives in
> [`docs/agent-reference.md`](docs/agent-reference.md).

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
JS        : Vanilla JS only — assets/js/status.js — NO npm/webpack/bundler
Templating: Liquid (Jekyll-flavored) — whitelisted filters only
Deployment: GitHub Pages from main root — no build step needed locally
Commands  : make serve  →  bundle exec jekyll serve --livereload
            make build  →  bundle exec jekyll build
```

**Never introduce:** npm, webpack, Vite, Tailwind, SCSS, CSS custom properties,
React, Astro, Vue, Jekyll plugins not on the GitHub Pages whitelist, or any
server-side logic.

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
- Brand: Flame `#f06300` (identity, marks) | Primary button: Flame fill `#f06300` with a Night `#061723` label | Links, focus, secondary button: Indigo `#4f46e5` | Pass/live: green `#15803d` | Text primary: `#111827` | Border: `#e5e7eb` | Bg subtle: `#f9fafb`. Full palette, contrast floors and rules: `DESIGN.md` and `design/tokens.json`. `#16a34a` fails text contrast (3.3:1); don't use it for text or buttons
- Spacing: multiples of 8px
- No CSS variables — hex values directly until design-system token migration

---

## 8. Workflow: board, gates, review

- UI changes: read DESIGN.md first (tokens, components, do and don't)
- Reviewing a PR: apply REVIEW.md (what is Important, verification, validation, security)

Status lives only on [Project #7](https://github.com/users/paruff/projects/7):
no status labels, no ✅ in plans. Routing labels say who does the work, not its
state. Work traces to `docs/ai-sdlc/<feature>/` intent → spec → plan; plans link
issues, never list tasks. Statuses, Gate, lifecycle and owner decisions:
[the board rules](https://github.com/paruff/uFawkes.dev/blob/main/docs/ai-sdlc/suite-release/plan.md#the-board-statuses-gates-and-moves).

```bash
# 1. Next item for an agent (label: the routing label you run as, claude-code or opencode)
gh project item-list 7 --owner paruff --limit 300 --query 'status:"Ready for agent" is:open label:opencode' \
  --format json --jq '.items | sort_by(.priority // "P9", .content.number) | .[:1][] | "\(.content.repository)#\(.content.number) \(.title)"'
# 2. Waiting on a human, and which gate each waits on
gh project item-list 7 --owner paruff --limit 300 --query 'status:"Needs human" is:open' \
  --format json --jq '.items[] | "\(.gate // "-")\t\(.content.repository)#\(.content.number) \(.title)"'
# Move: "In Progress" before you start; "Needs human" plus Gate "PR review" when the PR is up
gh project item-edit 7 --owner paruff --url <issue url> --field Status --value "In Progress"
```

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

The standard, what each repo has today, and how to close the gaps:
[`docs/ai-sdlc/suite-hygiene/main-protection.md`](docs/ai-sdlc/suite-hygiene/main-protection.md).
In short: one `main-protection` ruleset per repo with a pull request, no force
pushes or deletion, linear history, and the hook job plus `Artifact Chain` as
required checks. Ruleset changes are the owner's; an agent never bypasses them.

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

---

## Where to look

- Agent roster, skills, MCP servers, workflow: `docs/agent-reference.md` §2b
- Repo structure, front matter, navigation, launch commands, URLs: `docs/agent-reference.md`
- Suite status (machine-readable, refreshed daily): https://ufawkes.dev/status/suite_status.json
- Suite release plan: `docs/ai-sdlc/suite-release/`
