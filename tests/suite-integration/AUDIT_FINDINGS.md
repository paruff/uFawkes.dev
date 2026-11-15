# Audit findings: DORA event capture and Dojo lab grading

Bugs found by the suite integration harness (`make suite-integration-test`).
Each finding is pinned by at least one test that asserts the correct
behaviour and carries `@pytest.mark.finding("AF-nn")`. The mark makes the test
an expected failure, and it is strict: when the bug is fixed the test passes,
the run turns red, and the mark and the entry here are removed together.

To see every finding fail for real, run
`SUITE_NO_XFAIL=1 make suite-integration-test`.

Nothing in the sibling repositories was changed. Fixes belong to the
repository named in each finding.

## Result

381 tests. 312 pass. 69 are expected failures that pin the 24 findings below.
`RUNS=10 make suite-integration-test` gave these same counts in all ten
runs, each in a different test order. With `SUITE_NO_XFAIL=1` the same 69
tests fail and the same 312 pass.

Two of the findings (AF-23, AF-24) first showed up as tests that failed about
one run in ten. Both were real races in the code under test. Each is now
pinned by a test that sets up the interleaving directly instead of waiting
for it to happen.

## Checkouts audited

| Repository  | Commit     | Branch                                              |
| ----------- | ---------- | --------------------------------------------------- |
| fawkes      | `563149f9` | `main`                                              |
| uFawkesObs  | `90f06f2`  | `dependabot/pre_commit/pre-commit-hooks-de5fce9587` |
| uFawkesPipe | `d019b94`  | `main`                                              |
| uFawkesDevX | `f2ad92f`  | `docs/standard-spec-sections`                       |
| uFawkesDojo | `be44e56`  | `feat/pages-suite-tokens`                           |
| uFawkesAI   | `41aa00a`  | `docs/global-agents-intent-pointer`                 |

fawkes and uFawkesPipe are at `origin/main`. The other four are on feature
branches: rerun against `main` before opening issues for those repositories.
The harness tests whatever is checked out, so a checkout that moves between
runs can change the result.

## Summary

| ID    | Severity | Repository  | Finding                                                                            |
| ----- | -------- | ----------- | ---------------------------------------------------------------------------------- |
| AF-01 | High     | uFawkesObs  | Metrics order and window events by arrival time, not by when they happened         |
| AF-02 | Medium   | uFawkesObs  | A retry that differs in one optional field counts the deployment twice             |
| AF-03 | High     | uFawkesObs  | A failed canary and its rollback count as two failures, and recovery time is short |
| AF-04 | High     | uFawkesObs  | Staging and test deployments count as production                                   |
| AF-05 | Critical | uFawkesObs  | One timestamp without a UTC offset stops metrics for every team                    |
| AF-06 | Medium   | uFawkesObs  | Future-dated deployments and negative lead times are accepted                      |
| AF-07 | High     | uFawkesPipe | The deployment event does not wait for the SBOM or the signature                   |
| AF-08 | Medium   | uFawkesPipe | The signing step runs `bitnami/cosign:latest`                                      |
| AF-09 | Low      | uFawkesObs  | A missing required field is not named in the error location                        |
| AF-10 | Low      | uFawkesObs  | `pipeline_url` is never checked as a URI                                           |
| AF-11 | High     | uFawkesObs  | An event claimed by a worker that then dies is never processed                     |
| AF-12 | High     | uFawkesAI   | Its emitter has drifted from the other six, and dora-api rejects its deployments   |
| AF-13 | Medium   | uFawkesPipe | The deployment schema copy lacks two fields the shared emitter sends               |
| AF-14 | Medium   | six repos   | A deploy marker with no commit SHA or pipeline URL is dropped without an error     |
| AF-15 | High     | six repos   | The shared emitter never sends its deployment event to dora-api                    |
| AF-16 | High     | uFawkesDojo | White belt lab 01 passes a learner who never sent an event                         |
| AF-17 | High     | uFawkesDojo | A check that cannot run is skipped, and the grader still passes                    |
| AF-18 | Medium   | uFawkesDojo | White belt lab 02 never reads the `.env` it tells the learner to rely on           |
| AF-19 | High     | uFawkesDojo | The brown belt grader queries metrics that do not exist, and passes on empty data  |
| AF-20 | Low      | uFawkesDojo | The brown belt grader's default stack path is never expanded                       |
| AF-21 | Medium   | uFawkesDojo | White belt lab 02 fails without `gh`, which it calls optional                      |
| AF-22 | Low      | uFawkesDojo | A refused connection is reported as `HTTP 000000`                                  |
| AF-23 | High     | uFawkesObs  | A valid event gets HTTP 500 when it arrives while the worker is busy               |
| AF-24 | Low      | uFawkesDojo | White belt lab 02 can report a running container as not running                    |

## Findings

### AF-01 Metrics order and window events by arrival time (High, uFawkesObs)

The worker stamps `raw_events.recorded_at` with the time the event was
processed (`dora/ingestion/api/queue_sqlite.py:295`). Deployment frequency,
change failure rate, rework rate and recovery time all window and order on
that column (`dora/compute/metrics_db_sqlite.py:128-131`, `:229-239`). The
event's own `deployed_at` is used only for lead time.

What goes wrong:

- A failure deployed at 10:00 and a recovery deployed at 12:00, delivered in
  the opposite order, give no recovery time at all. Expected 2.0 hours.
- The same two events delivered in one burst give a recovery time of 0.0
  hours, which is tier "elite".
- A deployment from 90 days ago delivered today counts in the 30-day window.

`scripts/backfill_dora_from_github.py:11` already notes this limit for
backfills. It also affects any CI retry, any queue backlog and any outage of
dora-api, because all of them deliver events late.

Tests: `test_dora_edge_cases.py::test_recovery_time_when_the_recovery_arrives_before_the_failure`,
`::test_recovery_time_when_both_events_arrive_in_one_burst`,
`::test_deployment_older_than_the_window_is_not_counted_when_delivered_late`.

Fix: store the event's own timestamp (`deployed_at`, `occurred_at`,
`triggered_at`) in `recorded_at` and keep the arrival time in `ingested_at`,
which the table already has.

### AF-02 A retry that differs in one optional field counts twice (Medium, uFawkesObs)

Deduplication hashes the whole payload (`dora/ingestion/api/idempotency.py:12`).
The same deployment sent again with `deploy_duration_seconds` added is a new
row, so deployment frequency doubles.

Test: `test_dora_edge_cases.py::test_retry_that_adds_an_optional_field_is_still_one_deployment`.

Fix: key deployments on repo, service, environment, commit SHA, status and
`deployed_at`.

### AF-03 A failed canary and its rollback are counted as two failures (High, uFawkesObs)

Change 1 ships, change 2's canary fails and is rolled back, change 3 fixes
it. That is one failed change in three.

- Change failure rate is reported as 0.5 (two failures in four events).
  Expected 1/3. `dora/compute/metrics_db_sqlite.py:254-257` counts events,
  not changes.
- Recovery time is reported as 1.5 hours, measured from the rollback.
  Expected 2.0 hours, from the failed deployment to the next success, which
  is the definition in the function's own docstring (`:213-214`). The loop
  at `:230-235` only looks at the event directly after a failure, and that
  event is the rollback.

Tests: `test_dora_edge_cases.py::test_failed_canary_and_its_rollback_are_one_failed_change`,
`::test_recovery_time_runs_from_the_failed_canary_not_from_its_rollback`.

### AF-04 Staging and test deployments count as production (High, uFawkesObs)

`_deployment_rows` (`dora/compute/metrics_db_sqlite.py:128-131`) has no
filter on `environment`. A failed staging deployment raises the production
change failure rate from 0 to 0.5. ADR-006 defines every metric over
`production`.

The Dojo brown-belt grader posts a deployment with `"environment": "test"`
on every run, so each grading run adds a deployment to the stack's metrics.

Test: `test_dora_edge_cases.py::test_failed_staging_deployment_does_not_count_against_production`.

### AF-05 One timestamp without a UTC offset stops metrics for every team (Critical, uFawkesObs)

The `date-time` check is `datetime.fromisoformat`
(`dora/ingestion/api/validator.py:19-25`). It accepts `2026-11-10T10:00:00`
(no offset) and `2026-11-10` (date only). RFC 3339, which JSON Schema's
`date-time` means, requires an offset.

When an accepted deployment has one timestamp with an offset and one without,
lead time raises `TypeError: can't subtract offset-naive and offset-aware
datetimes` (`dora/compute/metrics_db_sqlite.py:178`). The exception aborts
the whole compute cycle. `/metrics` stops updating for every team, on every
cycle, until the event leaves the window 30 days later. Any client that can
post an event can do this with one request.

Tests: `test_dora_edge_cases.py::test_timestamp_without_a_utc_offset_is_rejected`
(four cases), `::test_one_event_with_a_naive_timestamp_does_not_stop_metrics_for_every_team`.

Fix: reject timestamps without an offset at validation. Also make the
compute cycle skip a row it cannot parse, so one bad row cannot stop the rest.

### AF-06 Future-dated deployments and negative lead times are accepted (Medium, uFawkesObs)

A deployment dated a year ahead is accepted and counted. A deployment whose
`first_commit_at` is after `deployed_at` is accepted and gives a lead time of
-4.0 hours, which pulls the median down and classifies as "elite".

Tests: `test_dora_edge_cases.py::test_deployment_dated_in_the_future_is_rejected`,
`::test_first_commit_after_the_deployment_cannot_yield_a_negative_lead_time`.

### AF-07 The deployment event does not wait for the SBOM or the signature (High, uFawkesPipe)

In `.woodpecker.yml`, `notify-obs` depends on `upload-defectdojo`, which
depends on `build-image` (`:450`, `:499`). `generate-sbom` and `sign-image`
are on a separate branch of the graph (`:411`, `:429`). Both steps do fail
the pipeline when their tool fails, which the harness confirms. But
`notify-obs` can run before or alongside them, so a build whose signing then
fails has already been recorded as a successful production deployment.

Tests: `test_supply_chain_gate.py::test_deployment_event_is_only_sent_after_the_image_is_attested`
(two cases).

Fix: `depends_on: [upload-defectdojo, sign-image]` on `notify-obs`.

Related gap, not a bug: the deployment event schema has no field for an SBOM
digest or a signature, and `additionalProperties: false` refuses one. The
metrics cannot tell an attested deployment from an unattested one.

### AF-08 The signing step runs `bitnami/cosign:latest` (Medium, uFawkesPipe)

`.woodpecker.yml:428`. The repository's own policy `policy/no-latest-tag.rego`
forbids this for compose services. The step that signs releases is the one
step that should not change under you.

Test: `test_supply_chain_gate.py::test_no_pipeline_step_runs_an_unpinned_latest_image`.

### AF-09 A missing required field is not named in the error location (Low, uFawkesObs)

For a missing field the 422 response has `"loc": ["body"]`, and the field
name appears only inside the message text. Every other error has
`"loc": ["body", "<field>"]`. `dora/ingestion/api/validator.py:84-90` builds
`loc` from the error path, which is empty for `required` errors.

Test: `test_ingestion_contract.py::test_missing_required_field_is_named_in_the_error_location`
(27 cases).

### AF-10 `pipeline_url` is never checked as a URI (Low, uFawkesObs)

The schema says `"format": "uri"`. Only a `date-time` checker is registered
(`dora/ingestion/api/validator.py:28-29`), so `"not a uri"` is accepted.

Test: `test_ingestion_contract.py::test_pipeline_url_that_is_not_a_uri_is_rejected`.

### AF-11 An event claimed by a worker that then dies is never processed (High, uFawkesObs)

`dequeue_next` sets the row to `processing`
(`dora/ingestion/api/queue_sqlite.py:220-229`) and only ever selects
`pending` rows. If the container stops between the claim and `mark_done`,
the row stays `processing` for good. The deployment is lost without a log
line, and the queue depth on `/health` does not show it. A resend does not
help either: the payload hash matches the stuck row, so the API answers 201
with the old id.

Test: `test_ingestion_contract.py::test_event_claimed_by_a_worker_that_died_is_processed_after_restart`.

Fix: on startup, set every `processing` row back to `pending`. The worker
runs in-process, so no other worker can own one.

### AF-12 uFawkesAI's emitter has drifted and its deployments are rejected (High, uFawkesAI)

`scripts/emit-dora-event.sh` is byte-identical in fawkes, uFawkesObs,
uFawkesPipe, uFawkesDevX, uFawkesDojo and uFawkes.dev. The uFawkesAI copy
differs: it adds `--repo` and `--deployment-intent`, and it puts
`deployment_intent` into `dora_event` (`scripts/emit-dora-event.sh:231-236`).
The deployment schema has `additionalProperties: false`, so dora-api answers
422: `Additional properties are not allowed ('deployment_intent' was
unexpected)`.

The Dojo white-belt lab 02 grader calls the emitter with those two flags, so
it only works with the uFawkesAI copy.

Tests: `test_emitters.py::test_emit_script_identical_to_obs[uFawkesAI]`,
`::test_github_deploy_marker_is_ingested_with_lead_time[uFawkesAI]`,
`::test_woodpecker_deploy_marker_without_gh_is_ingested[uFawkesAI]`.

Fix: decide whether `deployment_intent` belongs in the contract. If yes, add
it to the schema in uFawkesObs and uFawkesPipe and sync the emitter to all
seven repositories. If no, remove it from `dora_event`.

### AF-13 uFawkesPipe's deployment schema copy lacks two fields (Medium, uFawkesPipe)

`contracts/dora-events/deployment-event.schema.json` has no `first_commit_at`
or `pr_merged_at`. uFawkesObs's schema has both, and the shared emitter sends
both. Pipe's own emitter therefore produces events that Pipe's own published
contract forbids. `docs/dora-contract.md` already says the two copies are not
kept in sync by anything. The incident, PR and rework schemas match.

Test: `test_emitters.py::test_pipe_schema_matches_obs[deployment]`.

### AF-14 A deploy marker with no commit SHA or pipeline URL is dropped (Medium, the six repositories with the shared emitter)

Outside a git checkout and without `GITHUB_SHA` or `CI_COMMIT_SHA`, the
emitter exits 0 and prints an event whose `dora_event` has no `commit_sha`
and no `pipeline_url`, because null fields are removed
(`scripts/emit-dora-event.sh`, the `with_entries(select(.value != null))`
line). Both are required, so dora-api answers 422. The emitter reported
success, and the deployment is not counted.

Test: `test_emitters.py::test_deploy_without_sha_or_pipeline_url_is_not_lost`.

Fix: make `deploy-marker` exit non-zero when it cannot build a valid event.

### AF-15 The shared emitter never sends its event to dora-api (High, the six repositories with the shared emitter)

`deploy-marker` writes its line to stdout, to a file and to OTLP logs, which
uFawkesObs routes to Loki. Only `POST /event` on dora-api feeds the DORA
metrics, and nothing in uFawkesObs reads `dora_event` out of Loki and
forwards it. A repository that relies on the emitter alone has deploy
markers in its logs and no deployments in its metrics. Today deployments
reach the metrics only through uFawkesPipe's `notify-obs` step and the
workflows under `uFawkesObs/dora/collectors/`.

Test: `test_emitters.py::test_deploy_marker_reaches_the_dora_api`.

Fix: have `deploy-marker` POST `dora_event` to `${DORA_INGESTION_URL}/event`
when that variable is set, the way `notify-obs` does.

### AF-16 White belt lab 01 passes a learner who never sent an event (High, uFawkesDojo)

`white-belt/module-02-dora-metrics/lab-01/validate.sh` tells the learner
"You've seen real DORA metrics move because of events you sent yourself."
The grader checks only that containers run and that `/health`, `/metrics`
and two dashboards answer 200 (`:98-111`). On a stack that has just started,
with an empty queue and an empty `/metrics` body, it reports 8 of 8.

Test: `test_dojo_grading.py::test_lab1_zero_events_must_not_pass`.

Fix: require at least one `dora_deployment_frequency_per_week` sample on
`/metrics`.

### AF-17 A check that cannot run is skipped, and the grader still passes (High, uFawkesDojo)

Three graders turn "could not check" into a warning that is not counted:

- White belt lab 01 skips both dashboard checks when `./.env` is missing
  (`validate.sh:130-135`). It passes with no dashboards provisioned.
- Brown belt module 14 skips the Grafana dashboard check when it finds no
  credentials (`validate.sh:213-218`). It passes with no DORA dashboard.
- White belt lab 02 treats "Loki not reachable" as a skip
  (`validate.sh:164-166`). It passes and congratulates the learner on having
  "proved it reached Loki".

Tests: `test_dojo_grading.py::test_lab1_no_env_must_not_pass`,
`::test_brown_no_credentials_must_not_pass`,
`::test_lab2_loki_down_must_not_pass`.

### AF-18 White belt lab 02 never reads the `.env` it relies on (Medium, uFawkesDojo)

The grader changes directory into the uFawkesAI checkout (`validate.sh:80`)
and later looks for `./.env` to find the Grafana password (`:177`). By then
`./.env` is uFawkesAI's, not the one beside the uFawkesObs stack. The
dashboard check falls back to `admin:admin` and fails with 401 on any stack
with a real password, unless `GRAFANA_ADMIN_PASSWORD` is exported.

Test: `test_dojo_grading.py::test_lab2_dotenv_in_cwd_is_read`.

### AF-19 The brown belt grader queries metrics that do not exist (High, uFawkesDojo)

`brown-belt/module-14-dora-deep-dive/lab-01/validate.sh` queries
`dora_deployment_frequency`, `dora_lead_time_seconds`,
`dora_change_failure_rate`, `dora_mttr_seconds` and `dora_rework_rate`.
dora-api exports `dora_deployment_frequency_per_week`,
`dora_lead_time_p50_hours`, `dora_lead_time_p95_hours`, `dora_fdrt_p50_hours`,
`dora_cfr_pct` and `dora_rework_rate_pct`. None of the five names exists.

The grader does not notice. It accepts HTTP 200 with `"status": "success"`
(`:187-189`, `:295-302`), which Prometheus returns for any well-formed
query, including one with no data. With every query returning an empty
result, the grader reports 9 of 9. The "Event Ingestion → Metrics" check
filters on a `commit_sha` label that no DORA metric carries, so it can only
ever see an empty result, and it passes too.

Tests: `test_dojo_grading.py::test_brown_metric_name_is_exported_by_dora_api`
(five cases), `::test_brown_empty_prometheus_result_must_not_pass`.

### AF-20 The brown belt grader's default stack path is never expanded (Low, uFawkesDojo)

`UF_OBS_DIR="${UF_OBS_DIR:-~/dojo-labs/uFawkesObs}"` (`validate.sh:27`). A
tilde inside quotes is not expanded, so the documented default `.env` is
never found. Together with AF-17 the dashboard check is then skipped.

Test: `test_dojo_grading.py::test_brown_default_uf_obs_dir_is_read`.

Fix: `$HOME/dojo-labs/uFawkesObs`.

### AF-21 White belt lab 02 fails without `gh`, which it calls optional (Medium, uFawkesDojo)

`check_cmd gh || log_skip "gh (GitHub CLI) not installed; PR metadata will
be limited"`. `check_cmd` has already counted a failure before the skip
message prints, so a learner without `gh` gets 15 of 16 and exit 1.

Test: `test_dojo_grading.py::test_lab2_passes_without_the_optional_gh_cli`.

### AF-22 A refused connection is reported as `HTTP 000000` (Low, uFawkesDojo)

The brown belt grader uses `curl -w "%{http_code}" ... || echo "000"`. On a
refused connection curl prints `000` and exits non-zero, so the fallback adds
a second `000`. Cosmetic, but it is in the message the learner reads.

Test: `test_dojo_grading.py::test_brown_reports_a_refused_connection_as_http_000`.

### AF-23 A valid event gets HTTP 500 when it arrives while the worker is busy (High, uFawkesObs)

The API handlers and the in-process worker share one SQLite connection
(`dora/ingestion/api/queue_sqlite.py:48`, `:123-132`), and every operation
ends with a commit on it. The worker claims an event with
`UPDATE ... RETURNING` (`:220-229`). If a `POST /event` commits between that
statement and the worker reading its row, SQLite refuses:
`OperationalError: cannot commit transaction - SQL statements in progress`.
The client gets a 500 for a valid event.

This is how the harness found it: the brown belt grader posts two events in
a row, and about one run in ten the second one got a 500. With 400 events
posted at once against a running worker, 39, 221 and 335 of them failed in
three runs. An emitter that does not retry (uFawkesPipe's `notify-obs` only
logs a warning) loses the deployment.

The module's docstring says a single shared connection means "there is no
multi-writer contention to guard against". The contention is between
coroutines, not connections.

Test: `test_ingestion_contract.py::test_event_posted_while_the_worker_is_claiming_another_is_accepted`.

Fix: an `asyncio.Lock` around `_connect()`, or a second connection for the
worker.

### AF-24 White belt lab 02 can report a running container as not running (Low, uFawkesDojo)

`docker ps --format '{{.Names}}' | grep -q "^${name}$"` under
`set -o pipefail` (`validate.sh:50`). `grep -q` exits at the first match. If
`docker` writes anything after that, it is killed by SIGPIPE, the pipeline
counts as failed, and the grader prints "container is NOT running" for a
container that is running. It needs `docker ps` output large enough to
arrive in more than one write, so it is unlikely on a learner's laptop.
Lab 01 and the brown belt grader filter by name first and are not affected.

Test: `test_dojo_grading.py::test_lab2_finds_its_containers_on_a_host_that_runs_many`.

Fix: `docker ps --filter "name=^${name}$" --format '{{.Names}}' | grep -q .`,
or compare the output in a variable.
