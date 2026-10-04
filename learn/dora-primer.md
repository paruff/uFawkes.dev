---
layout: page
title: DORA Primer for AI Delivery Teams
description: Learn the five DORA metrics, common failure modes, and an action plan for improving delivery performance with AI-enabled teams.
og_title: DORA Primer for AI Delivery Teams
og_description: A practical DORA primer with metric definitions, targets, and next actions.
og_type: article
read_time: 8
next_guide_url: /learn/ai-capabilities.html
next_guide_title: AI Capabilities Guide
---

> **Part of the uFawkesDojo curriculum** — This guide aligns with [White Belt Module 2: DORA Metrics](https://dojo.ufawkes.dev/lesson.html?src=modules/white-belt/module-02-dora-metrics.md) and [Brown Belt Module 14: DORA Deep Dive](https://dojo.ufawkes.dev/lesson.html?src=modules/brown-belt/module-14-dora-deep-dive.md). For hands-on practice, run the [DORA Metrics Lab](https://dojo.ufawkes.dev/lesson.html?src=white-belt/module-02-dora-metrics/lab-01/instructions.md) against uFawkesObs.

DORA gives teams a shared language for delivery performance. In AI-assisted development, that matters even more: faster coding only helps when the platform keeps quality and flow stable.

{% assign share_url = page.url | absolute_url %}
Share: [X](https://twitter.com/intent/tweet?text={{ page.title | uri_escape }}&url={{ share_url | uri_escape }}) · [LinkedIn](https://www.linkedin.com/sharing/share-offsite/?url={{ share_url | uri_escape }}) · [Email](mailto:?subject={{ page.title | uri_escape }}&body={{ share_url | uri_escape }})

## The five DORA metrics

1. **Deployment frequency** — how often you ship to production.
2. **Change lead time** — commit to production elapsed time.
3. **Change fail rate** — percent of deployments causing incidents, rollbacks, or hotfixes.
4. **Failed deployment recovery time** — how quickly service recovers after a failed deployment (earlier guides call this mean time to restore, or MTTR).
5. **Deployment rework rate** — how much of your delivery work is rework: unplanned changes made to fix problems in work you already shipped. It is the earliest signal that output quality is slipping, which matters most when AI is writing more of the code.

Together these show speed, stability and quality. Optimize all five; over-optimizing one metric usually creates hidden drag elsewhere.

## What good looks like

- Frequent, small deployments instead of risky batch releases.
- Predictable lead time with fewer queue bottlenecks.
- Low failure rate through tests, policy checks, and safe rollout patterns.
- Fast recovery through clear alerts, runbooks, and ownership.
- Low rework: few unplanned fixes to things you already shipped.

## AI-specific anti-patterns

- **More code, same platform**: AI output increases PR volume without improving CI/CD and observability.
- **Local speed, global slowdown**: developers move faster but release approvals and incident handling become chokepoints.
- **Metric theater**: tracking output (lines, prompts, PR count) instead of outcome (DORA).

## 30-day improvement loop

1. Baseline the five metrics weekly.
2. Pick one bottleneck (for example, review wait time).
3. Ship one platform change (automation, guardrail, or dashboard).
4. Compare DORA movement after two release cycles.

For capability planning, continue with the [AI capabilities guide]({{ '/learn/ai-capabilities.html' | relative_url }}). For signal quality and instrumentation, read the [observability primer]({{ '/learn/observability-primer.html' | relative_url }}).

Repos launching soon — [get notified](https://tally.so/embed/ODbbpR)

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
