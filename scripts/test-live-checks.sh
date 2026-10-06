#!/usr/bin/env bash
# scripts/test-live-checks.sh — offline tests for live-checks.sh
# (suite-status plan, Tier 2). A stub `gh` serves fixture workflow runs.
set -euo pipefail

cd "$(dirname "$0")/.."

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fails=0
ok() { echo "  ok   $1"; }
bad() {
  echo "  FAIL $1"
  fails=$((fails + 1))
}
# cell <repo> <workflow> <col> -> that cell of the table (3=state, 5=note start)
cell() {
  awk -v k="$1/$2" -v col="$3" 'NR > 1 && ($1 "/" $2) == k { print $col; exit }' "$TMP/out.txt"
}
is() { # is <description> <repo> <workflow> <expected state>
  local got
  got="$(cell "$2" "$3" 3)"
  if [[ "$got" == "$4" ]]; then ok "$1"; else bad "$1 (got '$got', want '$4')"; fi
}
says() { # says <description> <regex> -> anywhere in the table output
  if grep -qE "$2" "$TMP/out.txt"; then ok "$1"; else bad "$1"; fi
}

FIX="$(pwd)/scripts/testdata/live-checks"
mkdir -p "$TMP/bin"
cat > "$TMP/bin/gh" << STUB
#!/usr/bin/env bash
# stub: gh api <url> --jq <expr>  -> fixture JSON through real jq
expr=""
prev=""
for a in "\$@"; do
  if [ "\$prev" = "--jq" ]; then expr="\$a"; fi
  prev="\$a"
done
body=""
case "\$*" in
  *repos/o/pass-ok/actions/workflows/pass.yml/runs*) body=\$(cat "$FIX/runs-pass.json") ;;
  *repos/o/pass-ok/actions/workflows/flaky.yml/runs*) body=\$(cat "$FIX/runs-flaky.json") ;;
  *repos/o/fail-steps/actions/workflows/boom.yml/runs*) body=\$(cat "$FIX/runs-boom.json") ;;
  *repos/o/fail-steps/actions/runs/222/jobs*) body=\$(cat "$FIX/jobs-222.json") ;;
  *repos/o/stale-old/actions/workflows/old.yml/runs*) body=\$(cat "$FIX/runs-old.json") ;;
  *repos/o/none-yet/actions/workflows/never.yml/runs*) body=\$(cat "$FIX/runs-never.json") ;;
  *repos/o/running-now/actions/workflows/busy.yml/runs*) body=\$(cat "$FIX/runs-busy.json") ;;
  *repos/o/wobble/actions/workflows/wobble.yml/runs*)
    # eventually consistent listing: a stale first read, a fresh second read
    n=\$(cat "$TMP/wobble-count" 2>/dev/null || echo 0)
    n=\$((n + 1)); echo "\$n" > "$TMP/wobble-count"
    if [ "\$n" -le 1 ]; then body=\$(cat "$FIX/runs-wobble-stale.json"); else body=\$(cat "$FIX/runs-wobble-fresh.json"); fi ;;
  *repos/o/broken-api/*) echo "gh: Bad credentials (HTTP 401)" >&2; exit 1 ;;
  *repos/o/gone-workflow/*) echo "gh: Not Found (HTTP 404)" >&2; exit 1 ;;
  *) echo "gh stub: unexpected call: \$*" >&2; exit 1 ;;
esac
printf '%s' "\$body" | jq -r "\$expr"
STUB
chmod +x "$TMP/bin/gh"
export PATH="$TMP/bin:$PATH"

echo "Table:"
LC_OWNER=o LC_NOW=2026-10-05T12:00:00Z LC_FILE="$FIX/checks-main.yml" \
  bash scripts/live-checks.sh --json "$TMP/live_checks.json" > "$TMP/out.txt"
is "a recent success passes" pass-ok pass.yml pass
is "a neutral run is stale, not pass" pass-ok flaky.yml stale
is "a failed run fails" fail-steps boom.yml fail
is "an old success is stale" stale-old old.yml stale
is "a never-run workflow is none" none-yet never.yml none
is "an in-flight run is running" running-now busy.yml running
says "failed steps are printed" 'integration tests, publish artifacts'
says "stale shows the age" '240h ago'
says "neutral is explained" 'verified nothing'

echo "JSON for /status/:"
jq_is() { # jq_is <description> <jq -e filter>
  if jq -e "$2" "$TMP/live_checks.json" > /dev/null; then ok "$1"; else bad "$1"; fi
}
jq_is "top-level keys" 'keys == ["checks","generated_at","run_url"]'
jq_is "states in list order" '[.checks[].state] == ["pass","stale","fail","stale","none","running"]'
jq_is "purpose and starts_stack round-trip" '.checks[0].purpose == "proves a healthy nightly shows pass" and .checks[0].starts_stack == true'
jq_is "failed steps round-trip" '.checks[2].failed_steps == ["integration tests","publish artifacts"]'
jq_is "LC_NOW is the generated_at" '.generated_at == "2026-10-05T12:00:00Z"'
jq_is "none has no run to link" '.checks[4].last_run_at == "" and .checks[4].run_url == ""'
jq_is "per-entry stale window" '.checks[3].stale_after_hours == 6'
jq_is "two entries in one repo stay distinct" '.checks[0].repo == .checks[1].repo and .checks[0].state == "pass" and .checks[1].state == "stale"'

echo "Unstable runs listing (eventual consistency):"
LC_OWNER=o LC_NOW=2026-10-05T12:00:00Z LC_FILE="$FIX/checks-wobble.yml" \
  bash scripts/live-checks.sh > "$TMP/wobble.txt" 2> "$TMP/wobble-err.txt"
wstate="$(awk 'NR > 1 { print $3; exit }' "$TMP/wobble.txt")"
if [[ "$wstate" == "pass" ]]; then
  ok "the later read wins"
else
  bad "the later read wins (got '$wstate', want 'pass')"
fi
if grep -qE 'unstable runs listing for wobble/wobble.yml' "$TMP/wobble-err.txt"; then
  ok "the disagreement is reported, not swallowed"
else
  bad "the disagreement is reported, not swallowed"
fi

echo "Script errors:"
if LC_OWNER=o LC_FILE="$FIX/checks-error.yml" bash scripts/live-checks.sh > /dev/null 2> "$TMP/err.txt"; then
  bad "an API error exits non-zero"
else
  ok "an API error exits non-zero"
fi
if grep -qE 'live-checks: broken-api/err.yml: gh: Bad credentials' "$TMP/err.txt"; then
  ok "the API error is reported, not swallowed"
else
  bad "the API error is reported, not swallowed"
fi

if LC_OWNER=o LC_FILE="$FIX/checks-gone.yml" bash scripts/live-checks.sh > /dev/null 2> "$TMP/err.txt"; then
  bad "an unknown workflow exits non-zero"
else
  ok "an unknown workflow exits non-zero"
fi
if grep -qE 'names a workflow the API does not know' "$TMP/err.txt"; then
  ok "the drift error says which entry broke"
else
  bad "the drift error says which entry broke"
fi

if LC_OWNER=o LC_FILE="$FIX/no-such-file.yml" bash scripts/live-checks.sh > /dev/null 2>&1; then
  bad "a missing YAML file exits non-zero"
else
  ok "a missing YAML file exits non-zero"
fi

if LC_OWNER=o LC_FILE="$FIX/checks-main.yml" bash scripts/live-checks.sh > /dev/null 2>&1; then
  ok "runs without --json"
else
  bad "runs without --json"
fi

if bash scripts/live-checks.sh --nope > /dev/null 2>&1; then
  bad "an unknown argument exits non-zero"
else
  ok "an unknown argument exits non-zero"
fi

if [[ "$fails" -ne 0 ]]; then
  echo "test-live-checks: $fails FAILED" >&2
  exit 1
fi
echo "test-live-checks: all checks passed"
