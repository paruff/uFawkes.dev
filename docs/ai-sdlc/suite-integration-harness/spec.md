# Spec: Suite integration harness for DORA event capture and Dojo lab grading

**Traces to:** [`intent.md`](intent.md) | **Status:** Draft | **Revision:** 1

## Requirements

**R1. One command, offline.** `make suite-integration-test` builds a pinned
image and runs the suite in a container with `--network none`. The sibling
checkouts (fawkes, uFawkesObs, uFawkesPipe, uFawkesDevX, uFawkesDojo,
uFawkesAI) and this repository are mounted read-only. `SUITE_ROOT` names the
directory that holds them and defaults to the parent of this repository.

**R2. Real code, stub edges.** The suite runs the real code from the
checkouts: each repository's `scripts/emit-dora-event.sh`, uFawkesPipe's
`notify-obs`, `generate-sbom` and `sign-image` step commands, uFawkesObs's
collectors, ingestion API, worker and metric computation, the fawkes
`dora-metrics` service, and the uFawkesDojo `validate.sh` graders. Only the
edges are stubbed: `gh`, `curl`, `docker`, `trivy`, `cosign`, `sleep`, and
the Grafana, Prometheus, Loki and OTLP endpoints.

**R3. Same dependencies as production.** The image uses the Python version
of uFawkesObs's dora-api image and installs uFawkesObs's own
`dora/ingestion/requirements-ingestion.lock`, copied in at build time.

**R4. No waiting on time.** dora-api is served in-process without its
background loops. A test runs the worker and the compute cycle itself. No
test sleeps or polls. Where a bug depends on timing, the test puts the
system in the exact interleaved state instead of racing for it. The one bounded wait is the readiness check for the
dora-api subprocess that the grader tests start. `sleep` is stubbed for the
graders.

**R5. Order independence.** `RUNS=n` repeats the suite n times. Each run
shuffles the tests with a different seed.

**R6. A known bug is a reproduction that passes.** A test body asserts the
correct behaviour. If a bug in a sibling repository breaks it, the test
carries `@pytest.mark.finding("AF-nn")` and the bug is entry AF-nn in
[`AUDIT_FINDINGS.md`](../../../tests/suite-integration/AUDIT_FINDINGS.md).
Such a test passes while its body fails its assertion (or raises the error
the mark names with `raises=`), which means the bug still reproduces. Any
other error fails the test. When the body passes, the test fails, so the fix, the mark and
the entry are removed together. The run ends with a line that counts the
reproductions. `SUITE_ASSERT_FIXED=1` runs every body as written and shows
each finding failing.

**R7. Sibling repositories are never changed.**

## Test criteria

The criteria, T1 to T48, are in
[`tests/suite-integration/SPEC.md`](../../../tests/suite-integration/SPEC.md),
beside the tests that check them.

## Acceptance criteria

- **AC1.** `make suite-integration-test` exits 0 on a machine with Docker
  and the seven checkouts, with the network cable out.
- **AC2.** `RUNS=10 make suite-integration-test` passes every test in all ten
  runs, with the same count of reproductions.
- **AC3.** `SUITE_ASSERT_FIXED=1 make suite-integration-test` fails exactly
  the tests that carry a `finding` mark.
- **AC4.** Every `finding` mark names an entry in `AUDIT_FINDINGS.md`, and
  every entry names a test.
- **AC5.** `git status` in each sibling checkout is unchanged by a run.

## Concerns

- The harness is not in CI. It needs seven checkouts side by side. Until a
  workflow checks them out, it runs on a laptop.
- A reproduction that passes is a bug that is still there. A green run
  means "every behaviour is as recorded", not "everything works". The count
  of reproductions is the number to drive down.
- The graders are tested against stubs for Grafana, Prometheus and Loki. A
  grader that passes here can still fail against the real stack if a real
  endpoint behaves differently from its stub. The nightly live run covers
  that.
