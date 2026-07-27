#!/bin/bash
# test-ralph-phase-integration.sh — Cross-story integration for phase detection
# (Epic 45-03 Story 5, spec 45 FR6 and FR7).
#
# --- Why this suite exists ----------------------------------------------------------------
#
# In epic 44-03 a template's `on 3` was changed to `on 4` — a code the script never returned —
# and every assertion stayed green. The script still exited 3, the prose still read correctly,
# and the branch could never fire, because nothing compared what the document claimed to what
# the program did. Spec 45 gives the prompt four codes to branch on, so the same failure is
# four times as available.
#
# So this suite does not check wording. It extracts the command from the prompt, builds one
# fixture per *situation the prompt names*, runs the command, and asserts that the code coming
# back is the code whose branch describes that situation:
#
#   everything traced and verified   → the branch that emits the promise
#   a row left unverified            → the branch that says keep working
#   no matrix naming the spec        → the branch that returns to phase 1
#   a spec that cannot be read       → no explicit branch; the catch-all, and never phase 1
#
# The command is extracted rather than re-typed (AD5, spec 43): a re-typed command tests the
# copy in the test. The one substitution made here is `--matrix-dir`, which the real
# invocation does not pass — it exists so fixtures can live under TEST_TMPDIR, and it is
# appended rather than replacing anything the prompt names.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/coverage-fixture-helpers.sh"

RALPH_SKILL="$SCRIPT_DIR/../../skills/ralph/SKILL.md"
ROLLUP="$SCRIPT_DIR/../lib/coverage-rollup.sh"

echo "Testing: the codes the prompt branches on are the codes the command returns (45-03 S5)"
echo "======================================================================================"

# --- The command and the branch table, both read out of the prompt --------------------------

completion_clause() { grep -F 'When phase 2 has no epic left to work' "$1"; }
phase_clause()      { grep -F 'Work spec {spec_path} to completion.' "$1"; }

COMPLETION=$(completion_clause "$RALPH_SKILL")
PHASE=$(phase_clause "$RALPH_SKILL")

COMMAND_TEMPLATE=$(printf '%s\n' "$COMPLETION" |
  sed -n 's/.*run \(bash {rollup_script}[^,]*--verdict\) and let its exit code decide.*/\1/p')

test_start "the completion clause names a runnable command"
assert_equals 'bash {rollup_script} --spec {spec_path} --verdict' "$COMMAND_TEMPLATE"

# Interpolate exactly the two placeholders the prompt itself would, then append the testing
# override. Nothing else about the command is invented here.
run_named_command() {
  local spec="$1" matrix_dir="$2" cmd
  cmd=$(printf '%s' "$COMMAND_TEMPLATE" |
    sed "s|{rollup_script}|$ROLLUP|; s|{spec_path}|$spec|")
  run_without_env CLAUDE_PROJECT_DIR -- $cmd --matrix-dir "$matrix_dir" >/dev/null 2>&1
  printf '%s\n' "$?"
}

branches() { printf '%s\n' "$COMPLETION" | sed 's/.*let its exit code decide: //' | tr ';' '\n'; }
branch_for() { branches | sed -n "s/^ *on $1, //p"; }
explicit_codes() { branches | sed -n 's/^ *on \([0-9]*\),.*/\1/p' | sort -u | tr '\n' ' '; }

codes_routed_to() {
  local label="$2"
  printf '%s\n' "$1" | grep -oE "Exit [0-9]+( or [0-9]+)? means $label" |
    sed "s/ means $label\$//; s/^Exit //; s/ or / /" |
    tr ' ' '\n' | grep -E '^[0-9]+$' | sort -u | tr '\n' ' '
}

# --- One fixture per situation the prompt names ----------------------------------------------

FX=$(coverage_fixture_dir phase-integration)
SPEC=$(coverage_fixture_spec 81-spec-phase-integration --dir "$FX" \
  --must FR1 "the only requirement")
SPEC_REF="docs/specifications/81-spec-phase-integration.md"

DELIVERED_DIR=$(coverage_fixture_dir phase-integration-delivered)
coverage_fixture_matrix 81-01-coverage-delivered "$SPEC_REF" --dir "$DELIVERED_DIR" \
  --epic "$DELIVERED_DIR/81-01-epic-delivered.md" \
  --row FR1 "the only requirement" "the FR1 criterion" "Story 1" '✓' >/dev/null
: > "$DELIVERED_DIR/81-01-epic-delivered.md"

OUTSTANDING_DIR=$(coverage_fixture_dir phase-integration-outstanding)
coverage_fixture_matrix 81-01-coverage-outstanding "$SPEC_REF" --dir "$OUTSTANDING_DIR" \
  --epic "$OUTSTANDING_DIR/81-01-epic-outstanding.md" \
  --row FR1 "the only requirement" "the FR1 criterion" "Story 1" '-' >/dev/null
: > "$OUTSTANDING_DIR/81-01-epic-outstanding.md"

# No matrix names this spec: the directory holds one that names a different spec, so the
# fixture distinguishes "nothing here" from "nothing here for you".
NO_MATRIX_DIR=$(coverage_fixture_dir phase-integration-no-matrix)
coverage_fixture_matrix 81-02-coverage-elsewhere "docs/specifications/99-spec-other.md" \
  --dir "$NO_MATRIX_DIR" --epic "$NO_MATRIX_DIR/81-02-epic-elsewhere.md" \
  --row FR1 "another spec's requirement" "another criterion" "Story 1" '✓' >/dev/null
: > "$NO_MATRIX_DIR/81-02-epic-elsewhere.md"

RC_DELIVERED=$(run_named_command "$SPEC" "$DELIVERED_DIR")
RC_OUTSTANDING=$(run_named_command "$SPEC" "$OUTSTANDING_DIR")
RC_NO_MATRIX=$(run_named_command "$SPEC" "$NO_MATRIX_DIR")
RC_UNREADABLE=$(run_named_command "$FX/81-99-spec-absent.md" "$DELIVERED_DIR")

test_start "control: the four situations produce four distinct exit codes"
DISTINCT=$(printf '%s\n%s\n%s\n%s\n' \
  "$RC_DELIVERED" "$RC_OUTSTANDING" "$RC_NO_MATRIX" "$RC_UNREADABLE" | sort -u | grep -c .)
assert_equals "4" "$DISTINCT"

# --- Each code against the branch that claims to describe its situation ----------------------

test_start "the code a fully verified spec returns is the branch that emits the promise"
assert_contains "$(branch_for "$RC_DELIVERED")" "output SPEC_DELIVERED"

test_start "the code an unverified row returns is the branch that keeps working"
assert_contains "$(branch_for "$RC_OUTSTANDING")" "keep working"

test_start "and that branch withholds the promise"
assert_contains "$(branch_for "$RC_OUTSTANDING")" "do not output it"

test_start "the code a spec with no matrix returns is the branch that goes back to phase 1"
assert_contains "$(branch_for "$RC_NO_MATRIX")" "go back to phase 1"

test_start "and the phase clause routes that same code to phase 1"
assert_contains " $(codes_routed_to "$PHASE" 'phase 1') " " $RC_NO_MATRIX "

# The must-NOT, measured end to end rather than read: the code an unreadable spec actually
# returns must not be the code the clauses route to phase 1.
test_start "must NOT treat a read failure as phase 1 not started"
if [ "$RC_UNREADABLE" != "$RC_NO_MATRIX" ] &&
   ! printf '%s' " $(codes_routed_to "$PHASE" 'phase 1') " | grep -q " $RC_UNREADABLE "; then
  test_pass
else
  test_fail "an unreadable spec returned $RC_UNREADABLE, which is routed to phase 1"
fi

test_start "the read-failure code is routed to stop"
assert_contains " $(codes_routed_to "$PHASE" 'the check could not run') " " $RC_UNREADABLE "

test_start "and it has no branch of its own, so it reaches the catch-all"
assert_not_contains " $(explicit_codes) " " $RC_UNREADABLE "

test_start "the catch-all withholds the promise and says the check could not run"
assert_contains "$COMPLETION" "on any other code, do not output it and say the check could not run"

# --- Controls: the comparison has to be able to fail -----------------------------------------
#
# Every assertion above passes if the branch text happens to contain the phrase. These two
# mutate the prompt the way the 44-03 defect mutated it — a branch moved to a code the
# situation does not produce — and the same lookups must disagree.

test_start "control: swapping two branches' codes is detected"
SWAPPED="$TEST_TMPDIR/ralph-swapped-branches.md"
sed "s/on $RC_NO_MATRIX, do not output it and go back to phase 1/on 9, do not output it and go back to phase 1/" \
  "$RALPH_SKILL" > "$SWAPPED"
SWAPPED_BRANCH=$(completion_clause "$SWAPPED" | sed 's/.*let its exit code decide: //' | tr ';' '\n' |
  sed -n "s/^ *on $RC_NO_MATRIX, //p")
if [ -z "$SWAPPED_BRANCH" ]; then
  test_pass
else
  test_fail "code $RC_NO_MATRIX still had a branch after being renumbered: $SWAPPED_BRANCH"
fi

test_start "control: routing the read-failure code to phase 1 is detected"
COLLAPSED="$TEST_TMPDIR/ralph-collapsed-routing.md"
sed "s/Exit $RC_NO_MATRIX means phase 1/Exit $RC_UNREADABLE means phase 1/" "$RALPH_SKILL" > "$COLLAPSED"
if printf '%s' " $(codes_routed_to "$(phase_clause "$COLLAPSED")" 'phase 1') " |
     grep -q " $RC_UNREADABLE "; then
  test_pass
else
  test_fail "the collapsed routing was not reported"
fi

test_summary
