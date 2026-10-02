#!/usr/bin/env bash
# scripts/check-status-drift.sh — AC-STATUS-01.
# Every `#### AC-` heading in suite-release/spec.md must have an entry in
# suite-release/acceptance.yml, and the other way round.
set -euo pipefail

cd "$(dirname "$0")/.."

SPEC="${SPEC:-docs/ai-sdlc/suite-release/spec.md}"
ACS="${ACS:-docs/ai-sdlc/suite-release/acceptance.yml}"

spec_ids="$(grep -oE '^#### AC-[A-Z]+-[0-9]+' "$SPEC" | sed 's/^#### //' | sort -u)"
yml_ids="$(grep -oE '^- id: AC-[A-Z]+-[0-9]+' "$ACS" | sed 's/^- id: //' | sort -u)"

missing="$(comm -23 <(printf '%s\n' "$spec_ids") <(printf '%s\n' "$yml_ids"))"
extra="$(comm -13 <(printf '%s\n' "$spec_ids") <(printf '%s\n' "$yml_ids"))"

fail=0
if [[ -n "$missing" ]]; then
  echo "In spec.md but not in acceptance.yml:" >&2
  printf '  %s\n' $missing >&2
  fail=1
fi
if [[ -n "$extra" ]]; then
  echo "In acceptance.yml but not in spec.md:" >&2
  printf '  %s\n' $extra >&2
  fail=1
fi
if [[ "$fail" -eq 0 ]]; then
  echo "check-status-drift: $(wc -l <<<"$spec_ids" | tr -d ' ') ACs in sync."
fi
exit "$fail"
