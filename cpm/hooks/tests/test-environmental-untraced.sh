#!/bin/bash
# test-environmental-untraced.sh — Epic 46-01 Story 2: environmental constraints enter
# the untraced count.
#
# Asserts the four [integration] acceptance criteria of "Environmental constraints enter
# the untraced count". Nothing under test was written for this story: spec 46's AD1 chose
# the `## Non-Functional Requirements` heading precisely *because* an `ENVn` label already
# parses, already emits a REQ record, and already holds the untraced count above zero.
#
# --- What a green run here does and does not mean --------------------------------
#
# Retro 23. Mechanically these are oracles -- they run coverage-rollup.sh over a built
# fixture and compare against expectations derived from the fixture's own label lists, so
# a parser that stopped counting ENV labels fails them. But as *evidence for this story*
# they are a regression net, not proof that anything was delivered: the property held
# before a line of epic 46-01 was written. What changes today is that it is under test.
# AD1 rests on it, Story 3's guard is only meaningful while it holds, and until now
# nothing in the repository would have noticed it breaking.
#
# If a run of this suite had found the property did *not* hold, the answer was an
# implementation task raised from the evidence -- not one written into the epic ahead of
# it. It held.
#
# --- Why two fixtures rather than one --------------------------------------------
#
# COVERED is the whole non-vacuity argument. Every assertion about UNCOVERED's untraced
# count would pass just as well against a roll-up that reported everything untraced
# always, or against a --matrix-dir it failed to read. COVERED runs the identical code
# path over the identical labels with the matrix rows filled in, and the counts have to
# move. Retro 21's shape: the negative control shares everything with the positive except
# the one thing under test.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/coverage-fixture-helpers.sh"
. "$SCRIPT_DIR/../lib/coverage-parse.sh"

echo "Testing environmental constraints in the untraced count (Epic 46-01 Story 2)"

# coverage_rollup_run, coverage_rollup_rc and coverage_count_type come from
# coverage-fixture-helpers.sh. They are called by their library names here rather than
# aliased to something shorter: the name is where a reader finds the CLAUDE_PROJECT_DIR
# contract they carry.

# One field of the SUMMARY record, by position. Field 1 is the record type.
summary_field() {
  printf '%s\n' "$1" | awk -F'\t' -v i="$2" '$1 == "SUMMARY" { print $i; exit }'
}

summary_arity() {
  printf '%s\n' "$1" | awk -F'\t' '$1 == "SUMMARY" { print NF; exit }'
}

# --- Fixtures ---------------------------------------------------------------------
#
# Four requirements in two groups. TRACED_LABELS are covered by a matrix row in both
# runs; ENV_LABELS are covered in COVERED and by nothing at all in UNCOVERED. Every
# expected count below is derived by counting these lists, so adding a label to either
# cannot leave a stale literal passing somewhere.

TRACED_LABELS="FR1 NFR1"
ENV_LABELS="ENV1 ENVX1"
ALL_LABELS="$TRACED_LABELS $ENV_LABELS"

count_words() { printf '%s\n' $1 | grep -c .; }

N_TRACED=$(count_words "$TRACED_LABELS")
N_ENV=$(count_words "$ENV_LABELS")
N_ALL=$(count_words "$ALL_LABELS")

text_for() {
  case "$1" in
    FR1)   echo "the pipeline records what the work must run on" ;;
    NFR1)  echo "an ordinary non-functional requirement, carrying no environmental class" ;;
    ENV1)  echo "PHP 8.2 or later available on the target host" ;;
    ENVX1) echo "must not require a queue worker" ;;
  esac
}

UNCOVERED_DIR=$(coverage_fixture_dir env-uncovered)
COVERED_DIR=$(coverage_fixture_dir env-covered)

# The functional requirement sits under Must Have and the other three under
# `## Non-Functional Requirements` -- which is the arrangement AD1 chose, and the one the
# first criterion names. `--nfr` takes an arbitrary label, so no builder change was needed
# for ENV1 or ENVX1 (verified before this epic was written; noted in the coverage matrix).
spec_args=(--must FR1 "$(text_for FR1)")
for label in NFR1 $ENV_LABELS; do
  spec_args+=(--nfr "$label" "$(text_for "$label")")
done

UNCOVERED_SPEC=$(coverage_fixture_spec 46-spec-env-uncovered --dir "$UNCOVERED_DIR" "${spec_args[@]}")
COVERED_SPEC=$(coverage_fixture_spec 46-spec-env-covered --dir "$COVERED_DIR" "${spec_args[@]}")

uncovered_rows=()
for label in $TRACED_LABELS; do
  uncovered_rows+=(--row "$label" "$(text_for "$label")" "a criterion for $label" "Story 1" '✓')
done

covered_rows=("${uncovered_rows[@]}")
for label in $ENV_LABELS; do
  covered_rows+=(--row "$label" "$(text_for "$label")" "a criterion for $label" "Story 1" '✓')
done

UNCOVERED_MATRIX=$(coverage_fixture_matrix 46-01-coverage-env-uncovered \
  "docs/specifications/46-spec-env-uncovered.md" \
  --dir "$UNCOVERED_DIR" "${uncovered_rows[@]}")

COVERED_MATRIX=$(coverage_fixture_matrix 46-01-coverage-env-covered \
  "docs/specifications/46-spec-env-covered.md" \
  --dir "$COVERED_DIR" "${covered_rows[@]}")

UNCOVERED_OUT=$(coverage_rollup_run --spec "$UNCOVERED_SPEC" --matrix-dir "$UNCOVERED_DIR")
COVERED_OUT=$(coverage_rollup_run --spec "$COVERED_SPEC" --matrix-dir "$COVERED_DIR")

# Before anything is read from those two runs: both matrices were found. Without this, a
# --matrix-dir the script silently failed to read would make every assertion about the
# untraced count pass for the wrong reason.
test_start "control: the uncovered run found its matrix"
assert_equals "1" "$(coverage_count_type "$UNCOVERED_OUT" MATRIX)"

test_start "control: the covered run found its matrix"
assert_equals "1" "$(coverage_count_type "$COVERED_OUT" MATRIX)"

# --- Criterion 1: an ENV label under the NFR heading emits a REQ and is counted --------

for label in $ENV_LABELS; do
  test_start "$label under ## Non-Functional Requirements emits a REQ record"
  assert_contains "$UNCOVERED_OUT" "$(printf 'REQ\t%s\tNon-Functional\t' "$label")"
done

# The heading field is asserted above rather than left implicit. It is the evidence that
# the label was read from the non-functional section and not from somewhere else that
# happens to parse -- which is the whole of AD1's mechanism claim.

test_start "every requirement the fixture carries gets a REQ record"
assert_equals "$N_ALL" "$(coverage_count_type "$UNCOVERED_OUT" REQ)"

test_start "the environmental labels are the untraced set"
assert_equals "$(printf '%s\n' $ENV_LABELS | LC_ALL=C sort)" "$(coverage_states_in "$UNCOVERED_OUT" untraced)"

test_start "SUMMARY counts them as untraced"
assert_equals "$N_ENV" "$(summary_field "$UNCOVERED_OUT" 4)"

test_start "SUMMARY counts every requirement, environmental ones included"
assert_equals "$N_ALL" "$(summary_field "$UNCOVERED_OUT" 3)"

# --- Criterion 2 (must NOT): no ENV label is dropped silently --------------------------
#
# Three ways a label can leave the untraced count without being covered: excluded,
# omitted from the requirement list, or counted but not reported. Each is asserted
# separately, because the SUMMARY count alone cannot tell them apart.

test_start "must NOT — no environmental label is excluded"
assert_equals "0" "$(coverage_count_type "$UNCOVERED_OUT" EXCLUDED)"

for label in $ENV_LABELS; do
  test_start "must NOT — $label is reported by name, not merely counted"
  assert_contains "$UNCOVERED_OUT" "$(printf 'STATE\t%s\tNon-Functional\tuntraced' "$label")"
done

# The verdict path is where "dropped silently" would actually cost something: cpm:ralph
# reads exit 3 as "work remains". An ENV label that fell out of the count would let a
# spec report itself delivered while its environmental constraint was never met -- which
# is the failure spec 46 exists for.
test_start "must NOT — an uncovered environmental constraint lets --verdict report done"
assert_equals "3" "$(coverage_rollup_rc --spec "$UNCOVERED_SPEC" --matrix-dir "$UNCOVERED_DIR" --verdict)"

# The control that gives the line above its meaning. Same labels, same code path, matrix
# rows filled in: the verdict has to flip, or exit 3 was never about the ENV labels.
test_start "control: covering them is what makes --verdict report done"
assert_equals "0" "$(coverage_rollup_rc --spec "$COVERED_SPEC" --matrix-dir "$COVERED_DIR" --verdict)"

test_start "control: covering them empties the untraced count"
assert_equals "0" "$(summary_field "$COVERED_OUT" 4)"

test_start "control: and moves them to delivered"
assert_equals "$(printf '%s\n' $ALL_LABELS | LC_ALL=C sort)" "$(coverage_states_in "$COVERED_OUT" delivered)"

# --- Criterion 3: the two classes are distinguishable in the records -------------------
#
# "Distinguishable" is a property of what a consumer can recover from the output, so it is
# asserted by classifying the emitted labels with the Story 1 predicate -- the same single
# definition coverage-rollup.sh uses (AD2), not a second copy written here.

UNTRACED_CLASSES=$(
  coverage_states_in "$UNCOVERED_OUT" untraced | awk "$_COVERAGE_AWK_LIB"'
    NF { printf "%s=%s\n", $0, cov_environmental_class($0) }
  ' | LC_ALL=C sort
)

test_start "the untraced labels classify as one requirement and one restriction"
assert_equals "$(printf 'ENV1=requirement\nENVX1=restriction')" "$UNTRACED_CLASSES"

# Asserted as a set difference rather than as two memberships: a classifier that returned
# "requirement" for both would satisfy two separate contains-assertions and fail this one.
DISTINCT_CLASSES=$(printf '%s\n' "$UNTRACED_CLASSES" | cut -d= -f2 | LC_ALL=C sort -u | grep -c .)

test_start "and they are two classes, not one repeated"
assert_equals "2" "$DISTINCT_CLASSES"

# The other half of "distinguishable": the labels that are not environmental must not
# acquire a class. Without this, a classifier returning "requirement" for everything
# passes the assertion above by half.
TRACED_CLASSES=$(
  printf '%s\n' $TRACED_LABELS | awk "$_COVERAGE_AWK_LIB"'
    NF { print cov_environmental_class($0) }
  ' | LC_ALL=C sort -u
)

test_start "control: the non-environmental requirements carry no class"
assert_empty "$TRACED_CLASSES"

# --- Criterion 4 (must NOT): SUMMARY's field arity is unchanged ------------------------
#
# cpm:status and cpm:ralph both read SUMMARY positionally. FR3's "distinguishable classes"
# has to be satisfied by the label prefix already present in the REQ and STATE records --
# which is what the section above asserts -- and never by widening this record.

test_start "must NOT — SUMMARY gains a field when environmental labels are present"
assert_equals "6" "$(summary_arity "$UNCOVERED_OUT")"

# Derived rather than pinned, and the pair is the point: the arity is the same whether
# environmental labels are untraced, covered, or absent, so no branch introduces a field.
NO_ENV_DIR=$(coverage_fixture_dir env-absent)
NO_ENV_SPEC=$(coverage_fixture_spec 46-spec-env-absent --dir "$NO_ENV_DIR" \
  --must FR1 "$(text_for FR1)" \
  --nfr NFR1 "$(text_for NFR1)")
NO_ENV_MATRIX=$(coverage_fixture_matrix 46-01-coverage-env-absent \
  "docs/specifications/46-spec-env-absent.md" \
  --dir "$NO_ENV_DIR" "${uncovered_rows[@]}")
NO_ENV_OUT=$(coverage_rollup_run --spec "$NO_ENV_SPEC" --matrix-dir "$NO_ENV_DIR")

test_start "control: a spec with no environmental labels at all still parses"
assert_equals "$N_TRACED" "$(coverage_count_type "$NO_ENV_OUT" REQ)"

test_start "must NOT — the arity differs between a spec with ENV labels and one without"
assert_equals "$(summary_arity "$NO_ENV_OUT")" "$(summary_arity "$UNCOVERED_OUT")"

test_start "must NOT — the arity differs between the covered and uncovered runs"
assert_equals "$(summary_arity "$COVERED_OUT")" "$(summary_arity "$UNCOVERED_OUT")"

# One SUMMARY per run, so the positional reads above are unambiguous.
for out_name in UNCOVERED COVERED NO_ENV; do
  out_var="${out_name}_OUT"
  test_start "the $out_name run emits exactly one SUMMARY record"
  assert_equals "1" "$(coverage_count_type "${!out_var}" SUMMARY)"
done

test_summary
