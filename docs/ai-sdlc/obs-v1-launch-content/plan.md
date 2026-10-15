# Plan: uFawkesObs v1.0.0 screenshots and launch post

**Traces to:** issue #66, suite-release AC-OBS-04 (`../suite-release/spec.md`)

Add real screenshots of a running uFawkesObs v1.0.0 to the Obs page and
publish a launch post on the blog. The dev.to and LinkedIn posts come from the
uFawkesAI release agent. The blog post must match them on version and links.

## Verification Strategy

- `make build` succeeds, and `_site/obs/index.html` references all four
  screenshots under `assets/img/obs/`.
- Each screenshot was taken from the `v1.0.0` tag started with `make up-full`.
  Logs and traces are the demo app's own telemetry. The DORA screenshot uses
  sample deployment events, and the page and post say so.
- The post renders at `/blog/ufawkesobs-v1-0-0/` and links the v1.0.0 release.
- After merge, record the blog URL on the release's Project item with the
  dev.to and LinkedIn URLs (AC-OBS-04).
