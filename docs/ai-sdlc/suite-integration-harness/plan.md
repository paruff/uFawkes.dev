# Plan: Suite integration harness for DORA event capture and Dojo lab grading

**Traces to:** [`spec.md`](spec.md) | **Status:** Draft

## Order of work

1. Runner: a pinned image, the checkouts mounted read-only, no network, and
   the real dora-api driven in-process (`run.sh`, `harness/obs.py`).
2. Mock emitters and fixtures: builders for the four event types, valid and
   invalid payloads, a stub `gh`, recording `curl` and loopback HTTP stubs.
3. Tests of the ingestion contract, the emitters in each repository and the
   Dojo graders.
4. Edge cases: late and out-of-order events, failed canaries and rollbacks,
   malformed timestamps, missing SBOMs and signatures.
5. Run the suite repeatedly in shuffled order until every run is identical.
6. Write up each bug found and open an issue in the repository that owns it.

## Verification Strategy

- `make suite-integration-test` exits 0.
- `RUNS=10 make suite-integration-test` passes every test in all ten
  runs, each in a different test order, with the same count of reproductions.
- `SUITE_ASSERT_FIXED=1 make suite-integration-test` fails on exactly the tests
  that carry a `finding` mark. This shows each finding is a real failure and
  not a test that is skipped.
- Every finding in `AUDIT_FINDINGS.md` names at least one test, and every
  `finding` mark names an entry that exists.

## Risks

- **A sibling checkout is on a feature branch.** The harness tests what is
  checked out. `AUDIT_FINDINGS.md` records the commit of each repository it
  ran against.
- **A fixed bug turns the run red.** That is intended: a reproduction
  fails once its bug is gone, so the fix and the removal of the mark land
  together.
