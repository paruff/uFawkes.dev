#!/usr/bin/env bash
# scripts/test-shift-left-drift.sh — shift-left-drift.sh opens, updates and
# closes one issue per repo, and is silent when nothing regressed (plan D2).
set -euo pipefail

unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."
SCRIPT="$PWD/scripts/shift-left-drift.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fails=0
check() { # check <description> <command...>
  local desc="$1"
  shift
  if "$@"; then echo "  ok   $desc"; else
    echo "  FAIL $desc"
    fails=$((fails + 1))
  fi
}

# A gh that records every call and lists the issues in $TMP/issues.json.
mkdir -p "$TMP/bin"
cat > "$TMP/bin/gh" << 'STUB'
#!/usr/bin/env bash
echo "$*" >> "$DRIFT_CALLS"
if [[ "$1 $2" == "issue list" ]]; then cat "$DRIFT_ISSUES"; fi
STUB
chmod +x "$TMP/bin/gh"
export PATH="$TMP/bin:$PATH" DRIFT_CALLS="$TMP/calls" DRIFT_ISSUES="$TMP/issues.json" DRIFT_REPO=o/r

snap() { # snap <file> <repo>=<sast>,<parity> ...
  local f="$1"
  shift
  python3 - "$f" "$@" << 'PY'
import json, sys
f, *specs = sys.argv[1:]
repos = []
for spec in specs:
    name, vals = spec.split("=")
    sast, parity = vals.split(",")
    repos.append({"repo": name, "cells": {"sast": sast, "parity": parity, "types": "-"}})
json.dump({"repos": repos}, open(f, "w"))
PY
}
run() { # run <current> [<previous>] -> $out; calls in $TMP/calls
  : > "$TMP/calls"
  out="$(bash "$SCRIPT" "$@" 2>&1)" || {
    echo "$out"
    return 1
  }
}
calls() { grep -c "^issue $1" "$TMP/calls" || true; }
writes() { grep -c '^issue \(create\|edit\|close\|comment\)' "$TMP/calls" || true; }

echo '[]' > "$DRIFT_ISSUES"
snap "$TMP/ok.json" A=ok,ok B=ok,ok
snap "$TMP/sast-bad.json" A=-,ok B=ok,ok

echo "Quiet by default:"
run "$TMP/sast-bad.json"
check "no previous snapshot: baseline only, no issue" test "$(calls create)" = 0
run "$TMP/ok.json" "$TMP/ok.json"
check "nothing regressed: no issue" test "$(writes)" = 0
run "$TMP/sast-bad.json" "$TMP/sast-bad.json"
check "a gap that was already there is not a regression" test "$(calls create)" = 0

echo "A regression opens one issue:"
run "$TMP/sast-bad.json" "$TMP/ok.json"
check "one issue created" test "$(calls create)" = 1
check "titled for the repo, labeled" grep -q -- "--title shift-left drift: A.*--label shift-left-drift" "$TMP/calls"
check "naming the column in the marker" grep -q "<!-- drift: sast -->" "$TMP/calls"
check "repo B is untouched" test "$(grep -c 'drift: B' "$TMP/calls" || true)" = 0

echo "Its state lives in the issue:"
python3 -c 'import json; json.dump([{"number": 7, "title": "shift-left drift: A", "body": "x\n<!-- drift: sast -->"}], open("'"$DRIFT_ISSUES"'", "w"))'
run "$TMP/sast-bad.json" "$TMP/sast-bad.json"
check "still broken, nothing new: no write" test "$(writes)" = 0
snap "$TMP/two-bad.json" A=-,- B=ok,ok
run "$TMP/two-bad.json" "$TMP/sast-bad.json"
check "a second column regressed: the issue is edited" grep -q "^issue edit 7 " "$TMP/calls"
check "and now names both columns" grep -q "<!-- drift: parity,sast -->" "$TMP/calls"
snap "$TMP/healed.json" A=ok,ok B=ok,ok
run "$TMP/healed.json" "$TMP/sast-bad.json"
check "back to ok: the issue is closed" grep -q "^issue close 7" "$TMP/calls"
snap "$TMP/half.json" A=ok,- B=ok,ok
run "$TMP/half.json" "$TMP/two-bad.json"
check "an unrelated gap doesn't keep it open" grep -q "^issue close 7" "$TMP/calls"

echo "Bad input is loud:"
check "a missing current snapshot fails" bash -c "! bash '$SCRIPT' '$TMP/none.json' > /dev/null 2>&1"

if [[ "$fails" -ne 0 ]]; then
  echo "test-shift-left-drift: $fails FAILED" >&2
  exit 1
fi
echo "test-shift-left-drift: all checks passed"
