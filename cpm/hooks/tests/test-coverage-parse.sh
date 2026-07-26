#!/bin/bash
# test-coverage-parse.sh — Epic 44-01 Story 2: spec and matrix extraction
#
# Asserts the four [unit] acceptance criteria of "Extract requirement labels from a spec
# and rows from a matrix". Everything under test is in cpm/hooks/lib/coverage-parse.sh,
# which decides nothing — no states, no untraced set, no exit codes. What is asserted here
# is faithfulness to the two document shapes, and nothing beyond it.
#
# Expected values are derived rather than pinned throughout (retro 19): the labels asserted
# present come from the same shell variable the fixture was built from, so editing a
# fixture recipe cannot leave a stale literal passing. Every negative control runs the
# identical code path against a mutated input (retro 21).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/coverage-fixture-helpers.sh"
. "$SCRIPT_DIR/../lib/coverage-parse.sh"

echo "Testing coverage extraction primitives (Epic 44-01 Story 2)"

# --- Criterion 2: requirement labels, with the heading they appeared under -----------

MUST_LABELS="FR1 FR2 FR9"
SHOULD_LABELS="FR10 FR11"

spec_args=()
for label in $MUST_LABELS; do
  spec_args+=(--must "$label" "requirement text for $label")
done
for label in $SHOULD_LABELS; do
  spec_args+=(--should "$label" "requirement text for $label")
done
spec_args+=(--wont "an unlabelled thing this iteration will not do")

SPEC=$(coverage_fixture_spec 44-spec-extract "${spec_args[@]}")
REQUIREMENTS=$(coverage_spec_requirements "$SPEC")

for label in $MUST_LABELS; do
  test_start "spec extraction emits $label under Must Have"
  assert_contains "$REQUIREMENTS" "$(printf '%s\tMust Have\t' "$label")"
done

for label in $SHOULD_LABELS; do
  test_start "spec extraction emits $label under Should Have"
  assert_contains "$REQUIREMENTS" "$(printf '%s\tShould Have\t' "$label")"
done

test_start "every requested label appears exactly once"
EXPECTED_COUNT=0
for label in $MUST_LABELS $SHOULD_LABELS; do
  EXPECTED_COUNT=$((EXPECTED_COUNT + 1))
done
assert_equals "$EXPECTED_COUNT" "$(printf '%s\n' "$REQUIREMENTS" | grep -c .)"

test_start "requirement text survives extraction"
assert_contains "$REQUIREMENTS" "$(printf 'FR2\tMust Have\trequirement text for FR2')"

# Control: the identical extraction against a spec built without the label. If the loop
# above were matching something every record contains, this would pass when it must fail.
SPEC_ONE=$(coverage_fixture_spec 44-spec-extract-one --must FR1 "only requirement")
test_start "control: a label the spec does not carry is not emitted"
assert_not_contains "$(coverage_spec_requirements "$SPEC_ONE")" "$(printf 'FR2\t')"

# An unlabelled Won't Have bullet is prose, not a requirement, and the fixture writes it
# the way a real spec does.
test_start "an unlabelled Won't Have bullet yields no record"
assert_not_contains "$REQUIREMENTS" "will not do"

# The heading is carried, not filtered on — a labelled Won't Have entry is emitted with
# its heading so the policy question can be answered where states are derived.
SPEC_WONT="$(dirname "$SPEC")/44-spec-wont-labelled.md"
cat > "$SPEC_WONT" <<'FIXTURE'
# Spec: labelled won't-have

## Functional Requirements

### Must Have

- **FR1** — a real requirement

### Won't Have (this iteration)

- **FR2** — a requirement ruled out for this iteration
FIXTURE

test_start "a labelled Won't Have entry is emitted with its heading"
assert_contains "$(coverage_spec_requirements "$SPEC_WONT")" "$(printf "FR2\tWon't Have (this iteration)\t")"

# Fence-awareness: an example bullet inside a fenced block is an example, not a requirement.
SPEC_FENCED="$(dirname "$SPEC")/44-spec-fenced.md"
cat > "$SPEC_FENCED" <<'FIXTURE'
# Spec: fenced

## Functional Requirements

### Must Have

- **FR1** — a real requirement

```markdown
- **FR99** — an example bullet inside a fence
```

- **FR2** — another real requirement
FIXTURE

FENCED_REQUIREMENTS=$(coverage_spec_requirements "$SPEC_FENCED")

test_start "a bullet inside a fenced block is not a requirement"
assert_not_contains "$FENCED_REQUIREMENTS" "FR99"

test_start "control: the bullets around the fence still are"
assert_equals "2" "$(printf '%s\n' "$FENCED_REQUIREMENTS" | grep -c .)"

test_start "an unreadable spec returns non-zero"
if coverage_spec_requirements "$TEST_TMPDIR/no-such-spec.md" >/dev/null 2>&1; then
  test_fail "Expected a non-zero return for an unreadable spec"
else
  test_pass
fi

test_start "an unreadable spec emits no records"
assert_empty "$(coverage_spec_requirements "$TEST_TMPDIR/no-such-spec.md" 2>/dev/null)"

# --- Criterion 1: qualifier resolution and story-originated rows ---------------------

test_start "FR1 (must NOT) resolves to FR1"
assert_equals "FR1" "$(coverage_base_label 'FR1 (must NOT)')"

test_start "FR6 (cross-site) resolves to FR6"
assert_equals "FR6" "$(coverage_base_label 'FR6 (cross-site)')"

test_start "an unqualified label resolves to itself"
assert_equals "FR1" "$(coverage_base_label 'FR1')"

test_start "a multi-word label keeps its words"
assert_equals "Test Infrastructure" "$(coverage_base_label 'Test Infrastructure (story-originated)')"

test_start "a label that is nothing but a qualifier resolves to no requirement"
assert_empty "$(coverage_base_label '(story-originated)')"

# --- Criterion 4 (must NOT): FR10 is not FR1 -----------------------------------------
#
# The hazard is real for this spec in particular: it has both an FR1 and an FR10, so any
# prefix-flavoured matching traces the wrong requirement silently.

test_start "FR10 resolves to FR10, not FR1"
assert_equals "FR10" "$(coverage_base_label 'FR10')"

test_start "FR10 (must NOT) resolves to FR10, not FR1"
assert_equals "FR10" "$(coverage_base_label 'FR10 (must NOT)')"

test_start "must NOT treat FR10's base as equal to FR1's"
if [ "$(coverage_base_label 'FR10')" = "$(coverage_base_label 'FR1')" ]; then
  test_fail "FR10 and FR1 resolved to the same base requirement"
else
  test_pass
fi

# Control for the assertion above: two labels that genuinely *are* the same requirement,
# compared the identical way. Without it, "these two differ" would also pass for a
# resolver that returned a different value every call.
test_start "control: FR1 and FR1 (must NOT) do resolve to the same base"
assert_equals "$(coverage_base_label 'FR1')" "$(coverage_base_label 'FR1 (must NOT)')"

# --- Criterion 3: matrix rows ---------------------------------------------------------

ROW_LABEL="FR1"
ROW_SPEC_TEXT="a script accepts either a spec path or one or more epic paths"
ROW_CRITERION="given a spec path, the script emits one record per requirement"

MATRIX=$(coverage_fixture_matrix 44-01-coverage-extract "$SPEC" \
  --row "$ROW_LABEL" "$ROW_SPEC_TEXT" "$ROW_CRITERION" "Story 3" '✓' \
  --row "FR10" "the tenth requirement's text" "a criterion for FR10" "Story 4" '' \
  --row "FR1 (must NOT)" "must NOT include rows from another spec" "must NOT include rows from another spec" "Story 3" '' \
  --row "(story-originated)" "—" "a criterion with no requirement behind it" "Story 1" '')
ROWS=$(coverage_matrix_rows "$MATRIX")

test_start "a matrix row's label is read from column 2"
assert_contains "$ROWS" "$(printf '\t%s\t%s\t' "$ROW_LABEL" "$ROW_SPEC_TEXT")"

test_start "a ✓ cell reads as verified"
assert_contains "$ROWS" "$(printf 'requirement\tFR1\t%s\t%s\tStory 3\tverified' "$ROW_LABEL" "$ROW_SPEC_TEXT")"

test_start "an empty cell reads as unverified"
assert_contains "$ROWS" "$(printf "requirement\tFR10\tFR10\tthe tenth requirement's text\tStory 4\tunverified")"

test_start "a qualified row carries its resolved base"
assert_contains "$ROWS" "$(printf 'requirement\tFR1\tFR1 (must NOT)\t')"

test_start "a story-originated row is reported with no base"
assert_contains "$ROWS" "$(printf 'story-originated\t\t(story-originated)\t')"

test_start "every row in the matrix produces exactly one record"
assert_equals "4" "$(printf '%s\n' "$ROWS" | grep -c .)"

test_start "the header row produces no record"
assert_not_contains "$ROWS" "Spec Requirement"

test_start "the separator row produces no record"
assert_not_contains "$ROWS" "---"

# ✓ is the only value read as verified. A cell nobody meant as proof must not become
# proof — this is the identical extraction against the same matrix with the tick replaced.
MATRIX_ALT="$(dirname "$MATRIX")/44-01-coverage-alt.md"
sed 's/| ✓ |/| yes |/' "$MATRIX" > "$MATRIX_ALT"
ALT_ROWS=$(coverage_matrix_rows "$MATRIX_ALT")

test_start "control: a cell holding something other than ✓ reads as unverified"
assert_not_contains "$ALT_ROWS" "$(printf '\tverified')"

test_start "control: that row is still present, just unverified"
assert_contains "$ALT_ROWS" "$(printf 'requirement\tFR1\t%s\t' "$ROW_LABEL")"

test_start "control: the unmutated matrix does report a verified row"
assert_contains "$ROWS" "$(printf '\tverified')"

# Fence-awareness on the matrix side: a Notes section may quote an example row.
MATRIX_FENCED="$(dirname "$MATRIX")/44-01-coverage-fenced.md"
cp "$MATRIX" "$MATRIX_FENCED"
{
  printf '\n## Notes\n\n'
  printf '```\n'
  printf '| 99 | FR99 | an example row | an example criterion | Story 9 | — | ✓ |\n'
  printf '```\n'
} >> "$MATRIX_FENCED"

FENCED_ROWS=$(coverage_matrix_rows "$MATRIX_FENCED")

test_start "a row quoted inside a fence produces no record"
assert_not_contains "$FENCED_ROWS" "FR99"

test_start "control: the real rows are unaffected by the appended fence"
assert_equals "$(printf '%s\n' "$ROWS" | grep -c .)" "$(printf '%s\n' "$FENCED_ROWS" | grep -c .)"

test_start "an unreadable matrix returns non-zero"
if coverage_matrix_rows "$TEST_TMPDIR/no-such-matrix.md" >/dev/null 2>&1; then
  test_fail "Expected a non-zero return for an unreadable matrix"
else
  test_pass
fi

test_start "an unreadable matrix emits no records"
assert_empty "$(coverage_matrix_rows "$TEST_TMPDIR/no-such-matrix.md" 2>/dev/null)"

# --- The library reads the repository's own documents ---------------------------------
#
# The fixtures above are built to be read; the real documents were not. Running the same
# extraction over one of each is what stops the parser from being correct only about
# shapes it was handed.

REPO_ROOT="$SCRIPT_DIR/../../.."
REAL_SPEC="$REPO_ROOT/docs/specifications/44-spec-coverage-rollup.md"
REAL_MATRIX="$REPO_ROOT/docs/epics/44-01-coverage-coverage-rollup-script.md"

# These are asserted readable rather than guarded with `if [ -r ]`. A guard turns a moved
# or renamed document into eight assertions that quietly stop running, and a suite whose
# count drops in silence is worse than one that fails: the failure names the cause.
test_start "the real spec is readable"
if [ -r "$REAL_SPEC" ]; then test_pass; else test_fail "Not readable: $REAL_SPEC"; fi

test_start "the real matrix is readable"
if [ -r "$REAL_MATRIX" ]; then test_pass; else test_fail "Not readable: $REAL_MATRIX"; fi

REAL_REQUIREMENTS=$(coverage_spec_requirements "$REAL_SPEC" 2>/dev/null)

test_start "the real spec yields requirements"
if [ "$(printf '%s\n' "$REAL_REQUIREMENTS" | grep -c .)" -gt 0 ]; then
  test_pass
else
  test_fail "Expected records from $REAL_SPEC"
fi

test_start "every record from the real spec carries a MoSCoW heading"
assert_empty "$(printf '%s\n' "$REAL_REQUIREMENTS" | awk -F'\t' 'NF > 0 && $2 == ""')"

# Extended for Story 4: the non-functional bullets are requirements too, and untraced
# detection that skipped them would miss a real gap in the load-bearing measurement.
test_start "the real spec's Non-Functional bullets are read as requirements"
REAL_NFRS=$(printf '%s\n' "$REAL_REQUIREMENTS" | awk -F'\t' '$1 ~ /^NFR[0-9]+$/')
if [ "$(printf '%s\n' "$REAL_NFRS" | grep -c .)" -gt 0 ]; then
  test_pass
else
  test_fail "Expected NFR records from $REAL_SPEC"
fi

test_start "every NFR record carries the non-functional section as its heading"
assert_empty "$(printf '%s\n' "$REAL_NFRS" | awk -F'\t' '$2 != "Non-Functional"')"

# The label is read off the front of the bullet, so the summary that follows it inside the
# same bold span stays with the text rather than being swallowed into the label.
test_start "a label carries no part of the summary that follows it"
assert_empty "$(printf '%s\n' "$REAL_REQUIREMENTS" | awk -F'\t' '$1 ~ / /')"

test_start "the text of NFR1 keeps the summary the bold span carried"
assert_contains "$REAL_NFRS" "$(printf 'NFR1\tNon-Functional\tRead-only.')"

# Control: a bullet whose bold span is prose rather than a requirement label is not a
# requirement. Without this, the leading-label rule could be dropped entirely and every
# bold bullet in a requirements section would become a record.
SPEC_PROSE="$(coverage_fixture_dir prose)/44-spec-prose-bullet.md"
cat > "$SPEC_PROSE" <<'FIXTURE'
# Spec: a bold bullet that is not a requirement

## Functional Requirements

### Must Have

- **FR1** — a real requirement
- **Note** — a bold bullet carrying no requirement label
FIXTURE

test_start "control: a bold bullet with no requirement label yields no record"
assert_not_contains "$(coverage_spec_requirements "$SPEC_PROSE")" "a bold bullet carrying no requirement label"

test_start "control: the real requirement beside it is still emitted"
assert_contains "$(coverage_spec_requirements "$SPEC_PROSE")" "a real requirement"

REAL_ROWS=$(coverage_matrix_rows "$REAL_MATRIX" 2>/dev/null)

test_start "the real matrix yields rows"
if [ "$(printf '%s\n' "$REAL_ROWS" | grep -c .)" -gt 0 ]; then
  test_pass
else
  test_fail "Expected records from $REAL_MATRIX"
fi

test_start "every real row is classified as requirement or story-originated"
assert_empty "$(printf '%s\n' "$REAL_ROWS" | awk -F'\t' 'NF > 0 && $1 != "requirement" && $1 != "story-originated"')"

test_start "every real row reads as verified or unverified"
assert_empty "$(printf '%s\n' "$REAL_ROWS" | awk -F'\t' 'NF > 0 && $6 != "verified" && $6 != "unverified"')"

test_start "no real requirement row resolves to an empty base"
assert_empty "$(printf '%s\n' "$REAL_ROWS" | awk -F'\t' '$1 == "requirement" && $2 == ""')"

test_start "every real story-originated row resolves to no base"
assert_empty "$(printf '%s\n' "$REAL_ROWS" | awk -F'\t' '$1 == "story-originated" && $2 != ""')"

test_summary
