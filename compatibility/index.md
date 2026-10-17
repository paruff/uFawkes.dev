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
is inferred. **Dev image** is the devcontainer image (the uFawkes CDE,
`ghcr.io/paruff/fawkes-space`) the release was built and tested in.

## Current releases

| Stack                                                | Current release                                                                     | Status                                                                        | Verified with                                                                                                         | Dev image                                                                                                 |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| [uFawkesAI](/ai/)                                    | [v2.0.0](https://github.com/paruff/uFawkesAI/releases/tag/v2.0.0)                   | Released                                                                      | uFawkesObs `main` (dfd4fc9): a delivery event reaches Loki ([evidence](https://github.com/paruff/uFawkesAI/pull/172)) | Publishes [`fawkes-space:2.0.0`](https://github.com/users/paruff/packages/container/package/fawkes-space) |
| [uFawkesObs](/obs/)                                  | [v1.0.0](https://github.com/paruff/uFawkesObs/releases/tag/v1.0.0)                  | Released                                                                      | Standalone only                                                                                                       | [`fawkes-space:2.0.0`](https://github.com/users/paruff/packages/container/package/fawkes-space)           |
| [uFawkesPipe](/pipe/)                                | [v1.16.0-beta.1](https://github.com/paruff/uFawkesPipe/releases/tag/v1.16.0-beta.1) | Beta, heading to v2.0.0                                                       | Not yet verified against a uFawkesObs release                                                                         | [`fawkes-space:2.0.0`](https://github.com/users/paruff/packages/container/package/fawkes-space)           |
| [uFawkesDevX](/devx/)                                | [v1.2.0](https://github.com/paruff/uFawkesDevX/releases/tag/v1.2.0)                 | Released, not yet verified on a clean host (heading to first verified stable) | Not yet verified                                                                                                      | [`fawkes-space:2.0.0`](https://github.com/users/paruff/packages/container/package/fawkes-space)           |
| [uFawkesDojo](https://paruff.github.io/uFawkesDojo/) | [0.2.0](https://github.com/paruff/uFawkesDojo/releases/tag/0.2.0)                   | Released                                                                      | Labs target a released, pinned stack version                                                                          | [`fawkes-space:2.0.0`](https://github.com/users/paruff/packages/container/package/fawkes-space)           |
| [fawkes](/fawkes/)                                   | [v0.3.163](https://github.com/paruff/fawkes/releases/tag/v0.3.163)                  | Pre-alpha, heading to Tracer Bullet Alpha (v0.4.0)                            | Not yet verified                                                                                                      | [`fawkes-space:2.0.0`](https://github.com/users/paruff/packages/container/package/fawkes-space)           |

## How this page is kept current

The `release` agent updates this table on each stack release. A "Verified
with" entry is added only after a real run of the two versions together, and
links to the evidence in the release notes.

See the [suite release plan](https://github.com/paruff/uFawkes.dev/blob/main/docs/ai-sdlc/suite-release/plan.md)
for the order stacks are released in.
