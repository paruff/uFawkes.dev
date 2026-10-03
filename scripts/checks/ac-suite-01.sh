#!/usr/bin/env bash
# AC-SUITE-01: no public entry point presents a retired name as current.
#
# Scope (owner decision, 2026-10-02): each repo's README.md and INTENT.md, and
# the ufawkes.dev pages. The wider docs belong to the later phases.
# A line passes when it explains the mention (see retired-terms.py) or is on the
# reviewed allowlist, ac-suite-01.allow.
#
# CHECK_RAW_BASE overrides https://raw.githubusercontent.com/paruff (tests).
set -euo pipefail
cd "$(dirname "$0")/../.."

TERMS='jenkins|ufawkesres|ufawkesdora|ufawkessec|four key metrics'
RAW="${CHECK_RAW_BASE:-https://raw.githubusercontent.com/paruff}"
REPOS=(uFawkes.dev uFawkesAI uFawkesObs uFawkesPipe uFawkesDevX uFawkesDojo fawkes)
HERE="$(pwd)/scripts/checks"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

items=()
fetch() { # fetch <repo> <path>  -> adds a LABEL=file item
  local out="$TMP/$1__${2//\//_}"
  if curl -fsS --max-time 30 "$RAW/$1/main/$2" -o "$out" 2> /dev/null; then
    items+=("$1:$2=$out")
  else
    echo "$1: cannot read $2 from main"
    return 1
  fi
}

missing=0
for repo in "${REPOS[@]}"; do
  fetch "$repo" README.md || missing=1
  fetch "$repo" INTENT.md || missing=1
done

# The site's own pages: list them from the repo tree, then fetch each.
pages="$(gh api "repos/paruff/uFawkes.dev/git/trees/main?recursive=1" \
  --jq '.tree[].path' 2> /dev/null | grep -E '^(index\.md|(obs|pipe|devx|ai|fawkes|compatibility|learn|blog)/[^/]+\.(md|html)|_posts/.*\.md|_data/.*\.yml)$' || true)"
[[ -n "$pages" ]] || {
  echo "uFawkes.dev: cannot list site pages"
  missing=1
}
while IFS= read -r p; do
  [[ -n "$p" ]] && { fetch uFawkes.dev "$p" || missing=1; }
done <<< "$pages"

rc=0
python3 "$HERE/retired-terms.py" --terms "$TERMS" --allow "$HERE/ac-suite-01.allow" "${items[@]}" || rc=1
exit $((rc | missing))
