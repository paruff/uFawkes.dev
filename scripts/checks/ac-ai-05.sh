#!/usr/bin/env bash
# AC-AI-05: no suite repo's devcontainer uses ufawkesai-devcontainer:latest.
set -euo pipefail

REPOS=(uFawkesAI uFawkesObs uFawkesPipe uFawkesDevX uFawkesDojo fawkes uFawkes.dev)
bad=0
for repo in "${REPOS[@]}"; do
  url="https://raw.githubusercontent.com/paruff/${repo}/main/.devcontainer/devcontainer.json"
  if ! body="$(curl -fsSL "$url")"; then
    echo "$repo: cannot read .devcontainer/devcontainer.json"
    bad=1
    continue
  fi
  if grep -q 'ufawkesai-devcontainer:latest' <<<"$body"; then
    echo "$repo: still uses :latest"
    bad=1
  elif ! grep -qE 'ufawkesai-devcontainer(:2\.0\.0|@sha256:)' <<<"$body"; then
    echo "$repo: does not pin ufawkesai-devcontainer to 2.0.0 or a digest"
    bad=1
  fi
done
exit "$bad"
