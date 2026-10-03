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
[[ "${1:-}" == "--time" ]] && TIME=1

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
  elif [[ "$out" == *"HTTP 404"* ]]; then
    : > "$WORK/$r.missing"
  else
    die "$r: $out"
  fi
done

# The R2 catalog: column -> (hook ids, the stage it belongs at).
# ponytail: matched by hook id, so a renamed hook reads as missing; it then shows up
# under "Unmapped hooks" and gets added here.
python3 - "$WORK" "${REPOS[@]}" > "$WORK/report.txt" << 'PY' || die "cannot parse a hook config"
import os, sys, yaml

work, repos = sys.argv[1], sys.argv[2:]
CATALOG = [
    ("actionlint", {"actionlint", "actionlint-docker", "actionlint-system"}, "pre-commit"),
    ("schema", {"check-jsonschema", "check-dependabot", "check-github-workflows", "check-github-actions"}, "pre-commit"),
    ("sast", {"semgrep", "semgrep-ci"}, "pre-push"),
    # golangci-lint v2 runs govet and staticcheck by default
    ("types", {"mypy", "pyright", "tsc", "go-vet", "go-vet-mod", "staticcheck", "golangci-lint"}, "pre-commit"),
    ("dep-iac", {"trivy", "conftest", "kubeconform", "kubeval", "terraform_tfsec", "terraform_trivy", "checkov"}, "pre-push"),
    ("unit", {"unit-tests"}, "pre-push"),
    ("commit-msg", {"conventional-commit", "conventional-commit-msg", "commit-msg"}, "commit-msg"),
]
# Hooks the catalog deliberately has no column for (format, lint, hygiene).
KNOWN = {
    "trailing-whitespace", "end-of-file-fixer", "check-yaml", "check-json", "check-added-large-files",
    "check-merge-conflict", "mixed-line-ending", "detect-private-key", "ruff", "ruff-format", "yamllint",
    "markdownlint", "prettier", "gitleaks", "shellcheck", "shfmt", "terraform_fmt", "terraform_validate",
    "terraform_tflint", "terraform_docs", "insert-license", "agent-report-contracts", "dora-vocabulary",
    "ai-stance", "status-drift", "agent-dispatch", "harness-parity", "kustomize-validate",
    "backstage-catalog-validate", "argocd-validate", "helm-lint", "check-k8s-secrets", "mkdocs-validate",
    "requirements-pin-check", "pre-push-validation",
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
        for h in repo.get("hooks") or []:
            hooks[h["id"]] = (h.get("stages") or default_stages, h.get("language", ""))
    row = [r]
    for _, ids, want in CATALOG:
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
    mapped = set().union(*(ids for _, ids, _ in CATALOG)) | KNOWN
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
PY
cat "$WORK/report.txt"

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
