---
name: visual-design
description: Visual design rules for uFawkes.dev — hierarchy, spacing rhythm, typography scale, color usage, and interaction patterns. All expressed in vanilla CSS/BEM constraints.
license: MIT
compatibility: opencode
---

# Visual Design — uFawkes.dev

## Design philosophy

uFawkes.dev is a **developer-facing platform site**. Visual decisions must serve comprehension and trust, not decoration. Every visual choice should answer: does this help a builder evaluate the stack faster?

Principles:

1. **Signal over noise** — remove everything that doesn't help the visitor decide
2. **Generous whitespace** — breathing room signals confidence
3. **Contrast hierarchy** — the most important thing on each page must be obviously most important
4. **Honest aesthetics** — no marketing gloss; clinical precision builds developer trust

## Typography scale

Use px values directly (no rem, no CSS variables yet):

| Level       | Size | Weight | Color     | Usage                          |
| ----------- | ---- | ------ | --------- | ------------------------------ |
| H1          | 36px | 700    | `#111827` | Page title — one per page      |
| H2          | 24px | 600    | `#111827` | Section headings               |
| H3          | 18px | 600    | `#111827` | Card headers, subsections      |
| Body        | 16px | 400    | `#374151` | Paragraph text                 |
| Small       | 14px | 400    | `#6b7280` | Metadata, captions, badges     |
| Code        | 14px | 400    | `#111827` | Monospace — system-ui fallback |
| Line height | —    | —      | 1.6       | All body text                  |

Mobile (≤640px): reduce H1 to 28px, H2 to 20px.

## Spacing rhythm

All spacing in multiples of 8px:

| Token   | Value | Usage                                            |
| ------- | ----- | ------------------------------------------------ |
| space-1 | 8px   | Tight — between related elements                 |
| space-2 | 16px  | Standard — card padding (mobile), between items  |
| space-3 | 24px  | Card padding (desktop), section internal spacing |
| space-4 | 32px  | Between major sections                           |
| space-6 | 48px  | Hero padding, major section breaks               |
| space-8 | 64px  | Page-level vertical rhythm                       |

## Color usage rules

```
Canonical palette: DESIGN.md and design/tokens.json (check: make design-check).
Rule: orange says who we are (and fills the primary button), indigo says you can act, green/red/amber say state.

#4f46e5  — Indigo 600, interaction colour
  Use: links, focus rings, secondary buttons, hover borders on cards, selected items
  White label on it: 6.29:1 (AA pass). Hover: #4338ca

#f06300  — Flame 500, brand/identity colour
  Use: marks, favicon, hero accent borders, bullets, large graphics only
  Never for text or button labels: 3.24:1 on white (graphics floor is 3:1)
  Orange text on white: use Ember #c2410c (5.18:1)

#15803d  — green 700, pass / live status only
  Use: live and pass badges (on #dcfce7, 4.57:1), always with a word or symbol
  Retired: #16a34a as an accent. It is 3.30:1 on white and fails for text

#111827  — text primary
  Use: H1, H2, H3, strong emphasis

#374151  — text secondary
  Use: body paragraphs, card descriptions

#6b7280  — text muted
  Use: metadata, dates, read time, repo name labels

#e5e7eb  — border default
  Use: card borders, dividers, horizontal rules

#f9fafb  — bg subtle
  Use: section backgrounds (alternating), code block backgrounds

#ffffff  — bg default
  Use: page background, card backgrounds
```

**Never**: use color as the only differentiator. Always pair color with shape, text, or icon.

## Component visual rules

### Cards (stack cards, learn cards)

```
background:    #ffffff
border:        1px solid #e5e7eb
border-radius: 8px
padding:       24px (desktop), 16px (mobile)
hover:         border-color #4f46e5, box-shadow 0 2px 8px rgba(79,70,229,0.12)
transition:    border-color 150ms ease, box-shadow 150ms ease
```

### Primary CTA buttons

```
background:    #f06300 (Flame 500)
color:         #061723 (Night), 5.62:1
padding:       12px 24px
border-radius: 6px
font-size:     16px
font-weight:   600
border:        none
hover:         background #e85800 on light (label 5.05:1), #fc8200 on dark
secondary:     transparent, 2px solid #4f46e5, label #4f46e5 (it also has .cta-button, so exclude it with :not(.cta-button--secondary))
focus:         outline 2px solid #4f46e5, outline-offset 2px
visited:       keep the label colour (a generic a:visited rule outranks a plain class)
```

### Code blocks / quick start commands

```
background:    #f9fafb
border:        1px solid #e5e7eb
border-left:   3px solid #f06300
border-radius: 4px
padding:       16px
font-family:   ui-monospace, 'Cascadia Code', monospace
font-size:     14px
color:         #111827
overflow-x:    auto
```

### Live / status badges

```
background:    #dcfce7
color:         #15803d
border-radius: 12px
padding:       2px 10px
font-size:     12px
font-weight:   600
```

## Layout grid

### Homepage stack family

```css
.stack-family__grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px;
}
@media (max-width: 767px) {
  .stack-family__grid {
    grid-template-columns: 1fr;
  }
}
```

### Hero section

```
max-width:  720px
margin:     0 auto
text-align: center
padding:    64px 24px 48px
```

### Content sections

```
max-width:  960px
margin:     0 auto
padding:    48px 24px
```

## Interaction patterns

### Hover states

- Duration: 150ms ease (not faster — feels jittery; not slower — feels sluggish)
- Only border-color, box-shadow, background-color — never layout properties
- Always pair with `prefers-reduced-motion` override (see accessibility-workflow skill)

### Focus rings

- 2px solid `#4f46e5` on light, `#a5b4fc` on dark, outline-offset 2px
- Never remove focus rings — only style them

### Transitions to avoid

- Transform on cards (causes layout thrash on low-end hardware)
- Opacity transitions on large blocks
- Color transitions on text (readability flash)
