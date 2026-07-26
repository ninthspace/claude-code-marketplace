#!/bin/bash
# test-convention-relocation.sh — Tests for the relocation of the Change Type
# Decision convention out of cpm/shared/skill-conventions.md and into
# cpm/skills/do/SKILL.md (spec 43, epic 43-03, Story 1).
#
# The move exists because the shared file is injected in full into every session
# in this repo, and this section had exactly one consumer. See CLAUDE.md's
# "What belongs in cpm/shared/skill-conventions.md".
#
# THE ASSERTION THAT MATTERS IS THE INVERSE ONE. "The section no longer appears
# in the shared file" is satisfied equally by a clean move and by a deletion
# that lost half its rules on the way (retro 18). So the absence assertion is
# paired here with a by-name presence assertion for each of the eight rules the
# section carried, and a negative control proving those eight discriminate.
#
# WHAT THIS SUITE DOES NOT TEST — read this before trusting a green run.
# Three of Story 1's five criteria are [manual]:
#   - that the shared file's reduction is attributable to relocated content
#     rather than removed rules (spec 40's guard clause — the byte count is
#     arithmetic, but what the bytes were is a read);
#   - that the `cpm:quick` consumer claim is resolved the right way, which is a
#     judgement about whether `quick` should carry the gate at all;
#   - the must-NOT on dropping a rule. The eight assertions below are a strong
#     structural proxy for it, and still a proxy: they prove eight literals are
#     present, not that each rule still says what it said. The rule-by-rule
#     before/after read is the oracle, and it was done.
#
# One assertion per test_start (retro 15), so the ratio stays honest.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

DO_SKILL="$SCRIPT_DIR/../../skills/do/SKILL.md"
SHARED="$SCRIPT_DIR/../../shared/skill-conventions.md"
SKILLS_DIR="$SCRIPT_DIR/../../skills"

echo "Testing: Change Type Decision relocation"
echo "======================================="

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

# The eight rules the section carried, as literals distinctive enough that each
# is present only if its rule survived the move.
RULE_1='three response patterns exist'
RULE_2='Wording fix, typo, single-criterion clarification'
RULE_3='Scope change, integration boundary, missing requirement that affects ≥2 stories'
RULE_4='Pattern noticed, codebase discovery, complexity insight'
RULE_5='Both scope change **and** lesson'
RULE_6='**When in doubt, choose pivot.**'
RULE_7='**Inline edit breadcrumb**'
RULE_8='rather than as a freeform "should we change this?" prompt'

# --- Criterion 1, absence half ---

test_start "The section heading is gone from the shared conventions"
assert_equals "0" "$(real_heading_count "$SHARED" '## Change Type Decision')"

test_start "The shared conventions retain no fragment of the section"
# Guards the heading assertion: a move that took the heading and left the matrix
# behind would satisfy it and would leave the duplication the move exists to end.
assert_not_contains "$(cat "$SHARED")" "$RULE_6"

test_start "Negative control: the heading counter can see a heading that is present"
assert_equals "1" "$(real_heading_count "$SHARED" '## Tool Operations')"

# --- Criterion 1, presence half: the eight rules, by name ---

test_start "Rule 1 survived the move: three response patterns"
assert_contains "$(cat "$DO_SKILL")" "$RULE_1"

test_start "Rule 2 survived the move: the inline-edit row"
assert_contains "$(cat "$DO_SKILL")" "$RULE_2"

test_start "Rule 3 survived the move: the pivot row"
assert_contains "$(cat "$DO_SKILL")" "$RULE_3"

test_start "Rule 4 survived the move: the retro-observation row"
assert_contains "$(cat "$DO_SKILL")" "$RULE_4"

test_start "Rule 5 survived the move: the pivot-and-retro row"
assert_contains "$(cat "$DO_SKILL")" "$RULE_5"

test_start "Rule 6 survived the move: when in doubt, choose pivot"
assert_contains "$(cat "$DO_SKILL")" "$RULE_6"

test_start "Rule 7 survived the move: the inline-edit breadcrumb"
assert_contains "$(cat "$DO_SKILL")" "$RULE_7"

test_start "Rule 8 survived the move: the gate is structured, not freeform"
assert_contains "$(cat "$DO_SKILL")" "$RULE_8"

test_start "Negative control: removing any one rule alone makes its check fail"
# One claim — that the eight literals discriminate — checked against each in
# turn. A literal that matched something incidental elsewhere in the file would
# leave its rule unguarded while all eight assertions above stayed green.
UNGUARDED=""
i=1
while [ "$i" -le 8 ]; do
  eval "rule=\$RULE_$i"
  fixture="$TEST_TMPDIR/without-rule-$i.md"
  grep -vF -- "$rule" "$DO_SKILL" > "$fixture"
  grep -qF -- "$rule" "$fixture" && UNGUARDED="$UNGUARDED $i"
  i=$((i + 1))
done
if [ -z "$UNGUARDED" ]; then test_pass; else test_fail "rule literal survived its own removal:$UNGUARDED"; fi

test_start "The section is defined exactly once across the plugin"
assert_equals "1" "$(real_heading_count "$DO_SKILL" '## Change Type Decision')"

# --- Criterion 2: the reference points at the local section ---

test_start "do no longer invokes the section as a shared convention"
assert_not_contains "$(cat "$DO_SKILL")" 'the shared **Change Type Decision** procedure'

test_start "do's Surface change moments bullet points at the local section"
assert_contains "$(grep -F 'Surface change moments explicitly' "$DO_SKILL")" 'the **Change Type Decision** procedure above'

test_start "No skill anywhere still calls it a shared convention"
# The dangling-reference check the absence assertion above cannot make: it looks
# at `do` only, and a stale pointer in any other skill would break at read time.
assert_empty "$(grep -rl 'shared \*\*Change Type Decision\*\*' "$SKILLS_DIR" 2>/dev/null)"

# --- Criterion 4: the cpm:quick consumer claim ---

test_start "The cpm:quick consumer claim is gone from the relocated section"
assert_not_contains "$(cat "$DO_SKILL")" 'change moments during execution (`cpm:do`, `cpm:quick`)'

test_start "Negative control: cpm:quick genuinely never referenced the section"
# The premise criterion 4 rests on. Had `quick` referenced it, dropping the
# claim would have been the wrong resolution rather than the accurate one.
assert_equals "0" "$(grep -c 'Change Type Decision' "$SKILLS_DIR/quick/SKILL.md")"

test_summary
