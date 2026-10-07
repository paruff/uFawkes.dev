#!/usr/bin/env bash
# scripts/test-check-branch-protection.sh — check-branch-protection.sh reports
# each way a repo departs from docs/ai-sdlc/suite-hygiene/main-protection.md,
# names it, and reports nothing for a repo that matches. A stub gh serves
# fixture repos (plan H, uFawkes.dev#152).
set -euo pipefail

unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_PREFIX GIT_COMMON_DIR
cd "$(dirname "$0")/.."
SCRIPT="$PWD/scripts/check-branch-protection.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fails=0
check() { # check <description> <command...>
  local desc="$1"
  shift
  if "$@"; then echo "  ok   $desc"; else
    echo "  FAIL $desc"
    fails=$((fails + 1))
  fi
}

# A gh that answers from $FX/<repo>/: repo.json, rulesets.json (a list), ruleset-<id>.json,
# classic.json (absent = 404), codeowners-root / codeowners-gh (present = exists).
mkdir -p "$TMP/bin"
cat > "$TMP/bin/gh" << 'STUB'
#!/usr/bin/env bash
[[ "$1" == api ]] || exit 1
path="$2"
repo="$(cut -d/ -f3 <<< "$path")"
d="$FX/$repo"
case "$path" in
  */rulesets/*) f="$d/ruleset-${path##*/}.json" ;;
  */rulesets) f="$d/rulesets.json" ;;
  */branches/*/protection) f="$d/classic.json" ;;
  */contents/CODEOWNERS) f="$d/codeowners-root" ;;
  */contents/.github/CODEOWNERS) f="$d/codeowners-gh" ;;
  *) f="$d/repo.json" ;;
esac
[[ -f "$f" ]] || { echo "gh: HTTP 404" >&2; exit 1; }
cat "$f"
STUB
chmod +x "$TMP/bin/gh"
export PATH="$TMP/bin:$PATH"

# build <name> [mutation...]: a healthy fixture repo, then one named departure.
build() {
  python3 - "$TMP/fx" "$@" << 'PY'
import json, os, sys
fx, name, *muts = sys.argv[1:]
d = os.path.join(fx, name)
os.makedirs(d, exist_ok=True)
repo = {"name": name, "default_branch": "main", "allow_squash_merge": True, "allow_merge_commit": False,
        "allow_rebase_merge": False, "delete_branch_on_merge": True}
rules = [{"type": "deletion"}, {"type": "non_fast_forward"}, {"type": "required_linear_history"},
         {"type": "pull_request", "parameters": {}},
         {"type": "required_status_checks", "parameters": {"required_status_checks": [
             {"context": "Pre-flight / Pre-flight Checks"}, {"context": "🔗 Artifact Chain"}]}}]
rs = {"id": 1, "name": "main-protection", "enforcement": "active", "target": "branch",
      "conditions": {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}}, "bypass_actors": [], "rules": rules}
extra, classic, owners = [], False, ("gh",)
for m in muts:
    if m == "no-hook": rules[4]["parameters"]["required_status_checks"] = [{"context": "🔗 Artifact Chain"}]
    elif m == "no-chain": rules[4]["parameters"]["required_status_checks"] = [{"context": "Pre-flight / Pre-flight Checks"}]
    elif m == "no-linear": rules.remove({"type": "required_linear_history"})
    elif m == "no-deletion": rules.remove({"type": "deletion"})
    elif m == "no-pr": rules.remove(rules[3])
    elif m == "no-nff": rules.remove({"type": "non_fast_forward"})
    elif m == "bypass": rs["bypass_actors"] = [{"actor_type": "RepositoryRole", "actor_id": 5, "bypass_mode": "pull_request"}]
    elif m == "classic": classic = True
    elif m == "inert": extra.append({"id": 2, "name": "validate", "enforcement": "active", "target": "branch",
                                     "conditions": {"ref_name": {"include": [], "exclude": []}}, "bypass_actors": [], "rules": []})
    elif m == "rename": rs["name"] = "main protection"
    elif m == "keep-branch": repo["delete_branch_on_merge"] = False
    elif m == "merge-commits": repo["allow_merge_commit"] = True
    elif m == "owners-dup": owners = ("gh", "root")
    elif m == "no-ruleset": rs = None
    else: raise SystemExit("unknown mutation " + m)
all_rs = ([rs] if rs else []) + extra
json.dump(repo, open(os.path.join(d, "repo.json"), "w"))
json.dump([{"id": r["id"], "name": r["name"]} for r in all_rs], open(os.path.join(d, "rulesets.json"), "w"))
for r in all_rs:
    json.dump(r, open(os.path.join(d, f"ruleset-{r['id']}.json"), "w"))
if classic: json.dump({"required_pull_request_reviews": {"required_approving_review_count": 1}}, open(os.path.join(d, "classic.json"), "w"))
if "gh" in owners: open(os.path.join(d, "codeowners-gh"), "w").write("* @o\n")
if "root" in owners: open(os.path.join(d, "codeowners-root"), "w").write("* @o\n")
PY
}
audit() { # audit <repo> [env...] -> $out, $rc
  local repo="$1"
  shift
  out="$(env ${1:+"$@"} FX="$TMP/fx" AUDIT_OWNER=o AUDIT_REPOS="$repo" bash "$SCRIPT" 2>&1)" && rc=0 || rc=$?
}
says() { grep -qiE "$1" <<< "$out"; }
only() { [[ "$(grep -c . <<< "$out")" == 1 ]] && says "$1"; }

echo "A repo that matches the standard:"
build good
audit good
check "reports nothing and exits 0" test "$rc" -eq 0 -a -z "$out"

echo "Each departure alone is named, and only it:"
n=0
while read -r mut pat; do
  n=$((n + 1))
  build "r$n" "$mut"
  audit "r$n"
  check "$mut: exits 1" test "$rc" -eq 1
  check "$mut: names it, and only it" only "$pat"
done << 'EOF'
no-hook hook job
no-chain artifact chain
no-linear linear history
no-deletion deletion
no-pr pull request
no-nff non.fast.forward
bypass bypass
classic classic
inert matches no branch
rename main-protection
keep-branch delete branch
merge-commits squash
owners-dup codeowners
no-ruleset no main-protection
EOF

echo "A decision the owner made is not a delta:"
build allowed bypass
audit allowed PROTECTION_ALLOW_BYPASS=allowed
check "an allowed repo's admin bypass is fine" test "$rc" -eq 0 -a -z "$out"

echo "Faults are loud, and are not a result:"
audit missing
check "an unreadable repo exits 2, not 1" test "$rc" -eq 2

if [[ "$fails" -ne 0 ]]; then
  echo "test-check-branch-protection: $fails FAILED" >&2
  exit 1
fi
echo "test-check-branch-protection: all checks passed"
