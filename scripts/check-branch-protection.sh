#!/usr/bin/env bash
# scripts/check-branch-protection.sh — does each suite repo's main protection
# match docs/ai-sdlc/suite-hygiene/main-protection.md? Read-only: GET calls only,
# nothing is changed (plan H, uFawkes.dev#152).
#
# Prints one line per departure, "<repo>: <what>", and nothing for a repo that
# matches. Exit 0: no departures. Exit 1: at least one. Exit 2: the script
# couldn't read a repo (an API or auth fault is not a result).
#
# Checks, per repo, against the default branch:
#   - exactly one ruleset applies to it, named main-protection; no ruleset
#     matches nothing (an empty include is inert); no classic branch protection
#   - it blocks deletion and force pushes, requires linear history and a pull
#     request, and requires the hook job and Artifact Chain as checks
#   - no bypass actors, except where the owner decided otherwise
#   - squash-only merging, delete branch on merge, a single CODEOWNERS
#
# Environment:
#   AUDIT_OWNER             GitHub owner (default paruff)
#   AUDIT_REPOS             space-separated repos (default: the ten suite repos)
#   PROTECTION_ALLOW_BYPASS repos allowed a repository-admin bypass for pull
#                           requests (default: uFawkes.dev, the owner's decision
#                           of 2026-10-07)
set -euo pipefail

command -v gh > /dev/null || {
  echo "check-branch-protection: gh is required" >&2
  exit 2
}
export AUDIT_OWNER="${AUDIT_OWNER:-paruff}"
export AUDIT_REPOS="${AUDIT_REPOS:-uFawkes.dev uFawkesAI uFawkesObs uFawkesPipe uFawkesDevX uFawkesDojo fawkes java-fawkes-path python-fawkes-path python-fawkes-path-gitops}"
export PROTECTION_ALLOW_BYPASS="${PROTECTION_ALLOW_BYPASS:-uFawkes.dev}"

python3 - << 'PY'
import json, os, re, subprocess, sys

owner = os.environ["AUDIT_OWNER"]
allow_bypass = set(os.environ["PROTECTION_ALLOW_BYPASS"].split())


def fault(msg):
    print(f"check-branch-protection: {msg}", file=sys.stderr)
    sys.exit(2)


def api(path, *, missing_ok=False):
    r = subprocess.run(["gh", "api", path], capture_output=True, text=True)
    if r.returncode == 0:
        return r.stdout
    if missing_ok and "404" in r.stderr:
        return None
    fault(f"{path}: {r.stderr.strip() or 'gh api failed'}")


departures = 0
for repo in os.environ["AUDIT_REPOS"].split():
    base = f"repos/{owner}/{repo}"
    info = json.loads(api(base))
    branch = info["default_branch"]
    found = []

    # Repository settings.
    if not info.get("delete_branch_on_merge"):
        found.append("delete branch on merge is off (a stacked PR stays pointed at its merged base)")
    if not (info.get("allow_squash_merge") and not info.get("allow_merge_commit") and not info.get("allow_rebase_merge")):
        found.append("merge methods are not squash-only")

    # Rulesets: which apply to the default branch, which are inert.
    applicable = []
    for stub in json.loads(api(f"{base}/rulesets")):
        rs = json.loads(api(f"{base}/rulesets/{stub['id']}"))
        if rs.get("target") != "branch" or rs.get("enforcement") != "active":
            continue
        include = rs["conditions"]["ref_name"].get("include") or []
        if not include:
            found.append(f'ruleset "{rs["name"]}" matches no branch (empty include), so it protects nothing')
        elif any(i in ("~DEFAULT_BRANCH", "~ALL", f"refs/heads/{branch}") for i in include):
            applicable.append(rs)
    if api(f"{base}/branches/{branch}/protection", missing_ok=True) is not None:
        found.append("classic branch protection is also set, on top of the ruleset")

    if not applicable:
        found.append(f"no main-protection ruleset applies to {branch}")
    else:
        if len(applicable) > 1:
            found.append("more than one ruleset applies to " + branch + ": " + ", ".join(r["name"] for r in applicable))
        if not any(r["name"] == "main-protection" for r in applicable):
            found.append(f'the ruleset is named "{applicable[0]["name"]}", expected main-protection')
        types = {rule["type"] for r in applicable for rule in r["rules"]}
        checks = [c["context"] for r in applicable for rule in r["rules"] if rule["type"] == "required_status_checks"
                  for c in rule["parameters"]["required_status_checks"]]
        if "deletion" not in types:
            found.append("branch deletion is not blocked (no deletion rule)")
        if "non_fast_forward" not in types:
            found.append("force pushes are not blocked (no non_fast_forward rule)")
        if "required_linear_history" not in types:
            found.append("linear history is not required (no required_linear_history rule)")
        if "pull_request" not in types:
            found.append("no pull request is required (no pull_request rule)")
        if not any(re.search(r"pre-?flight|pre-?commit", c, re.I) for c in checks):
            found.append("the hook job is not a required check")
        if not any(re.search(r"artifact chain", c, re.I) for c in checks):
            found.append("Artifact Chain is not a required check")
        for r in applicable:
            for actor in r.get("bypass_actors") or []:
                decided = repo in allow_bypass and actor.get("actor_type") == "RepositoryRole" \
                    and actor.get("actor_id") == 5 and actor.get("bypass_mode") == "pull_request"
                if not decided:
                    found.append(f'ruleset "{r["name"]}" has a bypass actor ({actor.get("actor_type")} {actor.get("actor_id")}, {actor.get("bypass_mode")})')

    # CODEOWNERS: GitHub reads .github/ first, so a root copy is ignored.
    if api(f"{base}/contents/CODEOWNERS", missing_ok=True) is not None and \
            api(f"{base}/contents/.github/CODEOWNERS", missing_ok=True) is not None:
        found.append("two CODEOWNERS files; GitHub reads only .github/CODEOWNERS")

    for line in found:
        print(f"{repo}: {line}")
    departures += len(found)

sys.exit(1 if departures else 0)
PY
