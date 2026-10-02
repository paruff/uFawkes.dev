#!/usr/bin/env bash
# scripts/suite-status.sh — build _data/suite_status.json (AC-STATUS-02, -03).
#
# 1. Runs each `check: command` AC in suite-release/acceptance.yml (60s timeout).
#    A manual AC passes only when `evidence` is a URL.
# 2. Reads Project #7 (GraphQL) for each item's release, status, labels, dates.
# 3. Writes the R3 JSON and prints a terminal summary.
#
# Exit non-zero only when the SCRIPT breaks (bad YAML, API error). A failing
# AC is a result, not a script error.
#
# Environment:
#   SUITE_STATUS_TOKEN  token with read:project (used as GH_TOKEN for the query)
#   STATUS_ITEMS_FILE   read project items from this JSON file instead of the
#                       API (tests; shape: see scripts/testdata/suite-status-items.json)
#   STATUS_NOW          override "now" (ISO 8601 UTC), for reproducible tests
#   STATUS_OUT          output path (default _data/suite_status.json)
#   STATUS_ACS          acceptance file (default docs/ai-sdlc/suite-release/acceptance.yml)
#   STATUS_SKIP_CHECKS  if set, record every command AC as "fail: skipped" (tests)
set -euo pipefail

cd "$(dirname "$0")/.."

ACS="${STATUS_ACS:-docs/ai-sdlc/suite-release/acceptance.yml}"
OUT="${STATUS_OUT:-_data/suite_status.json}"
NOW="${STATUS_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
OWNER="paruff"
PROJECT=7
TIMEOUT=60

die() {
  echo "suite-status: $*" >&2
  exit 1
}

command -v jq > /dev/null || die "jq is required"
command -v python3 > /dev/null || die "python3 is required"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- 1. acceptance criteria -------------------------------------------------
python3 - "$ACS" > "$WORK/acs.json" << 'PY' || die "cannot parse $ACS"
import json, sys, yaml
data = yaml.safe_load(open(sys.argv[1]))
if not isinstance(data, list):
    sys.exit("acceptance file must be a list")
for ac in data:
    for k in ("id", "release", "title", "check"):
        if not ac.get(k):
            sys.exit("AC missing %s: %r" % (k, ac))
    if ac["check"] not in ("command", "manual"):
        sys.exit("AC %s: check must be command or manual" % ac["id"])
json.dump(data, sys.stdout)
PY

: > "$WORK/results.jsonl"
n="$(jq length "$WORK/acs.json")"
for ((i = 0; i < n; i++)); do
  ac="$(jq -c ".[$i]" "$WORK/acs.json")"
  id="$(jq -r .id <<< "$ac")"
  check="$(jq -r .check <<< "$ac")"
  status="pass"
  detail=""
  if [[ "$check" == "manual" ]]; then
    ev="$(jq -r '.evidence // ""' <<< "$ac")"
    if [[ "$ev" =~ ^https?:// ]]; then
      status="pass"
      detail="$ev"
    else
      status="manual"
      detail="evidence pending"
    fi
  elif [[ -n "${STATUS_SKIP_CHECKS:-}" ]]; then
    status="fail"
    detail="skipped"
  else
    run="$(jq -r '.run // ""' <<< "$ac")"
    [[ -n "$run" ]] || die "$id: check is command but run is empty"
    set +e
    out="$(timeout "$TIMEOUT" bash -c "$run" 2>&1)"
    rc=$?
    set -e
    if [[ "$rc" -eq 124 ]]; then
      status="fail"
      detail="timed out after ${TIMEOUT}s"
    elif [[ "$rc" -ne 0 ]]; then
      status="fail"
      detail="$(printf '%s\n' "$out" | head -n 3 | tr '\n' ' ' | cut -c1-300)"
      [[ -n "$detail" ]] || detail="exit code $rc"
    fi
  fi
  jq -c --arg status "$status" --arg detail "$detail" \
    '{id, release, title, status: $status, detail: $detail}' <<< "$ac" >> "$WORK/results.jsonl"
done

# --- 2. project items -------------------------------------------------------
if [[ -n "${STATUS_ITEMS_FILE:-}" ]]; then
  cp "$STATUS_ITEMS_FILE" "$WORK/items.json"
else
  command -v gh > /dev/null || die "gh is required"
  export GH_TOKEN="${SUITE_STATUS_TOKEN:-${GH_TOKEN:-}}"
  [[ -n "$GH_TOKEN" ]] || die "no token: set SUITE_STATUS_TOKEN (fine-grained PAT, read:project)"
  # shellcheck disable=SC2016
  QUERY='query($owner:String!, $number:Int!, $endCursor:String) {
    user(login:$owner) { projectV2(number:$number) {
      items(first:100, after:$endCursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          release: fieldValueByName(name:"Release") { ... on ProjectV2ItemFieldSingleSelectValue { name } }
          status:  fieldValueByName(name:"Status")  { ... on ProjectV2ItemFieldSingleSelectValue { name } }
          content { ... on Issue {
            number title state url createdAt closedAt
            repository { name }
            assignees(first:1) { totalCount }
            labels(first:20) { nodes { name } }
          } }
        }
      }
    } }
  }'
  gh api graphql --paginate --slurp -f query="$QUERY" -F owner="$OWNER" -F number="$PROJECT" \
    > "$WORK/raw.json" || die "Project #$PROJECT query failed"
  jq '[ .[].data.user.projectV2.items.nodes[]
        | select(.content.number != null)
        | { release: (.release.name // ""), status: (.status.name // ""),
            number: .content.number, title: .content.title, state: .content.state,
            url: .content.url, repo: .content.repository.name,
            createdAt: .content.createdAt, closedAt: .content.closedAt,
            assigned: (.content.assignees.totalCount > 0),
            labels: [.content.labels.nodes[].name] } ]' "$WORK/raw.json" > "$WORK/items.json" \
    || die "cannot parse the Project #$PROJECT response"
fi

# --- 3. assemble the R3 document -------------------------------------------
RUN_URL=""
if [[ -n "${GITHUB_RUN_ID:-}" ]]; then
  RUN_URL="${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-paruff/uFawkes.dev}/actions/runs/${GITHUB_RUN_ID}"
fi

mkdir -p "$(dirname "$OUT")"
jq -n --slurpfile acs "$WORK/results.jsonl" --slurpfile items "$WORK/items.json" \
  --arg now "$NOW" --arg run_url "$RUN_URL" '
  def epoch: sub("Z$"; "") | strptime("%Y-%m-%dT%H:%M:%S") | mktime;
  def day: strftime("%Y-%m-%d");
  def route: if (.labels | index("goal")) then "goal"
             elif (.labels | index("model:nemotron-3-ultra")) then "nemotron"
             elif (.labels | index("model:mimo-v2.6-flash")) then "flash"
             else "unrouted" end;
  def isdone: (.state == "CLOSED") or (.status == "Done");
  ($now | epoch) as $t
  | ($acs | map(.release) | reduce .[] as $r ([]; if index($r) then . else . + [$r] end)) as $order
  | ($items[0]) as $all
  | [ $order | to_entries[] | . as $e | $e.value as $name
      | ($acs | map(select(.release == $name))) as $a
      | ($all | map(select(.release == $name))) as $is
      | ($is | map(select(isdone))) as $done
      | ($is | map(select(isdone | not))) as $open
      | ($done | map(select(.closedAt != null and ((.closedAt | epoch) >= ($t - 28*86400))))) as $recent
      | ($is | length) as $total
      | { name: $name,
          order: ($e.key + 1),
          acs: { pass: ($a | map(select(.status == "pass")) | length),
                 fail: ($a | map(select(.status == "fail")) | length),
                 manual_pending: ($a | map(select(.status == "manual")) | length),
                 total: ($a | length) },
          issues: { done: ($done | length),
                    in_progress: ($open | map(select(.status == "In Progress")) | length),
                    todo: ($open | map(select(.status != "In Progress")) | length),
                    total: $total },
          blockers: ($open | map(select(.labels | index("release-blocker")))
                     | map({repo, number, title, url})),
          routing: { goal: ($is | map(select(route == "goal")) | length),
                     nemotron: ($is | map(select(route == "nemotron")) | length),
                     flash: ($is | map(select(route == "flash")) | length) },
          pace: { closed_last_28d: ($recent | length),
                  weeks_to_done_estimate:
                    (if ($recent | length) < 3 or ($open | length) == 0 then null
                     else ((($open | length) / (($recent | length) / 4)) * 10 | round / 10) end) },
          ac_results: ($a | map({id, title, status, detail})),
          ready: ($open | map(select(.assigned | not))
                  | map({route: route, repo, number, title, url})) }
    ] as $releases
  | ($releases | map(select(.acs.pass != .acs.total)) | .[0].name // null) as $next
  | ($all | map(.createdAt | epoch) | min // $t) as $start
  | { generated_at: $now,
      run_url: $run_url,
      next_release: $next,
      releases: ($releases | map(if .name == $next then . else del(.ready) end)),
      burnup: ( [ range($start; $t; 7*86400), $t ] | unique
                | map(. as $d | { date: ($d | day),
                    done: ($all | map(select(.closedAt != null and ((.closedAt | epoch) <= $d))) | length),
                    total: ($all | map(select((.createdAt | epoch) <= $d)) | length) }) ) }
  ' > "$WORK/out.json" || die "could not assemble the status document"

mv "$WORK/out.json" "$OUT"
# Also served as /status/suite_status.json (static file; no front matter, so Jekyll copies it as-is).
if [[ "$OUT" == "_data/suite_status.json" ]]; then
  cp "$OUT" status/suite_status.json
fi

# --- 4. terminal summary ----------------------------------------------------
echo "Suite status as of $NOW  ->  $OUT"
jq -r '
  "Next release: \(.next_release // "none (all acceptance checks pass)")",
  (.releases[] | "  \(.name): ACs \(.acs.pass)/\(.acs.total) pass (\(.acs.fail) fail, \(.acs.manual_pending) manual pending) | issues \(.issues.done)/\(.issues.total) done | \(.blockers | length) blocker(s)")' "$OUT"
