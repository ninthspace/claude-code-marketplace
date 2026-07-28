#!/bin/bash
# test-coverage-label-resolution.sh — a matrix label resolves to exactly one requirement,
# or to none at all.
#
# The defect this covers was found by running `cpm:ralph` in spec mode against a greenfield
# repo, and it is the kind that hides behind a working script. `cov_base_label` stripped a
# trailing *parenthesised* qualifier and nothing else, so a label written as
# `FR7 — Pence-exact remainder rule` — more informative, and the form the generator actually
# produced — joined against no requirement. Every requirement in the spec read untraced while
# a full set of matrices sat on disk claiming to cover them. The same defect was live in this
# repository: spec 40 reported 10 of 10 untraced.
#
# --- Why the obvious fix is a worse bug ---------------------------------------------
#
# "Take the leading `^[A-Z]+[0-9]+` token" resolves the case above and quietly breaks a
# second one. Applied to `ENV1–ENV5` it yields `ENV1`: one requirement traced, four silently
# dropped, and a row on disk asserting coverage of all five. Todays failure is uniform and
# visible; that one is selective and invisible, which is strictly worse.
#
# So resolution refuses rather than guesses. A label naming more than one requirement — a
# range, a comma list, an `and` list — resolves to nothing and the row is reported as
# `UNRESOLVED`. The refusal is the assertion worth having, and the *first-member* control
# below is what tells a correct fix from the dangerous one: both make the descriptive-tail
# case pass, and only one leaves `ENV2`..`ENV5` unclaimed.
#
# --- The oracle ---------------------------------------------------------------------
#
# The pure-function checks are cheap and pin the vocabulary. The end-to-end section is the
# oracle: it builds real fixtures, runs `coverage-rollup.sh` the way a skill runs it, and
# asserts on emitted records. That path covers `cov_base_label`, `coverage_matrix_rows`,
# `emit_matrix_rows` and the verdict together — a change that fixed the function while
# leaving the row emitted as an ordinary `ROW` with an empty base would pass the first
# section and fail the second.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/coverage-fixture-helpers.sh"
. "$SCRIPT_DIR/../lib/coverage-parse.sh"

echo "Testing coverage matrix label resolution"

# --- Resolution: a label carrying a descriptive tail ---------------------------------

test_start "a label with an em-dash tail resolves to its requirement"
assert_equals "FR7" "$(coverage_base_label 'FR7 — Pence-exact remainder rule')"

test_start "and so does one whose prefix is a single letter"
assert_equals "R1" "$(coverage_base_label 'R1 — Subagent delegation')"

# The tail and the qualifier are independent, so a label carrying both must lose both
# rather than whichever the implementation happens to strip first.
test_start "a tail and a parenthesised qualifier both come off"
assert_equals "FR7" "$(coverage_base_label 'FR7 — remainder rule (must NOT)')"

# --- Refusal: a label naming more than one requirement -------------------------------

test_start "an en-dash range resolves to no requirement"
assert_empty "$(coverage_base_label 'ENV1–ENV5')"

test_start "including one whose prefix is the restriction class"
assert_empty "$(coverage_base_label 'ENVX1–ENVX3')"

# The hyphen form matters on its own: it is the one a keyboard produces, so it is the range
# most likely to be written by hand, and it is the one a dash-blind implementation is most
# likely to mistake for part of a descriptive tail.
test_start "and the plain-hyphen range form"
assert_empty "$(coverage_base_label 'FR3-FR5')"

test_start "a comma list resolves to no requirement"
assert_empty "$(coverage_base_label 'ENV9, ENV10, ENV11')"

test_start "and an and-list"
assert_empty "$(coverage_base_label 'FR8 and FR5')"

# **The control that separates a correct fix from the dangerous one.** Leading-token
# extraction passes every assertion above except this one: it returns `ENV1`, which is a
# real requirement, so the row resolves and traces — and ENV2 through ENV5 are dropped
# without a word. Stated as an inequality against the first member specifically, because
# that is the value the wrong implementation produces.
test_start "must NOT resolve a range to its first member"
if [ "$(coverage_base_label 'ENV1–ENV5')" = "ENV1" ]; then
  test_fail "the range resolved to ENV1, silently dropping ENV2 through ENV5"
else
  test_pass
fi

# --- Regression net over what already worked -----------------------------------------
#
# The resolution rules above are new; these four are the contract that existed before and
# must survive it. A rewrite that satisfied every assertion above by returning the leading
# token and nothing else would break all four.

test_start "a bare label still resolves to itself"
assert_equals "FR1" "$(coverage_base_label 'FR1')"

test_start "a parenthesised qualifier still comes off"
assert_equals "FR1" "$(coverage_base_label 'FR1 (must NOT)')"

test_start "a prose label with no requirement code is still returned whole"
assert_equals "Test Infrastructure" "$(coverage_base_label 'Test Infrastructure (story-originated)')"

test_start "FR10 still resolves to FR10, not FR1"
assert_equals "FR10" "$(coverage_base_label 'FR10 — the tenth requirement')"

# --- The oracle: end to end through the roll-up --------------------------------------

FIX_DIR=$(coverage_fixture_dir labelres)

SPEC=$(coverage_fixture_spec 90-spec-labelres --dir "$FIX_DIR" \
  --must ENV1 "the target provides one" \
  --must ENV2 "the target provides two" \
  --must ENV3 "the target provides three" \
  --must FR7  "the remainder rule")

# One matrix, two rows: a resolvable label carrying a tail, and a range naming all three
# ENVs. Both in the same matrix so the run cannot pass by ignoring the file wholesale.
MATRIX=$(coverage_fixture_matrix 90-01-coverage-labelres "$SPEC" --dir "$FIX_DIR" \
  --row "FR7 — Pence-exact remainder rule" "the remainder rule" "remainder criterion" "Story 1" '✓' \
  --row "ENV1–ENV3" "the target provides one" "environmental criterion" "Story 2" '✓')

RUN=$(coverage_rollup_run --spec "$SPEC" --matrix-dir "$FIX_DIR")

test_start "control: the fixture run emitted records at all"
assert_equals "1" "$(coverage_count_type "$RUN" MATRIX)"

test_start "the label with a tail traces to its requirement"
assert_equals "FR7" "$(printf '%s\n' "$RUN" | awk -F'\t' '$1 == "ROW" { print $3 }')"

test_start "the range row is reported as unresolved"
assert_equals "1" "$(coverage_count_type "$RUN" UNRESOLVED)"

# It must not *also* appear as a row. Emitting both would let a consumer counting ROW
# records treat the range as traced while the UNRESOLVED record sat beside it unread.
test_start "and is not emitted as a row as well"
assert_equals "1" "$(coverage_count_type "$RUN" ROW)"

# The same control as the pure-function one, asserted where it actually matters: on the
# records a consumer reads. Leading-token extraction produces a ROW with base ENV1 here.
test_start "must NOT trace any of the range members from that row"
assert_empty "$(printf '%s\n' "$RUN" | awk -F'\t' '$1 == "ROW" && $3 ~ /^ENV/ { print $3 }')"

# All three ENVs stay untraced, which is the honest report: the only row naming them names
# them in a form that cannot be resolved, so nothing has been shown to cover any of them.
test_start "every requirement the unresolved row named is reported untraced"
assert_equals "$(printf 'ENV1\nENV2\nENV3')" "$(coverage_states_in "$RUN" untraced)"

# --- The verdict ----------------------------------------------------------------------
#
# An unresolvable row is outstanding on its own account. In this fixture the untraced
# requirements would force exit 3 anyway, so the fixture below removes them: a spec with
# one requirement, covered by one verified row, plus one unresolved row. Without the
# UNRESOLVED rule that run is clean.

CLEAN_DIR=$(coverage_fixture_dir labelclean)
CLEAN_SPEC=$(coverage_fixture_spec 91-spec-labelclean --dir "$CLEAN_DIR" \
  --must FR7 "the remainder rule")
CLEAN_MATRIX=$(coverage_fixture_matrix 91-01-coverage-labelclean "$CLEAN_SPEC" --dir "$CLEAN_DIR" \
  --row "FR7 — Pence-exact remainder rule" "the remainder rule" "remainder criterion" "Story 1" '✓')

test_start "control: without an unresolved row the verdict is clean"
assert_equals "0" "$(coverage_rollup_rc --spec "$CLEAN_SPEC" --matrix-dir "$CLEAN_DIR" --verdict)"

# Now add one unresolved row to that same clean run. `FR8 and FR5` names requirements the
# spec does not define, so nothing becomes untraced by adding it — the only thing that
# changes is the presence of a row that resolves to nothing.
DIRTY_MATRIX=$(coverage_fixture_matrix 91-02-coverage-labeldirty "$CLEAN_SPEC" --dir "$CLEAN_DIR" \
  --row "FR8 and FR5" "combined path" "an end-to-end criterion" "Story 5" '✓')

test_start "control: the added row did not make anything untraced"
assert_empty "$(coverage_states_in "$(coverage_rollup_run --spec "$CLEAN_SPEC" --matrix-dir "$CLEAN_DIR")" untraced)"

test_start "an unresolved row alone makes the verdict outstanding"
assert_equals "3" "$(coverage_rollup_rc --spec "$CLEAN_SPEC" --matrix-dir "$CLEAN_DIR" --verdict)"

test_summary
