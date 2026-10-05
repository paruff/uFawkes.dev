#!/usr/bin/env bash
# scripts/run-unit-tests.sh — run the offline test suites a change affects.
#
# One entry point so pre-commit, preflight, and CI run exactly the same set.
# Previously each suite was invoked ad hoc, and three of the four were wired
# to nothing at all.
#
# All suites are offline and dependency-free: they stub `gh`, bind an
# ephemeral loopback port, and use vendored fixtures. That is what makes them
# safe to run on every commit — a test that needs the network or a pip install
# is a test whose result depends on the machine, not the code.
#
# Usage: run-unit-tests.sh [changed files...]
#   No files (or this runner among them): every suite. Otherwise only the
#   suites whose pattern matches a changed file (shift-left plan, phase A2).
#   The pre-commit hook passes the staged files; `--all-files` in CI and at
#   pre-push passes every file, so every suite runs there.
#   UNIT_TESTS_DRY_RUN=1 prints the selected suites instead of running them.
#   UNIT_TESTS_DIR overrides where the suites live (tests; default scripts).
#
# The selected suites run in parallel (phase A3): each works in its own mktemp
# directory and stubs, so they share no state. Results print in suite order.
#
# Exit 0 = every selected suite passed. Exit 1 = at least one failed.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

# "<suite> <regex of the files it tests>". Every scripts/test-*.sh must be
# listed: test-run-unit-tests.sh fails on one that isn't.
SUITES=(
  "test-check-secret-detection ^scripts/(test-)?check-secret-detection\.sh$"
  "test-emit-dora-event ^scripts/(test-)?emit-dora-event\.sh$|^scripts/testdata/ufawkesobs-"
  "test-artifact-chain ^scripts/(test-)?check-artifact-chain\.sh$"
  "test-dojo-feedback-intent ^scripts/(test-)?dojo-feedback-intent\.sh$"
  "test-shift-left-drift ^scripts/(test-)?shift-left-drift\.sh$"
  "test-suite-status ^scripts/(test-suite-status|suite-status|check-status-drift)\.sh$|^scripts/checks/|^scripts/testdata/suite-status"
  "test-check-design-tokens ^scripts/(test-)?check-design-tokens\.sh$|^design/tokens\.json$"
  "test-shift-left-audit ^scripts/(test-)?shift-left-audit\.sh$|^scripts/testdata/shift-left/"
  "test-run-unit-tests ^scripts/test-run-unit-tests\.sh$"
  "test-require-tool ^scripts/(test-)?require-tool\.sh$"
  "test-semgrep-scan ^scripts/(test-)?semgrep-scan\.sh$"
  "test-doctor ^scripts/(test-)?(doctor|shift-left-stamp|require-tool|check-shift-left-parity)\.sh$"
  "test-shift-left-triage ^scripts/(test-)?shift-left-triage\.sh$"
  "test-agent-gate ^scripts/(test-)?agent-gate\.sh$"
  "test-shift-left-parity ^scripts/(test-shift-left-parity|check-shift-left-parity)\.sh$"
)

selected=()
for entry in "${SUITES[@]}"; do
  name="${entry%% *}"
  pattern="${entry#* }"
  if [[ $# -eq 0 ]] || printf '%s\n' "$@" | grep -qE "$pattern|^scripts/run-unit-tests\.sh$"; then
    selected+=("${UNIT_TESTS_DIR:-scripts}/$name.sh")
  fi
done

if [[ -n "${UNIT_TESTS_DRY_RUN:-}" ]]; then
  for suite in "${selected[@]}"; do basename "$suite" .sh; done
  exit 0
fi
if [[ ${#selected[@]} -eq 0 ]]; then
  echo "run-unit-tests: no suite covers the changed files."
  exit 0
fi

failed=0
results=()
OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT

# ponytail: one process per suite, all at once; cap it if the list outgrows the cores.
for suite in "${selected[@]}"; do
  name="$(basename "$suite" .sh)"
  [[ -f "$suite" ]] || continue
  (
    bash "$suite" > "$OUT/$name.out" 2>&1
    echo $? > "$OUT/$name.rc"
  ) &
done
wait

for suite in "${selected[@]}"; do
  name="$(basename "$suite" .sh)"
  if [[ ! -f "$suite" ]]; then
    results+=("MISSING  $name")
    failed=1
    continue
  fi
  out="$(cat "$OUT/$name.out")"
  if [[ "$(cat "$OUT/$name.rc")" == 0 ]]; then
    last="$(printf '%s\n' "$out" | grep -E '✅|passed|PASSED|BEHAVED' | tail -1 | sed 's/^[[:space:]]*//')"
    results+=("PASS     $name — ${last:-ok}")
  else
    results+=("FAIL     $name")
    failed=1
    printf '\n─── %s failed ───\n%s\n\n' "$name" "$out" >&2
  fi
done

echo "Unit test suites (${#selected[@]} of ${#SUITES[@]}):"
for line in "${results[@]}"; do
  echo "  $line"
done

if [[ "$failed" -ne 0 ]]; then
  echo
  echo "run-unit-tests: FAILED" >&2
  exit 1
fi

echo "run-unit-tests: all ${#selected[@]} selected suites passed."
