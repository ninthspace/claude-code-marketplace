#!/bin/bash
# test-ralph-session-state-hygiene.sh — the two ways an autonomous loop mishandles its own
# state file: committing it, and offering a pause control that silently does nothing.
#
# Both were observed in the same field test (review 02, OBS-12/21 and OBS-37) and they share
# a subject — `.claude/ralph-loop.local.md` and the CPM progress files beside it — so they
# are fenced together rather than in two suites that would each re-derive the same slices.
#
# --- What has an oracle here ------------------------------------------------------------
#
# Two cross-document agreements, both checked by extraction rather than by grepping each
# side for a literal:
#
#   1. The ignore pattern in `cpm:ralph`'s pre-flight and the one in the shared Progress
#      File Management convention must be the same string. Two documents naming a glob is
#      how one of them ends up naming a glob that matches nothing.
#   2. `active:` means different things on different plugins, and exactly one plugin honours
#      it. The skill tells the user which behaviour they have; `docs/maintenance/README.md`
#      records the coupling. Which plugin that is gets read out of *both* and compared, so a
#      change to either side that is not made to the other fails here.
#
# The maintenance record is read by path from this suite deliberately. CLAUDE.md keeps that
# path out of `cpm/skills/` — a pointer from a skill is a line every invocation pays for —
# and asserts the pair from the suites instead. This is that assertion.
#
# --- Regression nets over prose -----------------------------------------------------------
#
# That pre-flight 1g names all three transient paths, gates the `.gitignore` edit on the
# user, and runs before the state file is written. Ordering is the whole point: the leak is
# caused by the first commit, so a check that runs afterwards has already lost.
#
# Usage: bash cpm/hooks/tests/test-ralph-session-state-hygiene.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

RALPH_SKILL="$SCRIPT_DIR/../../skills/ralph/SKILL.md"
CONV_FILE="$SCRIPT_DIR/../../shared/skill-conventions.md"
MAINT_FILE="$SCRIPT_DIR/../../../docs/maintenance/README.md"

echo "Testing: ralph session-state hygiene (gitignore pre-flight, active: field contract)"
echo "=================================================================================="

for f in "$RALPH_SKILL" "$CONV_FILE" "$MAINT_FILE"; do
  test_start "control: $(basename "$(dirname "$f")")/$(basename "$f") is readable"
  assert_equals "yes" "$( [ -r "$f" ] && echo yes || echo no )"
done

RALPH_TEXT=$(cat "$RALPH_SKILL")
CONV_TEXT=$(cat "$CONV_FILE")
MAINT_TEXT=$(cat "$MAINT_FILE")

# --- Part A: the ignore pre-flight (OBS-12, OBS-21) --------------------------------------

test_start "slice: the ignore pre-flight spans its own section and no more"
assert_slice_bounded "$RALPH_SKILL" '^#### 1g\.' '^### Step 2' 8 40

IGNORE_STEP=$(sed -n '/^#### 1g\./,/^### Step 2/p' "$RALPH_SKILL")

# All three, separately. One assertion over the block would pass on a version that named the
# ralph state file and forgot CPM's own — which is the half the field test actually leaked.
for path in '.claude/ralph-loop.local.md' 'docs/plans/.cpm-progress-' 'docs/plans/.cpm-compact-summary-'; do
  test_start "pre-flight names $path as session state"
  assert_contains "$IGNORE_STEP" "$path"
done

test_start "the .gitignore edit is gated on the user, not applied silently"
assert_contains "$IGNORE_STEP" "AskUserQuestion"

# Declining has to be a live option: a gate whose only path forward is "yes" is not a gate,
# and this edits a file in the user's repository.
test_start "and declining still launches the loop"
assert_contains "$IGNORE_STEP" "Continue without"

test_start "pre-flight states the check runs before arming, not after"
assert_contains "$IGNORE_STEP" "before arming, not after"

# The ordering claim, checked structurally rather than read from the prose above. Step 3 is
# where the state file is written and the loop is armed.
test_start "and 1g is positioned before the state-file write"
ln_1g=$(grep -n '^#### 1g\.' "$RALPH_SKILL" | cut -d: -f1)
ln_step3=$(grep -n '^### Step 3: State File Write and Launch' "$RALPH_SKILL" | cut -d: -f1)
if [ -n "$ln_1g" ] && [ -n "$ln_step3" ] && [ "$ln_1g" -lt "$ln_step3" ]; then
  test_pass
else
  test_fail "expected 1g before Step 3, got 1g=$ln_1g step3=$ln_step3"
fi

# The two documents must name the same glob. Extracted from each side rather than compared
# against a literal written here — a literal in the suite is a third place to get it wrong.
SKILL_GLOB=$(printf '%s' "$IGNORE_STEP" | grep -oE '/docs/plans/\.cpm-[^ `]*' | head -1)
CONV_GLOB=$(printf '%s' "$CONV_TEXT" | grep -oE 'The ignore entry is `[^`]+`' | grep -oE '/docs/plans/\.cpm-[^ `]*' | head -1)
assert_agrees "the CPM session-state ignore glob" \
  "ralph/SKILL.md" "$SKILL_GLOB" \
  "skill-conventions.md" "$CONV_GLOB"

# The convention carries the reason, not just the pattern. Without it the next reader sees a
# gitignore line with no stated cause and treats it as incidental.
test_start "the shared convention says why an interactive session never noticed"
assert_contains "$CONV_TEXT" "git add -A"

test_start "and that untracking later does not undo the commits already made"
assert_contains "$CONV_TEXT" "does not remove them from the commits already made"

# --- Part B: the active: field contract (OBS-37) -----------------------------------------

test_start "the skill states which plugin honours active:"
assert_contains "$RALPH_TEXT" "reads the field"

test_start "and that it is inert on the others"
assert_contains "$RALPH_TEXT" "the field is inert"

# The instruction that holds regardless of plugin. Without it a user on an inert plugin has
# been told the field does nothing and given no working alternative.
test_start "and names the stop that works on every plugin"
assert_contains "$RALPH_TEXT" "deleting \`.claude/ralph-loop.local.md\` stops the loop"

# The must-NOT. The trap OBS-37 recorded is a control that appears to work, so the skill must
# not state the pause unconditionally.
test_start "the skill does not claim active: false pauses every plugin"
assert_not_contains "$RALPH_TEXT" "setting it \`false\` pauses the loop on any plugin"

# The cross-document oracle. Both sides are asked *which* plugin honours the field, by
# extraction; a rename or a change of fork on either side fails here rather than leaving one
# document quietly describing a plugin that no longer behaves that way.
SKILL_HONOURS=$(printf '%s' "$RALPH_TEXT" | grep -oE '`[a-z-]+@[a-z-]+` reads the field' | grep -oE '`[^`]+`' | head -1 | tr -d '`')
MAINT_HONOURS=$(printf '%s' "$MAINT_TEXT" | grep -E '^\| `[a-z-]+@[a-z-]+` \| Yes \|' | grep -oE '`[^`]+`' | head -1 | tr -d '`')
assert_agrees "the plugin that honours \`active:\`" \
  "ralph/SKILL.md" "$SKILL_HONOURS" \
  "docs/maintenance/README.md" "$MAINT_HONOURS"

# The maintenance table is only informative if it also records the plugins that ignore it.
# A table listing one plugin says nothing about what a user on another one should expect.
test_start "the maintenance record names the plugins where active: is inert"
MAINT_INERT=$(printf '%s' "$MAINT_TEXT" | grep -cE '^\| `[a-z-]+@[a-z-]+` \| No \|')
assert_equals "2" "$MAINT_INERT"

# The schema table's own row must not still read as unconditional, which is what it said
# before the fork honoured the field.
test_start "and its schema row no longer says the field is unchecked"
assert_not_contains "$MAINT_TEXT" "Not currently checked by stop hook"

test_summary
