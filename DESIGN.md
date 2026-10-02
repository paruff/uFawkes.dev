# DESIGN.md: Fawkes and uFawkes brand and design system

**Status:** Draft, for owner review | **Created:** 2026-10-02 | **Owner:** @paruff

This is the single reference for how Fawkes (the platform) and uFawkes (the
open-source stacks and their site, ufawkes.dev) look, sound and behave. It
records what exists today, proposes a consistent direction, and lists the
decisions only the owner can make. Nothing here changes the site by itself.

**How to read it.** "Today" means measured in this repo or in
`paruff/fawkes` on 2026-10-02. "Proposed" means a recommendation. Every
contrast ratio below was computed from the hex values (WCAG 2.x relative
luminance), not estimated.

## 1. What exists today

| Asset                                                | Where                                                                  | Notes                                                                                                                                                   |
| ---------------------------------------------------- | ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Fawkes phoenix, "Fawkes Internal Developer Platform" | `paruff/fawkes`, `docs/assets/images/fawkes-idp.png` (1024 x 1024 PNG) | An orange phoenix with raised wings on a dark navy field. "FAWKES" in a bold geometric sans, and "INTERNAL DEVELOPER PLATFORM" in spaced capitals below |
| uFawkes flame favicon                                | `_layouts/default.html`, an inline SVG that draws the 🔥 emoji         | Renders differently on every OS, because it is a font glyph and not a drawn shape                                                                       |
| Brand green `#16a34a`                                | `assets/css/main.css` (24 occurrences), `CLAUDE.md` section 6          | Used for buttons, accents and links. Fails text contrast on white (3.30:1)                                                                              |
| Neutrals                                             | `assets/css/main.css`                                                  | `#111827` text, `#e5e7eb` borders, `#f9fafb` subtle backgrounds                                                                                         |

**The tension to resolve.** The two products share a flame identity (the
phoenix and the 🔥 favicon are both orange) but the site's accent colour is
green. A visitor who clicks from the phoenix to ufawkes.dev meets a
different brand colour. Section 3 proposes making orange the brand and
keeping green only for "passing / live".

### Colours measured from the phoenix image

Sampled from `fawkes-idp.png` on 2026-10-02 (nearest 8-bit bucket):

| Part of the image   | Value     |
| ------------------- | --------- |
| Background (corner) | `#061723` |
| Phoenix, deep       | `#e85800` |
| Phoenix, body       | `#f06300` |
| Phoenix, highlight  | `#fc8200` |

The typeface in the image looks like a geometric sans in a bold weight. I
could not identify it with certainty. See decision D3.

## 2. Names and marks

**Naming.**

- Write **Fawkes** for the platform and **uFawkes** for the suite of stacks
  and the site. Never "UFawkes", "ufawkes" or "U-Fawkes" in prose.
- Stacks are **uFawkesObs**, **uFawkesPipe**, **uFawkesDevX**,
  **uFawkesAI** and **uFawkesDojo**. Short forms in navigation and cards are
  Obs, Pipe, DevX, AI and Dojo.
- Repository names and commands stay lowercase in code font:
  `ufawkesobs`, `docker compose up obs`.

**Marks (proposed).**

| Mark     | Used for                                   | Source                                                                   |
| -------- | ------------------------------------------ | ------------------------------------------------------------------------ |
| Phoenix  | Fawkes: README header, docs, social card   | `fawkes-idp.png` today; a vector (SVG) version is needed, see D2         |
| Flame    | uFawkes: favicon, site header, stack cards | A drawn flame derived from the phoenix's crest and tail, in Flame orange |
| Wordmark | Both, set next to the mark                 | "Fawkes" or "uFawkes" in the heading font, never stretched or recoloured |

**Rules.**

- Clear space around a mark equals the height of the "F" in the wordmark.
- Minimum size: 16px for the flame (favicon), 48px for the phoenix.
- On dark, use the Flame colours on Night. On light, use the Ember colour
  (section 3), because Flame orange alone does not reach 4.5:1 on white.
- Don't add outlines, gradients that the source does not have, shadows or
  rotation. Don't place a mark on a busy photo.
- The 🔥 emoji is a placeholder. Replace it with the drawn flame once D2 is
  settled.

## 3. Colour

### Proposed palette

| Token       | Hex       | Role                                                    |
| ----------- | --------- | ------------------------------------------------------- |
| Night       | `#061723` | Dark backgrounds, text on Flame buttons                 |
| Flame 400   | `#fc8200` | Highlights and accents on dark                          |
| Flame 500   | `#f06300` | The brand colour: buttons, marks, large accents         |
| Flame 600   | `#e85800` | Pressed state, deep parts of the mark                   |
| Ember 700   | `#c2410c` | Orange text and links on white; white text on it passes |
| Ember 800   | `#9a3412` | Orange text on tinted backgrounds                       |
| Ink         | `#111827` | Body text on light                                      |
| Muted       | `#4b5563` | Secondary text on light                                 |
| Border      | `#e5e7eb` | Dividers and card borders on light                      |
| Subtle      | `#f9fafb` | Section backgrounds on light                            |
| Link        | `#1d4ed8` | Links in body text, underlined                          |
| Pass / Fail | see below | Status only. Never decoration                           |

### Contrast, computed

| Foreground on background | Ratio   | Use it for                                                  |
| ------------------------ | ------- | ----------------------------------------------------------- |
| Night on Flame 500       | 5.62:1  | Button label on a Flame button (passes AA, 4.5:1)           |
| Flame 500 on Night       | 5.62:1  | Orange text or icons on dark                                |
| Flame 400 on Night       | 7.22:1  | Orange text on dark (passes AAA)                            |
| Ember 700 on white       | 5.18:1  | Orange text and links on white                              |
| White on Ember 700       | 5.18:1  | A white-label button, if a darker button is wanted          |
| Ink on white             | 17.74:1 | Body text                                                   |
| Muted on white           | 7.56:1  | Secondary text                                              |
| Link on white            | 6.70:1  | Links                                                       |
| **Flame 500 on white**   | 3.24:1  | **Large text, icons and borders only. Fails for body text** |
| **White on Flame 500**   | 3.24:1  | **Do not use for button labels**                            |
| **Brand green on white** | 3.30:1  | **`#16a34a` fails for text. See decision D1**               |

Floor for everything: text 4.5:1 (3:1 for text 24px or bold 19px and up),
UI shapes and focus rings 3:1.

### Status colours

Status always carries a symbol and a word as well as colour.

| Status | Light                              | Ratio  | Dark (on Night) | Ratio   |
| ------ | ---------------------------------- | ------ | --------------- | ------- |
| Pass   | `#15803d` on `#dcfce7`, "✓ PASS"   | 4.57:1 | `#4ade80` text  | 10.44:1 |
| Fail   | `#b91c1c` on `#fee2e2`, "✗ FAIL"   | 5.30:1 | `#f87171` text  | 6.58:1  |
| Manual | `#4b5563` on `#f3f4f6`, "… MANUAL" | 6.87:1 | `#9ca3af` text  | 7.16:1  |

`#15803d` alone on Night is only 3.63:1, so dark mode uses the lighter green.

### Focus

A 2px outline, offset 2px. Ember 700 on light backgrounds (5.18:1) and
Flame 400 on dark (7.22:1).

## 4. Typography

**Today.** The site uses the minima system font stack. The phoenix image
uses a bold geometric sans that I could not identify.

**Proposed.**

- **Body and UI:** keep the system font stack. No web-font download, so no
  layout shift, no third-party request and nothing to host.
- **Wordmarks and the tagline in marks:** drawn into the SVG, so the site
  never needs the logo typeface at runtime.
- **Headings:** the same system stack at weight 700. This keeps the site
  fast and close to the Jekyll/vanilla-CSS constraint.
- **Tagline style, as in the image:** capitals, wide letter-spacing,
  weight 500. Use it sparingly, for one line under a mark.

| Role        | Size                                    | Weight | Line height |
| ----------- | --------------------------------------- | ------ | ----------- |
| Hero h1     | `clamp(1.6rem, 3vw, 2.4rem)` (existing) | 700    | 1.2         |
| Section h2  | 1.5rem                                  | 700    | 1.3         |
| Card h3     | 1.125rem                                | 600    | 1.4         |
| Body        | 1rem                                    | 400    | 1.6         |
| Small, meta | 0.875rem                                | 400    | 1.5         |
| Code        | 0.9em, monospace                        | 400    | 1.5         |

## 5. Layout and spacing

- Spacing in multiples of 8px.
- Content width 960px for reading and dashboards, 1100px for the header.
- Cards: white, `1px solid #e5e7eb`, 8px radius, 24px padding (16px on
  mobile). A highlighted card gets a 2px Flame 500 border.
- Breakpoints: 767px (tablet) and 640px (mobile) only.
- Dark mode follows `prefers-color-scheme` with Night as the page
  background and `#1f2937` for cards.

## 6. Components

| Component        | Rule                                                                                                                        |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Primary button   | Flame 500 background, Night label, 8px radius, label states the action ("Run Obs in 60 seconds", not "Get started")         |
| Secondary button | Transparent, 2px Ember 700 border, Ember 700 label                                                                          |
| Links in text    | Link colour, underlined, visible focus ring                                                                                 |
| Navigation       | Inline on screens above 767px, menu button at or below it. The current page is marked with `aria-current` and a text change |
| Status badge     | Symbol + word + colour pair from section 3                                                                                  |
| Progress bar     | 8px track `#e5e7eb`, Flame 500 fill (a graphic: 3:1 is enough), and the "3 / 9" text beside it                              |
| Code block       | Subtle background, wraps long commands, never makes the page scroll sideways                                                |
| Tables on mobile | Scroll inside their own container or turn into a list. The page itself never scrolls sideways                               |

## 7. Voice

- Plain and specific: "3 of 9 acceptance checks pass", not "30% complete".
- Honest about uncertainty: say "estimate", say "not verified", say "not
  built yet".
- Failures are shown as facts with a link, never softened.
- Claims are only made for what is in the repo or the release. If a feature
  is planned, say planned.
- Calls to action name the outcome and the time: "Run Obs in 60 seconds".

## 8. Imagery

- Marks are vector. No stock photos or generic illustrations.
- Screenshots show real output, with alt text that says what the screenshot
  proves.
- Every image has `alt` text. Decorative images use `alt=""`.
- Social card (Open Graph): Night background, phoenix or flame mark, the
  page's own title. To be made once D2 is settled.

## 9. Accessibility floor

WCAG 2.2 AA is the minimum: contrast as above, keyboard access to every
control, one `<h1>` per page, status never shown by colour alone, no
horizontal page scroll at 390px, and `prefers-reduced-motion` respected.

## 10. Implementing this (not done yet)

The site's CSS rules still apply: vanilla CSS in `assets/css/main.css`,
append-only, BEM names, hex values (no CSS variables until the token
migration). Proposed order, one small PR each:

1. Add the drawn flame as an SVG favicon and header mark (needs D2).
2. Move the brand accent from `#16a34a` to Flame 500 / Ember 700 for buttons,
   links and focus rings. `main.css` contains 24 occurrences of the green.
3. Keep green only for pass/live badges, with the dark-mode variants above.
4. Add the Open Graph card.
5. Mirror the palette and marks in `paruff/fawkes` docs and README.

## 11. Decisions for the owner

| #   | Decision                                                                                            | Recommendation                                                  |
| --- | --------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| D1  | Is orange (Flame) the brand colour, with green reserved for pass/live, or does the site keep green? | Orange. It matches the phoenix and the favicon the owner likes  |
| D2  | Who produces the vector phoenix and flame? The PNG is 1024 px and cannot be recoloured cleanly      | Trace or redraw as SVG, derived from the PNG, kept in one place |
| D3  | What is the logo typeface, and is it licensed for use? I could not identify it                      | Confirm with whoever made the image; keep it out of runtime CSS |
| D4  | Where does the master asset live: `paruff/fawkes`, `uFawkes.dev`, or a small shared repo?           | One source repo; the others link or copy at build time          |
| D5  | Does the Fawkes docs site adopt the same tokens?                                                    | Yes, so the two feel like one family                            |
| D6  | Link colour: keep blue `#1d4ed8`, or move links to Ember 700?                                       | Keep blue. It reads as "link" and keeps orange for actions      |

## 12. Provenance

- Phoenix image: `paruff/fawkes`, `docs/assets/images/fawkes-idp.png`, read
  from the `main` branch on 2026-10-02. I did not establish when the image
  was created or last changed (the checkout was shallow). Colours were
  sampled from a 128 px downscale, so treat the hex values as approximate
  until the vector source exists.
- The current site palette is from `assets/css/main.css` and `CLAUDE.md`
  section 6. Status colours and their ratios are from
  `docs/ai-sdlc/suite-status/spec.md`.
