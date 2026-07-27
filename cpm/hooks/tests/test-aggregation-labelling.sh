#!/bin/bash
# test-aggregation-labelling.sh — Tests for FR7: aggregated `✓` is labelled as
# aggregation, not verification, at every site presenting it. (Epic 44-02 Story 3, then
# epic 44-03 Story 3, which added the last site — `cpm:ralph`'s completion promise.)
#
# --- What this suite can and cannot claim ---------------------------------------------
#
# It cannot judge whether a site's wording is honest. Retro 21 named the reason: a clause
# *explaining* that a `✓` is not independent evidence and a clause *claiming* that it is
# contain the same tokens, so no assertion distinguishes them. That judgement is the
# story's `[manual]` criterion and it is made by reading each site.
#
# What this suite does is stop the site list from rotting, in two directions:
#
#   1. **Known sites keep the statement.** Each rostered aggregation site is sliced from
#      its skill file and checked to still carry it. A later edit that drops the sentence
#      fails here rather than being noticed by a stakeholder.
#   2. **New sites cannot appear unclassified.** Every `✓`-bearing line across `cpm/skills/`
#      is accounted for by the inventory below — either as a rostered aggregation site, or
#      as a line explicitly classified as not presenting an aggregate. A skill that starts
#      showing `✓` counts changes a count here and fails until a human has read it and
#      said which it is. That is the protection: the suite does not decide, it insists
#      someone does.
#
# The inventory is maintained by hand, and deliberately so — deriving it from the files it
# guards would make it agree with itself and catch nothing.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

SKILLS_DIR="$SCRIPT_DIR/../../skills"

# The FR7 statement, in the words spec 44 uses. Both halves matter: "aggregation" alone is
# a description, and the contrast with verification is the whole content of the claim.
STATEMENT='aggregation, not verification'

echo "Testing: aggregated ✓ is labelled as aggregation, not verification (FR7)"
echo "========================================================================"

# --- The inventory ---------------------------------------------------------------------
#
# Every `✓`-bearing line in cpm/skills/, by file, with what each one is. Read 2026-07-26.
#
#   do/SKILL.md      4  — 1 aggregation site (the batch summary's verification summary);
#                         3 not sites: drift detection compares one row's criterion text,
#                         and two place marks rather than presenting a total.
#   epics/SKILL.md   2  — neither is a site: one clears stale marks on regeneration, one is
#                         the verification-rule blockquote written into each matrix header.
#   pivot/SKILL.md   1  — not a site: it clears marks whose criterion text a cascade changed.
#   ralph/SKILL.md   1  — the prose of an aggregation site. The site itself is the prompt
#                         template's completion line, which prints a total but contains no
#                         `✓` character; this line is the paragraph explaining it. Added by
#                         epic 44-03, which is why the count moved from 11 to 12.
#   status/SKILL.md  4  — 2 aggregation sites (Phase 3b's section, and the stakeholder page
#                         that renders the same records); 2 are the prose of those sites.
#
# The `ralph` entry is the reason a `✓`-character count is not the same thing as a site
# list. A site is where a reader is shown a total; `✓` is only the most common way to write
# one. `ralph`'s total is written in words, so the character count under-reports it by one
# site — which is why the rostered sites below are asserted individually and the inventory
# is only the tripwire for *new* ones.
#
# A matrix itself is not "a site presenting aggregated `✓`": it carries one mark per row,
# each placed for that row. FR7's subject is the union of those marks — the roll-up, the
# batch summary, the page — which is where a reader sees green without seeing what produced
# it. `cpm:inspect` reads coverage rows but reports them sceptically ("rows marked verified
# with no test naming them") rather than totalling them, so it is not a site either.

INVENTORY="do:4 epics:2 pivot:1 ralph:1 status:4"

test_start "every skill carrying ✓ is in the inventory, with the same number of lines"
UNACCOUNTED=""
for file in "$SKILLS_DIR"/*/SKILL.md; do
  skill=$(basename "$(dirname "$file")")
  actual=$(grep -c '✓' "$file")
  expected=0
  for entry in $INVENTORY; do
    [ "${entry%%:*}" = "$skill" ] && expected="${entry##*:}"
  done
  [ "$actual" -eq "$expected" ] || UNACCOUNTED="$UNACCOUNTED $skill(want $expected, got $actual)"
done
assert_empty "$UNACCOUNTED"

test_start "control: the inventory is not vacuously empty"
INVENTORY_TOTAL=0
for entry in $INVENTORY; do
  INVENTORY_TOTAL=$((INVENTORY_TOTAL + ${entry##*:}))
done
assert_equals "12" "$INVENTORY_TOTAL"

# --- Site 1: cpm:status, Phase 3b -------------------------------------------------------

PHASE_3B=$(awk '/^### Phase 3b:/ { s = 1; next } /^### / { s = 0 } s' "$SKILLS_DIR/status/SKILL.md")

test_start "slice: Phase 3b spans a real region"
if [ "$(printf '%s\n' "$PHASE_3B" | grep -c .)" -ge 10 ]; then
  test_pass
else
  test_fail "the Phase 3b slice did not match as intended"
fi

test_start "status Phase 3b states that aggregation is not verification"
assert_contains "$PHASE_3B" "$STATEMENT"

# --- Site 2: cpm:status, the stakeholder page -------------------------------------------

PAGE=$(awk '/^#### The stakeholder page/ { s = 1; next } /^#+ / { s = 0 } s' "$SKILLS_DIR/status/SKILL.md")

test_start "slice: the stakeholder page section spans a real region"
if [ "$(printf '%s\n' "$PAGE" | grep -c .)" -ge 5 ]; then
  test_pass
else
  test_fail "the stakeholder page slice did not match as intended"
fi

# The page carries the statement by instruction rather than by repeating it: the section
# tells the renderer to carry it onto the page, which is the form the rule takes for output
# that does not exist until a page is composed.
test_start "the stakeholder page section requires the statement on the page"
assert_contains "$PAGE" "Carry the aggregation statement onto the page"

test_start "and says the marks mean there what they mean in the section"
assert_contains "$PAGE" "mean the same thing there"

# --- Site 3: cpm:do, the batch summary's verification summary ---------------------------

BATCH_SUMMARY=$(grep -F 'include a **verification summary**' "$SKILLS_DIR/do/SKILL.md")

test_start "slice: the verification summary item was found"
assert_contains "$BATCH_SUMMARY" "Coverage matrix:"

test_start "do's verification summary states that aggregation is not verification"
assert_contains "$BATCH_SUMMARY" "$STATEMENT"

test_start "and says who placed the marks it is counting"
assert_contains "$BATCH_SUMMARY" "placed by this skill on its own work"

# The example strings are the part a model copies. An example reading "9/9 requirements
# verified" beside a sentence saying the count is not verification teaches the opposite of
# what the sentence says, so the examples are checked too — but *only* the examples.
#
# The first attempt asserted the misleading phrasing was absent from the whole item, and it
# failed: the item quotes that phrasing on purpose, in the sentence telling a model not to
# use it. That is retro 21's finding arriving in the same shape it always does — the warning
# and the mistake are the same bytes — and the fix is the same too: narrow the haystack to
# the region where the phrasing would be an instruction rather than a caution.
EXAMPLES=$(printf '%s\n' "$BATCH_SUMMARY" | sed -n 's/.*(e\.g\. \(.*rows remain"\)).*/\1/p')

test_start "slice: the format examples were found"
assert_contains "$EXAMPLES" "Coverage matrix:"

test_start "the format examples state who did the marking"
assert_contains "$EXAMPLES" "marked verified by this run"

test_start "the format examples do not read as independent confirmation"
assert_not_contains "$EXAMPLES" "requirements verified"

# --- Not-a-site lines: classified, and checked to still be what the inventory says -------
#
# These four assertions are what make the inventory's counts meaningful. Without them a
# `✓` line could change from "clears a stale mark" to "reports a total" with the count
# unmoved, and the suite would not notice.

test_start "do's drift-detection line still compares one row, not a total"
assert_contains "$(grep -F '**Drift detection**' "$SKILLS_DIR/do/SKILL.md")" \
  "compare the \"Story Criterion (verbatim)\" text"

test_start "do's proof-recording lines still place marks rather than present them"
assert_contains "$(grep -F '**Epic-level proof recording**' "$SKILLS_DIR/do/SKILL.md")" \
  "mark any remaining unverified rows"

test_start "epics' regeneration line still clears stale marks"
assert_contains "$(grep -F '**Regeneration awareness**' "$SKILLS_DIR/epics/SKILL.md")" \
  "must clear verification for any rows whose"

test_start "pivot's invalidation line still clears marks"
assert_contains "$(grep -F '**Coverage matrix invalidation**' "$SKILLS_DIR/pivot/SKILL.md")" \
  "clear the \`✓\` from the Verified column"

# --- The statement is not accidentally universal ----------------------------------------
#
# Every assertion above is `assert_contains` over a slice. If the statement were sprinkled
# through every skill, they would all hold and mean nothing. It is scoped to the sites that
# present an aggregate, so a skill with no such site should not carry it.

test_start "control: the statement is absent from skills with no aggregation site"
STRAY=""
for skill in epics pivot; do
  grep -qF "$STATEMENT" "$SKILLS_DIR/$skill/SKILL.md" && STRAY="$STRAY $skill"
done
assert_empty "$STRAY"

# --- Site 4: cpm:ralph, the completion promise (epic 44-03) ------------------------------
#
# This assertion replaced one reading "cpm:ralph presents no aggregated ✓ yet — 44-03 adds
# both the site and the label". That is the inventory doing its job: the placeholder was
# written to fail the day the site was built, and it did.
#
# The site is the prompt template's completion line, not the prose beside it. That
# distinction is row 4's rule from this epic's own matrix — the stop hook feeds the template
# back verbatim each iteration and the loop reads nothing else, so a statement living only
# in the surrounding prose would be a label on something the operator never sees. Both are
# checked, and the template's is the one that matters.

RALPH_PROMPT=$(grep -F 'Run /cpm:do on epics' "$SKILLS_DIR/ralph/SKILL.md")

test_start "slice: ralph's prompt template was found"
assert_contains "$RALPH_PROMPT" "COVERAGE:"

test_start "the line ralph prints states that aggregation is not verification"
assert_contains "$RALPH_PROMPT" "$STATEMENT"

test_start "and says who placed the marks it is counting"
assert_contains "$RALPH_PROMPT" "placed by cpm:do on its own work"

# FR8's second half, and this story's second criterion. Epic scope counts rows in matrices;
# the measurement that would discriminate a delivered spec from an untraced one is the
# untraced count, which needs a requirement list epic scope does not have. A completion line
# that did not say so reads as a delivery verdict, which is the failure FR7 exists to stop.
test_start "the printed line says what it counts, so it cannot be read as a spec verdict"
assert_contains "$RALPH_PROMPT" "counts rows in these epics, not requirements in a spec"

RALPH_PROSE=$(awk '/^\*\*What the completion line measures/ { s = 1 } /^### Step 3:/ { s = 0 } s' \
  "$SKILLS_DIR/ralph/SKILL.md")

test_start "slice: the section documenting the site spans its own region and no more"
RALPH_PROSE_LINES=$(printf '%s\n' "$RALPH_PROSE" | grep -c .)
if [ "$RALPH_PROSE_LINES" -ge 2 ] && [ "$RALPH_PROSE_LINES" -le 6 ]; then
  test_pass
else
  test_fail "the slice is $RALPH_PROSE_LINES non-blank lines"
fi

test_start "the site names the discriminating measurement it does not carry"
assert_contains "$RALPH_PROSE" "untraced count"

# This asserted "`cpm:ralph` has no spec-scope promise, and building one is deferred" until
# spec 45 built one. The durable half of the claim is the boundary, not the deferral: the
# line ralph prints after an *epic*-scope run still cannot be read as a delivery verdict, and
# that stays true whatever spec mode gains. Retargeted to the boundary rather than widened —
# a net that also passes on "spec scope is deferred" would defend a sentence that is now
# false (retro 26).
test_start "and says that measurement belongs to spec scope, which epic mode does not carry"
assert_contains "$RALPH_PROSE" "epic mode has no spec-scope promise"

test_summary
