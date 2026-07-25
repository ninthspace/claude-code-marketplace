#!/bin/bash
# test-changeset-intent.sh — Tests intent-anchored (forward) resolution.
#
# These back Epic 42-01 Story 3's [tdd] [integration] acceptance criteria
# (spec 42 R1 intent-anchored half, R2 forward direction, AD5).
#
# This suite *is* the contract. Epic 42-02 writes the real git-native and CPM adapters
# against the interface asserted here, so what these assertions say an adapter may
# assume is what an adapter may assume. Written before the interface exists, per the
# story's [tdd] tag.
#
# **Why forward and reverse are compared byte-for-byte.** AD5 says the two directions
# "converge on one change-set structure before the join runs". Criterion 1 says forward
# resolution produces "the same change-set structure" and criterion 2 says the two
# "yield the same file set" — the same claim at two granularities. A single equality
# against the git-anchored output settles both, and settles them strictly: two
# structurally valid but differently ordered results would pass a weaker assertion while
# breaking every downstream consumer that assumes one shape.
#
# **What the stub is for.** The stub adapter knows nothing about git, trailers, or CPM
# documents — it looks selectors up in a table this suite writes. That is deliberate. A
# stub that understood commit trailers would be an early draft of 42-02's git-native
# adapter, and a suite exercising it would prove things about that adapter rather than
# about the interface. The interface is what this story freezes.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/git-fixture-helpers.sh"
source "$SCRIPT_DIR/../lib/changeset.sh"
source "$SCRIPT_DIR/../lib/changeset-resolve.sh"
source "$SCRIPT_DIR/../lib/changeset-intent.sh"
source "$SCRIPT_DIR/stub-intent-adapter.sh"

echo "Testing intent-anchored resolution..."
echo ""

# Passes only when the selector fails in all three required ways at once, and with the
# expected diagnostic. Same shape as test-changeset-resolve.sh's helper, extended to
# distinguish *which* refusal was given — R4 will need "none found" and "not answerable"
# to render differently, and that starts here.
assert_intent_error() {
  local expected_echo="$1"
  local expected_reason="$2"
  shift 2

  local out err rc
  out=$(changeset_resolve_intent "$@" 2>"$TEST_TMPDIR/stderr")
  rc=$?
  err=$(cat "$TEST_TMPDIR/stderr")

  if [ "$rc" -eq 0 ]; then
    test_fail "Expected a non-zero exit for selector: $*"
  elif [ -n "$out" ]; then
    test_fail "Expected no records on stdout, got: $(echo "$out" | head -3)"
  elif ! echo "$err" | grep -qF -- "$expected_echo"; then
    test_fail "Expected the diagnostic to echo '$expected_echo', got: $err"
  elif ! echo "$err" | grep -qF -- "$expected_reason"; then
    test_fail "Expected the diagnostic to say '$expected_reason', got: $err"
  else
    test_pass
  fi
}

# --- Fixture ---------------------------------------------------------------------

REPO=$(git_fixture_create intent)
git_fixture_commit "$REPO" "chore: seed" README.md "seed"
BASE=$(git_fixture_git "$REPO" rev-parse HEAD)
git_fixture_branch "$REPO" "feature/AUTH-123"
git_fixture_commit "$REPO" "feat(auth): add handler" src/auth.txt "handler"
FIRST=$(git_fixture_git "$REPO" rev-parse HEAD)
git_fixture_commit "$REPO" "docs: record the plan" docs/plan.md "plan" src/token.txt "token"
SECOND=$(git_fixture_git "$REPO" rev-parse HEAD)

GIT_OUT=$(changeset_resolve_git "$REPO" --since "$BASE")

# The map lists the commits oldest-first, which is the opposite of the order the
# git-anchored direction emits. An adapter's return order must not reach the structure.
stub_intent_map "epic 41-03" "$FIRST" "$SECOND"
changeset_intent_reset
changeset_intent_register stub

INTENT_OUT=$(changeset_resolve_intent "$REPO" "epic 41-03")

# --- Convergence -------------------------------------------------------------------

test_start "forward resolution produces the same change set as the git-anchored run"
assert_equals "$GIT_OUT" "$INTENT_OUT"

test_start "forward resolution produces a well-formed change set"
assert_empty "$(printf '%s\n' "$INTENT_OUT" | changeset_validate)"

test_start "forward resolution resolves the files those commits touched"
assert_equals "docs/plan.md
src/auth.txt
src/token.txt" "$(printf '%s\n' "$INTENT_OUT" | changeset_files)"

test_start "an adapter's return order does not reach the structure"
stub_intent_map "epic 41-03" "$SECOND" "$FIRST"
assert_equals "$INTENT_OUT" "$(changeset_resolve_intent "$REPO" "epic 41-03")"

# --- The adapter contract -----------------------------------------------------------

test_start "the selector reaches the adapter verbatim"
stub_intent_reset_seen
changeset_resolve_intent "$REPO" "story 41-03.2 // not parsed by anything" >/dev/null 2>&1
assert_equals "story 41-03.2 // not parsed by anything" "$(stub_intent_seen)"

test_start "two adapters resolving overlapping commits produce a deduplicated union"
stub_intent_map "epic 41-03" "$FIRST"
stub2_intent_map "epic 41-03" "$FIRST" "$SECOND"
changeset_intent_reset
changeset_intent_register stub
changeset_intent_register stub2
assert_equals "$GIT_OUT" "$(changeset_resolve_intent "$REPO" "epic 41-03")"

test_start "every registered adapter is queried"
stub_intent_reset_seen
stub2_intent_reset_seen
changeset_resolve_intent "$REPO" "epic 41-03" >/dev/null 2>&1
assert_equals "epic 41-03
epic 41-03" "$(stub_intent_seen; stub2_intent_seen)"

# --- must NOT silently return an empty change set ------------------------------------

test_start "an adapter that answers with no commits errors rather than returning nothing"
changeset_intent_reset
changeset_intent_register stub
stub_intent_map "epic 41-03" "$FIRST"
assert_intent_error "epic 99-99" "matched no changes" "$REPO" "epic 99-99"

test_start "no registered adapters errors rather than returning nothing"
changeset_intent_reset
assert_intent_error "epic 41-03" "no adapter" "$REPO" "epic 41-03"

# R4 (Epic 42-03) requires "none found" and "not answerable" to render differently. The
# distinction is impossible to add later without reopening the contract this story
# freezes, so the interface carries it from the start and it is asserted here.
test_start "an adapter that cannot answer renders differently from one that found nothing"
changeset_intent_reset
changeset_intent_register stub
stub_intent_unanswerable "ticket AUTH-123"
assert_intent_error "ticket AUTH-123" "no adapter" "$REPO" "ticket AUTH-123"

test_start "answerability is queryable without resolving"
changeset_intent_reset
changeset_intent_register stub
stub_intent_map "epic 41-03" "$FIRST"
assert_equals "0 2" "$(changeset_intent_answerable "$REPO" "epic 41-03"; printf '%s ' $?; changeset_intent_answerable "$REPO" "ticket AUTH-123"; printf '%s' $?)"

# An erroring adapter has said nothing about whether the question was answerable.
# Counting it as an answer would let a broken adapter turn "not answerable" into "none
# found", which is the conflation R4 exists to prevent.
test_start "an erroring adapter does not count as having answered"
changeset_intent_reset
changeset_intent_register stub
stub_intent_broken "epic 41-03"
changeset_intent_answerable "$REPO" "epic 41-03"
assert_equals "2" "$?"

test_start "the registry reports its adapters in registration order, without duplicates"
changeset_intent_reset
changeset_intent_register stub
changeset_intent_register stub2
changeset_intent_register stub
assert_equals "stub
stub2" "$(changeset_intent_adapters)"

test_start "registering an adapter that does not exist is refused"
changeset_intent_reset
changeset_intent_register no_such_adapter 2>/dev/null
assert_equals "1|" "$?|$(changeset_intent_adapters)"

# A broken adapter must fail loudly against its own name. Filtering its output instead
# would produce an empty change set, and "selector matched no changes" is a
# plausible-looking lie about a bug that lives somewhere else entirely.
test_start "an adapter returning something that is not a SHA is reported against that adapter"
changeset_intent_reset
changeset_intent_register stub
stub_intent_map "epic 41-03" "not-a-sha"
assert_intent_error "stub" "not a full commit SHA" "$REPO" "epic 41-03"

test_start "an adapter naming a commit outside the repository is reported, not silently dropped"
changeset_intent_reset
changeset_intent_register stub
stub_intent_map "epic 41-03" "0000000000000000000000000000000000000001"
assert_intent_error "epic 41-03" "not in this repository" "$REPO" "epic 41-03"

test_start "a missing repository directory errors with the path echoed back"
changeset_intent_reset
changeset_intent_register stub
assert_intent_error "$TEST_TMPDIR/no-such-repo" "no such repository" "$TEST_TMPDIR/no-such-repo" "epic 41-03"

test_summary
