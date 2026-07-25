#!/bin/bash
# test-linkset.sh — Tests the link-set structure, the adapter contract, and the join.
#
# These back Epic 42-02 Story 1's `[integration]` acceptance criteria (spec 42 R7, AD2).
#
# Story 1 freezes the seam AD2 depends on: two adapters implement it in this epic, two
# later epics consume its output, and the deferred issue-tracker adapters must be addable
# against it without reopening it. So what these assertions say an adapter may do is what
# an adapter may do.
#
# **Why this suite goes past the three criteria.** Retro 20 (Testing Gaps): a suite
# written from acceptance criteria is complete with respect to those criteria and silent
# about every other branch. Last epic that silence hid a defect in an unnamed third exit
# code. The criteria here name the contract, the harness and the zero-adapter path; the
# join's error paths, the registry's refusals and the validator's enum checks are named by
# none of them, and are covered below.
#
# **Why the conformance harness is tested by breaking things.** A harness only ever run
# against conforming adapters demonstrates that it executes, not that it discriminates.
# Every check in `linkset-conformance.sh` therefore has a positive control here: the stub
# is made to commit that violation and the harness is asserted to catch *that specific
# one*. Without the pairing, eight green checks and eight no-op checks look identical.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/git-fixture-helpers.sh"
source "$SCRIPT_DIR/../lib/changeset.sh"
source "$SCRIPT_DIR/../lib/changeset-resolve.sh"
source "$SCRIPT_DIR/../lib/linkset.sh"
source "$SCRIPT_DIR/../lib/linkset-join.sh"
source "$SCRIPT_DIR/linkset-conformance.sh"
source "$SCRIPT_DIR/stub-link-adapter.sh"

echo "Testing the link-set structure, adapter contract and join..."
echo ""

TAB="$LINKSET_TAB"

# Passes only when the join refuses in all three required ways at once: non-zero exit,
# nothing on stdout, and a diagnostic naming the thing that went wrong. Checking the exit
# code alone would pass a join that also printed a half-built link set.
assert_join_error() {
  local expected_a="$1"
  local expected_b="$2"
  shift 2

  local out err rc
  out=$(linkset_join "$@" 2>"$TEST_TMPDIR/stderr")
  rc=$?
  err=$(cat "$TEST_TMPDIR/stderr")

  if [ "$rc" -eq 0 ]; then
    test_fail "Expected a non-zero exit, got 0"
  elif [ -n "$out" ]; then
    test_fail "Expected no records on stdout, got: $(echo "$out" | head -3)"
  elif ! echo "$err" | grep -qF -- "$expected_a"; then
    test_fail "Expected the diagnostic to mention '$expected_a', got: $err"
  elif ! echo "$err" | grep -qF -- "$expected_b"; then
    test_fail "Expected the diagnostic to mention '$expected_b', got: $err"
  else
    test_pass
  fi
}

# Passes only when the harness rejects the given break mode *for the stated reason*. A
# harness that failed every adapter would satisfy a bare "returns non-zero", so the
# marker is what distinguishes a working check from a broken one.
assert_conformance_rejects() {
  local mode="$1"
  local marker="$2"

  stub_link_reset
  stub_link_break "$mode"

  local report rc
  report=$(linkset_conformance_check stub "$REPO" "$CHANGESET" 2>/dev/null)
  rc=$?
  stub_link_reset

  if [ "$rc" -eq 0 ]; then
    test_fail "Expected the harness to reject break mode '$mode', it passed"
  elif ! echo "$report" | grep -qF -- "$marker"; then
    test_fail "Expected the harness to report '$marker' for '$mode', got: $report"
  else
    test_pass
  fi
}

# Passes only when the validator rejects the record *and* names the reason.
assert_validate_rejects() {
  local record="$1"
  local marker="$2"

  local report rc
  report=$(printf '%s\n' "$record" | linkset_validate)
  rc=$?

  if [ "$rc" -eq 0 ]; then
    test_fail "Expected the validator to reject: $record"
  elif ! echo "$report" | grep -qF -- "$marker"; then
    test_fail "Expected the validator to report '$marker', got: $report"
  else
    test_pass
  fi
}

# --- Fixture ---------------------------------------------------------------------------

REPO=$(git_fixture_create linkset)
git_fixture_commit "$REPO" "chore: seed" README.md "seed"
BASE=$(git_fixture_git "$REPO" rev-parse HEAD)
git_fixture_commit "$REPO" "feat(auth): add handler" src/auth.txt "handler"
git_fixture_commit "$REPO" "docs: record the plan" docs/plan.md "plan"

CHANGESET="$TEST_TMPDIR/changeset"
changeset_resolve_git "$REPO" --since "$BASE" > "$CHANGESET"

# Read back rather than pinned: the fixture owns which files changed, and a literal list
# here would be asserting against a copy of the fixture rather than against the fixture
# (retro 19).
CHANGED_FILES=$(changeset_files < "$CHANGESET")

# --- The contract: an adapter returns a link set ------------------------------------

test_start "an adapter's link set covers exactly the files in the change set"
linkset_reset
linkset_register stub
JOINED=$(linkset_join "$REPO" "$CHANGESET")
assert_equals "$CHANGED_FILES" "$(printf '%s\n' "$JOINED" | linkset_linked_files | LC_ALL=C sort -u)"

test_start "the joined link set is well-formed"
assert_empty "$(printf '%s\n' "$JOINED" | linkset_validate)"

test_start "the link set carries the intent record its links reference"
assert_equals "STUB-1" "$(printf '%s\n' "$JOINED" | linkset_intent_ids)"

test_start "records from several adapters merge into one link set"
linkset_reset
linkset_register stub
linkset_register stub2
BOTH=$(linkset_join "$REPO" "$CHANGESET")
assert_equals "STUB-1
STUB-2" "$(printf '%s\n' "$BOTH" | linkset_intent_ids)"

test_start "adapter registration order does not reach the output"
linkset_reset
linkset_register stub2
linkset_register stub
assert_equals "$BOTH" "$(linkset_join "$REPO" "$CHANGESET")"

test_start "every registered adapter is queried"
linkset_reset
linkset_register stub
linkset_register stub2
stub_link_reset_seen
stub2_link_reset_seen
linkset_join "$REPO" "$CHANGESET" >/dev/null 2>&1
assert_equals "$CHANGED_FILES
$CHANGED_FILES" "$(stub_link_seen; stub2_link_seen)"

# --- must NOT require any adapter to be present -------------------------------------

# Three facts in one assertion, because the interesting one is only interesting given the
# other two: "emitted nothing" proves the zero-adapter path only if the change set had
# files to link in the first place (retro 18 — an absence assertion needs a positive
# control).
test_start "zero registered adapters succeeds and emits nothing, over a non-empty change set"
linkset_reset
ZERO_OUT=$(linkset_join "$REPO" "$CHANGESET" 2>"$TEST_TMPDIR/stderr")
ZERO_RC=$?
if [ -z "$CHANGED_FILES" ]; then
  test_fail "Positive control failed: the change set has no files, so an empty link set proves nothing"
elif [ "$ZERO_RC" -ne 0 ]; then
  test_fail "Expected exit 0 with no adapters, got $ZERO_RC: $(cat "$TEST_TMPDIR/stderr")"
elif [ -n "$ZERO_OUT" ]; then
  test_fail "Expected no records with no adapters, got: $(echo "$ZERO_OUT" | head -3)"
else
  test_pass
fi

test_start "every adapter declining to answer is also a valid configuration"
linkset_reset
linkset_register stub
stub_link_reset
stub_link_exit 2
DECLINED=$(linkset_join "$REPO" "$CHANGESET" 2>/dev/null)
assert_equals "0|" "$?|$DECLINED"
stub_link_reset

test_start "an adapter that declines does not suppress one that answers"
linkset_reset
linkset_register stub
linkset_register stub2
stub_link_exit 2
assert_equals "STUB-2" "$(linkset_join "$REPO" "$CHANGESET" | linkset_intent_ids)"
stub_link_reset

# --- The conformance harness ----------------------------------------------------------

linkset_reset
linkset_conformance_run stub "$REPO" "$CHANGESET"
linkset_conformance_run stub2 "$REPO" "$CHANGESET"

# Positive controls: each check in the harness must be shown to fail on demand, or a
# check that silently does nothing is indistinguishable from one that works.
test_start "the harness rejects an adapter that does not exist"
REPORT=$(linkset_conformance_check no_such_adapter "$REPO" "$CHANGESET" 2>/dev/null)
assert_equals "1|NOT DEFINED: no_such_adapter_link_changeset" "$?|$REPORT"

test_start "the harness rejects an exit code outside the contract"
assert_conformance_rejects exit-code "INVALID EXIT CODE: 3"

test_start "the harness rejects output alongside a cannot-answer exit"
assert_conformance_rejects exit2-output "EXIT 2 WITH OUTPUT"

test_start "the harness rejects a malformed record"
assert_conformance_rejects invalid-record "INVALID RECORD"

test_start "the harness rejects an adapter claiming a file is absent"
assert_conformance_rejects absent "ADAPTER CLAIMED absent"

test_start "the harness rejects a link to a file outside the change set"
assert_conformance_rejects foreign-path "FOREIGN PATH: not/in/the/change/set.txt"

test_start "the harness rejects a link to an intent record that is not present"
assert_conformance_rejects dangling "DANGLING INTENT ID: NO-SUCH-INTENT"

test_start "the harness rejects an adapter that answers differently on two identical runs"
assert_conformance_rejects nondeterministic "NON-DETERMINISTIC"

test_start "the harness rejects an adapter that errors on an empty change set"
assert_conformance_rejects error-on-empty "ERRORED ON EMPTY CHANGE SET"

# The harness only earns its place if passing it means the join will accept the adapter.
# Asserting the two verdicts *together* is what makes that an invariant rather than a
# coincidence: this exact case — a stray blank line — passed the harness and failed the
# join until the harness stopped filtering blanks the join does not filter.
test_start "the harness and the join agree on a record the join would reject"
linkset_reset
linkset_register stub
stub_link_reset
stub_link_break blank-line
CONFORMANCE_REPORT=$(linkset_conformance_check stub "$REPO" "$CHANGESET" 2>/dev/null)
CONFORMANCE_RC=$?
linkset_join "$REPO" "$CHANGESET" >/dev/null 2>&1
JOIN_RC=$?
stub_link_reset
if [ "$CONFORMANCE_RC" -eq 0 ]; then
  test_fail "The harness accepted an adapter emitting a blank line; the join rejects it"
elif [ "$JOIN_RC" -eq 0 ]; then
  test_fail "Positive control failed: the join accepted the blank line, so agreement proves nothing"
elif ! echo "$CONFORMANCE_REPORT" | grep -qF -- "MALFORMED"; then
  test_fail "Expected the harness to report MALFORMED, got: $CONFORMANCE_REPORT"
else
  test_pass
fi

# --- The join's own failure paths -----------------------------------------------------

# None of these are named by the story's criteria. Each turns a broken adapter into a
# loud failure attributed to that adapter, rather than into a shorter link set — which
# would surface as a longer orphan list and read as a finding about the code.
test_start "an erroring adapter fails the join, named"
linkset_reset
linkset_register stub
stub_link_exit 1
assert_join_error "stub" "failed" "$REPO" "$CHANGESET"
stub_link_reset

test_start "an adapter emitting an invalid record fails the join, named"
linkset_reset
linkset_register stub
stub_link_break invalid-record
assert_join_error "stub" "invalid record" "$REPO" "$CHANGESET"
stub_link_reset

test_start "an adapter linking a file outside the change set fails the join, named"
linkset_reset
linkset_register stub
stub_link_break foreign-path
assert_join_error "stub" "not in the change set" "$REPO" "$CHANGESET"
stub_link_reset

test_start "a missing repository directory errors with the path echoed back"
linkset_reset
assert_join_error "no such repository" "$TEST_TMPDIR/no-such-repo" "$TEST_TMPDIR/no-such-repo" "$CHANGESET"

test_start "a missing change set file errors with the path echoed back"
linkset_reset
assert_join_error "no such change set" "$TEST_TMPDIR/no-such-changeset" "$REPO" "$TEST_TMPDIR/no-such-changeset"

# --- The registry -----------------------------------------------------------------------

test_start "the registry reports its adapters in registration order, without duplicates"
linkset_reset
linkset_register stub
linkset_register stub2
linkset_register stub
assert_equals "stub
stub2" "$(linkset_adapters)"

test_start "registering an adapter that does not exist is refused and changes nothing"
linkset_reset
linkset_register no_such_adapter 2>/dev/null
assert_equals "1|" "$?|$(linkset_adapters)"

# --- The structure ------------------------------------------------------------------------

test_start "a well-formed link set validates"
assert_empty "$(printf 'INTENT%s42-01.3%sdone%sDefine intent resolution\nCRITERION%s42-01.3%sverified%sResolves forward\nLINK%ssrc/auth.txt%s42-01.3%sdeclared\n' \
  "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" | linkset_validate)"

test_start "the validator rejects an unknown record type"
assert_validate_rejects "MYSTERY${TAB}a${TAB}b${TAB}c" "UNKNOWN RECORD TYPE: MYSTERY"

test_start "the validator rejects a record with the wrong field count"
assert_validate_rejects "LINK${TAB}src/auth.txt${TAB}42-01.3" "MALFORMED"

test_start "the validator rejects an empty identifier"
assert_validate_rejects "LINK${TAB}${TAB}42-01.3${TAB}declared" "EMPTY IDENTIFIER"

test_start "the validator rejects an unknown intent status"
assert_validate_rejects "INTENT${TAB}42-01.3${TAB}finished${TAB}Title" "UNKNOWN INTENT STATUS: finished"

test_start "the validator rejects an unknown criterion state"
assert_validate_rejects "CRITERION${TAB}42-01.3${TAB}maybe${TAB}Text" "UNKNOWN CRITERION STATE: maybe"

test_start "the validator rejects an unknown confidence"
assert_validate_rejects "LINK${TAB}src/auth.txt${TAB}42-01.3${TAB}probably" "UNKNOWN CONFIDENCE: probably"

# `absent` is one of R7's three labels, so an adapter author reaching for it is making a
# plausible mistake rather than a typo. It gets its own diagnostic saying why not.
test_start "the validator rejects absent with a diagnostic distinct from an unknown value"
assert_validate_rejects "LINK${TAB}src/auth.txt${TAB}42-01.3${TAB}absent" "only the join may label a file absent"

test_start "normalisation orders record types and deduplicates"
assert_equals "INTENT${TAB}A${TAB}open${TAB}First
CRITERION${TAB}A${TAB}verified${TAB}Claim
LINK${TAB}src/auth.txt${TAB}A${TAB}derived" "$(printf 'LINK%ssrc/auth.txt%sA%sderived\nCRITERION%sA%sverified%sClaim\nLINK%ssrc/auth.txt%sA%sderived\nINTENT%sA%sopen%sFirst\n' \
  "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" | linkset_normalise)"

test_start "the counts report each record type"
assert_equals "1${TAB}1${TAB}2" "$(printf 'INTENT%sA%sopen%sFirst\nCRITERION%sA%sverified%sClaim\nLINK%sa.txt%sA%sderived\nLINK%sb.txt%sA%sderived\n' \
  "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" "$TAB" | linkset_counts)"

test_summary
