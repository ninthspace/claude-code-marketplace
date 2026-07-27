#!/bin/bash
# test-environmental-class.sh — Epic 46-01 Story 1: one definition of the environmental class
#
# Asserts the three [unit] acceptance criteria of "Define the environmental constraint class
# once". Everything under test is in cpm/hooks/lib/coverage-parse.sh: the awk functions
# cov_environmental_class and cov_is_environmental inside _COVERAGE_AWK_LIB, and the shell
# wrapper coverage_environmental_class.
#
# --- Which assertions are oracles, and which are nets ----------------------------
#
# Retro 23: for a deliverable that is partly prose, most assertions can only catch a rule
# being dropped, and a reader should not take a green run for a quality verdict. Here:
#
#   Sections 1-3 are ORACLES. They run the real classifier over real labels and compare
#   against expectations derived from the same table the inputs come from. A wrong
#   implementation fails them.
#
#   Section 4 is an INVENTORY. It does not decide whether a second definition is wrong; it
#   insists that a human look at one before it lands. Retro 22's shape.
#
#   Section 5 is a NET plus its own non-vacuity CONTROL. Asserting that a file mentions
#   $_COVERAGE_AWK_LIB proves nothing on its own -- the control proves the library is
#   actually reachable from an awk program built the way the roll-up builds its own.
#
# Expected values are derived rather than pinned (retro 19): every classification assertion
# reads its expectation from the CASES table below, so adding a case cannot leave a stale
# literal passing somewhere else.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
. "$SCRIPT_DIR/../lib/coverage-parse.sh"

LIB_DIR="$SCRIPT_DIR/../lib"
ROLLUP="$LIB_DIR/coverage-rollup.sh"

echo "Testing the environmental constraint class (Epic 46-01 Story 1)"

# The single table every classification assertion is derived from. Format: LABEL|EXPECTED.
# An empty expectation means "not environmental".
#
# ENVIRONMENT1 is the load-bearing negative. It is a *valid* requirement label under AD1's
# [A-Z]+[0-9]+ grammar, and an implementation matching /^ENV[0-9]+/ or testing a string
# prefix would classify the first two cases correctly and get this one wrong. It is the case
# that tells prefix-equality apart from prefix-matching.
CASES="
ENV1|requirement
ENV12|requirement
ENVX1|restriction
ENVX99|restriction
NFR1|
FR1|
ENVIRONMENT1|
ENVOY3|
"

# --- Criterion 2: ENV1 and ENVX1 classify; NFR1, FR1, ENVIRONMENT1 do not -------------

while IFS='|' read -r label expected; do
  [ -z "$label" ] && continue

  actual="$(coverage_environmental_class "$label")"

  if [ -n "$expected" ]; then
    test_start "$label classifies as $expected"
    assert_equals "$expected" "$actual"
  else
    test_start "$label does not classify as environmental"
    assert_empty "$actual"
  fi
done <<EOF
$CASES
EOF

# The table has to contain both kinds of case, or the loop above is satisfied by a
# classifier that always returns the empty string (or always returns "requirement").
POSITIVE_COUNT=$(printf '%s\n' "$CASES" | grep -c '|.')
NEGATIVE_COUNT=$(printf '%s\n' "$CASES" | grep -c '|$')

test_start "control: the case table contains classifying cases"
assert_equals "4" "$POSITIVE_COUNT"

test_start "control: the case table contains non-classifying cases"
assert_equals "4" "$NEGATIVE_COUNT"

# --- Criterion 3: the two classes are distinguishable ---------------------------------

# Asserted as a pair rather than as two separate equalities, so a classifier that collapsed
# both classes onto one answer fails here rather than passing two assertions that never
# compare their results to each other.
test_start "the requirement class and the restriction class are different answers"
assert_equals "requirement/restriction" \
  "$(coverage_environmental_class ENV1)/$(coverage_environmental_class ENVX1)"

test_start "a caller can ask for the restriction class by name"
assert_equals "restriction" "$(coverage_environmental_class ENVX1)"

test_start "a caller can ask for the requirement class by name"
assert_equals "requirement" "$(coverage_environmental_class ENV1)"

# A qualified label classifies by the requirement behind it, the same way coverage_base_label
# resolves one. Without this, a `must NOT` row would silently stop being environmental.
test_start "a qualified label classifies by its base requirement"
assert_equals "requirement" "$(coverage_environmental_class 'ENV1 (must NOT)')"

# --- The boolean agrees with the classifier ------------------------------------------
#
# Two functions that could each decide the question are two definitions. This asserts they
# cannot disagree, which is what makes the delegation in cov_is_environmental load-bearing
# rather than stylistic.

BOOL_PROBE=$(printf '%s\n' "$CASES" | grep . | cut -d'|' -f1)

test_start "control: the boolean probe has labels to check"
assert_contains "$BOOL_PROBE" "ENVIRONMENT1"

DISAGREEMENTS=$(
  printf '%s\n' "$BOOL_PROBE" | awk "$_COVERAGE_AWK_LIB"'
    NF {
      cls = cov_environmental_class($0)
      bool = cov_is_environmental($0)
      if ((cls != "") != (bool != 0)) print $0
    }
  '
)

test_start "cov_is_environmental agrees with cov_environmental_class on every case"
assert_empty "$DISAGREEMENTS"

# --- Criterion 1: one definition ------------------------------------------------------
#
# An inventory, not a detector. It counts the files under cpm/hooks/lib/ that carry the
# class prefixes as quoted literals; a second site makes this fail until someone has looked
# at it and said why two places decide the same question. AD2 is explicit that they drift.

DEFINING_FILES=$(grep -l '"ENVX"' "$LIB_DIR"/*.sh 2>/dev/null | LC_ALL=C sort)
DEFINING_COUNT=$(printf '%s\n' "$DEFINING_FILES" | grep -c .)

test_start "the environmental prefixes are defined in exactly one lib file"
assert_equals "1" "$DEFINING_COUNT"

test_start "and that file is coverage-parse.sh"
assert_contains "$DEFINING_FILES" "coverage-parse.sh"

test_start "coverage-rollup.sh does not restate the prefixes"
assert_not_contains "$(cat "$ROLLUP")" '"ENVX"'

# --- The roll-up can reach the shared library ----------------------------------------

test_start "the roll-up derives its records with the shared awk library in scope"
assert_contains "$(cat "$ROLLUP")" 'awk -F'"'"'\t'"'"' "$_COVERAGE_AWK_LIB"'

# The control. The assertion above is a grep over source text, and would pass just as well
# if _COVERAGE_AWK_LIB were empty or the functions had been deleted from it -- which is
# exactly what happens when a stray apostrophe closes the single-quoted library early. This
# builds an awk program the same way the roll-up does and calls the function for real.
CALLABLE=$(printf 'ENVX7\n' | awk -F'\t' "$_COVERAGE_AWK_LIB"'{ print cov_environmental_class($0) }')

test_start "control: the shared library is reachable from an awk program built that way"
assert_equals "restriction" "$CALLABLE"

# A second control on a function defined *before* the new ones, which separates two failures
# that otherwise look identical: "cov_environmental_class is broken" and "the library did not
# load at all".
#
# Measured during Story 1 rather than assumed: an apostrophe in a comment does not truncate
# the library part-way, it destroys all of it. Bash rejects the file at parse time, so
# _COVERAGE_AWK_LIB is never assigned and its length is 0 -- every awk program built from it
# becomes a bare pattern-less program that prints nothing. Both controls then fail together,
# which is how a green run on one and a red run on the other tells the two cases apart.
BASE_STILL_THERE=$(printf 'FR1 (must NOT)\n' | awk -F'\t' "$_COVERAGE_AWK_LIB"'{ print cov_base_label($0) }')

test_start "control: the shared library loaded at all, not merely in part"
assert_equals "FR1" "$BASE_STILL_THERE"

test_summary
