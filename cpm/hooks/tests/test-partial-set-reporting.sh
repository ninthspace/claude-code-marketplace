#!/bin/bash
# test-partial-set-reporting.sh — Epic 45-04 Story 1: report a partial phase 1 rather than
# resuming it (spec 45 FR9, FR9 must-NOT, NFR6).
#
# --- Why this story exists, and what changed under it ---------------------------------
#
# FR9 originally asked the loop to *resume* an interrupted phase 1. The 2026-07-27 pivot
# established that it cannot: `cpm:epics` writes each epic doc **and its matrix** before
# starting the next, so a partial phase 1 always leaves a matrix on disk, and exit `4` —
# *zero matrices name this spec* — is the only route into `/cpm:epics`. The resume path is
# unreachable through the phase predicate. What the loop does instead is report: name the
# requirements the partial set covers, name the ones it does not, and leave the epic docs
# exactly where they are.
#
# --- What has an oracle here ----------------------------------------------------------
#
# The load-bearing half is **reachability**, which is retro 29's remedy and is available
# here because `coverage-rollup.sh` is a real script and is what the branch predicate reads.
# A fixture is built in the situation FR9 describes — epics on disk, a requirement none of
# them covers — the roll-up is run for its *real* exit code, and the records it actually
# emits are checked against what the clause instructs the loop to say. A clause telling the
# loop to name the covered requirements is unfulfillable if nothing emits them, and that is
# a defect no amount of reading the clause would find. Before this story the clause asked
# only for the untraced names; asserting the covered side is emitted is what makes the
# widened instruction more than a wish.
#
# The other half is a **regression net over prose**. That the branch says it leaves the
# epic docs alone has no oracle — nothing in this repository launches a loop, and no
# executable reads the prompt. Those assertions are pinned wording, and each carries a
# control that mutates the clause into the plausible *wrong* design rather than merely
# deleting the string it greps for, so the control discriminates between two readings
# instead of restating the assertion backwards.
#
# --- What is deliberately not repeated here -------------------------------------------
#
# The FR9 must-NOT — that the clause never re-enters `/cpm:epics` over a partial set — is
# already asserted in `test-ralph-two-phase-prompt.sh`, which extracts the generation
# instruction by its exact form (`run /cpm:epics on {spec_path}`), shows it appears exactly
# once, shows it sits in the exit-4 sentence, and carries the pre-fix wording as a control.
# That is the same criterion; a second copy here would drift rather than reinforce.
#
# The renumbering half of NFR6 is asserted at its *real* failure mode rather than by
# arithmetic. `cpm:epics` assigns sub-numbers as `max + 1` across the union of the live and
# archived epic directories, and gaps from deleted sub-numbers are preserved deliberately —
# they are identifiers, not ordinals. A demonstration that `max + 1` over {01, 03} yields 04
# would be arithmetic that cannot fail. What *can* fail is the rule drifting to one that
# reuses a gap, or dropping the archive from its glob so an archived number comes back; both
# renumber an already-assigned identifier, and both are pinned below.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/coverage-fixture-helpers.sh"

RALPH_SKILL="$SCRIPT_DIR/../../skills/ralph/SKILL.md"
EPICS_SKILL="$SCRIPT_DIR/../../skills/epics/SKILL.md"

echo "Testing: partial-set reporting (Epic 45-04 Story 1)"
echo "=================================================="

# --- The branch under test ------------------------------------------------------------
#
# Located the way the four existing suites locate the epic-mode template: by its opening
# words, extracted rather than re-typed. A re-typed clause tests the copy in the test.

phase_clause() { grep -F 'Work spec {spec_path} to completion.' "$1"; }

PHASE=$(phase_clause "$RALPH_SKILL")

test_start "control: the skill carries exactly one spec-mode phase clause"
assert_equals "1" "$(printf '%s\n' "$PHASE" | grep -c .)"

# Sentences are split on the full stops that separate them; the clause has no abbreviations.
sentence_with() { printf '%s\n' "$1" | tr '.' '\n' | grep -F "$2"; }

PARTIAL=$(sentence_with "$PHASE" 'on any other code')

test_start "control: exactly one sentence carries the non-zero-untraced branch"
assert_equals "1" "$(printf '%s\n' "$PARTIAL" | grep -c .)"

# --- Criterion 1: the report names both sides -----------------------------------------
#
# Two independent checks rather than one pattern spanning both, so a sentence that names
# the covered side and drops the uncovered one fails just as loudly as the reverse.

names_covered()   { printf '%s\n' "$1" | grep -q 'does cover'; }
names_uncovered() { printf '%s\n' "$1" | grep -q 'untraced ones it does not'; }

test_start "the partial-set branch names the requirements the epics on disk do cover"
if names_covered "$PARTIAL"; then test_pass; else test_fail "branch reads: $PARTIAL"; fi

test_start "and names the untraced ones they do not"
if names_uncovered "$PARTIAL"; then test_pass; else test_fail "branch reads: $PARTIAL"; fi

# The control is the wording this story replaced — a real prior state of the file, not an
# invented one. It reported one side of the partial set and was silent about the other.
PRE_FIX=$(printf '%s\n' "$PARTIAL" |
  sed 's/report that partial set from the STATE records — the requirements it does cover as well as the untraced ones it does not — leave every epic doc already on disk exactly as it is, and stop/name those requirements and stop/')

test_start "control: the pre-fix wording named only the uncovered side"
if [ "$PRE_FIX" != "$PARTIAL" ] && ! names_covered "$PRE_FIX" && ! names_uncovered "$PRE_FIX"; then
  test_pass
else
  test_fail "the reverted branch reads: $PRE_FIX"
fi

# --- Criterion 1 and 3: the epics on disk are left alone ------------------------------
#
# A prose pin. The control mutates the branch into the plausible alternative design — one
# that tells the loop to finish the half-written set itself — rather than deleting the
# phrase the assertion greps for, so it separates two readings instead of restating the
# assertion in reverse.

leaves_alone() { printf '%s\n' "$1" | grep -q 'leave every epic doc already on disk exactly as it is'; }

test_start "the partial-set branch leaves the epic docs already on disk untouched"
if leaves_alone "$PARTIAL"; then test_pass; else test_fail "branch reads: $PARTIAL"; fi

COMPLETING=$(printf '%s\n' "$PARTIAL" |
  sed 's/leave every epic doc already on disk exactly as it is/complete the epic docs already on disk yourself/')

test_start "control: a branch that instructs completing the set on disk is detected"
if [ "$COMPLETING" != "$PARTIAL" ] && ! leaves_alone "$COMPLETING"; then
  test_pass
else
  test_fail "the mutated branch reads: $COMPLETING"
fi

# --- Reachability: the situation FR9 describes, and what the script emits in it --------
#
# Epics on disk, one requirement none of them covers. The exit code is taken from the run
# rather than assumed, so a future change to what this situation returns fails here instead
# of leaving the clause branching on a code nothing produces (retro 27).

P_DIR=$(coverage_fixture_dir partial-set)
P_SPEC=$(coverage_fixture_spec 79-spec-partial-set --dir "$P_DIR" \
  --must FR1 "a requirement the partial set covers and verified" \
  --must FR2 "a requirement the partial set covers, not yet verified" \
  --must FR3 "a requirement the interrupted run never reached")

coverage_fixture_matrix 79-01-coverage-partial-set \
  "docs/specifications/79-spec-partial-set.md" --dir "$P_DIR" \
  --row FR1 "a requirement the partial set covers and verified" "the FR1 criterion" "Story 1" '✓' \
  --row FR2 "a requirement the partial set covers, not yet verified" "the FR2 criterion" "Story 2" '' \
  >/dev/null

P_RC=$(coverage_rollup_rc --spec "$P_SPEC" --matrix-dir "$P_DIR" --verdict)
P_OUT=$(coverage_rollup_run --spec "$P_SPEC" --matrix-dir "$P_DIR")

test_start "control: a partial set is not the exit-4 case, so it reaches 'any other code'"
if [ "$P_RC" != "4" ] && [ "$P_RC" != "0" ]; then
  test_pass
else
  test_fail "the fixture returned $P_RC, so it does not exercise the branch under test"
fi

test_start "the roll-up names the untraced requirements the partial set does not cover"
assert_equals "FR3" "$(coverage_states_in "$P_OUT" untraced | tr '\n' ' ' | sed 's/ $//')"

# The half the widened instruction depends on. Both non-untraced states count as covered:
# a requirement with rows is claimed by the partial set whether or not those rows are ticked.
P_COVERED=$(printf '%s\n%s\n' \
  "$(coverage_states_in "$P_OUT" delivered)" "$(coverage_states_in "$P_OUT" in-progress)" |
  grep -c .)

test_start "and names the ones it does cover, which is what the widened branch asks for"
assert_equals "2" "$P_COVERED"

# Without this the untraced assertion above would pass on a fixture that traced nothing,
# and the partial state would never have been built.
F_DIR=$(coverage_fixture_dir fully-covered)
F_SPEC=$(coverage_fixture_spec 80-spec-fully-covered --dir "$F_DIR" \
  --must FR1 "the only requirement" )
coverage_fixture_matrix 80-01-coverage-fully-covered \
  "docs/specifications/80-spec-fully-covered.md" --dir "$F_DIR" \
  --row FR1 "the only requirement" "the FR1 criterion" "Story 1" '✓' >/dev/null

test_start "control: a fully-covered spec leaves nothing untraced, so the fixture discriminates"
assert_empty "$(coverage_states_in "$(coverage_rollup_run --spec "$F_SPEC" --matrix-dir "$F_DIR")" untraced)"

# --- NFR6: an already-assigned sub-number is never reassigned -------------------------
#
# The rule, read out of the skill that states it. `cpm:epics` runs nothing, so this is a
# pin — but it is a pin on the sentence whose drift would cause the renumber, not on a
# restatement of it somewhere downstream.

numbering_rule() {
  grep -F 'Assign `{seq}` per parent using the shared Numbering procedure' "$EPICS_SKILL"
}

RULE=$(numbering_rule)

test_start "control: the sub-number assignment rule could be located in cpm:epics"
assert_equals "1" "$(printf '%s\n' "$RULE" | grep -c .)"

test_start "sub-numbers are assigned as max + 1, so a preserved gap is never filled"
assert_contains "$RULE" 'take `max + 1`'

# A rule that fills the lowest free slot renumbers nothing on its own — it *reuses* an
# identifier a deleted epic still owns in every cross-reference written before the deletion.
LOWEST_FREE=$(printf '%s\n' "$RULE" | sed 's/take `max + 1`/take the lowest unused number/')

test_start "control: a lowest-unused rule is detected"
assert_not_contains "$LOWEST_FREE" 'take `max + 1`'

test_start "and the max is taken across the archive as well as the live directory"
assert_contains "$RULE" 'docs/archive/epics/{parent}-[0-9]*-epic-*.md'

NO_ARCHIVE=$(printf '%s\n' "$RULE" | sed 's| and `docs/archive/epics/{parent}-\[0-9\]\*-epic-\*\.md`||')

test_start "control: a rule that globs only the live directory is detected"
assert_not_contains "$NO_ARCHIVE" 'docs/archive/epics/{parent}-[0-9]*-epic-*.md'

test_summary
