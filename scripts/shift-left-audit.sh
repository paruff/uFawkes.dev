#!/usr/bin/env bash
# scripts/shift-left-audit.sh — which shift-left checks each suite repo has
# (docs/ai-sdlc/shift-left/spec.md R2, R6; plan phase A1). Read-only.
#
# Reads each repo's .pre-commit-config.yaml from main through `gh api` and
# prints a matrix of check x repo:
#   ok             the check is present, at the right stage, and that stage is installed
#   -              the check is missing
#   <stage>        present at a stage other than the catalog's. Earlier is allowed
#                  if it fits that stage's budget (R1); --time says whether it does
#   not-installed  present, but its stage is not in default_install_hook_types
#   system         count of `language: system` hooks (each a silent-pass risk, R4)
#
# Hooks from uFawkesPipe's shared source take their stages from its
# .pre-commit-hooks.yaml at the rev the repo pins.
#
# --json <path> also writes the matrix as JSON for /status/ (plan phase D1);
# for _data/shift_left.json it is also copied to status/shift_left.json.
#
# --time also shallow-clones each repo and times every hook over all files,
# summed per stage against the spec's budgets. All-files times are an upper
# bound: a real commit runs hooks on changed files only.
#
# Exit non-zero only when the SCRIPT breaks (API error, bad YAML). A missing
# check is a result, not a script error.
#
# Environment:
#   AUDIT_OWNER  GitHub owner (default paruff)
#   AUDIT_REPOS  space-separated repo list (default: the seven suite repos)
set -euo pipefail

cd "$(dirname "$0")/.."

OWNER="${AUDIT_OWNER:-paruff}"
read -r -a REPOS <<< "${AUDIT_REPOS:-uFawkes.dev uFawkesAI uFawkesObs uFawkesPipe uFawkesDevX uFawkesDojo fawkes}"
TIME=0
JSON=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --time) TIME=1 ;;
    --json)
      JSON="${2:?--json needs a path}"
      shift
      ;;
    *)
      echo "shift-left-audit: unknown argument: $1" >&2
      exit 1
      ;;
  esac
  shift
done

die() {
  echo "shift-left-audit: $*" >&2
  exit 1
}

command -v gh > /dev/null || die "gh is required"
command -v python3 > /dev/null || die "python3 is required"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

for r in "${REPOS[@]}"; do
  if out="$(gh api "repos/$OWNER/$r/contents/.pre-commit-config.yaml" --jq .content 2>&1)"; then
    printf '%s' "$out" | base64 -d > "$WORK/$r.yaml" || die "$r: cannot decode config"
    # A repo on uFawkesPipe's shared hooks: fetch the manifest at its pinned rev, once.
    rev="$(python3 -c '
import sys, yaml
for r in (yaml.safe_load(open(sys.argv[1])) or {}).get("repos") or []:
    if str(r.get("repo", "")).lower().rstrip("/").removesuffix(".git").endswith("paruff/ufawkespipe"):
        print(r.get("rev", ""))
        break
' "$WORK/$r.yaml")" || die "$r: cannot parse config"
    if [[ -n "$rev" && ! -f "$WORK/pipe-manifest-$rev.yaml" ]]; then
      m="$(gh api "repos/paruff/uFawkesPipe/contents/.pre-commit-hooks.yaml?ref=$rev" --jq .content 2>&1)" \
        || die "$r: cannot read uFawkesPipe's manifest at $rev: $m"
      printf '%s' "$m" | base64 -d > "$WORK/pipe-manifest-$rev.yaml" || die "cannot decode uFawkesPipe's manifest at $rev"
    fi
    # Its tracked files, to know which languages it has (the Type check column).
    # ponytail: the trees API truncates past 100k entries; no suite repo is near that.
    gh api "repos/$OWNER/$r/git/trees/HEAD?recursive=1" --jq '.tree[] | select(.type == "blob") | .path' > "$WORK/$r.tree" \
      || die "$r: cannot list its files"
  elif [[ "$out" == *"HTTP 404"* ]]; then
    : > "$WORK/$r.missing"
  else
    die "$r: $out"
  fi
done

# The R2 catalog: column -> (hook ids, the stage it belongs at).
# ponytail: matched by hook id, so a renamed hook reads as missing; it then shows up
# under "Unmapped hooks" and gets added here.
python3 - "$WORK" "$JSON" "${REPOS[@]}" > "$WORK/report.txt" << 'PY' || die "cannot parse a hook config"
import datetime, json, os, sys, yaml

work, json_out, repos = sys.argv[1], sys.argv[2], sys.argv[3:]
CATALOG = [
    ("actionlint", {"actionlint", "actionlint-docker", "actionlint-system"}, "pre-commit"),
    ("schema", {"check-jsonschema", "check-dependabot", "check-github-workflows", "check-github-actions"}, "pre-commit"),
    ("sast", {"semgrep", "semgrep-ci"}, "pre-push"),
    # Not matched by id alone: see LANGS. A checker counts only for a language the repo has.
    ("types", set(), "pre-commit"),
    ("dep-iac", {"trivy", "conftest", "kubeconform", "kubeval", "terraform_tfsec", "terraform_trivy", "checkov"}, "pre-push"),
    ("unit", {"unit-tests"}, "pre-push"),
    ("commit-msg", {"conventional-commit", "conventional-commit-msg", "commit-msg"}, "commit-msg"),
    # Adoption of the shift-left tooling itself (plan phase C)
    ("parity", {"shift-left-parity"}, "pre-commit"),
    ("stamps", {"shift-left-stamp"}, "pre-commit"),
]
LABELS = {"actionlint": "Actions lint", "schema": "Config schema", "sast": "SAST", "types": "Type check",
          "dep-iac": "Dependency / IaC scan", "unit": "Unit tests", "commit-msg": "Commit message",
          "parity": "CI parity", "stamps": "Doctor stamps"}
# Type check, per language the repo has in its own code (the template's
# golangci-lint hook is in every config, so matching it alone said "ok" for repos with no Go).
# golangci-lint v2 runs govet and staticcheck by default.
LANGS = [
    ("python", (".py",), {"mypy", "pyright"}),
    ("js/ts", (".js", ".mjs", ".cjs", ".jsx", ".ts", ".tsx"), {"tsc"}),
    ("go", (".go",), {"golangci-lint", "go-vet", "go-vet-mod", "staticcheck"}),
]
# Not the repo's own code: the template's agent framework and cookiecutter files, vendored
# dependencies, and tests (checked by running them).
NOT_CODE_PREFIXES = (".opencode/", ".agents/", "templates/", "node_modules/")
def own_code(path):
    parts = path.split("/")
    base = parts[-1]
    return not (path.startswith(NOT_CODE_PREFIXES) or "node_modules" in parts or "tests" in parts[:-1] or "test" in parts[:-1]
                or base.startswith(("test_", "test-")) or base.endswith(("_test.go", ".test.js", ".test.ts", ".spec.js", ".spec.ts", ".d.ts")))

# Hooks the catalog deliberately has no column for (format, lint, hygiene).
KNOWN = {
    "trailing-whitespace", "end-of-file-fixer", "check-yaml", "check-json", "check-added-large-files",
    "check-merge-conflict", "mixed-line-ending", "detect-private-key", "ruff", "ruff-format", "yamllint",
    "markdownlint", "prettier", "gitleaks", "shellcheck", "shfmt", "terraform_fmt", "terraform_validate",
    "terraform_tflint", "terraform_docs", "insert-license", "agent-report-contracts", "dora-vocabulary",
    "ai-stance", "status-drift", "agent-dispatch", "harness-parity", "kustomize-validate",
    "backstage-catalog-validate", "argocd-validate", "helm-lint", "check-k8s-secrets", "mkdocs-validate",
    "requirements-pin-check", "pre-push-validation", "shift-left-stamp", "shift-left-stamp-pre-push", "shift-left-parity",
}
cols = [c for c, _, _ in CATALOG] + ["system"]
rows, notes, unmapped = [], [], []
for r in repos:
    if os.path.exists(f"{work}/{r}.missing"):
        rows.append([r] + ["n/a"] * len(cols))
        notes.append(f"{r}: no .pre-commit-config.yaml on main")
        continue
    cfg = yaml.safe_load(open(f"{work}/{r}.yaml")) or {}
    installed = set(cfg.get("default_install_hook_types") or ["pre-commit"])
    default_stages = cfg.get("default_stages") or ["pre-commit"]
    hooks = {}  # id -> (stages, language)
    for repo in cfg.get("repos") or []:
        manifest = {}
        if str(repo.get("repo", "")).lower().rstrip("/").removesuffix(".git").endswith("paruff/ufawkespipe"):
            path = f"{work}/pipe-manifest-{repo.get('rev', '')}.yaml"
            manifest = {m["id"]: m for m in (yaml.safe_load(open(path)) or [])} if os.path.exists(path) else {}
        for h in repo.get("hooks") or []:
            h = {**manifest.get(h["id"], {}), **h}  # the repo's config overrides the manifest
            hooks[h["id"]] = (h.get("stages") or default_stages, h.get("language", ""))
    row = [r]
    tree = [x for x in open(f"{work}/{r}.tree").read().split("\n") if x and own_code(x)]
    needed = [ids for _, exts, ids in LANGS if any(x.endswith(exts) for x in tree)]
    for col, ids, want in CATALOG:
        if col == "types":
            if not needed:
                row.append("n/a")
                continue
            if any(not (ids2 & hooks.keys()) for ids2 in needed):
                row.append("-")
                continue
            ids = set().union(*needed)
        found = [hooks[i][0] for i in ids if i in hooks]
        if not found:
            row.append("-")
        elif not any(want in s for s in found):
            row.append(",".join(sorted({x for s in found for x in s})))
        elif want not in installed:
            row.append("not-installed")
        else:
            row.append("ok")
    row.append(str(sum(1 for _, lang in hooks.values() if lang == "system")))
    rows.append(row)
    mapped = set().union(*(ids for _, ids, _ in CATALOG)) | KNOWN | set().union(*(ids for _, _, ids in LANGS))
    extra = sorted(i for i in hooks if i not in mapped)
    if extra:
        unmapped.append(f"  {r}: {', '.join(extra)}")

table = [["repo"] + cols] + rows
widths = [max(len(t[i]) for t in table) for i in range(len(table[0]))]
for t in table:
    print("  ".join(v.ljust(w) for v, w in zip(t, widths)).rstrip())
for n in notes:
    print(n)
if unmapped:
    print("\nUnmapped hooks (no catalog column yet):")
    print("\n".join(unmapped))

if json_out:
    now = os.environ.get("AUDIT_NOW") or datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    run = os.environ.get("GITHUB_RUN_ID")
    data = {
        "generated_at": now,
        "run_url": f"{os.environ.get('GITHUB_SERVER_URL', 'https://github.com')}/{os.environ.get('GITHUB_REPOSITORY', '')}/actions/runs/{run}" if run else "",
        "columns": [{"id": c, "label": LABELS[c], "stage": st} for c, _, st in CATALOG],
        "repos": [],
    }
    notes_by_repo = {n.split(":", 1)[0]: n.split(": ", 1)[1] for n in notes}
    for row in rows:
        r = row[0]
        data["repos"].append({
            "repo": r,
            "cells": dict(zip([c for c, _, _ in CATALOG], row[1:1 + len(CATALOG)])),
            "system": row[-1],
            "note": notes_by_repo.get(r, ""),
        })
    with open(json_out, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
PY
cat "$WORK/report.txt"
# Also served as /status/shift_left.json (static file, copied as-is by Jekyll).
[[ "$JSON" == "_data/shift_left.json" ]] && cp "$JSON" status/shift_left.json

[[ "$TIME" == 1 ]] || exit 0

# --- timing -----------------------------------------------------------------
command -v pre-commit > /dev/null || die "pre-commit is required for --time"
now() { python3 -c 'import time; print(time.time())'; }
echo
echo "Hook timings (all files; upper bound). Budgets (spec R1): pre-commit 10s, pre-push 180s."
for r in "${REPOS[@]}"; do
  [[ -f "$WORK/$r.yaml" ]] || continue
  dir="$WORK/clone-$r"
  if ! git clone -q --depth 1 "https://github.com/$OWNER/$r" "$dir" 2> "$WORK/err"; then
    echo "$r: clone failed: $(cat "$WORK/err")"
    continue
  fi
  echo "== $r"
  # Environment installs are a one-off cost, so they are not timed.
  (cd "$dir" && pre-commit install-hooks > /dev/null 2>&1) || echo "  (some hook environments failed to install)"
  # stage<TAB>id for every hook; commit-msg hooks need a message file and run in <1s.
  python3 - "$WORK/$r.yaml" > "$WORK/hooks.tsv" << 'PY'
import sys, yaml
cfg = yaml.safe_load(open(sys.argv[1])) or {}
default = cfg.get("default_stages") or ["pre-commit"]
for repo in cfg.get("repos") or []:
    for h in repo.get("hooks") or []:
        for s in h.get("stages") or default:
            if s in ("pre-commit", "pre-push"):
                print(f"{s}\t{h['id']}")
PY
  pc=0 pp=0
  while IFS=$'\t' read -r stage id; do
    t0="$(now)"
    if out="$(cd "$dir" && pre-commit run "$id" --all-files --hook-stage "$stage" 2>&1)"; then
      result=pass
    else
      result=fail
    fi
    [[ "$out" == *"Skipped"* && "$result" == pass ]] && result=skipped
    secs="$(python3 -c "print(f'{$(now) - $t0:.1f}')")"
    printf '  %-10s %-28s %7ss  %s\n' "$stage" "$id" "$secs" "$result"
    if [[ "$stage" == pre-commit ]]; then pc="$(python3 -c "print($pc + $secs)")"; else pp="$(python3 -c "print($pp + $secs)")"; fi
  done < "$WORK/hooks.tsv"
  printf '  sum of hooks: pre-commit %.1fs, pre-push %.1fs (each run pays pre-commit startup)\n' "$pc" "$pp"
  # One run per stage is what a person actually waits for.
  for stage in pre-commit pre-push; do
    t0="$(now)"
    (cd "$dir" && pre-commit run --all-files --hook-stage "$stage" > /dev/null 2>&1) || true
    printf '  whole stage: %-10s %6.1fs\n' "$stage" "$(python3 -c "print($(now) - $t0)")"
  done
  rm -rf "$dir"
done
