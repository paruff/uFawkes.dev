#!/usr/bin/env bash
# AC-FAWKES-03: fawkes#2004 (extract-zip) and #1797 (CHANGE_ME_* credentials) are closed.
set -euo pipefail

bad=0
for n in 2004 1797; do
  state="$(gh api "repos/paruff/fawkes/issues/${n}" --jq .state)"
  if [[ "$state" != "closed" ]]; then
    echo "fawkes#${n} is ${state}"
    bad=1
  fi
done
exit "$bad"
