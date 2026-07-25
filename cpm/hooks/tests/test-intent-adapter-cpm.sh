#!/bin/bash
# test-intent-adapter-cpm.sh — Tests forward resolution of CPM intent selectors.
#
# These back Epic 42-05 Story 4's `[integration]` acceptance criteria (spec 42 R1's
# intent-anchored half and R2's forward direction).
#
# --- Why this suite exists at all -----------------------------------------------------
#
# Epic 42-01 Story 3 built the `<name>_intent_commits` contract and verified it against
# `stub-intent-adapter.sh`, a table lookup that knows nothing about git or CPM. That was
# right for a contract, and it left R1's intent half with no production channel: until this
# adapter, `/cpm:inspect epic 41-03` — the spec's own worked example — could not resolve.
# So this suite deliberately exercises the *real* adapter against a *real* repository, and
# the stub is not sourced here.
#
# --- What this suite does NOT test ----------------------------------------------------
#
# **Whether the commits it finds are the right ones in a judgement sense.** The adapter
# reads three channels — the epic document, its coverage matrix, and commit messages naming
# the id — and a commit that did the work while mentioning nothing is invisible to all
# three. That is a real limit of what a repository records, not a defect this suite can
# detect, and it is why `/cpm:inspect`'s orphan query exists in the other direction.
#
# **Spec-level selectors.** `epic 42` means a flat legacy epic here, never "every epic in
# spec 42's chain". The adapter answers `exit 2` for anything outside the two shapes the
# criteria name, and the assertions below pin that rather than assuming it.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/git-fixture-helpers.sh"
source "$SCRIPT_DIR/../lib/changeset.sh"
source "$SCRIPT_DIR/../lib/changeset-resolve.sh"
source "$SCRIPT_DIR/../lib/changeset-intent.sh"
source "$SCRIPT_DIR/../lib/intent-adapter-cpm.sh"

echo "Testing forward resolution of CPM intent selectors..."
echo ""

# --- Fixture ---------------------------------------------------------------------------
#
# Each of the adapter's three channels gets a commit that *only* that channel can find, so
# no assertion below can pass on the strength of a different channel having matched:
#
#   c3  the epic document, with a subject naming nothing
#   c4  a conventional-commit scope, touching no planning document
#   c5  a story id in the subject, touching no planning document
#   c6  the coverage matrix, with a subject naming nothing
#
# The unrelated commit sits *before* them all, so the epic's commits are contiguous at the
# tip and a git-anchored range covers exactly the same set — which is what makes the
# round-trip criterion a comparison of two directions rather than of two fixtures.

REPO=$(git_fixture_create intent-cpm)
git_fixture_commit "$REPO" "chore: seed" -- README.md "seed"

# A neighbouring id that shares 42-05 as a prefix. It sits before BASE so it is outside the
# git-anchored range too, which keeps the round-trip comparison honest while giving the
# adapter's trailing guard something real to exclude.
git_fixture_commit "$REPO" "feat(epic 42-051): a neighbouring epic" -- src/decoy.sh "decoy"
C_DECOY=$(git_fixture_git "$REPO" rev-parse HEAD)

git_fixture_commit "$REPO" "chore: unrelated tidy-up" -- src/other.sh "other"
BASE=$(git_fixture_git "$REPO" rev-parse HEAD)

git_fixture_commit "$REPO" "docs: plan the work" -- \
  docs/epics/42-05-epic-worked.md '# Worked

**Status**: Complete
'
C_DOC=$(git_fixture_git "$REPO" rev-parse HEAD)

git_fixture_commit "$REPO" "feat(epic 42-05): the implementation" -- src/impl.sh "impl"
C_SCOPE=$(git_fixture_git "$REPO" rev-parse HEAD)

git_fixture_commit "$REPO" "test: cover story 42-05.2" -- tests/t.sh "t"
C_STORY=$(git_fixture_git "$REPO" rev-parse HEAD)

git_fixture_commit "$REPO" "docs: the matrix" -- \
  docs/epics/42-05-coverage-worked.md '# Coverage Matrix: Worked
'
C_COVER=$(git_fixture_git "$REPO" rev-parse HEAD)

sorted() { LC_ALL=C sort; }

# --- Criterion: `epic NN-MM` resolves to the commits that produced it ---------------------

test_start "an epic selector is answered, not declined"
cpm_intent_commits "$REPO" "epic 42-05" >/dev/null 2>&1
assert_equals "0" "$?"

test_start "it finds every commit that names the epic, through all three channels"
assert_equals "$(printf '%s\n%s\n%s\n%s\n' "$C_DOC" "$C_SCOPE" "$C_STORY" "$C_COVER" | sorted)" \
  "$(cpm_intent_commits "$REPO" "epic 42-05" | sorted)"

# Each channel asserted alone, because the set comparison above passes if two channels
# happen to cover for a third that never worked.
test_start "the epic document alone is enough — a commit whose subject names nothing"
assert_contains "$(cpm_intent_commits "$REPO" "epic 42-05")" "$C_DOC"

test_start "the coverage matrix alone is enough"
assert_contains "$(cpm_intent_commits "$REPO" "epic 42-05")" "$C_COVER"

test_start "a conventional-commit scope alone is enough — no planning document touched"
assert_contains "$(cpm_intent_commits "$REPO" "epic 42-05")" "$C_SCOPE"

test_start "a story id in the subject counts towards its epic"
assert_contains "$(cpm_intent_commits "$REPO" "epic 42-05")" "$C_STORY"

# The control for all of the above: an adapter returning every commit in the repository
# would satisfy every `assert_contains` written so far.
test_start "and the unrelated commit is not swept in"
assert_empty "$(cpm_intent_commits "$REPO" "epic 42-05" | grep -F "$BASE")"

test_start "every value returned is a full commit SHA, as the contract requires"
assert_empty "$(cpm_intent_commits "$REPO" "epic 42-05" | grep -vE '^[0-9a-f]{40}$')"

# Prefix bleed is the failure hardest to notice, because the answer still looks like an
# answer — a neighbouring epic's commits arriving under this epic's id.
test_start "a neighbouring id sharing this one's prefix is not swept in"
assert_empty "$(cpm_intent_commits "$REPO" "epic 42-05" | grep -F "$C_DECOY")"

test_start "the control: that commit is found by its own id, so it is reachable"
assert_equals "$C_DECOY" "$(cpm_intent_commits "$REPO" "epic 42-051")"

# --- Criterion: `story NN-MM.K` resolves to the commits that produced it --------------------

test_start "a story selector resolves to the commit naming that story, and only it"
assert_equals "$C_STORY" "$(cpm_intent_commits "$REPO" "story 42-05.2")"

# The distinction that makes a story selector worth having. Falling back to the epic's
# commits when nothing names the story would return the whole epic while looking like it
# resolved the story — the shape `changeset-intent.sh` calls a plausible-looking lie.
test_start "a story nothing names resolves to nothing rather than to its epic"
assert_empty "$(cpm_intent_commits "$REPO" "story 42-05.9")"

test_start "and it is still an answer, not a refusal — the repository was asked"
cpm_intent_commits "$REPO" "story 42-05.9" >/dev/null 2>&1
assert_equals "0" "$?"

test_start "the alternate spelling a coverage matrix uses is recognised"
git_fixture_commit "$REPO" "fix: epic 42-05 Story 3 regression" -- src/fix.sh "fix"
C_ALT=$(git_fixture_git "$REPO" rev-parse HEAD)
assert_equals "$C_ALT" "$(cpm_intent_commits "$REPO" "story 42-05.3")"

# --- Criterion (must NOT): an empty match errors with the selector echoed back ---------------
#
# The adapter answers "nothing"; turning that into R1's error is `changeset_resolve_intent`'s
# job, and asserting it here is what proves the pair composes rather than each half being
# individually reasonable.

changeset_intent_reset
changeset_intent_register cpm

test_start "resolution through the registered adapter errors when nothing matches"
changeset_resolve_intent "$REPO" "story 42-05.9" >/dev/null 2>&1
assert_equals "1" "$?"

test_start "and echoes the selector back"
assert_contains "$(changeset_resolve_intent "$REPO" "story 42-05.9" 2>&1 >/dev/null)" "story 42-05.9"

test_start "an epic that does not exist errors rather than resolving to everything"
assert_contains "$(changeset_resolve_intent "$REPO" "epic 99-99" 2>&1 >/dev/null)" "epic 99-99"

# The positive control: the same function, the same registration, a selector that does
# match. Without it, "errors when nothing matches" is equally explained by an adapter that
# never matches anything.
test_start "the control: a selector that does match resolves rather than erroring"
changeset_resolve_intent "$REPO" "epic 42-05" >/dev/null 2>&1
assert_equals "0" "$?"

# --- Criterion: forward and reverse agree over the same commits ------------------------------

test_start "the intent direction yields the same file set as a range over the same commits"
INTENT_FILES=$(changeset_resolve_intent "$REPO" "epic 42-05" | changeset_files)
GIT_FILES=$(changeset_resolve_git "$REPO" --since "$BASE" | changeset_files)
assert_equals "$GIT_FILES" "$INTENT_FILES"

# The control: two empty file sets are equal, and so are two that happen to hold one file.
test_start "and the set compared is a real one, spanning both planning docs and code"
assert_equals "docs/epics/42-05-coverage-worked.md
docs/epics/42-05-epic-worked.md
src/fix.sh
src/impl.sh
tests/t.sh" "$INTENT_FILES"

test_start "the same commits reach both directions, not merely the same files"
assert_equals "$(changeset_resolve_git "$REPO" --since "$BASE" | changeset_commits | sorted)" \
  "$(changeset_resolve_intent "$REPO" "epic 42-05" | changeset_commits | sorted)"

# --- Criterion (must NOT): a git-anchored run must not need the intent record ------------------
#
# The risk this criterion guards is introduced *by* registering an intent adapter: a
# git-anchored selector must keep working in a repository the adapter can say nothing about,
# and must not consult it at all.

BARE=$(git_fixture_create intent-cpm-bare)
git_fixture_commit "$BARE" "chore: seed" -- README.md "seed"
BARE_BASE=$(git_fixture_git "$BARE" rev-parse HEAD)
git_fixture_commit "$BARE" "some work" -- src/a.py "a"

test_start "the repository has no CPM planning documents — the control"
assert_empty "$(ls -d "$BARE/docs" 2>/dev/null)"

test_start "a git-anchored selector resolves there with the adapter registered"
assert_equals "src/a.py" "$(changeset_resolve_git "$BARE" --since "$BARE_BASE" | changeset_files)"

test_start "and the adapter, asked directly, answers nothing rather than failing"
cpm_intent_commits "$BARE" "epic 42-05" >/dev/null 2>&1
assert_equals "0" "$?"

# --- The contract's third outcome ---------------------------------------------------------------
#
# `exit 2` is "not a kind of thing I know about", which is not the same as "none found" —
# the distinction the contract carries specifically so R4's answerability can exist.

test_start "an issue key is declined with exit 2, not answered with nothing"
cpm_intent_commits "$REPO" "AUTH-4" >/dev/null 2>&1
assert_equals "2" "$?"

test_start "a git ref is declined too — it is not this adapter's vocabulary"
cpm_intent_commits "$REPO" "main" >/dev/null 2>&1
assert_equals "2" "$?"

test_start "a malformed epic id is declined rather than half-parsed"
cpm_intent_commits "$REPO" "epic forty-two" >/dev/null 2>&1
assert_equals "2" "$?"

# Declining and finding nothing must be distinguishable, which is the whole reason exit 2
# exists. Asserted as a comparison, since each alone is explained by a constant.
test_start "declining and finding nothing are different exit codes"
cpm_intent_commits "$REPO" "AUTH-4" >/dev/null 2>&1; DECLINED=$?
cpm_intent_commits "$REPO" "epic 99-99" >/dev/null 2>&1; FOUND_NOTHING=$?
if [ "$DECLINED" = "$FOUND_NOTHING" ]; then
  test_fail "Both returned $DECLINED, so 'not answerable' and 'none found' are indistinguishable"
else
  test_pass
fi

test_start "a flat legacy epic id is answered, not declined"
cpm_intent_commits "$REPO" "epic 15" >/dev/null 2>&1
assert_equals "0" "$?"

test_start "a missing repository errors rather than answering nothing"
cpm_intent_commits "$TEST_TMPDIR/no-such-repo" "epic 42-05" >/dev/null 2>&1
assert_equals "1" "$?"

test_summary
