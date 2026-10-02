#!/usr/bin/env bash
# scripts/check-design-tokens.sh — the design tokens must meet their own
# contrast floor.
#
# Reads design/tokens.json. Every entry in "contrast" names a foreground and a
# background token path and a minimum WCAG 2.x ratio. The script resolves both,
# computes the ratio from relative luminance, and fails if any pair is below its
# minimum, if a path does not resolve, or if a value is not a #rrggbb colour.
#
# Usage: scripts/check-design-tokens.sh [tokens.json]
set -euo pipefail

cd "$(dirname "$0")/.."

FILE="${1:-design/tokens.json}"
[[ -f "$FILE" ]] || {
  echo "check-design-tokens: $FILE not found" >&2
  exit 1
}

python3 - "$FILE" <<'PY'
import json, re, sys

path = sys.argv[1]
tokens = json.load(open(path))
HEX = re.compile(r"^#[0-9a-fA-F]{6}$")


def resolve(ref, depth=0):
    """A value is a literal #rrggbb or a dotted path into the tokens."""
    if HEX.match(ref):
        return ref.lower()
    if depth > 5:
        raise ValueError("reference chain too deep: " + ref)
    node = tokens
    for part in ref.split("."):
        if not isinstance(node, dict) or part not in node:
            raise ValueError("does not resolve: " + ref)
        node = node[part]
    if not isinstance(node, str):
        raise ValueError("not a colour: " + ref)
    return resolve(node, depth + 1)


def luminance(hex_colour):
    channels = [int(hex_colour[i : i + 2], 16) / 255 for i in (1, 3, 5)]
    lin = [c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    return 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]


def ratio(a, b):
    hi, lo = sorted([luminance(a), luminance(b)], reverse=True)
    return (hi + 0.05) / (lo + 0.05)


pairs = tokens.get("contrast", [])
if not pairs:
    sys.exit("check-design-tokens: no contrast pairs to check")

failures = 0
for pair in pairs:
    try:
        fg, bg = resolve(pair["fg"]), resolve(pair["bg"])
    except (KeyError, ValueError) as err:
        print("  FAIL %s on %s: %s" % (pair.get("fg"), pair.get("bg"), err))
        failures += 1
        continue
    got = ratio(fg, bg)
    ok = got >= pair["min"]
    failures += 0 if ok else 1
    print(
        "  %s %5.2f:1 (min %s)  %s on %s  %s"
        % ("ok  " if ok else "FAIL", got, pair["min"], fg, bg, pair.get("use", ""))
    )

if failures:
    sys.exit("check-design-tokens: %d pair(s) below the floor" % failures)
print("check-design-tokens: %d pairs meet their floor." % len(pairs))
PY
