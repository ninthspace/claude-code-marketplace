#!/bin/bash
# test-autonomous-change-resolution.sh — Tests for the autonomous branch of the
# Change Type Decision gate in cpm/skills/do/SKILL.md (spec 43, epic 43-02).
#
# The branch exists because an autonomous run cannot answer an AskUserQuestion:
# a question posed mid-run is not a session stop, so the ralph stop hook never
# fires and the loop waits out its iteration. The branch resolves the change
# moment instead of presenting it.
#
# WHAT THIS SUITE DOES NOT TEST — read this before trusting a green run.
# Three of Story 1's seven criteria are tagged [manual] because they have no
# automatable oracle, and a grep proxy for any of them would report quality it
# cannot see:
#   - that the three dispositions neither overlap nor leave a change type
#     unhandled (prose coherence);
#   - that the worked example genuinely separates "wrong" from "unmet" rather
#     than merely mentioning both;
#   - that the rule actually prevents amendment on "tests fail" evidence — the
#     rule is prose and its violation is a model behaviour, not a file state.
# Those were verified by reading the finished block in place. What follows is
# the structural half only: the text is present, it sits in the autonomous path
# rather than the interactive one, and the must-NOT holds as a file fact.
#
# Stories 2 and 3 each add one more [manual] criterion; each is named in the
# comment heading its own section below, on the same terms.
#
# One assertion per test_start (retro 15), so the ratio stays honest.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

DO_SKILL="$SCRIPT_DIR/../../skills/do/SKILL.md"

echo "Testing: autonomous change resolution (cpm:do)"
echo "=============================================="

# md_block <file> <start-regex> <end-regex> — the lines from the first match of
# <start-regex> up to (not including) the next match of <end-regex>.
#
# Fence-aware by design: every CPM SKILL.md keeps `##` headings and bullet-shaped
# lines inside its output-format fences, so a slicer that ignored fences could
# pick up template text and report it as skill instruction (retro 17).
# The patterns travel through the environment rather than `awk -v`: -v applies
# escape processing to its value, which silently turns `\*\*` into `**` and
# leaves the match to fail for a reason nothing in the regex explains.
md_block() {
  MD_START="$2" MD_END="$3" awk '
    /^```/ { fence = !fence; next }
    fence  { next }
    $0 ~ ENVIRON["MD_START"]           { inblock = 1 }
    inblock && $0 ~ ENVIRON["MD_END"]  { inblock = 0 }
    inblock { print }
  ' "$1"
}

# Both paths moved out of the Guidelines bullet list and into the `## Change Type Decision`
# section they belong to, so the leading two-space bullet indent is gone and the autonomous
# path now ends at the next `##` heading rather than at the bullet that followed it. The
# claims below are unchanged: what is asserted is which path carries which rule, and that is
# a property of the text, not of where the section sits.
autonomous_block() { md_block "$DO_SKILL" '^\*\*Autonomous mode\*\*' '^## Graceful Degradation'; }
interactive_block() { md_block "$DO_SKILL" '^\*\*Interactive runs\*\*' '^\*\*Autonomous mode\*\*'; }

BLOCK=$(autonomous_block)

# --- The slice itself, before anything is asserted about its contents ---

test_start "The autonomous block is findable in do/SKILL.md"
if [ -n "$BLOCK" ]; then test_pass; else test_fail "autonomous_block matched nothing in $DO_SKILL"; fi

test_start "Negative control: the slice excludes the interactive path's option bullets"
# Without this, every assertion below could be passing on interactive-path text.
assert_not_contains "$BLOCK" "If the user chooses"

test_start "Negative control: the interactive slice is itself non-empty"
# Guards the control above — an empty interactive block would make it vacuous.
if [ -n "$(interactive_block)" ]; then test_pass; else test_fail "interactive_block matched nothing"; fi

# --- Criterion 1: three dispositions, and pivot is never invoked ---

test_start "The autonomous branch names the inline-edit disposition"
assert_contains "$BLOCK" "**Inline edit**"

test_start "The autonomous branch names the retro-observation disposition"
assert_contains "$BLOCK" "**Retro observation only**"

test_start "The autonomous branch names the amend-the-epic disposition"
assert_contains "$BLOCK" "**Amend the epic under execution**"

test_start "The autonomous branch states that /cpm:pivot is never invoked"
assert_contains "$BLOCK" '**`/cpm:pivot` is never invoked from an autonomous run.**'

test_start "The branch disapplies the shared matrix's when-in-doubt-choose-pivot default"
# Without this the matrix's own default contradicts the branch it sits above.
assert_contains "$BLOCK" "when in doubt, choose pivot"

# --- Criterion 3: blast radius ---

test_start "The blast radius names the open epic doc"
assert_contains "$BLOCK" "**open epic doc**"

test_start "The blast radius names the companion coverage matrix"
assert_contains "$BLOCK" "**companion coverage matrix**"

test_start "The blast radius is closed — those two files and no others"
assert_contains "$BLOCK" "and nothing else"

test_start "The blast radius names the source spec among the deferred artefacts"
assert_contains "$BLOCK" "the source spec"

test_start "Amending a criterion resets its coverage-matrix row to unverified"
assert_contains "$BLOCK" "resets its coverage-matrix row to unverified"

# --- Criterion 4: amendment requires a citable contradiction ---

test_start "Amendment is gated on a citable contradiction"
assert_contains "$BLOCK" "**Amendment requires a citable contradiction.**"

test_start "The first admissible citation is a file:line"
assert_contains "$BLOCK" '**`file:line`**'

test_start "The second admissible citation is a named requirement in the source spec"
assert_contains "$BLOCK" "**named requirement in the source spec**"

test_start "The third admissible citation is a conflicting criterion in the same epic"
assert_contains "$BLOCK" "**conflicting criterion in the same epic**"

test_start "The chosen citation is recorded in the breadcrumb"
assert_contains "$BLOCK" "record which one in the breadcrumb"

test_start "Unmet is distinguished from wrong"
assert_contains "$BLOCK" "**A criterion that is merely unmet is not a criterion that is wrong.**"

test_start "Declining to amend has a stated disposition rather than being left open"
assert_contains "$BLOCK" "mark the story blocked"

# --- Criterion 6 (must NOT): no AskUserQuestion in the autonomous path ---

test_start "must NOT: the autonomous path contains no AskUserQuestion"
assert_not_contains "$BLOCK" "AskUserQuestion"

test_start "Negative control: the interactive path does still use an AskUserQuestion"
# Proves the assertion above is discriminating rather than matching a token that
# appears nowhere in this region of the file either way.
assert_contains "$(interactive_block)" "AskUserQuestion"

# =====================================================================
# Story 2 — the **Pivot deferred** breadcrumb, and do:64's agreement
# =====================================================================
#
# Story 2's criterion 2 (do:64 permits the epic-scoped amendment while still
# forbidding spec and upstream edits) is [manual]: whether two sentences agree is
# a claim about meaning. Its structural half is asserted below as a regression
# net — the old contradictory phrasing is gone — but the agreement itself was
# verified by reading both sites together.

# Matched with `grep -xF`, so the literal has to carry the line's leading whitespace as well
# as its content. It sat inside a Guidelines bullet and carried a two-space indent; the block
# now sits at the top level of `## Change Type Decision` and carries none. The five fields
# asserted below are the claim — the indent was never part of it.
FORMAT_LINE='`**Pivot deferred**: {change} → {target artefact} (Story {N}, {YYYY-MM-DD}) — cited: {citation}`'
APPLY_LINE=$(grep -F 'What "apply" means autonomously' "$DO_SKILL")
CANONICAL_INLINE_CHANGE='**Inline change**: {one-line summary} ({YYYY-MM-DD})'
CANONICAL_RETRO_APPLIED='**Retro applied**: {nn} · {category} · {disposition} — {note}'

# --- Criterion 1: the format is defined once, with all five fields ---

test_start "The Pivot deferred format is specified exactly once in do/SKILL.md"
assert_equals "1" "$(grep -cxF "$FORMAT_LINE" "$DO_SKILL")"

test_start "The format carries the change field"
assert_contains "$FORMAT_LINE" '{change}'

test_start "The format carries the target artefact field"
assert_contains "$FORMAT_LINE" '{target artefact}'

test_start "The format carries the story number field"
assert_contains "$FORMAT_LINE" 'Story {N}'

test_start "The format carries the date field"
assert_contains "$FORMAT_LINE" '{YYYY-MM-DD}'

test_start "The format carries the citation field"
assert_contains "$FORMAT_LINE" '{citation}'

test_start "One breadcrumb is required per deferred artefact, not per amendment"
assert_contains "$BLOCK" "One breadcrumb per deferred artefact, not one per amendment"

# --- Criterion 2 (structural half only; agreement itself is [manual]) ---

test_start "The do:64 line is findable"
# Guards the must-NOT below, which would pass vacuously against an empty slice.
if [ -n "$APPLY_LINE" ]; then test_pass; else test_fail "no 'What \"apply\" means autonomously' line in $DO_SKILL"; fi

test_start "do:64 no longer forbids every edit to the epic"
# The old phrasing — "any edit to the epic or spec" — contradicted the branch
# above, which permits exactly one epic-scoped edit.
assert_not_contains "$APPLY_LINE" "any edit to the epic or spec"

test_start "do:64 still forbids edits to the source spec and everything upstream"
assert_contains "$APPLY_LINE" "any edit to the source spec or to any other artefact upstream of the open epic"

test_start "do:64 routes the permitted amendment through the citable-contradiction branch"
assert_contains "$APPLY_LINE" "requires a citable contradiction"

# --- Criterion 3: existing formats unchanged, and the new field is distinct ---

test_start "The Inline change field definition is unchanged"
# Epic 43-03 relocated the Change Type Decision convention out of the shared
# file and into `do`; the definition text came across verbatim. This assertion
# is about the field's *format*, so it follows the definition rather than
# pinning the file that happened to hold it when it was written.
assert_contains "$(grep -F 'Inline edit breadcrumb' "$DO_SKILL")" "$CANONICAL_INLINE_CHANGE"

test_start "The Retro applied field definition is unchanged"
assert_contains "$(grep -F 'Retro applied' "$DO_SKILL")" "$CANONICAL_RETRO_APPLIED"

test_start "A Pivot deferred line is not matched by cpm:retro's Inline change scan"
# retro/SKILL.md decides waivable-clean by scanning for the literal
# `**Inline change**`. A new field that contained that string would silently
# make every deferring epic look as though it carried an inline edit.
SAMPLE='**Pivot deferred**: relax the p95 target → docs/specifications/43-spec.md (Story 2, 2026-07-26) — cited: AD1'
assert_not_contains "$SAMPLE" "Inline change"

test_start "Negative control: a real Inline change line IS matched by that same scan"
assert_contains '**Inline change**: reworded criterion 3 (2026-07-26)' "Inline change"

# =====================================================================
# Story 3 — amendments reported as their own run-summary block
# =====================================================================
#
# Story 3's must-NOT (amendments are not folded into the deferred `**Retro
# applied**` list) is [manual]: whether two blocks are genuinely distinct is a
# claim about meaning, and a run summary is generated text with no file to
# assert against. What is asserted below is the instruction that produces it.

report_block() { md_block "$DO_SKILL" '^4\. \*\*Report\*\*' '^5\. \*\*Next epic check\*\*'; }
REPORT=$(report_block)

test_start "The Step 8 Report step is findable"
if [ -n "$REPORT" ]; then test_pass; else test_fail "report_block matched nothing in $DO_SKILL"; fi

test_start "Negative control: the slice stops before the next-epic check"
assert_not_contains "$REPORT" "Next epic check"

test_start "The Report step defines a criterion-amendments block"
assert_contains "$REPORT" "**Criterion amendments — a third block, reported on its own.**"

test_start "The amendments block is separate from both retro lists"
assert_contains "$REPORT" "separate from both retro lists above"

test_start "Amendments are not folded into the deferred-unreviewed list"
assert_contains "$REPORT" 'Do **not** fold this into the deferred-unreviewed `**Retro applied**` list'

test_start "The block is not indexed off the Pivot deferred fields"
# An amendment citing a conflicting criterion in the same epic defers nothing
# and writes no field, so a field-indexed block would silently omit it.
assert_contains "$REPORT" "Do not index the block off those fields"

test_start "Each amendment reports the criterion as it now stands"
assert_contains "$REPORT" "the criterion as it now stands"

test_start "Each amendment reports the citation that licensed it"
assert_contains "$REPORT" "the citation that licensed the change"

test_start "Each amendment reports the artefacts left out of step"
assert_contains "$REPORT" "every artefact left out of step"

test_start "An empty amendments block is stated rather than omitted"
assert_contains "$REPORT" "No criteria amended"

test_start "The Report step no longer claims cpm:status parses the Retro applied field"
# It reads `**Retro waived**` and story-level `**Retro**:`, and nothing reads
# `**Retro applied**` at all — the claim was false when written (Story 2).
assert_not_contains "$REPORT" "continue to parse them unchanged"

# =====================================================================
# Story 5 — the four encoding sites, asserted together
# =====================================================================
#
# The behaviour is spread across two files and four places, and three of them
# are inert on their own: the loop reads only `ralph`'s prompt template, and
# what that clause defers to is `cpm:do`. A partial landing therefore produces
# no error anywhere — it produces a loop that documents one behaviour and
# performs another. This test exists so a partial landing is a red suite.
#
# Story 5's other criterion (a single end-to-end read finds no contradiction
# between the five sites) is [manual], and no proxy is offered for it here.
# That read is what caught the last three defects in this epic; each time,
# every structural assertion was already green.

RALPH_SKILL="$SCRIPT_DIR/../../skills/ralph/SKILL.md"
# The override table moved out of the skill on 2026-07-28: it is a maintenance record and
# was being loaded on every invocation. The row and the prompt clause now sit in different
# files, which is what this suite has always been checking — that both halves land — and
# the split makes the claim sharper rather than weaker.
RALPH_COUPLING="$SCRIPT_DIR/../../../docs/maintenance/README.md"

# Each site: a label, the file it lives in, and a literal that is present only
# when that site has landed.
site_file() {
  case "$1" in
    autonomous-branch|step-8-amendments) echo "$DO_SKILL" ;;
    ralph-override-row) echo "$RALPH_COUPLING" ;;
    *) echo "$RALPH_SKILL" ;;
  esac
}
site_marker() {
  case "$1" in
    autonomous-branch)   echo '**Amend the epic under execution**' ;;
    step-8-amendments)   echo '**Criterion amendments — a third block, reported on its own.**' ;;
    ralph-override-row)  echo '| Guidelines — Change Type Decision' ;;
    ralph-prompt-clause) echo 'At the do Change Type Decision gate' ;;
  esac
}
SITES="autonomous-branch step-8-amendments ralph-override-row ralph-prompt-clause"

test_start "All four encoding sites are present together"
MISSING=""
for site in $SITES; do
  grep -qF -- "$(site_marker "$site")" "$(site_file "$site")" || MISSING="$MISSING $site"
done
if [ -z "$MISSING" ]; then test_pass; else test_fail "sites not landed:$MISSING"; fi

test_start "Negative control: removing any one site alone makes the check fail"
# One claim — that the check discriminates — verified against every site in
# turn, since a marker that matched something incidental would leave exactly
# one site unguarded and the test above still green.
UNGUARDED=""
for site in $SITES; do
  marker=$(site_marker "$site")
  file=$(site_file "$site")
  fixture="$TEST_TMPDIR/without-$site.md"
  grep -vF -- "$marker" "$file" > "$fixture"
  grep -qF -- "$marker" "$fixture" && UNGUARDED="$UNGUARDED $site"
done
if [ -z "$UNGUARDED" ]; then test_pass; else test_fail "marker survived its own removal:$UNGUARDED"; fi

test_summary
