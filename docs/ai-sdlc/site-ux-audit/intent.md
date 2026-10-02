# Intent: Site UX audit fixes

**Owner:** @paruff | **Created:** 2026-10-02 | **Status:** Draft

## Problem

A UX audit of the merged `main` build on 2026-10-02 (local build; the audit
environment could not reach ufawkes.dev) found defects that cost visitors
trust or block them:

- Above 767px the navigation was hidden behind a hamburger button, so desktop
  visitors saw no links.
- `/obs/`, `/pipe/`, `/devx/` and `/compatibility/` scrolled sideways at 390px.
- The home page had two `<h1>` elements, one of them empty.
- The active-page and Dojo nav links failed WCAG AA contrast (3.15:1).
- The blog had the global tagline as its meta description, and two page titles
  lost their separator.
- The suite status page linked to a JSON file that only existed after a
  deploy, and a broken status check blocked every site deploy.

## Desired outcome

Each defect above is fixed with the smallest change that removes it, without
adding dependencies or changing the stack.

## Out of scope

- The primary button colour (white on `#16a34a` is 3.30:1). A brand decision
  for the owner.
- The "four DORA metrics" wording in `/learn/dora-primer.html`. A content
  decision for the owner.
- The live site, the Tally form and screen-reader behaviour were not tested.
