---
layout: stack
title: uFawkesPipe
stack_name: uFawkesPipe
stack_color: purple
description: "Composable CI/CD pipelines with fast feedback and resilient release controls. Docker Compose setup in 60 seconds."
hero: Composable CI/CD pipelines with fast feedback. 60 seconds to running.
summary: Golden-path delivery automation with secure-by-default guardrails for teams that need resilient releases without heavyweight platform work.
repo_url: https://github.com/paruff/ufawkespipe
repo_name: paruff/ufawkespipe
features:
  - Opinionated pipeline templates for fast feedback loops
  - Delivery metrics hooks that feed DORA reporting
  - Release controls for safer deploys and rollbacks
  - Policy-as-code (Conftest/Rego `policy-check` step) and supply-chain scanning with Trivy, Gitleaks, SonarQube, and DefectDojo (merged from uFawkesSec)
  - Woodpecker CI pipelines driven by a standard `.fawkespipe.yml` contract
  - Education layer to help teams adopt delivery best practices
quick_start:
  - git clone https://github.com/paruff/ufawkespipe.git
  - cd ufawkespipe
  - docker compose up -d
compose_with:
  - name: uFawkesObs
    url: /obs/
    description: Observe every pipeline run, deploy, service health signal, and DORA metric.
  - name: uFawkesDevX
    url: /devx/
    description: Extend the stack with guided golden paths as DevX ships.
---
