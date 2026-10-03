#!/usr/bin/env bash
# AC-SUITE-03: every repo follows, and enforces, the document levels.
#
# On each repo's main: a root INTENT.md, the artifact-chain workflow, and the
# repo's own .artifact-chain-paths. (A repo without the paths file would silently
# check src/, which most of these repos don't have.)
#
# CHECK_RAW_BASE overrides https://raw.githubusercontent.com/paruff (tests).
set -euo pipefail

RAW="${CHECK_RAW_BASE:-https://raw.githubusercontent.com/paruff}"
REPOS=(uFawkes.dev uFawkesAI uFawkesObs uFawkesPipe uFawkesDevX uFawkesDojo fawkes)
FILES=(INTENT.md .github/workflows/artifact-chain.yml .artifact-chain-paths)

bad=0
for repo in "${REPOS[@]}"; do
  for f in "${FILES[@]}"; do
    if ! curl -fsS --max-time 30 -o /dev/null "$RAW/$repo/main/$f" 2> /dev/null; then
      echo "$repo: missing $f on main"
      bad=1
    fi
  done
done
[[ "$bad" -eq 0 ]] && echo "all ${#REPOS[@]} repos have INTENT.md, the artifact-chain workflow and their code paths"
exit "$bad"
