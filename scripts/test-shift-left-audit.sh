#!/usr/bin/env bash
# scripts/test-shift-left-audit.sh — offline tests for shift-left-audit.sh
# (shift-left plan, phase A1). A stub `gh` serves fixture hook configs.
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
# cell <repo> <column> -> that cell of the matrix (columns found by header name)
cell() {
  awk -v r="$1" -v c="$2" '$1=="repo"{for(i=1;i<=NF;i++)if($i==c)col=i} $1==r&&col{print $col; exit}' "$TMP/out.txt"
}
is() { # is <description> <repo> <column> <expected>
  local got
  got="$(cell "$2" "$3")"
  if [[ "$got" == "$4" ]]; then ok "$1"; else bad "$1 (got '$got', want '$4')"; fi
}
says() { # says <description> <regex> -> anywhere in the output
  if grep -qE "$2" "$TMP/out.txt"; then ok "$1"; else bad "$1"; fi
}

FIX="$(pwd)/scripts/testdata/shift-left"
mkdir -p "$TMP/bin"
cat > "$TMP/bin/gh" << STUB
#!/usr/bin/env bash
# gh api repos/<owner>/<repo>/contents/.pre-commit-config.yaml --jq .content
case "\$*" in
  *repos/paruff/uFawkesPipe/contents/.pre-commit-hooks.yaml?ref=v1.11.0*) base64 < "$FIX/pipe-manifest.yaml" ;;
  *repos/o/shared/contents/*) base64 < "$FIX/shared.yaml" ;;
  *repos/o/complete/contents/*) base64 < "$FIX/complete.yaml" ;;
  *repos/o/partial/contents/*) base64 < "$FIX/partial.yaml" ;;
  *repos/o/none/contents/*) echo "gh: Not Found (HTTP 404)" >&2; exit 1 ;;
  *repos/o/broken/contents/*) echo "gh: Bad credentials (HTTP 401)" >&2; exit 1 ;;
  *) echo "gh stub: unexpected call: \$*" >&2; exit 1 ;;
esac
STUB
chmod +x "$TMP/bin/gh"
export PATH="$TMP/bin:$PATH"

echo "Matrix:"
AUDIT_OWNER=o AUDIT_REPOS="complete partial none" bash scripts/shift-left-audit.sh > "$TMP/out.txt"
is "actionlint present" complete actionlint ok
is "config schema present" complete schema ok
is "SAST present at pre-push" complete sast ok
is "type check present" complete types ok
is "dep/IaC scan present" complete dep-iac ok
is "unit tests at pre-push" complete unit ok
is "commit-msg hook installed" complete commit-msg ok
is "no system hooks" complete system 0
is "missing actionlint shown" partial actionlint -
is "missing semgrep shown" partial sast -
is "golangci-lint counts as a Go type check" partial types ok
is "unit tests at the wrong stage" partial unit pre-commit
is "commit-msg hook defined, stage not installed" partial commit-msg not-installed
is "kubeval counts as dep/IaC, at its actual stage" partial dep-iac pre-commit
is "system hooks counted (R4)" partial system 3
says "unmapped hook ids listed" '^  partial: brand-new-check$'
is "no config is a result, not a crash" none actionlint n/a
says "no config explained" 'none: no .pre-commit-config.yaml on main'

echo "Shared hooks (stages from uFawkesPipe's manifest at the pinned rev):"
AUDIT_OWNER=o AUDIT_REPOS="shared complete none" bash scripts/shift-left-audit.sh --json "$TMP/sl.json" > "$TMP/out.txt"
is "semgrep from Pipe counts as SAST at pre-push" shared sast ok
is "trivy from Pipe counts as dep scan at pre-push" shared dep-iac ok
is "the parity hook is adopted" shared parity ok
is "the stamp hooks are adopted" shared stamps ok
is "a repo without them shows missing" complete parity -

echo "JSON for /status/:"
jq_is() { # jq_is <description> <jq -e filter>
  if jq -e "$2" "$TMP/sl.json" > /dev/null; then ok "$1"; else bad "$1"; fi
}
jq_is "top-level keys" 'keys == ["columns","generated_at","repos","run_url"]'
jq_is "columns carry id, label and stage" '.columns | all(has("id","label","stage")) and (map(.id) | index("parity") != null)'
jq_is "repos in the order audited" '[.repos[].repo] == ["shared","complete","none"]'
jq_is "cells match the table" '.repos[0].cells.sast == "ok" and .repos[1].cells.parity == "-"'
jq_is "no config is a note, cells n/a" '.repos[2].note != "" and (.repos[2].cells | all(.[]; . == "n/a"))'
jq_is "generated_at is ISO 8601 UTC" '.generated_at | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z$")'

echo "Script errors:"
if AUDIT_OWNER=o AUDIT_REPOS="broken" bash scripts/shift-left-audit.sh > /dev/null 2>&1; then
  bad "an API error exits non-zero"
else
  ok "an API error exits non-zero"
fi

if [[ "$fails" -ne 0 ]]; then
  echo "test-shift-left-audit: $fails FAILED" >&2
  exit 1
fi
echo "test-shift-left-audit: all checks passed"
