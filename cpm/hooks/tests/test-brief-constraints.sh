#!/bin/bash
# test-brief-constraints.sh — Epic 46-02 Story 1: `cpm:brief` carries constraints forward.
#
# Story 1's two [integration] acceptance criteria. The deliverable is prose in a SKILL.md,
# and what it changes is what a model writing a product brief produces — so what these
# assertions are, and are not, belongs before the first of them (retro 23).
#
# --- Oracles and regression nets ---------------------------------------------------
#
# ORACLE: the correspondence between the problem-brief template in `discover/SKILL.md` and
# the product-brief template in `brief/SKILL.md`. "Carries constraints forward" is only
# mechanical if the section a product brief writes is the section a problem brief wrote;
# both headings are extracted from their own documents and compared, so renaming either
# fails here rather than being discovered later by a facilitation that quietly re-asks.
# Neither side is a literal in this file — the documents are the oracle (retro 25).
#
# REGRESSION NETS: every assertion that a sentence is present in the skill. Those catch a
# rule being dropped. They cannot tell a rule a model honours from a rule it reads past,
# and no assertion over prose can. Story 1's third criterion — a product brief produced
# from a problem brief carrying constraints — is the one with that oracle, and the epic
# tags it [manual] because it is not available here.
#
# --- The wrong edit this suite is built around --------------------------------------
#
# FR8 exists because `cpm:brief` asked about constraints in two phases and had nowhere to
# put the answers. The wrong repair is to write more constraint prose into those phases
# and stop, which is exactly what the must-NOT criterion forbids. A file-wide grep for
# `## Constraints` cannot see that edit, because the phase prose now names the section it
# writes to — so it matches whether or not the template ever gained one. Every assertion
# below is therefore scoped to the output template's fenced block, and the control at the
# end shows the file-wide count is strictly larger, which is the whole reason for the
# scoping (retro 23: narrow the haystack to where presence is the thing being claimed).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

SKILLS_DIR="$SCRIPT_DIR/../../skills"
BRIEF="$SKILLS_DIR/brief/SKILL.md"
DISCOVER="$SKILLS_DIR/discover/SKILL.md"

echo "Testing that cpm:brief carries constraints forward (Epic 46-02 Story 1)"

# Both delegate to `skill_template` in test-helpers.sh, which holds the one definition of
# what slicing a SKILL.md's output template means — anchoring on the template's own first
# line rather than on its fence, because these files hold two ```markdown blocks and the
# second is the progress-file format. The short local names stay: they are this suite's
# vocabulary across its assertions, and only the definition moved.
brief_template() {
  skill_template "$BRIEF" '^# Product Brief: {Title}$'
}

problem_template() {
  skill_template "$DISCOVER" '^# Problem Brief'
}

# --- Non-vacuity: the slices exist before anything is asserted over them -------------
#
# Both ends bounded. A range matching nothing makes every assert_contains over it fail
# loudly; a range running past its closing fence passes on text belonging to another
# section, and only the upper bound catches that.

test_start "control: the product brief template slice is bounded"
assert_slice_bounded "$BRIEF" '^# Product Brief: {Title}$' '^```$' 20 60

test_start "control: the problem brief template slice is bounded"
assert_slice_bounded "$DISCOVER" '^# Problem Brief' '^```$' 8 30

# --- Criterion 1: the output template carries a `## Constraints` section --------------

test_start "the product brief output template carries a ## Constraints heading"
assert_equals "1" "$(brief_template | grep -c '^## Constraints$')"

# Placement, per Task 1.1: constraints bound what the features can be, so they follow the
# features and precede the differentiation drawn within them. Read as the order of the
# headings actually in the template rather than as three separate presence checks, which
# would pass for any arrangement of them.
test_start "it sits between Key Features and Differentiation"
assert_equals "$(printf 'Key Features\nConstraints\nDifferentiation')" "$(
  brief_template | awk '/^## (Key Features|Constraints|Differentiation)$/ { sub(/^## /, ""); print }'
)"

# --- Criterion 1, the oracle: the two templates name the same section -----------------
#
# `cpm:discover` writes the problem brief; `cpm:brief` reads it and writes the product
# brief. If the headings differ, "carry them forward" is a human instruction with no
# handle, which is the state FR8 was raised about. Each side is extracted from its own
# document, so this fails on a rename of either — and the non-empty controls come first,
# because two failed extractions compare equal and report green (retro 23).

BRIEF_HEADING=$(brief_template | grep '^## Constraints$')
PROBLEM_HEADING=$(problem_template | grep '^## Constraints$')

test_start "control: the problem brief template's constraints heading extracted"
assert_contains "$PROBLEM_HEADING" "Constraints"

test_start "control: the product brief template's constraints heading extracted"
assert_contains "$BRIEF_HEADING" "Constraints"

test_start "both templates name the section identically, so the hop is mechanical"
assert_equals "$PROBLEM_HEADING" "$BRIEF_HEADING"

# --- Criterion 2 (must NOT): the facilitation questions alone are not the repair -------
#
# The two questions predate this change and must survive it — a repair that replaced them
# with the template section would satisfy criterion 1 and still lose the answers. Asserted
# verbatim, because they are the sites the criterion names by line number.

test_start "Phase 1 still asks whether anything constrains the work"
assert_contains "$(cat "$BRIEF")" "Any new constraints or context?"

test_start "Phase 2 still asks how an approach aligns with the constraints from discovery"
assert_contains "$(cat "$BRIEF")" "How does it align with the constraints from discovery?"

# Both halves at once. The must-NOT is violated by questions present and template absent,
# so the pair is the assertion — either alone is satisfied by the defect.
test_start "the questions and the output section are both present, which is the pairing"
assert_equals "questions/section" "$(
  q=$(grep -c 'constraints from discovery' "$BRIEF")
  s=$(brief_template | grep -c '^## Constraints$')
  printf '%s/%s' "$([ "$q" -ge 1 ] && echo questions || echo missing)" \
                 "$([ "$s" -eq 1 ] && echo section   || echo missing)"
)"

# --- Wiring: the questions name where the answers go ----------------------------------
#
# Task 1.2's subject. Without this the two questions are still collecting into nothing;
# the template would hold a section no phase is told to fill.

test_start "Phase 1 names the output section as the destination for what it collects"
assert_contains "$(sed -n '/^### Phase 1: Problem Recap$/,/^### Phase 2:/p' "$BRIEF")" \
  'output'"'"'s `## Constraints` section'

test_start "Phase 2 routes a deciding constraint into the same set"
assert_contains "$(sed -n '/^### Phase 2: Solution Approaches$/,/^### Phase 3:/p' "$BRIEF")" \
  "add the deciding constraint to the set Phase 1 collected"

test_start "control: the Phase 1 slice is bounded, not the whole file"
assert_slice_bounded "$BRIEF" '^### Phase 1: Problem Recap$' '^### Phase 2:' 6 20

test_start "control: the Phase 2 slice is bounded, not the whole file"
assert_slice_bounded "$BRIEF" '^### Phase 2: Solution Approaches$' '^### Phase 3:' 8 25

# --- The control that justifies every slice above -------------------------------------
#
# If the file-wide count and the template-block count agreed, the scoping would be
# ceremony. They do not: the phases now discuss the section by name, so a file-wide grep
# matches the prose about the section as readily as the section. This assertion states
# that gap as a fact, and it is what makes the wrong edit — prose only, no template —
# invisible to the naive measurement and visible to the ones actually used.

FILE_WIDE=$(grep -c '## Constraints' "$BRIEF")
IN_TEMPLATE=$(brief_template | grep -c '^## Constraints$')

test_start "control: the file-wide count is non-zero, so it is a measurement at all"
assert_equals "yes" "$([ "$FILE_WIDE" -gt 0 ] && echo yes || echo no)"

test_start "a file-wide grep over-counts, which is why every assertion above is scoped"
assert_equals "yes" "$([ "$FILE_WIDE" -gt "$IN_TEMPLATE" ] && echo yes || echo no)"

test_summary
