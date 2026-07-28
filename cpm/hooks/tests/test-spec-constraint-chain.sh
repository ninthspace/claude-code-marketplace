#!/bin/bash
# test-spec-constraint-chain.sh — Epic 46-02 Story 5: cross-story integration.
#
# The chain spec 46 exists to repair, asserted as a chain rather than as five separate
# sentences:
#
#   cpm:discover writes `## Constraints` into a problem brief
#     → cpm:brief carries it forward and records a back-reference to that brief
#       → cpm:spec follows the back-reference, past the product brief, to the problem brief
#         → cpm:spec records the entries under a heading
#           → coverage-parse.sh reads requirements from that heading
#
# Every hop was a real defect: the brief had nowhere to put constraints (FR8), the spec had
# no step to elicit them (FR1), and it had no route back to where they were captured (FR5).
# Each is now fixed in its own document, and each fix names something in a *neighbouring*
# document — which is exactly the claim retro 25 found three of, unchecked, in one epic.
#
# --- These are oracles, and that is unusual for this epic ---------------------------
#
# Stories 1-4 are prose in a SKILL.md, so most of their suites are regression nets that catch
# a rule being dropped and cannot tell an honoured rule from a quoted one. This suite is
# different in kind: nothing here pins a literal. Each side of every comparison is extracted
# from the document that owns it, and the assertion is that the two sides agree.
#
# So renaming `docs/plans/` in cpm:discover fails here, and so does renaming it in cpm:spec —
# but renaming it in *both* passes, correctly, because the chain still resolves. That is the
# property worth having, and it is not available to an assertion that pins either side.
#
# --- Why the non-empty controls are half the suite ----------------------------------
#
# Story 5's second criterion exists because retro 23 found three assertions of exactly this
# shape gone vacuous: an extraction stops matching, both sides come back empty, empty equals
# empty, and the suite reports green while checking nothing. Every extraction below is
# asserted non-empty *before* the comparison that consumes it. The controls are not padding;
# they are what makes the comparisons mean anything.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

SKILLS_DIR="$SCRIPT_DIR/../../skills"
DISCOVER="$SKILLS_DIR/discover/SKILL.md"
BRIEF="$SKILLS_DIR/brief/SKILL.md"
SPEC_SKILL="$SKILLS_DIR/spec/SKILL.md"
PARSER="$SCRIPT_DIR/../lib/coverage-parse.sh"

echo "Testing the constraint chain end to end (Epic 46-02 Story 5)"

inheritance_section() {
  sed -n '/^### Constraint Inheritance (Startup)$/,/^## Process$/p' "$SPEC_SKILL"
}

step_3a() {
  sed -n '/^#### Step 3a: Environmental Constraints$/,/^### Section 4:/p' "$SPEC_SKILL"
}

# --- Both slices bounded before anything is extracted from them --------------------------
#
# Not ceremony. Every slicer here ends on a *neighbouring section's* heading, so if that
# neighbour is renamed the range runs to EOF and the slice silently widens. Hop 4 is the one
# that would go quiet: `spec/SKILL.md` names `## Non-Functional Requirements` twice — once as
# Step 3a's recording instruction, once as a heading in the output template — so an
# over-running Step 3a slice still yields the right string, from the wrong sentence, and the
# comparison passes while checking nothing about Step 3a at all. The bound is what keeps
# `head -1` honest.
#
# The bounds are the sibling suites' own, unchanged, so a section that grows past what they
# allow fails there too rather than only here.

test_start "control: the Step 3a slice is bounded"
assert_slice_bounded "$SPEC_SKILL" '^#### Step 3a: Environmental Constraints$' '^### Section 4:' 15 60

test_start "control: the inheritance section slice is bounded"
assert_slice_bounded "$SPEC_SKILL" '^### Constraint Inheritance (Startup)$' '^## Process$' 8 30

# --- Hop 1: the directory cpm:discover writes to is the directory cpm:spec globs ---------

DISCOVER_DIR=$(grep -o 'Save the brief to `docs/[a-z]*/' "$DISCOVER" | head -1 | sed 's/.*`//')
SPEC_PLAN_DIR=$(inheritance_section | grep -o 'docs/[a-z]*/\[0-9\]\*-plan-\*\.md' | head -1 | sed 's/\[0-9\].*//')

test_start "control: cpm:discover states where it writes problem briefs"
assert_contains "$DISCOVER_DIR" "docs/"

test_start "control: cpm:spec's inheritance section names a problem-brief glob"
assert_contains "$SPEC_PLAN_DIR" "docs/"

test_start "the inheritance glob targets the directory cpm:discover writes problem briefs to"
assert_equals "$DISCOVER_DIR" "$SPEC_PLAN_DIR"

# --- Hop 1b: the same, for ADRs -----------------------------------------------------------

ARCHITECT_DIR=$(grep -o 'Save each ADR to `docs/[a-z]*/' "$SKILLS_DIR/architect/SKILL.md" | head -1 | sed 's/.*`//')
SPEC_ADR_DIR=$(inheritance_section | grep -o 'docs/[a-z]*/\[0-9\]\*-adr-\*\.md' | head -1 | sed 's/\[0-9\].*//')

test_start "control: cpm:architect states where it writes ADRs"
assert_contains "$ARCHITECT_DIR" "docs/"

test_start "control: cpm:spec's inheritance section names an ADR glob"
assert_contains "$SPEC_ADR_DIR" "docs/"

test_start "and it targets the directory cpm:architect writes ADRs to"
assert_equals "$ARCHITECT_DIR" "$SPEC_ADR_DIR"

# --- Hop 2: the field cpm:spec follows is the field cpm:brief writes ----------------------
#
# The product brief's back-reference. cpm:brief's own output template is the definition; the
# inheritance section names what it follows. Neither is a literal here.

BRIEF_FIELD=$(skill_template "$BRIEF" '^# Product Brief: {Title}$' \
  | awk '/problem brief/ && /^\*\*/ { sub(/:.*/, ""); print; exit }')
SPEC_FIELD=$(inheritance_section | grep -o '`\*\*[A-Za-z]*\*\*` field' | head -1 | sed 's/^`//; s/` field$//')

test_start "control: cpm:brief's template writes a field naming the problem brief"
assert_contains "$BRIEF_FIELD" "**"

test_start "control: cpm:spec's inheritance section names a field it follows"
assert_contains "$SPEC_FIELD" "**"

test_start "the field cpm:spec follows is the field cpm:brief writes"
assert_equals "$BRIEF_FIELD" "$SPEC_FIELD"

# --- Hop 3: the section name is the same string in all three documents --------------------
#
# "Carry the constraints forward" is only mechanical if the heading a problem brief writes is
# the heading a product brief writes and the heading cpm:spec reads. Three documents, one
# string, none of them pinned here.

DISCOVER_CONSTRAINTS=$(skill_template "$DISCOVER" '^# Problem Brief' | grep '^## Constraints$')
BRIEF_CONSTRAINTS=$(skill_template "$BRIEF" '^# Product Brief: {Title}$' | grep '^## Constraints$')
SPEC_READS=$(inheritance_section | grep -o '`## Constraints`' | head -1 | tr -d '`')

test_start "control: the problem brief template names a constraints section"
assert_contains "$DISCOVER_CONSTRAINTS" "Constraints"

test_start "control: the product brief template names one too"
assert_contains "$BRIEF_CONSTRAINTS" "Constraints"

test_start "control: cpm:spec's inheritance section names the section it reads"
assert_contains "$SPEC_READS" "Constraints"

# Compared pairwise rather than by counting distinct values. The counting form was written
# first — `printf` the three, `sort -u | grep -c .`, expect 1 — and a mutation renaming the
# problem brief's section proved it vacuous in exactly the way criterion 2 names: `grep -c .`
# skips the empty line, so a one-sided empty extraction still counts 1 and the comparison
# passes. Only the control fired. Pairwise equality has no such hole, and each comparison is
# already guarded by its own control above.
test_start "the product brief names the same section as the problem brief it copies from"
assert_equals "$DISCOVER_CONSTRAINTS" "$BRIEF_CONSTRAINTS"

test_start "and cpm:spec reads that same section, so the hop needs no translation"
assert_equals "$BRIEF_CONSTRAINTS" "$SPEC_READS"

# --- Hop 4: the heading cpm:spec records under is the heading the parser reads -------------
#
# The last hop, and the one spec 46 is actually about. AD1 chose the non-functional heading
# precisely because `coverage-parse.sh` already reads requirements from it — so an ENVn entry
# is traced with no parser change. That choice is only sound while the two strings match, and
# the parser names its heading in a variable, so both sides are extractable.

PARSER_NFR_HEADING=$(grep -o "CPM_MD_NFR_HEADING='[^']*'" "$PARSER" | head -1 | sed "s/.*='//; s/'\$//")
SPEC_RECORD_HEADING=$(step_3a | grep -o '`## [A-Za-z-]* Requirements`' | head -1 | tr -d '`')

test_start "control: the parser names the heading it reads requirements from"
assert_contains "$PARSER_NFR_HEADING" "## "

test_start "control: Step 3a names the heading it records entries under"
assert_contains "$SPEC_RECORD_HEADING" "## "

test_start "cpm:spec records constraints under the heading coverage-parse.sh reads"
assert_equals "$PARSER_NFR_HEADING" "$SPEC_RECORD_HEADING"

# --- The must-NOT the chain has to keep -------------------------------------------------
#
# The chain runs through the product brief and must not stop there. Story 1 gave the product
# brief a `## Constraints` section of its own, which makes reading it the locally obvious
# shortcut and the thing FR5 forbids. Asserted as the set of planning directories the
# inheritance section routes to, so adding the briefs directory as a fallback fails here even
# though every sentence in the section would still read correctly.

test_start "the chain reaches past the product brief rather than reading it"
assert_equals "$(printf '%s\n%s' "$ARCHITECT_DIR" "$DISCOVER_DIR" | LC_ALL=C sort)" "$(
  inheritance_section | grep -o 'docs/[a-z]*/' | LC_ALL=C sort -u
)"

test_summary
