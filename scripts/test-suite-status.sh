#!/usr/bin/env bash
# scripts/test-suite-status.sh — offline tests for suite-status.sh and
# check-status-drift.sh (AC-STATUS-01, -02, -03).
set -euo pipefail

cd "$(dirname "$0")/.."

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fails=0
check() { # check <description> <jq -e filter> <file>
  if jq -e "$2" "$3" > /dev/null; then echo "  ok   $1"; else
    echo "  FAIL $1"
    fails=$((fails + 1))
  fi
}

cat > "$TMP/acs.yml" << 'YML'
- id: AC-T-01
  release: Alpha
  title: Passing command
  check: command
  run: "true"
  evidence: ""
- id: AC-T-02
  release: Alpha
  title: Failing command
  check: command
  run: "echo boom; exit 3"
  evidence: ""
- id: AC-T-03
  release: Alpha
  title: Manual with evidence
  check: manual
  run: ""
  evidence: https://example.com/run/1
- id: AC-T-04
  release: AI 2.0
  title: Manual without evidence
  check: manual
  run: ""
  evidence: ""
YML

# AC-STATUS-02: output matches the R3 shape. Fixture releases are "Alpha" and "AI 2.0".
STATUS_ACS="$TMP/acs.yml" STATUS_ITEMS_FILE=scripts/testdata/suite-status-items.json \
  STATUS_OUT="$TMP/out.json" STATUS_NOW=2026-10-02T06:00:00Z bash scripts/suite-status.sh > /dev/null
echo "R3 shape:"
check "top-level keys" 'keys == ["burnup","generated_at","next_release","releases","run_url"]' "$TMP/out.json"
check "release keys" '.releases | all(has("name","order","acs","issues","blockers","routing","pace","ac_results"))' "$TMP/out.json"

# AC-STATUS-03: a failing AC is a result, not a script error.
echo "Results:"
check "failing AC recorded as fail with output" '.releases[0].ac_results | map(select(.id=="AC-T-02"))[0] | .status=="fail" and (.detail|test("boom"))' "$TMP/out.json"
check "manual with URL passes" '.releases[0].ac_results | map(select(.id=="AC-T-03"))[0].status=="pass"' "$TMP/out.json"
check "manual without evidence is pending" '.releases[1].ac_results[0].status=="manual"' "$TMP/out.json"
check "next release is the first not fully passing" '.next_release=="Alpha"' "$TMP/out.json"

# Project data: use the fixture with matching release names.
cat > "$TMP/acs2.yml" << 'YML'
- id: AC-T-10
  release: AI 2.0
  title: Command
  check: command
  run: "true"
  evidence: ""
- id: AC-T-11
  release: Dojo 0.2
  title: Manual
  check: manual
  run: ""
  evidence: ""
YML
STATUS_ACS="$TMP/acs2.yml" STATUS_ITEMS_FILE=scripts/testdata/suite-status-items.json \
  STATUS_OUT="$TMP/out2.json" STATUS_NOW=2026-10-02T06:00:00Z bash scripts/suite-status.sh > /dev/null
echo "Project data:"
check "issue counts" '.releases[0].issues == {"done":3,"in_progress":1,"todo":1,"total":5}' "$TMP/out2.json"
check "blocker listed" '.releases[0].blockers | length == 1 and .[0].number == 111' "$TMP/out2.json"
check "routing split" '.releases[0].routing == {"goal":2,"nemotron":2,"flash":1}' "$TMP/out2.json"
check "pace: 3 closed in 28d, 2 open -> 2/(3/4) = 2.7 weeks" '.releases[0].pace == {"closed_last_28d":3,"weeks_to_done_estimate":2.7}' "$TMP/out2.json"
check "pace hidden with too little data" '.releases[1].pace.weeks_to_done_estimate == null' "$TMP/out2.json"
check "ready list only on next release (Dojo 0.2 here)" '(.releases[1].ready | length) == 1 and (.releases[0] | has("ready") | not)' "$TMP/out2.json"
check "burn-up ends at now with totals" '.burnup[-1] == {"date":"2026-10-02","done":3,"total":6}' "$TMP/out2.json"

# AC-STATUS-03: a broken script (bad YAML) exits non-zero.
echo "Script errors:"
printf 'not: [a list' > "$TMP/bad.yml"
if STATUS_ACS="$TMP/bad.yml" STATUS_ITEMS_FILE=scripts/testdata/suite-status-items.json \
  STATUS_OUT="$TMP/bad.json" bash scripts/suite-status.sh > /dev/null 2>&1; then
  echo "  FAIL bad YAML should exit non-zero"
  fails=$((fails + 1))
else
  echo "  ok   bad YAML exits non-zero"
fi

# AC-STATUS-01: drift check fails on a spec AC with no entry.
echo "Drift check:"
printf '#### AC-X-01: a\n#### AC-X-02: b\n' > "$TMP/spec.md"
printf -- '- id: AC-X-01\n' > "$TMP/drift.yml"
if SPEC="$TMP/spec.md" ACS="$TMP/drift.yml" bash scripts/check-status-drift.sh > /dev/null 2>&1; then
  echo "  FAIL drift should be detected"
  fails=$((fails + 1))
else
  echo "  ok   spec AC without entry fails"
fi
bash scripts/check-status-drift.sh > /dev/null && echo "  ok   real spec and acceptance.yml are in sync"

if [[ "$fails" -ne 0 ]]; then
  echo "test-suite-status: $fails FAILED"
  exit 1
fi
echo "test-suite-status: all checks passed ✅"
