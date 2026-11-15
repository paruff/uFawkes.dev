#!/usr/bin/env bash
# tests/suite-integration/run.sh — run the cross-repo DORA and Dojo grading
# harness in Docker, offline.
#
# The sibling checkouts are mounted read-only and the container has no
# network (--network none): a test can only pass on what is in the checkouts.
#
# Usage: run.sh [pytest args...]
#   SUITE_ROOT  directory holding the checkouts (default: parent of this repo)
#   RUNS        repeat the suite N times, each in a different test order (default 1)
# Exit 0 = every run passed.
set -euo pipefail
cd "$(dirname "$0")"

SUITE_ROOT="${SUITE_ROOT:-$(cd ../../.. && pwd)}"
RUNS="${RUNS:-1}"
IMAGE=ufawkes-suite-integration

mounts=(-v "$(cd ../.. && pwd):/suite/uFawkes.dev:ro")
for repo in fawkes uFawkesObs uFawkesPipe uFawkesDevX uFawkesDojo uFawkesAI; do
  if [ ! -d "$SUITE_ROOT/$repo" ]; then
    echo "run.sh: missing checkout $SUITE_ROOT/$repo (set SUITE_ROOT)" >&2
    exit 2
  fi
  mounts+=(-v "$SUITE_ROOT/$repo:/suite/$repo:ro")
done

cp "$SUITE_ROOT/uFawkesObs/dora/ingestion/requirements-ingestion.lock" .obs.lock
docker build -q -t "$IMAGE" . > /dev/null

for run in $(seq 1 "$RUNS"); do
  echo "── suite-integration run $run/$RUNS (order seed $run) ──"
  docker run --rm --network none --tmpfs /tmp:exec "${mounts[@]}" -e SUITE_SEED="$run" -e SUITE_ASSERT_FIXED="${SUITE_ASSERT_FIXED:-}" "$IMAGE" "$@"
done
