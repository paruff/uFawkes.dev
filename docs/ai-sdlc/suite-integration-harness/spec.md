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

**R6. A known bug is a strict expected failure.** A test asserts the correct
behaviour. If a bug in a sibling repository breaks it, the test carries
`@pytest.mark.finding("AF-nn")` and the bug is entry AF-nn in
[`AUDIT_FINDINGS.md`](../../../tests/suite-integration/AUDIT_FINDINGS.md).
The harness turns the mark into a strict expected failure, so a fixed bug
makes the run fail until the mark and the entry are removed.
`SUITE_NO_XFAIL=1` turns the marks off and shows every finding failing.

**R7. Sibling repositories are never changed.**

## Test criteria

Each row is a behaviour the suite checks. "Finding" names the audit entry
when the behaviour is broken today.

### Ingestion contract (`test_ingestion_contract.py`)

| #    | Criterion                                                                                                         | Finding |
| ---- | ----------------------------------------------------------------------------------------------------------------- | ------- |
| T1   | Every valid deployment, incident, PR and rework fixture is accepted (201), processed once and stored unchanged    |         |
| T2   | Every invalid fixture (73 cases) is rejected (422), names the field, and queues nothing                           |         |
| T3   | A missing required field is named in the error's `loc`                                                            | AF-09   |
| T4   | `pipeline_url` must be a URI                                                                                      | AF-10   |
| T5   | Fixtures agree with the JSON Schema files, so they cannot drift from the contract                                 |         |
| T6   | A batch is all or nothing, and reports the index of the bad event                                                 |         |
| T7   | The same payload sent twice, in any key order, before or after processing, is one event                           |         |
| T8   | With `DORA_API_KEY` set, a missing or wrong token gets 401 and queues nothing. `/health` and `/metrics` stay open |         |
| T9   | `/health` queue depth follows pending events                                                                      |         |
| T10  | An event claimed by a worker that died is processed after a restart                                               | AF-11   |
| T10a | An event posted while the worker is claiming another one is accepted                                              | AF-23   |

### Emitters (`test_emitters.py`)

| #   | Criterion                                                                                                                                     | Finding |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| T11 | `emit-dora-event.sh` is byte-identical in all seven repositories                                                                              | AF-12   |
| T12 | uFawkesPipe's four schema copies and this repository's vendored copy equal uFawkesObs's                                                       | AF-13   |
| T13 | Each repository's deploy marker, under GitHub Actions and Woodpecker variables, is accepted and counted. With PR data, the lead time is exact | AF-12   |
| T14 | A deploy marker with status `failure` or `rollback` counts as a failed change, not a deployment                                               |         |
| T15 | A deployment is never dropped without an error when CI context is missing                                                                     | AF-14   |
| T16 | A deploy marker reaches dora-api                                                                                                              | AF-15   |
| T17 | `job-start` then `job-finish` gives the exact duration                                                                                        |         |
| T18 | The OTLP export carries the event line, and a dead endpoint does not fail the pipeline                                                        |         |
| T19 | uFawkesPipe's `notify-obs` step sends an event dora-api accepts, sends the API key when set, and posts nothing when the URL is unset          |         |
| T20 | Every payload in uFawkesObs's collectors (curl examples, deployment sender, incident scripts) is accepted                                     |         |
| T21 | The fawkes `dora-metrics` service reports exact gauges for a fixed set of merged release PRs                                                  |         |

### Edge cases (`test_dora_edge_cases.py`)

| #   | Criterion                                                                                             | Finding |
| --- | ----------------------------------------------------------------------------------------------------- | ------- |
| T22 | Recovery time is the gap between the failed and the next successful deployment                        |         |
| T23 | Recovery time is the same when the events arrive out of order or in one burst                         | AF-01   |
| T24 | A deployment older than the window does not count when delivered late                                 | AF-01   |
| T25 | A retry that adds an optional field is still one deployment                                           | AF-02   |
| T26 | A failed canary and its rollback are one failed change                                                | AF-03   |
| T27 | Recovery time runs from the failed canary, not from its rollback                                      | AF-03   |
| T28 | A rollback with no later success has no recovery time. Another repository's success does not close it |         |
| T29 | A failed staging deployment does not change production metrics                                        | AF-04   |
| T30 | Lead time is exact across UTC offsets                                                                 |         |
| T31 | A timestamp without a UTC offset is rejected, and can never stop metrics for other teams              | AF-05   |
| T32 | A future-dated deployment is rejected, and lead time is never negative                                | AF-06   |
| T33 | The `/metrics` text has one `TYPE` line per metric and the exact value and tier                       |         |

### Supply chain gate (`test_supply_chain_gate.py`)

| #   | Criterion                                                                                        | Finding |
| --- | ------------------------------------------------------------------------------------------------ | ------- |
| T34 | The SBOM step and the signing step fail the pipeline, with an error event, when their tool fails |         |
| T35 | The deployment event is sent only after the SBOM exists and the image is signed                  | AF-07   |
| T36 | The deployment event waits for the scans, the policy check and the build                         |         |
| T37 | No pipeline step runs an image tagged `latest`                                                   | AF-08   |

### Dojo lab grading (`test_dojo_grading.py`)

Graders covered: white belt module 02 labs 01 and 02, brown belt module 14
lab 01.

| #   | Criterion                                                                                    | Finding      |
| --- | -------------------------------------------------------------------------------------------- | ------------ |
| T38 | With the whole stack up and the lab done, each grader exits 0 with the exact check count     |              |
| T39 | With exactly one thing broken, each grader exits 1 and names that check (one case per check) |              |
| T40 | A learner who sent no event does not pass                                                    | AF-16        |
| T41 | A check that cannot run is a failure, not a silent skip                                      | AF-17        |
| T42 | A metric the grader queries is one dora-api exports                                          | AF-19        |
| T43 | A grader passes only when the metric query returns data                                      | AF-19        |
| T44 | The event a grader's emitter produces is one dora-api accepts                                | AF-12        |
| T45 | A grader finds the Grafana credentials where its instructions say they are                   | AF-18, AF-20 |
| T46 | A grader does not fail a learner for lacking an optional tool                                | AF-21        |
| T47 | A grader's failure message states the real HTTP status                                       | AF-22        |
| T48 | A grader finds a running container however many others the host runs                         | AF-24        |

## Acceptance criteria

- **AC1.** `make suite-integration-test` exits 0 on a machine with Docker
  and the seven checkouts, with the network cable out.
- **AC2.** `RUNS=10 make suite-integration-test` reports the same passed and
  expected-failure counts in all ten runs.
- **AC3.** `SUITE_NO_XFAIL=1 make suite-integration-test` fails exactly the
  tests that carry a `finding` mark.
- **AC4.** Every `finding` mark names an entry in `AUDIT_FINDINGS.md`, and
  every entry names a test.
- **AC5.** `git status` in each sibling checkout is unchanged by a run.

## Concerns

- The harness is not in CI. It needs seven checkouts side by side. Until a
  workflow checks them out, it runs on a laptop.
- An expected failure is a bug that is still there. A green run means
  "nothing new broke", not "everything works". The count of expected
  failures is the number to drive down.
- The graders are tested against stubs for Grafana, Prometheus and Loki. A
  grader that passes here can still fail against the real stack if a real
  endpoint behaves differently from its stub. The nightly live run covers
  that.
