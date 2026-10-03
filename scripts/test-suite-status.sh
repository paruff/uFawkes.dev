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

# Offline stubs. gh answers the few API calls the status script makes; curl answers
# only the made-up *.example hosts and passes everything else (file://) to the real one.
mkdir -p "$TMP/bin"
REAL_CURL="$(command -v curl)"
cat > "$TMP/bin/gh" << 'STUB'
#!/usr/bin/env bash
case "$*" in
  *trees/main*) echo "index.md" ;;
  *pulls/101*) echo '{"state":"closed","at":"2026-09-30T10:00:00Z"}' ;; # merged 2 days ago
  *pulls/102*) echo '{"state":"closed","at":"2026-08-01T10:00:00Z"}' ;; # merged 62 days ago
  *pulls/103*) echo '{"state":"open","at":null}' ;;                    # not merged
  *pulls/404*) echo "gh: Not Found (HTTP 404)" >&2; exit 1 ;;
  *) echo "gh stub: unexpected call: $*" >&2; exit 1 ;;
esac
STUB
cat > "$TMP/bin/curl" << STUB
#!/usr/bin/env bash
for a in "\$@"; do url="\$a"; done
case "\$url" in
  https://ok.example*) printf 200 ;;
  https://dead.example*) printf 404 ;;
  *) exec "$REAL_CURL" "\$@" ;;
esac
STUB
chmod +x "$TMP/bin/gh" "$TMP/bin/curl"
export PATH="$TMP/bin:$PATH"

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
  evidence: https://ok.example/run/1
  evidence_date: 2026-09-20
- id: AC-T-05
  release: Alpha
  title: PR evidence merged 2 days ago
  check: manual
  run: ""
  evidence: https://github.com/o/r/pull/101
- id: AC-T-06
  release: Alpha
  title: PR evidence merged 62 days ago
  check: manual
  run: ""
  evidence: https://github.com/o/r/pull/102
- id: AC-T-07
  release: Alpha
  title: PR evidence not merged
  check: manual
  run: ""
  evidence: https://github.com/o/r/pull/103
- id: AC-T-08
  release: Alpha
  title: Dead evidence link
  check: manual
  run: ""
  evidence: https://dead.example/x
  evidence_date: 2026-09-30
- id: AC-T-09
  release: Alpha
  title: Evidence link with no date
  check: manual
  run: ""
  evidence: https://ok.example/nodate
- id: AC-T-12
  release: Alpha
  title: Evidence older than 30 days
  check: manual
  run: ""
  evidence: https://ok.example/old
  evidence_date: 2026-08-01
- id: AC-T-13
  release: Alpha
  title: PR evidence that cannot be looked up
  check: manual
  run: ""
  evidence: https://github.com/o/r/pull/404
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
check "top-level keys" 'keys == ["burnup","generated_at","next_release","releases","run_url","stale_days"]' "$TMP/out.json"
check "stale limit is 30 days" '.stale_days == 30' "$TMP/out.json"
check "ac result carries freshness" '.releases[0].ac_results | all(has("verified_at","age_days"))' "$TMP/out.json"
check "release keys" '.releases | all(has("name","order","acs","issues","blockers","routing","pace","ac_results"))' "$TMP/out.json"

# AC-STATUS-03: a failing AC is a result, not a script error.
echo "Results:"
check "failing AC recorded as fail with output" '.releases[0].ac_results | map(select(.id=="AC-T-02"))[0] | .status=="fail" and (.detail|test("boom"))' "$TMP/out.json"
# Evidence is verified, not merely present (tier 1): status, and the age that decided it.
echo "Evidence:"
ev() { jq -e --arg id "$1" --arg st "$2" --arg d "$3" \
  '.releases[0].ac_results | map(select(.id==$id))[0] | .status==$st and (.detail|test($d))' "$TMP/out.json" > /dev/null; }
evcheck() { if ev "$1" "$2" "$3"; then echo "  ok   $4"; else
  echo "  FAIL $4"
  fails=$((fails + 1))
fi; }
evcheck AC-T-03 pass "12 days old" "link that resolves + recent date passes"
evcheck AC-T-05 pass "1 day old" "PR merged yesterday passes (singular unit)"
evcheck AC-T-06 stale "61 days old" "PR merged 61 days ago is stale"
evcheck AC-T-07 manual "still open" "an open PR is not evidence yet"
evcheck AC-T-08 stale "unreachable" "a dead link is stale"
evcheck AC-T-09 stale "no evidence_date" "a link with no date is stale"
evcheck AC-T-12 stale "62 days old" "a dated link older than 30 days is stale"
evcheck AC-T-13 stale "could not verify" "evidence that cannot be looked up is stale, never pass"
check "counts: 3 pass (1 command + 2 evidence), 5 stale, 1 awaiting, 1 fail" '.releases[0].acs | .pass==3 and .stale==5 and .manual_pending==1 and .fail==1' "$TMP/out.json"
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

# The machine-checked criteria (scripts/checks/). Each runs against a fixture here.
echo "Checks:"
ok() { echo "  ok   $1"; }
bad() {
  echo "  FAIL $1"
  fails=$((fails + 1))
}
# board checks read the items file suite-status.sh already fetched
cat > "$TMP/items-bad.json" << 'JSON'
[{"repo":"R","number":1,"title":"routed","state":"OPEN","release":"Obs 1.0","labels":["goal"]},
 {"repo":"R","number":2,"title":"unrouted","state":"OPEN","release":"Obs 1.0","labels":["bug"]},
 {"repo":"R","number":3,"title":"double","state":"OPEN","release":"Obs 1.0","labels":["goal","model:mimo-v2.6-flash"]},
 {"repo":"R","number":4,"title":"closed unrouted","state":"CLOSED","release":"Obs 1.0","labels":[]},
 {"repo":"R","number":5,"title":"a blocker","state":"OPEN","release":"Obs 1.0","labels":["goal","release-blocker"]}]
JSON
cat > "$TMP/items-ok.json" << 'JSON'
[{"repo":"R","number":1,"title":"routed","state":"OPEN","release":"Obs 1.0","labels":["goal"]},
 {"repo":"R","number":4,"title":"closed unrouted","state":"CLOSED","release":"Obs 1.0","labels":[]},
 {"repo":"R","number":6,"title":"blocker in another release","state":"OPEN","release":"AI 2.0","labels":["goal","release-blocker"]}]
JSON
out="$(STATUS_ITEMS_JSON="$TMP/items-bad.json" bash scripts/checks/ac-suite-02.sh 2>&1)" && bad "AC-SUITE-02 should fail on unrouted and double-routed issues" \
  || { grep -q "R#2" <<< "$out" && grep -q "R#3" <<< "$out" && ! grep -q "R#4" <<< "$out" && ok "AC-SUITE-02 names unrouted and double-routed open issues, ignores closed"; }
STATUS_ITEMS_JSON="$TMP/items-ok.json" bash scripts/checks/ac-suite-02.sh > /dev/null && ok "AC-SUITE-02 passes when every open issue has one routing label" || bad "AC-SUITE-02 should pass"
out="$(STATUS_ITEMS_JSON="$TMP/items-bad.json" bash scripts/checks/ac-obs-02.sh 2>&1)" && bad "AC-OBS-02 should fail with an open blocker" \
  || { grep -q "R#5" <<< "$out" && ok "AC-OBS-02 names the open Obs 1.0 blocker"; }
STATUS_ITEMS_JSON="$TMP/items-ok.json" bash scripts/checks/ac-obs-02.sh > /dev/null && ok "AC-OBS-02 ignores blockers in other releases" || bad "AC-OBS-02 should pass"

# checks that read GitHub, pointed at a file:// tree
RAW="$TMP/raw"
for r in uFawkes.dev uFawkesAI uFawkesObs uFawkesPipe uFawkesDevX uFawkesDojo fawkes; do
  mkdir -p "$RAW/$r/main/.github/workflows"
  printf '# %s\nA stack. Replaced Jenkins with Woodpecker.\n' "$r" > "$RAW/$r/main/README.md"
  printf '# intent\n' > "$RAW/$r/main/INTENT.md"
  : > "$RAW/$r/main/.github/workflows/artifact-chain.yml"
  : > "$RAW/$r/main/.artifact-chain-paths"
done
printf '# site\n' > "$RAW/uFawkes.dev/main/index.md"
export CHECK_RAW_BASE="file://$RAW"
bash scripts/checks/ac-suite-03.sh > /dev/null && ok "AC-SUITE-03 passes when every repo has the three files" || bad "AC-SUITE-03 should pass"
rm "$RAW/uFawkesObs/main/.artifact-chain-paths"
out="$(bash scripts/checks/ac-suite-03.sh 2>&1)" && bad "AC-SUITE-03 should fail on a missing file" \
  || { grep -q "uFawkesObs: missing .artifact-chain-paths" <<< "$out" && ok "AC-SUITE-03 names the repo and the missing file"; }
bash scripts/checks/ac-suite-01.sh > /dev/null && ok "AC-SUITE-01 passes when every retired mention is explained" || bad "AC-SUITE-01 should pass"
printf '# fawkes\nJenkins runs our CI/CD pipelines.\n' > "$RAW/fawkes/main/README.md"
out="$(bash scripts/checks/ac-suite-01.sh 2>&1)" && bad "AC-SUITE-01 should fail on an unexplained Jenkins claim" \
  || { grep -q "fawkes:README.md:2" <<< "$out" && ok "AC-SUITE-01 names the file and line of the unexplained claim"; }
printf '# Pipe\n| uFawkesRes* |\n' > "$RAW/uFawkesPipe/main/README.md"
printf '# fawkes\nfine\n' > "$RAW/fawkes/main/README.md"
bash scripts/checks/ac-suite-01.sh > /dev/null && ok "AC-SUITE-01 honours the reviewed allowlist" || bad "AC-SUITE-01 should honour the allowlist"
unset CHECK_RAW_BASE
mkdir -p "$TMP/dojo/modules"
printf 'Module 5 uses Jenkins for CI.\nFour key metrics are tracked.\n[VIDEO PLACEHOLDER]\n' > "$TMP/dojo/modules/m5.md"
out="$(CHECK_DOJO_DIR="$TMP/dojo" bash scripts/checks/ac-dojo-01.sh 2>&1)" && bad "AC-DOJO-01 should fail on unlabeled claims" \
  || { grep -q "^3 lines to fix" <<< "$out" && ok "AC-DOJO-01 counts the unlabeled lines"; }
printf 'Module 5 used Jenkins; replaced in Dojo 0.4.\n' > "$TMP/dojo/modules/m5.md"
CHECK_DOJO_DIR="$TMP/dojo" bash scripts/checks/ac-dojo-01.sh > /dev/null && ok "AC-DOJO-01 passes when the mention is labeled" || bad "AC-DOJO-01 should pass"

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
