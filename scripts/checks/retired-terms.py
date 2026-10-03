#!/usr/bin/env python3
"""Find lines that name a retired term with no qualifier on the same line.

Used by the AC-SUITE-01 and AC-DOJO-01 checks. A mention is fine when the line
also says why it is historical (deprecated, merged, "not Jenkins", ...), or when
it is on the reviewed allowlist (each entry carries its reason).

  retired-terms.py --terms REGEX [--allow FILE] LABEL=PATH [LABEL=PATH ...]
  retired-terms.py --terms REGEX [--allow FILE] --stdin LABEL < text

LABEL is "repo" or "repo:file" and is what the allowlist matches against.
Exit 0 = nothing unqualified, 1 = violations (printed as LABEL:LINE: text).
"""

import argparse
import re
import sys

# A line that carries one of these already explains the mention.
QUALIFIER = re.compile(
    r"deprecat|histor|supersed|archiv|merged|retire|former|replac|no longer|"
    r"legacy|\bwas\b|\bwere\b|used to|removed|dropped|instead of|\bnot\b|never|"
    r"ADR-0|stale|planned",
    re.IGNORECASE,
)


def load_allow(path):
    """Lines of `label|substring|reason`; a line starting with `#` is a comment."""
    allow = []
    if not path:
        return allow
    with open(path, encoding="utf-8") as fh:
        for raw in fh:
            if not raw.strip() or raw.lstrip().startswith("#"):
                continue
            parts = raw.rstrip("\n").split("|")
            if len(parts) < 3:
                sys.exit(f"allowlist line needs label|substring|reason: {raw!r}")
            allow.append((parts[0].strip(), parts[1].strip()))
    return allow


def scan(label, text, terms, allow):
    bad = []
    for n, line in enumerate(text.splitlines(), 1):
        if not terms.search(line) or QUALIFIER.search(line):
            continue
        if any(lab == label and sub in line for lab, sub in allow):
            continue
        bad.append(f"{label}:{n}: {line.strip()[:160]}")
    return bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--terms", required=True)
    ap.add_argument("--allow")
    ap.add_argument("--stdin", action="store_true")
    ap.add_argument("items", nargs="+")
    a = ap.parse_args()
    terms = re.compile(a.terms, re.IGNORECASE)
    allow = load_allow(a.allow)
    bad = []
    if a.stdin:
        bad += scan(a.items[0], sys.stdin.read(), terms, allow)
    else:
        for item in a.items:
            label, _, path = item.partition("=")
            try:
                with open(path, encoding="utf-8", errors="replace") as fh:
                    text = fh.read()
            except OSError as e:
                sys.exit(f"cannot read {path}: {e}")
            bad += scan(label, text, terms, allow)
    for b in bad:
        print(b)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
