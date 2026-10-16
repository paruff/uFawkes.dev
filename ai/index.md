---
layout: stack
title: uFawkesAI
stack_name: uFawkesAI
stack_color: green
description: "uFawkesAI — an AI-SDLC template for Claude Code, Copilot, Cursor and Codex. One AGENTS.md, DORA AI Capabilities built in."
hero: Make your AI agent work the way DORA research says high performers work.
summary: A GitHub template with one AGENTS.md every agent reads, agent profiles for each pipeline stage, and CI guardrails. v2.0.0 adds a pinned devcontainer image (fawkes-space:2.0.0) and a tested "Use this template" flow.
coming_soon: false
repo_url: https://github.com/paruff/uFawkesAI
repo_name: paruff/uFawkesAI
features:
  - One AGENTS.md that Claude Code, Copilot, Cursor, Codex and Gemini CLI all load
  - 14 agent profiles, from spec and design through build, test and review
  - A 10-step idea-to-deploy golden path and a tested prompt library
  - CI that blocks oversized PRs and flags stale docs
  - A weekly metrics script for rework rate, PR revision rate and CI cycle time
quick_start:
  - gh repo create my-project --template paruff/uFawkesAI --private --clone
  - cd my-project
  - claude # or open it in Copilot, Cursor or Codex; AGENTS.md loads automatically
compose_with:
  - name: uFawkesPipe
    url: /pipe/
    description: Run the agent's changes through CI/CD with security checks built in.
  - name: uFawkesDojo
    url: https://paruff.github.io/uFawkesDojo/
    description: Practice the workflow in a hands-on lab.
---

## Where this stands

v2.0.0 is released. It adds a devcontainer image you can pin by version (`fawkes-space:2.0.0`) and a template flow that's tested from a clean checkout. See the [v2.0.0 release](https://github.com/paruff/uFawkesAI/releases/tag/v2.0.0) and the [suite release plan](https://github.com/paruff/uFawkes.dev/blob/main/docs/ai-sdlc/suite-release/plan.md).
