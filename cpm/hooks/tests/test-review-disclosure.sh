#!/bin/bash
# test-review-disclosure.sh — Tests overflow disclosure and scope prioritisation.
#
# These back Epic 42-04 Story 2's `[integration]` acceptance criteria (spec 42 R5, and the
# NFR "Behaviour at Scale").
#
# --- What this suite does NOT test ----------------------------------------------------------
#
# **Whether the budget is the right budget.** What actually fits in one pass depends on the
# model, the files and the day; nothing here has an opinion about the number, only about
# what happens on each side of it. Nor does it test whether reviewing orphans first finds
# better problems — that is the spec's judgement, and this suite verifies only that the
# ordering it asks for is the ordering that happens.
#
# --- The two branches are compared, not merely visited ----------------------------------------
#
# The third criterion has two halves — gap queries available, gap queries absent — and a
# fallback that quietly ignored the gap queries would satisfy both if each were tested in
# its own fixture. So both run against the **same** change set with the **same** budget, and
# the orderings are asserted to differ. The fixture is built so the orphans sort *late*,
# because if they happened to sort first the two branches would agree and the comparison
# would prove nothing.
#
# The fallback branch is entered by unsetting `gap_orphans` in a subshell, which is the same
# condition a caller creates by not sourcing `gap-queries.sh` — not a test-only flag that
# nothing in production ever sets.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/git-fixture-helpers.sh"
source "$SCRIPT_DIR/../lib/changeset.sh"
source "$SCRIPT_DIR/../lib/changeset-resolve.sh"
source "$SCRIPT_DIR/../lib/linkset.sh"
source "$SCRIPT_DIR/../lib/linkset-join.sh"
source "$SCRIPT_DIR/../lib/gap-queries.sh"
source "$SCRIPT_DIR/../lib/review.sh"
source "$SCRIPT_DIR/stub-link-adapter.sh"

echo "Testing overflow disclosure and scope prioritisation..."
echo ""

TAB="$REVIEW_TAB"

examined_of()   { printf '%s\n' "$1" | awk -F'\t' '$1 == "EXAMINED"   { print $2 }'; }
unexamined_of() { printf '%s\n' "$1" | awk -F'\t' '$1 == "UNEXAMINED" { print $2 }'; }

# --- Fixture -----------------------------------------------------------------------------
#
# Five files. `src/a.sh`, `src/b.sh` and `src/c.sh` are linked; `src/d.sh` and `src/e.sh`
# are orphans — deliberately the two that sort *last*, so orphan priority and change-set
# order cannot coincide.

REPO=$(git_fixture_create disclosure)
git_fixture_commit "$REPO" "chore: seed" -- README.md "seed"
BASE=$(git_fixture_git "$REPO" rev-parse HEAD)
git_fixture_commit "$REPO" "feat: five files" -- \
  src/a.sh "a" src/b.sh "b" src/c.sh "c" src/d.sh "d" src/e.sh "e"

CHANGESET="$TEST_TMPDIR/changeset"
changeset_resolve_git "$REPO" --since "$BASE" > "$CHANGESET"
ALL_FILES=$(changeset_files < "$CHANGESET")
TOTAL=$(printf '%s\n' "$ALL_FILES" | grep -c '[^[:space:]]')

stub_link_records \
  "INTENT${TAB}epic 42-04${TAB}open${TAB}Change-Set Review" \
  "LINK${TAB}src/a.sh${TAB}epic 42-04${TAB}derived" \
  "LINK${TAB}src/b.sh${TAB}epic 42-04${TAB}derived" \
  "LINK${TAB}src/c.sh${TAB}epic 42-04${TAB}declared"

linkset_reset
linkset_register stub
JOINED=$(linkset_join "$REPO" "$CHANGESET")

# --- The fixture separates the two branches ---------------------------------------------------

# Asserted first, because every comparison below is vacuous if the orphans already sort
# first: the two orderings would agree and a fallback ignoring the gap queries would pass.
test_start "the fixture's orphans sort last, so orphan priority cannot coincide with file order"
ORPHANS=$(printf '%s\n' "$JOINED" | gap_orphans "$CHANGESET")
assert_equals "src/d.sh
src/e.sh" "$ORPHANS"

test_start "and there are linked files for them to be prioritised ahead of"
assert_equals "3" "$(LC_ALL=C comm -23 <(printf '%s\n' "$ALL_FILES") <(printf '%s\n' "$ORPHANS") | wc -l | tr -d ' ')"

# --- Criterion: prioritisation, and its fallback ------------------------------------------------

FULL_WITH=$(printf '%s\n' "$JOINED" | review_select "$CHANGESET" "$TOTAL")
FULL_WITHOUT=$(printf '%s\n' "$JOINED" | ( unset -f gap_orphans; review_select "$CHANGESET" "$TOTAL" ))

test_start "with the gap queries available the order is orphans first"
assert_equals "src/d.sh
src/e.sh
src/a.sh
src/b.sh
src/c.sh" "$(examined_of "$FULL_WITH")"

test_start "without them the order falls back to change-set order"
assert_equals "$ALL_FILES" "$(examined_of "$FULL_WITHOUT")"

# The comparison the criterion actually turns on. Same change set, same budget, same link
# set — only the availability of the gap queries differs, so only prioritisation can explain
# a difference in the result.
test_start "the two branches produce different orders for identical input"
if [ "$(examined_of "$FULL_WITH")" = "$(examined_of "$FULL_WITHOUT")" ]; then
  test_fail "Both branches produced the same order, so prioritisation is unproven"
else
  test_pass
fi

test_start "each branch names which one it took"
assert_equals "orphans-first|deterministic" \
  "$(printf '%s\n' "$FULL_WITH" | awk -F'\t' '$1 == "ORDER" { print $2 }')|$(printf '%s\n' "$FULL_WITHOUT" | awk -F'\t' '$1 == "ORDER" { print $2 }')"

# Reordering must not become losing or duplicating. The set is asserted rather than the
# sequence, so this holds whatever the priority rule becomes later.
test_start "prioritising reorders the change set without adding or losing a file"
assert_equals "$ALL_FILES" "$(examined_of "$FULL_WITH" | LC_ALL=C sort)"

# --- Criterion: the files not examined are listed explicitly --------------------------------------

PARTIAL=$(printf '%s\n' "$JOINED" | review_select "$CHANGESET" 2)

# Derived, not pinned. `comm` against the examined list means this assertion still holds
# when the fixture gains a file, where a literal expected list would silently go stale —
# an invariant asserted against a pinned value is still a snapshot.
test_start "the unexamined list is exactly the change set minus what was examined"
assert_equals "$(LC_ALL=C comm -23 <(printf '%s\n' "$ALL_FILES") <(examined_of "$PARTIAL" | LC_ALL=C sort))" \
  "$(unexamined_of "$PARTIAL" | LC_ALL=C sort)"

test_start "examined and unexamined together account for every file, with none counted twice"
assert_equals "$ALL_FILES" \
  "$( { examined_of "$PARTIAL"; unexamined_of "$PARTIAL"; } | LC_ALL=C sort -u)"

test_start "the budget is honoured exactly, not approximately"
assert_equals "2" "$(examined_of "$PARTIAL" | wc -l | tr -d ' ')"

test_start "under a budget the orphans are the ones that get examined"
assert_equals "$ORPHANS" "$(examined_of "$PARTIAL")"

test_start "coverage reports both numbers"
assert_equals "COVERAGE${TAB}2${TAB}${TOTAL}" "$(printf '%s\n' "$PARTIAL" | grep '^COVERAGE')"

# --- Criterion (must NOT): a partial review must not present as complete ----------------------------

test_start "a partial selection is marked incomplete"
assert_equals "COMPLETE${TAB}no" "$(printf '%s\n' "$PARTIAL" | grep '^COMPLETE')"

test_start "a selection that fits is marked complete"
assert_equals "COMPLETE${TAB}yes" "$(printf '%s\n' "$FULL_WITH" | grep '^COMPLETE')"

test_start "a complete selection discloses nothing, because there is nothing to disclose"
assert_empty "$(unexamined_of "$FULL_WITH")"

PARTIAL_RENDER=$(printf '%s\n' "$PARTIAL" | review_render_coverage)
FULL_RENDER=$(printf '%s\n' "$FULL_WITH" | review_render_coverage)

test_start "the partial rendering says so, and names every file it did not reach"
assert_equals "PARTIAL REVIEW - examined 2 of 5 file(s). Not examined:
  src/a.sh
  src/b.sh
  src/c.sh" "$PARTIAL_RENDER"

test_start "the complete rendering claims the whole change set"
assert_equals "reviewed all 5 file(s) in the change set" "$FULL_RENDER"

# The must-NOT itself. Both are renderings of a review that ran; one may claim completeness
# and the other may not, and no reader should have to count to tell them apart.
test_start "the two renderings cannot be mistaken for one another"
if [ -z "$PARTIAL_RENDER" ] || [ -z "$FULL_RENDER" ]; then
  test_fail "Positive control failed: a rendering was empty, so 'they differ' proves nothing"
elif [ "$PARTIAL_RENDER" = "$FULL_RENDER" ]; then
  test_fail "A partial review rendered identically to a complete one"
else
  test_pass
fi

# A count would let a reader move on without checking. The criterion says "listed
# explicitly", and this is the assertion that a summary line cannot satisfy.
test_start "the disclosure lists each skipped file rather than counting them"
assert_equals "3" "$(printf '%s\n' "$PARTIAL_RENDER" | grep -c '^  src/')"

# --- Edges ---------------------------------------------------------------------------------------

test_start "a zero budget examines nothing and discloses everything"
ZERO=$(printf '%s\n' "$JOINED" | review_select "$CHANGESET" 0)
assert_equals "0|$TOTAL|no" \
  "$(examined_of "$ZERO" | grep -c '[^[:space:]]')|$(unexamined_of "$ZERO" | wc -l | tr -d ' ')|$(printf '%s\n' "$ZERO" | awk -F'\t' '$1 == "COMPLETE" { print $2 }')"

test_start "a budget larger than the change set is complete rather than an error"
BIG=$(printf '%s\n' "$JOINED" | review_select "$CHANGESET" 999)
assert_equals "COMPLETE${TAB}yes" "$(printf '%s\n' "$BIG" | grep '^COMPLETE')"

test_start "a non-numeric budget is refused rather than silently treated as zero"
printf '%s\n' "$JOINED" | review_select "$CHANGESET" "lots" >/dev/null 2>&1
assert_equals "1" "$?"

test_start "an empty budget is refused, since a missing limit is not an unlimited one"
printf '%s\n' "$JOINED" | review_select "$CHANGESET" "" >/dev/null 2>&1
assert_equals "1" "$?"

test_start "a missing change set errors rather than reviewing nothing and calling it complete"
printf '' | review_select "$TEST_TMPDIR/no-such-changeset" 5 >/dev/null 2>&1
assert_equals "1" "$?"

test_summary
