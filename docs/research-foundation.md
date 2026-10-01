# uFawkes Research Foundation

> Moved from `docs/roadmap.md` on 2026-09-27, when the roadmap was replaced by
> the suite release plan ([`docs/ai-sdlc/suite-release/`](ai-sdlc/suite-release/)).
> Stack references are updated for the 2026-08 consolidation: DORA merged into
> uFawkesObs, Sec merged into uFawkesPipe.

> **Evidence rule (2026-10-01):** a finding may back a public claim only if
> its source is linked under [Sources](#sources). Rows marked _unverified_
> haven't been checked against their primary source yet. Don't cite them
> publicly until they are. Five of the seven "DORA archetypes" previously
> listed here were not DORA's names; that table is corrected below.

## Core Research Findings

### DORA 2025-2026 — Core Findings

| Finding                                                                                                                                                                                                                                                                                                        | Source                                                                                     | uFawkes Implication                                                                                         |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| **AI is an amplifier** — magnifies strengths AND dysfunctions                                                                                                                                                                                                                                                  | DORA 2025 State of AI-Assisted Software Development                                        | Every stack must strengthen foundations (observability, pipelines, small batches) before adding AI features |
| **7 AI Capabilities** amplify AI benefits — clear and communicated AI stance, healthy data ecosystems, AI-accessible internal data, strong version control practices, working in small batches, user-centric focus, quality internal platforms. AI tools "can harm teams that don't have a user-centric focus" | DORA AI Capabilities Model (2025-11-25)                                                    | Map each stack to specific capabilities; stack combinations address all 7                                   |
| **AI Productivity Paradox** — individual output up 21%, PRs merged up 98%, but organizational delivery metrics flat _(unverified)_                                                                                                                                                                             | Faros.ai telemetry (10k devs). Not in DORA 2025: checked against the report PDF 2026-10-01 | Stacks must include delivery metrics (DORA), not just coding metrics                                        |
| **ROI framework** — AI creates ROI when org converts local speed → stable delivery, reduced rework, better experiments, reinvested engineering capacity. Expect a J-curve: a dip before gains                                                                                                                  | DORA ROI of AI-Assisted Software Development (v2026.1, 2026-04-22; CC BY-NC-SA 4.0)        | Each stack must demonstrate end-to-end flow improvement                                                     |
| **7 team archetypes** need different AI strategies                                                                                                                                                                                                                                                             | DORA 2025                                                                                  | Offer stack profiles for different maturity levels                                                          |
| **VSM as force multiplier** — "VSM acts as a force multiplier for AI investments": a systems-level view ensures AI is applied to the right problems                                                                                                                                                            | DORA 2025 State of AI-Assisted Software Development                                        | uFawkesObs (which absorbed uFawkesDORA) connects value streams to delivery metrics                          |

### CNCF Platform Engineering Research

| Finding                                                                                                  | Source                                                       | uFawkes Implication                                             |
| -------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ | --------------------------------------------------------------- |
| **Platform engineering reduces cognitive load** — developers focus on business value, not infrastructure | CNCF Platforms White Paper (2023)                            | DevX stack abstracts infrastructure complexity via golden paths |
| **85% of orgs implementing IDPs** — market is maturing rapidly                                           | Port 2025 State of Internal Developer Portals _(unverified)_ | Timing is right for open-source IDP stack                       |
| **Developer tool sprawl costs $1M/year** in lost productivity (7.4 tools avg, 75% lose 6-15 hrs/week)    | Port 2025 _(unverified)_                                     | Composable stacks reduce tool sprawl — one stack, one concern   |
| **78% of teams wait 1+ day for SRE/DevOps assistance**                                                   | Port 2025 _(unverified)_                                     | Self-service stacks eliminate ticket-ops bottleneck             |
| **Only 34% use portals to drive engineering standards**                                                  | Port 2025 _(unverified)_                                     | uFawkesDevX enforces standards via templates + scorecards       |
| **Hybrid platform approaches** emerging as dominant model for AI workloads                               | CNCF Technology Radar Q1 2026 _(unverified)_                 | Composable stacks support hybrid AI platform patterns           |
| **Platform maturity model** — 5 aspects × 4 levels (Ad-Hoc → Standardized → Optimized → Advanced)        | CNCF Platform Engineering Maturity Model 2023-2025           | Stack profiles map to maturity levels                           |
| **Helm, Backstage, kro** are "Adopt" technologies                                                        | CNCF Technology Radar Q1 2026 _(unverified)_                 | Align stack tech choices with CNCF recommendations              |

### SPACE Framework — Developer Productivity

| Dimension                         | What It Measures                                 | uFawkes Alignment                                                                                        |
| --------------------------------- | ------------------------------------------------ | -------------------------------------------------------------------------------------------------------- |
| **Satisfaction & Well-being**     | Developer happiness, burnout, work-life balance  | DevX stack reduces cognitive load; Obs stack provides actionable (not overwhelming) alerts               |
| **Performance**                   | Code quality, reliability, user satisfaction     | Obs stack (DORA metrics) measures delivery performance; Pipe stack (security guardrails) prevents rework |
| **Activity**                      | Commits, PRs, deployments (in context)           | Pipe stack tracks deployment frequency; Obs stack (DORA metrics) contextualizes activity                 |
| **Communication & Collaboration** | Code reviews, knowledge sharing, documentation   | DevX stack provides golden paths that encode team knowledge                                              |
| **Efficiency & Flow**             | Flow state time, context switching, blocked time | Composable stacks reduce context switching; self-service eliminates blocked time                         |

**Key insight from Microsoft Research (Brian Houck, STACK 2024)** _(unverified)_: AI is reshaping traditional workflows — SPACE dimensions remain relevant but measurement must adapt. PR throughput is useful when viewed across all five dimensions, not in isolation.

### Developer Experience — guides the uFawkesAI CDE

No peer-reviewed study of devcontainers or cloud development environments
specifically was found (2026-10-01); that literature is vendor material. The
CDE is therefore designed against the general DevEx evidence below.

| Finding                                                                                                                                                                                                                                 | Source                                                                                                                                                                             | CDE implication                                                                                                            |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **DevEx has three core dimensions: feedback loops, cognitive load, flow state.** Measure with developer perceptions _and_ system data together                                                                                          | Noda, Storey, Forsgren, Greiler, _DevEx: What Actually Drives Productivity_ (ACM Queue 21:2, 2023)                                                                                 | Budget time-to-ready (feedback), one entry point and one config source (cognitive load), no interactive setup steps (flow) |
| **Better DevEx has measurable outcomes:** deep-work time, intuitive tools and processes, and fast feedback correlate with higher self-reported productivity and innovation                                                              | Forsgren et al., _DevEx in Action_ (ACM Queue 21:6, 2024)                                                                                                                          | Pair each speed metric with a short developer survey; never report one without the other                                   |
| **Productivity is multi-dimensional:** Satisfaction, Performance, Activity, Communication, Efficiency/flow. Use at least three, never activity alone                                                                                    | Forsgren et al., _The SPACE of Developer Productivity_ (ACM Queue 19:1, 2021)                                                                                                      | The CDE's release notes report ≥ 3 SPACE dimensions, not just tool counts                                                  |
| **Every build-latency improvement helps; there is no magic threshold.** Developers go off-task during builds and return more slowly the longer they wait                                                                                | Jaspan & Green et al., _Developer Productivity for Humans, Part 4: Build Latency, Predictability, and Developer Productivity_ (IEEE Software, 2023)                                | Track cold and warm start time per release and refuse regressions, rather than chasing one target number                   |
| **Onboarding and ramp-up are measurable and improvable**                                                                                                                                                                                | Green, Jaspan et al., _Developer Productivity for Humans, Part 5: Onboarding and Ramp-Up_ (IEEE Software, 2023)                                                                    | Measure time from "Use this template" to first merged PR, in the Dojo "Start here" lab                                     |
| **Good days are days with few interruptions during development; meetings are constructive during planning and release**                                                                                                                 | Meyer, Barr, Bird, Zimmermann, _Today was a Good Day_ (IEEE TSE 47:5, 2021; n = 5,971)                                                                                             | Agents run long tasks in the background (orchestrator mode); notifications are opt-in                                      |
| **AI effects are real but context-dependent:** ~21% faster on an enterprise task (RCT, n = 96 Google engineers), yet experienced developers on their own repos were ~19% _slower_ while believing they were 20% faster (RCT, 246 tasks) | Paradis et al., Google ([arXiv 2410.12944](https://arxiv.org/abs/2410.12944), 2024); METR ([2025-07-10](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/)) | uFawkesAI makes no speedup claim it hasn't measured, and the Dojo lab records perceived _and_ measured time                |

### AI-Native SDLC — the process and harness model for uFawkesAI

| Finding                                                                                                                                                                                                    | Source                                                                                 | uFawkes implication                                                                               |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| **Six stages, each committing an artifact the next reads:** `intent.md` → `spec.md` → `plan.md` → PR → review findings → incident record. "The agent may act up to the production gate and cannot pass it" | Claxton, _The AI-Native SDLC Playbook_ (Anthropic, 2026-08-21)                         | uFawkesAI's artifact chain; Stage 6 (breach → `intent.md`) is the Obs ↔ AI integration direction |
| **Agent = Model + Harness;** most agent failures are harness failures. Without both tests and evals, it's still vibe coding                                                                                | Osmani, Saboo, Kartakis, _The New SDLC With Vibe Coding_ (May 2026, course whitepaper) | uFawkesAI is the harness; evals gate merges                                                       |

### Industry signal (context, not evidence)

Surveys from industry bodies and vendors show where the market is, not
what works. Use them for positioning, never as the basis for a design
decision.

| Signal                                                                                                                                                                                                                                                                                                               | Source                                                                                       | Relevance                                                                                                                                                                           |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 94% see AI as critical to platform engineering's future; "shifting down" (controls embedded in the platform) replaces "shift left"; platform teams are "absorbing traditional silos like observability, security, data, and FinOps"; 29.6% of platform teams don't measure success; 55.9% run more than one platform | platformengineering.org, _State of Platform Engineering Vol 4_ (2025-12-16; survey, n = 518) | Supports the suite's multi-plane shape (Obs, Pipe with security, DevX) and fawkes's multi-plane IDP; the 29.6% is the Obs/DORA pitch. Weak evidence: self-selected community survey |

---

## DORA AI Capabilities → Stack Mapping

| Capability                           | Primary Stack                            | Supporting Stacks                                        | Measurable Outcome                      |
| ------------------------------------ | ---------------------------------------- | -------------------------------------------------------- | --------------------------------------- |
| **Clear and communicated AI stance** | uFawkesAI (`AI_STANCE.md` in every repo) | All                                                      | AI policy doc in repo README            |
| **Healthy data ecosystems**          | Obs (incl. DORA metrics)                 | Pipe                                                     | Data quality SLIs defined               |
| **AI-accessible internal data**      | Obs                                      | uFawkesAI (MCP servers, `ufawkes-knowledge` skill), DevX | Feature store / context API accessible  |
| **Quality internal platforms**       | DevX                                     | Pipe (incl. Sec guardrails)                              | Platform adoption rate >80%             |
| **User-centric focus**               | DevX                                     | All                                                      | DX Core 4 satisfaction scores           |
| **Strong version control practices** | Pipe                                     | uFawkesAI (artifact chain, hooks), All                   | Trunk-based adoption %, branch lifetime |
| **Working in small batches**         | Pipe                                     | Obs (DORA metrics)                                       | Batch size, deployment frequency        |

---

## Team Archetype → Stack Profile Mapping

The seven archetypes are DORA 2025's cluster analysis
([report](https://dora.dev/research/2025/dora-report/)). The stack mapping
is uFawkes's own judgment, not DORA's.

| DORA 2025 archetype           | What DORA describes                         | uFawkes entry point (our mapping)      |
| ----------------------------- | ------------------------------------------- | -------------------------------------- |
| **Foundational challenges**   | Survival mode; significant process gaps     | uFawkesObs alone: see the system first |
| **The legacy bottleneck**     | Constant reaction to unstable systems       | uFawkesObs → uFawkesPipe               |
| **Constrained by process**    | Consumed by inefficient workflows           | uFawkesPipe → uFawkesDevX              |
| **High impact, low cadence**  | Quality work, delivered slowly              | uFawkesPipe (small batches)            |
| **Stable and methodical**     | Deliberate delivery, high quality           | uFawkesPipe + uFawkesAI                |
| **Pragmatic performers**      | Fast, but in merely functional environments | uFawkesDevX + uFawkesAI                |
| **Harmonious high-achievers** | A virtuous cycle of sustainable excellence  | uFawkesAI; graduate to fawkes          |

---

## Sources

Verified 2026-10-01 against the primary document (PDF where available).

- DORA, _2025 State of AI-assisted Software Development_: [PDF](https://services.google.com/fh/files/misc/2025_state_of_ai_assisted_software_development.pdf) · [page](https://dora.dev/research/2025/dora-report/)
- DORA, _AI Capabilities Model_ (2025-11-25): [PDF](https://services.google.com/fh/files/misc/2025_dora_ai_capabilities_model.pdf) · [page](https://dora.dev/ai/capabilities-model/report/)
- DORA, _The ROI of AI-assisted Software Development_ (v2026.1, 2026-04-22): [PDF](https://services.google.com/fh/files/misc/dora-roi-of-ai-assisted-software-development-2026.pdf) · [page](https://dora.dev/ai/roi/report/)
- Forsgren et al., _The SPACE of Developer Productivity_ (ACM Queue 19:1, 2021): [article](https://queue.acm.org/detail.cfm?id=3454124) · [PDF](https://queue.acm.org/doi/pdf/10.1145/3454122.3454124) · [space-framework.com](https://space-framework.com/)
- Noda et al., _DevEx: What Actually Drives Productivity_ (2023): https://dl.acm.org/doi/10.1145/3610285
- Forsgren et al., _DevEx in Action_ (2024): https://dl.acm.org/doi/10.1145/3639443
- Jaspan, Green et al., _Build Latency, Predictability, and Developer Productivity_ (2023): https://ui.adsabs.harvard.edu/abs/2023ISoft..40d..25J/abstract
- Green, Jaspan et al., _Onboarding and Ramp-Up_ (2023): https://research.google/pubs/developer-productivity-for-humans-part-5-onboarding-and-ramp-up/
- Meyer et al., _Today was a Good Day_ (2021): https://www.microsoft.com/en-us/research/wp-content/uploads/2019/04/devtime-preprint-TSE19.pdf
- Paradis et al., _How much does AI impact development speed?_ (2024): https://arxiv.org/abs/2410.12944
- METR, _Early-2025 AI and experienced open-source developer productivity_: https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/
- Anthropic, _The AI-Native SDLC Playbook_ (2026-08-21): https://claude.com/blog/the-ai-native-sdlc-playbook
- Osmani, Saboo, Kartakis, _The New SDLC With Vibe Coding_ (May 2026): [PDF](https://readwise-assets.s3.amazonaws.com/media/wisereads/articles/the-new-sdlc-with-vibe-coding/1317.pdf)
- platformengineering.org, _State of Platform Engineering Vol 4_ (2025-12-16): [PDF](https://5890440.fs1.hubspotusercontent-eu1.net/hubfs/5890440/State%20of%20Platform%20Engineering%20Vol%204%202025.pdf) · [announcement](https://platformengineering.org/blog/announcing-the-state-of-platform-engineering-vol-4)
