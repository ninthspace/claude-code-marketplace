#!/bin/bash
# test-spec-constraint-inheritance.sh — Epic 46-02 Story 4: the step inherits rather than
# re-asks.
#
# Story 4's three [integration] criteria, plus regression nets over the two [manual] ones.
# The story tags its first three criteria more strongly than spec 46 did: FR5 is `[manual]`
# in the spec, but following the product brief's `**Source**` field makes the resolution path
# a structural fact about the documents rather than facilitation behaviour, so it has an
# oracle the spec did not anticipate.
#
# --- Oracles and regression nets ---------------------------------------------------
#
# REGRESSION NETS: everything here. Each assertion catches a rule being dropped from
# `spec/SKILL.md`; none can report that a facilitation honoured it. Said plainly because the
# criteria being covered read like behaviour and are being checked as prose (retro 23).
#
# The one available oracle — that the directories this section globs are the directories
# `cpm:discover` and `cpm:architect` actually write to, derived from their own SKILL.md save
# lines rather than pinned here — is **Story 5's criterion 1 verbatim** and is deliberately
# left to `test-spec-constraint-chain.sh`. Spending it here would leave that story asserting
# nothing new.
#
# --- Why every assertion is scoped to the section ----------------------------------
#
# Criterion 2 forbids locating the problem brief by "most recent". `spec/SKILL.md:18` says
# exactly that phrase — legitimately, about a different question: which document to use as
# the spec's *input*, not where its constraints come from. A file-wide
# `assert_not_contains "most recent"` therefore fails on correct code.
#
# Criterion 3's must-NOT has the same shape from the other direction: the new section has to
# mention the product brief in order to say it is not the constraint source, and the Input
# section names it three more times.
#
# So both are scoped to the new section, and each is paired with a control asserting the
# legitimate site elsewhere in the file is still there. Without those controls a repair that
# satisfies the must-NOT by deleting Input step 3b would pass — the assertion would be
# narrower and also wrong about where the rule belongs. Retro 23's trap, met twice in one
# story.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

SPEC_SKILL="$SCRIPT_DIR/../../skills/spec/SKILL.md"

echo "Testing cpm:spec's constraint inheritance startup check (Epic 46-02 Story 4)"

inheritance_section() {
  sed -n '/^### Constraint Inheritance (Startup)$/,/^## Process$/p' "$SPEC_SKILL"
}

input_section() {
  sed -n '/^## Input$/,/^### ADR Discovery (Startup)$/p' "$SPEC_SKILL"
}

# --- Non-vacuity: both slices bounded before anything is asserted over them -------------

test_start "control: the inheritance section slice is bounded"
assert_slice_bounded "$SPEC_SKILL" '^### Constraint Inheritance (Startup)$' '^## Process$' 8 30

test_start "control: the Input section slice is bounded"
assert_slice_bounded "$SPEC_SKILL" '^## Input$' '^### ADR Discovery (Startup)$' 5 20

# AD5 asks for ADR Discovery's shape. The section has to sit *after* it, because resolving a
# product brief's `**Source**` requires the input to have been resolved first.
test_start "the section follows ADR Discovery and precedes the process sections"
assert_equals "$(printf '### ADR Discovery (Startup)\n### Constraint Inheritance (Startup)')" \
  "$(grep '^### \(ADR Discovery\|Constraint Inheritance\) (Startup)$' "$SPEC_SKILL")"

# --- Criterion 1: the glob targets both patterns ---------------------------------------

test_start "the inheritance glob targets the problem brief pattern"
assert_contains "$(inheritance_section)" 'docs/plans/[0-9]*-plan-*.md'

test_start "and the ADR pattern"
assert_contains "$(inheritance_section)" 'docs/architecture/[0-9]*-adr-*.md'

# --- Criterion 2: located by the Source field, not by recency ---------------------------

test_start "the problem brief is located by following the product brief's Source field"
assert_contains "$(inheritance_section)" '`**Source**` field'

# The guard that makes following it safe: cpm:brief writes that field as a path *or* the
# literal "direct input", so an unresolvable value is an absent brief rather than an error.
test_start "and only when that value names a path that exists"
assert_contains "$(inheritance_section)" "names a path that exists on disk"

# The section mentions recency exactly once, and that once is the prohibition. Stated as a
# count plus a direction rather than as a filtered assert_not_contains: filtering the known
# sentence out couples the assertion to that sentence's wording, so a harmless rewording
# reads as a routing change. A second mention is what a recency route actually looks like.
test_start "the section mentions recency exactly once"
assert_equals "1" "$(inheritance_section | grep -c 'most recent')"

test_start "and that mention forbids it rather than instructing it"
assert_contains "$(inheritance_section | grep 'most recent')" "Do not pick the most recent"

# The control that makes the scoping above correct rather than merely narrow. Deleting the
# Input section's own recency rule would satisfy a file-wide must-NOT while breaking how
# cpm:spec picks its input — a repair in the wrong place, and this is what refuses it.
test_start "control: the Input section still resolves its own input by recency, untouched"
assert_contains "$(input_section)" "look for the most recent"

# --- Criterion 3 (must NOT): the product brief is not the constraint source --------------
#
# Asserted positively. `assert_not_contains "product brief"` is unavailable here — the section
# must name it to rule it out — so what is checked is the direction of the statement and the
# path the resolution actually lands on.

test_start "the section states the product brief is a waypoint, not the source"
assert_contains "$(inheritance_section)" "The product brief is a waypoint, not the source."

test_start "and gives the reason, so the hop is not optimised away later"
assert_contains "$(inheritance_section)" "derived, written during ideation, and lossy"

# The resolution steps name docs/plans/ as the source and never docs/briefs/. Read as the set
# of planning directories the section routes *to*, so a section that quietly added the briefs
# directory as a fallback fails here even while every sentence above still reads correctly.
test_start "the directories the section reads constraints from exclude docs/briefs/"
assert_equals "$(printf 'docs/architecture/\ndocs/plans/')" "$(
  inheritance_section | grep -o 'docs/[a-z]*/' | LC_ALL=C sort -u
)"

# --- Criterion 5 (regression net): absence degrades silently -----------------------------

test_start "the section skips silently when neither glob yields anything"
assert_contains "$(inheritance_section)" "skip silently"

test_start "and states that absence is never an error and never a prompt"
assert_contains "$(inheritance_section)" "Absence is never an error and never a prompt."

# --- Criterion 4 (regression net): inherited entries are presented, not re-asked ----------

test_start "inherited entries are presented for confirmation and only gaps facilitated"
assert_contains "$(inheritance_section)" "facilitate only what is missing"

# Inheritance decides what is *asked*, not what is *recorded* — an inherited constraint still
# has to be falsifiable and still gets a label, or Story 3's fail-closed rule has a hole in it
# exactly the size of the upstream documents.
test_start "an inherited entry is still subject to Step 3a's labelling and falsifiability"
assert_contains "$(inheritance_section)" "inheritance decides what is asked, never what is recorded"

test_summary
