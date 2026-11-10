#!/usr/bin/env bash
# AC-SITE-01: the site lists the seven repos and the compatibility matrix is current.
#
# Each matrix row's "Current release" link must name the repo's newest GitHub
# Release (pre-releases count: Pipe and fawkes only have those).
# COMPAT_FILE overrides compatibility/index.md (tests).
set -euo pipefail
cd "$(dirname "$0")/../.."

bad=0
for page in ai/index.md fawkes/index.md compatibility/index.md obs/index.md pipe/index.md devx/index.md; do
  [[ -f "$page" ]] || {
    echo "missing site page: $page"
    bad=1
  }
done

compat="${COMPAT_FILE:-compatibility/index.md}"
rows="$(grep -oE 'github\.com/paruff/[A-Za-z.]+/releases/tag/[^)]+' "$compat" | sort -u)"
[[ -n "$rows" ]] || {
  echo "$compat: no release links found"
  exit 1
}
while IFS= read -r link; do
  repo="$(cut -d/ -f3 <<< "$link")"
  listed="${link##*/}"
  if ! latest="$(gh api "repos/paruff/$repo/releases?per_page=1" --jq '.[0].tag_name' 2>&1)"; then
    echo "$repo: cannot read releases ($latest)"
    bad=1
  elif [[ "$listed" != "$latest" ]]; then
    echo "$repo: matrix says $listed, newest release is $latest"
    bad=1
  fi
done <<< "$rows"
exit "$bad"
