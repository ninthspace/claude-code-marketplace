#!/bin/bash
# test-disposition-convention.sh — Tests for the Disposition convention in
# cpm/shared/skill-conventions.md and its eight consumers.
#
# The convention is DPM's, ported (quick 1). It says every item a report
# mentions carries one of four dispositions — Fixed, Left alone, Unverified,
# Needs you — named for what the READER must do rather than for what the run
# did.
#
# WHAT MAKES THIS SUITE WORTH HAVING IS THE SECOND CRITERION. In DPM the
# convention is a `###` nested under Conversational Output, which costs nothing
# because a DPM skill reads the whole shared file once per run. CPM's
# Conversational Output is a CORE_SECTIONS entry, and conventions-core.sh emits
# a core section IN FULL, subsections included, into every session in this
# repository. So the placement — a sibling `## Disposition` rather than a child
# of Conversational Output — is the load-bearing part of the port, and it is
# invisible in the file: both placements read as correct prose, and only the
# hook's output tells them apart. Hence the emission assertions below, which
# check the index line names it and the body does not arrive.
#
# WHAT THIS SUITE DOES NOT TEST. That each skill's mapping is the RIGHT one —
# that a `[target]` criterion really is Unverified and a criterion unmet-but-
# continued really is Needs you — is a judgement, not a literal. The assertions
# here prove eight skills reference the convention by name; a reviewer's read is
# the oracle for whether each names its own items correctly.
#
# One assertion per test_start (retro 15), so the ratio stays honest.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

SHARED="$SCRIPT_DIR/../../shared/skill-conventions.md"
CORE_LIB="$SCRIPT_DIR/../lib/conventions-core.sh"
SKILLS_DIR="$SCRIPT_DIR/../../skills"

# The eight skills that close with a report of outcomes, and so consume the
# convention. Every other CPM skill produces a document and hands off.
CONSUMERS="do quick review audit inspect pivot archive clean"

echo "Testing: the Disposition convention"
echo "=================================="

# real_heading_count <file> <heading> — occurrences of <heading> at the start of
# a line and OUTSIDE any code fence. Every CPM SKILL.md keeps `##` headings
# inside its output-format fences (retro 17), so a plain grep would count a
# template heading as a section heading.
real_heading_count() {
  MD_HEADING="$2" awk '
    /^```/ { fence = !fence; next }
    fence  { next }
    index($0, ENVIRON["MD_HEADING"]) == 1 { n++ }
    END { print n + 0 }
  ' "$1"
}

# The `## Disposition` section's own lines, bounded by the next `## `.
disposition_section() {
  awk '
    /^## Disposition$/ { inside = 1; next }
    inside && /^## /   { exit }
    inside             { print }
  ' "$SHARED"
}

SECTION="$(disposition_section)"

# --- Criterion 1: the section exists, and names the four in order ---

test_start "The shared conventions carry a top-level ## Disposition section"
assert_equals "1" "$(real_heading_count "$SHARED" '## Disposition')"

test_start "Control: the section slice is a section and not the rest of the file"
# An awk range that failed to find its end would swallow every section after it,
# and every content assertion below would then pass on someone else's prose.
assert_equals "in-range" "$(
  n=$(echo "$SECTION" | grep -c .)
  [ "$n" -ge 10 ] && [ "$n" -le 40 ] && echo in-range || echo "$n lines"
)"

test_start "The four dispositions are defined, in the order a report renders them"
assert_equals "Fixed|Left alone|Unverified|Needs you" "$(
  echo "$SECTION" | sed -n 's/^- \*\*\([^*]*\)\*\*.*/\1/p' | paste -sd'|' -
)"

test_start "Negative control: the label extractor reads the file and not a literal"
# Guards the assertion above. If the bullet format changed, the extractor would
# return nothing, and an empty string compared against an expected empty string
# is the green-on-nothing failure retro 30 records.
assert_equals "non-empty" "$(
  v=$(echo "$SECTION" | sed -n 's/^- \*\*\([^*]*\)\*\*.*/\1/p')
  [ -n "$v" ] && echo non-empty || echo empty
)"

# --- Criterion 4: the four rules that give the convention teeth ---

test_start "Rule: the label follows the reader's obligation, not the run's action"
assert_contains "$SECTION" "The label follows the reader's obligation, not your action."

test_start "Rule: an item fitting none of the four is not reported"
assert_contains "$SECTION" "An item that fits none of the four is not reported."

test_start "Rule: a disposition with no items renders no heading at all"
assert_contains "$SECTION" "A disposition with no items is not rendered at all"

test_start "Rule: Unverified is structural, so a run-level failure is Needs you"
assert_contains "$SECTION" "Unverified means the check is impossible in this environment"

# --- Criterion 2: the placement, which is the whole of the port ---

test_start "CORE_SECTIONS does not name Disposition"
assert_not_contains "$(cat "$CORE_LIB")" "Disposition"

EXTRACT="$(bash "$CORE_LIB" "$SHARED")"

test_start "Control: the extract emits a core section's body"
# Without this, the two assertions below are satisfied by an emitter that
# produced nothing at all.
assert_contains "$EXTRACT" "Aim for the shortest response that does the job."

test_start "The extract names Disposition in its section index"
assert_contains "$EXTRACT" "Disposition"

test_start "The extract does not carry the Disposition section's body"
assert_not_contains "$EXTRACT" "it is waiting on the reader, and nothing else in the report is"

test_start "Disposition is not nested inside Conversational Output"
# The inverse of the assertion above, read from the file rather than from the
# hook: a `### Disposition` under Conversational Output would be emitted in full
# by a hook that never mentions the word, so CORE_SECTIONS staying clean does
# not by itself prove the placement.
assert_equals "0" "$(real_heading_count "$SHARED" '### Disposition')"

# --- Criterion 3: the eight consumers reference it by name ---

for skill in $CONSUMERS; do
  test_start "cpm:$skill instructs its report to use the convention"
  assert_contains "$(cat "$SKILLS_DIR/$skill/SKILL.md")" '**Disposition**'
done

test_start "Negative control: a skill that reports no outcomes does not reference it"
# `brief` produces a document and hands off; it has nothing to disposition. If
# this fails, the reference has been pasted rather than placed.
assert_not_contains "$(cat "$SKILLS_DIR/brief/SKILL.md")" '**Disposition**'

test_start "No skill restates the four definitions in place of referencing them"
# The shared file holds the definitions; a skill that copies them is the copy
# nobody reconciles when this one changes. A skill naming three or more of the
# labels in bold is reproducing the list rather than naming its own items.
COPIERS=""
for skill in $CONSUMERS; do
  hits=0
  for label in 'Fixed' 'Left alone' 'Unverified' 'Needs you'; do
    grep -qF -- "- **$label**" "$SKILLS_DIR/$skill/SKILL.md" && hits=$((hits + 1))
  done
  [ "$hits" -ge 3 ] && COPIERS="$COPIERS $skill"
done
assert_empty "$COPIERS"

test_summary
