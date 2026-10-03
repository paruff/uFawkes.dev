#!/usr/bin/env bash
# scripts/test-run-unit-tests.sh — run-unit-tests.sh picks the suites a change
# affects (shift-left plan, phase A2). UNIT_TESTS_DRY_RUN lists them instead of
# running them, so this suite never recurses into the others.
set -euo pipefail

cd "$(dirname "$0")/.."

fails=0
picks() { # picks <description> <expected suites, space-separated> [files...]
  local desc="$1" want="$2" got
  shift 2
  got="$(UNIT_TESTS_DRY_RUN=1 bash scripts/run-unit-tests.sh "$@" | tr '\n' ' ' | sed 's/ $//')"
  if [[ "$got" == "$want" ]]; then echo "  ok   $desc"; else
    echo "  FAIL $desc (got '$got', want '$want')"
    fails=$((fails + 1))
  fi
}

registered() { sed -n '/^SUITES=(/,/^)/p' scripts/run-unit-tests.sh | grep -oE '^  "test-[a-z-]+' | tr -d ' "'; }
ALL="$(registered | tr '\n' ' ' | sed 's/ $//')"

echo "Selection:"
picks "no files: every suite" "$ALL"
picks "a script under test picks its suite" "test-artifact-chain" scripts/check-artifact-chain.sh
picks "the test file itself picks its suite" "test-dojo-feedback-intent" scripts/test-dojo-feedback-intent.sh
picks "a fixture picks its suite" "test-shift-left-audit" scripts/testdata/shift-left/complete.yaml
picks "an AC check picks the status suite" "test-suite-status" scripts/checks/ac-suite-01.sh
picks "design tokens pick the token suite" "test-check-design-tokens" design/tokens.json
picks "two changes pick two suites, in suite order" "test-emit-dora-event test-check-design-tokens" design/tokens.json scripts/emit-dora-event.sh
picks "unrelated files pick nothing" "" index.md assets/css/main.css
picks "the runner itself picks every suite" "$ALL" scripts/run-unit-tests.sh

echo "Coverage:"
for t in scripts/test-*.sh; do
  n="$(basename "$t" .sh)"
  if registered | grep -qx "$n"; then echo "  ok   $n is registered"; else
    echo "  FAIL $n is not in SUITES: it would never run"
    fails=$((fails + 1))
  fi
done

if [[ "$fails" -ne 0 ]]; then
  echo "test-run-unit-tests: $fails FAILED" >&2
  exit 1
fi
echo "test-run-unit-tests: all checks passed"
