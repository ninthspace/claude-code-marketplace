#!/bin/bash
# test-inspect-resolve.sh — Tests selector dispatch for /cpm:inspect.
#
# These back Epic 42-05 Story 1's first and fourth acceptance criteria (spec 42 R1, AD1,
# AD5).
#
# --- What this suite does NOT test ----------------------------------------------------
#
# **Whether resolution is correct.** That is Epic 42-01's, and its two suites already
# assert it. Everything here is about *routing*: that a selector reaches the resolver the
# spec says it should. The two questions fail for unrelated reasons, and a suite that can
# only see a change set reports a routing bug as a resolution bug.
#
# **Whether the intent direction produces anything useful.** R1's intent half has no
# production adapter — the only `*_intent_commits` implementation in this repository is
# `stub-intent-adapter.sh`, and Epic 42-05 Story 4 exists to supply a real one. So the
# intent-routing assertions below run against the stub, and they prove the selector
# arrived, not that anything in this repository can answer it.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/git-fixture-helpers.sh"
source "$SCRIPT_DIR/../lib/changeset.sh"
source "$SCRIPT_DIR/../lib/inspect-resolve.sh"
source "$SCRIPT_DIR/stub-intent-adapter.sh"

echo "Testing /cpm:inspect selector dispatch..."
echo ""

# --- Fixture ---------------------------------------------------------------------------
#
# One repository carrying every R1 selector form at once: a seed commit to anchor
# `--since` and a range, a branch off it, and an uncommitted file for the working tree.

REPO=$(git_fixture_create dispatch)
git_fixture_commit "$REPO" "chore: seed" -- README.md "seed"
BASE=$(git_fixture_git "$REPO" rev-parse HEAD)
git_fixture_commit "$REPO" "feat: two files" -- src/a.sh "a" src/b.sh "b"
HEAD_SHA=$(git_fixture_git "$REPO" rev-parse HEAD)

git_fixture_branch "$REPO" feature/dispatch
git_fixture_commit "$REPO" "feat: branch file" -- src/branch.sh "branch"
git_fixture_checkout "$REPO" main

printf 'dirty\n' > "$REPO/src/uncommitted.sh"

files_of() { printf '%s\n' "$1" | changeset_files; }

# --- Criterion: every selector form from R1 is accepted and dispatched -----------------
#
# Direction and result are asserted separately for each form. A router that answered `git`
# for everything would satisfy the direction half for three of the four forms, so the
# resolution half is what stops the pair being vacuous — and vice versa: a form that
# resolves but routes through the wrong resolver would still produce a change set.

test_start "--since routes git and resolves"
assert_equals "git|src/a.sh
src/b.sh" "$(inspect_selector_direction "$REPO" --since "$BASE")|$(files_of "$(inspect_resolve "$REPO" --since "$BASE")")"

test_start "a commit range routes git and resolves"
assert_equals "git|src/a.sh
src/b.sh" "$(inspect_selector_direction "$REPO" "$BASE..$HEAD_SHA")|$(files_of "$(inspect_resolve "$REPO" "$BASE..$HEAD_SHA")")"

test_start "a branch name routes git and resolves"
assert_equals "git|src/branch.sh" \
  "$(inspect_selector_direction "$REPO" feature/dispatch)|$(files_of "$(inspect_resolve "$REPO" feature/dispatch)")"

test_start "--working-tree routes git and resolves"
assert_equals "git|src/uncommitted.sh" \
  "$(inspect_selector_direction "$REPO" --working-tree)|$(files_of "$(inspect_resolve "$REPO" --working-tree)")"

# The intent half. The stub is what makes the selector resolvable at all; what is being
# asserted is that `epic 42-05` reached an intent adapter rather than being handed to git
# as a branch name.
changeset_intent_reset
changeset_intent_register stub
stub_intent_map "epic 42-05" "$HEAD_SHA"

test_start "an intent-anchored selector routes intent and resolves"
assert_equals "intent|src/a.sh
src/b.sh" \
  "$(inspect_selector_direction "$REPO" "epic 42-05")|$(files_of "$(inspect_resolve "$REPO" "epic 42-05")")"

test_start "an intent selector given as separate words reaches the adapter whole"
stub_intent_reset_seen
inspect_resolve "$REPO" epic 42-05 >/dev/null 2>&1
assert_equals "epic 42-05" "$(stub_intent_seen | tail -1)"

# The forms converge on one structure, which is what lets everything downstream be written
# once. Asserted as a comparison between two runs rather than against a literal, so it
# still holds when the fixture changes.
test_start "the intent and git directions over the same commit yield the same file set"
assert_equals "$(files_of "$(inspect_resolve "$REPO" --since "$BASE")")" \
  "$(files_of "$(inspect_resolve "$REPO" "epic 42-05")")"

# --- The ambiguous rule, asserted in both directions -----------------------------------
#
# Rule 3 decides a bare token by whether the branch exists. One direction alone is equally
# explained by a router that always answers the same way, so both are run — same token
# shape, same repository, differing only in whether a branch of that name is there.

test_start "a bare token naming a branch routes git"
assert_equals "git" "$(inspect_selector_direction "$REPO" feature/dispatch)"

test_start "a bare token naming no branch routes intent"
assert_equals "intent" "$(inspect_selector_direction "$REPO" AUTH-4)"

# The control for the pair above: if the fixture had no such branch, "names a branch"
# would be describing a condition that never held.
test_start "the fixture really does have the branch the rule turns on"
assert_equals "1" "$(git_fixture_git "$REPO" show-ref --verify --quiet refs/heads/feature/dispatch && echo 1)"

test_start "a token that is neither a branch nor known to any adapter still routes intent"
changeset_intent_reset
assert_equals "intent" "$(inspect_selector_direction "$REPO" AUTH-4)"

# --- Criterion (must NOT): no CPM artifacts required ------------------------------------
#
# The strong form of AD1's "must not require CPM artifacts in the target repository": a
# repository with no `docs/` at all, resolved and joined with both *real* adapters. Using
# the real adapters is the point — a stub would prove only that a stub tolerates the
# absence.

source "$SCRIPT_DIR/../lib/linkset.sh"
source "$SCRIPT_DIR/../lib/linkset-join.sh"
source "$SCRIPT_DIR/../lib/link-adapter-git.sh"
source "$SCRIPT_DIR/../lib/link-adapter-cpm.sh"
source "$SCRIPT_DIR/../lib/gap-queries.sh"

BARE=$(git_fixture_create bare-no-cpm)
git_fixture_commit "$BARE" "chore: seed" -- README.md "seed"
BARE_BASE=$(git_fixture_git "$BARE" rev-parse HEAD)
git_fixture_commit "$BARE" "add some code" -- src/x.py "x" src/y.py "y"

test_start "a repository with no CPM artifacts has none — the control for what follows"
assert_empty "$(ls -d "$BARE/docs" 2>/dev/null)"

BARE_CHANGESET="$TEST_TMPDIR/bare-changeset"
inspect_resolve "$BARE" --since "$BARE_BASE" > "$BARE_CHANGESET" 2>/dev/null
BARE_FILES=$(changeset_files < "$BARE_CHANGESET")

test_start "resolution works without any CPM artifacts"
assert_equals "src/x.py
src/y.py" "$BARE_FILES"

linkset_reset
linkset_register gitnative
linkset_register cpm
BARE_JOINED=$(linkset_join "$BARE" "$BARE_CHANGESET")

test_start "the join runs with both real adapters and produces no links to invent"
assert_empty "$(printf '%s\n' "$BARE_JOINED" | awk -F'\t' '$1 == "LINK"')"

test_start "every file is an orphan rather than the run failing"
assert_equals "$BARE_FILES" "$(printf '%s\n' "$BARE_JOINED" | gap_orphans "$BARE_CHANGESET")"

# Exit status, separately from content. Epic 42-03 shipped with a defect where every
# content assertion passed while the report exited 1, so a correct run reported itself as
# having failed.
test_start "the gap report exits 0 on a repository it can say nothing about"
printf '%s\n' "$BARE_JOINED" | gap_report "$BARE" "$BARE_CHANGESET" >/dev/null 2>&1
assert_equals "0" "$?"

# --- Errors -------------------------------------------------------------------------------

test_start "an intent selector with no registered adapter errors"
changeset_intent_reset
inspect_resolve "$REPO" "epic 99-99" >/dev/null 2>&1
assert_equals "1" "$?"

test_start "and echoes the selector back, per R1's must-NOT"
changeset_intent_reset
assert_contains "$(inspect_resolve "$REPO" "epic 99-99" 2>&1 >/dev/null)" "epic 99-99"

test_start "a git selector matching nothing errors with the selector echoed back"
assert_contains "$(inspect_resolve "$REPO" "$HEAD_SHA..$HEAD_SHA" 2>&1 >/dev/null)" "$HEAD_SHA..$HEAD_SHA"

# No selector is the dispatcher's own failure rather than a resolver's: with nothing to
# route, the dispatch matches no branch and the run would otherwise succeed having done
# nothing at all.
test_start "no selector is refused rather than succeeding silently"
inspect_resolve "$REPO" >/dev/null 2>&1
assert_equals "1" "$?"

test_start "an unknown flag is refused rather than treated as a branch name"
inspect_resolve "$REPO" --nonsense >/dev/null 2>&1
assert_equals "1" "$?"

test_summary
