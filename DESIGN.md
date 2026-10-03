# DESIGN.md: Fawkes and uFawkes brand and design system

**Status:** Draft, revision 3, for owner review | **Updated:** 2026-10-03 | **Owner:** @paruff

This is the single reference for how Fawkes (the platform) and uFawkes (the
open-source stacks and their site, ufawkes.dev) look, sound and behave.
**uFawkes.dev is its canonical home.** The machine-readable version is
[`design/tokens.json`](design/tokens.json), published at
`https://ufawkes.dev/design/tokens.json`, and `make design-check` fails if any
colour pair in it drops below its contrast floor.

**How to read it.** "Today" means measured in the seven repos on 2026-10-02.
"Proposed" means a recommendation that nobody has approved yet. Every
contrast ratio was computed from the hex values (WCAG relative luminance),
not estimated.

## 1. What exists today: inventory of the seven repos

Inventory made on 2026-10-02 from a shallow clone of each repo's default branch.

| Repo        | What it ships visually                                                                                          | Colours found                                                    | Logo / favicon                                                                         |
| ----------- | --------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| uFawkes.dev | Jekyll site, hand-written CSS (`assets/css/main.css`)                                                           | Green `#16a34a` (24 occurrences), grays                          | 🔥 emoji as the favicon, no logo                                                       |
| fawkes      | MkDocs Material docs site; a React design system (`design-system/`, 30+ components, tokens in TypeScript)       | Indigo `#6366f1` primary, teal secondary, amber accent in MkDocs | The phoenix PNG; the README's logo path (`docs/images/fawkes-logo.png`) does not exist |
| uFawkesDojo | Three hand-written HTML pages (`index.html`, `lesson.html`, `onboarding.html`), served at dojo.ufawkes.dev      | Violet gradient `#667eea` (40 times) to `#764ba2` (12 times)     | None                                                                                   |
| uFawkesDevX | One hand-written API gateway docs page, "Developer Control Plane - API Gateway" (`gateway/api-docs/index.html`) | `#667eea`, `#764ba2`                                             | None                                                                                   |
| uFawkesObs  | No site. Grafana dashboards (colours found in `dashboards/platform/dora-overview.json`) and a README            | Amber `#d68b00`, orange-red `#d63902`, green `#1b7f3a` (data)    | None                                                                                   |
| uFawkesPipe | No site. README only                                                                                            | None                                                             | None                                                                                   |
| uFawkesAI   | No site. README only                                                                                            | README badge blue `#0a66c2`                                      | None                                                                                   |

### What the inventory shows

1. **Three unrelated "brand" colours.** The phoenix and the favicon are
   orange, ufawkes.dev is green, and the Fawkes design system, its docs and
   the Dojo are indigo or violet. A visitor moving between them sees three
   products.
2. **Only one repo has a real token set,** the Fawkes design system
   (`design-system/src/tokens/`), and it already uses the same neutral and
   status scales as ufawkes.dev (`#111827`, `#e5e7eb`, `#15803d`, `#b91c1c`).
   That is a strong base to converge on.
3. **Orange is already a "warning" colour in the stacks.** Obs thresholds use
   amber and orange-red, and the Fawkes design system's `warning` is amber
   (`#f59e0b`). Using the same orange family for the brand risks being read
   as a status.
4. **A real accessibility defect in the design system:** white text on its
   main primary `#6366f1` is 4.47:1, just under AA (4.5:1). Its `600` step,
   `#4f46e5`, is 6.29:1.
5. **A name collision.** `uFawkesPipe` and `uFawkesDevX` already have a
   lowercase `design.md` (engineering design documents). On macOS and Windows,
   file names are case-insensitive by default, so a root `DESIGN.md` there
   would collide with it. Other repos should link to this file instead of
   copying it.
6. **Most repos have no mark at all,** and the Fawkes README links to a logo
   that does not exist.

## 2. The phoenix and the colours measured from it

Source: `paruff/fawkes`, `docs/assets/images/fawkes-idp.png` (1024 x 1024 PNG),
read from its default branch on 2026-10-02: an orange phoenix with raised
wings on a dark navy field, with "FAWKES" in a bold geometric sans and
"INTERNAL DEVELOPER PLATFORM" in spaced capitals.

Colours sampled from a 128 px downscale, so treat them as approximate:

| Part of the image  | Value     |
| ------------------ | --------- |
| Background         | `#061723` |
| Phoenix, deep      | `#e85800` |
| Phoenix, body      | `#f06300` |
| Phoenix, highlight | `#fc8200` |

The lettering in the image is image-generated, not a named font (see D3).

## 3. Colour: two tiers

**Rule.** Orange says _who we are_ and, by owner decision D9, fills the one
primary button. Indigo says _you can act on this_: links, focus rings,
secondary buttons, selected items. Green, red and amber say _what state
something is in_. Orange and indigo are both interactive on a button, so
orange never appears as text or as a status.

| Tier        | Colours                       | Used for                                                                                | Never used for             |
| ----------- | ----------------------------- | --------------------------------------------------------------------------------------- | -------------------------- |
| Identity    | Flame, Ember, Night           | Marks, favicon, hero accents, large graphics, the phoenix, the primary button fill (D9) | Links, status, data series |
| Interaction | Indigo (Fawkes design system) | Links, focus rings, secondary buttons, selected items                                   | Decoration, status         |
| Status      | Green, red, amber, gray       | Pass, fail, warning, manual, only with a symbol and a word                              | Branding, buttons          |
| Neutral     | Gray scale                    | Text, borders, backgrounds                                                              | -                          |

### Palette (authoritative values are in `design/tokens.json`)

| Token          | Hex                   | Role                                           |
| -------------- | --------------------- | ---------------------------------------------- |
| Night          | `#061723`             | Dark background; button label on dark buttons  |
| Flame 400      | `#fc8200`             | Orange on dark                                 |
| Flame 500      | `#f06300`             | The brand orange, for marks and large graphics |
| Flame 600      | `#e85800`             | Deep orange                                    |
| Ember 700      | `#c2410c`             | Orange text on white                           |
| Ember 800      | `#9a3412`             | Orange text on tinted backgrounds              |
| Indigo 600     | `#4f46e5`             | Buttons, links, focus on light                 |
| Indigo 700     | `#4338ca`             | Button hover on light                          |
| Indigo 300/400 | `#a5b4fc` / `#818cf8` | Link and button on dark                        |
| Ink            | `#111827`             | Body text on light                             |
| Muted          | `#4b5563`             | Secondary text on light                        |
| Border         | `#e5e7eb`             | Dividers and card borders on light             |

### Key contrast figures, all computed

| Pair                                   | Ratio  | Use                                            |
| -------------------------------------- | ------ | ---------------------------------------------- |
| White on Indigo 600                    | 6.29:1 | Button label (passes AA, 4.5:1)                |
| Indigo 600 on white                    | 6.29:1 | Links; focus ring (needs only 3:1)             |
| Night on Indigo 400                    | 6.10:1 | Button label on dark                           |
| Indigo 300 on Night                    | 9.12:1 | Links and focus on dark                        |
| Ember 700 on white                     | 5.18:1 | Orange text on white                           |
| Flame 400 on Night                     | 7.22:1 | Orange on dark                                 |
| **Flame 500 on white**                 | 3.24:1 | **Graphics only. Not text, not button labels** |
| **Brand green `#16a34a` on white**     | 3.30:1 | **Fails for text. Retire as the accent**       |
| **White on `#6366f1` (design system)** | 4.47:1 | **Just under AA. Use Indigo 600**              |

Floor for everything: text 4.5:1 (3:1 for text of 24px, or 19px bold, and
up), UI shapes and focus rings 3:1. The full set of 28 checked pairs is in
`design/tokens.json` under `contrast`.

### Status colours

Status always carries a symbol and a word as well as colour.

| Status  | Light                               | Dark (on Night) |
| ------- | ----------------------------------- | --------------- |
| Pass    | `#15803d` on `#dcfce7`, "✓ PASS"    | `#4ade80` text  |
| Fail    | `#b91c1c` on `#fee2e2`, "✗ FAIL"    | `#f87171` text  |
| Warning | `#92400e` on `#fef3c7`, "! WARNING" | `#fbbf24` text  |
| Manual  | `#4b5563` on `#f3f4f6`, "… MANUAL"  | `#9ca3af` text  |

Warning is amber with a "!" and the word, so it cannot be confused with the
brand orange.

## 4. Names and marks

**Naming.**

- Write **Fawkes** for the platform and **uFawkes** for the suite of stacks
  and the site. Never "UFawkes", "ufawkes" or "U-Fawkes" in prose.
- Stacks are **uFawkesObs**, **uFawkesPipe**, **uFawkesDevX**,
  **uFawkesAI** and **uFawkesDojo**. Short forms in navigation and cards are
  Obs, Pipe, DevX, AI and Dojo.
- Repository names and commands stay lowercase in code font:
  `ufawkesobs`, `docker compose up obs`.

**Marks.**

| Mark     | Used for                                 | Source                                                                                                                                                                           |
| -------- | ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Phoenix  | Fawkes: README header, docs, social card | `fawkes-idp.png` today. A vector version is still needed (D2)                                                                                                                    |
| Flame    | uFawkes: favicon, header, stack cards    | [`design/marks/flame.svg`](design/marks/flame.svg). **Interim**: a simple drawn flame in Flame 500 and 400, made on 2026-10-02 to replace the 🔥 emoji. It is not the final mark |
| Wordmark | Next to either mark                      | "Fawkes" or "uFawkes" in the heading font, never stretched or recoloured                                                                                                         |

**Rules.**

- Clear space around a mark equals the height of the "F" in the wordmark.
- Minimum size: 16px for the flame, 48px for the phoenix. The flame was
  checked at 16, 32 and 220px on white and on Night.
- On dark, use the Flame colours on Night. On light, text in orange uses
  Ember 700.
- Don't add outlines, gradients the source does not have, shadows or
  rotation, and don't place a mark on a busy photo.

## 5. Typography

**Today.** ufawkes.dev and the Fawkes design system both use the system font
stack. The design system's tokens name "Inter" as a display font; I searched its
`src/`, `public/` and `mkdocs.yml` and found no font being loaded.

**Proposed.** System font stack for everything, so there is no web-font
download and no layout shift; the stack is in `design/tokens.json`.
Wordmarks are drawn into SVG, so the site never needs the logo typeface at
runtime.

| Role        | Size                         | Weight | Line height |
| ----------- | ---------------------------- | ------ | ----------- |
| Hero h1     | `clamp(1.6rem, 3vw, 2.4rem)` | 700    | 1.2         |
| Section h2  | 1.5rem                       | 700    | 1.3         |
| Card h3     | 1.125rem                     | 600    | 1.4         |
| Body        | 1rem                         | 400    | 1.6         |
| Small, meta | 0.875rem                     | 400    | 1.5         |
| Code        | 0.9em, monospace             | 400    | 1.5         |

## 6. Layout and spacing

- Spacing in multiples of 8px (the Fawkes design system uses a 4px base; its
  steps of 8px and up already line up).
- Content width 960px for reading and dashboards, 1100px for the header.
- Cards: white, `1px solid #e5e7eb`, 8px radius, 24px padding (16px on
  mobile). A highlighted card gets a 2px Indigo 600 border.
- Breakpoints: 767px (tablet) and 640px (mobile) only.
- Dark mode follows `prefers-color-scheme`, with Night as the page background
  and `#1f2937` for cards.

## 7. Components

| Component        | Rule                                                                                                                                                                             |
| ---------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Primary button   | Flame 500 background, Night label (5.62:1), 8px radius; hover Flame 600 on light and Flame 400 on dark. The label states the action ("Run Obs in 60 seconds", not "Get started") |
| Secondary button | Transparent, 2px Indigo 600 border, Indigo 600 label                                                                                                                             |
| Links in text    | Indigo 600, underlined, with a visible focus ring                                                                                                                                |
| Focus ring       | 2px outline, 2px offset: Indigo 600 on light, Indigo 300 on dark                                                                                                                 |
| Navigation       | Inline above 767px, menu button at or below it. The current page is marked with `aria-current` and a text change                                                                 |
| Status badge     | Symbol, word and colour pair from section 3                                                                                                                                      |
| Progress bar     | 8px track `#e5e7eb`, Indigo 600 fill, and the "3 / 9" text beside it                                                                                                             |
| Code block       | Subtle background, wraps long commands, never makes the page scroll sideways                                                                                                     |
| Tables on mobile | Scroll inside their own container or turn into a list. The page itself never scrolls sideways                                                                                    |

## 8. Voice

- Plain and specific: "3 of 9 acceptance checks pass", not "30% complete".
- Honest about uncertainty: say "estimate", "not verified", "not built yet".
- Failures are shown as facts with a link, never softened.
- Claims are made only for what is in the repo or the release.
- Calls to action name the outcome and the time: "Run Obs in 60 seconds".

## 9. Imagery

- Marks are vector. No stock photos or generic illustrations.
- Screenshots show real output, with alt text that says what the screenshot
  proves. Every image has `alt` text; decorative images use `alt=""`.
- Social card (Open Graph): Night background, the mark, the page's own title.

## 10. Accessibility floor

WCAG 2.2 AA is the minimum: contrast as above, keyboard access to every
control, one `<h1>` per page, status never shown by colour alone, no
horizontal page scroll at 390px, and `prefers-reduced-motion` respected.

## 11. UX and UI review: proposed answers to D1 to D4

This section is a design review written for an owner who is not a
designer. **It is a recommendation, not an approval.** Where something is
evidence and where it is my judgment is marked.

### The audience

Two sources in this repo describe who the site is for:

- The `ux-audit` personas: a **Builder** (senior engineer deciding whether to
  adopt a stack, high trust threshold), an **Operator** (platform engineer or
  SRE who already uses one stack and skims for commands) and a
  **Contributor** (someone deciding whether the project is alive).
- The seven DORA 2025 team archetypes in
  [`docs/research-foundation.md`](docs/research-foundation.md), which maps each
  to a starting stack. The mapping to stacks is this project's own judgment.

What the design must do for them: be scannable (Operators skip hero copy and
read commands), look trustworthy and consistent (Builders notice stub content
and inconsistency), and show activity honestly (Contributors check dates).

### What the evidence does and does not say

The research this project cites (DevEx: feedback loops, cognitive load and
flow state; SPACE; see `docs/research-foundation.md` and its linked sources)
is about developer productivity, not about brand colour. **I found no study
in those sources that shows any particular brand colour affects adoption.**
So the recommendations below rest on three things that are not colour
research:

1. **Cognitive load** (a DevEx dimension): the same action should look the
   same everywhere. This is applying the DevEx finding to design, and is my
   inference, not a result anyone measured.
2. **Legibility**: WCAG 2.2 contrast, which is a standard, not a study.
3. **No semantic collisions**: a colour should not mean two things. In ops
   tooling orange and amber already mean "warning" (seen in Obs and in the
   Fawkes design system).

### D1: Which colour is the brand?

**Recommendation: use both, with different jobs.** Orange is the identity
(marks, favicon, hero), and indigo is the action colour (buttons, links,
focus). Green is only for "pass". See section 3.

Why not one colour for everything:

- Orange as the action colour would collide with the "warning" meaning and
  fails contrast with white text (3.24:1).
- Green as the action colour collides with "success" and fails contrast
  (3.30:1). This is today's site.
- Indigo as the action colour needs the fewest changes: the Fawkes design
  system, its MkDocs site and the Dojo are already indigo or violet. Only
  ufawkes.dev has to change its buttons.

Trade-off: two accent hues instead of one. Orange stays out of controls,
which keeps it distinctive.

### D2: Who makes the vector marks?

**Recommendation: an interim now, a commissioned set later.**

- **Now:** [`design/marks/flame.svg`](design/marks/flame.svg), a simple drawn
  flame, replaces the emoji. It is a placeholder.
- **Later:** a designer redraws the phoenix and the flame as a matched pair,
  plus a wordmark. The brief: the phoenix in the PNG, one flat colour version,
  one two-tone version, legible at 16px. Tracing the PNG by software would
  give a poor result at small sizes.
- I did not price this. Treat it as a quote to get.

### D3: The logo typeface

**Resolved by the owner (2026-10-02): the phoenix image was created with
ChatGPT, about a year ago.** That changes the question.

- The lettering in an AI-generated image is drawn by the image model, not set
  in a font. There is probably no named, licensed typeface to find, so there is
  nothing to license. It also means the "FAWKES" lettering cannot be reused as
  live text, and the wordmark should be redrawn properly.
- **Recommendation:** have the final wordmark drawn from scratch in vector
  (with the phoenix and flame, see D2) and keep using the system font stack for
  the site and the design system.
- **Ownership is a separate question I cannot settle.** Whether the owner holds
  the rights to a generated image depends on the generator's terms of use and on
  copyright law, which differs by country and was still developing when I last
  looked. Please check the current terms of the service used and, if the mark
  matters commercially, take legal advice. A mark redrawn by a designer avoids
  the question.

### D4: Where does it live?

**Decided by the owner: uFawkes.dev.** In this repo that means:

- `DESIGN.md` (the guide), `design/tokens.json` (the values) and
  `design/marks/` (the marks), all published under `https://ufawkes.dev/design/`.
- The Fawkes design system keeps its TypeScript tokens for now. Later it
  should generate them from `tokens.json`, so there is only one source.
- Other repos link here from their README and `AGENTS.md` and do not copy the
  file (see the name collision in section 1).

### Decisions recorded (2026-10-02)

| #   | Decision                                                                  | Outcome                                                            |
| --- | ------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| D3  | The logo typeface                                                         | Phoenix made with ChatGPT. Redraw the wordmark; see D3 above       |
| D5  | Does the Fawkes docs site adopt these tokens?                             | **Yes** (owner). The Fawkes docs and design system will follow     |
| D6  | Link colour                                                               | Indigo 600 (resolved by D1)                                        |
| D7  | May I open small pointer PRs in the six other repos?                      | **Approved** (owner): one PR per repo, README and `AGENTS.md` only |
| D8  | Is the interim flame acceptable until a designer delivers the final mark? | **Yes** (owner), flagged as interim                                |

### Decisions recorded (2026-10-03)

| #   | Decision                                                       | Outcome                                                                                          |
| --- | -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| D9  | The primary button colour                                      | **Flame orange with a Night label** (owner, option B). Overrides the Indigo recommendation in D1 |
| D10 | Should the Fawkes design system's default primary move to 600? | **Yes** (owner). Indigo 500 is 4.47:1 on white; 600 passes. Tracked in a separate fawkes PR      |

**What D9 trades away.** D1 argued against an orange action colour because
orange and amber already mean "warning" in ops tools, and I found no study
showing a brand colour affects adoption (see above), so this is a judgment
call, not a measured one. The mitigations: the button uses a dark label (5.62:1
against the fill, 5.05:1 on hover), the fill is the brand orange rather than
the amber used for warnings, links and focus rings stay Indigo, and orange
never appears as text or as a status. If users read the button as a warning,
revisit it.

### Still open

- Nothing from the colour questions. D1's text above is kept as the record of
  the reasoning, with D9 as the outcome for buttons.

## 12. Implementing this

The site's CSS rules still apply: vanilla CSS in `assets/css/main.css`,
append-only, BEM names, hex values (no CSS variables until the token
migration). Order, one small PR each:

1. **This PR:** tokens, the interim flame, the contrast check and this guide.
2. **ufawkes.dev:** buttons, links, focus and nav to Indigo, the flame as
   favicon and header mark, green only for pass/live. `main.css` contains 24
   occurrences of the old green.
3. **Pointer PRs** in the other six repos (D7 approved).
4. **Repos with their own CSS:** Dojo and the DevX API page move from the
   violet gradient to the tokens; the Fawkes design system adopts the
   corrected primary and generates its tokens from `tokens.json`.
5. **Open Graph card and the final marks** (D2).

## 13. Provenance

- Inventory: shallow clones of the default branch of each repo, 2026-10-02.
  File and colour counts come from searching those clones, so they cover
  tracked files only and may miss colours produced at runtime.
- Phoenix image: `paruff/fawkes`, `docs/assets/images/fawkes-idp.png`. Created
  with ChatGPT about a year before 2026-10-02, per the owner. I did not
  establish the exact date or which version of the generator.
- Indigo, neutral and status scales: the Fawkes design system,
  `design-system/src/tokens/colors.ts` (indigo `50` to `900`), and this
  site's existing `main.css`.
- The flame in `design/marks/flame.svg` was drawn for this PR and has no
  other source.
