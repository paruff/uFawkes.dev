#!/usr/bin/env bash
# AC-DOJO-01: the curriculum is accurate. The Dojo's content has no "four key"
# metrics claim, no unlabeled Jenkins, and no [VIDEO PLACEHOLDER].
#
# Scans the whole Dojo repo (shallow clone of main). A line that explains the
# mention (deprecated, replaced in Dojo 0.4, "not Jenkins", ...) passes; see
# retired-terms.py. CHECK_DOJO_DIR scans a local directory instead (tests).
set -euo pipefail
cd "$(dirname "$0")/../.."

HERE="$(pwd)/scripts/checks"
TERMS='four key|jenkins|\[VIDEO PLACEHOLDER\]'
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

dir="${CHECK_DOJO_DIR:-}"
if [[ -z "$dir" ]]; then
  dir="$TMP/dojo"
  git clone --depth 1 --quiet https://github.com/paruff/uFawkesDojo.git "$dir" \
    || {
      echo "cannot clone uFawkesDojo"
      exit 2
    }
fi

items=()
while IFS= read -r f; do
  items+=("uFawkesDojo:${f#"$dir"/}=$f")
done < <(find "$dir" -type f \( -name '*.md' -o -name '*.yml' -o -name '*.yaml' -o -name '*.html' \) \
  -not -path '*/.git/*' -not -path '*/node_modules/*' | sort)

[[ "${#items[@]}" -gt 0 ]] || {
  echo "no content files found in $dir"
  exit 2
}

out="$(python3 "$HERE/retired-terms.py" --terms "$TERMS" "${items[@]}" || true)"
if [[ -n "$out" ]]; then
  count="$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
  printf '%s lines to fix; first 5:\n' "$count"
  printf '%s\n' "$out" | head -5
  exit 1
fi
echo "no unlabeled retired claims in ${#items[@]} content files"
