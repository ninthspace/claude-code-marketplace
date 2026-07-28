#!/bin/bash
# test-epics-reachability.sh — `cpm:epics` requires a criterion describing the way in, and
# gap-checks a Must Have that has none.
#
# The defect this guards against is not a criterion that fails the testability standard. It is a
# criterion that *passes* it. "Submitting valid credentials returns 200 with a session token" is
# specific, observable and verifiable; a test asserts it by posting to the route; the coverage
# matrix ticks the row honestly. Every gate in the chain says yes, and nothing in the chain ever
# asks whether a person can reach the route — so a spec can be fully covered, fully ticked and
# fully tested by a delivered system no one can get into.
#
# That makes the requirement here a **pair**, and both halves have to be asserted separately:
#
#   Step 3  — the standard that makes an affordance criterion required when the requirement
#             names a user action
#   Step 4  — the gap check that blocks a Must Have covered only by response criteria
#
# Step 4's half lives in `test-epics-environmental-gap.sh`, which owns that section's class
# inventory and asserts the unreachable class sits below the uncovered/unreachable boundary and
# above the should-have warning. This suite does not duplicate it. What this suite adds is the
# seam between the two: Step 4 cites the standard by name, and a citation that resolves to
# nothing is the retro 24 failure mode exactly — a reference changed on one side while every
# assertion stayed green.
#
# --- Which assertions are oracles ---------------------------------------------------
#
# **One is.** The cross-reference below derives the standards Step 3 *declares* and the standards
# Step 4 *cites*, independently, and requires every citation to resolve. Nothing is pinned to a
# spelling, so renaming the standard in both places stays green — which is correct — while
# renaming it in one place fails.
#
# **The rest are regression nets over prose**, and are labelled as such rather than dressed up.
# A skill instruction cannot be executed by a test, so what these can do is notice deletion and
# notice the specific weakening that produced the defect in the first place: an exemplar that
# presents a response-only criterion as the finished article. That exemplar assertion matters
# more than its shape suggests — the guidance is copied from, so a worked example demonstrating
# the failure mode teaches it faster than the surrounding paragraph forbids it.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

EPICS_SKILL="$SCRIPT_DIR/../../skills/epics/SKILL.md"

echo "Testing cpm:epics' reachability standard and unreachable gap class"

# Step 3 as a whole, for the declared-standards inventory. The reachability standard is not the
# only standard the step states, and the oracle is about the set, not about one member.
step3() {
  awk '/^### Step 3: Break into Stories/,/^### Step 3b/' "$EPICS_SKILL"
}

gap_check() {
  sed -n '/^\*\*Cross-epic gap check\*\*/,/^Present the full task tree/p' "$EPICS_SKILL"
}

test_start "control: the Step 3 slice is bounded"
assert_slice_bounded "$EPICS_SKILL" '^### Step 3: Break into Stories' '^### Step 3b' 30 120

# --- The suite finds the standard the way a reader would: by following the citation ------
#
# The obvious way to slice Step 3's standard is to `sed` for its literal name. That makes the
# suite a third place the name is written, so renaming it consistently in the skill's two sites
# — a change that alters nothing — turns the suite red for a reason that has nothing to do with
# the rename. Retro 31 called that out: a two-sided mutation should stay green, and a suite that
# fails it is measuring its own spelling.
#
# So the name is read out of Step 4's citation and used to locate Step 3's declaration. Rename
# both sites and everything below still resolves; rename one and the oracle fires. The suite
# never spells the standard's name at all.
STANDARD=$(gap_check | grep -o '\*\*[A-Za-z -]*standard\*\*' | head -1)

test_start "control: the gap check cites exactly one standard, which the slice below follows"
assert_equals "1" "$(gap_check | grep -o '\*\*[A-Za-z -]*standard\*\*' | LC_ALL=C sort -u | grep -c .)"

# Sliced from the cited standard's own bold lead to the bold lead that starts the next topic.
# Bounded because `epics/SKILL.md` is ~51k of prose and the extractions below match by shape —
# unbounded, they would collect the skill's entire bullet and bold-lead vocabulary.
STANDARD_RE="^$(printf '%s' "$STANDARD" | sed 's/[*]/\\*/g')"

reachability() {
  sed -n "/$STANDARD_RE/,/^\*\*Test approach tag propagation\*\*/p" "$EPICS_SKILL"
}

test_start "control: the cited standard resolves to a bounded section in Step 3"
assert_slice_bounded "$EPICS_SKILL" "$STANDARD_RE" '^\*\*Test approach tag propagation\*\*' 4 12

# --- The oracle: Step 4's citation resolves to a standard Step 3 declares ----------------
#
# Derived from each side in its own idiom — Step 3 declares standards as bold leads at the start
# of a line, Step 4 cites one mid-sentence — and compared as sets. A citation with no declaration
# is the failure; a declaration with no citation is not (Step 3 states more standards than Step 4
# has reason to name), so this is a subset check rather than equality.

DECLARED=$(step3 | grep -o '^\*\*[A-Za-z -]*standard\*\*' | LC_ALL=C sort -u)
CITED=$(gap_check | grep -o '\*\*[A-Za-z -]*standard\*\*' | LC_ALL=C sort -u)

test_start "control: Step 3 declares at least one standard"
assert_equals "non-empty" "$( [ -n "$DECLARED" ] && echo non-empty || echo empty )"

test_start "control: the gap check cites at least one standard"
assert_equals "non-empty" "$( [ -n "$CITED" ] && echo non-empty || echo empty )"

# `comm` needs sorted input, which both sides already are. Empty output means every citation
# resolved. Asserted as the empty string rather than as a count, so a one-sided empty extraction
# cannot pass by arithmetic — retro 30's lesson, where `grep -c` over a set that skipped the
# empty line counted 1 and passed.
test_start "every standard the gap check cites is one Step 3 actually declares"
assert_equals "" "$(comm -13 <(printf '%s\n' "$DECLARED") <(printf '%s\n' "$CITED"))"

# --- Regression nets over the standard's prose ------------------------------------------
#
# Deletion, and the two weakenings that would leave the section present but toothless.

test_start "the standard requires a criterion naming the affordance, not merely the outcome"
assert_contains "$(reachability)" 'at least one criterion must name the affordance that reaches it'

# The affordance criterion is *additional*. A version that let it stand in for the response
# criterion would trade one half-covered requirement for the other half.
test_start "the affordance criterion is required alongside the response criterion, not instead of it"
assert_contains "$(reachability)" 'neither substitutes for the other'

# --- The exemplar ------------------------------------------------------------------------
#
# The load-bearing regression net. Guidance is copied from, so which example wears which label
# decides what gets written far more than the paragraph above it does. A response-only criterion
# labelled as the passing form teaches the defect directly.

INCOMPLETE=$(reachability | grep '^- \*\*Incomplete\*\*')
COMPLETE=$(reachability | grep '^- \*\*Complete\*\*')

test_start "control: both halves of the worked example resolve"
assert_equals "2" "$(printf '%s\n%s\n' "$INCOMPLETE" "$COMPLETE" | grep -c '^- \*\*')"

test_start "the response-only criterion is the one labelled incomplete"
assert_contains "$INCOMPLETE" 'returns 200'

test_start "and the complete form adds to that criterion rather than replacing it"
assert_contains "$COMPLETE" 'that criterion, plus'

# A response-only example presented as complete is the exact shape being guarded against, so
# assert its absence rather than inferring it from the two assertions above.
test_start "the complete form is not itself a bare response claim"
assert_not_contains "$COMPLETE" 'returns 200 with a session token" — '

test_summary
