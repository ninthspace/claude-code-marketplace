#!/bin/bash
# test-gap-degradation.sh — Tests the review surviving a repository it cannot read.
#
# These back Epic 42-03 Story 3's `[integration]` acceptance criteria (spec 42 R9), and
# double as the epic's cross-story verification: Stories 1 and 2 are exercised together
# here, under the one condition where their correct behaviours differ.
#
# **R3 and R4 degrade in opposite directions, and that is the whole story.** With nothing
# resolving anything, "every file is an orphan" is the *right answer* to R3 — the spec says
# so in as many words, because an orphan is defined by the absence of a link and absence is
# what a silent channel establishes. R4 cannot do the same: "no unbacked claims" asserts
# that claims were examined, and a channel carrying no claims examined none. A review that
# rendered both halves the same way would be wrong about one of them, and the assertion
# that catches it compares the two renderings in the same breath.
#
# **Every "nothing found" here carries a control.** In a fixture built specifically so that
# nothing resolves, an empty result is the expected outcome of both a working query and a
# broken one — so the suite asserts counts against the change-set total rather than
# emptiness, and keeps a repository where the same calls do find links.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/git-fixture-helpers.sh"
source "$SCRIPT_DIR/../lib/changeset.sh"
source "$SCRIPT_DIR/../lib/changeset-resolve.sh"
source "$SCRIPT_DIR/../lib/linkset.sh"
source "$SCRIPT_DIR/../lib/linkset-join.sh"
source "$SCRIPT_DIR/../lib/link-adapter-git.sh"
source "$SCRIPT_DIR/../lib/link-adapter-cpm.sh"
source "$SCRIPT_DIR/../lib/gap-queries.sh"

echo "Testing the review under zero-adapter degradation..."
echo ""

TAB="$LINKSET_TAB"

# --- Fixture: a repository with nothing CPM or git-native can read ------------------------
#
# No `docs/epics/`, no commit trailers, no conventional-commit scope, and left on `main`
# so the branch signal is refused too. Every channel both real adapters read is absent, and
# none of that is an error — it is what most repositories look like.

BARE=$(git_fixture_create bare-review)
git_fixture_commit "$BARE" "initial import" -- README.md "readme"
BARE_BASE=$(git_fixture_git "$BARE" rev-parse HEAD)
git_fixture_commit "$BARE" "tidy up the helpers" -- \
  src/one.sh "one" src/two.sh "two" lib/three.sh "three"

BARE_CS="$TEST_TMPDIR/cs-bare"
changeset_resolve_git "$BARE" --since "$BARE_BASE" > "$BARE_CS"
BARE_FILES=$(changeset_files < "$BARE_CS")
BARE_COUNT=$(printf '%s\n' "$BARE_FILES" | grep -c '[^[:space:]]')

# --- Criterion: the review still runs, and must NOT hard-fail ------------------------------

# Asserted first and separately from what the review says. "Produces a review" and
# "produces the right review" are different claims, and the must-NOT is about the first.
test_start "the join succeeds in a repository both real adapters have nothing to say about"
linkset_reset && linkset_register gitnative && linkset_register cpm
BARE_JOINED=$(linkset_join "$BARE" "$BARE_CS" 2>"$TEST_TMPDIR/err")
assert_equals "0" "$?"

test_start "the review runs to completion rather than hard-failing"
BARE_REPORT=$(printf '%s\n' "$BARE_JOINED" | gap_report "$BARE" "$BARE_CS" 2>"$TEST_TMPDIR/err")
assert_equals "0" "$?"

test_start "with no adapters registered at all the review still runs"
linkset_reset
ZERO_JOINED=$(linkset_join "$BARE" "$BARE_CS")
ZERO_REPORT=$(printf '%s\n' "$ZERO_JOINED" | gap_report "$BARE" "$BARE_CS" 2>"$TEST_TMPDIR/err")
assert_equals "0" "$?"

test_start "nothing was written to stderr — a silent channel is not a warning"
assert_empty "$(cat "$TEST_TMPDIR/err")"

# --- Criterion: every file is reported as an orphan ------------------------------------------

# Stated as a count against the change-set total rather than as a list comparison, because
# the fixture was built so that nothing resolves: an empty orphan list and a full one are
# both "no output" shaped, and only the denominator tells them apart.
test_start "every file in the change set is reported as an orphan"
assert_equals "ORPHANS${TAB}${BARE_COUNT}${TAB}${BARE_COUNT}" \
  "$(printf '%s\n' "$BARE_REPORT" | grep '^ORPHANS')"

test_start "the fixture really does have files to orphan, so that count means something"
if [ "$BARE_COUNT" -lt 2 ]; then
  test_fail "Positive control failed: the change set has $BARE_COUNT file(s), so 'all of them' proves little"
else
  test_pass
fi

test_start "each orphaned file is named, not merely counted"
assert_equals "$BARE_FILES" "$(printf '%s\n' "$BARE_REPORT" | awk -F'\t' '$1 == "ORPHAN" { print $2 }')"

test_start "the zero-adapter and no-channel configurations agree"
assert_equals "$(printf '%s\n' "$BARE_REPORT" | grep '^ORPHAN')" \
  "$(printf '%s\n' "$ZERO_REPORT" | grep '^ORPHAN')"

# The control that makes every assertion above mean something. The same functions, the same
# registration, a repository that does carry provenance — if this reported everything
# orphaned too, the fixture above would be proving nothing about degradation.
test_start "the same calls on a repository with provenance do not orphan everything"
RICH=$(git_fixture_create rich-review)
git_fixture_commit "$RICH" "chore: seed" -- README.md "seed"
RICH_BASE=$(git_fixture_git "$RICH" rev-parse HEAD)
git_fixture_commit "$RICH" "feat: land it" --trailer "Refs: epic 42-03" -- src/one.sh "one"
changeset_resolve_git "$RICH" --since "$RICH_BASE" > "$TEST_TMPDIR/cs-rich"
linkset_reset && linkset_register gitnative && linkset_register cpm
RICH_REPORT=$(linkset_join "$RICH" "$TEST_TMPDIR/cs-rich" | gap_report "$RICH" "$TEST_TMPDIR/cs-rich")
assert_equals "ORPHANS${TAB}0${TAB}1" "$(printf '%s\n' "$RICH_REPORT" | grep '^ORPHANS')"

# --- The asymmetry: R3 degrades into a finding, R4 into a refusal ----------------------------

test_start "R4 reports that it cannot answer rather than that it found nothing"
assert_equals "ANSWERABILITY${TAB}unanswerable" \
  "$(printf '%s\n' "$BARE_REPORT" | grep '^ANSWERABILITY')"

test_start "R4 examined no claims, and says zero of zero rather than zero of nothing"
assert_equals "CLAIMS${TAB}0${TAB}0" "$(printf '%s\n' "$BARE_REPORT" | grep '^CLAIMS')"

# The heart of it. Both halves are empty; one is a result and one is a refusal, and the
# rendering must not let a reader mistake the second for the first.
test_start "the two halves render as a finding and a refusal, not as two findings"
RENDERED=$(printf '%s\n' "$BARE_REPORT" | gap_render)
assert_equals "3 of 3 file(s) changed with no intent behind them
not answerable - no active adapter carries verification claims" "$RENDERED"

test_start "the review renders both halves, never only the half it can speak to"
assert_equals "2" "$(printf '%s\n' "$RENDERED" | grep -c '[^[:space:]]')"

# --- Cross-story: the combined report agrees with the queries it is built from -----------------

# Story 3's note calls this the epic's cross-story verification. Stories 1 and 2 each test
# their own query in isolation; nothing until here checks that the review a caller actually
# runs returns what those queries return.
test_start "the report's orphan records match the orphan query run alone"
assert_equals "$(printf '%s\n' "$BARE_JOINED" | gap_orphans "$BARE_CS")" \
  "$(printf '%s\n' "$BARE_REPORT" | awk -F'\t' '$1 == "ORPHAN" { print $2 }')"

test_start "the report's counts match the orphan counts run alone"
assert_equals "$(printf '%s\n' "$BARE_JOINED" | gap_orphan_counts "$BARE_CS")" \
  "$(printf '%s\n' "$BARE_REPORT" | awk -F'\t' '$1 == "ORPHANS" { print $2 "\t" $3 }')"

# The same agreement in a repository where both queries have something to say — the bare
# fixture agrees trivially, since both sides are empty on the R4 half.
test_start "the report agrees with both queries in a repository that answers them"
CROSS=$(git_fixture_create cross-check)
git_fixture_commit "$CROSS" "chore: seed" -- README.md "seed"
CROSS_BASE=$(git_fixture_git "$CROSS" rev-parse HEAD)
git_fixture_commit "$CROSS" "feat: land alpha" -- \
  "docs/epics/42-09-epic-alpha.md" "# Alpha

**Source spec**: docs/specifications/42-spec-change-set-review.md
**Status**: Complete

## Do the thing
**Story**: 1
**Status**: Complete
**Satisfies**: R1
" \
  src/alpha.sh "alpha" src/loose.sh "loose"
changeset_resolve_git "$CROSS" --since "$CROSS_BASE" > "$TEST_TMPDIR/cs-cross"
linkset_reset && linkset_register gitnative && linkset_register cpm
CROSS_JOINED=$(linkset_join "$CROSS" "$TEST_TMPDIR/cs-cross")
CROSS_REPORT=$(printf '%s\n' "$CROSS_JOINED" | gap_report "$CROSS" "$TEST_TMPDIR/cs-cross")
assert_equals "$(printf '%s\n' "$CROSS_JOINED" | gap_unbacked "$CROSS")" \
  "$(printf '%s\n' "$CROSS_REPORT" | awk -F'\t' '$1 == "UNBACKED" { print $2 }')"

# That cross-check repository has claims and no tests, so R4 is answerable *and* finds
# something. Without this, the agreement above holds over two empty lists.
test_start "that cross-check really does exercise an answerable R4 with a finding"
assert_equals "answerable|2" \
  "$(printf '%s\n' "$CROSS_REPORT" | awk -F'\t' '$1 == "ANSWERABILITY" { print $2 }')|$(printf '%s\n' "$CROSS_REPORT" | awk -F'\t' '$1 == "CLAIMS" { print $2 }')"

# --- Bad input still errors -------------------------------------------------------------------

# R9 says absence of provenance is never a failure. It does not say absence of a repository
# is fine, and a review that shrugged at a missing change set would report every file in it
# as an orphan — of zero files.
test_start "a missing change set errors rather than producing an empty review"
printf '' | gap_report "$BARE" "$TEST_TMPDIR/no-such-changeset" >/dev/null 2>&1
assert_equals "1" "$?"

test_start "a missing repository errors rather than producing an empty review"
printf '' | gap_report "$TEST_TMPDIR/no-such-repo" "$BARE_CS" >/dev/null 2>&1
assert_equals "1" "$?"

test_summary
