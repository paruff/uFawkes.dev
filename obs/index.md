---
layout: stack
title: uFawkesObs
stack_name: uFawkesObs
stack_color: blue
description: "Deploy Prometheus + Grafana observability in 60 seconds. DORA dashboards, AI metrics, and deployment-event collectors for GitHub Actions and Woodpecker CI."
hero: Prometheus + Grafana + AI observability. 60 seconds to running.
summary: Operational telemetry, unified DORA dashboards, and AI delivery visibility in one starter stack.
repo_url: https://github.com/paruff/ufawkesobs
repo_name: paruff/ufawkesobs
features:
  - DORA dashboards wired to delivery and reliability signals — deployment frequency, lead time, change failure rate, and MTTR (merged from uFawkesDORA)
  - Value stream mapping that connects delivery changes to team outcomes
  - AI metrics for copilots, agents, and assisted workflows
  - Alerting defaults for platform health and release flow
  - Deployment-event collectors for GitHub Actions, Woodpecker CI, and manual incident reports
  - Education layer that explains what the signals mean
quick_start:
  - git clone https://github.com/paruff/ufawkesobs.git
  - cd ufawkesobs
  - docker compose up -d
compose_with:
  - name: uFawkesPipe
    url: /pipe/
    description: Add CI/CD orchestration, release controls, and secure-by-default guardrails around your telemetry.
  - name: uFawkesDevX
    url: /devx/
    description: Pair metrics with guided developer workflows as DevX ships.
---

## Build in public

Follow stack progress in the [uFawkes blog]({{ '/blog/' | relative_url }}), starting with [the founding story]({{ '/blog/why-im-building-the-ufawkes-open-source-platform-engineering-stack/' | relative_url }}).
