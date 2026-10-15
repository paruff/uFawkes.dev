---
layout: stack
title: Fawkes
stack_name: Fawkes
stack_color: amber
description: "Fawkes — the internal delivery platform behind the uFawkes stacks. Orchestration, Tekton CI, GitOps. Runs locally on k3d; Alpha ships via tracer-bullet release."
hero: The platform behind the stacks. Pre-alpha, runs on your laptop.
summary: Fawkes is the core internal delivery platform (orchestration, Tekton CI, GitOps). The composable uFawkes stacks cover observability, delivery and developer experience.
coming_soon: false
repo_url: https://github.com/paruff/fawkes
repo_name: paruff/fawkes
features:
  - "Internal delivery platform: orchestration, Tekton CI, GitOps on Kubernetes"
  - "Local evaluation on k3d in ~20 minutes with `make dev-up`"
  - "Five core components: GitOps controller, Tekton pipelines, platform services, ingress, observability"
  - "DORA metrics pipeline feeding uFawkesObs dashboards"
  - "Secure-by-default platform with policy-as-code and supply-chain scanning"
  - "Education layer explaining platform concepts for team adoption"
quick_start:
  - git clone https://github.com/paruff/fawkes.git
  - cd fawkes
  - make dev-up
compose_with:
  - name: uFawkesObs
    url: /obs/
    description: Observe platform health, delivery signals, and DORA metrics from your Fawkes cluster.
  - name: uFawkesPipe
    url: /pipe/
    description: Add CI/CD orchestration with Woodpecker pipelines and release controls.
  - name: uFawkesDevX
    url: /devx/
    description: Extend with golden paths and developer experience workflows.
notify_title: Get notified at the Alpha release
notify_copy: Fawkes is pre-alpha (v0.3.95). Local evaluation on k3d works; cloud production does not yet. Leave your email and we'll write when Alpha ships. The repo and its Known Limitations page are public now.
---

## Try it locally

You can evaluate Fawkes on your laptop in about 20 minutes with `make dev-up`, which creates a k3d cluster and deploys the five core components. Start with the [getting-started guide](https://github.com/paruff/fawkes/blob/main/docs/getting-started.md) and read the [known limitations](https://github.com/paruff/fawkes/blob/main/docs/KNOWN_LIMITATIONS.md) first.
