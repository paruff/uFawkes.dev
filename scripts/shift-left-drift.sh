#!/usr/bin/env bash
# scripts/shift-left-drift.sh — one issue per repo when a shift-left check
# regresses (docs/ai-sdlc/shift-left/spec.md R6, plan D2). No regression, no issue.
#
# Usage: shift-left-drift.sh <current.json> [<previous.json>]
#   Both are shift-left-audit.sh's JSON. A regression is a cell that was "ok"
#   in the previous snapshot and is not now. Without a previous snapshot this
#   is a baseline: nothing is opened (a first run must not flood).
#   One issue "shift-left drift: <repo>", labeled shift-left-drift, holds the
#   regressed columns in a "<!-- drift: a,b -->" marker. Each run re-checks
#   those columns: an issue is opened or edited when they change, and closed
#   when they are all ok again.
#
# Environment:
#   DRIFT_REPO  where the issues live (default $GITHUB_REPOSITORY)
#   GH_TOKEN    needs issues: write on DRIFT_REPO
set -euo pipefail

current="${1:?usage: shift-left-drift.sh <current.json> [<previous.json>]}"
previous="${2:-}"
[[ -f "$current" ]] || {
  echo "shift-left-drift: no such file: $current" >&2
  exit 1
}
repo="${DRIFT_REPO:-${GITHUB_REPOSITORY:?set DRIFT_REPO or GITHUB_REPOSITORY}}"
label=shift-left-drift
issues="$(gh issue list --repo "$repo" --label "$label" --state open --limit 100 --json number,title,body)"

DRIFT_ISSUES="$issues" python3 - "$current" "$previous" "$repo" "$label" << 'PY'
import json, os, re, subprocess, sys

current_path, previous_path, repo, label = sys.argv[1:5]
cells = lambda doc: {r["repo"]: r["cells"] for r in doc["repos"]}
cur = cells(json.load(open(current_path)))
try:
    prev = cells(json.load(open(previous_path))) if previous_path else {}
except (OSError, ValueError, KeyError):
    prev = {}  # unreadable: a baseline, not an alarm
open_issues = {}
for i in json.loads(os.environ["DRIFT_ISSUES"]):
    m = re.fullmatch(r"shift-left drift: (.+)", i["title"])
    if m:
        marker = re.search(r"<!-- drift: ([^>]*?) -->", i["body"] or "")
        open_issues[m.group(1)] = (i["number"], marker.group(1).split(",") if marker and marker.group(1) else [])

def gh(*args):
    subprocess.run(["gh", *args], check=True)

label_made = False
for name, now in cur.items():
    number, tracked = open_issues.get(name, (None, []))
    regressed = [c for c, v in now.items() if v != "ok" and prev.get(name, {}).get(c) == "ok"]
    cols = sorted({c for c in tracked if now.get(c) != "ok"} | set(regressed))
    if not cols:
        if number:
            gh("issue", "close", str(number), "--repo", repo, "--comment", f"{name}: {', '.join(tracked)} are ok again.")
        continue
    if number and cols == sorted(tracked):
        continue
    body = (f"These shift-left checks were ok and no longer are in **{name}**:\n\n"
            + "".join(f"- `{c}`: now `{now.get(c)}`\n" for c in cols)
            + "\nSee the matrix on https://ufawkes.dev/status/. This issue closes itself when they are ok again.\n"
            + f"\n<!-- drift: {','.join(cols)} -->")
    if number:
        gh("issue", "edit", str(number), "--repo", repo, "--body", body)
    else:
        if not label_made:
            subprocess.run(["gh", "label", "create", label, "--repo", repo, "--color", "d93f0b",
                            "--description", "A shift-left check regressed in a suite repo"], check=False)
            label_made = True
        gh("issue", "create", "--repo", repo, "--title", f"shift-left drift: {name}", "--label", label, "--body", body)
PY
