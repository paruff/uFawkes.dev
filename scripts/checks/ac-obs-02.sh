#!/usr/bin/env bash
# AC-OBS-02: no open release blockers for uFawkesObs v1.0.0.
#
# A blocker is an open Project #7 item in the "Obs 1.0" release carrying the
# `release-blocker` label. Reads $STATUS_ITEMS_JSON (see ac-suite-02.sh).
set -euo pipefail

items="${STATUS_ITEMS_JSON:?STATUS_ITEMS_JSON is not set; run this through scripts/suite-status.sh}"

blockers="$(jq -r '
  .[] | select(.release == "Obs 1.0" and .state == "OPEN" and (.labels | index("release-blocker")))
  | "\(.repo)#\(.number) \(.title[0:70])"' "$items")"

if [[ -n "$blockers" ]]; then
  echo "open release blockers:"
  printf '%s\n' "$blockers"
  exit 1
fi
echo "no open release blockers"
