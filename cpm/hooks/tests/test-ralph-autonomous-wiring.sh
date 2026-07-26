#!/bin/bash
# test-ralph-autonomous-wiring.sh — Tests for the two sites in cpm/skills/ralph/
# SKILL.md that carry the autonomous change-resolution behaviour (spec 43, epic
# 43-02, Story 4): the Change Type Decision row in the cpm:do Interaction Gates
# table, and the matching clause in the generated prompt template.
#
# Only the second is operative. The stop hook feeds the prompt back verbatim on
# each iteration, so the loop reads the template line and never reads the table;
# the table is documentation for whoever maintains the override set. That
# asymmetry is why the story's criterion demands the two be asserted *together*
# in a single test — a table row that landed without its prompt clause would
# document a behaviour the loop does not have, and would read as done.
#
# WHAT THIS SUITE DOES NOT TEST — read this before trusting a green run.
# Three of Story 4's five criteria are [manual]:
#   - that the clause names the behaviour and its guard without restating the
#     rule (an editorial judgement — the structural half is asserted below as
#     the absence of the rule's distinctive detail, which is a proxy, not the
#     criterion);
#   - the must-NOT on restatement, which shares that oracle;
#   - that the prompt stays a pure function of its interpolated variables — the
#     template is a static line with no conditional text, which is why the
#     property holds, but "same inputs, same prompt" is a claim about the
#     assembly step and no file state proves it.
# Those were verified by reading the finished sites in place.
#
# One assertion per test_start (retro 15), so the ratio stays honest. The paired
# criterion-1 test is the deliberate exception the criterion asks for: it is one
# assertion *about the pair*, and it names which side is missing when it fails.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

RALPH_SKILL="$SCRIPT_DIR/../../skills/ralph/SKILL.md"

echo "Testing: ralph autonomous change-resolution wiring"
echo "=================================================="

TABLE_MARKER='| Guidelines — Change Type Decision'
PROMPT_MARKER='take do'\''s autonomous branch'

# prompt_line <file> — the generated prompt template, which is the single line
# beginning "Run /cpm:do on epics". Extracted rather than re-typed: a re-typed
# copy is how a documented invocation drifted from the real one for months
# (spec 43, epic 43-01).
prompt_line() { grep -F 'Run /cpm:do on epics' "$1"; }

# has_both <file> — the paired condition, as one predicate over one file, so
# both the real file and the fixtures below are judged by identical logic.
has_both() {
  grep -qF -- "$TABLE_MARKER" "$1" && grep -qF -- "$PROMPT_MARKER" "$1"
}

PROMPT=$(prompt_line "$RALPH_SKILL")

# --- The slice itself, before anything is asserted about its contents ---

test_start "The prompt template line is findable in ralph/SKILL.md"
if [ -n "$PROMPT" ]; then test_pass; else test_fail "no 'Run /cpm:do on epics' line in $RALPH_SKILL"; fi

test_start "There is exactly one prompt template line"
# Two would make every assertion below ambiguous about which one it checked.
assert_equals "1" "$(prompt_line "$RALPH_SKILL" | wc -l | tr -d ' ')"

# --- Criterion 1: the two sites, asserted together ---

test_start "The override table row and the prompt clause are both present"
if has_both "$RALPH_SKILL"; then
  test_pass
elif grep -qF -- "$TABLE_MARKER" "$RALPH_SKILL"; then
  test_fail "table row present but the prompt clause is missing — the documented behaviour is not the one the loop receives"
elif grep -qF -- "$PROMPT_MARKER" "$RALPH_SKILL"; then
  test_fail "prompt clause present but the override table row is missing"
else
  test_fail "neither site is present"
fi

test_start "Negative control: the pair check fails when only the table row is present"
sed "s/${PROMPT_MARKER}/REMOVED/" "$RALPH_SKILL" > "$TEST_TMPDIR/no-prompt.md"
if has_both "$TEST_TMPDIR/no-prompt.md"; then
  test_fail "the pair check passed a file whose prompt clause was removed — it is not discriminating"
else
  test_pass
fi

test_start "Negative control: the pair check fails when only the prompt clause is present"
sed "s/${TABLE_MARKER}/| REMOVED/" "$RALPH_SKILL" > "$TEST_TMPDIR/no-row.md"
if has_both "$TEST_TMPDIR/no-row.md"; then
  test_fail "the pair check passed a file whose table row was removed — it is not discriminating"
else
  test_pass
fi

# --- Criterion 3: the stated budget matches the measured length ---

test_start "The stated character budget matches the template's actual length"
STATED=$(grep -oE '\*\*Length: [0-9]+ characters\*\*' "$RALPH_SKILL" | grep -oE '[0-9]+')
assert_equals "${#PROMPT}" "$STATED"

test_start "Negative control: a stated budget that disagrees with the template is detected"
# Run the same extract-and-compare against a file whose stated figure has been
# mutated. Without this the assertion above proves only that some number was
# found, which is what "around 1100" against an actual 1,477 also satisfied.
sed 's/\*\*Length: [0-9]* characters\*\*/**Length: 1100 characters**/' "$RALPH_SKILL" > "$TEST_TMPDIR/bad-budget.md"
BAD_STATED=$(grep -oE '\*\*Length: [0-9]+ characters\*\*' "$TEST_TMPDIR/bad-budget.md" | grep -oE '[0-9]+')
BAD_PROMPT=$(prompt_line "$TEST_TMPDIR/bad-budget.md")
if [ "${#BAD_PROMPT}" = "$BAD_STATED" ]; then
  test_fail "the comparison accepted a file stating 1100 against a ${#BAD_PROMPT}-character template"
else
  test_pass
fi

# --- What the prompt clause says (structural half of criteria 2 and 5) ---

test_start "The prompt clause tells the loop not to pick one of the gate's options"
assert_contains "$PROMPT" "do not pick one of its options"

test_start "The prompt clause names the amend-the-epic disposition"
assert_contains "$PROMPT" "amend the open epic doc"

test_start "The prompt clause states that /cpm:pivot is never taken"
assert_contains "$PROMPT" "never /cpm:pivot"

test_start "The prompt clause names the guard on amendment"
assert_contains "$PROMPT" "Amend only on a citable contradiction"

test_start "The prompt clause requires the Pivot deferred breadcrumb"
assert_contains "$PROMPT" "Pivot deferred breadcrumb"

test_start "The prompt clause requires amendments reported apart from deferrals"
assert_contains "$PROMPT" "Report amendments separately"

# --- must NOT restate the rule: the distinctive detail stays in cpm:do ---

test_start "must NOT: the prompt does not restate the blast radius"
assert_not_contains "$PROMPT" "coverage matrix"

test_start "must NOT: the prompt does not restate the wrong-versus-unmet rule"
assert_not_contains "$PROMPT" "merely unmet"

test_start "must NOT: the prompt does not restate the breadcrumb's field list"
assert_not_contains "$PROMPT" "target artefact"

# --- The prompt's own format constraints, which this story's clause must keep ---

test_start "The prompt template contains no backticks"
# The stop hook feeds the line back verbatim; markdown in it is noise the model
# has to parse past on every iteration.
assert_not_contains "$PROMPT" '`'

test_start "The prompt template uses -- rather than an em dash"
assert_not_contains "$PROMPT" "—"

test_start "Negative control: the em-dash assertion can see an em dash"
assert_contains "$TABLE_MARKER" "—"

test_summary
