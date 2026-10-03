---
name: design-system-workflow
description: Process for evolving the Fawkes Design System (FDS) — token definition, pattern library maintenance, compliance checking, and documentation. Currently in bootstrap phase.
license: MIT
compatibility: opencode
---

# Design System Workflow — Fawkes Design System (FDS)

## Current phase: Bootstrap

A first token set now exists: `DESIGN.md` and `design/tokens.json` (canonical, checked by `make design-check`). No component library exists yet. The FDS is being assembled from patterns already in `assets/css/main.css` and AGENTS.md. Design-System work is **PR 3 deferred** — do not activate without Planning agent instruction.

## Token lifecycle

1. **Identify** — UX or UI agent uses a value (e.g. `#4f46e5`) in a spec
2. **Name** — Design-System agent assigns a semantic name (`color-brand`)
3. **Document** — Add to token table in this skill
4. **Canonicalize** — Planning agent adds to AGENTS.md Section 6
5. **Enforce** — Review agent checks all new CSS against canonical values

## Pattern library lifecycle

1. **Component needed** — UX agent identifies component need
2. **Spec produced** — UI agent produces anatomy + styling spec
3. **Entry created** — Design-System agent documents in pattern library
4. **Implemented** — Build agent creates `_includes/` file and CSS
5. **Verified** — Review agent validates against spec

## Compliance checking

Before approving any CSS change, verify:

- [ ] Color values match canonical token table
- [ ] Spacing values are multiples of 8px
- [ ] BEM naming follows `.block__element--modifier`
- [ ] Breakpoints use only 767px or 640px
- [ ] No new values introduced without token documentation

## Future: CSS custom properties

When the token system is mature enough for CSS variables, the migration path is:

1. Define all tokens as custom properties in `:root {}`
2. Update `main.css` in a single PR — do not do incrementally
3. Planning agent must approve before any CSS variable is introduced

Do not introduce CSS variables before this migration is planned and approved.
