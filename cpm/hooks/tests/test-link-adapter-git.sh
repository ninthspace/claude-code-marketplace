#!/bin/bash
# test-link-adapter-git.sh — Tests the git-native link adapter.
#
# These back Epic 42-02 Story 2's `[integration]` acceptance criteria (spec 42 R7,
# R2 reverse direction, AD2).
#
# The adapter is exercised **through the join**, not by calling it directly, because the
# criteria are about a changed file resolving to an intent record and the join is what
# produces that result. Calling the adapter alone would test the parser and leave the
# path the tool actually takes uncovered.
#
# **The confidence assertions carry more weight than the resolution ones.** That a
# trailer produces a link is the easy half; that a trailer produces a *declared* link and
# a conventional-commit scope produces a *derived* one is the Confidence Integrity
# requirement, and the way it breaks is not a crash but a judgement call made once and
# never looked at again.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/git-fixture-helpers.sh"
source "$SCRIPT_DIR/../lib/changeset.sh"
source "$SCRIPT_DIR/../lib/changeset-resolve.sh"
source "$SCRIPT_DIR/../lib/linkset.sh"
source "$SCRIPT_DIR/../lib/linkset-join.sh"
source "$SCRIPT_DIR/../lib/link-adapter-git.sh"
source "$SCRIPT_DIR/linkset-conformance.sh"

echo "Testing the git-native link adapter..."
echo ""

TAB="$LINKSET_TAB"

# The (intent, confidence) pairs resolved for one path, sorted — the unit every criterion
# in this story is stated in.
links_for() {
  printf '%s\n' "$1" | linkset_links \
    | awk -F'\t' -v p="$2" '$1 == p { print $2 "\t" $3 }' \
    | LC_ALL=C sort
}

# "This signal resolves to nothing" is the claim three tests below make, and an empty
# result satisfies it equally when the signal was correctly ignored and when the join
# errored before reaching it. So the absence is asserted only alongside the two facts
# that make it mean something: the join succeeded, and it was given files to link.
assert_no_links() {
  local repo="$1"
  local changeset_file="$2"

  local out rc
  out=$(linkset_join "$repo" "$changeset_file" 2>"$TEST_TMPDIR/stderr")
  rc=$?

  if [ "$rc" -ne 0 ]; then
    test_fail "Expected the join to succeed, got $rc: $(cat "$TEST_TMPDIR/stderr")"
  elif [ -z "$(changeset_files < "$changeset_file")" ]; then
    test_fail "Positive control failed: the change set has no files, so 'no links' proves nothing"
  elif [ -n "$(printf '%s\n' "$out" | linkset_links)" ]; then
    test_fail "Expected no links, got: $(printf '%s\n' "$out" | linkset_links | head -3)"
  else
    test_pass
  fi
}

# --- Fixture -----------------------------------------------------------------------------
#
# One repository carrying all three signals at once, because that is the state a real
# repository is in: a branch name over commits that variously do and do not carry
# trailers. Testing each signal in its own pristine repository would never exercise the
# case where two of them resolve the same file, which is most files.

REPO=$(git_fixture_create gitnative)
git_fixture_commit "$REPO" "chore: seed" -- README.md "seed"
BASE=$(git_fixture_git "$REPO" rev-parse HEAD)

git_fixture_branch "$REPO" "feature/AUTH-123"
git_fixture_commit "$REPO" "feat: add the handler" --trailer "Refs: epic 41-03" -- src/auth.txt "handler"
git_fixture_commit "$REPO" "fix(billing): correct rounding" -- src/billing.txt "round"
git_fixture_commit "$REPO" "chore: wrap up" --trailer "Closes: AUTH-9, epic 41-04" -- src/close.txt "done"

CHANGESET="$TEST_TMPDIR/changeset"
changeset_resolve_git "$REPO" --since "$BASE" > "$CHANGESET"
CHANGED_FILES=$(changeset_files < "$CHANGESET")

linkset_reset
linkset_register gitnative
OUT=$(linkset_join "$REPO" "$CHANGESET")

# --- Criterion: commit trailers resolve a changed file to an intent record -------------

test_start "a Refs: trailer resolves its commit's file to an intent record, declared"
assert_equals "epic 41-03${TAB}declared" "$(links_for "$OUT" src/auth.txt | grep -F 'epic 41-03')"

test_start "a Closes: trailer resolves its commit's file to an intent record, declared"
assert_equals "AUTH-9${TAB}declared" "$(links_for "$OUT" src/close.txt | grep -F 'AUTH-9')"

# `Refs: epic 41-03, AUTH-124` names two records. Splitting on whitespace instead of
# commas would turn `epic 41-03` into `epic` and `41-03`, neither of which is anything.
test_start "one trailer naming several records resolves to each of them"
assert_equals "AUTH-9${TAB}declared
epic 41-04${TAB}declared" "$(links_for "$OUT" src/close.txt | grep -vF 'AUTH-123')"

test_start "the change set resolves to exactly the intent records its three signals name"
assert_equals "AUTH-123
AUTH-9
billing
epic 41-03
epic 41-04" "$(printf '%s\n' "$OUT" | linkset_intent_ids | LC_ALL=C sort -u)"

# --- Criterion: conventional-commit subjects resolve a changed file --------------------

test_start "a conventional-commit scope resolves its commit's file to an intent record"
assert_equals "billing${TAB}derived" "$(links_for "$OUT" src/billing.txt | grep -F 'billing')"

# The distinction the Confidence Integrity requirement turns on: a trailer exists to name
# an intent record, a scope names an area of the code and the link is an inference.
test_start "a scope is derived while a trailer on the same change set is declared"
assert_equals "derived|declared" "$(links_for "$OUT" src/billing.txt | grep -F 'billing' | cut -f2)|$(links_for "$OUT" src/auth.txt | grep -F 'epic 41-03' | cut -f2)"

test_start "a conventional-commit subject with no scope resolves to nothing"
SCOPELESS=$(git_fixture_create scopeless)
git_fixture_commit "$SCOPELESS" "chore: seed" -- README.md "seed"
SCOPELESS_BASE=$(git_fixture_git "$SCOPELESS" rev-parse HEAD)
git_fixture_commit "$SCOPELESS" "feat: add a thing with no scope" -- src/thing.txt "thing"
changeset_resolve_git "$SCOPELESS" --since "$SCOPELESS_BASE" > "$TEST_TMPDIR/cs-scopeless"
assert_no_links "$SCOPELESS" "$TEST_TMPDIR/cs-scopeless"

# --- Criterion: branch names resolve a changed file --------------------------------------

test_start "the branch name resolves every file in the change set to an intent record"
assert_equals "$CHANGED_FILES" "$(printf '%s\n' "$OUT" | linkset_links \
  | awk -F'\t' '$2 == "AUTH-123" && $3 == "derived" { print $1 }' | LC_ALL=C sort)"

# Linking a change set to an intent record called `main` would provenance every file in
# the repository and empty R3's orphan list of its meaning.
test_start "an integration branch resolves to nothing"
PLAIN=$(git_fixture_create onmain)
git_fixture_commit "$PLAIN" "chore: seed" -- README.md "seed"
PLAIN_BASE=$(git_fixture_git "$PLAIN" rev-parse HEAD)
git_fixture_commit "$PLAIN" "just a subject" -- src/plain.txt "plain"
changeset_resolve_git "$PLAIN" --since "$PLAIN_BASE" > "$TEST_TMPDIR/cs-plain"
assert_no_links "$PLAIN" "$TEST_TMPDIR/cs-plain"

test_start "a namespaced integration branch also resolves to nothing"
git_fixture_branch "$PLAIN" "release/main"
assert_no_links "$PLAIN" "$TEST_TMPDIR/cs-plain"

# A bisect or an interactive rebase leaves HEAD detached. That is a legitimate state, not
# an error, and the branch signal is simply unavailable there.
test_start "a detached HEAD resolves to nothing rather than failing"
git_fixture_git "$REPO" checkout -q --detach HEAD
DETACHED=$(linkset_join "$REPO" "$CHANGESET" 2>/dev/null)
DETACHED_RC=$?
git_fixture_checkout "$REPO" "feature/AUTH-123"
if [ "$DETACHED_RC" -ne 0 ]; then
  test_fail "Expected the join to succeed with a detached HEAD, got $DETACHED_RC"
elif printf '%s\n' "$DETACHED" | linkset_links | grep -qF 'AUTH-123'; then
  test_fail "Expected no branch-derived links with a detached HEAD"
elif [ -z "$(printf '%s\n' "$DETACHED" | linkset_links)" ]; then
  test_fail "Positive control failed: no links at all, so the missing branch link proves nothing"
else
  test_pass
fi

# --- Criterion: the adapter works in any repository with no configuration ---------------

# Nothing happens between creating this repository and getting links out of it: no config
# file, no marker, no adoption step. That is the whole argument for AD2's git-native
# baseline, and it is only demonstrated by a repository this suite has never touched.
test_start "an unconfigured repository yields links with no setup step"
FRESH=$(git_fixture_create unconfigured)
git_fixture_commit "$FRESH" "chore: seed" -- README.md "seed"
FRESH_BASE=$(git_fixture_git "$FRESH" rev-parse HEAD)
git_fixture_branch "$FRESH" "bugfix/TICKET-7"
git_fixture_commit "$FRESH" "fix(core): repair it" --trailer "Refs: TICKET-7" -- src/core.txt "core"
changeset_resolve_git "$FRESH" --since "$FRESH_BASE" > "$TEST_TMPDIR/cs-fresh"
# `Refs: TICKET-7` and the branch `bugfix/TICKET-7` name the same (file, intent) pair at
# different confidences, so Story 4's precedence collapses them to the declared one. That
# is R7 working on a fixture built before precedence existed, not a lost signal — the
# branch-derived link for a *different* intent would still be here.
assert_equals "TICKET-7${TAB}declared
core${TAB}derived" "$(links_for "$(linkset_join "$FRESH" "$TEST_TMPDIR/cs-fresh")" src/core.txt)"

# A directory with no git history is not a channel this adapter can read. Exit 2 says so;
# exit 1 would stop the join over a repository that simply has nothing to offer it.
test_start "a directory that is not a git repository is declined, not failed"
mkdir -p "$TEST_TMPDIR/not-a-repo"
gitnative_link_changeset "$TEST_TMPDIR/not-a-repo" "$CHANGESET" >/dev/null 2>&1
assert_equals "2" "$?"

# --- The contract ---------------------------------------------------------------------

# Story 1's second criterion: any adapter must pass the conformance suite. This is the
# first real adapter to run through it.
linkset_conformance_run gitnative "$REPO" "$CHANGESET"

# The contract forbids an adapter adding to the change set. A commit routinely touches
# files a narrower selector left out, so this is the ordinary case, not an edge one.
test_start "a file dropped from the change set is not linked, though its commit remains"
NARROW="$TEST_TMPDIR/changeset-narrow"
grep -vF 'src/billing.txt' "$CHANGESET" > "$NARROW"
NARROW_OUT=$(linkset_join "$REPO" "$NARROW")
if [ "$(changeset_commits < "$NARROW" | wc -l | tr -d ' ')" != "$(changeset_commits < "$CHANGESET" | wc -l | tr -d ' ')" ]; then
  test_fail "Positive control failed: narrowing dropped a commit, so the absent link proves nothing"
elif printf '%s\n' "$NARROW_OUT" | linkset_links | grep -qF 'src/billing.txt'; then
  test_fail "Expected no link for a file outside the change set"
elif ! printf '%s\n' "$NARROW_OUT" | linkset_links | grep -qF 'src/auth.txt'; then
  test_fail "Positive control failed: no links survived narrowing at all"
else
  test_pass
fi

test_start "every intent record this adapter emits is honest about what git does not know"
assert_equals "unknown" "$(printf '%s\n' "$OUT" | linkset_intents | cut -f2 | LC_ALL=C sort -u)"

# git carries no verification claims — commit trailers record why a change happened, never
# whether it was checked. Emitting a CRITERION here would make R4's unbacked-claims query
# answerable from a channel that cannot answer it.
test_start "this adapter emits no verification claims"
assert_empty "$(printf '%s\n' "$OUT" | linkset_criteria)"

test_summary
