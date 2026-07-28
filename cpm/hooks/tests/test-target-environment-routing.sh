#!/bin/bash
# test-target-environment-routing.sh — `[target]` is a production claim, not an environmental one.
#
# --- The failure this covers -----------------------------------------------------------
#
# `[target]`'s definition is precise — "a mechanical check that can only run against the real
# deployment target" — but the sites that *route* an entry to it were not. Step 3a captures
# constraints for two environments, development and production, and Step 6d ended "go back to
# Step 3a and add it there — labelled, falsifiable, and verified `[target]`" for entries that
# are by construction development tooling: a test runner, a browser driver, a test database.
#
# The consequence is not a mislabelling. `cpm:do` and `cpm:ralph` both instruct that a
# `[target]` criterion is never self-assessed and never counted as met, so a requirement about
# the machine the run is on becomes unverifiable by the only thing in a position to verify it.
# A field-test spec tagged every `ENVn` that way and its coverage could not reach a clean
# verdict however much was built — the failure naming a deployment target that had nothing to
# do with it.
#
# --- Which assertions are oracles ------------------------------------------------------
#
# **The environment correspondence is.** Step 3a's constraint table names the environments, and
# the routing rule below it says what tag each takes. The two are read independently and
# compared as sets, so a third row added to the table without extending the rule fails here,
# and renaming an environment in both places stays green. Neither side is pinned to the other.
#
# **The Step 6d must-NOT is a scoped prohibition, not a token search.** The prohibition cannot
# be "`[target]` does not appear in Step 6d" — the paragraph that forbids the routing has to
# write the tag's name to forbid it, which is retro 23's trap. What is asserted instead is the
# *prescription*: the clause naming what an entry added there is tagged as. That clause is
# exactly where `verified [target]` sat, and it is the only place in the step where the token
# would be an instruction rather than a warning.
#
# **Everything else is a regression net over prose.** That each site still draws the
# distinction at all is checkable; that it draws it well is not.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

SPEC_SKILL="$SCRIPT_DIR/../../skills/spec/SKILL.md"
EPICS_SKILL="$SCRIPT_DIR/../../skills/epics/SKILL.md"

echo "Testing that [target] routes by environment, not by the word 'environmental'"

# Step 3a, whole. The table and the routing rule both live here.
step_3a() {
  sed -n '/^#### Step 3a: Environmental Constraints$/,/^### Section 4:/p' "$SPEC_SKILL"
}

# The constraint table's row labels — the environments the step elicits for.
table_environments() {
  step_3a | grep '^| \*\*' | sed 's/^| \*\*\([A-Za-z]*\)\*\* |.*/\1/' | LC_ALL=C sort -u
}

# The routing rule: the paragraph that says which tag each environment takes, from its lead-in
# to the blank line before the next. Sliced from its own opening rather than from the table, so
# a rule deleted outright yields nothing and fails loudly instead of inheriting the table's text.
routing_rule() {
  step_3a | sed -n '/^\*\*Which environment an entry names decides/,/^$/p'
}

# The environments the routing rule distinguishes, read the same way as the table's — a bolded
# single word, so a passing mention of "development tooling" elsewhere in the step is not
# mistaken for a routing claim, and the rule's bolded lead-in sentence is not either.
#
# No allow-list of names: filtering to `development|production` would pin this suite to
# vocabulary that lives in exactly two places, and a rename applied to both would fail here
# while both sides still agreed. Whatever the rule bolds is what it claims to route.
rule_environments() {
  routing_rule | grep -o '\*\*[A-Za-z]*\*\*' | tr -d '*' | LC_ALL=C sort -u
}

# Step 6d, and the clause naming what an entry added there is tagged as.
step_6d() {
  sed -n '/^#### Step 6d: Reconcile Tags Against/,/^#### Step 6e:/p' "$SPEC_SKILL"
}

tag_prescription() {
  step_6d | grep -o 'add it there\*\* — [^.]*\.'
}

# cpm:epics assigns tags for criteria the spec did not cover, so it routes too.
epics_target_guideline() {
  sed -n '/^  Reach for `\[target\]` — never `\[manual\]` —/,/^- \*\*Testing tasks/p' "$EPICS_SKILL"
}

# --- Controls: every slice is bounded before it is asserted over ------------------------

test_start "control: the Step 3a slice is bounded, not the whole file"
assert_slice_bounded "$SPEC_SKILL" \
  '^#### Step 3a: Environmental Constraints$' '^### Section 4:' 15 60

test_start "control: the Step 6d slice is bounded"
assert_slice_bounded "$SPEC_SKILL" \
  '^#### Step 6d: Reconcile Tags Against' '^#### Step 6e:' 4 20

test_start "control: the cpm:epics [target] guideline slice is bounded"
assert_slice_bounded "$EPICS_SKILL" \
  '^  Reach for `\[target\]` — never `\[manual\]` —' '^- \*\*Testing tasks' 1 6

test_start "control: the routing rule was found in Step 3a"
assert_equals "non-empty" "$( [ -n "$(routing_rule)" ] && echo non-empty || echo empty )"

# --- The oracle: the table and the rule name the same environments ----------------------
#
# Read from two places nobody edits together. The table is elicitation guidance and predates
# this rule; the rule is what decides a tag. A row added to one without the other is the drift
# this catches, and it is the drift that produced the defect: the table already split
# development from production while every consumer treated `ENVn` as one undifferentiated kind.

assert_agrees "the environments" \
  "Step 3a's constraint table" "$(table_environments)" \
  "the routing rule below it" "$(rule_environments)"

# The positive control for the pair. Two empty sets agree, so the comparison above would pass
# on a step whose table and rule had both been deleted.
#
# It counts rather than naming. "Development" and "Production" are Step 3a's own vocabulary and
# nothing outside this skill reads them, so a rename applied to the table and the rule together
# is a legitimate edit that must stay green — naming them here would make this suite a third
# site of a two-site name and turn that rename red. What the step does contract for is the
# split itself: its own prose says "Cover both environments" and "the table's two rows".
test_start "control: the step distinguishes exactly two environments"
assert_equals "2" "$(table_environments | grep -c .)"

# And that the extraction is selecting rather than matching everything — the table's other
# bolded cells are the two *classes*, which must not be read as environments.
test_start "control: the class headings are not extracted as environments"
if table_environments | grep -qi 'requirement\|restriction'; then
  test_fail "Requirement/Restriction were extracted as environments, so the row/column axes are conflated"
else
  test_pass
fi

# --- The must-NOT: Step 6d does not prescribe [target] ----------------------------------
#
# Scoped to the prescription clause for the reason in the header. Everything this step adds is
# development tooling — the tags it reconciles against imply a test runner, a browser driver or
# a test database, all of them claims about the machine the run is on.

test_start "control: Step 6d still prescribes a tag for what it adds"
assert_equals "non-empty" "$( [ -n "$(tag_prescription)" ] && echo non-empty || echo empty )"

test_start "Step 6d must NOT prescribe [target] for the entries it adds"
assert_not_contains "$(tag_prescription)" 'target]'

# The control that makes the scoping honest rather than merely narrow. A prohibition over one
# clause is satisfied by deleting the clause's subject entirely, leaving the step silent on the
# question — which is how the routing error gets made again by someone with no instruction
# either way.
test_start "control: Step 6d still says the entries it adds are development tooling"
assert_contains "$(step_6d)" "development tooling"

# --- Regression net: each routing site still draws the distinction ----------------------
#
# A site that names only one environment has lost the distinction rather than settled it, and
# reads as an instruction to tag every environmental entry the same way — which is the state
# all three of these were in.

test_start "the cpm:spec vocabulary bullet distinguishes the two environments"
TARGET_BULLET=$(grep -F -- '- `[target]` — Verified by a mechanical check' "$SPEC_SKILL")
if printf '%s' "$TARGET_BULLET" | grep -qi 'production' \
  && printf '%s' "$TARGET_BULLET" | grep -qi 'development'; then
  test_pass
else
  test_fail "the [target] bullet names at most one environment: $TARGET_BULLET"
fi

test_start "control: that bullet was actually found"
assert_equals "non-empty" "$( [ -n "$TARGET_BULLET" ] && echo non-empty || echo empty )"

test_start "cpm:epics' [target] guideline distinguishes the two environments"
GUIDELINE=$(epics_target_guideline)
if printf '%s' "$GUIDELINE" | grep -qi 'production' \
  && printf '%s' "$GUIDELINE" | grep -qi 'development'; then
  test_pass
else
  test_fail "the cpm:epics guideline names at most one environment"
fi

# The direction, at the site furthest from Step 3a. Naming both environments is satisfied by a
# sentence that swaps them, so the exclusion is asserted where it decides the tag.
test_start "and it excludes the development case from [target] rather than including it"
assert_contains "$GUIDELINE" "is not one"

test_summary
