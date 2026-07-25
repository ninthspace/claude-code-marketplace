#!/bin/bash
# test-linkset-precedence.sh — Tests confidence labelling and precedence.
#
# These back Epic 42-02 Story 4's `[unit]` acceptance criteria (spec 42 R7).
#
# **What is and is not assertable here.** There is no oracle for whether a derived link is
# *true* — "epic 41-03 owns this file" cannot be checked by a test, as the spec says of
# R7's precedence row. What can be checked is that labels are applied consistently and
# that a declared marker always beats a derived one. Every assertion below is about
# precedence or about the label vocabulary; none claims a link is correct.
#
# The stubs are used rather than the real adapters because precedence must hold for *any*
# combination of channels, including combinations this iteration does not ship. Story 6
# runs the same property through the git-native and CPM adapters, where the pair arises
# from real signals instead of a table.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/git-fixture-helpers.sh"
source "$SCRIPT_DIR/../lib/changeset.sh"
source "$SCRIPT_DIR/../lib/changeset-resolve.sh"
source "$SCRIPT_DIR/../lib/linkset.sh"
source "$SCRIPT_DIR/../lib/linkset-join.sh"
source "$SCRIPT_DIR/stub-link-adapter.sh"

echo "Testing confidence labelling and precedence..."
echo ""

TAB="$LINKSET_TAB"

# --- Fixture -----------------------------------------------------------------------------

REPO=$(git_fixture_create precedence)
git_fixture_commit "$REPO" "chore: seed" -- README.md "seed"
BASE=$(git_fixture_git "$REPO" rev-parse HEAD)
git_fixture_commit "$REPO" "feat: two files" -- src/a.txt "a" src/b.txt "b"

CHANGESET="$TEST_TMPDIR/changeset"
changeset_resolve_git "$REPO" --since "$BASE" > "$CHANGESET"
CHANGED_FILES=$(changeset_files < "$CHANGESET")

# One record set per adapter, naming the SAME (file, intent) pair at different
# confidences. This is the contested case, and it is the only one precedence has an
# opinion about.
CONTESTED_INTENT="INTENT${TAB}SHARED-1${TAB}open${TAB}Shared record"
CONTESTED_DERIVED="LINK${TAB}src/a.txt${TAB}SHARED-1${TAB}derived"
CONTESTED_DECLARED="LINK${TAB}src/a.txt${TAB}SHARED-1${TAB}declared"

# --- A declared marker always wins over a derived one ------------------------------------

test_start "a declared link beats a derived one for the same (file, intent) pair"
linkset_reset
stub_link_reset
stub2_link_reset
stub_link_records "$CONTESTED_INTENT" "$CONTESTED_DERIVED"
stub2_link_records "$CONTESTED_INTENT" "$CONTESTED_DECLARED"
linkset_register stub
linkset_register stub2
assert_equals "src/a.txt${TAB}SHARED-1${TAB}declared" "$(linkset_join "$REPO" "$CHANGESET" | linkset_links)"

# If precedence depended on which adapter answered first, it would be a property of the
# caller's registration order rather than of the data — and Story 6's cross-adapter
# criterion would hold only by luck.
test_start "the declared link wins regardless of which adapter is registered first"
linkset_reset
linkset_register stub2
linkset_register stub
assert_equals "src/a.txt${TAB}SHARED-1${TAB}declared" "$(linkset_join "$REPO" "$CHANGESET" | linkset_links)"

test_start "the contested pair collapses to exactly one link, not two"
assert_equals "1" "$(linkset_join "$REPO" "$CHANGESET" | linkset_links | wc -l | tr -d ' ')"

# Precedence is scoped to the pair. Two intents naming the same file are different claims
# about that file, not a contest, and collapsing them would silently discard provenance.
test_start "two different intents naming one file both survive"
linkset_reset
stub_link_reset
stub2_link_reset
stub_link_records "$CONTESTED_INTENT" "$CONTESTED_DERIVED"
stub2_link_records "INTENT${TAB}OTHER-2${TAB}open${TAB}Other record" "LINK${TAB}src/a.txt${TAB}OTHER-2${TAB}declared"
linkset_register stub
linkset_register stub2
assert_equals "src/a.txt${TAB}OTHER-2${TAB}declared
src/a.txt${TAB}SHARED-1${TAB}derived" "$(linkset_join "$REPO" "$CHANGESET" | linkset_links)"

# --- must NOT label a derived link as declared under any adapter combination --------------

# The must-NOT is about what precedence may *create*, not only about what it prefers. A
# collapse that promoted the surviving record's confidence would satisfy every positive
# criterion above and violate Confidence Integrity outright.
test_start "a derived link with no declared rival stays derived"
linkset_reset
stub_link_reset
stub2_link_reset
stub_link_records "$CONTESTED_INTENT" "$CONTESTED_DERIVED"
linkset_register stub
assert_equals "src/a.txt${TAB}SHARED-1${TAB}derived" "$(linkset_join "$REPO" "$CHANGESET" | linkset_links)"

test_start "two adapters both answering derived produce a derived link, not a declared one"
linkset_reset
stub_link_reset
stub2_link_reset
stub_link_records "$CONTESTED_INTENT" "$CONTESTED_DERIVED"
stub2_link_records "$CONTESTED_INTENT" "$CONTESTED_DERIVED"
linkset_register stub
linkset_register stub2
assert_equals "src/a.txt${TAB}SHARED-1${TAB}derived" "$(linkset_join "$REPO" "$CHANGESET" | linkset_links)"

test_start "no confidence value other than declared or derived reaches the output"
linkset_reset
stub_link_reset
stub2_link_reset
linkset_register stub
linkset_register stub2
assert_equals "declared
derived" "$(linkset_join "$REPO" "$CHANGESET" | linkset_links | cut -f3 | LC_ALL=C sort -u)"

# --- Every file carries exactly one of declared / derived / absent -------------------------

test_start "every file in the change set gets exactly one label"
linkset_reset
stub_link_reset
stub2_link_reset
stub_link_records "$CONTESTED_INTENT" "$CONTESTED_DERIVED"
linkset_register stub
LABELS=$(linkset_join "$REPO" "$CHANGESET" | linkset_labels "$CHANGESET")
assert_equals "$CHANGED_FILES" "$(printf '%s\n' "$LABELS" | cut -f2 | LC_ALL=C sort)"

test_start "a file no adapter resolved is labelled absent"
assert_equals "src/a.txt${TAB}derived
src/b.txt${TAB}absent" "$(printf '%s\n' "$LABELS" | cut -f2,3 | LC_ALL=C sort)"

test_start "a file inherits the strongest confidence among its links"
linkset_reset
stub_link_reset
stub2_link_reset
stub_link_records "$CONTESTED_INTENT" "$CONTESTED_DERIVED" \
  "INTENT${TAB}OTHER-2${TAB}open${TAB}Other record" "LINK${TAB}src/a.txt${TAB}OTHER-2${TAB}declared"
linkset_register stub
assert_equals "declared" "$(linkset_join "$REPO" "$CHANGESET" | linkset_labels "$CHANGESET" | awk -F'\t' '$2=="src/a.txt"{print $3}')"

# R9: "In a repository with no recognised intent source, the review still runs and every
# file is reported as an orphan." With no adapters at all the join emits nothing, so the
# labels come entirely from the change set — which is what makes that requirement work.
test_start "with no adapters registered every file is labelled absent"
linkset_reset
NO_ADAPTER_LABELS=$(linkset_join "$REPO" "$CHANGESET" | linkset_labels "$CHANGESET")
if [ -z "$CHANGED_FILES" ]; then
  test_fail "Positive control failed: the change set has no files, so a full absent list proves nothing"
else
  assert_equals "$(printf '%s\n' "$CHANGED_FILES" | sed "s/\$/${TAB}absent/")" "$(printf '%s\n' "$NO_ADAPTER_LABELS" | cut -f2,3)"
fi

test_start "labels are emitted in change-set order, not adapter order"
linkset_reset
stub_link_reset
linkset_register stub
assert_equals "$CHANGED_FILES" "$(linkset_join "$REPO" "$CHANGESET" | linkset_labels "$CHANGESET" | cut -f2)"

test_start "a missing change set file errors rather than labelling nothing"
printf '' | linkset_labels "$TEST_TMPDIR/no-such-changeset" >/dev/null 2>&1
assert_equals "1" "$?"

# --- Intent-record reconciliation ----------------------------------------------------------

# Not named by any criterion, and unavoidable: the git-native adapter emits `unknown`
# status with the ID as the title because git knows neither, while the CPM adapter reads
# both from the document. Two records for one ID would reach the JSON and the page.
test_start "an intent record that states a status outranks one that says unknown"
linkset_reset
stub_link_reset
stub2_link_reset
stub_link_records "INTENT${TAB}SHARED-1${TAB}unknown${TAB}SHARED-1" "$CONTESTED_DERIVED"
stub2_link_records "INTENT${TAB}SHARED-1${TAB}done${TAB}A real title" "$CONTESTED_DECLARED"
linkset_register stub
linkset_register stub2
assert_equals "SHARED-1${TAB}done${TAB}A real title" "$(linkset_join "$REPO" "$CHANGESET" | linkset_intents)"

test_start "intent reconciliation does not depend on registration order"
linkset_reset
linkset_register stub2
linkset_register stub
assert_equals "SHARED-1${TAB}done${TAB}A real title" "$(linkset_join "$REPO" "$CHANGESET" | linkset_intents)"

test_summary
