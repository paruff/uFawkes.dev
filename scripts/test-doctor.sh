#!/usr/bin/env bash
# scripts/test-doctor.sh — fault injection for scripts/doctor.sh (shift-left
# spec R5, AC-SHIFT-01, -02, -07). Each scenario copies one healthy throwaway
# repo, breaks one thing, and asserts the doctor names it, and only it.
set -euo pipefail

# Git exports GIT_INDEX_FILE (and friends) to hooks; run from the unit-tests
# hook, they would point the throwaway repos at the real index. See
# test-artifact-chain.sh.
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_PREFIX GIT_COMMON_DIR
# Likewise a real push exports PRE_COMMIT_TO_REF (and friends) to its hooks;
# leaked into a throwaway push, the stamp records the outer repo's ref.
while read -r v; do unset "$v"; done < <(compgen -e | grep '^PRE_COMMIT')
# And CI's SKIP list (shift-left-stamp, ...) would skip the throwaway repos' stamps.
unset SKIP

cd "$(dirname "$0")/.."
HERE="$PWD"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export PRE_COMMIT_HOME="$TMP/pre-commit-home" # never touch the real cache
unset SHIFT_LEFT_ALLOW_MISSING
fails=0
check() { # check <description> <command...>
  local desc="$1"
  shift
  if "$@"; then echo "  ok   $desc"; else
    echo "  FAIL $desc"
    fails=$((fails + 1))
  fi
}
# doctor <repo> [args] -> sets $out and $rc
doctor() {
  local repo="$1"
  shift
  out="$(cd "$repo" && bash scripts/doctor.sh "$@" 2>&1)" && rc=0 || rc=$?
}
says() { grep -qE "$1" <<< "$out"; }
fails_only() { # the FAIL lines name exactly this check id
  [[ "$(grep -oE 'FAIL +D[0-9]' <<< "$out" | awk '{print $2}' | sort -u | tr '\n' ' ')" == "$1 " ]]
}
git_q() { git -c user.email=t@example.invalid -c user.name=t "$@"; }

# --- the healthy template ----------------------------------------------------
T="$TMP/template"
mkdir -p "$T/scripts" "$T/src"
cp scripts/doctor.sh scripts/require-tool.sh scripts/shift-left-stamp.sh scripts/check-shift-left-parity.sh "$T/scripts/"
cat > "$T/scripts/lint.sh" << 'SH'
#!/usr/bin/env bash
exit 0
SH
chmod +x "$T/scripts/"*.sh
echo "x = 1" > "$T/src/app.py"
cat > "$T/.pre-commit-config.yaml" << 'YML'
minimum_pre_commit_version: "3.0.0"
default_install_hook_types: [pre-commit, commit-msg, pre-push]
repos:
  - repo: local
    hooks:
      - id: lint
        name: lint
        entry: scripts/lint.sh
        language: script
        files: ^src/
      - id: needs-tool
        name: needs a tool
        entry: scripts/require-tool.sh git -- true
        language: script
        files: ^src/
      - id: never-applies
        name: tool missing, but no file here uses it
        entry: scripts/require-tool.sh nosuchtool -- true
        language: script
        files: ^infra/
      - id: commit-msg
        name: commit msg
        entry: "true"
        language: system
        stages: [commit-msg]
      - id: shift-left-stamp
        name: stamp
        entry: scripts/shift-left-stamp.sh pre-commit
        language: script
        always_run: true
        pass_filenames: false
      - id: shift-left-stamp-pre-push
        name: stamp
        entry: scripts/shift-left-stamp.sh pre-push
        language: script
        always_run: true
        pass_filenames: false
        stages: [pre-push]
YML
mkdir -p "$T/.github/workflows"
cat > "$T/.github/workflows/ci.yml" << 'YML'
jobs:
  hooks:
    steps:
      - run: pre-commit run --all-files
      - run: pre-commit run --all-files --hook-stage pre-push
      - run: pre-commit run --hook-stage commit-msg --commit-msg-filename "$f"
YML
cat > "$T/.shift-left.yml" << 'YML'
local-only:
  - id: shift-left-stamp
    reason: records that hooks ran in this clone
  - id: shift-left-stamp-pre-push
    reason: as above, for pre-push
YML
(
  cd "$T"
  git init -q -b main
  pre-commit install > /dev/null
  git add -A
  git_q commit -qm "chore: init" > /dev/null 2>&1
) || {
  echo "test-doctor: cannot build the template repo" >&2
  exit 1
}
scenario() { # scenario <name> -> fresh copy of the template, path in $R
  R="$TMP/$1"
  cp -R "$T" "$R"
  # pre-commit's hook scripts hold no repo path, so the copy's hooks work as-is
}

s1() {
  echo "Healthy:"
  scenario healthy
  doctor "$R"
  check "exits 0" test "$rc" -eq 0
  check "a line per check" says "ok +D5"
  doctor "$R" --quiet
  check "--quiet prints nothing" test -z "$out"
}

s2() {
  echo "D1 uninstalled stage (AC-SHIFT-01):"
  scenario no-commit-msg
  rm "$R/.git/hooks/commit-msg"
  doctor "$R"
  check "exits 1" test "$rc" -eq 1
  check "names the stage" says "FAIL +D1 .*commit-msg hook is not installed"
  check "and the fix" says "fix: pre-commit install$"
  check "only D1 fails" fails_only D1
  scenario foreign-hook
  echo '#!/bin/sh' > "$R/.git/hooks/pre-push"
  doctor "$R"
  check "a hook pre-commit didn't write is not 'installed'" fails_only D1
}

s3() {
  echo "D2 hook entries:"
  scenario deleted-script
  git -C "$R" rm -q scripts/lint.sh
  doctor "$R"
  check "a deleted hook script fails D2 by name" says "FAIL +D2 .*lint.*scripts/lint.sh"
  check "only D2 fails" fails_only D2
  scenario missing-tool
  sed -i.bak 's/require-tool.sh git/require-tool.sh nosuchtool/' "$R/.pre-commit-config.yaml"
  doctor "$R"
  check "a missing tool fails D2 by name (AC-SHIFT-02)" says "FAIL +D2 .*nosuchtool"
  SHIFT_LEFT_ALLOW_MISSING=nosuchtool doctor "$R"
  check "allowed: passes" test "$rc" -eq 0
  check "allowed: still listed" says "SKIPPED.*nosuchtool"
  SHIFT_LEFT_ALLOW_MISSING=nosuchtool doctor "$R" --quiet
  check "allowed: quiet stays quiet" test -z "$out"
  check "a hook no tracked file uses is not checked" bash -c "! grep -q never-applies <<< \"\$0\"" "$out"
}

s4() {
  echo "D3 pre-commit itself:"
  scenario old-pre-commit
  mkdir -p "$TMP/oldbin"
  printf '#!/usr/bin/env bash\necho "pre-commit 2.1.0"\n' > "$TMP/oldbin/pre-commit"
  chmod +x "$TMP/oldbin/pre-commit"
  out="$(cd "$R" && PATH="$TMP/oldbin:$PATH" bash scripts/doctor.sh 2>&1)" && rc=0 || rc=$?
  check "older than minimum_pre_commit_version fails D3" says "FAIL +D3 .*2\.1\.0.*3\.0\.0"
}

s5() {
  echo "D4 config:"
  scenario bad-config
  printf 'repos: [\n' > "$R/.pre-commit-config.yaml"
  doctor "$R"
  check "an invalid config fails D4" says "FAIL +D4"
  check "and exits 1" test "$rc" -eq 1
}

s6() {
  echo "D5 stamps:"
  scenario no-verify
  echo "x = 2" > "$R/src/app.py"
  git -C "$R" add -A
  (cd "$R" && git_q commit -q --no-verify -m "feat: skip hooks") > /dev/null 2>&1
  doctor "$R"
  check "a --no-verify commit fails D5" says "FAIL +D5 .*pre-commit"
  check "only D5 fails" fails_only D5
  echo "x = 3" > "$R/src/app.py"
  git -C "$R" add -A
  (cd "$R" && git_q commit -q -m "feat: with hooks") > /dev/null 2>&1
  doctor "$R"
  check "the next normal commit clears it" test "$rc" -eq 0
}

s7() {
  echo "D5 push stamps:"
  scenario push
  git init -q --bare "$TMP/remote.git"
  git -C "$R" remote add origin "$TMP/remote.git"
  git -C "$R" push -q origin main > /dev/null 2>&1
  git -C "$R" switch -qc feature
  echo "x = 4" > "$R/src/app.py"
  git -C "$R" add -A
  (cd "$R" && git_q commit -q -m "feat: feature") > /dev/null 2>&1
  git -C "$R" push -q -u origin feature > /dev/null 2>&1
  doctor "$R"
  check "a branch pushed with hooks passes" test "$rc" -eq 0
  echo "x = 5" > "$R/src/app.py"
  git -C "$R" add -A
  (cd "$R" && git_q commit -q -m "feat: more") > /dev/null 2>&1
  git -C "$R" push -q --no-verify > /dev/null 2>&1
  doctor "$R"
  check "a --no-verify push fails D5 pre-push" says "FAIL +D5 .*pre-push"
}

# The scenarios are independent: run them at once, print them in order.
s8() {
  echo "D6 CI parity:"
  scenario no-ci-pre-commit
  sed -i.bak '/pre-commit run --all-files$/d' "$R/.github/workflows/ci.yml"
  rm "$R/.github/workflows/ci.yml.bak"
  doctor "$R"
  check "CI no longer runs the pre-commit stage: D6 names the hook" says "FAIL +D6 .*hook lint .*pre-commit"
  check "only D6 fails" fails_only D6
}

# A scenario that dies part-way (set -u, a failed git step) is a failure,
# not a pass with fewer checks.
SCENARIOS=(s1 s2 s3 s4 s5 s6 s7 s8)
for s in "${SCENARIOS[@]}"; do
  (
    set -e
    "$s"
  ) > "$TMP/$s.log" 2>&1 || echo "  FAIL scenario $s stopped early (exit $?)" >> "$TMP/$s.log" &
done
wait
for s in "${SCENARIOS[@]}"; do cat "$TMP/$s.log"; done
fails="$(cat "$TMP"/s*.log | grep -c '^  FAIL' || true)"

cd "$HERE"
if [[ "$fails" -ne 0 ]]; then
  echo "test-doctor: $fails FAILED" >&2
  exit 1
fi
echo "test-doctor: all checks passed"
