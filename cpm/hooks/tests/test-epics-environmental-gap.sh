#!/bin/bash
# test-epics-environmental-gap.sh — Epic 46-03 Story 1: `cpm:epics` gap-checks environmental
# constraints.
#
# AD3 makes an uncovered environmental constraint a blocker like a must-have rather than a
# warning like a should-have. `coverage-rollup.sh` already refuses to let a Scope deferral
# exclude one (spec 46, FR6, shipped in epic 46-01). This story puts `cpm:epics` on the same
# footing, and the interesting property is not either rule on its own — it is that the two
# components block on the *same set*.
#
# --- Why there are two assertions over one claim ------------------------------------
#
# Criterion 2 is a **correspondence** oracle: the blocking classes are derived from
# `epics/SKILL.md` and from `coverage-rollup.sh` independently and compared. Nothing is
# pinned, so renaming a class consistently in both places stays green — which is correct, and
# is the property a pinned assertion cannot have. Spec 46 asks for exactly this shape and says
# why: retro 24, where a template's `on 3` was changed to a code the script never returned and
# every assertion stayed green.
#
# But a correspondence oracle alone cannot tell "both sides block on the right classes" from
# "both sides block on everything". Retro 28's lesson, from this spec's own first epic: the
# load-bearing assertion was the control, because the positive criterion was satisfied by a
# guard that excluded nothing at all. So criterion 1 is asserted as an **inventory** — the
# blocking set is *exactly* must and environmental — which fails if `should` is ever admitted,
# including when it is admitted to both sides at once.
#
# Neither assertion subsumes the other, and the pair is what the story actually claims:
#
#   correspondence  — the two components agree with each other
#   inventory       — and what they agree on is the right set
#
# --- Why every extraction has a control stated before it ----------------------------
#
# Retro 30: in epic 46-02 an assertion of this exact shape went vacuous when one side stopped
# matching, and only its control noticed. Worse, the comparison had been written as a count of
# distinct values — `sort -u | grep -c .`, expect 1 — which *skips the empty line*, so a
# one-sided empty extraction still counted 1 and passed. Every comparison below is pairwise
# equality, never a count, and every extraction is asserted non-empty first.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

EPICS_SKILL="$SCRIPT_DIR/../../skills/epics/SKILL.md"
ROLLUP="$SCRIPT_DIR/../lib/coverage-rollup.sh"

echo "Testing cpm:epics' environmental gap check (Epic 46-03 Story 1)"

# The gap check, sliced from its own bold lead to the sentence that starts the next topic.
# Bounded because `epics/SKILL.md` is ~51k of prose containing many bold-lead bullets, and the
# extraction below matches bold-lead bullets by shape — unbounded, it would collect the
# skill's entire bullet vocabulary and the inventory assertion would report a set that has
# nothing to do with the gap check.
gap_check() {
  sed -n '/^\*\*Cross-epic gap check\*\*/,/^Present the full task tree/p' "$EPICS_SKILL"
}

# The section declares two kinds of gap and the correspondence oracle below is about only the
# first kind. **Uncovered** classes — a requirement no coverage matrix claims — are the ones
# `coverage-rollup.sh` also reasons about, so the two components must agree on that set.
# **Unreachable** is a gap in a requirement that *is* covered, found by reading the criteria;
# the roll-up counts ticks and structurally cannot see it, so demanding agreement there would
# force a class into the roll-up that the roll-up has no way to evaluate.
#
# So the harvest stops at the sentence that introduces the second kind. That narrowing is the
# dangerous edit in this file — it is also how someone could quietly drop a real uncovered class
# out of the oracle by moving its bullet below the boundary — so the boundary is not trusted:
# it is asserted to exist, to sit in the right place, and to have exactly the unreachable class
# beneath it.
UNCOVERED_BOUNDARY='^A third class is a gap'

uncovered_classes() {
  sed -n "/^\*\*Cross-epic gap check\*\*/,/$UNCOVERED_BOUNDARY/p" "$EPICS_SKILL"
}

# The roll-up's condition for letting a Scope deferral remove a requirement from the count.
# Sliced from the deferral test to the condition's own closing `)) {` rather than to a line
# number, so the slice tracks the code if it moves.
deferral_guards() {
  sed -n '/(label in deferred) &&/,/)) {/p' "$ROLLUP"
}

test_start "control: the gap-check slice is bounded"
assert_slice_bounded "$EPICS_SKILL" '^\*\*Cross-epic gap check\*\*' '^Present the full task tree' 5 20

test_start "control: the uncovered-class slice is bounded"
assert_slice_bounded "$EPICS_SKILL" '^\*\*Cross-epic gap check\*\*' "$UNCOVERED_BOUNDARY" 3 10

# If the boundary sentence ever stops matching, `sed` runs the range to end-of-file and the
# harvest silently becomes "every bold-lead bullet in a 51k skill" — which fails as a baffling
# inventory mismatch rather than as "the boundary moved". Assert it resolves, on its own.
test_start "control: the uncovered/unreachable boundary sentence resolves"
assert_equals "1" "$(gap_check | grep -c "$UNCOVERED_BOUNDARY")"

# Bounded for the same reason, and it is the less obvious of the two. If the deferral condition
# is reshaped so the closing `)) {` no longer terminates the range, the slice runs on and
# `grep -o '![a-z_]*('` collects every negated call after it. That direction fails *safe* — the
# derived set grows and the inventory catches it — but it fails as a confusing inventory
# mismatch rather than as "the slice stopped meaning what it says", which is a much longer
# debugging session for whoever hits it.
test_start "control: the roll-up's deferral-guard slice is bounded"
assert_slice_bounded "$ROLLUP" '(label in deferred) &&' ')) {' 2 8

# --- The two derivations ----------------------------------------------------------------
#
# Each side names its blocking classes in its own idiom, and each is reduced to the same
# canonical form — the class's first word, lowercased. On the skill side that is the bold lead
# of each blocking-class bullet; on the roll-up side it is the negated guard names in the
# deferral condition, stripped of their `is_` / `cov_is_` prefixes. Neither side is pinned to
# the other's spelling, which is what makes the comparison an oracle rather than two literals
# that happen to match.

EPICS_BLOCKING=$(uncovered_classes | grep -o '^- \*\*[A-Za-z ]*\*\*' | sed 's/^- \*\*//; s/\*\*$//' \
  | awk '{ print tolower($1) }' | LC_ALL=C sort -u)

ROLLUP_BLOCKING=$(deferral_guards | grep -o '![a-z_]*(' \
  | sed 's/^!//; s/($//; s/(//; s/^cov_is_//; s/^is_//' | LC_ALL=C sort -u)

# --- Criteria 3 and 2: non-empty on each side, then the comparison ----------------------
#
# `assert_agrees` emits the two non-empty controls and the comparison, in that order. Criterion
# 3 exists to demand precisely that ordering, so it is asserted by the helper that holds it
# rather than restated here.

assert_agrees "the blocking classes" \
  "epics/SKILL.md" "$EPICS_BLOCKING" \
  "coverage-rollup.sh" "$ROLLUP_BLOCKING"

# --- Criterion 1: and that set is must ∪ environmental, not everything -------------------
#
# The inventory. Stated on both sides rather than one, so a failure names which component
# drifted instead of only reporting that they disagree — and so that a class admitted to both
# at once still fails.

test_start "cpm:epics blocks on exactly the must-have and environmental classes"
assert_equals "$(printf 'environmental\nmust')" "$EPICS_BLOCKING"

test_start "and so does coverage-rollup.sh"
assert_equals "$(printf 'environmental\nmust')" "$ROLLUP_BLOCKING"

# --- Criterion 1: the environmental bullet is a GAP, not a warning -----------------------
#
# Position, not presence. The section names GAP classes and then, further down, says
# should-haves are warnings. A bullet that is present but sits below the warning sentence
# would satisfy any grep for it while meaning the opposite of AD3. Read as line offsets within
# the bounded slice.

GAP_LINE=$(gap_check | grep -n 'is a \*\*GAP\*\*' | head -1 | cut -d: -f1)
ENV_LINE=$(gap_check | grep -n '^- \*\*Environmental\*\*' | head -1 | cut -d: -f1)
WARN_LINE=$(gap_check | grep -n 'warnings, not blockers' | head -1 | cut -d: -f1)

test_start "control: the GAP declaration, the environmental bullet and the warning all resolve"
assert_equals "3" "$(printf '%s\n%s\n%s\n' "$GAP_LINE" "$ENV_LINE" "$WARN_LINE" | grep -c '^[0-9][0-9]*$')"

test_start "the environmental bullet sits under the GAP declaration, not under the warning"
assert_equals "yes" "$( [ "$GAP_LINE" -lt "$ENV_LINE" ] && [ "$ENV_LINE" -lt "$WARN_LINE" ] && echo yes || echo no )"

# --- The boundary is load-bearing, so assert what sits on each side of it ----------------
#
# Narrowing the harvest is only sound while exactly one class lives below the boundary and it is
# the one the roll-up cannot evaluate. These three assertions are what stop the narrowing from
# becoming a place to hide an uncovered class from the correspondence oracle.

test_start "the unreachable class is declared in the gap check"
assert_contains "$(gap_check)" '- **Unreachable**'

test_start "and is deliberately outside the set the roll-up is held to"
assert_not_contains "$(uncovered_classes)" '- **Unreachable**'

# Exactly one — so a future class added below the boundary has to be considered rather than
# inheriting the unreachable exemption by sitting in the same paragraph.
test_start "and it is the only class below the boundary"
assert_equals "1" "$(gap_check | sed -n "/$UNCOVERED_BOUNDARY/,\$p" | grep -c '^- \*\*[A-Za-z ]*\*\*')"

# Position, exactly as for the environmental bullet: below the boundary but still above the
# should-have warning, because an unreachable must-have blocks rather than warns.
THIRD_LINE=$(gap_check | grep -n "$UNCOVERED_BOUNDARY" | head -1 | cut -d: -f1)
UNREACH_LINE=$(gap_check | grep -n '^- \*\*Unreachable\*\*' | head -1 | cut -d: -f1)

# Both are compared arithmetically below, and an empty one makes `[` abort with a shell error
# rather than a test failure — the assertion still fails, but behind noise that reads like a
# broken suite instead of a moved bullet. Resolve them first, and substitute a sentinel so the
# comparison stays arithmetic either way.
test_start "control: the boundary and the unreachable bullet both resolve"
assert_equals "2" "$(printf '%s\n%s\n' "$THIRD_LINE" "$UNREACH_LINE" | grep -c '^[0-9][0-9]*$')"

: "${THIRD_LINE:=0}" "${UNREACH_LINE:=0}"

test_start "the unreachable bullet sits below the boundary and above the warning"
assert_equals "yes" "$( [ "$ENV_LINE" -lt "$THIRD_LINE" ] && [ "$THIRD_LINE" -lt "$UNREACH_LINE" ] \
  && [ "$UNREACH_LINE" -lt "$WARN_LINE" ] && echo yes || echo no )"

# The control retro 28 asks for. "Environmental is a GAP" is also satisfied by a check that
# blocks on everything, and the inventory above is what refuses that — but only while the
# should-have rule it is measured against still exists. Delete the warning sentence and the
# inventory still passes with the section saying nothing about should-haves at all.
test_start "control: an uncovered should-have is still a warning rather than a blocker"
assert_contains "$(gap_check)" "Should-have requirements not covered are warnings, not blockers."

# --- AD4 regression net: the skill states the convention it has to apply -----------------
#
# Not a criterion. AD4 puts the labelling convention in each of `spec`, `brief` and `epics`
# rather than in shared conventions, and Margot's one-definition constraint applies to the two
# lib seams, not to skill prose (`test-environmental-class.sh` scopes its inventory to
# `cpm/hooks/lib/*.sh` for the same reason). Without the label forms here the skill is told to
# classify by a name it is never given.

test_start "the environmental bullet names both label forms so the class is identifiable"
assert_contains "$(gap_check | grep '^- \*\*Environmental\*\*')" 'ENVn'

test_start "including the restriction form"
assert_contains "$(gap_check | grep '^- \*\*Environmental\*\*')" 'ENVXn'

test_summary
