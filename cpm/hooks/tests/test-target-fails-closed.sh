#!/bin/bash
# test-target-fails-closed.sh — Epic 46-03 Story 3: `[target]` fails closed in autonomous
# execution.
#
# The defect this story fixes is a fall-through, not a missing sentence. `do/SKILL.md` routed
# verification with two branches — the automated tags, and "`[manual]` or no tag" — so *any*
# tag the skill did not recognise landed in the second one and got self-assessed. That is
# worse than an untagged criterion: it reads in the epic doc as a deliberate verification
# choice while being the opposite of one, and for `[target]` specifically it means confirming
# "the production host provides PHP 8.2 or later" from a sandbox that already does.
#
# --- Oracles and regression nets ----------------------------------------------------
#
# ORACLES: the routing inventory (criterion 2) and the two correspondence assertions
# (criteria 1/2 consistency, and criterion 4). Each derives both sides from the documents that
# own them; none is pinned to a literal, so a consistent rename across the components stays
# green while a one-sided change fails.
#
# REGRESSION NETS: criterion 3, and the wording of `[target]`'s branch. They catch a rule being
# deleted from prose and cannot report that an execution honoured it. Said plainly because the
# criteria read like behaviour and are being checked as text.
#
# --- Why the inventory replaces "run the script and assert the branch" --------------
#
# Retro 29's lesson — the prompt-clause suites asserted what a clause *said* and never which
# branch a real situation lands in — was applied to this story at the consumption gate. Its
# remedy, "build a fixture, run the real script for its exit code, assert which branch that
# code selects", has nothing to run here: no executable in this repo reads test-approach tags
# at all. `grep` over `cpm/hooks/lib/` and `cpm/hooks/` finds no `[unit]`, `[manual]` or
# `[integration]`, and `coverage-parse.sh` has no notion of a tag. Routing exists only as prose.
#
# The agreed adaptation asserts the property structurally instead: derive every tag the
# vocabulary defines, derive every tag `do/SKILL.md` names a branch for, and require the map to
# be **total**. A tag with nowhere to fall through cannot fall through — which is criterion 2
# as a structural fact rather than as a search for a sentence. It is weaker than running the
# real thing and stronger than grepping for wording, and the gap is named here rather than left
# for a reader to assume the stronger reading.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

SPEC_SKILL="$SCRIPT_DIR/../../skills/spec/SKILL.md"
DO_SKILL="$SCRIPT_DIR/../../skills/do/SKILL.md"
RALPH_SKILL="$SCRIPT_DIR/../../skills/ralph/SKILL.md"

echo "Testing that [target] fails closed (Epic 46-03 Story 3)"

vocabulary() {
  sed -n '/^#### Step 6a: Define Tag Vocabulary$/,/^\*\*Tag propagation\*\*/p' "$SPEC_SKILL"
}

# Step 5's per-criterion routing — the branch list itself.
routing_map() {
  sed -n '/^- For each criterion, assess whether/,/^- If all criteria are met/p' "$DO_SKILL"
}

# The verification-gate statement of the same partition, at a different point in the skill.
gate_rule() {
  grep '^\*\*Test execution in verification gates\*\*' "$DO_SKILL"
}

# The autonomous prompt's completion clause.
ralph_clause() {
  grep -o 'Task complete means:.*never self-assessed\.' "$RALPH_SKILL"
}

test_start "control: the routing-map slice is bounded"
assert_slice_bounded "$DO_SKILL" '^- For each criterion, assess whether' '^- If all criteria are met' 5 15

# The vocabulary slice needs the same guard, and did not have it until the story's refactoring
# pass. `test-target-tag-vocabulary.sh` takes this identical slice and bounds it; this file took
# the slice and did not. Two callers, one contract, one of them silently missing it — which is
# retro 28's promotion condition arriving without a third caller to justify a shared fixture.
# The contract is restored where it was lost rather than by moving a repo-specific slicer into
# the generic helper file; that trade is worth revisiting if a third caller appears.
test_start "control: the tag-vocabulary slice is bounded"
assert_slice_bounded "$SPEC_SKILL" '^#### Step 6a: Define Tag Vocabulary$' '^\*\*Tag propagation\*\*' 5 20

# --- Criterion 2: the map is total, so nothing can fall through --------------------------
#
# The level tags are derived by *excluding* the vocabulary entries that describe a workflow
# mode, rather than by listing five names here. `[tdd]` is orthogonal — it says how to work,
# not what kind of evidence counts — so it legitimately has no verification branch, and a naive
# comparison of the whole vocabulary against the routing map would fail on correct code.

LEVEL_TAGS=$(vocabulary | grep '^- `\[[a-z]*\]`' | grep -v 'Workflow mode' \
  | grep -o '^- `\[[a-z]*\]`' | sed 's/^- `\[//; s/\]`$//' | LC_ALL=C sort)

ROUTED_TAGS=$(routing_map | grep -o '`\[[a-z]*\]`' | sed 's/`\[//; s/\]`//' | LC_ALL=C sort -u)

# Non-vacuity for the exclusion itself. If "Workflow mode" ever stops matching, the filter
# silently excludes nothing, LEVEL_TAGS gains `tdd`, and the comparison below fails — loudly,
# but for a reason that reads like a routing defect. This says which it is.
test_start "control: the workflow-mode filter actually excluded a tag"
assert_equals "tdd" "$(vocabulary | grep '^- `\[[a-z]*\]`' | grep 'Workflow mode' \
  | grep -o '^- `\[[a-z]*\]`' | sed 's/^- `\[//; s/\]`$//' | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')"

assert_agrees "the verification-level tags" \
  "cpm:spec's vocabulary" "$LEVEL_TAGS" \
  "cpm:do's routing map" "$ROUTED_TAGS"

# The branch that closes the fall-through. Total-ness above is what makes an unrecognised tag
# impossible to route by accident; this is the instruction for what to do when one appears
# anyway, which the map cannot express.
test_start "an unrecognised tag has its own branch rather than sharing the untagged one"
assert_contains "$(routing_map)" "An unrecognised tag"

test_start "and that branch reports rather than self-assessing"
assert_contains "$(routing_map | grep -A1 'An unrecognised tag')" "do not fall back to self-assessment"

# --- Criterion 1: [target] is not routed to self-assessment ------------------------------
#
# Scoped to `[target]`'s own branch. `Self-assess` appears legitimately one bullet above, in
# `[manual]`'s branch, where it is the correct instruction — a file-wide or section-wide
# absence assertion fails on correct code, which is retro 23's trap and the third time this
# epic has met it.

# The tag's *name* is read out of the vocabulary rather than typed here, and the vocabulary
# entry is found by its definition rather than by its name. Everything below then checks what
# the branch says while staying indifferent to what the tag is called.
#
# This is not fastidiousness. A three-file mutation renaming the tag consistently across
# `cpm:spec`, `cpm:do` and `cpm:ralph` leaves every claim in this story true, and the suite
# should stay green — the correspondence assertions already do. With the name typed into the
# slicer below, four assertions failed on that mutation for no reason but the spelling, which
# would read to the next author as "renaming the tag breaks the contract" when it does not.
TARGET_TAG=$(vocabulary | grep 'can only run against the real deployment target' \
  | grep -o '^- `\[[a-z]*\]`' | sed 's/^- `//; s/`$//')

# Escaped before it goes near `sed`. A tag is spelled `[target]`, which in a basic regular
# expression is a *character class* matching one of `t`, `a`, `r`, `g`, `e` — so interpolating
# it raw silently matches nothing and the slice comes back empty. Caught by the control below
# firing on unmodified files, which is the whole reason that control is stated before the
# assertions that depend on the slice.
TARGET_RE=$(printf '%s' "$TARGET_TAG" | sed 's/[][]/\\&/g')

target_branch() {
  routing_map | sed -n "/^  - \*\*\`$TARGET_RE\`\*\*/,/^  - \*\*An unrecognised/p" | grep -v '^  - \*\*An unrecognised'
}

test_start "control: the [target] branch was located"
assert_equals "non-empty" "$( [ -n "$(target_branch)" ] && echo non-empty || echo empty )"

test_start "[target] is not routed to self-assessment"
assert_not_contains "$(target_branch)" "Self-assess by inspecting"

test_start "it is recorded as unverified in this environment instead"
assert_contains "$(target_branch)" "unverified in this environment"

# It must not block completion either. A criterion that can never be satisfied where the run
# happens would stall the loop rather than protect anything — retro 29's non-termination
# failure arriving through a different door.
test_start "and it does not block completion, which would stall an autonomous loop"
assert_contains "$(target_branch)" "does not block completion"

# The control that makes the scoping correct rather than merely narrow: [manual]'s branch still
# says to self-assess. A "fix" that satisfied the assertion above by deleting self-assessment
# everywhere would pass a narrower check while breaking how [manual] is verified.
test_start "control: [manual] still routes to self-assessment, untouched"
assert_contains "$(routing_map | grep '\[manual\]')" "Self-assess by inspecting"

# --- Task 3.2: the skill does not disagree with itself -----------------------------------

GATE_TAGS=$(gate_rule | grep -o '`\[[a-z]*\]`' | sed 's/`\[//; s/\]`//' | LC_ALL=C sort -u)

assert_agrees "the tags named by cpm:do's two statements of the partition" \
  "the per-criterion routing map" "$ROUTED_TAGS" \
  "the verification-gate rule" "$GATE_TAGS"

# Naming the same tags is not agreeing about them, and this assertion exists because the one
# above was proved insufficient. Deleting the gate rule's substantive `[target]` sentence —
# "record `target-only — unverified in this environment` and assess nothing" — left the tag
# named in the rule's trailing exception clause, so the sets still matched and the mutation
# passed. A presence-set comparison is the right shape for criterion 4, where the question
# genuinely is *which tags are named*; it is too weak for Task 3.2, where the question is what
# each statement says to do with them. Retro 28's lesson in a new place: the assertion was
# satisfied by a change that removed the feature.
test_start "the gate rule states [target]'s treatment rather than only naming the tag"
assert_contains "$(gate_rule)" "never self-assessed and never counted as met"

# --- Criteria 3 and 4: cpm:ralph's prompt ------------------------------------------------

RALPH_TAGS=$(ralph_clause | grep -o '\[[a-z]*\]' | sed 's/\[//; s/\]//' | LC_ALL=C sort -u)

assert_agrees "the tags named for task completion" \
  "cpm:do's routing map" "$ROUTED_TAGS" \
  "cpm:ralph's prompt" "$RALPH_TAGS"

# Criterion 3, as a regression net. The tag being *named* in the prompt is criterion 4's
# business; what it is named as is this one's.
test_start "the prompt states a [target] criterion is never counted as met"
assert_contains "$(ralph_clause)" "never count it as met"

test_start "and never self-assessed"
assert_contains "$(ralph_clause)" "never self-assess one"

# --- The stated length stays honest ------------------------------------------------------
#
# Two other suites already compare `**Length:**` against the template line, so this is not
# repeated here. What is asserted is the thing those suites cannot see: that the clause this
# story added is actually inside the line they measure, rather than in the prose around it.

test_start "the completion clause lives on the measured template line"
assert_contains "$(sed -n '/^Run \/cpm:do on epics {epic_range}/p' "$RALPH_SKILL")" "criterion is checkable only against the real deployment target"

test_summary
