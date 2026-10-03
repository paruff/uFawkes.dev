#!/usr/bin/env bash
# scripts/shift-left-stamp.sh — record that a hook stage ran, and on what
# (shift-left spec R5, D5). Run as the last, always-run hook of each stage;
# scripts/doctor.sh compares the stamp with the commit or push it belongs to.
#
# Usage: shift-left-stamp.sh <pre-commit|pre-push>
#   pre-commit stamps the tree about to be committed (`git write-tree`);
#   pre-push stamps the tree of the commit being pushed.
# A stamp means the hooks ran on that content, not that they passed: a failed
# run blocks the commit, and CI catches a --no-verify after one.
set -euo pipefail

stage="${1:?usage: shift-left-stamp.sh <pre-commit|pre-push>}"
case "$stage" in
  pre-commit) tree="$(git write-tree)" ;;
  pre-push) tree="$(git rev-parse "${PRE_COMMIT_TO_REF:-HEAD}^{tree}")" ;;
  *)
    echo "shift-left-stamp: unknown stage $stage" >&2
    exit 2
    ;;
esac
dir="$(git rev-parse --git-path shift-left)"
mkdir -p "$dir"
echo "$tree" > "$dir/$stage"
