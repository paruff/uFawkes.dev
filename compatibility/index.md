---
layout: page
title: "Compatibility: stack versions"
description: Which release of each uFawkes stack is current, and which versions of the other stacks it has been verified with.
og_title: "Compatibility: stack versions"
og_description: Current release of each uFawkes stack and what it has been verified with.
og_type: website
---

Each uFawkes stack is released on its own. This page lists the current
release of every stack and which versions of the other stacks it has been
verified with. **"Standalone only"** means the stack has been tested by
itself and nothing else.

A blank or "not yet verified" entry means exactly that. Nothing on this page
is inferred.

## Current releases

| Stack                                                | Current release                                                                    | Status                         | Verified with                                 |
| ---------------------------------------------------- | ---------------------------------------------------------------------------------- | ------------------------------ | --------------------------------------------- |
| [uFawkesObs](/obs/)                                  | [v0.4.12-beta.1](https://github.com/paruff/uFawkesObs/releases/tag/v0.4.12-beta.1) | Beta, heading to v1.0.0        | Standalone only                               |
| [uFawkesPipe](/pipe/)                                | [v1.7.4-beta.1](https://github.com/paruff/uFawkesPipe/releases/tag/v1.7.4-beta.1)  | Beta, heading to v2.0.0        | Not yet verified against a uFawkesObs release |
| [uFawkesDevX](/devx/)                                | None yet                                                                           | Pre-release, heading to v0.1.0 | Not yet verified                              |
| [uFawkesDojo](https://paruff.github.io/uFawkesDojo/) | [0.1.0-alpha.1](https://github.com/paruff/uFawkesDojo/releases/tag/0.1.0-alpha.1)  | Alpha                          | Labs target a released, pinned stack version  |

## How this page is kept current

The `release` agent updates this table on each stack release. A "Verified
with" entry is added only after a real run of the two versions together, and
links to the evidence in the release notes.

See the [suite release plan](https://github.com/paruff/uFawkes.dev/blob/main/docs/ai-sdlc/suite-release/plan.md)
for the order stacks are released in.
