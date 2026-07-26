#!/bin/bash
# test-coverage-fixtures.sh — Epic 44-01 Story 1: coverage fixture builders
#
# Asserts the five [unit] acceptance criteria of "Establish coverage fixture builders
# under TEST_TMPDIR". The builders under test are a *test* library, so this suite is the
# thing that stops later stories from being written against a fixture that lies about the
# documents it stands in for.
#
# Two habits are deliberate throughout, both carried from retros:
#
#   * Expected values are derived, never pinned. The labels asserted present are the same
#     shell variable the builder was asked for, so editing the fixture recipe cannot leave
#     a stale literal passing (retro 19: an invariant asserted against a pinned expected
#     value is still a pin).
#
#   * Every negative control runs the identical code path as the assertion it guards,
#     against a mutated input — never a different check that happens to fail (retro 21: a
#     control sharing no code path with its assertion is decoration).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/coverage-fixture-helpers.sh"

echo "Testing coverage fixture builders (Epic 44-01 Story 1)"

# --- Criterion 1: the spec builder ---------------------------------------------------

MUST_LABELS="FR1 FR2 FR5"
SHOULD_LABELS="FR10 FR11"

spec_args=()
for label in $MUST_LABELS; do
  spec_args+=(--must "$label" "requirement text for $label")
done
for label in $SHOULD_LABELS; do
  spec_args+=(--should "$label" "requirement text for $label")
done
spec_args+=(--wont "a thing this iteration will not do")

SPEC=$(coverage_fixture_spec 44-spec-fixture "${spec_args[@]}")
SPEC_CONTENT=$(cat "$SPEC")

test_start "spec builder writes its file under TEST_TMPDIR"
case "$SPEC" in
  "$TEST_TMPDIR"/*) test_pass ;;
  *) test_fail "Spec written outside TEST_TMPDIR: $SPEC" ;;
esac

for label in $MUST_LABELS $SHOULD_LABELS; do
  test_start "spec contains the requested requirement label $label"
  assert_contains "$SPEC_CONTENT" "- **$label** —"
done

test_start "spec carries the Must Have heading"
assert_contains "$SPEC_CONTENT" "### Must Have"

test_start "spec carries the Should Have heading"
assert_contains "$SPEC_CONTENT" "### Should Have"

test_start "spec carries the Won't Have heading"
assert_contains "$SPEC_CONTENT" "### Won't Have (this iteration)"

# Control for the containment assertions above: the identical check, against a spec built
# without the label. If the loop were grepping the wrong file — or matching something
# every spec contains — this would pass when it must fail.
SPEC_ONE=$(coverage_fixture_spec 44-spec-single --must FR1 "only requirement")
SPEC_ONE_CONTENT=$(cat "$SPEC_ONE")

test_start "control: a label that was not requested does not appear"
assert_not_contains "$SPEC_ONE_CONTENT" "- **FR2** —"

test_start "control: a section with no entries emits no heading"
assert_not_contains "$SPEC_ONE_CONTENT" "### Should Have"

# A spec with no requirements at all is Story 5's fail-closed input, so it has to be
# constructible — and it must still look like a spec.
SPEC_EMPTY=$(coverage_fixture_spec 44-spec-empty)
test_start "a spec with no requirements still carries the Functional Requirements heading"
assert_contains "$(cat "$SPEC_EMPTY")" "## Functional Requirements"

# Retro 20: an equality (or comparison) between two fixtures needs a preceding assertion
# that they are two fixtures. The intended call form runs the builder in a subshell, so a
# counter-based implementation would return the same path every time and any comparison
# built on it would pass for the wrong reason.
SPEC_A=$(coverage_fixture_spec 44-spec-twice --must FR1 "first")
SPEC_B=$(coverage_fixture_spec 44-spec-twice --must FR1 "second")

test_start "two calls with the same slug return distinct paths"
if [ "$SPEC_A" = "$SPEC_B" ]; then
  test_fail "Both calls returned the same path: $SPEC_A"
else
  test_pass
fi

test_start "both files from the same slug exist independently"
if [ -f "$SPEC_A" ] && [ -f "$SPEC_B" ]; then
  test_pass
else
  test_fail "Expected both fixture files to exist: $SPEC_A, $SPEC_B"
fi

# --- Criterion 2: the matrix builder ------------------------------------------------

DIR=$(coverage_fixture_dir shared)
SHARED_SPEC=$(coverage_fixture_spec 44-spec-shared --dir "$DIR" --must FR1 "shared spec requirement")

ROW_LABEL="FR1"
ROW_SPEC_TEXT="a script accepts either a spec path or one or more epic paths"
ROW_CRITERION="given a spec path, the script emits one record per requirement"

MATRIX=$(coverage_fixture_matrix 44-01-coverage-fixture "$SHARED_SPEC" --dir "$DIR" \
  --row "$ROW_LABEL" "$ROW_SPEC_TEXT" "$ROW_CRITERION" "Story 3" '✓')
MATRIX_CONTENT=$(cat "$MATRIX")

test_start "matrix builder writes its file under TEST_TMPDIR"
case "$MATRIX" in
  "$TEST_TMPDIR"/*) test_pass ;;
  *) test_fail "Matrix written outside TEST_TMPDIR: $MATRIX" ;;
esac

test_start "matrix carries the caller-supplied Source spec value"
assert_contains "$MATRIX_CONTENT" "**Source spec**: $SHARED_SPEC"

test_start "matrix row carries the label as given"
assert_contains "$MATRIX_CONTENT" "| $ROW_LABEL |"

test_start "matrix row carries the spec text as given"
assert_contains "$MATRIX_CONTENT" "| $ROW_SPEC_TEXT |"

test_start "matrix row carries the criterion as given"
assert_contains "$MATRIX_CONTENT" "| $ROW_CRITERION |"

test_start "matrix row carries the Verified cell as given"
assert_contains "$MATRIX_CONTENT" "| $ROW_CRITERION | Story 3 | — | ✓ |"

test_start "matrix carries the seven-column header CPM writes"
assert_contains "$MATRIX_CONTENT" "| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |"

test_start "a spec and a matrix can be placed in one directory"
if [ "$(dirname "$SHARED_SPEC")" = "$(dirname "$MATRIX")" ]; then
  test_pass
else
  test_fail "Expected --dir to place both documents together"
fi

# The Source spec field is written verbatim, including a path that does not resolve —
# the input Story 5's fail-closed cases and Story 6's invariant assertion both need.
MISSING_TARGET="$TEST_TMPDIR/no-such-spec.md"
MATRIX_DANGLING=$(coverage_fixture_matrix 44-02-coverage-dangling "$MISSING_TARGET" \
  --row FR1 "text" "criterion" "Story 1" '')

test_start "Source spec may name a file that does not exist"
assert_contains "$(cat "$MATRIX_DANGLING")" "**Source spec**: $MISSING_TARGET"

test_start "control: that Source spec target really is absent"
if [ -e "$MISSING_TARGET" ]; then
  test_fail "Expected $MISSING_TARGET not to exist"
else
  test_pass
fi

# --- Criterion 3: the four row variants ----------------------------------------------

VARIANTS=$(coverage_fixture_matrix 44-03-coverage-variants "$SHARED_SPEC" \
  --row "FR1" "plain requirement text" "a verified criterion" "Story 3" '✓' \
  --row "FR2" "another requirement" "an unverified criterion" "Story 4" '' \
  --row "FR1 (must NOT)" "must NOT include rows from a matrix belonging to a different spec" "must NOT include rows from a matrix belonging to a different spec" "Story 3" '-' \
  --row "(story-originated)" "—" "a criterion with no requirement behind it" "Story 1" '')
VARIANTS_CONTENT=$(cat "$VARIANTS")

test_start "a verified row ends in the | ✓ | cell cpm:do writes"
assert_contains "$VARIANTS_CONTENT" "| a verified criterion | Story 3 | — | ✓ |"

test_start "an unverified row ends in the | | cell cpm:do edits from"
assert_contains "$VARIANTS_CONTENT" "| an unverified criterion | Story 4 | — | |"

test_start "a qualifier-bearing label survives unaltered"
assert_contains "$VARIANTS_CONTENT" "| FR1 (must NOT) |"

test_start "a story-originated row carries — as its spec text"
assert_contains "$VARIANTS_CONTENT" "| (story-originated) | — |"

test_start "'-' and '' both produce an unverified cell"
assert_contains "$VARIANTS_CONTENT" "| must NOT include rows from a matrix belonging to a different spec | Story 3 | — | |"

# Control for the verified/unverified assertions: the identical row recipe with the
# verification state flipped. A check that matched both states would pass above and fail
# here — which is the whole point of writing it.
FLIPPED=$(coverage_fixture_matrix 44-04-coverage-flipped "$SHARED_SPEC" \
  --row "FR1" "plain requirement text" "a verified criterion" "Story 3" '')

test_start "control: flipping the verified argument removes the ✓ from that row"
assert_not_contains "$(cat "$FLIPPED")" "| a verified criterion | Story 3 | — | ✓ |"

test_start "control: the flipped row is present, just unverified"
assert_contains "$(cat "$FLIPPED")" "| a verified criterion | Story 3 | — | |"

# A Verified cell the builder does not recognise is an error, not a silently unverified
# row — otherwise a typo in a later story's fixture would make a verification test pass
# for the wrong reason.
test_start "an unrecognised Verified value is rejected"
BAD_OUTPUT=$(coverage_fixture_matrix 44-05-coverage-bad "$SHARED_SPEC" \
  --row FR1 "text" "criterion" "Story 1" 'yes' 2>&1)
BAD_STATUS=$?
if [ "$BAD_STATUS" -ne 0 ]; then
  test_pass
else
  test_fail "Expected a non-zero exit for an unrecognised Verified value"
fi

test_start "the rejection names what it refused"
assert_contains "$BAD_OUTPUT" "verified cell must be"

# --- Criterion 4: library conventions -------------------------------------------------

test_start "the helper filename is outside run-all-tests.sh's test-*.sh glob"
case "coverage-fixture-helpers.sh" in
  test-*.sh) test_fail "run-all-tests.sh would execute the helper library standalone" ;;
  *) test_pass ;;
esac

test_start "the helper library sits alongside test-helpers.sh and git-fixture-helpers.sh"
if [ -f "$SCRIPT_DIR/coverage-fixture-helpers.sh" ] &&
   [ -f "$SCRIPT_DIR/test-helpers.sh" ] &&
   [ -f "$SCRIPT_DIR/git-fixture-helpers.sh" ]; then
  test_pass
else
  test_fail "Expected all three libraries in $SCRIPT_DIR"
fi

# Sourcing order is a real constraint, not a comment: the library has no temp directory of
# its own. Sourced without TEST_TMPDIR it must fail loudly rather than scatter fixtures
# into the working tree.
test_start "sourcing without TEST_TMPDIR fails loudly"
SOURCE_OUTPUT=$(run_without_env TEST_TMPDIR -- bash -c "source '$SCRIPT_DIR/coverage-fixture-helpers.sh'" 2>&1)
SOURCE_STATUS=$?
if [ "$SOURCE_STATUS" -ne 0 ]; then
  test_pass
else
  test_fail "Expected a non-zero exit when TEST_TMPDIR is unset"
fi

test_start "the failure names the missing variable"
assert_contains "$SOURCE_OUTPUT" "TEST_TMPDIR is not set"

# --- Criterion 5: must NOT write outside TEST_TMPDIR ----------------------------------

# Positive control first: "nothing written outside TEST_TMPDIR" is satisfied equally by a
# correct builder and by one that never wrote anything at all.
test_start "control: the builders did create fixtures this run"
if [ "$(coverage_fixture_count)" -gt 0 ]; then
  test_pass
else
  test_fail "No fixtures on disk — the containment assertions below would be vacuous"
fi

test_start "every fixture path returned this run is under TEST_TMPDIR"
ESCAPED=""
for path in "$SPEC" "$SPEC_ONE" "$SPEC_EMPTY" "$SPEC_A" "$SPEC_B" "$SHARED_SPEC" \
            "$MATRIX" "$MATRIX_DANGLING" "$VARIANTS" "$FLIPPED"; do
  case "$path" in
    "$TEST_TMPDIR"/*) ;;
    *) ESCAPED="$ESCAPED $path" ;;
  esac
done
assert_empty "$ESCAPED"

test_start "a slug containing a path separator is refused"
if coverage_fixture_spec "nested/slug" --must FR1 text >/dev/null 2>&1; then
  test_fail "Expected a slug containing '/' to be refused"
else
  test_pass
fi

test_start "a slug containing .. is refused"
if coverage_fixture_spec "../escape" --must FR1 text >/dev/null 2>&1; then
  test_fail "Expected a slug containing '..' to be refused"
else
  test_pass
fi

# The refusal has to prevent the write, not merely report it. Aim a --dir at a real
# directory outside the root, then assert nothing landed there.
OUTSIDE_DIR="$TEST_TMPDIR-outside-$$"
mkdir -p "$OUTSIDE_DIR"

test_start "a --dir outside the fixture root is refused"
if coverage_fixture_matrix 44-06-coverage-escape "$SHARED_SPEC" --dir "$OUTSIDE_DIR" \
     --row FR1 text criterion "Story 1" '' >/dev/null 2>&1; then
  test_fail "Expected a --dir outside the fixture root to be refused"
else
  test_pass
fi

test_start "the refused --dir received no file"
assert_empty "$(ls -A "$OUTSIDE_DIR" 2>/dev/null)"

# Control for the assertion above: the identical builder call, aimed inside the root,
# must leave a file. Without it, "the directory is empty" would also pass for a builder
# that writes nothing anywhere.
INSIDE_DIR=$(coverage_fixture_dir inside)
coverage_fixture_matrix 44-07-coverage-inside "$SHARED_SPEC" --dir "$INSIDE_DIR" \
  --row FR1 text criterion "Story 1" '' >/dev/null 2>&1

test_start "control: the same call aimed inside the root does write a file"
if [ -n "$(ls -A "$INSIDE_DIR" 2>/dev/null)" ]; then
  test_pass
else
  test_fail "Expected the in-root call to write a fixture"
fi

rm -rf "$OUTSIDE_DIR"

test_summary
