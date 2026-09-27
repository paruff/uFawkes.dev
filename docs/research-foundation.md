# uFawkes Research Foundation

> Moved from `docs/roadmap.md` on 2026-09-27, when the roadmap was replaced by
> the suite release plan ([`docs/ai-sdlc/suite-release/`](ai-sdlc/suite-release/)).
> Stack references are updated for the 2026-08 consolidation: DORA merged into
> uFawkesObs, Sec merged into uFawkesPipe.

## Core Research Findings

### DORA 2025-2026 — Core Findings

| Finding                                                                                                                                                                                                            | Source                                              | uFawkes Implication                                                                                         |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **AI is an amplifier** — magnifies strengths AND dysfunctions                                                                                                                                                      | DORA 2025 State of AI-Assisted Software Development | Every stack must strengthen foundations (observability, pipelines, small batches) before adding AI features |
| **7 AI Capabilities** amplify AI benefits — clear AI stance, healthy data ecosystems, AI-accessible internal data, quality internal platform, user-centric focus, strong version control, working in small batches | DORA AI Capabilities Model 2025                     | Map each stack to specific capabilities; stack combinations address all 7                                   |
| **AI Productivity Paradox** — individual output up 21%, PRs merged up 98%, but organizational delivery metrics flat                                                                                                | Faros.ai telemetry (10k devs) + DORA 2025           | Stacks must include delivery metrics (DORA), not just coding metrics                                        |
| **ROI framework** — AI creates ROI when org converts local speed → stable delivery, reduced rework, better experiments, reinvested engineering capacity                                                            | DORA ROI of AI-Assisted Software Development 2026   | Each stack must demonstrate end-to-end flow improvement                                                     |
| **7 team archetypes** need different AI strategies                                                                                                                                                                 | DORA 2025                                           | Offer stack profiles for different maturity levels                                                          |
| **VSM as force multiplier** — Value Stream Management ensures local gains translate to product outcomes                                                                                                            | DORA 2025 + Honeycomb analysis                      | uFawkesObs (which absorbed uFawkesDORA) connects value streams to delivery metrics                          |

### CNCF Platform Engineering Research

| Finding                                                                                                  | Source                                             | uFawkes Implication                                             |
| -------------------------------------------------------------------------------------------------------- | -------------------------------------------------- | --------------------------------------------------------------- |
| **Platform engineering reduces cognitive load** — developers focus on business value, not infrastructure | CNCF Platforms White Paper (2023)                  | DevX stack abstracts infrastructure complexity via golden paths |
| **85% of orgs implementing IDPs** — market is maturing rapidly                                           | Port 2025 State of Internal Developer Portals      | Timing is right for open-source IDP stack                       |
| **Developer tool sprawl costs $1M/year** in lost productivity (7.4 tools avg, 75% lose 6-15 hrs/week)    | Port 2025                                          | Composable stacks reduce tool sprawl — one stack, one concern   |
| **78% of teams wait 1+ day for SRE/DevOps assistance**                                                   | Port 2025                                          | Self-service stacks eliminate ticket-ops bottleneck             |
| **Only 34% use portals to drive engineering standards**                                                  | Port 2025                                          | uFawkesDevX enforces standards via templates + scorecards       |
| **Hybrid platform approaches** emerging as dominant model for AI workloads                               | CNCF Technology Radar Q1 2026                      | Composable stacks support hybrid AI platform patterns           |
| **Platform maturity model** — 5 aspects × 4 levels (Ad-Hoc → Standardized → Optimized → Advanced)        | CNCF Platform Engineering Maturity Model 2023-2025 | Stack profiles map to maturity levels                           |
| **Helm, Backstage, kro** are "Adopt" technologies                                                        | CNCF Technology Radar Q1 2026                      | Align stack tech choices with CNCF recommendations              |

### SPACE Framework — Developer Productivity

| Dimension                         | What It Measures                                 | uFawkes Alignment                                                                                        |
| --------------------------------- | ------------------------------------------------ | -------------------------------------------------------------------------------------------------------- |
| **Satisfaction & Well-being**     | Developer happiness, burnout, work-life balance  | DevX stack reduces cognitive load; Obs stack provides actionable (not overwhelming) alerts               |
| **Performance**                   | Code quality, reliability, user satisfaction     | Obs stack (DORA metrics) measures delivery performance; Pipe stack (security guardrails) prevents rework |
| **Activity**                      | Commits, PRs, deployments (in context)           | Pipe stack tracks deployment frequency; Obs stack (DORA metrics) contextualizes activity                 |
| **Communication & Collaboration** | Code reviews, knowledge sharing, documentation   | DevX stack provides golden paths that encode team knowledge                                              |
| **Efficiency & Flow**             | Flow state time, context switching, blocked time | Composable stacks reduce context switching; self-service eliminates blocked time                         |

**Key insight from Microsoft Research (Brian Houck, STACK 2024)**: AI is reshaping traditional workflows — SPACE dimensions remain relevant but measurement must adapt. PR throughput is useful when viewed across all five dimensions, not in isolation.

---

## DORA AI Capabilities → Stack Mapping

| Capability                         | Primary Stack            | Supporting Stacks           | Measurable Outcome                      |
| ---------------------------------- | ------------------------ | --------------------------- | --------------------------------------- |
| **Clear + communicated AI stance** | AI                       | All                         | AI policy doc in repo README            |
| **Healthy data ecosystems**        | Obs (incl. DORA metrics) | Pipe                        | Data quality SLIs defined               |
| **AI-accessible internal data**    | Obs                      | DevX                        | Feature store / context API accessible  |
| **Quality internal platform**      | DevX                     | Pipe (incl. Sec guardrails) | Platform adoption rate >80%             |
| **User-centric focus**             | DevX                     | All                         | DX Core 4 satisfaction scores           |
| **Strong version control**         | Pipe                     | All                         | Trunk-based adoption %, branch lifetime |
| **Working in small batches**       | Pipe                     | Obs (DORA metrics)          | Batch size, deployment frequency        |

---

## Team Archetype → Stack Profile Mapping

| DORA Archetype                | Recommended Stacks | Entry Point         | Priority                                |
| ----------------------------- | ------------------ | ------------------- | --------------------------------------- |
| **Harmonious High-Achievers** | All (composable)   | DevX golden paths   | Low — they're already winning           |
| **Legacy Bottleneck**         | Obs → Pipe         | Observability first | High — biggest ROI opportunity          |
| **AI Experimenters**          | AI → Obs           | Agent templates     | Medium — need guardrails fast           |
| **Platform Builders**         | DevX → Pipe        | IDP scaffolding     | High — aligns with CNCF recommendations |
| **Security-First**            | Pipe → Obs         | Policy-as-code      | Medium — regulated industries           |
| **Metrics-Driven**            | Obs → Pipe         | Dashboard starter   | Medium — need data to act               |
| **Starting Out**              | Obs (only)         | 60-second Grafana   | High — lowest barrier to entry          |

---
