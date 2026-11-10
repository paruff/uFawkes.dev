#!/usr/bin/env bash
# AC-AI-05: no suite repo's devcontainer uses fawkes-space:latest.
#
# CHECK_RAW_BASE overrides https://raw.githubusercontent.com/paruff (tests).
set -euo pipefail

REPOS=(uFawkesAI uFawkesObs uFawkesPipe uFawkesDevX uFawkesDojo fawkes uFawkes.dev)
bad=0
for repo in "${REPOS[@]}"; do
  url="${CHECK_RAW_BASE:-https://raw.githubusercontent.com/paruff}/${repo}/main/.devcontainer/devcontainer.json"
  if ! body="$(curl -fsSL "$url")"; then
    echo "$repo: cannot read .devcontainer/devcontainer.json"
    bad=1
    continue
  fi
  if grep -q 'fawkes-space:latest' <<< "$body"; then
    echo "$repo: still uses :latest"
    bad=1
  # A digest pins, with or without a version tag in front (:2.2.0@sha256:...).
  elif ! grep -qE 'fawkes-space(:[0-9][^@"]*)?@sha256:|fawkes-space:2\.0\.0' <<< "$body"; then
    echo "$repo: does not pin fawkes-space to 2.0.0 or by digest (e.g. :2.2.0@sha256:...)"
    bad=1
  fi
done
exit "$bad"
