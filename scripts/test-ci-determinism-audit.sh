#!/usr/bin/env bash
# scripts/test-ci-determinism-audit.sh — offline tests for ci-determinism-audit.sh
# (ci-pipeline R10). A stub `gh` serves fixture workflows.
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
cell() { # cell <repo> <column> -> that cell of the matrix
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
lacks() { # lacks <description> <regex>
  if grep -qE "$2" "$TMP/out.txt"; then bad "$1"; else ok "$1"; fi
}

FIX="$(pwd)/scripts/testdata/ci-determinism"
mkdir -p "$TMP/bin"
cat > "$TMP/bin/gh" << STUB
#!/usr/bin/env bash
# Serves gh api repos/o/<repo>/contents/<path> --jq <filter> from the fixtures.
case "\$*" in
  *repos/o/clean/contents/.github/workflows\ *) echo ci.yml ;;
  *repos/o/messy/contents/.github/workflows\ *) printf 'ci.yml\nreusable-lint.yml\n' ;;
  *repos/o/clean/contents/.github/workflows/ci.yml*) base64 < "$FIX/clean/ci.yml" ;;
  *repos/o/messy/contents/.github/workflows/ci.yml*) base64 < "$FIX/messy/ci.yml" ;;
  *repos/o/messy/contents/.github/workflows/reusable-lint.yml*) base64 < "$FIX/messy/reusable-lint.yml" ;;
  *repos/o/clean/contents/.devcontainer/devcontainer.json*) base64 < "$FIX/clean/devcontainer.json" ;;
  *repos/o/messy/contents/.devcontainer/devcontainer.json*) base64 < "$FIX/messy/devcontainer.json" ;;
  *repos/o/messy/contents/.pipeline.yml*) base64 < "$FIX/messy/pipeline.yml" ;;
  *repos/o/uFawkesPipe/contents/images/ci/Dockerfile?ref=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa*) base64 < "$FIX/clean/Dockerfile" ;;
  *repos/o/broken/*) echo "gh: Bad credentials (HTTP 401)" >&2; exit 1 ;;
  *repos/o/*/contents/*) echo "gh: Not Found (HTTP 404)" >&2; exit 1 ;;
  *) echo "gh stub: unexpected call: \$*" >&2; exit 1 ;;
esac
STUB
chmod +x "$TMP/bin/gh"
export PATH="$TMP/bin:$PATH"

echo "Matrix:"
AUDIT_OWNER=o AUDIT_REPOS="clean messy bare" bash scripts/ci-determinism-audit.sh --json "$TMP/ci.json" > "$TMP/out.txt"
is "one Pipe SHA is ok" clean pipe_refs ok
is "two Pipe SHAs, matched case-insensitively" messy pipe_refs 2
is "no workflows: not applicable" bare pipe_refs n/a
is "no local copies" clean local_copies ok
is "a local copy of a Pipe reusable" messy local_copies 1
is "hook job in ufawkes-ci at a digest" clean ci_image ok
is "hook job in some other image" messy ci_image ubuntu:latest
is "no workflows: CI image n/a" bare ci_image n/a
is "release behind the image matches the devcontainer" clean release_match ok
is "an unreadable side is n/a, not a failure" messy release_match n/a
is "everything pinned" clean unpinned ok
is "unpinned action, container and service image" messy unpinned 3
says "the unpinned action is located" 'messy: unpinned: ci.yml:[0-9]+ actions/checkout@v4'
lacks "a grep guard for :latest is not an unpinned image" 'unpinned: .*grep'
is "no silent passes" clean silent ok
is "continue-on-error and || true, minus the listed one" messy silent 2
says "continue-on-error located" 'messy: silent: ci.yml:[0-9]+ Flaky \(continue-on-error\)'
says "|| true located" 'messy: silent: ci.yml:[0-9]+ Quiet \(\|\| true\)'
lacks "a step listed under informational: is not a finding" 'Status \(informational\)'

echo "JSON for /status/:"
jq_is() { # jq_is <description> <jq -e filter>
  if jq -e "$2" "$TMP/ci.json" > /dev/null; then ok "$1"; else bad "$1"; fi
}
jq_is "top-level keys" 'keys == ["columns","generated_at","repos","run_url"]'
jq_is "columns carry id and label" '.columns | all(has("id","label"))'
jq_is "repos in the order audited" '[.repos[].repo] == ["clean","messy","bare"]'
jq_is "cells match the table" '.repos[1].cells.silent == "2" and .repos[0].cells.pipe_refs == "ok"'
jq_is "findings carry the detail" '(.repos[1].findings.pipe_refs | length) == 2 and (.repos[1].findings.silent | length) == 2'
jq_is "generated_at is ISO 8601 UTC" '.generated_at | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{8}Z$")'

echo "Script errors:"
if AUDIT_OWNER=o AUDIT_REPOS="broken" bash scripts/ci-determinism-audit.sh > /dev/null 2>&1; then
  bad "an API error exits non-zero"
else
  ok "an API error exits non-zero"
fi

if [[ "$fails" -ne 0 ]]; then
  echo "test-ci-determinism-audit: $fails FAILED" >&2
  exit 1
fi
echo "test-ci-determinism-audit: all checks passed"
