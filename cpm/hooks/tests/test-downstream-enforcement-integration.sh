#!/bin/bash
# test-downstream-enforcement-integration.sh — Epic 46-03 Story 4: cross-story integration.
#
# The two [integration] criteria of "Verify cross-story integration for Downstream Enforcement":
# the four-way agreement of the automated tag set (AD6), and the byte budget (NFR6). The story's
# third criterion — that the new elicitation sub-step converges in 1–2 AskUserQuestion rounds — is
# tagged [manual] on the story and has no oracle here.
#
# --- Criterion 1: which site in each skill, and what that does not cover -------------
#
# Four skills name the automated tag set, and most of them name it in more than one place.
# `cpm:epics` alone names it at five sites. This suite reads **one designated site per skill** —
# the operative one, where the set decides what the skill does rather than merely describing it:
#
#   spec   the Default-to-automation rule, which is what proposes a tag in the first place
#   epics  the auto-generated-testing-task check, which is what a criterion's tag decides
#   do     the per-criterion routing map's automated branch, which selects run-tests over
#          self-assess — the same branch list Story 3's suite proved total
#   ralph  the autonomous prompt's completion clause
#
# A second site in the same skill drifting away from its operative one is **not covered**, and
# there is no sound mechanical way to add that here. The obvious rule — "every line naming a set
# of level tags" — over-collects (`cpm:epics` line 464's worked example names `[unit]`,
# `[integration]` and `[manual]` together, quite correctly, because it is an illustration of a
# result rather than a statement of the set). The repair for that over-collection is worse than
# the disease: filtering to lines whose level-tag set has exactly three members *defines away*
# any line that dropped one, so the check could never fail. That is retro 30's vacuity in a new
# shape, and it is named here rather than shipped.
#
# --- Criterion 2: the byte budget, and why this assertion will age ------------------
#
# NFR6 asks that "the bytes added to each skill file are stated and asserted". The statement is
# the delta table in the epic doc; the assertion is below. Two independent things are checked,
# and only the second is durable:
#
#   * the table's `After` column against the files as they are now — a **point-in-time** check.
#     Any later change to any of the five skills fails it, correctly, because the stated figure
#     stops being the measured one. The remedy is a fresh baseline row, not a looser assertion.
#   * the table's internal arithmetic, and its agreement with the prose baseline sentence written
#     separately above it — durable, and the half that catches the realistic failure. Retro 24's
#     lesson was a stated figure nothing derived from the real thing; hand arithmetic across a
#     five-row table and a prose sentence is exactly where that recurs.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel 2>/dev/null)"

SPEC_SKILL="$SCRIPT_DIR/../../skills/spec/SKILL.md"
EPICS_SKILL="$SCRIPT_DIR/../../skills/epics/SKILL.md"
DO_SKILL="$SCRIPT_DIR/../../skills/do/SKILL.md"
RALPH_SKILL="$SCRIPT_DIR/../../skills/ralph/SKILL.md"
EPIC_DOC="$REPO_ROOT/docs/epics/46-03-epic-downstream-enforcement.md"

echo "Testing cross-story integration for downstream enforcement (Epic 46-03 Story 4)"

test_start "control: the repository root resolves, so the assertions below have a subject"
assert_contains "$REPO_ROOT" "/"

# --- Criterion 1: every skill that names the automated tag set names the same set --------
#
# Each extraction is scoped to the tags on its own designated statement, so a skill that named a
# fourth tag there would disagree with the other three rather than being filtered out.

tags_of() { grep -o '\[[a-z]*\]' | tr -d '[]' | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ $//'; }

# The rule paragraph names `[manual]` too, in the sentence *after* the automation default —
# correctly, since its job is to say when not to automate. The slice ends where that sentence
# begins, which is a boundary decision and is why the control below asserts it stayed bounded.
spec_automated() {
  grep '\*\*Default to automation\*\*' "$SPEC_SKILL" \
    | sed 's/.*\*\*Default to automation\*\* —//; s/\. Propose .*//'
}

epics_automated() {
  grep '^\*\*Auto-generated testing tasks\*\*' "$EPICS_SKILL"
}

# The routing map's automated branch, found by what the branch *does* rather than by the tags it
# names — the same derivation Story 3's suite uses, for the same reason: a branch located by its
# tag names cannot report that the names changed.
do_automated() {
  sed -n '/^- For each criterion, assess whether/,/^- If all criteria are met/p' "$DO_SKILL" \
    | grep 'use the pass/fail result as evidence' | sed 's/\*\*:.*//'
}

ralph_automated() {
  grep -o 'all tagged criteria ([^)]*)' "$RALPH_SKILL"
}

# Bounded before it is trusted. The spec slice is a substring cut out of a long paragraph by two
# `sed` substitutions; if the trailing one stopped matching, the slice would silently grow to
# include `[manual]` and every comparison below would fail for a reason that reads like drift.
test_start "control: the spec slice stops before the sentence that introduces [manual]"
assert_not_contains "$(spec_automated)" "manual"

SPEC_AUTO=$(spec_automated | tags_of)
EPICS_AUTO=$(epics_automated | tags_of)
DO_AUTO=$(do_automated | tags_of)
RALPH_AUTO=$(ralph_automated | tags_of)

assert_agrees "the automated tag set" \
  "cpm:spec's default-to-automation rule" "$SPEC_AUTO" \
  "cpm:epics' testing-task check" "$EPICS_AUTO"

assert_agrees "the automated tag set" \
  "cpm:epics' testing-task check" "$EPICS_AUTO" \
  "cpm:do's routing map" "$DO_AUTO"

assert_agrees "the automated tag set" \
  "cpm:do's routing map" "$DO_AUTO" \
  "cpm:ralph's completion clause" "$RALPH_AUTO"

# The inventory. Story 1 of this epic demonstrated that this and the correspondence assertions
# above are different claims and neither subsumes the other: correspondence cannot tell "all four
# right" from "all four drifted together", and an inventory cannot tell real agreement from four
# literals that happen to match. The cost is that a deliberate rename of a tag fails here while
# the three assertions above stay green — which is the correct division of labour, not a defect.
test_start "and that set is the three automated tags, not a wider one that swallowed [manual]"
assert_equals "feature integration unit" "$SPEC_AUTO"

# Retro 28's control. "All four name the same set" is also satisfied by all four naming every tag
# in the vocabulary, which would route `[manual]` and `[target]` criteria to the test runner —
# the precise inversion of what Story 3 built. Asserted against cpm:do, where the consequence
# would actually be executed.
test_start "control: [manual] is still routed away from the automated branch, not into it"
assert_not_contains "$(do_automated)" "manual"

test_start "control: and so is [target]"
assert_not_contains "$(do_automated)" "target"

# --- Criterion 2: each skill's stated byte delta matches its actual ----------------------

# The delta table's data rows, comma separators stripped, `+` signs dropped, the bold Total row
# kept separate so it can be checked against the sum rather than counted as a sixth skill.
budget_rows() {
  grep '^| `' "$EPIC_DOC" | tr -d ',+` ' | awk -F'|' '{ print $2, $3, $4, $5 }'
}

budget_total() {
  grep '^| \*\*Total\*\*' "$EPIC_DOC" | tr -d ',+*` ' | awk -F'|' '{ print $3, $4, $5 }'
}

test_start "control: the delta table has a row for each of the five skill files"
assert_equals "5" "$(budget_rows | grep -c .)"

# Each row against the file it names. The point-in-time half — see the header.
MEASURED_MISMATCHES=""
STATED_ARITHMETIC=""
SUM_BASE=0; SUM_DELTA=0; SUM_AFTER=0

while read -r skill base delta after; do
  [ -n "$skill" ] || continue
  actual=$(wc -c < "$SCRIPT_DIR/../../skills/$skill/SKILL.md" | tr -d ' ')
  [ "$actual" = "$after" ] || \
    MEASURED_MISMATCHES="$MEASURED_MISMATCHES$skill: stated $after, measured $actual"$'\n'
  [ "$((base + delta))" = "$after" ] || \
    STATED_ARITHMETIC="$STATED_ARITHMETIC$skill: $base + $delta != $after"$'\n'
  SUM_BASE=$((SUM_BASE + base))
  SUM_DELTA=$((SUM_DELTA + delta))
  SUM_AFTER=$((SUM_AFTER + after))
done <<EOF
$(budget_rows)
EOF

# Stated before measured. A row whose arithmetic is wrong makes the measured comparison report a
# drift that is really a typo, and the two failures read identically from the summary line.
test_start "every stated baseline plus its stated delta equals its stated after-size"
assert_empty "$STATED_ARITHMETIC"

test_start "and the rows sum to the stated totals"
assert_equals "$(budget_total)" "$SUM_BASE $SUM_DELTA $SUM_AFTER"

test_start "each skill's stated after-size matches the file as it is now"
assert_empty "$MEASURED_MISMATCHES"

# The prose sentence recording the breakdown baseline and the table's Baseline column were
# written separately, months of edits apart in the file's history — so they are a correspondence,
# not a pin. A half-edit that corrected one and not the other is the realistic way this table
# stops meaning anything, and it is invisible to every assertion above.
prose_baseline() { grep '^\*\*NFR6 baseline recorded at breakdown\*\*' -A1 "$EPIC_DOC" | tr -d ',`'; }

# `[a-z]\+` and not `[a-z]*`: the zero-letter form matched the sentence's own total, which is not
# a per-skill figure, and produced a six-entry side that could never equal the table's five.
PROSE_BASELINE=$(prose_baseline | grep -o '[a-z]\+ [0-9]\{4,\}' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')

TABLE_BASELINE=$(budget_rows | awk '{ print $1, $2 }' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')

assert_agrees "the per-skill baselines" \
  "the prose sentence recorded at breakdown" "$PROSE_BASELINE" \
  "the delta table's Baseline column" "$TABLE_BASELINE"

# The sentence states a total as well as a breakdown, and nothing above reads it. A total that
# disagreed with its own five parts is the same class of defect one level up.
PROSE_TOTAL=$(prose_baseline | grep -o '[0-9]\+ bytes' | grep -o '[0-9]\+')

test_start "control: the breakdown sentence states a total to check"
assert_equals "non-empty" "$( [ -n "$PROSE_TOTAL" ] && echo non-empty || echo empty )"

test_start "and that total is the sum of the per-skill baselines it goes on to list"
assert_equals "$PROSE_TOTAL" "$SUM_BASE"

test_summary
