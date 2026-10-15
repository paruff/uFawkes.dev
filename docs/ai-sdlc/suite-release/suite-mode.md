# Suite mode and system requirements (#70)

## Definition

**Suite mode** is uFawkesObs, uFawkesPipe and uFawkesDevX running together on
one Docker host, each from its own `compose.yaml` on `main`, with no uFawkesRes
dependency (uFawkesPipe#97 closed; DevX database pending uFawkesDevX#57).
Each stack alone is "single-stack mode".

## Status: not measured

Nothing below is a measurement yet. The published table (site and each stack
README) stays empty until the numbers in the Results section are filled from a
real run. Do not publish the issue's starting estimates as requirements.

## Procedure

Clean host, at least 16 GB RAM and 4 vCPUs (the issue's starting estimate, to
be confirmed). Docker Desktop on macOS: raise the VM to the host's limits and
set `vm.max_map_count >= 524288` for SonarQube.

1. Bring up Obs, Pipe and DevX. Wait for all healthchecks.
2. `scripts/measure-suite.sh idle 30 10`
3. Open the Grafana dashboards, start a real Pipe pipeline run, then
   `scripts/measure-suite.sh pipeline-run 90 10`
4. Repeat steps 2–3 for each stack alone.
5. After 24 h: `scripts/measure-suite.sh disk 0`

## Results (fill from the CSVs in `suite-measurements/`)

| Scope      | Idle mem | Peak mem | Idle CPU | Peak CPU | Disk 24 h | Min | Recommended |
| ---------- | -------- | -------- | -------- | -------- | --------- | --- | ----------- |
| Obs alone  |          |          |          |          |           |     |             |
| Pipe alone |          |          |          |          |           |     |             |
| DevX alone |          |          |          |          |           |     |             |
| Suite      |          |          |          |          |           |     |             |

## Remaining work for #70

- [ ] Run the procedure and fill the table
- [ ] Publish the table on ufawkes.dev and in each stack README
- [ ] `deploy.resources` limits and reservations in uFawkesPipe and uFawkesDevX, derived from the results
