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
  - DORA dashboards wired to delivery and reliability signals — all five DORA metrics: deployment frequency, change lead time, change fail rate, failed deployment recovery time, and deployment rework rate (merged from uFawkesDORA)
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

## See it running

Screenshots from uFawkesObs [v1.0.0](https://github.com/paruff/uFawkesObs/releases/tag/v1.0.0), started with `make up-full` on a laptop. The telemetry comes from the bundled demo app. The DORA numbers come from six sample deployment events sent to the stack's own ingestion API, not from a real team.

<figure>
  <img src="{{ '/assets/img/obs/grafana-metrics.png' | relative_url }}" alt="Grafana Node Exporter dashboard showing CPU, memory, disk and network metrics for the running stack" width="1440" height="900" loading="lazy">
  <figcaption><strong>Metrics.</strong> Prometheus metrics in Grafana.</figcaption>
</figure>

<figure>
  <img src="{{ '/assets/img/obs/grafana-logs.png' | relative_url }}" alt="Grafana Explore showing Loki logs from the demo app, with a log volume histogram split by error, info and warning" width="1440" height="900" loading="lazy">
  <figcaption><strong>Logs.</strong> Loki log volume and lines from the demo app.</figcaption>
</figure>

<figure>
  <img src="{{ '/assets/img/obs/grafana-traces.png' | relative_url }}" alt="Grafana Explore showing a Tempo TraceQL search returning traces from the demo app" width="1440" height="900" loading="lazy">
  <figcaption><strong>Traces.</strong> A Tempo TraceQL search over the demo app's requests.</figcaption>
</figure>

<figure>
  <img src="{{ '/assets/img/obs/grafana-dora.png' | relative_url }}" alt="Grafana DORA Metrics dashboard showing deployment frequency, lead time, change failure rate, failed deployment recovery time and rework rate" width="1440" height="900" loading="lazy">
  <figcaption><strong>DORA.</strong> The five DORA metrics, computed from sample deployment events.</figcaption>
</figure>
