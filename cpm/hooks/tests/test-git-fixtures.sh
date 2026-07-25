#!/bin/bash
# test-git-fixtures.sh — Tests the synthetic git-repository fixture helper.
#
# These back Epic 42-01 Story 1's [integration] acceptance criteria (spec 42, Testing
# Strategy → Test Infrastructure).
#
# Three properties are under test, and each needed a different shape of assertion:
#
# 1. **The four commit shapes.** Spec 42 AD2's git-native adapter reads trailers,
#    conventional-commit subjects and branch names, and AD2's derivation rule reads
#    co-commits. Each shape is asserted by reading it back through *git's own*
#    accessors — `%(trailers:key=...)`, `%s`, `rev-parse --abbrev-ref` — rather than by
#    grepping the raw message. A fixture that only satisfies a regex written here would
#    prove nothing about what the adapter will be able to parse.
#
# 2. **Isolation.** Two claims, tested two ways. That a fixture is a separate repository
#    is structural — its toplevel is itself and it sits outside the host repo. That the
#    host's git configuration cannot reach it is behavioural: a hostile global config
#    with `init.templateDir` set is proven to leak a marker into a plain `git init`,
#    and proven not to leak into a fixture. The negative control is the point — without
#    it, "no marker found" is satisfied equally by working isolation and by a probe
#    that never worked.
#
# 3. **No leftovers, pass or fail.** This cannot be asserted in-process: the guarantee
#    is carried by `test-helpers.sh`'s `trap ... EXIT`, which fires when a *suite*
#    exits. So two child suites are written to disk and run — one that ends green, one
#    that ends red through `test_summary`'s `exit 1` — and each is checked to have left
#    nothing behind. Each child reports its fixture's commit count before exiting, and
#    that report is asserted separately: "the directory is gone" is satisfied just as
#    well by a helper that never created anything, so the absence assertion is paired
#    with a positive control (retro 18).
#
# No expected value in this suite is pinned. Commit SHAs, the host repository root and
# the child suites' temp directories are all read back at run time from the thing under
# test (retro 19) — a fixture harness whose assertions pinned a SHA would have to be
# edited every time a fixture recipe changed.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/git-fixture-helpers.sh"

HELPER="$SCRIPT_DIR/git-fixture-helpers.sh"

echo "Testing git fixture helper..."
echo ""

# --- Commit shapes --------------------------------------------------------------

REPO=$(git_fixture_create shapes)
git_fixture_commit "$REPO" "chore: seed" README.md "seed"
git_fixture_branch "$REPO" "feature/AUTH-123"
git_fixture_commit "$REPO" "fix(auth): handle token expiry" \
  --trailer "Refs: epic 41-03" \
  --trailer "Closes: #42" \
  docs/epics/41-03-epic-auth.md "**Satisfies**: R1" \
  src/auth.txt "code"

test_start "git_fixture_create builds a real repository"
assert_equals "true" "$(git_fixture_git "$REPO" rev-parse --is-inside-work-tree 2>/dev/null)"

test_start "the commit sequence has the specified length"
assert_equals "2" "$(git_fixture_git "$REPO" rev-list --count HEAD)"

test_start "commits are ordered as specified"
assert_equals "fix(auth): handle token expiry
chore: seed" "$(git_fixture_git "$REPO" log --format='%s')"

test_start "a conventional-commit subject survives verbatim"
assert_equals "fix(auth): handle token expiry" "$(git_fixture_git "$REPO" log -1 --format='%s')"

test_start "git's own trailer parser resolves the Refs trailer"
assert_equals "epic 41-03" "$(git_fixture_git "$REPO" log -1 --format='%(trailers:key=Refs,valueonly)' | head -1)"

test_start "git's own trailer parser resolves the Closes trailer"
assert_equals "#42" "$(git_fixture_git "$REPO" log -1 --format='%(trailers:key=Closes,valueonly)' | head -1)"

test_start "a branch name is set on HEAD"
assert_equals "feature/AUTH-123" "$(git_fixture_git "$REPO" rev-parse --abbrev-ref HEAD)"

test_start "co-committed files land in one commit"
assert_equals "docs/epics/41-03-epic-auth.md
src/auth.txt" "$(git_fixture_git "$REPO" show --name-only --format= HEAD | sort)"

test_start "git_fixture_checkout returns to an existing branch"
git_fixture_checkout "$REPO" main
assert_equals "main" "$(git_fixture_git "$REPO" rev-parse --abbrev-ref HEAD)"

# Determinism is what lets every other assertion here read its expected value back at
# run time instead of pinning one: the same recipe must produce the same SHA in a
# different repository, on a different day.
DET_A=$(git_fixture_create det)
git_fixture_commit "$DET_A" "chore: seed" README.md "seed"
DET_B=$(git_fixture_create det)
git_fixture_commit "$DET_B" "chore: seed" README.md "seed"

test_start "the same recipe produces the same commit SHA"
assert_equals "$(git_fixture_git "$DET_A" rev-parse HEAD)" "$(git_fixture_git "$DET_B" rev-parse HEAD)"

# --- Isolation ------------------------------------------------------------------

HOST_ROOT=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)

# Both sides are compared with symlinks resolved: git reports a repository's toplevel
# in its physical form, and on macOS the temp directory reached via /var is a symlink
# to /private/var. Comparing the two forms directly fails on a correct fixture.
REPO_PHYSICAL=$(cd "$REPO" && pwd -P)

test_start "a fixture sits outside the host repository"
case "$REPO_PHYSICAL" in
  "$HOST_ROOT"/*) test_fail "Fixture path is inside the host repository: $REPO_PHYSICAL" ;;
  *) test_pass ;;
esac

test_start "a fixture is its own repository, not a view of the host"
assert_equals "$REPO_PHYSICAL" "$(git_fixture_git "$REPO" rev-parse --show-toplevel)"

test_start "a fixture has no remotes configured"
assert_empty "$(git_fixture_git "$REPO" remote)"

# The helper's own prose names the network verbs it avoids, so the sweep reads code
# only — a literal in a comment is invisible to review and fully visible to a grep
# (retro 19). `git_fixture_git` passes arbitrary arguments through by design; what is
# asserted is that the helper itself never reaches for the network.
test_start "the helper contains no network operations"
assert_empty "$(grep -vE '^[[:space:]]*#' "$HELPER" | grep -nE '\b(clone|fetch|pull|push|ls-remote|submodule)\b')"

# Negative control first: prove the probe can detect a leak at all.
HOSTILE="$TEST_TMPDIR/hostile"
mkdir -p "$HOSTILE/template"
echo "leaked" > "$HOSTILE/template/HOST-CONFIG-MARKER"
printf '[init]\n\ttemplateDir = %s\n' "$HOSTILE/template" > "$HOSTILE/gitconfig"

mkdir -p "$HOSTILE/control"
GIT_CONFIG_GLOBAL="$HOSTILE/gitconfig" git init -q "$HOSTILE/control"

test_start "negative control: host git config does reach a plain git init"
if [ -f "$HOSTILE/control/.git/HOST-CONFIG-MARKER" ]; then
  test_pass
else
  test_fail "The isolation probe cannot detect a leak — it proves nothing about the fixture"
fi

export GIT_CONFIG_GLOBAL="$HOSTILE/gitconfig"
ISOLATED=$(git_fixture_create isolated)
git_fixture_commit "$ISOLATED" "chore: seed" README.md "seed"
unset GIT_CONFIG_GLOBAL

test_start "host git config does not reach a fixture repository"
if [ -f "$ISOLATED/.git/HOST-CONFIG-MARKER" ]; then
  test_fail "Host templateDir leaked into the fixture at $ISOLATED/.git"
else
  test_pass
fi

test_start "a fixture commits successfully under a hostile host config"
assert_equals "1" "$(git_fixture_git "$ISOLATED" rev-list --count HEAD)"

# --- No leftovers, pass or fail --------------------------------------------------

write_child_suite() {
  local path="$1"
  local outcome="$2"   # pass | fail
  cat > "$path" <<CHILD
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/git-fixture-helpers.sh"

repo=\$(git_fixture_create child)
git_fixture_commit "\$repo" "chore: seed" a.txt "alpha"
git_fixture_commit "\$repo" "chore: more" b.txt "beta"

echo "CHILD_TMPDIR=\$TEST_TMPDIR"
echo "CHILD_REPO=\$repo"
echo "CHILD_COMMITS=\$(git_fixture_git "\$repo" rev-list --count HEAD)"

test_start "child assertion"
if [ "$outcome" = "pass" ]; then
  assert_equals "alpha" "\$(cat "\$repo/a.txt")"
else
  assert_equals "alpha" "deliberate-failure"
fi
test_summary
CHILD
}

run_child_suite() {
  local outcome="$1"
  local script="$TEST_TMPDIR/child-$outcome.sh"
  write_child_suite "$script" "$outcome"
  bash "$script" 2>/dev/null
}

for OUTCOME in pass fail; do
  CHILD_OUT=$(run_child_suite "$OUTCOME")
  CHILD_TMPDIR=$(echo "$CHILD_OUT" | sed -n 's/^CHILD_TMPDIR=//p')
  CHILD_REPO=$(echo "$CHILD_OUT" | sed -n 's/^CHILD_REPO=//p')
  CHILD_COMMITS=$(echo "$CHILD_OUT" | sed -n 's/^CHILD_COMMITS=//p')

  # Positive control: without this, the absence assertion below is satisfied just as
  # well by a helper that never built anything.
  test_start "a $OUTCOME-ing child suite really did build a populated fixture"
  assert_equals "2" "$CHILD_COMMITS"

  test_start "a $OUTCOME-ing child suite leaves its fixture repository behind: no"
  if [ -n "$CHILD_REPO" ] && [ -e "$CHILD_REPO" ]; then
    test_fail "Fixture repository survived the child suite: $CHILD_REPO"
  else
    test_pass
  fi

  test_start "a $OUTCOME-ing child suite leaves its working directory behind: no"
  if [ -n "$CHILD_TMPDIR" ] && [ -e "$CHILD_TMPDIR" ]; then
    test_fail "Working directory survived the child suite: $CHILD_TMPDIR"
  else
    test_pass
  fi
done

# --- Teardown API ----------------------------------------------------------------

test_start "git_fixture_destroy refuses a path outside the fixture root"
assert_equals "1" "$(git_fixture_destroy "$TEST_TMPDIR/not-a-fixture" 2>/dev/null; echo $?)"

# The root check is a textual prefix match, so a traversal starts with the root and
# still points outside it. This function ends in `rm -rf`; the escape is worth locking.
test_start "git_fixture_destroy refuses a path that escapes the root via .."
assert_equals "1" "$(git_fixture_destroy "$(git_fixture_root)/../escaped" 2>/dev/null; echo $?)"

test_start "git_fixture_destroy removes a single fixture"
DOOMED=$(git_fixture_create doomed)
BEFORE=$(git_fixture_count)
git_fixture_destroy "$DOOMED"
assert_equals "$((BEFORE - 1))" "$(git_fixture_count)"

test_start "git_fixture_destroy_all removes every fixture"
git_fixture_destroy_all
assert_equals "0" "$(git_fixture_count)"

test_summary
