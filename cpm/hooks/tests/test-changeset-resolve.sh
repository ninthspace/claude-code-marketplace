#!/bin/bash
# test-changeset-resolve.sh — Tests git-anchored selector resolution.
#
# These back Epic 42-01 Story 2's [integration] acceptance criteria (spec 42 R1, AD5).
#
# The positive criterion says four selector forms "each resolve to a change-set
# structure comprising a set of commits and a set of files". Three of the four describe
# the same commits by different routes, so they are asserted to produce *byte-identical*
# output rather than merely valid output — R1's whole point is that the forms converge,
# and two structurally-valid-but-different results would satisfy a weaker assertion
# while breaking the property Story 3's round-trip depends on.
#
# Expected values come from the fixture recipe, never from the resolver. The file set is
# compared against the paths this suite told the fixture to write; the commit count
# against the number of commits it asked for. Deriving the expectation by re-running the
# resolver's own logic would assert only that the code agrees with itself. No SHA
# appears as a literal — every one is read back from the fixture at run time (retro 19).
#
# The must-NOT — "must NOT silently return an empty change set when a selector matches
# nothing — it errors with the selector echoed back" — has three parts: a non-zero exit,
# the selector present in the diagnostic, and *nothing on stdout*. All three are checked
# together in one `test_start` by assert_selector_error, because a failure in any one of
# them is the same defect and splitting them would inflate the pass count over the test
# count (retro 15). The positive tests above it are its control: the same repository
# demonstrably does produce a populated change set for a selector that matches.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/git-fixture-helpers.sh"
source "$SCRIPT_DIR/../lib/changeset.sh"
source "$SCRIPT_DIR/../lib/changeset-resolve.sh"

echo "Testing git-anchored selector resolution..."
echo ""

# Passes only when the selector fails in all three required ways at once.
assert_selector_error() {
  local expected_echo="$1"
  shift

  local out err rc
  out=$(changeset_resolve_git "$@" 2>"$TEST_TMPDIR/stderr")
  rc=$?
  err=$(cat "$TEST_TMPDIR/stderr")

  if [ "$rc" -eq 0 ]; then
    test_fail "Expected a non-zero exit for selector: $*"
  elif [ -n "$out" ]; then
    test_fail "Expected no records on stdout, got: $(echo "$out" | head -3)"
  elif ! echo "$err" | grep -qF -- "$expected_echo"; then
    test_fail "Expected the diagnostic to echo '$expected_echo', got: $err"
  else
    test_pass
  fi
}

# --- Fixture ---------------------------------------------------------------------

REPO=$(git_fixture_create resolve)
git_fixture_commit "$REPO" "chore: seed" README.md "seed"
BASE=$(git_fixture_git "$REPO" rev-parse HEAD)
git_fixture_branch "$REPO" "feature/AUTH-123"
git_fixture_commit "$REPO" "feat(auth): add handler" src/auth.txt "handler"
git_fixture_commit "$REPO" "docs: record the plan" docs/plan.md "plan" src/token.txt "token"
TIP=$(git_fixture_git "$REPO" rev-parse HEAD)

SINCE_OUT=$(changeset_resolve_git "$REPO" --since "$BASE")

# --- The structure each form resolves to -------------------------------------------

test_start "--since resolves the commits made after the ref, and their files"
assert_equals "2${CHANGESET_TAB}3" "$(printf '%s\n' "$SINCE_OUT" | changeset_counts)"

test_start "--since resolves the files those commits touched"
assert_equals "docs/plan.md
src/auth.txt
src/token.txt" "$(printf '%s\n' "$SINCE_OUT" | changeset_files)"

test_start "--since produces a well-formed change set"
assert_empty "$(printf '%s\n' "$SINCE_OUT" | changeset_validate)"

test_start "a commit range resolves identically to --since over the same commits"
assert_equals "$SINCE_OUT" "$(changeset_resolve_git "$REPO" "$BASE..$TIP")"

test_start "a branch name resolves identically to --since over the same commits"
assert_equals "$SINCE_OUT" "$(changeset_resolve_git "$REPO" "feature/AUTH-123")"

# A branch is measured from where it split, not from the default branch. The two are the
# same for a branch cut off main, so the distinction only becomes visible on a stacked
# branch — where measuring against main would report the parent branch's commits as this
# branch's own, which is a wrong answer that looks entirely plausible.
git_fixture_branch "$REPO" "feature/AUTH-456"
git_fixture_commit "$REPO" "feat(auth): refresh tokens" src/refresh.txt "refresh"
STACKED_OUT=$(changeset_resolve_git "$REPO" "feature/AUTH-456")

test_start "a branch stacked on another branch is measured from where it split"
assert_equals "src/refresh.txt" "$(printf '%s\n' "$STACKED_OUT" | changeset_files)"

test_start "a stacked branch does not claim its parent branch's commits"
assert_equals "1${CHANGESET_TAB}1" "$(printf '%s\n' "$STACKED_OUT" | changeset_counts)"

test_start "the parent branch still measures from its own split point"
assert_equals "$SINCE_OUT" "$(changeset_resolve_git "$REPO" "feature/AUTH-123")"

git_fixture_checkout "$REPO" "feature/AUTH-123"

test_start "every COMMIT record names a commit that exists in the repository"
MISSING=""
while IFS= read -r sha; do
  git_fixture_git "$REPO" cat-file -e "${sha}^{commit}" 2>/dev/null || MISSING="$MISSING $sha"
done <<EOF
$(printf '%s\n' "$SINCE_OUT" | changeset_commits)
EOF
assert_empty "$MISSING"

test_start "the same selector twice produces byte-identical output"
assert_equals "$SINCE_OUT" "$(changeset_resolve_git "$REPO" --since "$BASE")"

# The working tree is the one form with no commits — a set of files and an empty set of
# commits is still the structure, not a degenerate case.
echo "scratch" > "$REPO/untracked.txt"
printf 'seed\nedited\n' > "$REPO/README.md"
WT_OUT=$(changeset_resolve_git "$REPO" --working-tree)

test_start "--working-tree resolves the uncommitted files"
assert_equals "README.md
untracked.txt" "$(printf '%s\n' "$WT_OUT" | changeset_files)"

test_start "--working-tree resolves no commits"
assert_equals "0${CHANGESET_TAB}2" "$(printf '%s\n' "$WT_OUT" | changeset_counts)"

test_start "--working-tree produces a well-formed change set"
assert_empty "$(printf '%s\n' "$WT_OUT" | changeset_validate)"

git_fixture_git "$REPO" checkout -q -- README.md
rm -f "$REPO/untracked.txt"

# --- The file set is a pure function of the commit set ------------------------------
#
# Documented behaviour, asserted because Story 3's round-trip criterion depends on it:
# files are the union of what the commits touched, not the range's net diff. A file
# edited and then restored inside the range nets to nothing and must still be reported.

REVERTED=$(git_fixture_create reverted)
git_fixture_commit "$REVERTED" "chore: seed" README.md "seed"
REV_BASE=$(git_fixture_git "$REVERTED" rev-parse HEAD)
git_fixture_commit "$REVERTED" "feat: edit" README.md "edited"
git_fixture_commit "$REVERTED" "revert: restore" README.md "seed"

test_start "a file edited and restored within the range stays in the change set"
assert_equals "README.md" "$(changeset_resolve_git "$REVERTED" --since "$REV_BASE" | changeset_files)"

test_start "the reverted range really does net to no change"
assert_empty "$(git_fixture_git "$REVERTED" diff --name-only "$REV_BASE" HEAD)"

# --- must NOT silently return an empty change set -----------------------------------

test_start "an empty commit range errors rather than returning nothing"
assert_selector_error "--since HEAD" "$REPO" --since HEAD

test_start "an unresolvable ref errors with the selector echoed back"
assert_selector_error "no-such-ref" "$REPO" --since no-such-ref

test_start "a missing branch errors with the selector echoed back"
assert_selector_error "no-such-branch" "$REPO" "no-such-branch"

test_start "a clean working tree errors rather than returning nothing"
assert_selector_error "--working-tree" "$REPO" --working-tree

test_start "a branch with nothing to have split from errors rather than resolving to its whole history"
assert_selector_error "main" "$REPO" main

test_start "an unknown selector flag errors with the selector echoed back"
assert_selector_error "--frobnicate" "$REPO" --frobnicate

test_start "a missing repository directory errors with the path echoed back"
assert_selector_error "$TEST_TMPDIR/no-such-repo" "$TEST_TMPDIR/no-such-repo" --working-tree

test_summary
