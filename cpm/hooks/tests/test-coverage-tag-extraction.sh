#!/bin/bash
# test-coverage-tag-extraction.sh — the test approach a matrix assigns reaches the records.
#
# --- The failure this covers --------------------------------------------------------
#
# `coverage_matrix_rows` read columns 2, 3, 4, 6 and 8 of a seven-column table. Column 7 —
# Spec Test Approach — was never extracted, so every consumer saw a row as a tick or not a
# tick and nothing else. `[target]` and `[manual]` are the two tags whose ticks rest on
# something other than a test having run: one on an environment nobody here has, the other
# on a human verdict. Unextracted, a matrix that is entirely those two is indistinguishable
# from one every test in the suite discharged, and the roll-up reports both as green.
#
# --- Which assertions are oracles ---------------------------------------------------
#
# **The round trip is.** Each tag is written into a fixture matrix, and the expectation is
# read back out of that same file rather than typed a second time here — so the assertion
# compares what the document says against what the records say, and a tag renamed in the
# fixture needs no edit below. A test that spelled `[target]` on both sides would pass for
# a parser that returned its own input.
#
# **The empty-column control is.** A matrix whose Spec Test Approach cell is `—` must yield
# that cell and not a tag borrowed from a neighbouring column. Off-by-one is the failure
# mode a field appended to a positional record actually has, and `[manual]` sitting in the
# covered-by field would satisfy every presence check written the obvious way.
#
# **The field-position assertions are structural, not stylistic.** The tag is last because
# every existing consumer indexes positionally; asserting the index is asserting that
# contract, which is the thing an insertion would break silently.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/coverage-fixture-helpers.sh"

source "$SCRIPT_DIR/../lib/coverage-parse.sh"

echo "Testing that a matrix's test approach column reaches the roll-up records"

FIX_DIR=$(coverage_fixture_dir tag-extraction)

SPEC=$(coverage_fixture_spec 70-spec-tagging \
  --dir "$FIX_DIR" \
  --must FR1 "a requirement discharged by a test" \
  --must FR2 "a requirement about the deployment host" \
  --must FR3 "a requirement a person confirms" \
  --must FR4 "a requirement whose row carries no tag")

MATRIX=$(coverage_fixture_matrix 70-01-coverage-tagging "$SPEC" \
  --dir "$FIX_DIR" \
  --tag '`[integration]`' --row FR1 "the FR1 text" "the FR1 criterion" "Story 1" '✓' \
  --tag '`[target]`'      --row FR2 "the FR2 text" "the FR2 criterion" "Story 1" '✓' \
  --tag '`[manual]`'      --row FR3 "the FR3 text" "the FR3 criterion" "Story 2" '' \
                          --row FR4 "the FR4 text" "the FR4 criterion" "Story 2" '' \
  --tag '`[feature]`'     --row "(story-originated)" "—" "a criterion with no requirement" "Story 2" '✓' \
                          --row "FR2, FR3" "two requirements at once" "the criterion claiming both" "Story 3" '')

# The last row above is not about tags. It is here so the run emits an `UNRESOLVED` record,
# which makes the record-type correspondence at the end of this file cover every type the
# script can produce. Without it that check passes on a skill table missing the type
# entirely — verified by removing the row from the table and watching it stay green.

# The tag cell a given row carries, read out of the matrix document itself. Column 6 of the
# table body, counting from the first cell after the leading pipe.
matrix_tag_for() {
  awk -F'|' -v want="$1" '
    /^\|[[:space:]]*[0-9]+[[:space:]]*\|/ {
      label = $3
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", label)
      if (label != want) next
      tag = $7
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", tag)
      gsub(/`/, "", tag)
      print tag
      exit
    }
  ' "$MATRIX"
}

# The tag field of the record a given label produced, from the parse library.
record_tag_for() {
  coverage_matrix_rows "$MATRIX" | awk -F'\t' -v want="$1" '$3 == want { print $7; exit }'
}

# --- Controls ------------------------------------------------------------------------

test_start "control: the fixture matrix parsed into records"
ROWS=$(coverage_matrix_rows "$MATRIX")
assert_equals "6" "$(printf '%s\n' "$ROWS" | grep -c .)"

# Five rows, five distinct tag values — four tags and the `—` of the untagged row. A parser
# returning one value for every row would satisfy the round trip below on any single label.
test_start "control: the fixture wrote distinguishable tags, not one repeated value"
assert_equals "5" "$(printf '%s\n' "$ROWS" | awk -F'\t' '{ print $7 }' | LC_ALL=C sort -u | grep -c .)"

# --- The round trip: document cell in, record field out ------------------------------

for label in FR1 FR2 FR3 FR4; do
  test_start "$label's record carries the tag its matrix row was written with"
  assert_equals "$(matrix_tag_for "$label")" "$(record_tag_for "$label")"
done

# The extraction reads the matrix too, so a positive control is needed that it is finding
# real cells rather than agreeing with itself on empty strings.
test_start "control: the tags read out of the document are non-empty and distinct"
DOC_TAGS=$(for label in FR1 FR2 FR3; do matrix_tag_for "$label"; done | LC_ALL=C sort -u)
assert_equals "3" "$(printf '%s\n' "$DOC_TAGS" | grep -c .)"

# --- Off-by-one: the field lands where it is documented ------------------------------

test_start "the tag is the seventh field, after verified rather than instead of it"
assert_equals "verified	[target]" \
  "$(printf '%s\n' "$ROWS" | awk -F'\t' '$3 == "FR2" { printf "%s\t%s", $6, $7 }')"

test_start "an untagged row reports the cell it has, not the neighbouring column"
assert_equals "—" "$(record_tag_for FR4)"

test_start "control: FR4's covered-by is still its own, so nothing shifted left"
assert_equals "Story 2" \
  "$(printf '%s\n' "$ROWS" | awk -F'\t' '$3 == "FR4" { print $5 }')"

# Backticks are markup, not tag. A consumer comparing against `[target]` must not have to
# know how the column renders.
test_start "the tag arrives without the backticks the column renders it in"
assert_not_contains "$(printf '%s\n' "$ROWS" | awk -F'\t' '{ print $7 }')" '`'

test_start "control: the matrix on disk does carry the backticks"
assert_contains "$(cat "$MATRIX")" '`[target]`'

# --- The roll-up records carry it through --------------------------------------------
#
# The parse library is one hop; what a reader sees is the script. A tag extracted correctly
# and dropped on the way out would pass everything above.

OUT=$(coverage_rollup_run --spec "$SPEC" --matrix-dir "$FIX_DIR")

test_start "control: the roll-up emitted rows for this spec"
assert_equals "4" "$(coverage_count_type "$OUT" ROW)"

test_start "a ROW record ends with the tag its matrix row carries"
assert_equals "[target]" \
  "$(printf '%s\n' "$OUT" | awk -F'\t' '$1 == "ROW" && $3 == "FR2" { print $7 }')"

test_start "and a CRITERION record carries one too, in its own last field"
assert_equals "[feature]" \
  "$(printf '%s\n' "$OUT" | awk -F'\t' '$1 == "CRITERION" { print $6 }')"

# The reason the field went on the end. Both consumers inside the script index positionally,
# and an inserted field would move `verified` under them without any of them failing.
test_start "ROW's verified field is still the sixth, where its consumers read it"
assert_equals "verified" \
  "$(printf '%s\n' "$OUT" | awk -F'\t' '$1 == "ROW" && $3 == "FR1" { print $6 }')"

test_start "CRITERION's verified field is still the fifth"
assert_equals "verified" \
  "$(printf '%s\n' "$OUT" | awk -F'\t' '$1 == "CRITERION" { print $5 }')"

# --- The verdict is unchanged by the tag ---------------------------------------------
#
# Reported, not interpreted. A `[target]` row that is ticked is a verified row, and making
# the verdict discount it here would move a judgement out of the skill that states it and
# into the script — while turning every spec with a production-host requirement into one
# that can never reach a clean verdict.

test_start "a tick on a [target] row counts as verified, as it did before the tag existed"
assert_equals "FR3 FR4" \
  "$(printf '%s\n' "$OUT" | awk -F'\t' '$1 == "ROW" && $6 == "unverified" { printf "%s ", $3 }' | sed 's/ $//')"

VERDICT_RC=$(coverage_rollup_rc --spec "$SPEC" --matrix-dir "$FIX_DIR" --verdict)
test_start "control: this fixture has unverified rows, so the verdict is outstanding"
assert_equals "3" "$VERDICT_RC"

ALL_VERIFIED_DIR=$(coverage_fixture_dir tag-verdict)
ALL_SPEC=$(coverage_fixture_spec 71-spec-all-target \
  --dir "$ALL_VERIFIED_DIR" --must FR1 "a requirement about the deployment host")
coverage_fixture_matrix 71-01-coverage-all-target "$ALL_SPEC" \
  --dir "$ALL_VERIFIED_DIR" \
  --tag '`[target]`' --row FR1 "the FR1 text" "the FR1 criterion" "Story 1" '✓' >/dev/null

test_start "a spec whose every row is a ticked [target] still reaches a clean verdict"
assert_equals "0" "$(coverage_rollup_rc --spec "$ALL_SPEC" --matrix-dir "$ALL_VERIFIED_DIR" --verdict)"

# --- The field has a reader --------------------------------------------------------
#
# A field nothing is told to use is the original defect relocated: the distinction would be
# in the records instead of the matrix and still invisible to everyone. `cpm:status` is the
# skill that renders these records for a human, so it is where the instruction has to land.

STATUS_SKILL="$SCRIPT_DIR/../../skills/status/SKILL.md"

status_record_table() {
  sed -n '/^| Type | Fields |$/,/^$/p' "$STATUS_SKILL"
}

test_start "control: the cpm:status record table was found"
assert_equals "non-empty" "$( [ -n "$(status_record_table)" ] && echo non-empty || echo empty )"

# Every type the script emits appears in the table the skill documents. Read from a live run
# rather than listed here, so a type added to the script and not to the skill fails.
test_start "every record type the roll-up emits is documented in cpm:status"
UNDOCUMENTED=""
for t in $(printf '%s\n' "$OUT" | awk -F'\t' '{ print $1 }' | LC_ALL=C sort -u); do
  printf '%s' "$(status_record_table)" | grep -q "\`$t\`" || UNDOCUMENTED="$UNDOCUMENTED $t"
done
assert_empty "$UNDOCUMENTED"

test_start "control: that check would notice a type the table omits"
if printf '%s' "$(status_record_table)" | grep -q '`NOTAREALTYPE`'; then
  test_fail "the table matched a record type that does not exist, so it matches anything"
else
  test_pass
fi

# Documented in the table is not the same as acted on. The rendering rules are where the
# skill says what a reader is told, and a tag reported without saying what it means is a
# column of jargon beside a wall of green.
test_start "cpm:status states what a [target] or [manual] tick rests on"
RENDER_RULES=$(sed -n '/^\*\*Render it like this:\*\*$/,/^#### The stakeholder page/p' "$STATUS_SKILL")
if printf '%s' "$RENDER_RULES" | grep -q 'target\]' \
  && printf '%s' "$RENDER_RULES" | grep -q 'manual\]'; then
  test_pass
else
  test_fail "the rendering rules name neither tag, so the field is reported and unexplained"
fi

test_start "control: the rendering-rules slice is bounded"
assert_slice_bounded "$STATUS_SKILL" \
  '^\*\*Render it like this:\*\*$' '^#### The stakeholder page' 8 20

test_summary
