# Audit findings: DORA event capture and Dojo lab grading

Bugs found by the suite integration harness (`make suite-integration-test`).
Each finding has at least one test that reproduces it. The test body asserts
the correct behaviour and carries `@pytest.mark.finding("AF-nn")`. While the
bug is there the body fails its assertion, and the test passes: the bug
reproduces. Any other error in the body is a harness fault and fails. When
the bug is fixed the body passes and the test fails, so the mark and the
entry here are removed together with the fix.

To see every finding fail for real, run
`SUITE_ASSERT_FIXED=1 make suite-integration-test`.

Nothing in the sibling repositories was changed. Fixes belong to the
repository named in each finding.

## Result

382 tests, all passing. 38 of them are reproductions of the 11 findings
below, so a green run means "every behaviour is as recorded here", not
"everything works". With `SUITE_ASSERT_FIXED=1` those 38 fail and the other
344 pass.

The eleven High findings and AF-20 were fixed in the sibling repositories
(see their pull requests) and their marks and entries removed. The rest are
open. The suite was last run against `origin/main` of each repository with
those fixes applied.

AF-24 first showed up as a test that failed about one run in ten. It was a
real race in the code under test and now has a test that sets up the
interleaving directly instead of waiting for it to happen.

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

| ID    | Severity | Repository  | Finding                                                                        |
| ----- | -------- | ----------- | ------------------------------------------------------------------------------ |
| AF-02 | Medium   | uFawkesObs  | A retry that differs in one optional field counts the deployment twice         |
| AF-06 | Medium   | uFawkesObs  | Future-dated deployments and negative lead times are accepted                  |
| AF-08 | Medium   | uFawkesPipe | The signing step runs `bitnami/cosign:latest`                                  |
| AF-09 | Low      | uFawkesObs  | A missing required field is not named in the error location                    |
| AF-10 | Low      | uFawkesObs  | `pipeline_url` is never checked as a URI                                       |
| AF-13 | Medium   | uFawkesPipe | The deployment schema copy lacks two fields the shared emitter sends           |
| AF-14 | Medium   | six repos   | A deploy marker with no commit SHA or pipeline URL is dropped without an error |
| AF-18 | Medium   | uFawkesDojo | White belt lab 02 never reads the `.env` it tells the learner to rely on       |
| AF-21 | Medium   | uFawkesDojo | White belt lab 02 fails without `gh`, which it calls optional                  |
| AF-22 | Low      | uFawkesDojo | A refused connection is reported as `HTTP 000000`                              |
| AF-24 | Low      | uFawkesDojo | White belt lab 02 can report a running container as not running                |

## Findings

### AF-02 A retry that differs in one optional field counts twice (Medium, uFawkesObs)

Deduplication hashes the whole payload (`dora/ingestion/api/idempotency.py:12`).
The same deployment sent again with `deploy_duration_seconds` added is a new
row, so deployment frequency doubles.

Test: `test_dora_edge_cases.py::test_retry_that_adds_an_optional_field_is_still_one_deployment`.

Fix: key deployments on repo, service, environment, commit SHA, status and
`deployed_at`.

### AF-06 Future-dated deployments and negative lead times are accepted (Medium, uFawkesObs)

A deployment dated a year ahead is accepted and counted. A deployment whose
`first_commit_at` is after `deployed_at` is accepted and gives a lead time of
-4.0 hours, which pulls the median down and classifies as "elite".

Tests: `test_dora_edge_cases.py::test_deployment_dated_in_the_future_is_rejected`,
`::test_first_commit_after_the_deployment_cannot_yield_a_negative_lead_time`.

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

### AF-18 White belt lab 02 never reads the `.env` it relies on (Medium, uFawkesDojo)

The grader changes directory into the uFawkesAI checkout (`validate.sh:80`)
and later looks for `./.env` to find the Grafana password (`:177`). By then
`./.env` is uFawkesAI's, not the one beside the uFawkesObs stack. The
dashboard check falls back to `admin:admin` and fails with 401 on any stack
with a real password, unless `GRAFANA_ADMIN_PASSWORD` is exported.

Test: `test_dojo_grading.py::test_lab2_dotenv_in_cwd_is_read`.

### AF-21 White belt lab 02 fails without `gh`, which it calls optional (Medium, uFawkesDojo)

`check_cmd gh || log_skip "gh (GitHub CLI) not installed; PR metadata will
be limited"`. `check_cmd` has already counted a failure before the skip
message prints, so a learner without `gh` gets 15 of 16 and exit 1.

Test: `test_dojo_grading.py::test_lab2_passes_without_the_optional_gh_cli`.

### AF-22 A refused connection is reported as `HTTP 000000` (Low, uFawkesDojo)

The brown belt grader uses `curl -w "%{http_code}" ... || echo "000"`. On a
refused connection curl prints `000` and exits non-zero, so the fallback adds
a second `000`. Cosmetic, but it is in the message the learner reads.

Test: `test_dojo_brown.py::test_brown_reports_a_refused_connection_as_http_000`.

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
