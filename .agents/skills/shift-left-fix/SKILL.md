---
name: shift-left-fix
description: Fix failing pre-commit hooks or a red CI hook job — the mechanical failures only (lint, format, schema, commit message), proven by rerunning the same hook — and hand tests, security findings and anything unknown to a person. Use when the agent gate blocks a stop, a commit or push is rejected by a hook, or Pre-flight fails.
license: MIT
compatibility: opencode
---

# Shift-left fix

Spec: `docs/ai-sdlc/shift-left/spec.md` R10. A failing check is information,
not an obstacle. Fix what is mechanical; hand on what needs judgment.

## 1. Get the log

- **Local:** the output of the hook run that failed. To reproduce it:
  `pre-commit run --files <changed files>` (add `--hook-stage pre-push` for a
  push).
- **CI:** `gh run view <run-id> --log-failed > /tmp/ci.log`.

## 2. Sort it

```bash
bash scripts/shift-left-triage.sh /tmp/ci.log   # or pipe the local output in
```

Each line is `<class><TAB><hook id>`:

| Class        | What to do                                                                                                                                                       |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `fixed`      | The formatter already rewrote the files. Review the diff, then rerun the hook to confirm it passes.                                                              |
| `mechanical` | Change the **code** until the rule passes: quote the variable, fix the YAML, shorten the commit title. The rule is right; it does not move.                      |
| `judgment`   | Stop. Don't fix it. Report it (step 4). Tests, semgrep, Trivy, gitleaks, the parity check, merge conflicts, and any hook the triage script doesn't know go here. |

## 3. Prove each fix

Rerun **the same hook** on the same files until it passes:

```bash
pre-commit run <hook-id> --files <files>
```

Then rerun the whole stage once (`pre-commit run --files <files>`), because a
fix for one hook can trip another. A fix you haven't rerun is a guess.

## 4. Hand off the rest

For each `judgment` failure, tell the person:

- the hook id and the file
- the log lines that show the failure (at most 20)
- why it needs a person: a behaviour change, a security call, or a rule
  decision

## Never

These are the limits that make an agent fixing checks safe. None of them may
be used to turn a check green; each needs the person's explicit say-so.

- `git commit --no-verify`, `git push --no-verify`, `SKIP=`, or
  `SHIFT_LEFT_ALLOW_MISSING=`
- Editing a hook, test or ruleset to pass: `.pre-commit-config.yaml`,
  `.shift-left.yml`, `scripts/test-*.sh`, `.gitleaks.toml`,
  `.github/actionlint.yaml`, `.markdownlint.json`, `.yamllint`
- Inline suppressions: `# shellcheck disable=`, `# nosemgrep`, `# noqa`,
  `# type: ignore`, `// eslint-disable`, `<!-- markdownlint-disable -->`
- Deleting or skipping a failing test, or loosening its assertion

If the only way to green is one of these, it was a `judgment` failure after
all: hand it off.
