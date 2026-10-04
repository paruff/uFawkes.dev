---
layout: page
title: AI Capabilities Guide for Platform Teams
description: Understand AI capability maturity across tooling, workflow, governance, and outcomes using a DORA-aligned approach.
og_title: AI Capabilities Guide for Platform Teams
og_description: A practical model for moving AI from isolated experiments to measurable delivery impact.
og_type: article
read_time: 6
next_guide_url: /learn/observability-primer.html
next_guide_title: Observability Primer
---

> **Part of the uFawkesDojo curriculum** — This guide aligns with the Dojo's AI-capability framing across belts: the 5th DORA metric (Rework Rate) in [White Belt Module 2](https://dojo.ufawkes.dev/lesson.html?src=modules/white-belt/module-02-dora-metrics.md) and [Brown Belt Module 14](https://dojo.ufawkes.dev/lesson.html?src=modules/brown-belt/module-14-dora-deep-dive.md); developer workflow automation in [White Belt Module 4](https://dojo.ufawkes.dev/lesson.html?src=modules/white-belt/module-04-first-deployment.md) (Backstage catalog, golden-path Cookiecutter); and the uFawkesDevX stack (Backstage, Coder, Score) as the Compose-tier platform for AI-assisted delivery.

AI adoption is not one capability. It is a stack of capabilities that must mature together: development workflow, platform guardrails, observability, and team operating model.

{% assign share_url = page.url | absolute_url %}
Share: [X](https://twitter.com/intent/tweet?text={{ page.title | uri_escape }}&url={{ share_url | uri_escape }}) · [LinkedIn](https://www.linkedin.com/sharing/share-offsite/?url={{ share_url | uri_escape }}) · [Email](mailto:?subject={{ page.title | uri_escape }}&body={{ share_url | uri_escape }})

## Capability layers

1. **Assist** — copilots help with local code generation and refactoring.
2. **Automate** — repeatable tasks move to templates, workflows, and policy checks.
3. **Augment decisions** — telemetry and AI insights suggest actions with context.
4. **Govern at scale** — security, compliance, and quality controls are default, not optional.

## How to avoid stalled AI rollouts

- Pair every AI feature with an operational owner.
- Track DORA metric impact for every major AI workflow change.
- Keep golden paths short: one command to run, one dashboard to verify, one rollback path.
- Instrument agent and copilot workflows so failures are visible.

## Practical scorecard

Rate each area from 1 (ad hoc) to 5 (reliable):

- Workflow integration (IDE + CI + deployment path)
- Observability coverage (metrics, logs, traces, alerts)
- Guardrails (tests, policy, rollback safety)
- Team enablement (docs, runbooks, onboarding)
- Business impact (DORA movement, incident trends)

Revisit the score monthly and prioritize the lowest scoring domain first.

If you need the delivery baseline first, start with the [DORA primer]({{ '/learn/dora-primer.html' | relative_url }}). For the AI-Native SDLC mindset, start with [From Vibe Coding to Agentic Engineering]({{ '/learn/vibe-coding-to-agentic.html' | relative_url }}). Then use the [observability primer]({{ '/learn/observability-primer.html' | relative_url }}) to improve signal quality.

Run this yourself: [uFawkesDevX (Backstage, Coder, golden paths)](https://github.com/paruff/uFawkesDevX)

{% include guide-meta.html %}

## Get notified when new guides ship

<iframe
  src="https://tally.so/embed/wQ6aZ6?alignLeft=1&hideTitle=1&transparentBackground=1"
  title="Get notified when new guides ship"
  width="100%"
  height="290"
  loading="lazy"
  sandbox="allow-forms allow-scripts"
  referrerpolicy="no-referrer"
></iframe>
