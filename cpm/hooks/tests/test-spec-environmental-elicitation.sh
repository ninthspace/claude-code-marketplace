#!/bin/bash
# test-spec-environmental-elicitation.sh — Epic 46-02 Story 2: `cpm:spec` elicits
# environmental requirements and restrictions.
#
# Story 2's two [integration] criteria. Its other three are [manual] — whether a
# facilitation *reaches* a step, and what it asks once there, has no oracle in a test suite,
# and the epic tags them accordingly. Nothing here should be read as covering them.
#
# --- Oracles and regression nets ---------------------------------------------------
#
# ORACLE: the labels the output template advertises are fed to `coverage_environmental_class`
# from `coverage-parse.sh` — the one definition epic 46-01 Story 1 built, and the same code
# `coverage-rollup.sh` consults. A template that told an author to write `ENVIRONMENT1` would
# read perfectly and produce labels the roll-up does not classify; this is the assertion that
# the advertised grammar and the implemented grammar are the same grammar, rather than two
# descriptions that agree by inspection. Retro 28 asked for exactly this to be made
# mechanical where it can be.
#
# REGRESSION NETS: the assertions that Step 3a states a rule — that it is not skippable, that
# it covers both environments and both classes, that it names development tooling. They catch
# the rule being deleted. They cannot tell a rule a model follows from one it reads past.
#
# --- The must-NOT, and why it is an inventory rather than a grep --------------------
#
# AD1 rejected a separate `## Environment` section: `coverage-parse.sh` reads requirements
# from `## Functional Requirements` and `## Non-Functional Requirements` only, so a section
# of its own is invisible to the roll-up and cannot hold the untraced count above zero.
#
# The obvious form is `assert_not_contains "$SPEC_SKILL" "## Environment"`. It passes today
# only because `spec/SKILL.md` never mentions the rejected section — and it would fail the
# moment someone documents *why* the section is rejected, which is a legitimate edit and
# exactly retro 23's trap: the warning and the mistake are the same bytes. So the measurement
# is the set of `## ` headings inside the output template, asserted whole. That catches
# `## Environment` and any other section added beside it, it cannot be defeated by prose
# anywhere else in the file, and adding a section deliberately is a visible edit to this list
# rather than a silent one. The suite does not decide which sections are right; it insists
# someone says so.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/../lib/coverage-parse.sh"

SPEC_SKILL="$SCRIPT_DIR/../../skills/spec/SKILL.md"

echo "Testing cpm:spec's environmental constraint elicitation (Epic 46-02 Story 2)"

# Delegates to `skill_template` in test-helpers.sh — the one definition of what slicing a
# SKILL.md's output template means, and of why the anchor is the template's own first line
# rather than its fence.
spec_template() {
  skill_template "$SPEC_SKILL" '^# Spec: {Title}$'
}

# The `## Non-Functional Requirements` block within that template, ending at the next
# top-level heading.
nfr_block() {
  spec_template | awk '
    /^## Non-Functional Requirements$/ { inside = 1; next }
    /^## / { inside = 0 }
    inside'
}

step_3a() {
  sed -n '/^#### Step 3a: Environmental Constraints$/,/^### Section 4:/p' "$SPEC_SKILL"
}

# --- Non-vacuity: every slice below is bounded before it is asserted over -------------

test_start "control: the spec output template slice is bounded"
assert_slice_bounded "$SPEC_SKILL" '^# Spec: {Title}$' '^```$' 30 90

# The upper bound sits well below what a broken end anchor produces — the same slice run to
# end-of-file is 225 non-blank lines — so it still separates "this step grew" from "the range
# stopped matching Section 4", which is the only thing it is here to tell apart.
test_start "control: the Step 3a slice is bounded, not the whole file"
assert_slice_bounded "$SPEC_SKILL" '^#### Step 3a: Environmental Constraints$' '^### Section 4:' 15 60

test_start "control: the non-functional block of the template is non-empty"
assert_contains "$(nfr_block)" "NFR1"

# --- Criterion 4: the template documents both labels under the NFR heading -------------

test_start "the template shows an ENVn requirement label under Non-Functional Requirements"
assert_equals "1" "$(nfr_block | grep -c '\*\*ENV1 ')"

test_start "and an ENVXn restriction label in the same block"
assert_equals "1" "$(nfr_block | grep -c '\*\*ENVX1 ')"

# The criterion says the template documents ENVn *for requirements* and ENVXn *for
# restrictions*. Two labels present in either order satisfies "both are shown"; only the
# direction of the mapping satisfies what was asked, so it is read off the block.
test_start "the block maps ENVn to must-be-available and ENVXn to must-not-be-required"
assert_equals "available/not required" "$(
  nfr_block | awk '
    /\*\*ENV1 /  && /must provide/       { a = "available" }
    /\*\*ENVX1 / && /must not require/   { b = "not required" }
    END { printf "%s/%s", a, b }
  '
)"

# --- Criterion 4, the oracle: advertised grammar == implemented grammar ----------------
#
# The labels the template tells an author to write, fed to the predicate the roll-up uses.
# `ENVIRONMENT1` is the discriminating case: a valid label under AD1's grammar, plausible in
# a template, and not environmental. A template drifting to it fails here and nowhere else.

# Extracted by AD1's whole label grammar — `[A-Z]+[0-9]+` — deliberately, not by the
# environmental prefixes. An extractor that matched only labels which already classify would
# make the assertion below circular: it could never surface a template advertising a label
# the predicate rejects, which is the single thing it exists to catch.
TEMPLATE_LABELS=$(nfr_block | grep -o '\*\*[A-Z][A-Z]*[0-9][0-9]*' | sed 's/^\*\*//' | LC_ALL=C sort -u)

test_start "control: labels were actually extracted from the template to classify"
assert_equals "$(printf 'ENV1\nENVX1\nNFR1')" "$TEMPLATE_LABELS"

# Labels from the document, classes from the predicate, compared as a map. `NFR1` classifying
# empty is the in-line discrimination control: a predicate answering "requirement" to
# everything satisfies the two environmental entries and fails this one.
test_start "each label the template advertises classifies as its name promises"
assert_equals "ENV1=requirement ENVX1=restriction NFR1=" "$(
  printf '%s\n' "$TEMPLATE_LABELS" | while IFS= read -r label; do
    [ -n "$label" ] || continue
    printf '%s=%s ' "$label" "$(coverage_environmental_class "$label")"
  done | sed 's/ $//'
)"

# The control that gives the assertion above its teeth: the predicate says no to a label that
# looks like it should pass. Without this, a predicate returning "requirement" for everything
# would satisfy every assertion in this section.
test_start "control: the predicate refuses ENVIRONMENT1, so it is not classifying everything"
assert_equals "" "$(coverage_environmental_class ENVIRONMENT1)"

# --- Criterion 5 (must NOT): no new top-level section in the output template -----------

test_start "the output template's sections are exactly these six"
assert_equals "$(printf '## Problem Summary\n## Functional Requirements\n## Non-Functional Requirements\n## Architecture Decisions\n## Scope\n## Testing Strategy')" \
  "$(spec_template | grep '^## ')"

# Stated separately from the inventory so a failure reads as "the rejected section was added"
# rather than only as "the section list changed".
test_start "no ## Environment section is introduced, which AD1 rejected"
assert_not_contains "$(spec_template | grep '^## ')" "## Environment"

# Why the section list is the right haystack: the rule AD1 states is about the *template*.
# Step 3a states it positively and never names the rejected section, so a file-wide
# assert_not_contains happens to agree today — and would stop agreeing the moment someone
# documents the rejection, which is a legitimate edit. Asserted as the fact it is, so the
# day it changes, this line is what explains why the narrower haystack was chosen.
test_start "control: Step 3a states the rule without naming the rejected section"
assert_not_contains "$(step_3a)" "## Environment"

test_start "control: Step 3a does place the entries under the heading AD1 chose"
assert_contains "$(step_3a)" '`## Non-Functional Requirements`'

# --- Step 3a states the rules the [manual] criteria are judged against -----------------
#
# Regression nets, per this file's header. Each catches its rule being dropped; none can
# report whether a facilitation honoured it.

test_start "Step 3a is stated to be not skippable"
assert_contains "$(step_3a)" "not skippable"

test_start "it ends in labelled entries or an explicit none-apply"
assert_contains "$(step_3a)" '"none apply"'

# Both environments as rows of the two-by-two, so the count is over the axis the step is
# built on rather than over two words that could appear anywhere in the prose.
test_start "it covers development and production as rows of the constraint table"
assert_equals "1/1" "$(
  s=$(step_3a)
  printf '%s/%s' \
    "$(printf '%s\n' "$s" | grep -c '| \*\*Development\*\* |')" \
    "$(printf '%s\n' "$s" | grep -c '| \*\*Production\*\* |')"
)"

# And both classes as its columns. Together these are criterion 2's two axes; either alone
# is satisfied by a table that lost a dimension.
test_start "and requirement and restriction as its columns"
assert_equals "1/1" "$(
  s=$(step_3a)
  printf '%s/%s' \
    "$(printf '%s\n' "$s" | grep -c '\*\*Requirement\*\* — must be available')" \
    "$(printf '%s\n' "$s" | grep -c '\*\*Restriction\*\* — must not be required')"
)"

test_start "it names development tooling explicitly, not only the production environment"
assert_contains "$(step_3a)" "browser automation"

test_start "it names the greenfield reason the development half exists"
assert_contains "$(step_3a)" '`Test command: none`'

test_summary
