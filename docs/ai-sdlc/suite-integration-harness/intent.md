# Intent: Suite integration harness for DORA event capture and Dojo lab grading

**Status:** Draft | **Owner:** @paruff

## Problem

A deployment becomes a DORA number by crossing repositories. A pipeline in
uFawkesPipe, uFawkesDevX or fawkes emits an event, uFawkesObs validates and
stores it and computes the metrics, and a uFawkesDojo grader reads those
metrics to decide whether a learner passed a lab. Each repository tests its
own part. Nothing tests the path between them, so a schema copy can drift, an
emitter can send a field the API refuses, and a grader can pass a learner who
did nothing, and every repository's own tests stay green.

The existing end-to-end checks need a running stack (`make up-dora`, a
nightly live run, or a cluster). They are slow, they depend on timing, and
they cannot run on a pull request.

## Desired outcome

One command runs on a laptop with Docker and no network, takes seconds, and
gives the same result every time. It runs the real emitters, the real
ingestion API and the real graders from the sibling checkouts, and it says
which cross-repository behaviours work and which are broken.

## Users

- A maintainer changing an event schema, an emitter, the ingestion API or a
  grader, who needs to know what the change breaks in the other repositories.
- An agent working a suite issue, which needs a check it can run and trust.

## Constraints

- No cluster, no cloud account, no running stack, no network at test time.
- Sibling repositories are read, never written. A bug found there is
  reported, not patched from here.
- No test may wait on a clock. A test that needs time to pass is driving
  the wrong thing.
- Tools run in Docker, not on the host.

## Where it lives

`tests/suite-integration/` in this repository, which already holds the
suite-wide checks. Run with `make suite-integration-test`.

## Out of scope

- Fixing the bugs it finds. They are listed in
  [`AUDIT_FINDINGS.md`](../../../tests/suite-integration/AUDIT_FINDINGS.md)
  for the owning repositories.
- Grafana dashboards, Prometheus rules and Loki queries against a live stack.
  The nightly live run keeps covering those.
- Wiring the harness into CI. It needs all seven checkouts, which CI here
  does not have yet.
