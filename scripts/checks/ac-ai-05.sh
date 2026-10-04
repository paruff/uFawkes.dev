#!/usr/bin/env bash
# AC-AI-05: every suite repo's devcontainer pins the released image,
# fawkes-space:2.0.0 (optionally with its digest): not :latest, and not a
# pre-release such as 2.0.0-rc.3. The image was ufawkesai-devcontainer until
# uFawkesAI renamed it.
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
  pinned="$(grep -oE 'fawkes-space:[^"@]+' <<< "$body" | head -1)"
  if [[ -z "$pinned" ]]; then
    echo "$repo: does not use ghcr.io/paruff/fawkes-space"
    bad=1
  elif [[ "$pinned" != "fawkes-space:2.0.0" ]]; then
    echo "$repo: pins ${pinned}, not the released fawkes-space:2.0.0"
    bad=1
  fi
done
exit "$bad"
