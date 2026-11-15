# Audit findings: DORA event capture and Dojo lab grading

Bugs found by the suite integration harness (`make suite-integration-test`).
Each open finding has at least one test that reproduces it. The test body asserts
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

No findings are open. Every finding the harness has raised was fixed in the
repository it names, and its mark and entry were removed with the fix.

| IDs                  | Fixed in                                              |
| -------------------- | ----------------------------------------------------- |
| AF-01 03 04 05 11 23 | uFawkesObs (#722, #723)                               |
| AF-07 15             | uFawkesPipe (#231)                                    |
| AF-16 17 19 20       | uFawkesDojo (#129)                                    |
| AF-02 06 09 10       | uFawkesObs, `fix/audit-medium-low`                    |
| AF-08 13             | uFawkesPipe, `fix/audit-medium-low`                   |
| AF-14                | emitter, all six repositories, `fix/audit-medium-low` |
| AF-18 21 22 24       | uFawkesDojo, `fix/audit-medium-low`                   |

The last four rows are in open pull requests. Run the suite against those
branches until they merge. The harness keeps no reproductions now; add a
`@pytest.mark.finding("AF-nn")` test and an entry here when it finds the next
bug.
