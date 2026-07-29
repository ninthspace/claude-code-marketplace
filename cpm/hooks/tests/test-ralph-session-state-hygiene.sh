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

# --- The iteration log is session state too, and must land inside that same glob -------
#
# It is written every iteration, so if it fell outside the ignore pattern it would be the
# worst offender of the three paths above — and it is the newest, so it is the one most
# likely to be added without anyone re-checking. Rather than assert the name, this derives
# the glob's prefix from 1g and requires the logged path to start with it: renaming the log
# is fine, moving it out from under the ignore is not.
LOG_PATH=$(grep -oE 'docs/plans/\.cpm-ralph-log-[^ `]*' "$RALPH_SKILL" | head -1)

test_start "control: the skill names an iteration-log path at all"
if [ -n "$LOG_PATH" ]; then
  test_pass
else
  test_fail "no docs/plans/.cpm-ralph-log-* path in $RALPH_SKILL"
fi

test_start "the iteration log sits under the glob 1g already ignores"
GLOB_PREFIX=${SKILL_GLOB%\*}
GLOB_PREFIX=${GLOB_PREFIX#/}
case "$LOG_PATH" in
  "$GLOB_PREFIX"*) test_pass ;;
  *) test_fail "log path '$LOG_PATH' is not covered by 1g's glob '$SKILL_GLOB'" ;;
esac

# One placeholder has to serve both modes, and it does so only because of where it sits. Spec
# mode assembles its prompt by replacing the template's opening sentence and its completion
# clause; a placeholder in either of those reaches epic mode and not spec mode. So this is
# asserted positionally against the two boundaries rather than by grepping each block for the
# literal — the same clause copied into the phase clause as well would log twice per iteration.
TPL=$(grep -F 'Run /cpm:do on epics' "$RALPH_SKILL")

test_start "the template interpolates the log clause"
assert_contains "$TPL" '{log_clause}'

test_start "and it sits in the middle spec-mode assembly keeps, not in a replaced region"
# The lower bound is the first sentence spec mode *keeps*, not the last one it replaces. Bounding
# on "Continue to each next epic automatically." instead would accept a placeholder glued to that
# sentence's full stop — inside the text being replaced, and higher-offset all the same.
OFF_LOG=$(printf '%s' "$TPL" | awk '{print index($0, "{log_clause}")}')
OFF_OPEN=$(printf '%s' "$TPL" | awk '{print index($0, "Make all decisions autonomously")}')
OFF_DONE=$(printf '%s' "$TPL" | awk '{print index($0, "When the last specified epic completes")}')
if [ "${OFF_OPEN:-0}" -gt 0 ] && [ "${OFF_DONE:-0}" -gt 0 ] &&
   [ "${OFF_LOG:-0}" -gt "$OFF_OPEN" ] && [ "${OFF_LOG:-0}" -lt "$OFF_DONE" ]; then
  test_pass
else
  test_fail "log clause at offset ${OFF_LOG:-0}, outside the surviving middle (${OFF_OPEN:-0}..${OFF_DONE:-0})"
fi

test_start "and the spec-mode phase clause carries no second copy"
assert_not_contains "$(grep -F 'Work spec {spec_path} to completion.' "$RALPH_SKILL")" '{log_clause}'

test_start "the clause is defined in the assembly step's variable list"
assert_contains "$(sed -n '/^### Step 2: Prompt Assembly/,/^#### /p' "$RALPH_SKILL")" '`{log_clause}`'

# The three properties that make the log worth writing. Each is separately losable: a log
# with no commit records nothing a stall check can use, a check with no threshold never
# fires, and a check that does not stop is a log with extra steps.
LOG_SECTION=$(sed -n '/^#### The iteration log/,/^\*\*Template\*\*/p' "$RALPH_SKILL")

# The clause itself, not the section around it. The prose explaining the clause names the same
# fields the clause carries, so an assertion over the whole section stays green on a clause that
# has dropped one — the paragraph mentioning it is enough to satisfy the grep.
LOG_CLAUSE=$(printf '%s\n' "$LOG_SECTION" | awk '/^```/{n++; next} n==1')

# Phrase assertions run against the clause with its line breaks flattened. The block is hard
# wrapped, so where a sentence happens to break is a typographic accident — a phrase assertion
# that fails because a clause got one word longer is testing the wrap, not the rule.
LOG_FLAT=$(printf '%s\n' "$LOG_CLAUSE" | tr '\n' ' ' | tr -s ' ')

test_start "slice: the iteration-log section is bounded"
assert_slice_bounded "$RALPH_SKILL" '^#### The iteration log' '^\*\*Template\*\*' 8 40

test_start "control: the clause block extracts, and is the clause rather than the section"
CLAUSE_LINES=$(printf '%s\n' "$LOG_CLAUSE" | grep -c .)
SECTION_LINES=$(printf '%s\n' "$LOG_SECTION" | grep -c .)
if [ "$CLAUSE_LINES" -ge 3 ] && [ "$CLAUSE_LINES" -lt "$SECTION_LINES" ]; then
  test_pass
else
  test_fail "clause slice is $CLAUSE_LINES lines against a $SECTION_LINES-line section"
fi

test_start "the logged line carries the commit, not only the counts"
assert_contains "$LOG_CLAUSE" 'git rev-parse'

# A repository with no commits is the normal state at iteration 1 of a run started in a fresh
# directory, and `git rev-parse HEAD` exits 128 there. Without the fallback the field carries
# the stderr text, which compares equal across iterations exactly as a real value would — so
# the defect hides inside a working stall check rather than breaking it.
test_start "and falls back rather than letting git's stderr stand in the field"
assert_contains "$LOG_FLAT" 'no-commit'

# The independent signal. The figures move when cpm:do marks rows and the commit moves when
# cpm:do commits — both on work landing, so they are two readings of one event. The tree is
# the only field that moves while work is still in progress.
test_start "the logged line carries a working-tree fingerprint too"
assert_contains "$LOG_FLAT" 'git status --porcelain'

test_start "the stall check requires the figures, the commit and the tree to be unchanged"
if printf '%s\n' "$LOG_FLAT" | grep -qF 'the same figures, the same commit and the same tree'; then
  test_pass
else
  test_fail "the stall condition does not require all three"
fi

test_start "and it names the stopping action rather than only saying to stop"
assert_contains "$LOG_FLAT" 'stop the loop'

# The must-NOT. The whole argument for this log is that it records what a command returned,
# not what the loop thought it was doing — a narrative clause is the kind that goes quiet
# just when it matters, which the field test demonstrated across sixteen stories.
test_start "the section states the log records command output, not the loop's account"
assert_contains "$LOG_SECTION" "Only facts a command produced"

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
