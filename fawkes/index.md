---
layout: stack
title: Fawkes
stack_name: Fawkes
stack_color: amber
description: "Fawkes — an internal delivery platform you can run locally on k3d. Pre-alpha: local evaluation works; cloud production is not ready."
hero: The platform behind the stacks. Pre-alpha, runs on your laptop.
summary: Fawkes is the core internal delivery platform (orchestration, Tekton CI, GitOps). It is not the Dojo curriculum and not a hosted CI service. The composable uFawkes stacks cover observability, delivery and developer experience.
coming_soon: true
repo_url: https://github.com/paruff/fawkes
repo_name: paruff/fawkes
notify_title: Get notified at the Alpha release
notify_copy: Fawkes is pre-alpha (v0.3.95). Local evaluation on k3d works; cloud production does not yet. Leave your email and we'll write when Alpha ships. The repo and its Known Limitations page are public now.
---

## Try it locally

You can evaluate Fawkes on your laptop in about 20 minutes with `make dev-up`, which creates a k3d cluster and deploys the five core components. Start with the [getting-started guide](https://github.com/paruff/fawkes/blob/main/docs/getting-started.md) and read the [known limitations](https://github.com/paruff/fawkes/blob/main/docs/KNOWN_LIMITATIONS.md) first.
