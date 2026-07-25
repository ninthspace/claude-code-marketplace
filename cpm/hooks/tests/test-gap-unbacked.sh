#!/bin/bash
# test-gap-unbacked.sh — Tests the unbacked-claims query and its answerability half.
#
# These back Epic 42-03 Story 2's `[integration]` acceptance criteria (spec 42 R4).
#
# **Two things are being tested and only one of them is a list.** The query finds claims no
# test names; the answerability report decides whether the query was in a position to find
# anything at all. R4's must-NOT is about the second, and it is the harder half — an empty
# list is produced identically by "everything is backed" and by "no adapter here can tell
# you", and the first is a lie told most confidently in exactly the repositories a reader
# would most trust it.
#
# --- The fixture separates two readings of "naming", deliberately -----------------------
#
# `test-alpha.sh` cites Epic 42-01 in its header and mentions epic 42-02 in a passing
# remark that tests nothing. Under the reading settled at this story's gate — any mention
# in a test file counts — epic 42-02 is *backed* by that remark. Under a header-only
# reading it would not be. The assertion below pins the chosen reading and, in doing so,
# records its cost in executable form: this is the query under-reporting a real gap, which
# is the unsafe direction, and it is asserted rather than left as a footnote.
#
# --- All three exit codes, not the two the criteria name --------------------------------
#
# Retro 20 found `changeset_intent_answerable` treating an *erroring* adapter as having
# answered, and named R4 as the requirement that conflation would defeat — two epics before
# R4 existed. The contract has three exit codes; this story's criteria name none of them.
# So answerability is exercised against all three, and the `exit 1` case is the one no
# criterion asked for.

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

echo "Testing the unbacked-claims query..."
echo ""

TAB="$LINKSET_TAB"

# --- Adapters with controllable capability and exit code -------------------------------
#
# Local rather than added to stub-link-adapter.sh: capability is a Story 2 concept, and the
# shared stub is the asset Epic 42-02's conformance suite runs against.

CAPABLE_RC=0
capable_link_capabilities() { printf 'criteria\n'; }
capable_link_changeset()    { return "$CAPABLE_RC"; }

# Declares a capability it does not spell `criteria`. An adapter may carry any number of
# capabilities this query knows nothing about, and none of them make it answer R4.
othercap_link_capabilities() { printf 'provenance\n'; }
othercap_link_changeset()    { return 0; }

# No capability companion at all — the shape every adapter written before the convention
# existed has, and the shape `gitnative` still has.
silent_link_changeset() { return 0; }

# --- Fixture -----------------------------------------------------------------------------

REPO=$(git_fixture_create unbacked)
git_fixture_commit "$REPO" "chore: seed" -- README.md "seed"
BASE=$(git_fixture_git "$REPO" rev-parse HEAD)

git_fixture_commit "$REPO" "feat: land both epics" -- \
  "docs/epics/42-01-epic-alpha.md" "# Alpha

**Source spec**: docs/specifications/42-spec-change-set-review.md
**Status**: Complete

## Resolve the thing
**Story**: 1
**Status**: Complete
**Satisfies**: R1

## Defer the other thing
**Story**: 2
**Status**: Pending
**Satisfies**: R2
" \
  "docs/epics/42-01-coverage-alpha.md" "# Coverage Matrix: Alpha

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|---|---|---|---|---|---|
| 1 | R1 | Resolve the thing. | The thing resolves | Story 1 | \`[integration]\` | ✓ |
| 2 | R2 | Defer the other thing. | The other thing is deferred | Story 2 | \`[integration]\` |  |
" \
  "docs/epics/42-02-epic-beta.md" "# Beta

**Source spec**: docs/specifications/42-spec-change-set-review.md
**Status**: Complete

## Join the things
**Story**: 1
**Status**: Complete
**Satisfies**: R7
" \
  "tests/test-alpha.sh" "#!/bin/bash
# These back Epic 42-01 Story 1's [integration] acceptance criteria.

assert_equals \"resolved\" \"\$(resolve_the_thing)\"

# Unlike epic 42-02, this suite does not reach the join at all.
" \
  "src/alpha.sh" "alpha"

CHANGESET="$TEST_TMPDIR/changeset"
changeset_resolve_git "$REPO" --since "$BASE" > "$CHANGESET"

linkset_reset
linkset_register cpm
JOINED=$(linkset_join "$REPO" "$CHANGESET")

# --- The claims themselves ----------------------------------------------------------------

# Asserted before anything rests on it. A claim set that quietly came back empty would make
# every "no unbacked claims" assertion below true for the wrong reason.
test_start "the claim set is the intents asserting completion, and nothing else"
assert_equals "epic 42-01
epic 42-02
story 42-01.1
story 42-02.1" "$(printf '%s\n' "$JOINED" | gap_claims)"

# `story 42-01.2` is Pending with an unverified row, so it asserts nothing and cannot be an
# unbacked claim. R4 is about claims that were *made*, not work that is unfinished.
test_start "a story that claims nothing is not a claim, however untested it is"
assert_empty "$(printf '%s\n' "$JOINED" | gap_claims | grep -F 'story 42-01.2')"

# --- Criterion: a verified claim with no test naming it is listed ---------------------------

UNBACKED=$(printf '%s\n' "$JOINED" | gap_unbacked "$REPO")

test_start "a claim no test names anywhere is listed as unbacked"
assert_equals "story 42-02.1" "$UNBACKED"

test_start "a claim whose epic and story a test header cites is not unbacked"
assert_empty "$(printf '%s\n' "$UNBACKED" | grep -F 'story 42-01.1')"

# The CPM header convention writes "Epic 42-01 Story 1"; the adapter emits `story 42-01.1`.
# Without the alternate spelling every story-level claim in every repository would report
# unbacked, and R4's output would be noise rather than a finding.
test_start "a story claim is matched through the spelling test headers actually use"
assert_equals "story 42-01.1
epic 42-01 Story 1" "$(_gap_id_spellings 'story 42-01.1')"

test_start "matching is case-insensitive, since headers capitalise what the adapter does not"
assert_empty "$(printf '%s\n' "$UNBACKED" | grep -F 'epic 42-01')"

# --- The separating case, and the cost of the chosen reading --------------------------------

# `epic 42-02` is named only by a remark that tests nothing — "Unlike epic 42-02, this suite
# does not reach the join at all." Under the reading settled at this story's gate it counts,
# so the claim reports backed. That is this query under-reporting a real gap, and it is
# asserted here so the trade-off is visible in the suite rather than only in a comment.
test_start "a passing mention in a test backs a claim, which is the chosen reading's cost"
assert_empty "$(printf '%s\n' "$UNBACKED" | grep -F 'epic 42-02')"

# The control for the assertion above: it is only evidence about *mentions* if the mention
# is genuinely all there is. If a real assertion in that file named epic 42-02, the test
# above would pass while proving nothing.
test_start "that mention really is the only thing naming it, and it tests nothing"
assert_equals "1|0" "$(grep -ciF 'epic 42-02' "$REPO/tests/test-alpha.sh")|$(grep -cE '^[[:space:]]*assert.*42-02' "$REPO/tests/test-alpha.sh")"

# --- Counts and the report shape ------------------------------------------------------------

REPORT=$(printf '%s\n' "$JOINED" | gap_unbacked_report "$REPO" "$CHANGESET")

test_start "the report carries a denominator, not an unbacked count alone"
assert_equals "CLAIMS${TAB}1${TAB}4" "$(printf '%s\n' "$REPORT" | grep '^CLAIMS')"

test_start "the report lists each unbacked claim as its own record"
assert_equals "UNBACKED${TAB}story 42-02.1" "$(printf '%s\n' "$REPORT" | grep '^UNBACKED')"

# --- Criterion (must NOT): answerable and answered-empty must not look alike -----------------

test_start "with a claims-carrying adapter that read this repository, R4 is answerable"
assert_equals "answerable" "$(gap_r4_answerability "$REPO" "$CHANGESET")"

# Only git-native: it records why a change happened, never whether it was checked.
test_start "an adapter with no capability companion cannot answer R4"
linkset_reset && linkset_register gitnative && linkset_register silent
assert_equals "unanswerable" "$(gap_r4_answerability "$REPO" "$CHANGESET")"

test_start "an adapter declaring some other capability still cannot answer R4"
linkset_reset && linkset_register othercap
assert_equals "unanswerable" "$(gap_r4_answerability "$REPO" "$CHANGESET")"

test_start "no adapters at all cannot answer R4"
linkset_reset
assert_equals "unanswerable" "$(gap_r4_answerability "$REPO" "$CHANGESET")"

# Capability is necessary and not sufficient. The CPM adapter declares `criteria` and still
# cannot answer in a repository with no `docs/epics/` — it declines with exit 2.
test_start "a capable adapter that declines this repository cannot answer here"
NOEPICS=$(git_fixture_create no-epics)
git_fixture_commit "$NOEPICS" "chore: seed" -- README.md "seed"
NOEPICS_BASE=$(git_fixture_git "$NOEPICS" rev-parse HEAD)
git_fixture_commit "$NOEPICS" "feat: work" -- src/x.txt "x"
changeset_resolve_git "$NOEPICS" --since "$NOEPICS_BASE" > "$TEST_TMPDIR/cs-noepics"
linkset_reset && linkset_register cpm
assert_equals "unanswerable" "$(gap_r4_answerability "$NOEPICS" "$TEST_TMPDIR/cs-noepics")"

# The control for the test above: the same adapter, same registration, a repository it can
# read. Without this, "unanswerable" there is equally explained by a capability check that
# never matches anything.
test_start "that same adapter answers in a repository it can read, so the decline is the cause"
assert_equals "answerable" "$(gap_r4_answerability "$REPO" "$CHANGESET")"

# **The branch no criterion names.** An adapter that errors has not answered, and treating
# it as though it had is exactly how "not answerable" becomes "none found".
test_start "a capable adapter that errors has not answered, and R4 stays unanswerable"
linkset_reset && linkset_register capable
CAPABLE_RC=1
assert_equals "unanswerable" "$(gap_r4_answerability "$REPO" "$CHANGESET")"

test_start "the same adapter answering cleanly does make R4 answerable"
CAPABLE_RC=0
assert_equals "answerable" "$(gap_r4_answerability "$REPO" "$CHANGESET")"

test_start "a capable adapter declining leaves R4 unanswerable"
CAPABLE_RC=2
assert_equals "unanswerable" "$(gap_r4_answerability "$REPO" "$CHANGESET")"

# --- Criterion (must NOT): the two states render differently -----------------------------------

# The must-NOT discharged where a human would meet it. Both are empty lists; they must not
# read alike.
NONE_FOUND=$(printf 'ANSWERABILITY\tanswerable\nCLAIMS\t0\t7\n' | gap_unbacked_render)
NOT_ANSWERABLE=$(printf 'ANSWERABILITY\tunanswerable\nCLAIMS\t0\t0\n' | gap_unbacked_render)

test_start "an empty list from an adapter that could answer reads as none found"
assert_equals "no unbacked claims - all 7 verified claim(s) are named by a test" "$NONE_FOUND"

test_start "an empty list from adapters that could not answer reads as not answerable"
assert_equals "not answerable - no active adapter carries verification claims" "$NOT_ANSWERABLE"

# The must-NOT itself, and the counts are held **identical** on purpose. Comparing
# `CLAIMS 0 7` against `CLAIMS 0 0` would differ in the denominator alone, so the assertion
# would pass over a renderer that had collapsed the two states entirely — an inequality
# that holds trivially is no more use than an equality that does. With the same counts on
# both sides, answerability is the only thing left that can make them read differently.
test_start "the two states differ on answerability alone, not on their counts"
SAME_COUNTS_ANSWERABLE=$(printf 'ANSWERABILITY\tanswerable\nCLAIMS\t0\t7\n' | gap_unbacked_render)
SAME_COUNTS_NOT=$(printf 'ANSWERABILITY\tunanswerable\nCLAIMS\t0\t7\n' | gap_unbacked_render)
if [ -z "$SAME_COUNTS_ANSWERABLE" ] || [ -z "$SAME_COUNTS_NOT" ]; then
  test_fail "Positive control failed: a rendering was empty, so 'they differ' proves nothing"
elif [ "$SAME_COUNTS_ANSWERABLE" = "$SAME_COUNTS_NOT" ]; then
  test_fail "The two states rendered identically: $SAME_COUNTS_ANSWERABLE"
else
  test_pass
fi

test_start "a non-empty finding reads as neither of the two empty states"
assert_equals "1 of 4 verified claim(s) are named by no test" \
  "$(printf '%s\n' "$REPORT" | gap_unbacked_render)"

# --- Degradation ---------------------------------------------------------------------------

# R9 reaching R4: no adapters, so no claims and nothing that could have found any. Both
# halves must say so, and the unbacked list being empty must not read as good news.
test_start "with no adapters there are no claims and the report says it cannot answer"
linkset_reset
BARE=$(linkset_join "$REPO" "$CHANGESET")
assert_equals "ANSWERABILITY${TAB}unanswerable CLAIMS${TAB}0${TAB}0" \
  "$(printf '%s\n' "$BARE" | gap_unbacked_report "$REPO" "$CHANGESET" | tr '\n' ' ' | sed 's/ $//')"

# Every test file in the repository could be deleted and the claims would remain claims.
test_start "a repository with no test files reports every claim as unbacked"
NOTESTS=$(git_fixture_create no-tests)
git_fixture_commit "$NOTESTS" "chore: seed" -- README.md "seed"
NOTESTS_BASE=$(git_fixture_git "$NOTESTS" rev-parse HEAD)
git_fixture_commit "$NOTESTS" "feat: epic only" -- \
  "docs/epics/42-01-epic-alpha.md" "# Alpha

**Source spec**: docs/specifications/42-spec-change-set-review.md
**Status**: Complete

## Resolve the thing
**Story**: 1
**Status**: Complete
**Satisfies**: R1
" \
  "src/a.sh" "a"
changeset_resolve_git "$NOTESTS" --since "$NOTESTS_BASE" > "$TEST_TMPDIR/cs-notests"
linkset_reset && linkset_register cpm
NOTESTS_JOINED=$(linkset_join "$NOTESTS" "$TEST_TMPDIR/cs-notests")
if [ -n "$(_gap_test_files "$NOTESTS")" ]; then
  test_fail "Positive control failed: the fixture has test files, so this is not the case under test"
else
  assert_equals "$(printf '%s\n' "$NOTESTS_JOINED" | gap_claims)" \
    "$(printf '%s\n' "$NOTESTS_JOINED" | gap_unbacked "$NOTESTS")"
fi

test_start "a missing repository errors rather than reporting no unbacked claims"
printf '' | gap_unbacked "$TEST_TMPDIR/no-such-repo" >/dev/null 2>&1
assert_equals "1" "$?"

test_summary
