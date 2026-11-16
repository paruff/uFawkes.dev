# Plan: audit the job stamps exactly

**Traces to:** paruff/uFawkes.dev#228, paruff/uFawkes.dev#230 | **Status:** In review

`make ci-determinism-audit` reports `job_stamps` for PI-9: a job with steps must start
with a `job-start` step and end with a `job-finish` step that runs `if: always()`.
The first version matched by substring, so `no-job-start-here` and `if: !always()`
counted. This plan tightens the match.

| Step | What                                                                                     |
| ---- | ---------------------------------------------------------------------------------------- |
| S1   | The first step name starts with `job-start`, the last with `job-finish`                  |
| S2   | The last step's `if` is exactly `always()` or `${{ always() }}`                          |
| S3   | Fixtures cover a look-alike name, `!always()` on its own, and the `${{ always() }}` form |

## Verification Strategy

| Check                                          | How                                                                      |
| ---------------------------------------------- | ------------------------------------------------------------------------ |
| Exact match accepts and rejects the right jobs | `bash scripts/test-ci-determinism-audit.sh` (clean, messy fixtures)      |
| The spec still names every departure           | `make ci-determinism-audit`, compared with the spec's "Known departures" |
| Not covered yet                                | A live run of the audit with this change (the per-repo counts may move)  |
