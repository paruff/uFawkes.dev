#!/usr/bin/env bash
# scripts/test-check-design-tokens.sh — offline tests for check-design-tokens.sh.
set -euo pipefail

cd "$(dirname "$0")/.."

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fails=0

expect() { # expect <pass|fail> <description> <tokens-file> [DESIGN.md]
  if bash scripts/check-design-tokens.sh "${@:3}" > /dev/null 2>&1; then got=pass; else got=fail; fi
  if [[ "$got" == "$1" ]]; then echo "  ok   $2"; else
    echo "  FAIL $2 (expected $1, got $got)"
    fails=$((fails + 1))
  fi
}

echo "check-design-tokens:"
expect pass "the real tokens meet their floor" design/tokens.json

cat > "$TMP/low.json" << 'JSON'
{"color": {"a": "#f06300", "b": "#ffffff"},
 "contrast": [{"fg": "color.a", "bg": "color.b", "min": 4.5, "use": "orange text on white"}]}
JSON
expect fail "orange on white fails the 4.5 floor (3.24:1)" "$TMP/low.json"

cat > "$TMP/graphic.json" << 'JSON'
{"color": {"a": "#f06300", "b": "#ffffff"},
 "contrast": [{"fg": "color.a", "bg": "color.b", "min": 3, "use": "graphic"}]}
JSON
expect pass "orange on white meets the 3:1 floor for graphics" "$TMP/graphic.json"

cat > "$TMP/missing.json" << 'JSON'
{"color": {"a": "#000000"},
 "contrast": [{"fg": "color.a", "bg": "color.nope", "min": 4.5}]}
JSON
expect fail "an unresolved path fails loudly" "$TMP/missing.json"

cat > "$TMP/badhex.json" << 'JSON'
{"color": {"a": "red", "b": "#ffffff"},
 "contrast": [{"fg": "color.a", "bg": "color.b", "min": 4.5}]}
JSON
expect fail "a non-hex colour fails" "$TMP/badhex.json"

echo '{"color": {}}' > "$TMP/empty.json"
expect fail "a file with no contrast pairs fails" "$TMP/empty.json"

echo "DESIGN.md front matter vs tokens.json:"
expect pass "the real DESIGN.md colours match the real tokens" design/tokens.json DESIGN.md

sed 's/flame-500: "#f06300"/flame-500: "#f06301"/' DESIGN.md > "$TMP/drift.md"
expect fail "a DESIGN.md colour that differs from tokens.json fails" design/tokens.json "$TMP/drift.md"

awk '{ print } /^  night: "#061723"$/ { print "  teal-500: \"#14b8a6\"" }' DESIGN.md > "$TMP/extra.md"
expect fail "a DESIGN.md colour with no tokens.json entry fails" design/tokens.json "$TMP/extra.md"

if [[ "$fails" -ne 0 ]]; then
  echo "test-check-design-tokens: $fails FAILED"
  exit 1
fi
echo "test-check-design-tokens: all checks passed ✅"
