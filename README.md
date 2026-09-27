# uFawkes.dev

Open-source platform engineering ecosystem — observability, pipelines, and developer experience.

**Live site:** [ufawkes.dev](https://ufawkes.dev) | **Release plan:** [docs/ai-sdlc/suite-release/](docs/ai-sdlc/suite-release/) | **Status:** [Project](https://github.com/users/paruff/projects/7) | **Start here:** [INTENT.md](INTENT.md)

## What is uFawkes?

uFawkes is a collection of opinionated, ready-to-run stacks for platform engineering teams. Each stack ships with sensible defaults so you can go from zero to running in 60 seconds.

| Stack                                    | Status | Description                                                                     | GitHub                                          |
| ---------------------------------------- | ------ | ------------------------------------------------------------------------------- | ----------------------------------------------- |
| [uFawkesObs](https://ufawkes.dev/obs/)   | Live   | Prometheus + Grafana + AI observability + DORA dashboards (merged uFawkesDORA)  | [GitHub](https://github.com/paruff/ufawkesobs)  |
| [uFawkesPipe](https://ufawkes.dev/pipe/) | Live   | CI/CD pipeline orchestration + secure-by-default guardrails (merged uFawkesSec) | [GitHub](https://github.com/paruff/ufawkespipe) |
| [uFawkesDevX](https://ufawkes.dev/devx/) | Live   | Golden paths for platform adoption                                              | [GitHub](https://github.com/paruff/ufawkesdevx) |

> uFawkesDORA and uFawkesSec are retired as standalone stacks (merged into uFawkesObs and uFawkesPipe). See [docs/roadmap.md](docs/roadmap.md) for what happened to each goal from the retired roadmap.

## Research Foundation

uFawkes is built on objective research:

- [DORA 2025 State of AI-Assisted Software Development](https://dora.dev/research/2025) — AI as amplifier, 7 AI Capabilities
- [DORA AI Capabilities Model](https://dora.dev/research/2025/ai-capabilities-model/) — 7 foundational practices that amplify AI benefits
- [CNCF Platforms White Paper](https://tag-app-delivery.cncf.io/whitepapers/platforms) — Internal developer platform best practices
- [SPACE Framework](https://www.microsoft.com/en-us/research/publication/the-space-of-developer-productivity-theres-more-to-it-than-you-think/) — Holistic developer productivity measurement

## Quick start

```bash
git clone https://github.com/paruff/ufawkesobs.git
cd ufawkesobs
docker compose up -d
```

## Contributing

This site is built with Jekyll and deployed via GitHub Pages from the `main` branch. To contribute:

1. Open an issue or pick one from the [issue tracker](https://github.com/paruff/uFawkes.dev/issues)
2. Create a branch (`git checkout -b fix/my-change`)
3. Make your changes and run `make build` to verify
4. Open a PR — CI must pass before merge

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License

MIT
