---
name: accessibility-workflow
description: Three-phase accessibility workflow for uFawkes.dev — audit (find issues), remediate (fix specifications), verify (confirm compliance). Covers WCAG AA, Jekyll/HTML patterns, and vanilla CSS focus states.
license: MIT
compatibility: opencode
---

# Accessibility Workflow — uFawkes.dev

Target: **WCAG 2.1 AA** minimum. AAA where achievable without design compromise.

## Phase 1 — Audit

### What to check

**Structure**

- [ ] One `<h1>` per page (no double H1 — see issue #1 in tracker)
- [ ] Heading levels sequential: h1 → h2 → h3, no skips
- [ ] Landmark regions present: `<header>`, `<main>`, `<nav>`, `<footer>`
- [ ] Skip-to-content link at top of page

**Images**

- [ ] All `<img>` have `alt` attribute
- [ ] Decorative images have `alt=""`
- [ ] Informative images have descriptive alt text (not "image of...")
- [ ] Badge images have meaningful alt text (not raw URL)

**Links**

- [ ] No "click here" or "read more" links without context
- [ ] External links have `rel="noopener noreferrer"` and `target="_blank"`
- [ ] External links that open new tab warn users (visually or via aria-label)

**Color and contrast**

- [ ] Normal text (< 18px or < 14px bold): contrast ratio ≥ 4.5:1
- [ ] Large text (≥ 18px or ≥ 14px bold): contrast ratio ≥ 3:1
- [ ] UI components and focus indicators: ≥ 3:1
- [ ] Color is never the only means of conveying information

**Keyboard navigation**

- [ ] All interactive elements reachable by Tab key
- [ ] Focus order is logical (matches visual order)
- [ ] Focus rings visible on all interactive elements
- [ ] Dropdown nav keyboard-operable

**Forms**

- [ ] All inputs have associated `<label>` elements
- [ ] Error messages are descriptive and associated with inputs
- [ ] Required fields are marked (not color-only)

**Motion**

- [ ] Animations respect `prefers-reduced-motion`
- [ ] No content flashes more than 3 times per second

### Contrast reference (brand palette)

| Foreground                     | Background | Ratio   | Pass/Fail                              |
| ------------------------------ | ---------- | ------- | -------------------------------------- |
| `#111827` (text primary)       | `#ffffff`  | 17.74:1 | ✅ AAA                                 |
| `#374151` (text secondary)     | `#ffffff`  | 10.31:1 | ✅ AAA                                 |
| `#6b7280` (text muted)         | `#ffffff`  | 4.83:1  | ✅ AA                                  |
| `#4f46e5` (Indigo, action)     | `#ffffff`  | 6.29:1  | ✅ AA                                  |
| `#ffffff`                      | `#4f46e5`  | 6.29:1  | ✅ AA                                  |
| `#c2410c` (Ember, orange text) | `#ffffff`  | 5.18:1  | ✅ AA                                  |
| `#f06300` (Flame, brand)       | `#ffffff`  | 3.24:1  | ❌ text, ✅ graphics (3:1)             |
| `#16a34a` (old green)          | `#ffffff`  | 3.30:1  | ❌ text. Don't use for text or buttons |
| `#15803d` (green, pass)        | `#ffffff`  | 5.02:1  | ✅ AA                                  |
| `#111827`                      | `#f9fafb`  | 16.98:1 | ✅ AAA                                 |

Ratios computed from the hex values (WCAG relative luminance); an earlier
version of this table listed `#16a34a` at 4.7:1, which is wrong. The palette
and its checked pairs live in `DESIGN.md` and `design/tokens.json`; run
`make design-check` after changing a colour there.

⚠️ Always verify contrast with a tool when adding new color combinations.

## Phase 2 — Remediate

### Focus states (vanilla CSS)

Add to `assets/css/main.css` (append only):

```css
/* Global focus ring — append to end of main.css */
:focus-visible {
  outline: 2px solid #4f46e5;
  outline-offset: 2px;
}

/* Remove default outline only when :focus-visible is supported */
:focus:not(:focus-visible) {
  outline: none;
}
```

### Screen-reader-only utility

```css
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
```

Use `.sr-only` for: duplicate H1 text, icon button labels, "opens in new tab" notices.

### Double H1 fix (issue #1)

```html
<!-- Replace this in index.md: -->
# uFawkes

<!-- With this: -->
<span class="sr-only">uFawkes</span>
```

### Skip navigation

Add to `_layouts/default.html` immediately after `<body>`:

```html
<a class="skip-nav" href="#main-content">Skip to main content</a>
```

Add CSS:

```css
.skip-nav {
  position: absolute;
  left: -9999px;
  z-index: 999;
  padding: 8px 16px;
  background: #4f46e5;
  color: #ffffff;
  font-weight: 600;
}
.skip-nav:focus {
  left: 8px;
  top: 8px;
}
```

Add `id="main-content"` to `<main>` element.

### Motion reduction

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

## Phase 3 — Verify

After any accessibility-related change:

1. Run `make build` — confirm no build errors
2. Check heading structure: `grep -n "^#" [file.md]`
3. Check for alt text: `grep -n "<img" [file]` — confirm all have alt=""
4. Manually tab through affected page in browser
5. Confirm focus rings are visible on all interactive elements
6. Run contrast check on any new color combinations

### Review agent checklist (accessibility section)

- [ ] Heading hierarchy is logical
- [ ] All images have alt text
- [ ] Links are descriptive
- [ ] Focus states exist for all interactive elements
- [ ] Contrast ≥ 4.5:1 for normal text
- [ ] `prefers-reduced-motion` respected for any transitions
