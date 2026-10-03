#!/usr/bin/env bash
# AC-SUITE-02: every open issue on Project #7 carries exactly one routing label
# (goal, model:nemotron-3-ultra or model:mimo-v2.6-flash).
#
# Reads $STATUS_ITEMS_JSON, the Project items suite-status.sh already fetched,
# so this check and the dashboard always look at the same data.
set -euo pipefail

items="${STATUS_ITEMS_JSON:?STATUS_ITEMS_JSON is not set; run this through scripts/suite-status.sh}"

bad="$(jq -r '
  def routing: [.labels[] | select(. == "goal" or . == "model:nemotron-3-ultra" or . == "model:mimo-v2.6-flash")];
  .[] | select(.state == "OPEN") | select((routing | length) != 1)
  | "\(.repo)#\(.number) has \(routing | length) routing labels: \(.title[0:60])"' "$items")"

if [[ -n "$bad" ]]; then
  printf '%s\n' "$bad"
  exit 1
fi
echo "$(jq '[.[] | select(.state == "OPEN")] | length' "$items") open issues, each with exactly one routing label"
