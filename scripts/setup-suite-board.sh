#!/usr/bin/env bash
# One-shot setup of Project #7 ("uFawkes Suite Release") for the board workflow:
# AGENTS.md §8 and docs/ai-sdlc/suite-release/plan.md "The board: statuses, gates and moves".
# Review, then run once from the repo root:  bash scripts/setup-suite-board.sh
# Preview without writing anything:          DRY_RUN=1 bash scripts/setup-suite-board.sh
# Needs gh logged in with the `project` scope (check: gh auth status).
#
# Safe to re-run: Status options keep their IDs (no item loses its value), Gate is created
# once, comments are matched by marker text, and new issues by exact title.
set -euo pipefail

OWNER=paruff
P=7
TITLE="uFawkes Suite Release"
DRY_RUN="${DRY_RUN:-}"

log() { echo "$*" >&2; }
run() { # run a write; in DRY_RUN mode, print it instead
  if [ -n "$DRY_RUN" ]; then
    printf 'DRY_RUN:' >&2
    printf ' %q' "$@" >&2
    echo >&2
  else
    "$@"
  fi
}
url() { echo "https://github.com/$OWNER/$1/issues/$2"; } # <repo> <number>
set_field() {                                            # <repo> <number> <field> <value>
  run gh project item-edit "$P" --owner "$OWNER" --url "$(url "$1" "$2")" --field "$3" --value "$4" > /dev/null
  log "  $3=$4 <- $1#$2"
}
move() { set_field "$1" "$2" Status "$3"; } # <repo> <number> <status>
comment_once() {                            # <repo> <number> <marker> <body>
  if gh issue view "$2" --repo "$OWNER/$1" --json comments --jq '.comments[].body' | grep -qF "$3"; then
    log "  comment already on $1#$2"
  else
    run gh issue comment "$2" --repo "$OWNER/$1" --body "$4" > /dev/null
  fi
}
blocked() { # <repo> <number> <what it waits on>
  move "$1" "$2" Blocked
  comment_once "$1" "$2" "Blocked on the board" "Blocked on the board (Project #7): waits on $3. Move it on when that lands."
}
new_issue() { # <repo> <title> <labels> <body>  -> sets Status "Ready for agent"
  local found
  found=$(gh issue list --repo "$OWNER/$1" --state all --search "\"$2\" in:title" --json title,number \
    --jq ".[] | select(.title == \"$2\") | .number" | head -1)
  if [ -n "$found" ]; then
    log "  exists: $1#$found"
  elif [ -n "$DRY_RUN" ]; then
    run gh issue create --repo "$OWNER/$1" --title "$2" --label "$3" --project "$TITLE" --body "<body>"
    return
  else
    found=$(gh issue create --repo "$OWNER/$1" --title "$2" --label "$3" --project "$TITLE" --body "$4" | sed 's#.*/##')
    log "  created: $1#$found"
  fi
  move "$1" "$found" "Ready for agent"
}

# --- 1. Status options: rename Todo to Backlog, add three, keep every existing ID --------
log "Status options"
STATUS=$(gh project field-list "$P" --owner "$OWNER" --format json --jq '.fields[] | select(.name=="Status")')
FIELD=$(jq -r .id <<< "$STATUS")
opt() { jq -r --arg n "$1" '.options[] | select(.name==$n) | .id' <<< "$STATUS"; }
if [ -n "$(opt "Ready for agent")" ]; then
  log "  already set: $(jq -r '[.options[].name] | join(", ")' <<< "$STATUS")"
else
  TODO=$(opt Todo)
  INPROG=$(opt "In Progress")
  DONE=$(opt Done)
  [ -n "$TODO" ] && [ -n "$INPROG" ] && [ -n "$DONE" ] || {
    log "Status options are not Todo / In Progress / Done; stopping."
    exit 1
  }
  # In Progress and Done keep their exact names: scripts/suite-status.sh matches them.
  run gh api graphql -f query="mutation {
  updateProjectV2Field(input: {fieldId: \"$FIELD\", singleSelectOptions: [
    {id: \"$TODO\",   name: \"Backlog\",         color: GRAY,   description: \"Not ready, or its release is gated\"},
    {                 name: \"Ready for agent\", color: BLUE,   description: \"Routing label, plan link and exit criterion; release not Blocked\"},
    {id: \"$INPROG\", name: \"In Progress\",     color: YELLOW, description: \"Claimed: move here before starting\"},
    {                 name: \"Needs human\",     color: PURPLE, description: \"Waits on the owner: a decision, a PR to review or merge, or human-only work\"},
    {                 name: \"Blocked\",         color: RED,    description: \"Waits on something named in the issue\"},
    {id: \"$DONE\",   name: \"Done\",            color: GREEN,  description: \"Closed or merged\"}
  ]}) { projectV2Field { ... on ProjectV2SingleSelectField { options { name } } } }
}" > /dev/null
  log "  Todo -> Backlog (same ID), added Ready for agent, Needs human, Blocked"
fi

# --- 2. Gate field ------------------------------------------------------------------------
log "Gate field"
if gh project field-list "$P" --owner "$OWNER" --format json --jq '.fields[].name' | grep -qx Gate; then
  log "  already exists"
else
  run gh project field-create "$P" --owner "$OWNER" --name Gate --data-type SINGLE_SELECT \
    --single-select-options "intent,spec,plan,PR review,merge/release" > /dev/null
fi

# --- 3. Labels: kind of issue, never status ------------------------------------------------
log "Labels"
for repo in uFawkes.dev uFawkesAI uFawkesObs uFawkesPipe uFawkesDevX uFawkesDojo fawkes; do
  run gh label edit question --repo "$OWNER/$repo" --description "Decision needed from the owner"
done
# Status lives on the board. No open fawkes issue carries these (checked 2026-10-24).
for l in status-blocked status-ready status-testing; do
  if gh label list --repo "$OWNER/fawkes" --search "$l" --json name --jq '.[].name' | grep -qx "$l"; then
    run gh label delete "$l" --repo "$OWNER/fawkes" --yes
  fi
done
# The one open item with no routing label (AC-SUITE-02): it already has its model label.
run gh issue edit 64 --repo "$OWNER/uFawkes.dev" --add-label opencode > /dev/null

# --- 4. Open items: Todo was renamed Backlog, so only moves out of Backlog are listed ------
# Triage of 2026-10-24. Ready for agent: routing label, acceptance criteria in the body, no
# open dependency, and work that can run now (the plan lets later releases' work run early).
log "Ready for agent"
for n in 670 671 182; do move uFawkesObs "$n" "Ready for agent"; done # Obs 1.0, the next release
for n in 121 125 145 155; do move uFawkesPipe "$n" "Ready for agent"; done
for n in 2004 2227; do move fawkes "$n" "Ready for agent"; done        # P0 security blocker; AI 2.0 follow-up
move uFawkes.dev 70 "Ready for agent"                                  # its blockers Pipe#97, DevX#57 are closed
for n in 42 43 44 45; do move uFawkesDojo "$n" "Ready for agent"; done # Obs labs (Phase 3)

log "Needs human"
move uFawkesPipe 122 "Needs human" # decide build-image via CNB, or drop the claim (+ ADR)
set_field uFawkesPipe 122 Gate plan
run gh issue edit 122 --repo "$OWNER/uFawkesPipe" --add-label question --add-assignee "$OWNER" > /dev/null
move fawkes 684 "Needs human" # purges git history with BFG and rotates credentials: owner approves first
set_field fawkes 684 Gate plan
move fawkes 1797 "Needs human" # real secret values only the owner can supply; no gate, human-only work

log "Blocked"
blocked uFawkesObs 600 "uFawkesObs#670, #671 and AC-OBS-01 (the v1.0.1 finish)"
blocked uFawkesObs 502 "uFawkesObs#182, the live rollback drill (its stated dependency)"
blocked uFawkesPipe 120 "uFawkesPipe#122, the build-image decision"
blocked fawkes 1804 "the P0 security issues fawkes#2004 and #1797"

# Stay in Backlog: fawkes Alpha work (Phase 6, last) #1569 #1572 #1715 #1856 #1857 #1858 #1919
# #1948 #2130 #2188; fawkes #2189-#2191 (tracked, not promised); uFawkesPipe#123 (after #122);
# uFawkes.dev#64 (P3); uFawkesDojo #46-#52 (Pipe and DevX labs, Phases 4 and 5).

# --- 5. DESIGN.md gaps (D9, D14, D15) -------------------------------------------------------
log "Design issues"
new_issue uFawkes.dev "fix(css): bring main.css in line with DESIGN.md (D9 button, retired green)" \
  "opencode,model:nemotron-3-ultra" "**Plan section.** \`DESIGN.md\`, Components → \"Today in the site CSS\".

**Spec or acceptance IDs.** n/a: design debt (D9, D13).

**Exit criterion.** \`grep -c '#16a34a' assets/css/main.css\` prints 0; \`.cta-button\` is Flame \`#f06300\` with a Night \`#061723\` label (hover \`#e85800\`); \`make build\` and \`make design-check\` pass.

**Files to change, and what not to touch.** \`assets/css/main.css\` only, append-only (AGENTS.md §6): add overriding rules at the end, never reorder. Green \`#15803d\` stays for pass/live. Don't touch layouts or content.

**Design.** \`DESIGN.md\` Colors and Components."

new_issue fawkes "feat(design-system): primary button to Flame with a Night label (D14)" \
  "opencode,model:nemotron-3-ultra" "**Plan section.** \`DESIGN.md\` (this repo), \"Today\" table; suite decision D14.

**Spec or acceptance IDs.** n/a: design debt.

**Exit criterion.** The primary \`Button\` renders Flame \`#f06300\` with a Night \`#061723\` label (hover \`#e85800\`), and the design-system tests pass with \`primaryDefault.test.ts\` updated to match.

**Files to change, and what not to touch.** \`design-system/src/components/Button/Button.css\`, the tokens it reads, and \`design-system/src/tokens/primaryDefault.test.ts\`. Links, focus and secondary buttons stay Indigo 600.

**Design.** \`DESIGN.md\` Components."

new_issue uFawkesDojo "feat(pages): move the three pages to the suite tokens (D15)" \
  "opencode,model:nemotron-3-ultra" "**Plan section.** \`DESIGN.md\` (this repo), \"Today\" table; suite decision D15.

**Spec or acceptance IDs.** n/a: design debt.

**Exit criterion.** \`grep -ciE '#667eea|#764ba2|#f093fb|#f5576c' index.html lesson.html onboarding.html\` prints 0 for each file; primary buttons are Flame with a Night label; status colours use the palette with a symbol and a word; \`make verify-labs\` passes.

**Files to change, and what not to touch.** \`index.html\`, \`lesson.html\`, \`onboarding.html\`, one commit each. Lesson text stays as it is.

**Design.** \`DESIGN.md\` Colors, Components, Do's and Don'ts."

new_issue uFawkesDevX "feat(api-docs): move the API docs page to the suite tokens (D15)" \
  "opencode,model:mimo-v2.6-flash" "**Plan section.** \`DESIGN.md\` (this repo), \"Today\" table; suite decision D15.

**Spec or acceptance IDs.** n/a: design debt.

**Exit criterion.** \`grep -ciE '#667eea|#764ba2' gateway/api-docs/index.html\` prints 0; HTTP methods show as words, not colour alone.

**Files to change, and what not to touch.** \`gateway/api-docs/index.html\` only. Backstage keeps its own theme.

**Design.** \`DESIGN.md\` Components."

# --- 6. Manual steps (the CLI can't set built-in workflows or views) ----------------------
cat >&2 << EOF

Done. Board: https://github.com/users/$OWNER/projects/$P

Manual steps, in the web UI (Project → ⋯ → Workflows / views):
  1. "Item added to project": confirm it now says Backlog (Todo was renamed, same option).
  2. "Pull request linked to issue": check what it sets. If it can set the issue to
     "Needs human", choose that; otherwise leave it and move issues by hand (REVIEW.md).
  3. Optional views: "Agent queue" (filter  status:"Ready for agent"), and "Needs human"
     (filter  status:"Needs human", group by Gate).

Check the two AGENTS.md commands now return items:
  gh project item-list 7 --owner paruff --limit 300 --query 'status:"Ready for agent" is:open' --format json --jq '.items | length'
  gh project item-list 7 --owner paruff --limit 300 --query 'status:"Needs human" is:open' --format json --jq '.items | length'
EOF
