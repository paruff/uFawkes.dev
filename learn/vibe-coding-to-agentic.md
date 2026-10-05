---
layout: page
title: From Vibe Coding to Agentic Engineering
description: Understand the shift from unstructured AI-assisted coding to disciplined agentic engineering using the AI-Native SDLC Playbook.
og_title: From Vibe Coding to Agentic Engineering
og_description: A White Belt primer on moving from ad-hoc AI use to structured, measurable AI-native software delivery.
og_type: article
read_time: 8
next_guide_url: /learn/dora-primer.html
next_guide_title: DORA Primer
---

> **Part of the uFawkesDojo curriculum** — This primer introduces the AI-Native SDLC mindset that underpins the Dojo's "Start here" lab and the uFawkesAI template. It cites [The AI-Native SDLC Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook) (Claxton, Anthropic, 2026).

{% assign share_url = page.url | absolute_url %}
Share: [X](https://twitter.com/intent/tweet?text={{ page.title | uri_escape }}&url={{ share_url | uri_escape }}) · [LinkedIn](https://www.linkedin.com/sharing/share-offsite/?url={{ share_url | uri_escape }}) · [Email](mailto:?subject={{ page.title | uri_escape }}&body={{ share_url | uri_escape }})

## The problem: vibe coding doesn't scale

**Vibe coding** is the default mode when developers first adopt AI coding assistants:

- Prompt the model, accept the output, maybe tweak it, move on
- No systematic verification beyond "it runs on my machine"
- No shared standards for when to use AI vs. when to write code manually
- No measurement of whether AI actually improves delivery outcomes
- Context and decisions stay in the developer's head (or chat history)

This works for prototypes and personal projects. It **fails** for team delivery:

| Vibe coding symptom                  | Delivery impact                             |
| ------------------------------------ | ------------------------------------------- |
| Inconsistent AI use across the team  | Unreviewable PRs, hidden quality variance   |
| No guardrails on generated code      | Security issues, technical debt, test gaps  |
| "It works" replaces "it's correct"   | Incidents from AI-introduced bugs           |
| No feedback loop on AI effectiveness | Can't justify tooling cost or improve usage |

## The shift: agentic engineering

**Agentic engineering** treats AI as a _capability to be engineered_, not a magic wand:

- **Structured workflows**: AI use follows defined patterns (intent → spec → plan → execute → verify)
- **Explicit guardrails**: Policy-as-code, automated checks, human-in-the-loop gates
- **Measurable outcomes**: DORA metrics track whether AI improves delivery
- **Observable agent behavior**: Telemetry on what agents do, decide, and produce
- **Continuous improvement**: Regular retrospectives on AI workflow effectiveness

The AI-Native SDLC Playbook (Claxton, Anthropic, 2026) frames this as **six stages of maturity**:

| Stage             | Focus                       | Key practice                        |
| ----------------- | --------------------------- | ----------------------------------- |
| 1. Ad-hoc         | Individual experimentation  | Copilot, chat UI                    |
| 2. Assisted       | Personal productivity       | Prompt libraries, snippets          |
| 3. Automated      | Team workflows              | Templates, CI integration           |
| 4. Orchestrated   | Cross-cutting orchestration | Multi-agent pipelines, policy gates |
| 5. Governed       | Compliance & safety         | Audit trails, approval gates        |
| 6. Self-improving | Continuous optimization     | Eval-driven prompt/rule refinement  |

Most teams are at Stage 1–2. The uFawkes suite targets **Stage 3–4** as the starting baseline for platform teams.

## Why this matters for platform teams

Platform engineers don't just _use_ AI—they build the **platform that makes AI safe and effective for the whole organization**.

| Platform responsibility | Vibe coding approach          | Agentic engineering approach                   |
| ----------------------- | ----------------------------- | ---------------------------------------------- |
| **CI/CD pipelines**     | Manual AI-generated YAML      | Golden-path templates with policy checks       |
| **Code review**         | Human reads AI output         | Automated rule evaluation + human review       |
| **Testing**             | "AI wrote tests, good enough" | Mutation testing, contract tests, eval suites  |
| **Observability**       | None                          | Agent telemetry, DORA metrics, eval dashboards |
| **Security**            | Post-hoc scanning             | Shift-left policy-as-code (Rego/OPA)           |
| **Onboarding**          | "Figure it out"               | Runnable "Start here" lab with validation      |

## The uFawkes path

The uFawkes suite is built _for_ agentic engineering:

| Stack           | Role in agentic engineering                                                          |
| --------------- | ------------------------------------------------------------------------------------ |
| **uFawkesAI**   | Template + devcontainer + agent harnesses (the "Start here" lab runs here)           |
| **uFawkesObs**  | Observability plane: metrics, logs, traces, DORA dashboards for AI workflows         |
| **uFawkesPipe** | CI/CD + policy plane: Woodpecker, Conftest/Rego, DefectDojo, golden paths            |
| **uFawkesDevX** | Developer experience: Backstage catalog, Coder workspaces, Cookiecutter golden paths |
| **fawkes**      | Kubernetes-native graduation target (Tekton, ArgoCD, CloudNativePG)                  |

## Your first step: the "Start here" lab

The Dojo's entry-point lab (built on uFawkesAI `v2.0.0`) walks you through one complete **intent → spec → plan → execute → verify** cycle:

1. **Generate a repo** from the uFawkesAI template (pinned to `v2.0.0`)
2. **Open the devcontainer** — all tooling pre-installed (Claude Code, OpenCode, pre-commit, evals)
3. **Write an intent** for a small change
4. **Produce a spec** with acceptance criteria
5. **Create a plan** the planner accepts
6. **Execute** and run `make validate`
7. **Verify** the eval passes against `baseline.json`

This is **agentic engineering in miniature**: structured, verified, measurable.

## Key takeaways

1. **Vibe coding is Stage 1** — necessary for learning, insufficient for delivery
2. **Agentic engineering is Stages 3–4+** — structured workflows, guardrails, measurement
3. **The platform enables the shift** — golden paths, policy-as-code, observability
4. **DORA metrics are the scoreboard** — if AI doesn't move them, it's not working
5. **Start with the lab** — the "Start here" lab is your first calibrated step

## Continue learning

- **Next**: [DORA Primer]({{ '/learn/dora-primer.html' | relative_url }}) — the five metrics that measure whether agentic engineering works
- **Hands-on**: Run the [Dojo "Start here" lab](https://dojo.ufawkes.dev/lesson.html?src=white-belt/module-01-what-is-idp/lab-01/instructions.md) (when published with Dojo 0.2)
- **Reference**: [The AI-Native SDLC Playbook](https://claude.com/blog/the-ai-native-sdlc-playbook) (Claxton, Anthropic, 2026-08-21)

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
