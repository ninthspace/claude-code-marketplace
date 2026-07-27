#!/bin/bash
# test-ralph-promise-modes.sh — Tests for the per-mode completion promise
# (Epic 45-03 Story 4, spec 45 FR10 and its must-NOT).
#
# --- What has an oracle here ------------------------------------------------------------
#
# The promise exists in two places that must agree: the variable table binds a tag per mode,
# and each mode's completion clause tells the model to emit a literal string. The stop hook
# compares the emitted text to the frontmatter with string equality, so a table and a clause
# that disagree by one character produce a loop that never ends — and both halves read
# perfectly on their own. So the assertion is the correspondence: the mapping is parsed out of
# the table, the tokens out of the clauses, and the two are compared.
#
# Retro 23's shape is why this suite exists rather than an extra assertion in
# `test-ralph-promise.sh`: every assertion there is phrased about "the promise" and scoped to
# the epic-mode template line. Those stay correct and become *epic mode's* assertions; what
# they cannot see is a second subject.
#
# The must-NOT — no evidence inside the tag — is checked as a shape rather than a word: the
# instruction that emits must have the tag as its last token before the punctuation, and the
# counts must be instructed separately. A control moves the counts inside and the shape check
# fails.
#
# Not tested: that the stop hook actually matches. Nothing here runs it, and the hook lives in
# another plugin (ralph-wiggum). What is checkable is that the strings this skill writes into
# the frontmatter and into the prompt are the same string.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

RALPH_SKILL="$SCRIPT_DIR/../../skills/ralph/SKILL.md"

echo "Testing: ralph's per-mode completion promise (Epic 45-03 Story 4)"
echo "================================================================="

# --- The mapping, read out of the variable table --------------------------------------------

promise_row() { grep -F '`{completion_promise}` —' "$1"; }

promise_for() {
  promise_row "$1" | grep -oE '`[A-Z_]+` in [a-z]+ mode' |
    awk -v m="$2" '$0 ~ ("in " m " mode") { gsub(/`/, "", $1); print $1 }'
}

EPIC_BOUND=$(promise_for "$RALPH_SKILL" epic)
SPEC_BOUND=$(promise_for "$RALPH_SKILL" spec)

test_start "the variable table binds a promise for each mode"
if [ -n "$EPIC_BOUND" ] && [ -n "$SPEC_BOUND" ]; then
  test_pass
else
  test_fail "read epic='$EPIC_BOUND' spec='$SPEC_BOUND' from the table row"
fi

test_start "spec mode's promise differs from epic mode's"
if [ "$EPIC_BOUND" != "$SPEC_BOUND" ]; then
  test_pass
else
  test_fail "both modes bind $EPIC_BOUND"
fi

# --- The tokens, read out of the clauses that emit them --------------------------------------

template_line()     { grep -F 'Run /cpm:do on epics' "$1"; }
completion_clause() { grep -F 'When phase 2 has no epic left to work' "$1"; }

emitted_token() { printf '%s\n' "$1" | sed -n 's/.*then output \([A-Z_]*\).*/\1/p'; }

EPIC_EMITTED=$(emitted_token "$(template_line "$RALPH_SKILL")")
SPEC_EMITTED=$(emitted_token "$(completion_clause "$RALPH_SKILL")")

test_start "control: a token was extracted from each clause"
if [ -n "$EPIC_EMITTED" ] && [ -n "$SPEC_EMITTED" ]; then
  test_pass
else
  test_fail "extracted epic='$EPIC_EMITTED' spec='$SPEC_EMITTED'"
fi

test_start "the tag epic mode emits is the tag epic mode binds"
assert_equals "$EPIC_BOUND" "$EPIC_EMITTED"

test_start "the tag spec mode emits is the tag spec mode binds"
assert_equals "$SPEC_BOUND" "$SPEC_EMITTED"

test_start "control: a table entry changed without its clause is detected"
DRIFTED="$TEST_TMPDIR/ralph-drifted-promise.md"
sed "s/\`$SPEC_BOUND\` in spec mode/\`SPEC_COMPLETE\` in spec mode/" "$RALPH_SKILL" > "$DRIFTED"
if [ "$(promise_for "$DRIFTED" spec)" != "$(emitted_token "$(completion_clause "$DRIFTED")")" ]; then
  test_pass
else
  test_fail "the drifted table still compared equal to the clause"
fi

# --- Fixed at launch, not chosen -------------------------------------------------------------
#
# "Fixed at launch" is checkable two ways: the value is derived from the mode resolved in
# Step 1a, and it is written into the frontmatter the launch step writes. What would break it
# is a gate offering the promise as an option, so the negative is that no AskUserQuestion in
# this skill mentions the promise.

test_start "the promise is derived from the mode rather than asked for"
assert_contains "$(promise_row "$RALPH_SKILL")" "Taken from \`{mode}\` (Step 1a) and fixed for the run"

test_start "and it is written into the state file's frontmatter"
assert_contains "$(grep -c 'completion_promise: "{completion_promise}"' "$RALPH_SKILL")" "1"

# Scoped to the skill's own procedure, with the prompt blocks removed. Those blocks name both
# `AskUserQuestion` (telling the model to answer gates autonomously) and the tag, so a
# line-wide search reports the template as a gate offering the promise — the first version of
# this assertion did exactly that. The wrong edit it is written for is a gate in *this* skill
# whose options are promise strings, which can only appear in the procedural text.
procedural_text() {
  grep -vF 'Run /cpm:do on epics' "$1" |
    grep -vF 'When phase 2 has no epic left to work' |
    grep -vF 'Work spec {spec_path} to completion.'
}

test_start "must NOT offer the promise as a choice: no gate in the procedure names a tag"
assert_empty "$(procedural_text "$RALPH_SKILL" | grep 'AskUserQuestion' |
  grep -E 'ALL_EPICS_COMPLETE|SPEC_DELIVERED')"

test_start "control: a gate offering the two tags as options is detected"
CHOOSY="$TEST_TMPDIR/ralph-promise-choice.md"
awk '{ print }
  /^#### One promise per mode/ { print ""; print "Use AskUserQuestion: options ALL_EPICS_COMPLETE or SPEC_DELIVERED." }' \
  "$RALPH_SKILL" > "$CHOOSY"
if [ -n "$(procedural_text "$CHOOSY" | grep 'AskUserQuestion' | grep -E 'ALL_EPICS_COMPLETE|SPEC_DELIVERED')" ]; then
  test_pass
else
  test_fail "the inserted gate was not reported"
fi

# --- The must-NOT: evidence beside the tag, never inside it ------------------------------------
#
# Shape, not vocabulary: the emit instruction ends at the tag, and the counts are a separate
# instruction. `tag_is_last` reads the characters that follow the token in the emitting
# sentence — anything other than punctuation means payload rode along inside it.

tag_is_last() {
  printf '%s\n' "$1" | grep -qE "then output $2[;.]"
}

test_start "epic mode's emit instruction ends at the tag"
if tag_is_last "$(template_line "$RALPH_SKILL")" "$EPIC_EMITTED"; then
  test_pass
else
  test_fail "something follows $EPIC_EMITTED in the emitting sentence"
fi

test_start "spec mode's emit instruction ends at the tag"
if tag_is_last "$(completion_clause "$RALPH_SKILL")" "$SPEC_EMITTED"; then
  test_pass
else
  test_fail "something follows $SPEC_EMITTED in the emitting sentence"
fi

test_start "both clauses instruct the counts to go beside the promise"
if printf '%s\n' "$(template_line "$RALPH_SKILL")" | grep -qF 'on their own line beside the promise' &&
   printf '%s\n' "$(completion_clause "$RALPH_SKILL")" | grep -qF 'on their own line beside the promise'; then
  test_pass
else
  test_fail "one of the two clauses does not place the counts beside the promise"
fi

test_start "control: evidence moved inside the tag is detected"
INSIDE="$TEST_TMPDIR/ralph-payload-in-tag.md"
sed "s/then output $SPEC_EMITTED;/then output $SPEC_EMITTED with the counts;/" "$RALPH_SKILL" > "$INSIDE"
if ! tag_is_last "$(completion_clause "$INSIDE")" "$SPEC_EMITTED"; then
  test_pass
else
  test_fail "the payload-carrying tag passed the shape check"
fi

# The prompt writes no tag markup of its own — the hook's per-iteration system message carries
# the `<promise>` instruction, and Step 2 rules XML out of the prompt. Asserted for epic mode
# already; spec mode's clause is the second subject retro 23 predicted.
test_start "spec mode's clause writes no promise tag of its own"
assert_not_contains "$(completion_clause "$RALPH_SKILL")" "<promise>"

test_summary
