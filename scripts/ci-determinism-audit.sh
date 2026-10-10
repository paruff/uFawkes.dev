#!/usr/bin/env bash
# scripts/ci-determinism-audit.sh — how deterministic each suite repo's CI is
# (docs/ai-sdlc/ci-pipeline/spec.md R10, AC-1..3, AC-7). Read-only.
#
# Reads each repo's .github/workflows/*.yml, .devcontainer/devcontainer.json and
# .pipeline.yml from the default branch through `gh api`, and prints a matrix:
#   pipe_refs      ok = one uFawkesPipe SHA; n = n distinct refs; n/a = calls none
#   local_copies   ok = none; n = workflow files named like a Pipe reusable
#   ci_image       ok = the hook job runs in ghcr.io/paruff/ufawkes-ci@sha256:...
#                  (one digest across the suite); else what it runs in
#   release_match  ok = the uFawkesAI release behind ufawkes-ci's FROM is the one the
#                  devcontainer's fawkes-space pins; n/a = either side not readable
#   unpinned       ok = none; n = `uses:` without a 40-hex SHA, images without @sha256
#   silent         ok = none; n = continue-on-error: true / `|| true` not listed
#                  under `informational:` in .pipeline.yml
#
# --json <path> also writes the matrix, with the findings behind each cell, for
# /status/; for _data/ci_determinism.json it is also copied to status/.
#
# Exit non-zero only when the SCRIPT breaks (API error, bad YAML). A finding is a
# result, not a script error.
#
# Environment:
#   AUDIT_OWNER  GitHub owner (default paruff)
#   AUDIT_REPOS  space-separated repo list (default: the seven suite repos)
set -euo pipefail

cd "$(dirname "$0")/.."

OWNER="${AUDIT_OWNER:-paruff}"
read -r -a REPOS <<< "${AUDIT_REPOS:-uFawkes.dev uFawkesAI uFawkesObs uFawkesPipe uFawkesDevX uFawkesDojo fawkes}"
JSON=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      JSON="${2:?--json needs a path}"
      shift
      ;;
    *)
      echo "ci-determinism-audit: unknown argument: $1" >&2
      exit 1
      ;;
  esac
  shift
done

die() {
  echo "ci-determinism-audit: $*" >&2
  exit 1
}

command -v gh > /dev/null || die "gh is required"
command -v python3 > /dev/null || die "python3 is required"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# fetch <repo> <path> <dest> -> 0 and the file, 1 if it is not there. Any other API error is fatal.
fetch() {
  local out
  if out="$(gh api "repos/$OWNER/$1/contents/$2" --jq .content 2>&1)"; then
    printf '%s' "$out" | base64 -d > "$3" || die "$1: cannot decode $2"
  elif [[ "$out" == *"HTTP 404"* ]]; then
    return 1
  else
    die "$1: $2: $out"
  fi
}

for r in "${REPOS[@]}"; do
  mkdir -p "$WORK/$r/wf"
  if names="$(gh api "repos/$OWNER/$r/contents/.github/workflows" --jq '.[] | select(.name | test("\\.ya?ml$")) | .name' 2>&1)"; then
    while IFS= read -r n; do
      [[ -n "$n" ]] && { fetch "$r" ".github/workflows/$n" "$WORK/$r/wf/$n" || die "$r: $n vanished"; }
    done <<< "$names"
  elif [[ "$names" != *"HTTP 404"* ]]; then
    die "$r: $names"
  fi
  fetch "$r" .devcontainer/devcontainer.json "$WORK/$r/devcontainer.json" || true
  fetch "$r" .pipeline.yml "$WORK/$r/pipeline.yml" || true
done

python3 - "$WORK" "$JSON" "$OWNER" "${REPOS[@]}" > "$WORK/report.txt" << 'PY' || die "cannot parse a workflow"
import base64, datetime, json, os, re, subprocess, sys, yaml

work, json_out, owner, repos = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:]
REUSABLES = {"reusable-build", "reusable-lint", "reusable-security-scanning", "reusable-dependency-review",
             "reusable-tests", "reusable-preflight", "reusable-main-ci-guard"}
PIPE = re.compile(r"^paruff/ufawkespipe/\.github/workflows/[^@]+@(.+)$", re.I)
SHA = re.compile(r"^[0-9a-f]{40}$")
CI_IMAGE = re.compile(r"^ghcr\.io/paruff/ufawkes-ci@sha256:[0-9a-f]{64}$", re.I)


def get(node, key):
    """The value node under `key` in a YAML mapping node, or None."""
    if isinstance(node, yaml.MappingNode):
        for k, v in node.value:
            if k.value == key:
                return v
    return None


def items(node):
    return node.value if isinstance(node, yaml.SequenceNode) else []


def pairs(node):
    return [(k.value, v) for k, v in node.value] if isinstance(node, yaml.MappingNode) else []


def text(node):
    return node.value if isinstance(node, yaml.ScalarNode) else ""


def informational(path):
    """Step names (or file:step) the repo lists under `informational:` in .pipeline.yml."""
    if not os.path.exists(path):
        return set()
    out = set()
    for e in (yaml.safe_load(open(path)) or {}).get("informational") or []:
        out.add(str(e.get("step") or e.get("name")) if isinstance(e, dict) else str(e))
    return out


def audit(repo):
    d = f"{work}/{repo}"
    res = {"pipe_refs": [], "local_copies": [], "ci_image": "", "unpinned": [], "silent": []}
    listed = informational(f"{d}/pipeline.yml")
    files = sorted(os.listdir(f"{d}/wf"))
    res["has_workflows"] = bool(files)

    def silent(fn, flag, label, kind):
        if label not in listed and f"{fn}:{label}" not in listed:
            res["silent"].append(f"{fn}:{flag.start_mark.line + 1} {label} ({kind})")

    for fn in files:
        if repo.lower() != "ufawkespipe" and os.path.splitext(fn)[0] in REUSABLES:
            res["local_copies"].append(fn)
        root = yaml.compose(open(f"{d}/wf/{fn}"))
        for jname, job in pairs(get(root, "jobs")):
            container = get(job, "container")
            image = text(get(container, "image") or container)
            if image and "${{" not in image and "@sha256:" not in image:
                res["unpinned"].append(f"{fn}:{container.start_mark.line + 1} image {image}")
            for _, svc in pairs(get(job, "services")):
                si = text(get(svc, "image"))
                if si and "${{" not in si and "@sha256:" not in si:
                    res["unpinned"].append(f"{fn}:{get(svc, 'image').start_mark.line + 1} image {si}")
            hook_job = False
            jlabel = text(get(job, "name")) or jname
            for node in [job] + items(get(job, "steps")):
                is_step = node is not job
                label = (text(get(node, "name")) or text(get(node, "uses")) or "run") if is_step else jlabel
                uses = text(get(node, "uses"))
                if uses:
                    m = PIPE.match(uses)
                    if m:
                        res["pipe_refs"].append(m.group(1))
                    if not uses.startswith(("./", "docker://")) and not SHA.match(uses.rpartition("@")[2]):
                        res["unpinned"].append(f"{fn}:{get(node, 'uses').start_mark.line + 1} {uses}")
                run = text(get(node, "run"))
                if "pre-commit run" in run:
                    hook_job = True
                if re.search(r"\|\|\s*true\s*$", run.rstrip()):
                    silent(fn, get(node, "run"), label, "|| true")
                if text(get(node, "continue-on-error")) == "true":
                    silent(fn, get(node, "continue-on-error"), label, "continue-on-error")
            if hook_job:
                res["ci_image"] = image or "none"
    return res


def pinned_release(path):
    """The uFawkesAI release a devcontainer's fawkes-space pin names, or ''."""
    if not os.path.exists(path):
        return ""
    m = re.search(r"fawkes-space[^\s\"']*?:([0-9][^\s\"'@]*)", open(path).read())
    return m.group(1) if m else ""


def image_release(sha):
    """The uFawkesAI release behind uFawkesPipe's images/ci/Dockerfile FROM at `sha`, or ''."""
    p = subprocess.run(["gh", "api", f"repos/{owner}/uFawkesPipe/contents/images/ci/Dockerfile?ref={sha}", "--jq", ".content"],
                       capture_output=True, text=True)
    if p.returncode != 0:
        if "HTTP 404" in p.stderr + p.stdout:
            return ""
        sys.exit(f"uFawkesPipe: images/ci/Dockerfile at {sha}: {p.stderr or p.stdout}")
    m = re.search(r"^FROM\s+\S*fawkes-core:([0-9][^\s@]*)", base64.b64decode(p.stdout).decode(), re.M)
    return m.group(1) if m else ""


results = {r: audit(r) for r in repos}
digests = {re.search(r"sha256:[0-9a-f]+", x["ci_image"]).group(0) for x in results.values() if CI_IMAGE.match(x["ci_image"])}
COLS = [("pipe_refs", "Pipe release"), ("local_copies", "Local copies"), ("ci_image", "CI image"),
        ("release_match", "Release match"), ("unpinned", "Unpinned"), ("silent", "Silent passes")]
rows, cells = [], {}
for r in repos:
    x = results[r]
    x["pipe_refs"] = refs = sorted(set(x["pipe_refs"]))
    img = x["ci_image"]
    dev = pinned_release(f"{work}/{r}/devcontainer.json")
    built = image_release(refs[0]) if len(refs) == 1 else ""
    x["devcontainer_release"], x["image_release"] = dev, built
    if not x["has_workflows"]:
        ci = "n/a"
    elif CI_IMAGE.match(img):
        ci = "ok" if len(digests) == 1 else "digests differ"
    else:
        ci = img.split("@")[0] or "none"
    cells[r] = {
        "pipe_refs": "n/a" if not refs else "ok" if len(refs) == 1 else str(len(refs)),
        "local_copies": str(len(x["local_copies"])) if x["local_copies"] else "ok",
        "ci_image": ci,
        "release_match": "n/a" if not (dev and built) else "ok" if dev == built else "differs",
        "unpinned": str(len(x["unpinned"])) if x["unpinned"] else "ok",
        "silent": str(len(x["silent"])) if x["silent"] else "ok",
    }
    rows.append([r] + [cells[r][k] for k, _ in COLS])

table = [["repo"] + [k for k, _ in COLS]] + rows
widths = [max(len(t[i]) for t in table) for i in range(len(table[0]))]
for t in table:
    print("  ".join(v.ljust(w) for v, w in zip(t, widths)).rstrip())
for r in repos:
    x = results[r]
    for k in ("local_copies", "unpinned", "silent"):
        for f in x[k]:
            print(f"{r}: {k}: {f}")
    if len(x["pipe_refs"]) > 1:
        print(f"{r}: pipe_refs: {', '.join(x['pipe_refs'])}")

if json_out:
    now = os.environ.get("AUDIT_NOW") or datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    run = os.environ.get("GITHUB_RUN_ID")
    data = {
        "generated_at": now,
        "run_url": f"{os.environ.get('GITHUB_SERVER_URL', 'https://github.com')}/{os.environ.get('GITHUB_REPOSITORY', '')}/actions/runs/{run}" if run else "",
        "columns": [{"id": k, "label": lbl} for k, lbl in COLS],
        "repos": [{"repo": r, "cells": cells[r], "ci_image": results[r]["ci_image"],
                   "devcontainer_release": results[r]["devcontainer_release"], "image_release": results[r]["image_release"],
                   "findings": {k: results[r][k] for k in ("pipe_refs", "local_copies", "unpinned", "silent")}} for r in repos],
    }
    with open(json_out, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
PY
cat "$WORK/report.txt"
# Also served as /status/ci_determinism.json (static file, copied as-is by Jekyll).
[[ "$JSON" == "_data/ci_determinism.json" ]] && cp "$JSON" status/ci_determinism.json
exit 0
