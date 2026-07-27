#!/bin/bash
# test-coverage-rollup.sh — Tests for cpm/hooks/lib/coverage-rollup.sh (Epic 44-01 Story 3)
#
# One section per acceptance criterion:
#   1. Spec scope emits one record per requirement, sourced only from matrices whose
#      **Source spec** names the spec
#   2. Epic scope emits row-state records and no untraced section
#   3. must NOT include rows from a matrix belonging to a different spec
#   4. Records are tab-separated with a fixed field count per record type
#   5. The script runs with `jq` and `python3` unavailable — grep/awk/sed only
#   6. One output format: no second rendering mode, and none selectable
#
# Every negative control runs the identical code path against a mutated input, and states
# what it would catch. Expected values are derived from the fixtures at run time rather
# than pinned, so editing a fixture cannot leave an assertion quietly asserting the past.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/coverage-fixture-helpers.sh"
. "$SCRIPT_DIR/../lib/coverage-parse.sh"

ROLLUP="$SCRIPT_DIR/../lib/coverage-rollup.sh"
REPO_ROOT="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel 2>/dev/null)"

echo "Testing the coverage roll-up script (Epic 44-01 Story 3)"

# Run the script the way a skill does: with CLAUDE_PROJECT_DIR genuinely unset, which is
# the environment a /cpm:* Bash call actually has (AD5, spec 43's defect). Diagnostics go
# to stderr and are dropped here so only records reach the assertions.
rollup() {
  run_without_env CLAUDE_PROJECT_DIR -- bash "$ROLLUP" "$@" 2>/dev/null
}

# Number of records of one type in a captured run.
count_type() {
  printf '%s\n' "$1" | awk -F'\t' -v t="$2" '$1 == t { n++ } END { print n + 0 }'
}

# --- Fixtures -------------------------------------------------------------------
#
# One directory holds the spec, a second spec, and three matrices. Putting the foreign
# matrix in the *same* --matrix-dir is the point: the must-NOT is about the field, not
# about which directory a file happens to sit in.

FIX_DIR=$(coverage_fixture_dir rollup)

MUST_LABELS="FR1 FR2"
SHOULD_LABELS="FR10"
ALL_LABELS="$MUST_LABELS $SHOULD_LABELS"

spec_args=()
for label in $MUST_LABELS; do
  spec_args+=(--must "$label" "requirement text for $label")
done
for label in $SHOULD_LABELS; do
  spec_args+=(--should "$label" "requirement text for $label")
done

SPEC=$(coverage_fixture_spec 44-spec-rollup --dir "$FIX_DIR" "${spec_args[@]}")
OTHER_SPEC=$(coverage_fixture_spec 45-spec-other --dir "$FIX_DIR" \
  --must FR99 "a requirement belonging to another spec entirely")

# The **Source spec** values name a `docs/specifications/` path while the fixture specs
# live under TEST_TMPDIR. That is deliberate: matching compares basenames, so a caller
# passing the absolute path of the same spec still matches the field as a real matrix
# writes it.
MATRIX_ONE=$(coverage_fixture_matrix 44-01-coverage-alpha "docs/specifications/44-spec-rollup.md" \
  --dir "$FIX_DIR" \
  --row FR1 "requirement text for FR1" "the first criterion" "Story 1" '✓' \
  --row "FR1 (must NOT)" "must NOT do the other thing" "must NOT do the other thing" "Story 1" '' \
  --row "(story-originated)" "—" "a criterion with no requirement behind it" "Story 1" '✓')

MATRIX_TWO=$(coverage_fixture_matrix 44-02-coverage-beta "docs/specifications/44-spec-rollup.md" \
  --dir "$FIX_DIR" \
  --row FR2 "requirement text for FR2" "the second criterion" "Story 2" '')

FOREIGN_MATRIX=$(coverage_fixture_matrix 45-01-coverage-foreign "docs/specifications/45-spec-other.md" \
  --dir "$FIX_DIR" \
  --row FR99 "a requirement belonging to another spec entirely" "the foreign criterion" "Story 1" '✓')

SPEC_OUT=$(rollup --spec "$SPEC" --matrix-dir "$FIX_DIR")

# --- Criterion 1: one record per requirement, from matching matrices only ------------

for label in $ALL_LABELS; do
  test_start "spec scope emits a REQ record for $label"
  assert_contains "$SPEC_OUT" "$(printf 'REQ\t%s\t' "$label")"
done

test_start "the REQ count equals the number of requirements the fixture was given"
EXPECTED_REQS=$(printf '%s\n' $ALL_LABELS | awk 'END { print NR }')
assert_equals "$EXPECTED_REQS" "$(count_type "$SPEC_OUT" REQ)"

test_start "control: a label the spec does not carry gets no REQ record"
assert_not_contains "$SPEC_OUT" "$(printf 'REQ\tFR99\t')"

test_start "both matrices naming the spec are reported"
assert_equals "2" "$(count_type "$SPEC_OUT" MATRIX)"

test_start "each MATRIX record carries the source spec it was matched on"
assert_contains "$SPEC_OUT" "$(printf 'MATRIX\t%s\tdocs/specifications/44-spec-rollup.md' "$MATRIX_ONE")"

test_start "rows from a matching matrix are emitted"
assert_contains "$SPEC_OUT" "$(printf 'ROW\t%s\tFR1\tFR1\tStory 1\tverified' "$MATRIX_ONE")"

test_start "a qualified label is reported under its base requirement"
assert_contains "$SPEC_OUT" "$(printf 'ROW\t%s\tFR1\tFR1 (must NOT)\tStory 1\tunverified' "$MATRIX_ONE")"

test_start "a story-originated row is reported as a CRITERION, not a ROW"
assert_contains "$SPEC_OUT" "$(printf 'CRITERION\t%s\t(story-originated)\tStory 1\tverified' "$MATRIX_ONE")"

test_start "control: that row is not also reported as a ROW"
assert_not_contains "$SPEC_OUT" "$(printf 'ROW\t%s\t\t(story-originated)' "$MATRIX_ONE")"

# An epic doc whose slug begins with "coverage" contains `-coverage-` in its own filename
# — `44-01-epic-coverage-rollup-script.md` is one — and epic docs carry a **Source spec**
# field too. A discovery that tested only for the substring would read that epic as a
# matrix and report its rows a second time. This is that case, constructed.
EPIC_LOOKALIKE="$FIX_DIR/44-03-epic-coverage-lookalike.md"
cat > "$EPIC_LOOKALIKE" <<'FIXTURE'
# Epic: a slug that begins with the word coverage

**Source spec**: docs/specifications/44-spec-rollup.md

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 1 | FR1 | requirement text for FR1 | a row that must not be discovered | Story 9 | — | ✓ |
FIXTURE

LOOKALIKE_OUT=$(rollup --spec "$SPEC" --matrix-dir "$FIX_DIR")

# Assert on the file and on the covered-by cell, both of which the records carry. The
# criterion column does not appear in any record type, so an assertion phrased in terms of
# it would hold no matter what discovery did.
test_start "an epic doc whose slug starts with 'coverage' is not discovered as a matrix"
assert_not_contains "$LOOKALIKE_OUT" "44-03-epic-coverage-lookalike.md"

test_start "and none of its rows reach the output"
assert_not_contains "$LOOKALIKE_OUT" "Story 9"

test_start "control: that same file is read when it is named as a matrix"
LOOKALIKE_MATRIX="$FIX_DIR/44-04-coverage-lookalike.md"
cp "$EPIC_LOOKALIKE" "$LOOKALIKE_MATRIX"
assert_contains "$(rollup --spec "$SPEC" --matrix-dir "$FIX_DIR")" "Story 9"
rm -f "$LOOKALIKE_MATRIX" "$EPIC_LOOKALIKE"

# --- Criterion 3 (must NOT): rows from another spec's matrix --------------------------

# The foreign matrix's row is identified by its label and its file, both of which the
# records carry. An assertion on the criterion *text* would pass whatever the script did,
# since no record type carries that column.
test_start "must NOT emit a row from a matrix belonging to a different spec"
assert_not_contains "$SPEC_OUT" "FR99"

test_start "must NOT report the foreign matrix at all"
assert_not_contains "$SPEC_OUT" "$FOREIGN_MATRIX"

# Without this control an empty result would prove only that the fixture never worked.
test_start "control: the foreign matrix is emitted when its own spec is the scope"
OTHER_OUT=$(rollup --spec "$OTHER_SPEC" --matrix-dir "$FIX_DIR")
assert_contains "$OTHER_OUT" "$(printf 'ROW\t%s\tFR99\tFR99\tStory 1\tverified' "$FOREIGN_MATRIX")"

test_start "control: and the first spec's matrices are then the ones excluded"
assert_not_contains "$OTHER_OUT" "$MATRIX_ONE"

# --- Criterion 2: epic scope reports rows and no untraced section ---------------------

EPIC_PATH="$FIX_DIR/44-01-epic-alpha.md"
EPIC_OUT=$(rollup --epic "$EPIC_PATH")

test_start "epic scope emits the rows of the epic's own matrix"
assert_contains "$EPIC_OUT" "$(printf 'ROW\t%s\tFR1\tFR1\tStory 1\tverified' "$MATRIX_ONE")"

test_start "epic scope emits no REQ records — there is no requirement list to compare against"
assert_equals "0" "$(count_type "$EPIC_OUT" REQ)"

# Untraced detection is Story 4's, and it must never appear here. Asserting on the *set*
# of record types rather than on the absence of one name means a later story that adds a
# derived record type cannot leak it into epic scope unnoticed.
test_start "epic scope emits only MATRIX, ROW and CRITERION records"
UNEXPECTED=$(printf '%s\n' "$EPIC_OUT" |
  awk -F'\t' '$1 != "MATRIX" && $1 != "ROW" && $1 != "CRITERION" { print $1 }' | sort -u)
assert_empty "$UNEXPECTED"

test_start "several epics can be given at once"
TWO_EPIC_OUT=$(rollup --epic "$EPIC_PATH" "$FIX_DIR/44-02-epic-beta.md")
assert_equals "2" "$(count_type "$TWO_EPIC_OUT" MATRIX)"

test_start "--matrix-dir is refused in epic scope rather than silently ignored"
MIXED_RC=0
run_without_env CLAUDE_PROJECT_DIR -- \
  bash "$ROLLUP" --epic "$EPIC_PATH" --matrix-dir "$FIX_DIR" >/dev/null 2>&1 || MIXED_RC=$?
assert_equals "2" "$MIXED_RC"

test_start "an epic whose matrix does not exist fails, naming the file it looked for"
MISSING_ERR=$(run_without_env CLAUDE_PROJECT_DIR -- \
  bash "$ROLLUP" --epic "$FIX_DIR/44-09-epic-absent.md" 2>&1 >/dev/null)
assert_contains "$MISSING_ERR" "44-09-coverage-absent.md"

# --- Criterion 4: tab-separated records with a fixed field count per type -------------

test_start "every record type has a constant field count across the whole run"
ARITY_DRIFT=$(printf '%s\n' "$SPEC_OUT" | awk -F'\t' '
  { if ($1 in seen) { if (seen[$1] != NF) drift[$1] = 1 } else { seen[$1] = NF } }
  END { for (t in drift) print t }
')
assert_empty "$ARITY_DRIFT"

test_start "the field counts are the documented ones"
ARITIES=$(printf '%s\n' "$SPEC_OUT" | awk -F'\t' '{ a[$1] = NF } END {
  n = split("CRITERION MATRIX REQ ROW", order, " ")
  for (i = 1; i <= n; i++) if (order[i] in a) printf "%s=%d ", order[i], a[order[i]]
}')
assert_equals "CRITERION=5 MATRIX=3 REQ=4 ROW=6 " "$ARITIES"

test_start "the separator is a tab and nothing else — no line carries a stray separator"
NON_TAB=$(printf '%s\n' "$SPEC_OUT" | LC_ALL=C grep -c $'\t' || true)
TOTAL_LINES=$(printf '%s\n' "$SPEC_OUT" | awk 'END { print NR }')
assert_equals "$TOTAL_LINES" "$NON_TAB"

test_start "control: a record type absent from the output is absent from the arity list"
assert_not_contains "$ARITIES" "STATE="

# --- Criterion 5: no new dependencies ------------------------------------------------
#
# Shadow `jq`, `python3` and `python` with stubs that refuse to run. If the script reached
# for any of them the run fails — a behavioural test, not a grep of the source for the
# word `jq`, which would pass for a script that shelled out to it by another name.

STUB_DIR="$TEST_TMPDIR/stubs"
mkdir -p "$STUB_DIR"
for tool in jq python python3; do
  printf '#!/bin/sh\necho "%s: not available" >&2\nexit 127\n' "$tool" > "$STUB_DIR/$tool"
  chmod +x "$STUB_DIR/$tool"
done

test_start "control: the stubs really do shadow the real tools"
STUB_RC=0
PATH="$STUB_DIR:$PATH" jq --version >/dev/null 2>&1 || STUB_RC=$?
assert_equals "127" "$STUB_RC"

test_start "the script runs with jq and python unavailable"
STUBBED_OUT=$(PATH="$STUB_DIR:$PATH" rollup --spec "$SPEC" --matrix-dir "$FIX_DIR")
assert_equals "$SPEC_OUT" "$STUBBED_OUT"

# --- Criterion 6: one output format --------------------------------------------------

test_start "output is byte-identical whether the terminal claims colour support or not"
DUMB_OUT=$(TERM=dumb rollup --spec "$SPEC" --matrix-dir "$FIX_DIR")
FANCY_OUT=$(TERM=xterm-256color rollup --spec "$SPEC" --matrix-dir "$FIX_DIR")
assert_equals "$DUMB_OUT" "$FANCY_OUT"

test_start "the output carries no escape sequences"
ESCAPES=$(printf '%s\n' "$SPEC_OUT" | LC_ALL=C grep -c $'\033' || true)
assert_equals "0" "$ESCAPES"

test_start "the output carries no carriage returns"
CRS=$(printf '%s\n' "$SPEC_OUT" | LC_ALL=C grep -c $'\r' || true)
assert_equals "0" "$CRS"

# The strongest available statement of "one format" is that no argument selects another.
test_start "no flag selects a second rendering — --format is rejected"
FORMAT_RC=0
run_without_env CLAUDE_PROJECT_DIR -- \
  bash "$ROLLUP" --spec "$SPEC" --format json >/dev/null 2>&1 || FORMAT_RC=$?
assert_equals "2" "$FORMAT_RC"

test_start "control: the same invocation without that flag succeeds"
OK_RC=0
run_without_env CLAUDE_PROJECT_DIR -- \
  bash "$ROLLUP" --spec "$SPEC" --matrix-dir "$FIX_DIR" >/dev/null 2>&1 || OK_RC=$?
assert_equals "0" "$OK_RC"

# ======================================================================================
# Story 4 — requirement states and untraced detection
# ======================================================================================
#
# One spec, one matrix, five requirements chosen so that every state is reached and the
# partition has something to hold over:
#
#   FR1  two rows, both ✓            → delivered
#   FR2  two rows, one ✓             → in progress
#   FR3  one row, none ✓             → in progress
#   FR4  no rows anywhere            → untraced
#   NFR1 no rows anywhere            → untraced
#   FR9  ruled out under Won't Have  → excluded, and *not* untraced

S4_DIR=$(coverage_fixture_dir states)

S4_SPEC=$(coverage_fixture_spec 46-spec-states --dir "$S4_DIR" \
  --must FR1 "the delivered requirement" \
  --must FR2 "the partly verified requirement" \
  --must FR3 "the wholly unverified requirement" \
  --must FR4 "the requirement no matrix mentions" \
  --wont-labelled FR9 "a requirement ruled out for this iteration" \
  --nfr NFR1 "Read-only.")

S4_MATRIX=$(coverage_fixture_matrix 46-01-coverage-states "docs/specifications/46-spec-states.md" \
  --dir "$S4_DIR" \
  --row FR1 "the delivered requirement" "first half of FR1" "Story 1" '✓' \
  --row "FR1 (must NOT)" "the delivered requirement" "second half of FR1" "Story 1" '✓' \
  --row FR2 "the partly verified requirement" "first half of FR2" "Story 2" '✓' \
  --row FR2 "the partly verified requirement" "second half of FR2" "Story 2" '' \
  --row FR3 "the wholly unverified requirement" "the only FR3 criterion" "Story 3" '' \
  --row "(story-originated)" "—" "a criterion with no requirement behind it" "Story 1" '✓')

S4_OUT=$(rollup --spec "$S4_SPEC" --matrix-dir "$S4_DIR")

# The state of one label, read out of the records.
state_of() {
  printf '%s\n' "$S4_OUT" | awk -F'\t' -v l="$1" '$1 == "STATE" && $2 == l { print $4 }'
}

# --- Criterion 3: three states, derived from row-level ✓, never a proportion -----------

test_start "every row verified reports delivered"
assert_equals "delivered" "$(state_of FR1)"

test_start "a mix of verified and unverified rows reports in progress"
assert_equals "in-progress" "$(state_of FR2)"

test_start "rows present but none verified reports in progress, not delivered"
assert_equals "in-progress" "$(state_of FR3)"

# A qualifier-bearing row counts toward its base requirement, or FR1 would have one
# unverified row it never had.
test_start "a qualified label's row counts toward its base requirement"
assert_contains "$S4_OUT" "$(printf 'ROW\t%s\tFR1\tFR1 (must NOT)' "$S4_MATRIX")"

# Control: flipping one of FR1's two ticks must move it off delivered. Without this, a
# derivation that reported everything as delivered would pass the assertion above.
test_start "control: unticking one of FR1's rows moves it to in progress"
S4_FLIPPED="$S4_DIR/46-02-coverage-flipped.md"
sed 's/| second half of FR1 | Story 1 | — | ✓ |/| second half of FR1 | Story 1 | — | |/' \
  "$S4_MATRIX" > "$S4_FLIPPED"
rm -f "$S4_MATRIX"
FLIPPED_OUT=$(rollup --spec "$S4_SPEC" --matrix-dir "$S4_DIR")
assert_equals "in-progress" "$(printf '%s\n' "$FLIPPED_OUT" | awk -F'\t' '$1 == "STATE" && $2 == "FR1" { print $4 }')"

test_start "control: the mutation really did change one cell and nothing else"
assert_equals "1" "$(diff <(printf '%s\n' "$S4_OUT") <(printf '%s\n' "$FLIPPED_OUT") | grep -c '^< STATE.FR1')"
mv "$S4_FLIPPED" "$S4_MATRIX"

test_start "no state value is a proportion or carries a digit"
assert_empty "$(printf '%s\n' "$S4_OUT" | awk -F'\t' '$1 == "STATE" && $4 ~ /[0-9]/')"

test_start "the state vocabulary is exactly the three the spec names"
STATES_SEEN=$(printf '%s\n' "$S4_OUT" | awk -F'\t' '$1 == "STATE" { print $4 }' | sort -u | tr '\n' ' ')
assert_equals "delivered in-progress untraced " "$STATES_SEEN"

# --- Criterion 1: untraced detection --------------------------------------------------

test_start "a requirement no matrix mentions is reported untraced"
assert_equals "untraced" "$(state_of FR4)"

test_start "a non-functional requirement no matrix mentions is reported untraced"
assert_equals "untraced" "$(state_of NFR1)"

test_start "untraced records are emitted before any other state — FR2 makes them the headline"
FIRST_STATE=$(printf '%s\n' "$S4_OUT" | awk -F'\t' '$1 == "STATE" { print $4; exit }')
assert_equals "untraced" "$FIRST_STATE"

test_start "no untraced record is emitted for a requirement that does have rows"
assert_empty "$(printf '%s\n' "$S4_OUT" |
  awk -F'\t' '$1 == "STATE" && $4 == "untraced" && ($2 == "FR1" || $2 == "FR2" || $2 == "FR3")')"

# A ruled-out requirement will never have a matrix row. Reporting it as untraced would
# report the spec working as intended as though it were a gap.
test_start "a Won't Have requirement is excluded, not reported untraced"
assert_contains "$S4_OUT" "$(printf 'EXCLUDED\tFR9\t')"

test_start "and it appears in no STATE record at all"
assert_empty "$(printf '%s\n' "$S4_OUT" | awk -F'\t' '$1 == "STATE" && $2 == "FR9"')"

test_start "control: it is still reported as a requirement of the spec"
assert_contains "$S4_OUT" "$(printf 'REQ\tFR9\t')"

# --- Criterion 2: traced and untraced account for every requirement -------------------
#
# Asserted as a set difference in both directions, over the records of a single run. Both
# sides come from one enumeration, so the partition holds by construction and this is a
# regression net rather than a restatement of the code.

REQ_LABELS=$(printf '%s\n' "$S4_OUT" | awk -F'\t' '$1 == "REQ" { print $2 }' | sort)
STATE_LABELS=$(printf '%s\n' "$S4_OUT" | awk -F'\t' '$1 == "STATE" || $1 == "EXCLUDED" { print $2 }' | sort)

test_start "every requirement in the spec has a state or an exclusion"
assert_empty "$(comm -23 <(printf '%s\n' "$REQ_LABELS") <(printf '%s\n' "$STATE_LABELS"))"

test_start "and nothing has a state that is not a requirement of the spec"
assert_empty "$(comm -13 <(printf '%s\n' "$REQ_LABELS") <(printf '%s\n' "$STATE_LABELS"))"

test_start "control: the partition is over a non-empty set"
if [ "$(printf '%s\n' "$REQ_LABELS" | grep -c .)" -gt 0 ]; then
  test_pass
else
  test_fail "The partition assertions would hold vacuously over an empty requirement set"
fi

test_start "the summary's counts add up to the requirements it reports"
SUMMARY_LINE=$(printf '%s\n' "$S4_OUT" | awk -F'\t' '$1 == "SUMMARY"')
assert_empty "$(printf '%s\n' "$SUMMARY_LINE" | awk -F'\t' '$3 != $4 + $5 + $6 { print }')"

test_start "the summary's requirement total matches the STATE records emitted"
STATE_COUNT=$(printf '%s\n' "$S4_OUT" | awk -F'\t' '$1 == "STATE" { n++ } END { print n + 0 }')
assert_equals "$STATE_COUNT" "$(printf '%s\n' "$SUMMARY_LINE" | cut -f3)"

# --- Criterion 4: two runs over unchanged inputs emit an identical record set ----------

test_start "control: the two runs are separate invocations that each produced records"
RUN_ONE=$(rollup --spec "$S4_SPEC" --matrix-dir "$S4_DIR")
RUN_TWO=$(rollup --spec "$S4_SPEC" --matrix-dir "$S4_DIR")
if [ -n "$RUN_ONE" ] && [ -n "$RUN_TWO" ]; then
  test_pass
else
  test_fail "Comparing two empty outputs would hold whatever the script did"
fi

test_start "two runs over unchanged inputs are byte-identical"
assert_equals "$RUN_ONE" "$RUN_TWO"

# Without this, "identical" would be satisfied by a script that emitted the same thing
# regardless of its input, and a count flat across ralph iterations would mean nothing.
test_start "control: a run over changed inputs is not identical"
CHANGED=$(coverage_fixture_matrix 46-03-coverage-extra "docs/specifications/46-spec-states.md" \
  --dir "$S4_DIR" \
  --row FR4 "the requirement no matrix mentions" "a criterion that closes the gap" "Story 4" '✓')
RUN_THREE=$(rollup --spec "$S4_SPEC" --matrix-dir "$S4_DIR")
if [ "$RUN_ONE" != "$RUN_THREE" ]; then
  test_pass
else
  test_fail "Adding a matrix that traces FR4 left the output unchanged"
fi

test_start "and the requirement that gained a verified row is no longer untraced"
assert_equals "delivered" "$(printf '%s\n' "$RUN_THREE" | awk -F'\t' '$1 == "STATE" && $2 == "FR4" { print $4 }')"
rm -f "$CHANGED"

# --- Epic scope carries none of it ----------------------------------------------------

test_start "epic scope emits no STATE, EXCLUDED or SUMMARY records"
S4_EPIC_OUT=$(rollup --epic "$S4_DIR/46-01-epic-states.md")
assert_empty "$(printf '%s\n' "$S4_EPIC_OUT" |
  awk -F'\t' '$1 == "STATE" || $1 == "EXCLUDED" || $1 == "SUMMARY" { print $1 }')"

test_start "control: it did emit rows, so the assertion above is not vacuous"
assert_contains "$S4_EPIC_OUT" "$(printf 'ROW\t%s\tFR1' "$S4_MATRIX")"

# ======================================================================================
# Story 5 — fail closed on every incomplete computation
# ======================================================================================
#
# Each case is asserted twice over: the exit status is non-zero, *and* the message names
# the file that could not be read. A predicate that fails silently is indistinguishable
# from one that passed, so a non-zero exit with an unhelpful message only half-satisfies
# the criteria.

S5_DIR=$(coverage_fixture_dir failclosed)

# Run one invocation, leaving its status in S5_RC and its stderr in S5_ERR. Both are set
# in the caller's shell rather than printed: a `$(...)` wrapper would run this in a
# subshell, and the message — half of what each criterion asks for — would be lost with it.
S5_RC=0
S5_ERR=""
run_rollup() {
  S5_RC=0
  S5_ERR=$(run_without_env CLAUDE_PROJECT_DIR -- bash "$ROLLUP" "$@" 2>&1 >/dev/null) || S5_RC=$?
}

test_start "a missing spec exits non-zero"
run_rollup --spec "$S5_DIR/99-spec-absent.md" --matrix-dir "$S5_DIR"
if [ "$S5_RC" != "0" ]; then test_pass; else test_fail "Expected non-zero, got $S5_RC"; fi

test_start "and the message names the spec it could not read"
assert_contains "$S5_ERR" "99-spec-absent.md"

# A spec exists and matrices exist, but none of them names it. Nothing is untraced because
# nothing was compared — the complete-by-default result the spec is written against.
S5_SPEC=$(coverage_fixture_spec 47-spec-failclosed --dir "$S5_DIR" \
  --must FR1 "the only requirement")
S5_FOREIGN=$(coverage_fixture_matrix 48-01-coverage-elsewhere "docs/specifications/48-spec-elsewhere.md" \
  --dir "$S5_DIR" \
  --row FR1 "a requirement of some other spec" "a criterion" "Story 1" '✓')

test_start "zero matrices naming the spec exits non-zero"
run_rollup --spec "$S5_SPEC" --matrix-dir "$S5_DIR"
if [ "$S5_RC" != "0" ]; then test_pass; else test_fail "Expected non-zero, got $S5_RC"; fi

test_start "and the message names the spec nothing pointed at"
assert_contains "$S5_ERR" "47-spec-failclosed.md"

# Control: the identical invocation succeeds once a matrix names the spec, so the failure
# above is attributable to the discovery result and not to the fixture being broken.
test_start "control: it exits zero once a matrix does name the spec"
S5_MATRIX=$(coverage_fixture_matrix 47-01-coverage-failclosed "docs/specifications/47-spec-failclosed.md" \
  --dir "$S5_DIR" \
  --row FR1 "the only requirement" "a criterion" "Story 1" '✓')
run_rollup --spec "$S5_SPEC" --matrix-dir "$S5_DIR"
assert_equals "0" "$S5_RC"

test_start "an unreadable matrix exits non-zero"
chmod 000 "$S5_MATRIX"
run_rollup --spec "$S5_SPEC" --matrix-dir "$S5_DIR"
if [ "$S5_RC" != "0" ]; then test_pass; else test_fail "Expected non-zero, got $S5_RC"; fi

test_start "and the message names the matrix it could not read"
assert_contains "$S5_ERR" "47-01-coverage-failclosed.md"
chmod 644 "$S5_MATRIX"

test_start "control: readable again, the same invocation succeeds"
run_rollup --spec "$S5_SPEC" --matrix-dir "$S5_DIR"
assert_equals "0" "$S5_RC"

# A spec with matrices but no requirement bullets is the same false-clean shape: nothing
# untraced because nothing was compared.
test_start "a spec yielding no requirements exits non-zero"
S5_EMPTY=$(coverage_fixture_spec 49-spec-empty --dir "$S5_DIR")
cp "$S5_MATRIX" "$S5_DIR/49-01-coverage-empty.md"
sed -i.bak 's|47-spec-failclosed.md|49-spec-empty.md|' "$S5_DIR/49-01-coverage-empty.md"
rm -f "$S5_DIR/49-01-coverage-empty.md.bak"
run_rollup --spec "$S5_EMPTY" --matrix-dir "$S5_DIR"
if [ "$S5_RC" != "0" ]; then test_pass; else test_fail "Expected non-zero, got $S5_RC"; fi

test_start "and the message names the spec whose requirements it could not find"
assert_contains "$S5_ERR" "49-spec-empty.md"

test_start "a matrix directory that does not exist exits non-zero, naming it"
run_rollup --spec "$S5_SPEC" --matrix-dir "$S5_DIR/no-such-directory"
if [ "$S5_RC" != "0" ]; then test_pass; else test_fail "Expected non-zero, got $S5_RC"; fi

test_start "and names the directory"
assert_contains "$S5_ERR" "no-such-directory"

test_start "an epic whose matrix is unreadable exits non-zero, naming the matrix"
chmod 000 "$S5_MATRIX"
run_rollup --epic "$S5_DIR/47-01-epic-failclosed.md"
if [ "$S5_RC" != "0" ]; then test_pass; else test_fail "Expected non-zero, got $S5_RC"; fi

test_start "and epic scope's message names the matrix too"
assert_contains "$S5_ERR" "47-01-coverage-failclosed.md"
chmod 644 "$S5_MATRIX"

# --- must NOT exit zero on any path where the computation did not complete -------------
#
# Enumerated in one place so the must-NOT is checked over the whole set of failure shapes
# rather than one at a time, and so a path added later without an exit is visible as a gap
# here rather than in production.

test_start "must NOT exit zero on any failing path"
chmod 000 "$S5_MATRIX"
ZERO_EXITS=""
for case_args in \
  "--spec|$S5_DIR/99-spec-absent.md|--matrix-dir|$S5_DIR" \
  "--spec|$S5_EMPTY|--matrix-dir|$S5_DIR" \
  "--spec|$S5_SPEC|--matrix-dir|$S5_DIR" \
  "--spec|$S5_SPEC|--matrix-dir|$S5_DIR/no-such-directory" \
  "--epic|$S5_DIR/47-01-epic-failclosed.md" \
  "--epic|$S5_DIR/99-01-epic-absent.md" \
  "--spec" \
  "--bogus"
do
  OLD_IFS="$IFS"; IFS='|'
  # shellcheck disable=SC2086
  set -- $case_args
  IFS="$OLD_IFS"
  run_rollup "$@"
  if [ "$S5_RC" = "0" ]; then
    ZERO_EXITS="$ZERO_EXITS $case_args"
  fi
done
assert_empty "$ZERO_EXITS"
chmod 644 "$S5_MATRIX"

# Control: the same runner over a working invocation must report the zero, or the
# assertion above would hold for a harness that never ran anything.
test_start "control: the runner does report a zero exit when there is one"
run_rollup --spec "$S5_SPEC" --matrix-dir "$S5_DIR"
assert_equals "0" "$S5_RC"

test_start "every failure path writes its diagnostic to stderr, not stdout"
STDOUT_ON_FAILURE=$(run_without_env CLAUDE_PROJECT_DIR -- \
  bash "$ROLLUP" --spec "$S5_DIR/99-spec-absent.md" --matrix-dir "$S5_DIR" 2>/dev/null)
assert_empty "$STDOUT_ON_FAILURE"

# ======================================================================================
# Story 6 — the read-only guarantee and the input invariants
# ======================================================================================
#
# These run against the repository's own documents, not fixtures. Both are assertions
# about the real inputs the script trusts, and a fixture cannot stand in for either: a
# constructed matrix says nothing about whether the twenty present ones point at specs
# that exist, and a constructed directory says nothing about whether a run over the real
# tree left it alone.

test_start "the repository root resolves, so the assertions below have a subject"
if [ -n "$REPO_ROOT" ] && [ -d "$REPO_ROOT/docs/epics" ]; then
  test_pass
else
  test_fail "Could not resolve a repository root with docs/epics from $SCRIPT_DIR"
fi

# --- Task 6.1: NFR1, read-only ---------------------------------------------------------
#
# `git status` reporting no change is satisfied equally by a correct script and by one
# that never ran, so the run's output is asserted in the same breath. Content checksums go
# further than `git status`: they would catch a rewrite that happened to restore the same
# tracked/untracked classification.

docs_checksums() {
  find "$REPO_ROOT/docs/specifications" "$REPO_ROOT/docs/epics" -type f -name '*.md' \
    | LC_ALL=C sort | while IFS= read -r f; do cksum "$f"; done
}

BEFORE_STATUS=$(cd "$REPO_ROOT" && git status --porcelain)
BEFORE_SUMS=$(docs_checksums)

REAL_OUT=$(rollup --spec "$REPO_ROOT/docs/specifications/44-spec-coverage-rollup.md")
REAL_EPIC_OUT=$(rollup --epic "$REPO_ROOT/docs/epics/44-01-epic-coverage-rollup-script.md")

AFTER_STATUS=$(cd "$REPO_ROOT" && git status --porcelain)
AFTER_SUMS=$(docs_checksums)

test_start "the run over the real repository produced records"
if [ -n "$REAL_OUT" ] && [ -n "$REAL_EPIC_OUT" ]; then
  test_pass
else
  test_fail "A script that never ran would satisfy every read-only assertion below"
fi

test_start "git status reports exactly what it reported before the run"
assert_equals "$BEFORE_STATUS" "$AFTER_STATUS"

test_start "every spec and matrix is byte-identical after the run"
assert_equals "$BEFORE_SUMS" "$AFTER_SUMS"

test_start "control: the checksum snapshot does detect a changed file"
CANARY="$TEST_TMPDIR/canary.md"
printf 'one\n' > "$CANARY"
CANARY_BEFORE=$(cksum "$CANARY")
printf 'two\n' > "$CANARY"
if [ "$CANARY_BEFORE" != "$(cksum "$CANARY")" ]; then
  test_pass
else
  test_fail "cksum reported no change across a rewritten file"
fi

test_start "the failing paths are read-only too"
rollup --spec "$REPO_ROOT/docs/specifications/no-such-spec.md" >/dev/null 2>&1
assert_equals "$BEFORE_SUMS" "$(docs_checksums)"

# --- Task 6.2: every present matrix's **Source spec** resolves to a file that exists ----
#
# The script trusts this field for discovery (AD2). If one named a file that does not
# exist, spec scope would silently never match it and the matrix's rows would vanish from
# every roll-up — a false clean with nothing to point at.

# The check itself, over any directory — so the controls below run the identical code path
# against a directory built to fail it, rather than a re-typed copy of the predicate.
# Emits one finding per problem matrix; silence is a clean directory.
source_spec_findings() {
  local dir="$1" f src
  for f in "$dir"/*.md; do
    [ -f "$f" ] || continue
    coverage_is_matrix_name "${f##*/}" || continue
    src=$(coverage_matrix_source_spec "$f")
    if [ -z "$src" ]; then
      printf 'no-field\t%s\n' "$f"
    elif [ ! -f "$REPO_ROOT/$src" ] && [ ! -f "$src" ]; then
      printf 'unresolved\t%s\t%s\n' "$f" "$src"
    fi
  done
}

# Matrices the name test finds, listed separately so "no findings" can be told apart from
# "nothing was examined".
matrix_names_in() {
  local dir="$1" f
  for f in "$dir"/*.md; do
    [ -f "$f" ] || continue
    coverage_is_matrix_name "${f##*/}" || continue
    printf '%s\n' "$f"
  done
}

REAL_MATRICES=$(matrix_names_in "$REPO_ROOT/docs/epics")
REAL_FINDINGS=$(source_spec_findings "$REPO_ROOT/docs/epics")

test_start "the repository has coverage matrices to check"
if [ "$(printf '%s\n' "$REAL_MATRICES" | grep -c .)" -gt 0 ]; then
  test_pass
else
  test_fail "Found no coverage matrices under $REPO_ROOT/docs/epics"
fi

test_start "every present matrix carries a **Source spec** field"
assert_empty "$(printf '%s\n' "$REAL_FINDINGS" | awk -F'\t' '$1 == "no-field" { print $2 }')"

test_start "every present matrix's **Source spec** resolves to a file that exists"
assert_empty "$(printf '%s\n' "$REAL_FINDINGS" | awk -F'\t' '$1 == "unresolved" { print $2 " -> " $3 }')"

# Controls: the same function, over a directory holding one matrix that names a spec which
# does not exist, one with no field at all, and one that is fine. Without these, both
# assertions above would hold for a check that examined nothing.
S6_DIR=$(coverage_fixture_dir invariants)
coverage_fixture_matrix 50-01-coverage-broken "docs/specifications/50-spec-does-not-exist.md" \
  --dir "$S6_DIR" --row FR1 "a requirement" "a criterion" "Story 1" '✓' >/dev/null
coverage_fixture_matrix 51-01-coverage-fine "docs/specifications/44-spec-coverage-rollup.md" \
  --dir "$S6_DIR" --row FR1 "a requirement" "a criterion" "Story 1" '✓' >/dev/null
printf '# Matrix with no source spec field\n\n| # |\n' > "$S6_DIR/52-01-coverage-fieldless.md"

S6_FINDINGS=$(source_spec_findings "$S6_DIR")

test_start "control: the check detects a source spec that resolves to nothing"
assert_contains "$S6_FINDINGS" "$(printf 'unresolved\t%s/50-01-coverage-broken.md' "$S6_DIR")"

test_start "control: the check detects a matrix carrying no **Source spec** at all"
assert_contains "$S6_FINDINGS" "$(printf 'no-field\t%s/52-01-coverage-fieldless.md' "$S6_DIR")"

test_start "control: and it does not flag the matrix whose source spec exists"
assert_not_contains "$S6_FINDINGS" "51-01-coverage-fine.md"

# The subject is *position*, not presence. This assertion used to read
# `grep -- '-epic-'` over the whole name, which is a proxy for "this is an epic doc" that
# held only because no epic had ever been about epics. `45-01-coverage-autonomous-epic-
# generation.md` is a legitimate matrix whose *slug* contains `-epic-`, and it turned the
# proxy red while `coverage_is_matrix_name` classified it — and its epic doc — correctly.
# What the name test actually guarantees is that the segment after `{parent}-{seq}-` is
# `coverage-`, so that is what is asserted.
test_start "the name test admits no epic doc — checked by position, not by substring"
assert_empty "$(printf '%s\n' "$REAL_MATRICES" |
  sed 's|.*/||' |
  grep -E '^[0-9]+(-[0-9]+)?-epic-' || true)"

# Without this, the assertion above is satisfied by a name test that finds nothing at all,
# and by one that finds everything except the shape it is supposed to exclude.
test_start "control: an epic doc's own name is rejected by the name test"
if coverage_is_matrix_name "45-01-epic-autonomous-epic-generation.md"; then
  test_fail "an epic doc whose slug contains -epic- was classified as a matrix"
else
  test_pass
fi

test_start "control: and the matrix beside it is accepted"
if coverage_is_matrix_name "45-01-coverage-autonomous-epic-generation.md"; then
  test_pass
else
  test_fail "a matrix whose slug contains -epic- was rejected"
fi

# --- `--verdict` (Epic 44-03 Story 1, Task 1.4) -----------------------------------
#
# AD4 puts the delivery verdict in the script so that `cpm:ralph` relays it rather than
# deriving it. The flag is opt-in: `cpm:status` asks "did this compute?" and `cpm:ralph`
# asks "is this done?", and overloading one exit code with both answers is how a read
# failure becomes indistinguishable from an honest report of incomplete work.
#
# The load-bearing assertion in this section is the byte-identity one. Everything else here
# is about the exit code, and an exit code is a cheap thing to get right while silently
# changing the output that a reader and a consumer both depend on.

# Run and capture the status. `run_without_env` is used exactly as `rollup()` does, so the
# only difference between these runs and the ones above is the flag under test.
V_RC=0
V_OUT=""
run_verdict() {
  V_RC=0
  V_OUT=$(run_without_env CLAUDE_PROJECT_DIR -- bash "$ROLLUP" "$@" 2>/dev/null) || V_RC=$?
}

# One directory, three epics: everything verified, nothing verified, and a spec whose
# requirement no matrix mentions. Built rather than found — the repository has no epic that
# is guaranteed to stay half-verified, and pinning one would make this section a test of
# whatever was in flight the day it was written (retro 19).
V_DIR=$(coverage_fixture_dir verdict)

V_SPEC=$(coverage_fixture_spec 70-spec-verdict --dir "$V_DIR" \
  --must FR1 "a requirement with a verified row" \
  --must FR2 "a requirement no matrix mentions" \
  --wont-labelled FR3 "a requirement ruled out for this iteration")

coverage_fixture_matrix 70-01-coverage-done "docs/specifications/70-spec-verdict.md" \
  --dir "$V_DIR" \
  --epic "$V_DIR/70-01-epic-done.md" \
  --row FR1 "a requirement with a verified row" "the FR1 criterion" "Story 1" '✓' >/dev/null

coverage_fixture_matrix 70-02-coverage-partial "docs/specifications/70-spec-verdict.md" \
  --dir "$V_DIR" \
  --epic "$V_DIR/70-02-epic-partial.md" \
  --row FR1 "a requirement with a verified row" "a second FR1 criterion" "Story 2" '' >/dev/null

coverage_fixture_matrix 70-03-coverage-story "docs/specifications/70-spec-verdict.md" \
  --dir "$V_DIR" \
  --epic "$V_DIR/70-03-epic-story.md" \
  --row "(story-originated)" "—" "a criterion with no requirement behind it" "Story 3" '' >/dev/null

# The epic-mode calls address the epic path, which the script maps to the matrix beside it.
: > "$V_DIR/70-01-epic-done.md"
: > "$V_DIR/70-02-epic-partial.md"
: > "$V_DIR/70-03-epic-story.md"

test_start "epic scope: every row verified exits 0"
run_verdict --epic "$V_DIR/70-01-epic-done.md" --verdict
assert_equals "0" "$V_RC"

test_start "epic scope: an unverified row exits 3, not 1"
run_verdict --epic "$V_DIR/70-02-epic-partial.md" --verdict
assert_equals "3" "$V_RC"

# A story-originated criterion never reaches a STATE record, so a verdict built only from
# requirement states would call this matrix complete. It is unverified work sitting in a
# matrix the promise just read.
test_start "epic scope: an unverified story-originated criterion also exits 3"
run_verdict --epic "$V_DIR/70-03-epic-story.md" --verdict
assert_equals "3" "$V_RC"

test_start "epic scope: one outstanding epic among several exits 3"
run_verdict --epic "$V_DIR/70-01-epic-done.md" "$V_DIR/70-02-epic-partial.md" --verdict
assert_equals "3" "$V_RC"

# Isolated deliberately: every row in this directory is verified, so the only thing that can
# produce a 3 is the untraced requirement. Run against `$V_DIR` — which also holds unverified
# rows — the same assertion passed with the untraced check removed from the script entirely,
# because the unverified rows were producing the 3 on their own.
U_DIR=$(coverage_fixture_dir verdict-untraced)
U_SPEC=$(coverage_fixture_spec 72-spec-untraced --dir "$U_DIR" \
  --must FR1 "a requirement with a verified row" \
  --must FR2 "a requirement no matrix mentions")
coverage_fixture_matrix 72-01-coverage-done "docs/specifications/72-spec-untraced.md" \
  --dir "$U_DIR" \
  --row FR1 "a requirement with a verified row" "the FR1 criterion" "Story 1" '✓' >/dev/null

test_start "spec scope: an untraced requirement exits 3 with every row verified"
run_verdict --spec "$U_SPEC" --matrix-dir "$U_DIR" --verdict
assert_equals "3" "$V_RC"

test_start "control: every row in that directory really is verified"
run_verdict --spec "$U_SPEC" --matrix-dir "$U_DIR"
assert_empty "$(printf '%s\n' "$V_OUT" | awk -F'\t' '$1 == "ROW" && $6 != "verified"')"

test_start "control: and the untraced requirement is reported as such"
assert_contains "$V_OUT" "$(printf 'STATE\tFR2\tMust Have\tuntraced')"

test_start "spec scope: an untraced requirement alongside unverified rows also exits 3"
run_verdict --spec "$V_SPEC" --matrix-dir "$V_DIR" --verdict
assert_equals "3" "$V_RC"

# A Won't Have requirement will never have a matrix row. Counting it as outstanding would
# mean a spec that deliberately ruled something out could never reach a passing verdict —
# `cpm:ralph` would then be unable to promise on any spec with a Won't Have section, which
# is most of them. It is reported as `EXCLUDED`, never as untraced, and must not count.
W_DIR=$(coverage_fixture_dir verdict-wont)
W_SPEC=$(coverage_fixture_spec 71-spec-excluded --dir "$W_DIR" \
  --must FR1 "a requirement with a verified row" \
  --wont-labelled FR9 "a requirement ruled out for this iteration")
coverage_fixture_matrix 71-01-coverage-done "docs/specifications/71-spec-excluded.md" \
  --dir "$W_DIR" \
  --row FR1 "a requirement with a verified row" "the FR1 criterion" "Story 1" '✓' >/dev/null

test_start "spec scope: a Won't Have requirement does not make the verdict outstanding"
run_verdict --spec "$W_SPEC" --matrix-dir "$W_DIR" --verdict
assert_equals "0" "$V_RC"

test_start "control: that spec really does carry an excluded requirement"
run_verdict --spec "$W_SPEC" --matrix-dir "$W_DIR"
assert_contains "$V_OUT" "$(printf 'EXCLUDED\tFR9')"

# The verdict must not swallow a read failure. Reporting "work outstanding" when the truth
# is "the check never ran" is the confusion the third code exists to prevent.
test_start "a read failure keeps exit 1 under --verdict"
run_verdict --epic "$V_DIR/70-99-epic-absent.md" --verdict
assert_equals "1" "$V_RC"

test_start "a usage error keeps exit 2 under --verdict"
run_verdict --verdict
assert_equals "2" "$V_RC"

# NFR4 across the flag: `--verdict` changes the exit code and nothing else. If it altered,
# reordered or suppressed a record, every consumer of the default path would be reading a
# different document from the one the verdict was computed over.
#
# Compared over the **spec-scope** run, which emits every record type — MATRIX, REQ, STATE,
# SUMMARY, ROW and CRITERION. An earlier version compared an epic-scope run carrying no
# CRITERION records, and a deliberately introduced `grep -v CRITERION` on the `--verdict`
# path passed it: byte-identity over a subset of the format is not byte-identity.
test_start "--verdict emits byte-identical output to the same run without it"
run_verdict --spec "$V_SPEC" --matrix-dir "$V_DIR" --verdict
V_WITH="$V_OUT"
run_verdict --spec "$V_SPEC" --matrix-dir "$V_DIR"
assert_equals "$V_OUT" "$V_WITH"

test_start "control: the compared output carries every record type the format defines"
V_TYPES=$(printf '%s\n' "$V_WITH" | awk -F'\t' '{ print $1 }' | sort -u | tr '\n' ' ')
assert_equals "CRITERION EXCLUDED MATRIX REQ ROW STATE SUMMARY " "$V_TYPES"

# The default path is the contract epic 44-01 shipped and `cpm:status` reads. Asserted
# directly rather than left to the suite above, so that "adding --verdict moved nothing"
# is a claim this section makes rather than one inferred from other tests passing.
test_start "without --verdict, an outstanding epic still exits 0"
run_verdict --epic "$V_DIR/70-02-epic-partial.md"
assert_equals "0" "$V_RC"

test_start "without --verdict, an untraced requirement still exits 0"
run_verdict --spec "$V_SPEC" --matrix-dir "$V_DIR"
assert_equals "0" "$V_RC"

# --- The fourth `--verdict` code (Epic 45-03 Story 1, spec 45 FR7 / AD2) -------------------
#
# In spec mode `cpm:ralph` starts with no epics at all, and that is iteration 1 rather than a
# failure. Today it is exit 1 — the same code as a genuine read failure — so the loop cannot
# tell "phase one hasn't run yet" from "stop, the check is broken". AD2 gives the first case
# its own code, on the `--verdict` path only.
#
# The wrong edits this section is written against, named before the assertions were chosen
# (retro 26): the new code leaking onto the default path, where `cpm:status` reads it; and the
# new code absorbing the read failure, which would trade one conflation for another.

# A readable spec that no matrix names, in a directory that is *not* empty — the other matrix
# names a different spec. An empty directory would leave "zero matrices name it" and "nothing
# to read" indistinguishable, which is the distinction under test.
N_DIR=$(coverage_fixture_dir verdict-no-matrix)

N_SPEC=$(coverage_fixture_spec 71-spec-no-matrix --dir "$N_DIR" \
  --must FR1 "a requirement in a spec no matrix names")

coverage_fixture_matrix 71-01-coverage-other "docs/specifications/70-spec-verdict.md" \
  --dir "$N_DIR" \
  --epic "$N_DIR/71-01-epic-other.md" \
  --row FR1 "a requirement with a verified row" "the FR1 criterion" "Story 1" '✓' >/dev/null
: > "$N_DIR/71-01-epic-other.md"

test_start "control: the fixture spec is readable"
if [ -r "$N_SPEC" ]; then
  test_pass
else
  test_fail "$N_SPEC is not readable — every assertion below would be testing a read failure"
fi

test_start "control: the matrix directory is not empty, and its matrix names another spec"
assert_contains "$(cat "$N_DIR/71-01-coverage-other.md")" "70-spec-verdict.md"

# The four codes this script can already return, measured rather than assumed, so "distinct"
# below is a comparison against what the program does and not against literals in this file.
run_verdict --spec "$W_SPEC" --matrix-dir "$W_DIR" --verdict
RC_DELIVERED_RUN="$V_RC"
run_verdict --spec "$V_SPEC" --matrix-dir "$V_DIR" --verdict
RC_OUTSTANDING_RUN="$V_RC"
run_verdict --spec "$N_DIR/71-99-spec-absent.md" --matrix-dir "$N_DIR" --verdict
RC_UNREADABLE="$V_RC"
run_verdict --verdict
RC_USAGE="$V_RC"

run_verdict --spec "$N_SPEC" --matrix-dir "$N_DIR" --verdict
RC_NO_MATRIX="$V_RC"

test_start "--verdict returns a code of its own when the spec is readable and no matrix names it"
if [ "$RC_NO_MATRIX" != "$RC_UNREADABLE" ] &&
   [ "$RC_NO_MATRIX" != "$RC_USAGE" ] &&
   [ "$RC_NO_MATRIX" != "$RC_DELIVERED_RUN" ] &&
   [ "$RC_NO_MATRIX" != "$RC_OUTSTANDING_RUN" ]; then
  test_pass
else
  test_fail "no-matrix returned $RC_NO_MATRIX; delivered=$RC_DELIVERED_RUN outstanding=$RC_OUTSTANDING_RUN unreadable=$RC_UNREADABLE usage=$RC_USAGE"
fi

test_start "control: the four codes it is compared against are themselves four distinct values"
if [ "$(printf '%s\n%s\n%s\n%s\n' "$RC_DELIVERED_RUN" "$RC_OUTSTANDING_RUN" "$RC_UNREADABLE" "$RC_USAGE" | sort -u | grep -c .)" = "4" ]; then
  test_pass
else
  test_fail "delivered=$RC_DELIVERED_RUN outstanding=$RC_OUTSTANDING_RUN unreadable=$RC_UNREADABLE usage=$RC_USAGE — the distinctness check compares against fewer values than it names"
fi

# The read failure keeps its own code. Without this the new code could simply have absorbed
# the old one, which reads as a fix and is the same conflation pointing the other way.
test_start "an unreadable spec still returns the read-failure code under --verdict"
assert_equals "1" "$RC_UNREADABLE"

# Containment: the default path is what `cpm:status` reads, and AD2 confines the change to
# `--verdict`. The same fixture, one flag apart.
test_start "without --verdict, the no-matrix case still exits 1 as it did before"
run_verdict --spec "$N_SPEC" --matrix-dir "$N_DIR"
assert_equals "1" "$V_RC"

test_start "so the new code appears on the --verdict path and nowhere else"
if [ "$RC_NO_MATRIX" != "$V_RC" ]; then
  test_pass
else
  test_fail "both paths returned $V_RC — the change is not confined to --verdict"
fi

# Output is unchanged either way: AD2 changes an exit code, and NFR4's one-output-format rule
# holds across this flag as it does across the others.
test_start "the diagnostic still names the directory and the spec it looked for"
N_ERR=$(run_without_env CLAUDE_PROJECT_DIR -- bash "$ROLLUP" --spec "$N_SPEC" --matrix-dir "$N_DIR" --verdict 2>&1 >/dev/null || true)
assert_contains "$N_ERR" "no matrix in $N_DIR names 71-spec-no-matrix.md as its source spec"

test_start "and the no-matrix run emits no records on stdout"
run_verdict --spec "$N_SPEC" --matrix-dir "$N_DIR" --verdict
assert_empty "$V_OUT"

# The script's usage text describes its own exit codes, which makes it a document describing
# a program — and retro 24's finding is that asserting the two halves separately never
# asserts that they agree. A code added without being documented, or documented without ever
# being returned, is invisible to every assertion above. Both sets are gathered from runs:
# the documented one by running the script with no arguments, the measured one from the five
# runs above.
USAGE_TEXT=$(run_without_env CLAUDE_PROJECT_DIR -- bash "$ROLLUP" 2>&1 >/dev/null || true)
DOCUMENTED_CODES=$(printf '%s\n' "$USAGE_TEXT" |
  sed -n '/^--verdict changes only the exit code/,/usage error\./p' |
  grep -oE '(^|[^0-9])[0-9]([^0-9]|$)' | grep -oE '[0-9]' | sort -u | tr '\n' ' ')
MEASURED_CODES=$(printf '%s\n%s\n%s\n%s\n%s\n' \
  "$RC_DELIVERED_RUN" "$RC_OUTSTANDING_RUN" "$RC_NO_MATRIX" "$RC_UNREADABLE" "$RC_USAGE" |
  sort -u | tr '\n' ' ')

test_start "control: the usage text names a code set at all"
if [ "$(printf '%s' "$DOCUMENTED_CODES" | wc -w | tr -d ' ')" = "5" ]; then
  test_pass
else
  test_fail "extracted '$DOCUMENTED_CODES' from the usage text — expected five codes"
fi

test_start "the exit codes the usage text documents are the codes the script returns"
assert_equals "$DOCUMENTED_CODES" "$MEASURED_CODES"

test_start "control: a documented code the script never returns is detected"
FAKE_DOCUMENTED=$(printf '%s\n5\n' "$DOCUMENTED_CODES" | tr ' ' '\n' | grep -E '.' | sort -u | tr '\n' ' ')
if [ "$FAKE_DOCUMENTED" = "$MEASURED_CODES" ]; then
  test_fail "adding a sixth documented code left the two sets equal"
else
  test_pass
fi

# The script states its exit codes twice — in the header comment a maintainer reads and in
# the usage text a caller sees — and the assertion above defends only the second. Two copies
# that are each individually correct is the shape retro 26 flagged: nothing here would notice
# the header keeping three codes after the usage text grew a fourth.
header_codes() {
  sed -n '/^# With `--verdict`/,/^#   2  usage error$/p' "$1" |
    sed -n 's/^#   \([0-9]\)  .*/\1/p' | sort -u | tr '\n' ' '
}
HEADER_CODES=$(header_codes "$ROLLUP")

test_start "control: the header comment names a code set at all"
if [ "$(printf '%s' "$HEADER_CODES" | wc -w | tr -d ' ')" = "5" ]; then
  test_pass
else
  test_fail "extracted '$HEADER_CODES' from the header comment — expected five codes"
fi

test_start "the header comment documents the same codes the script returns"
assert_equals "$HEADER_CODES" "$MEASURED_CODES"

test_start "control: a code dropped from the header alone is detected"
STALE_HEADER="$TEST_TMPDIR/stale-header-rollup.sh"
grep -v '^#   4  the spec was readable' "$ROLLUP" > "$STALE_HEADER"
if [ "$(header_codes "$STALE_HEADER")" = "$MEASURED_CODES" ]; then
  test_fail "removing code 4 from the header left it agreeing with the measured set"
else
  test_pass
fi

test_summary
