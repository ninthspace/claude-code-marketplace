#!/bin/bash
# test-target-tag-vocabulary.sh — Epic 46-03 Story 2: `[target]` enters the tag vocabulary.
#
# AD6 adds a sixth test-approach tag for criteria that are mechanically checkable but only
# against the real deployment target. The whole point is that it is *not* `[manual]`:
# `[manual]` means a human verdict is the best evidence available, while `[target]` means the
# check is obvious and this machine cannot give it — so a verdict from here is worth nothing.
# Collapse the two and an autonomous run self-assesses "runs on PHP 8.2 or later" from a
# sandbox where it does, which is the false pass spec 46 exists to stop.
#
# --- The must-NOT, and why it is not an absence assertion ---------------------------
#
# Criterion 3 forbids treating `[target]` as a synonym for `[manual]`. The obvious encoding —
# assert the two tags never appear together — **fails on correct code**, and this was checked
# rather than predicted: they co-occur at `epics/SKILL.md:166`, an enumeration listing every
# propagable tag as a peer, and at `:513`, the sentence whose entire job is to tell them apart.
# Both are exactly what the story wants. Retro 23 found this same assertion failing for this
# same reason, and the epic's own task description flagged it in advance.
#
# So the haystack is narrowed to where co-occurrence would be *conflation* rather than
# *contrast*: the `Reach for [manual] only when` list, which routes a criterion to human
# judgement. `[target]` appearing there is the defect, in a way it is not anywhere else.
#
# The direction of the distinguishing sentence is asserted positively alongside it, because a
# narrowed must-NOT is also satisfied by deleting the contrast entirely — the section would
# then say nothing about the distinction and pass. That pairing is the shape 46-02 Story 4
# settled on: a scoped prohibition plus a control that the legitimate site survives.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

SPEC_SKILL="$SCRIPT_DIR/../../skills/spec/SKILL.md"
EPICS_SKILL="$SCRIPT_DIR/../../skills/epics/SKILL.md"

echo "Testing the [target] tag vocabulary (Epic 46-03 Story 2)"

# Section 6a's vocabulary — what the facilitation presents to the user.
vocabulary_list() {
  sed -n '/^#### Step 6a: Define Tag Vocabulary$/,/^\*\*Tag propagation\*\*/p' "$SPEC_SKILL"
}

# The output template's tag legend — what downstream skills read.
template_legend() {
  sed -n '/^### Tag Vocabulary$/,/^### Acceptance Criteria Coverage$/p' "$SPEC_SKILL"
}

# The list of reasons to route a criterion to human judgement — the list itself, ending at the
# justification sentence that closes it. Deliberately *not* extended to the next guideline
# bullet: the `[target]` paragraph sits between the two, so the wider slice contains the tag
# legitimately and the must-NOT below fails on correct code. That over-wide slice was the first
# thing written here and it did exactly that.
manual_routing() {
  sed -n '/^  Reach for `\[manual\]` only when the criterion describes:$/,/^  Every `\[manual\]` tag carries/p' "$EPICS_SKILL"
}

test_start "control: the Section 6a vocabulary slice is bounded"
assert_slice_bounded "$SPEC_SKILL" '^#### Step 6a: Define Tag Vocabulary$' '^\*\*Tag propagation\*\*' 5 20

test_start "control: the manual-routing slice is bounded"
assert_slice_bounded "$EPICS_SKILL" '^  Reach for `\[manual\]` only when the criterion describes:$' '^  Every `\[manual\]` tag carries' 4 10

# --- Criterion 1: both cpm:spec sites carry the tag --------------------------------------
#
# Asserted as an inventory at each site rather than as two `assert_contains` calls. The task
# exists because a tag in one site and not the other is how a vocabulary drifts, and only an
# inventory notices that the two sites disagree about the *set* — a containment check passes
# happily while one site quietly carries five tags and the other six.

VOCAB_TAGS=$(vocabulary_list | grep -o '^- `\[[a-z]*\]`' | sed 's/^- `\[//; s/\]`$//' | LC_ALL=C sort)
LEGEND_TAGS=$(template_legend | grep -o '^- `\[[a-z]*\]`' | sed 's/^- `\[//; s/\]`$//' | LC_ALL=C sort)

assert_agrees "the tag set" \
  "Section 6a" "$VOCAB_TAGS" \
  "the output template legend" "$LEGEND_TAGS"

test_start "and that set is the six the vocabulary now has"
assert_equals "$(printf 'feature\nintegration\nmanual\ntarget\ntdd\nunit')" "$VOCAB_TAGS"

# The definition, not just the name. A tag listed with the wrong meaning propagates the wrong
# verification behaviour, and the name alone would satisfy any presence check.
test_start "the vocabulary defines [target] as checkable only against the real target"
assert_contains "$(vocabulary_list | grep '^- `\[target\]`')" "can only run against the real deployment target"

# --- Criterion 2: cpm:epics propagates it ------------------------------------------------

PROPAGATED=$(grep -o 'append the appropriate tags from the spec.s testing strategy: [^.]*\.' "$EPICS_SKILL" \
  | grep -o '`\[[a-z]*\]`' | sed 's/`\[//; s/\]`//' | LC_ALL=C sort)

assert_agrees "the propagable tags" \
  "cpm:spec's vocabulary" "$VOCAB_TAGS" \
  "cpm:epics' propagation list" "$PROPAGATED"

# --- Criterion 3 (must NOT): not a synonym for [manual] ----------------------------------
#
# Scoped, for the reason in the header. The prohibition is over the routing list only.

test_start "[target] is not listed among the reasons to reach for [manual]"
assert_not_contains "$(manual_routing)" 'target]'

# The control that makes the scoping correct rather than merely narrow. Delete the sentence
# that tells the two tags apart and the assertion above still passes — with the skill now
# silent on the distinction, which is the conflation by omission rather than by statement.
test_start "control: the guideline still states which of the two an environmental check takes"
assert_contains "$(cat "$EPICS_SKILL")" 'Reach for `[target]` — never `[manual]` —'

# And the direction, so the sentence cannot be reworded into the opposite claim while keeping
# both tag names. Counted rather than filtered: the routing paragraph names `[target]` once,
# and that once must be the one that separates them.
test_start "the guideline gives the reason the two must not be merged"
assert_contains "$(cat "$EPICS_SKILL")" 'hands it to self-assessment'

test_summary
