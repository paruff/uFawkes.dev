# Plan: Medium and Low audit findings

The suite integration harness (`tests/suite-integration`) found these bugs.
The fixes live in the repositories each finding names:
[uFawkesObs#724](https://github.com/paruff/uFawkesObs/pull/724),
[uFawkesPipe#234](https://github.com/paruff/uFawkesPipe/pull/234),
[uFawkesDojo#130](https://github.com/paruff/uFawkesDojo/pull/130),
[fawkes#2331](https://github.com/paruff/fawkes/pull/2331),
[uFawkesDevX#158](https://github.com/paruff/uFawkesDevX/pull/158) and
[uFawkesAI#303](https://github.com/paruff/uFawkesAI/pull/303).
This repository drops the finding marks and report entries, and syncs its copy
of the shared `scripts/emit-dora-event.sh`.

## Verification Strategy

- `make suite-integration-test` with the six sibling checkouts on their
  `fix/audit-medium-low` branches: all tests pass and no finding reproduction
  is left. Before the fixes, the same tests with the marks removed fail.
- This PR's harness tests fail against sibling `main` until those PRs merge.
  Merge the sibling PRs first.
- Pre-commit passes on this branch.
