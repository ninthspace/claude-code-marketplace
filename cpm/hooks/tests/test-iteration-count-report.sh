#!/bin/bash
# test-iteration-count-report.sh — Epic 45-04 Story 3: report the roll-up's counts every
# iteration (spec 45 FR11 and its must-NOT).
#
# --- What the criterion turned into --------------------------------------------------
#
# FR11 originally carried an N-iteration non-convergence threshold. The 2026-07-27 pivot
# withdrew it: `69320ef` made exit 4 the only route into `/cpm:epics`, so a phase that cannot
# progress now stops rather than repeats, and a threshold would guard a case the loop can no
# longer reach. What is left is the reporting half — make a run that is neither stalled nor
# finished visible *while it is running* — and a must-NOT that is an ordering claim: the loop
# may not branch on the counts without having reported them in the same iteration.
#
# --- What has an oracle here ---------------------------------------------------------
#
# **The field names are a correspondence, not a pin.** FR11 asks for "the traced and verified
# counts it read from the roll-up", and the roll-up emits neither of those words. Its
# spec-scope SUMMARY record carries `requirements`, `untraced`, `delivered` and `in-progress`,
# and the clause names those four verbatim because computing a *traced* or *verified* figure
# from them is exactly what `ralph/SKILL.md`'s "the loop relays; it does not compute" rule
# forbids. So the assertion derives the field list from `coverage-rollup.sh`'s own record
# documentation and from the clause, and compares — a rename on both sides stays green, which
# is what a correspondence is for, and a clause that drops a field fires.
#
# The comparison drops `scope`, the record's one non-numeric field, and that exclusion is not
# taken on trust: a real run is made and asserted to put the literal `spec` in that position
# and integers in the other four. A filter that removed a field the assertion exists to catch
# would be retro 31's near-miss repeated, so the filter is the one the data justifies.
#
# **The must-NOT is an ordering claim, which retro 27 showed is offset arithmetic.** Both
# sentences are located in the clause with `grep -bo` and their byte positions compared. A
# control swaps them and re-runs the same comparison. This needs no running loop, and the
# alternative — asserting both sentences merely exist — is satisfied by a clause that reports
# after it has already branched, which is the defect the must-NOT names.
#
# --- What this suite does not test ----------------------------------------------------
#
# That any loop prints the line. Nothing here launches one, and no executable in this
# repository reads the prompt. The counts' *availability* is what is checked against the real
# script; obedience is not checkable here and is not claimed.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/coverage-fixture-helpers.sh"

RALPH_SKILL="$SCRIPT_DIR/../../skills/ralph/SKILL.md"
ROLLUP_SRC="$SCRIPT_DIR/../lib/coverage-rollup.sh"

echo "Testing: the per-iteration count report (Epic 45-04 Story 3)"
echo "==========================================================="

phase_clause() { grep -F 'Work spec {spec_path} to completion.' "$1"; }

PHASE=$(phase_clause "$RALPH_SKILL")

test_start "control: the skill carries exactly one spec-mode phase clause"
assert_equals "1" "$(printf '%s\n' "$PHASE" | grep -c .)"

# --- Criterion 1: the counts reported are the ones the roll-up emits ------------------
#
# Script side: the documented spec-scope SUMMARY field list. The header states it twice — once
# in the record catalogue, once above the derived-records block — so the two copies are checked
# against each other *before* either is used.
#
# The first version of this took `sort -u` across both copies, on the reasoning that a future
# third copy should not change the answer. It also meant a copy that *disagreed* changed
# nothing: deleting a field from one line left the union intact and the suite green. That was
# found by a one-sided mutation and is retro 30's `sort -u` swallowing a difference, in the
# place the difference mattered most. Agreement first, then use one.

script_summary_lines() {
  grep -E '^#   SUMMARY ' "$ROLLUP_SRC" \
    | sed -e 's/^#   SUMMARY *//' -e 's/  *(.*)$//' -e 's/ *$//'
}

script_summary_fields() {
  script_summary_lines | head -1 \
    | tr ',' '\n' | tr -d ' ' | grep -v '^scope$' | grep . | LC_ALL=C sort
}

test_start "control: coverage-rollup.sh documents the SUMMARY record more than once"
DOC_COPIES=$(script_summary_lines | grep -c .)
if [ "$DOC_COPIES" -ge 2 ]; then
  test_pass
else
  test_fail "found $DOC_COPIES copies, so the agreement check below has nothing to compare"
fi

test_start "and every copy of it names the same fields"
assert_equals "1" "$(script_summary_lines | LC_ALL=C sort -u | grep -c .)"

# Clause side: the labels the COUNTS instruction names, in the order it names them. The
# instruction writes "in progress" where the record writes "in-progress" — the clause is read
# aloud in a log line and the record is tab-delimited data — so the space is normalised. That
# is the only normalisation applied, and it is one-directional.

clause_summary_fields() {
  printf '%s\n' "$PHASE" \
    | grep -o 'COUNTS: [^.]*' | sed 's/^COUNTS: //' \
    | tr ',' '\n' \
    | sed -e 's/^ *//' -e 's/^[A-Z] //' -e 's/in progress/in-progress/' \
    | grep -E '^[a-z-]+$' | LC_ALL=C sort -u
}

SCRIPT_FIELDS=$(script_summary_fields | tr '\n' ' ' | sed 's/ $//')
CLAUSE_FIELDS=$(clause_summary_fields | tr '\n' ' ' | sed 's/ $//')

assert_agrees "the SUMMARY count fields" \
  "coverage-rollup.sh's record documentation" "$SCRIPT_FIELDS" \
  "the phase clause's COUNTS line" "$CLAUSE_FIELDS"

test_start "and there are four of them, so a dropped field is a changed set"
assert_equals "4" "$(printf '%s\n' "$CLAUSE_FIELDS" | tr ' ' '\n' | grep -c .)"

# The exclusion of `scope` above, justified against a real run rather than assumed. Field 1
# is the record type, field 2 the scope, fields 3-6 the counts.
C_DIR=$(coverage_fixture_dir counts)
C_SPEC=$(coverage_fixture_spec 81-spec-counts --dir "$C_DIR" \
  --must FR1 "a verified requirement" \
  --must FR2 "a requirement with an unverified row" \
  --must FR3 "a requirement with no row at all")
coverage_fixture_matrix 81-01-coverage-counts \
  "docs/specifications/81-spec-counts.md" --dir "$C_DIR" \
  --row FR1 "a verified requirement" "the FR1 criterion" "Story 1" '✓' \
  --row FR2 "a requirement with an unverified row" "the FR2 criterion" "Story 1" '' \
  >/dev/null

SUMMARY_REC=$(coverage_rollup_run --spec "$C_SPEC" --matrix-dir "$C_DIR" \
  | awk -F'\t' '$1 == "SUMMARY"')

test_start "control: the run emits exactly one SUMMARY record to read the counts from"
assert_equals "1" "$(printf '%s\n' "$SUMMARY_REC" | grep -c .)"

test_start "its scope field is a name, which is why it is not one of the four counts"
assert_equals "spec" "$(printf '%s\n' "$SUMMARY_REC" | cut -f2)"

test_start "and its other four fields are numbers, which is why they are"
NON_NUMERIC=$(printf '%s\n' "$SUMMARY_REC" | cut -f3-6 | tr '\t' '\n' | grep -vE '^[0-9]+$')
assert_empty "$NON_NUMERIC"

# A run that is neither stalled nor finished is precisely one where the counts differ from
# each other. Without this the fixture could be all-zeros and the report would be worthless.
test_start "control: the fixture is a mid-flight run, so the counts are not all the same"
assert_equals "3 1 1 1" "$(printf '%s\n' "$SUMMARY_REC" | cut -f3-6 | tr '\t' ' ')"

# --- Criterion 1: reported every iteration, not only at the end -----------------------

test_start "the clause prints the counts every iteration, including the ones that stop"
assert_contains "$PHASE" 'print it every iteration, including the ones that stop'

test_start "and takes the numbers verbatim rather than working them out"
assert_contains "$PHASE" 'working none of them out yourself'

# --- The must-NOT: reported before branched on ----------------------------------------
#
# Retro 27's shape. `grep -bo` gives the byte offset of a match within the clause, so "before"
# is a comparison of two integers rather than something a running loop would have to show.

offset_of() { printf '%s' "$1" | grep -boF "$2" | head -1 | cut -d: -f1; }

REPORT_AT=$(offset_of "$PHASE" 'print one line reading COUNTS')
BRANCH_AT=$(offset_of "$PHASE" 'Exit 1 or 2 means')

test_start "control: both the report sentence and the first branch are located in the clause"
if [ -n "$REPORT_AT" ] && [ -n "$BRANCH_AT" ]; then
  test_pass
else
  test_fail "report offset '$REPORT_AT', branch offset '$BRANCH_AT'"
fi

test_start "the counts are reported before the clause branches on them"
if [ "$REPORT_AT" -lt "$BRANCH_AT" ]; then
  test_pass
else
  test_fail "report at $REPORT_AT, first branch at $BRANCH_AT"
fi

# The swap has to be a real reordering of the two sentences, not a deletion — a deletion would
# make the offsets unreadable and the comparison would fail for the wrong reason.
#
# It is built by exchanging two *positions* in the clause's sentence list, located by short
# substrings, rather than by a `sed` of their full text. The first version of this control did
# the latter and coupled an ordering check to every word in both sentences: renaming one of the
# count fields — a change an ordering control has no business noticing — made the substitution
# silently miss, and the control reported "the swap did not apply". A control that fails for
# reasons outside what it controls for is the failure retro 27 named, arriving inside the
# assertion written to honour it.
swap_sentences() {
  printf '%s' "$1" | awk -v a="$2" -v b="$3" '
    {
      n = split($0, s, /\. /)
      ai = 0; bi = 0
      for (i = 1; i <= n; i++) {
        if (index(s[i], a)) ai = i
        if (index(s[i], b)) bi = i
      }
      if (ai && bi) { t = s[ai]; s[ai] = s[bi]; s[bi] = t }
      out = s[1]
      for (i = 2; i <= n; i++) out = out ". " s[i]
      print out
    }'
}

SWAPPED=$(swap_sentences "$PHASE" 'reading COUNTS' 'Exit 1 or 2 means')

SW_REPORT_AT=$(offset_of "$SWAPPED" 'print one line reading COUNTS')
SW_BRANCH_AT=$(offset_of "$SWAPPED" 'Exit 1 or 2 means')

test_start "control: the swap applied and left both sentences in place"
if [ "$SWAPPED" != "$PHASE" ] && [ -n "$SW_REPORT_AT" ] && [ -n "$SW_BRANCH_AT" ]; then
  test_pass
else
  test_fail "swap produced offsets '$SW_REPORT_AT' and '$SW_BRANCH_AT'"
fi

test_start "control: a clause that reports after branching fails the same comparison"
if [ "$SW_REPORT_AT" -gt "$SW_BRANCH_AT" ]; then
  test_pass
else
  test_fail "after the swap the report was still at $SW_REPORT_AT, before $SW_BRANCH_AT"
fi

test_summary
