---
layout: home
title: ""
---

<div class="hero-layout">
  <section class="hero-copy">
    <h1>Production platform engineering in minutes. Open source. DORA AI-ready.</h1>
    <p class="problem-statement">
      DORA 2025 research: AI amplifies your platform's strengths — and dysfunctions.
      uFawkes gives you the platform foundation that makes AI delivery actually work.
    </p>
    <a href="{{ '/obs/' | relative_url }}" class="cta-button">Run Obs in 60 seconds →</a>
    <a href="#stack-family" class="cta-button cta-button--secondary">See the stacks ↓</a>
  </section>

</div>

<section class="try-now">
  <h2>Try it now</h2>
  <p>Pick a stack and run it locally in 60 seconds:</p>
  <div class="try-now__commands">
    <code class="try-now__command">docker compose up obs</code>
    <code class="try-now__command">docker compose up pipe</code>
  </div>
</section>

<h2 id="stack-family">Stack Family</h2>

<section class="stack-grid" aria-label="uFawkes stack family">
  <article class="stack-card">
    <h3><a class="stack-link" href="{{ '/obs/' | relative_url }}">👁️ Obs</a> <img alt="Live" src="https://img.shields.io/badge/status-live-16a34a" /></h3>
    <p>Operational telemetry and reliability visibility for AI-enabled delivery teams.</p>
    <p><code>docker compose up obs</code></p>
    <p><a href="https://github.com/paruff/ufawkesobs" target="_blank" rel="noopener noreferrer">View on GitHub →</a></p>
  </article>
  <article class="stack-card">
    <h3><a class="stack-link" href="{{ '/pipe/' | relative_url }}">🔁 Pipe</a> <img alt="Live" src="https://img.shields.io/badge/status-live-16a34a" /></h3>
    <p>Composable CI/CD pipelines with fast feedback and resilient release controls.</p>
    <p><code>docker compose up pipe</code></p>
    <p><a href="https://github.com/paruff/ufawkespipe" target="_blank" rel="noopener noreferrer">View on GitHub →</a></p>
  </article>
  <article class="stack-card">
    <h3><a class="stack-link" href="{{ '/devx/' | relative_url }}">🧭 DevX</a> <img alt="Live" src="https://img.shields.io/badge/status-live-16a34a" /></h3>
    <p>Developer experience golden paths that make platform adoption simple and fast.</p>
    <p><code>docker compose up devx</code></p>
    <p><a href="https://github.com/paruff/ufawkesdevx" target="_blank" rel="noopener noreferrer">View on GitHub →</a></p>
  </article>
</section>

<section class="dojo-callout">
  <h2>🟢 Try the Fawkes Dojo</h2>
  <p>Interactive learning sandbox. Run real stacks in your browser — no install required.</p>
  <a href="https://paruff.github.io/uFawkesDojo/" class="cta-button" target="_blank" rel="noopener noreferrer">Launch Dojo →</a>
</section>

## DORA AI Capabilities

<p><strong>uFawkes implements the 7 DORA AI Capabilities.</strong> Based on the <a href="https://dora.dev/research/2025/ai-capabilities-model/" target="_blank" rel="noopener noreferrer">DORA AI Capabilities Model</a>, these foundational practices amplify the positive impact of AI on organizational performance.</p>

<section class="capability-map" aria-label="DORA AI capabilities by stack">
  <article class="capability-map__row">
    <div class="capability-map__capability">
      <h3>1. Clear + communicated AI stance</h3>
      <p>Define and communicate how your organization uses AI in software development.</p>
    </div>
    <div class="capability-map__stacks">
      <a href="{{ '/devx/' | relative_url }}" class="badge badge--live">DevX</a>
    </div>
  </article>
  <article class="capability-map__row">
    <div class="capability-map__capability">
      <h3>2. Healthy data ecosystems</h3>
      <p>Ensure your telemetry, metrics, and operational data are structured and accessible.</p>
    </div>
    <div class="capability-map__stacks">
      <a href="{{ '/obs/' | relative_url }}" class="badge badge--live">Obs</a>
    </div>
  </article>
  <article class="capability-map__row">
    <div class="capability-map__capability">
      <h3>3. AI-accessible internal data</h3>
      <p>Make your platform data consumable by AI tools and agents for better insights.</p>
    </div>
    <div class="capability-map__stacks">
      <a href="{{ '/obs/' | relative_url }}" class="badge badge--live">Obs</a>
    </div>
  </article>
  <article class="capability-map__row">
    <div class="capability-map__capability">
      <h3>4. Quality internal platform</h3>
      <p>Build a reliable, self-service platform that reduces cognitive load for developers.</p>
    </div>
    <div class="capability-map__stacks">
      <a href="{{ '/devx/' | relative_url }}" class="badge badge--live">DevX</a>
      <a href="{{ '/pipe/' | relative_url }}" class="badge badge--live">Pipe</a>
    </div>
  </article>
  <article class="capability-map__row">
    <div class="capability-map__capability">
      <h3>5. User-centric focus</h3>
      <p>Prioritize developer experience and measure satisfaction across your platform.</p>
    </div>
    <div class="capability-map__stacks">
      <a href="{{ '/devx/' | relative_url }}" class="badge badge--live">DevX</a>
    </div>
  </article>
  <article class="capability-map__row">
    <div class="capability-map__capability">
      <h3>6. Strong version control practices</h3>
      <p>Enforce trunk-based development, code review, and automated testing workflows.</p>
    </div>
    <div class="capability-map__stacks">
      <a href="{{ '/pipe/' | relative_url }}" class="badge badge--live">Pipe</a>
    </div>
  </article>
  <article class="capability-map__row">
    <div class="capability-map__capability">
      <h3>7. Working in small batches</h3>
      <p>Enable frequent, small deployments with fast feedback loops and rollback capabilities.</p>
    </div>
    <div class="capability-map__stacks">
      <a href="{{ '/pipe/' | relative_url }}" class="badge badge--live">Pipe</a>
      <a href="{{ '/obs/' | relative_url }}" class="badge badge--live">Obs</a>
    </div>
  </article>
  <article class="capability-map__row">
    <div class="capability-map__capability">
      <h3>Graduation path: Fawkes platform</h3>
      <p>The internal delivery platform (orchestration, Tekton CI, GitOps) that the composable stacks build on. Run locally on k3d; Alpha ships via tracer-bullet release.</p>
    </div>
    <div class="capability-map__stacks">
      <a href="{{ '/fawkes/' | relative_url }}" class="badge badge--live">Fawkes</a>
    </div>
  </article>
</section>

<section class="email-capture" aria-labelledby="notify-title">
  <h2 id="notify-title">Stay updated</h2>
  <p>Get notified when new stacks ship and guides are published.</p>
  <iframe
    src="https://tally.so/embed/ODbbpR?alignLeft=1&hideTitle=1&transparentBackground=1"
    title="Stay updated"
    width="100%"
    height="290"
    loading="lazy"
    sandbox="allow-forms allow-scripts"
    referrerpolicy="no-referrer"></iframe>
</section>

<section class="research-section">
  <h2>Backed by Research</h2>
  <p>uFawkes is built on objective research from industry leaders:</p>
  <ul>
    <li><a href="https://dora.dev/research/2025" target="_blank" rel="noopener noreferrer">DORA 2025 State of AI-Assisted Software Development</a> — AI as amplifier, 7 AI Capabilities</li>
    <li><a href="https://dora.dev/research/2025/ai-capabilities-model/" target="_blank" rel="noopener noreferrer">DORA AI Capabilities Model</a> — 7 foundational practices that amplify AI benefits</li>
    <li><a href="https://cloud.google.com/resources/content/dora-roi-of-ai-assisted-software-development" target="_blank" rel="noopener noreferrer">DORA ROI of AI-Assisted Software Development 2026</a> — Framework for measuring AI investment returns</li>
    <li><a href="https://tag-app-delivery.cncf.io/whitepapers/platforms" target="_blank" rel="noopener noreferrer">CNCF Platforms White Paper</a> — Internal developer platform best practices</li>
    <li><a href="https://tag-app-delivery.cncf.io/whitepapers/platform-eng-maturity-model" target="_blank" rel="noopener noreferrer">CNCF Platform Engineering Maturity Model</a> — 5 aspects × 4 levels maturity framework</li>
    <li><a href="https://www.microsoft.com/en-us/research/publication/the-space-of-developer-productivity-theres-more-to-it-than-you-think/" target="_blank" rel="noopener noreferrer">SPACE Framework</a> — Holistic developer productivity measurement</li>
  </ul>
</section>

<p class="maintainer-bio">Built by <a href="https://github.com/paruff">@paruff</a> · <a href="https://www.linkedin.com/in/paruff/">LinkedIn</a> — 20+ years in platform engineering, CI/CD, and developer experience. Building uFawkes to give every team the platform foundation that makes AI delivery actually work.</p>
