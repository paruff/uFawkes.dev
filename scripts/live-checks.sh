#!/usr/bin/env bash
# scripts/live-checks.sh — the suite's scheduled workflows, latest run on main
# (docs/ai-sdlc/suite-release/live-checks.yml; suite-status plan, Tier 2).
# Read-only.
#
# For every entry in live-checks.yml the workflow's latest run on `main` is
# read through `gh api` and reported as:
#   pass     last run succeeded, within stale_after_hours
#   stale    last run succeeded but is older than stale_after_hours, or its
#            conclusion verified nothing (neutral, skipped)
#   fail     last run failed or was cancelled; up to 3 failed step names print
#   running  a run is in flight
#   none     no run on main yet
#
# An entry naming a workflow the API does not know is a script error: the
# YAML has drifted from the repo and must be fixed. A failing nightly is a
# result, not an error.
#
# --json <path> also writes the results as JSON for /status/; for
# _data/live_checks.json it is also copied to status/live_checks.json.
#
# Exit non-zero only when the SCRIPT breaks (API error, bad YAML, unknown
# workflow). A red nightly never fails this script.
#
# Environment:
#   LC_OWNER  GitHub owner (default paruff)
#   LC_FILE   the YAML list (default docs/ai-sdlc/suite-release/live-checks.yml)
#   LC_NOW    override "now" (ISO 8601 UTC), for the offline tests
set -euo pipefail

cd "$(dirname "$0")/.."

OWNER="${LC_OWNER:-paruff}"
FILE="${LC_FILE:-docs/ai-sdlc/suite-release/live-checks.yml}"
JSON=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      JSON="${2:?--json needs a path}"
      shift
      ;;
    *)
      echo "live-checks: unknown argument: $1" >&2
      exit 1
      ;;
  esac
  shift
done

die() {
  echo "live-checks: $*" >&2
  exit 1
}

command -v gh > /dev/null || die "gh is required"
command -v python3 > /dev/null || die "python3 is required"
[[ -f "$FILE" ]] || die "no such file: $FILE"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# repo<TAB>workflow<TAB>stale_after_hours for every entry; YAML errors die here.
python3 - "$FILE" > "$WORK/entries.tsv" << 'PY' || die "cannot parse $FILE"
import sys, yaml
data = yaml.safe_load(open(sys.argv[1])) or {}
checks = data.get("checks")
if not isinstance(checks, list) or not checks:
    sys.exit(f"{sys.argv[1]}: no `checks` list")
for i, c in enumerate(checks):
    for key in ("repo", "workflow", "stale_after_hours"):
        if key not in c:
            sys.exit(f"{sys.argv[1]}: checks[{i}] is missing `{key}`")
    print(c["repo"], c["workflow"], c["stale_after_hours"], sep="\t")
PY

# Fetch each entry's latest run on main, then the failed steps of a failed run.
# The runs listing is eventually consistent and has been seen to serve an
# older page (a Sep run where the newest was same-day): read it twice, use the
# later read, and say so when the two disagree.
fetch_runs() { # <repo> <workflow> -> tsv row on stdout, empty when no runs
  local out
  if out="$(gh api "repos/$OWNER/$1/actions/workflows/$2/runs?branch=main&per_page=1" \
    --jq 'if (.workflow_runs | length) == 0 then "" else (.workflow_runs[0] | [.status, (.conclusion // ""), (.created_at // ""), (.html_url // ""), ((.id // 0) | tostring)] | @tsv) end' 2>&1)"; then
    printf '%s' "$out"
  else
    [[ "$out" == *"HTTP 404"* ]] && die "$1/$2: live-checks.yml names a workflow the API does not know (renamed or deleted?)"
    die "$1/$2: $out"
  fi
}

: > "$WORK/facts.tsv"
while IFS=$'\t' read -r repo wf stale_after; do
  row1="$(fetch_runs "$repo" "$wf")"
  row="$(fetch_runs "$repo" "$wf")"
  if [[ "$row1" != "$row" ]]; then
    echo "live-checks: unstable runs listing for $repo/$wf; used the later read" >&2
  fi
  if [[ -z "$row" ]]; then
    printf '%s\t%s\t%s\t%s\t\t\t\t\n' "$repo" "$wf" "$stale_after" "none" >> "$WORK/facts.tsv"
    continue
  fi
  IFS=$'\t' read -r status conclusion created url run_id <<< "$row"
  steps=""
  case "$conclusion" in
    failure | timed_out | cancelled | action_required)
      if ! steps="$(gh api "repos/$OWNER/$repo/actions/runs/$run_id/jobs?per_page=100" \
        --jq '[.jobs[].steps[]? | select(.conclusion == "failure") | .name] | unique | .[0:3] | join(", ")' 2>&1)"; then
        die "$repo/$wf: cannot read the failed steps of run $run_id: $steps"
      fi
      ;;
  esac
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$repo" "$wf" "$stale_after" "$status" "$conclusion" "$created" "$url" "$steps" >> "$WORK/facts.tsv"
done < "$WORK/entries.tsv"

# The table, and the JSON for /status/. Classification happens here so both
# always agree; age math is python because BSD and GNU date disagree.
python3 - "$FILE" "$WORK/facts.tsv" "$JSON" << 'PY' || die "cannot build the report"
import datetime, json, os, sys, yaml

path, facts_path, json_out = sys.argv[1], sys.argv[2], sys.argv[3]
now = os.environ.get("LC_NOW") or datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
now_dt = datetime.datetime.strptime(now, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)

facts = {}
for line in open(facts_path):
    repo, wf, stale_after, status, conclusion, created, url, steps = line.rstrip("\n").split("\t")
    facts[(repo, wf)] = {
        "stale_after_hours": int(stale_after), "status": status, "conclusion": conclusion,
        "last_run_at": created, "run_url": url, "failed_steps": [s for s in steps.split(", ") if s],
    }

entries = (yaml.safe_load(open(path)) or {}).get("checks") or []
rows, checks = [], []
for e in entries:
    f = facts[(e["repo"], e["workflow"])]
    state, note = "", ""
    if f["status"] == "none" or not f["last_run_at"]:
        state = "none"
    elif f["status"] != "completed":
        state = "running"
    elif f["conclusion"] == "success":
        age = (now_dt - datetime.datetime.strptime(f["last_run_at"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)).total_seconds() / 3600
        state = "stale" if age > f["stale_after_hours"] else "pass"
        note = f"{age:.0f}h ago"
    elif f["conclusion"] in ("neutral", "skipped"):
        state = "stale"
        note = f"last run {f['conclusion']} — verified nothing"
    else:
        state = "fail"
        note = ", ".join(f["failed_steps"]) or f["conclusion"]
    rows.append([e["repo"], e["workflow"], state, f["last_run_at"] or "-", note])

widths = [max(len(t[i]) for t in [["repo", "workflow", "state", "last run", "note"]] + rows) for i in range(5)]
for t in [["repo", "workflow", "state", "last run", "note"]] + rows:
    print("  ".join(v.ljust(w) for v, w in zip(t, widths)).rstrip())

if json_out:
    data = {
        "generated_at": now,
        "run_url": f"{os.environ.get('GITHUB_SERVER_URL', 'https://github.com')}/{os.environ.get('GITHUB_REPOSITORY', '')}/actions/runs/{os.environ['GITHUB_RUN_ID']}" if os.environ.get("GITHUB_RUN_ID") else "",
        "checks": [],
    }
    for e in entries:
        f = facts[(e["repo"], e["workflow"])]
        row = next(r for r in rows if r[0] == e["repo"] and r[1] == e["workflow"])
        data["checks"].append({
            "repo": e["repo"],
            "workflow": e["workflow"],
            "purpose": e.get("purpose", ""),
            "starts_stack": bool(e.get("starts_stack", False)),
            "state": row[2],
            "last_run_at": f["last_run_at"] if f["last_run_at"] else "",
            "run_url": f["run_url"],
            "failed_steps": f["failed_steps"],
            "stale_after_hours": f["stale_after_hours"],
        })
    with open(json_out, "w") as fh:
        json.dump(data, fh, indent=2)
        fh.write("\n")
PY

# Also served as /status/live_checks.json (static file, copied as-is by Jekyll).
if [[ "$JSON" == "_data/live_checks.json" ]]; then
  cp "$JSON" status/live_checks.json
fi
