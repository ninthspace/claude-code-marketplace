#!/bin/bash
# test-ralph-phase-predicate.sh — Tests for the AD1 phase predicate contract
# (Epic 45-03 Story 2, spec 45 FR8 and NFR2, and their two must-NOTs).
#
# --- What has an oracle here ------------------------------------------------------------
#
# The story's claim is that the phase judgement is a *reading of the roll-up's records*, so
# the assertion worth making is a correspondence: the record and field the contract tells the
# loop to read are the record and field the script actually emits, and the field it names is
# the one that behaves the way the contract says it behaves.
#
#   * **The field name is looked up, not asserted.** The section names a `SUMMARY` field; its
#     position comes from the script's own documented record format, and its values come from
#     three real runs. Renaming the field on either side breaks the lookup.
#   * **The field is discriminated behaviourally.** Phase 1 is about *tracing* and phase 2
#     about *verification*, and `untraced` is the only SUMMARY field that moves with the first
#     and holds still under the second. So the fixtures vary those two axes independently: the
#     named field must differ between traced and untraced, and must not differ between
#     verified and unverified. Naming `delivered` instead — a wrong edit that reads perfectly
#     — fails the second half, and the control asserts exactly that.
#
# --- What is evidence rather than proof ---------------------------------------------------
#
# Both must-NOTs. "Does not infer phase from the epic files" and "does not derive traced or
# verified state" are claims about what a document *doesn't* instruct, and a document can
# describe a derivation without using any of the words this suite looks for. What is checkable
# is that every sentence in the contract mentioning the epic files, or pairing a state word
# with a computing verb, denies it rather than instructs it — and that the check moves when a
# realistic wrong edit is made, which is what the mutation controls demonstrate. Retro 21's
# shape governs the phrasing: the sentences stating these rules must write the very tokens the
# rules forbid, so the negatives are scoped to sentences and read with their denials.
#
# Nothing here launches a loop. Whether `cpm:ralph` actually reads the records at runtime is
# unasserted and unassertable by this suite.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/coverage-fixture-helpers.sh"

RALPH_SKILL="$SCRIPT_DIR/../../skills/ralph/SKILL.md"
ROLLUP="$SCRIPT_DIR/../lib/coverage-rollup.sh"

echo "Testing: ralph's phase predicate reads the roll-up's records (Epic 45-03 Story 2)"
echo "================================================================================"

# --- Slice --------------------------------------------------------------------------------

PRED_START='^#### The phase predicate'
# The next heading of any level, not `**Template**`. The old terminator assumed this section
# was permanently the last thing before the template block, which is a claim about the file's
# layout rather than about the predicate — and it stopped being true the moment a sibling
# section was added between them, at which point every assertion below silently widened to
# cover that section's prose too.
#
# `\{1,\}` and not `\+`: this is a BRE fed to `sed`, where `\+` is a literal plus and the
# pattern silently never matches — which does not fail, it runs the slice to end-of-file and
# passes every `assert_contains` against the whole document. The `^#+ ` form elsewhere in
# this directory is correct because those are `awk`, which is ERE.
PRED_END='^#\{1,\} '
predicate_slice() { sed -n "/$PRED_START/,/$PRED_END/p" "$1"; }

test_start "slice: the phase predicate section spans its own block and no more"
assert_slice_bounded "$RALPH_SKILL" "$PRED_START" "$PRED_END" 3 10

SLICE=$(predicate_slice "$RALPH_SKILL")

# --- Criterion 1: the judgement comes from the roll-up's records ---------------------------
#
# The command first: the section names one, and it has to be one the script accepts. A flag
# the script rejects would make the whole contract unreachable while reading correctly.

CITED_FLAGS=$(printf '%s\n' "$SLICE" | grep -oE ' --[a-z-]+' | tr -d ' ' | sort -u | tr '\n' ' ')

test_start "the section names the roll-up command with its scope and verdict flags"
assert_equals "--spec --verdict " "$CITED_FLAGS"

# Fixtures. One spec, three matrix directories, varying tracing and verification separately:
#
#   A  both requirements traced, both rows verified   → nothing outstanding
#   B  one requirement traced                          → differs from A in tracing only
#   C  both traced, one row unverified                 → differs from A in verification only
FX=$(coverage_fixture_dir phase-predicate)
SPEC=$(coverage_fixture_spec 80-spec-phase-predicate --dir "$FX" \
  --must FR1 "the first requirement" \
  --must FR2 "the second requirement")
SPEC_REF="docs/specifications/80-spec-phase-predicate.md"

A_DIR=$(coverage_fixture_dir phase-predicate-clean)
coverage_fixture_matrix 80-01-coverage-clean "$SPEC_REF" --dir "$A_DIR" \
  --epic "$A_DIR/80-01-epic-clean.md" \
  --row FR1 "the first requirement" "the FR1 criterion" "Story 1" '✓' \
  --row FR2 "the second requirement" "the FR2 criterion" "Story 1" '✓' >/dev/null
: > "$A_DIR/80-01-epic-clean.md"

B_DIR=$(coverage_fixture_dir phase-predicate-untraced)
coverage_fixture_matrix 80-01-coverage-untraced "$SPEC_REF" --dir "$B_DIR" \
  --epic "$B_DIR/80-01-epic-untraced.md" \
  --row FR1 "the first requirement" "the FR1 criterion" "Story 1" '✓' >/dev/null
: > "$B_DIR/80-01-epic-untraced.md"

C_DIR=$(coverage_fixture_dir phase-predicate-unverified)
coverage_fixture_matrix 80-01-coverage-unverified "$SPEC_REF" --dir "$C_DIR" \
  --epic "$C_DIR/80-01-epic-unverified.md" \
  --row FR1 "the first requirement" "the FR1 criterion" "Story 1" '✓' \
  --row FR2 "the second requirement" "the FR2 criterion" "Story 1" '-' >/dev/null
: > "$C_DIR/80-01-epic-unverified.md"

# Each run is the command the section names, against one of the three directories.
run_predicate() {
  PRED_OUT=$(run_without_env CLAUDE_PROJECT_DIR -- \
    bash "$ROLLUP" --spec "$SPEC" --matrix-dir "$1" --verdict 2>/dev/null)
  PRED_RC=$?
}

run_predicate "$A_DIR"; A_OUT="$PRED_OUT"; A_RC="$PRED_RC"
run_predicate "$B_DIR"; B_OUT="$PRED_OUT"; B_RC="$PRED_RC"
run_predicate "$C_DIR"; C_OUT="$PRED_OUT"; C_RC="$PRED_RC"

# The record type the section names, checked against the records the script emits.
CITED_RECORD=$(printf '%s\n' "$SLICE" | grep -oE '`[A-Z][A-Z]+`' | tr -d '`' | sort -u)

test_start "the section names exactly one record type"
assert_equals "SUMMARY" "$CITED_RECORD"

test_start "and the script emits a record of that type"
assert_contains "$(printf '%s\n' "$A_OUT" | cut -f1 | sort -u)" "$CITED_RECORD"

test_start "control: a record type the script never emits is not found among them"
assert_not_contains "$(printf '%s\n' "$A_OUT" | cut -f1 | sort -u)" "TOTALS"

# The field's position is read out of the script's own documented record format rather than
# counted here — the format is what a consumer is entitled to rely on, and re-typing the
# index is how epic 44-01's awk read every verdict one field to the left.
CITED_FIELD=$(printf '%s\n' "$SLICE" | grep -oE '`[a-z-]+` field' | head -1 | sed 's/`\([a-z-]*\)`.*/\1/')
FORMAT_LINE=$(sed -n "s/^#   $CITED_RECORD  *\(.*\)  *(spec scope)\$/\1/p" "$ROLLUP")
FIELD_INDEX=$(printf '%s\n' "$FORMAT_LINE" | tr ',' '\n' | sed 's/^ *//; s/ *$//' |
  grep -n "^$CITED_FIELD\$" | cut -d: -f1)
FIELD_INDEX=$((FIELD_INDEX + 1))

test_start "the field the section names is a documented field of that record"
if [ "$FIELD_INDEX" -gt 1 ]; then
  test_pass
else
  test_fail "'$CITED_FIELD' is not in the documented $CITED_RECORD format: $FORMAT_LINE"
fi

field_of() { printf '%s\n' "$1" | awk -F'\t' -v r="$CITED_RECORD" -v i="$2" '$1 == r { print $i }'; }

A_FIELD=$(field_of "$A_OUT" "$FIELD_INDEX")
B_FIELD=$(field_of "$B_OUT" "$FIELD_INDEX")
C_FIELD=$(field_of "$C_OUT" "$FIELD_INDEX")

test_start "control: the three runs each emit that record with a value"
if [ -n "$A_FIELD" ] && [ -n "$B_FIELD" ] && [ -n "$C_FIELD" ]; then
  test_pass
else
  test_fail "field $FIELD_INDEX read as '$A_FIELD' / '$B_FIELD' / '$C_FIELD'"
fi

# Phase 1's predicate, in the section's own words: the field reads `0` when the epics exist.
test_start "the named field reads 0 when every requirement is traced"
assert_equals "0" "$A_FIELD"

test_start "and moves when a requirement has no row — the tracing axis"
if [ "$A_FIELD" != "$B_FIELD" ]; then
  test_pass
else
  test_fail "traced and untraced fixtures both report $CITED_FIELD=$A_FIELD"
fi

test_start "and holds still when a row is unverified — not the verification axis"
assert_equals "$A_FIELD" "$C_FIELD"

# Without this control the pair above is satisfied by any field that happens to differ, and
# by `delivered` in particular — which is the wrong edit that reads perfectly.
test_start "control: another field of the same record fails that pair, so the pair discriminates"
OTHER_MOVES=0
i=2
while [ "$i" -le "$(printf '%s\n' "$FORMAT_LINE" | tr ',' '\n' | grep -c .)" ]; do
  i=$((i + 1))
  [ "$i" = "$FIELD_INDEX" ] && continue
  OTHER_A=$(field_of "$A_OUT" "$i")
  OTHER_C=$(field_of "$C_OUT" "$i")
  [ "$OTHER_A" != "$OTHER_C" ] && OTHER_MOVES=$((OTHER_MOVES + 1))
done
if [ "$OTHER_MOVES" -gt 0 ]; then
  test_pass
else
  test_fail "no other $CITED_RECORD field moves between the verified and unverified runs"
fi

# Phase 2's predicate is the exit code, and the section states which one.
CITED_EXIT=$(printf '%s\n' "$SLICE" | sed -n 's/.*exits `\([0-9]\)`.*/\1/p' | head -1)

test_start "the section names the exit code that ends phase 2"
assert_equals "0" "$CITED_EXIT"

test_start "and the script returns it when every row is verified"
assert_equals "$CITED_EXIT" "$A_RC"

test_start "control: it returns something else while a row is unverified"
if [ "$C_RC" != "$CITED_EXIT" ]; then
  test_pass
else
  test_fail "the unverified fixture also exited $C_RC"
fi

# --- The two must-NOTs, and the relay claim ------------------------------------------------
#
# Sentence-scoped, because the sentences stating these rules have to write the tokens the
# rules forbid. A sentence *mentions* something and either denies it or instructs it; only the
# second is a violation.

sentences() { printf '%s\n' "$1" | tr '\n' ' ' | sed 's/\. /.\n/g'; }

denied() { printf '%s\n' "$1" | grep -qiE 'never|not consulted|says nothing|no marker|rather than'; }

# Sentences that make the epic files an input to the phase decision.
file_inference() {
  local s
  while IFS= read -r s; do
    printf '%s\n' "$s" | grep -qiE 'docs/epics|epic files|epic list|\{epic_count\}|count of files' || continue
    denied "$s" && continue
    printf '%s\n' "$s"
  done < <(sentences "$(predicate_slice "$1")")
}

# Sentences that pair a requirement-state word with a verb that computes it. The verbs are
# matched as whole words: an unbounded `sum` matches inside `SUMMARY`, which is the record
# the contract is *supposed* to name, and the predicate reported the correct sentence as a
# violation on its first run.
DERIVE_VERBS='counts?|counting|computes?|computing|derives?|deriving|tall(y|ies)|sums?|summing|works? .* out'
state_derivation() {
  local s
  while IFS= read -r s; do
    printf '%s\n' "$s" | grep -qiE 'untraced|unverified|verified|traced|rows' || continue
    printf '%s\n' "$s" | grep -qiE "(^|[^[:alpha:]])($DERIVE_VERBS)([^[:alpha:]]|\$)" || continue
    denied "$s" && continue
    printf '%s\n' "$s"
  done < <(sentences "$(predicate_slice "$1")")
}

test_start "must NOT infer phase from the presence or count of epic files"
assert_empty "$(file_inference "$RALPH_SKILL")"

test_start "must NOT derive traced or verified state from the records"
assert_empty "$(state_derivation "$RALPH_SKILL")"

test_start "the section states that the loop relays the fields it read"
assert_contains "$SLICE" "It names the fields it read and repeats their values"

# The controls. Each mutation is a concrete wrong edit — the clause someone would actually
# write — run through the identical predicate.
MUTANT_FILES="$TEST_TMPDIR/ralph-infers-from-files.md"
awk -v ins="If \`docs/epics/\` holds no matching files, the run is in phase 1." '
  { print }
  /^#### The phase predicate$/ && !done { print ""; print ins; done = 1 }' \
  "$RALPH_SKILL" > "$MUTANT_FILES"

test_start "control: a clause reading phase off the epic directory is detected"
if [ -n "$(file_inference "$MUTANT_FILES")" ]; then
  test_pass
else
  test_fail "the inserted clause was not reported"
fi

MUTANT_DERIVE="$TEST_TMPDIR/ralph-derives-state.md"
sed 's/it never counts rows, sums a column/count the verified rows and compare them to the total/' \
  "$RALPH_SKILL" > "$MUTANT_DERIVE"

test_start "control: the mutation edited the sentence it was aimed at"
if ! diff -q "$RALPH_SKILL" "$MUTANT_DERIVE" >/dev/null; then
  test_pass
else
  test_fail "the derivation mutation changed nothing"
fi

test_start "control: an instruction to count the rows itself is detected"
if [ -n "$(state_derivation "$MUTANT_DERIVE")" ]; then
  test_pass
else
  test_fail "the counting instruction was not reported"
fi

test_summary
