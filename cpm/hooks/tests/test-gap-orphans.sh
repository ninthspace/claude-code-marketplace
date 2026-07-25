#!/bin/bash
# test-gap-orphans.sh — Tests the orphan-changes query.
#
# These back Epic 42-03 Story 1's `[integration]` acceptance criteria (spec 42 R3).
#
# **The fixture is built around the case that separates two readings of the criteria.**
# Story 1's positive criterion — "A file with no adapter link appears in the orphan list;
# a file with a declared link does not" — is satisfied equally well by a correct
# implementation and by `orphan = anything not declared`. Only a file carrying a *lone
# derived link* tells them apart, and that file (`src/derived-only.txt`) is the first thing
# this fixture builds. Retro 20 named this shape: when a criterion admits more than one
# reading, the fixture must contain the case that separates them, or the suite is testing
# the implementation's assumption rather than the requirement.
#
# **Every "no orphans" assertion carries a positive control.** An empty orphan list is
# produced equally by a change set where everything is linked and by a query that errored,
# returned nothing, or was handed an empty change set. Retro 20's subshell defect was this
# shape one level up, so the emptiness is never asserted alone.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/git-fixture-helpers.sh"
source "$SCRIPT_DIR/../lib/changeset.sh"
source "$SCRIPT_DIR/../lib/changeset-resolve.sh"
source "$SCRIPT_DIR/../lib/linkset.sh"
source "$SCRIPT_DIR/../lib/linkset-join.sh"
source "$SCRIPT_DIR/../lib/gap-queries.sh"
source "$SCRIPT_DIR/stub-link-adapter.sh"

echo "Testing the orphan-changes query..."
echo ""

TAB="$LINKSET_TAB"

# --- Fixture -----------------------------------------------------------------------------
#
# Four files, one per case the criteria distinguish:
#
#   src/declared.txt      a declared link      → not an orphan
#   src/derived-only.txt  a derived link only  → not an orphan  (the separating case)
#   src/both.txt          both confidences     → not an orphan
#   src/orphan.txt        no link at all       → an orphan

REPO=$(git_fixture_create orphans)
git_fixture_commit "$REPO" "chore: seed" -- README.md "seed"
BASE=$(git_fixture_git "$REPO" rev-parse HEAD)
git_fixture_commit "$REPO" "feat: four files" -- \
  src/declared.txt "d" src/derived-only.txt "w" src/both.txt "b" src/orphan.txt "o"

CHANGESET="$TEST_TMPDIR/changeset"
changeset_resolve_git "$REPO" --since "$BASE" > "$CHANGESET"
CHANGED_FILES=$(changeset_files < "$CHANGESET")

stub_link_records \
  "INTENT${TAB}epic 42-03${TAB}open${TAB}Gap Queries" \
  "LINK${TAB}src/declared.txt${TAB}epic 42-03${TAB}declared" \
  "LINK${TAB}src/derived-only.txt${TAB}epic 42-03${TAB}derived" \
  "LINK${TAB}src/both.txt${TAB}epic 42-03${TAB}derived"
stub2_link_records \
  "LINK${TAB}src/both.txt${TAB}epic 42-03${TAB}declared"

linkset_reset
linkset_register stub
linkset_register stub2
JOINED=$(linkset_join "$REPO" "$CHANGESET")

ORPHANS=$(printf '%s\n' "$JOINED" | gap_orphans "$CHANGESET")

# --- The fixture is doing what it claims --------------------------------------------------

# Asserted before anything rests on it: if the join did not actually produce a file whose
# only link is derived, the separating case is not in the fixture and the criterion-reading
# assertions below would all hold over an implementation that gets it wrong.
test_start "the fixture really does contain a file whose only link is derived"
assert_equals "derived" "$(printf '%s\n' "$JOINED" | linkset_links \
  | awk -F'\t' '$1 == "src/derived-only.txt" { print $3 }')"

test_start "the fixture really does contain a file with no link at all"
assert_empty "$(printf '%s\n' "$JOINED" | linkset_links | grep -F 'src/orphan.txt')"

# --- Criterion: a file with no link appears, a file with a declared link does not ---------

test_start "the orphan list is exactly the file nothing resolved"
assert_equals "src/orphan.txt" "$ORPHANS"

test_start "a file with a declared link is not an orphan"
assert_empty "$(printf '%s\n' "$ORPHANS" | grep -F 'src/declared.txt')"

# --- Criterion: must NOT list a file as an orphan when any adapter resolves it ------------

# The separating case. An implementation reading "orphan = not declared" passes every
# assertion above and fails this one, which is the only reason the fixture carries this
# file at all.
test_start "a file whose only link is derived is not an orphan"
assert_empty "$(printf '%s\n' "$ORPHANS" | grep -F 'src/derived-only.txt')"

test_start "a file resolved by two adapters at different confidences is not an orphan"
assert_empty "$(printf '%s\n' "$ORPHANS" | grep -F 'src/both.txt')"

# The must-NOT stated over the whole result rather than file by file: no orphan may carry
# a link. Enumerating the result is what caught Epic 42-02 Story 3's mislabelled coverage
# matrix, where a per-file grep would have passed.
test_start "no file in the orphan list carries a link of any confidence"
assert_empty "$(printf '%s\n' "$ORPHANS" | while IFS= read -r p; do
  [ -n "$p" ] && printf '%s\n' "$JOINED" | linkset_links | awk -F'\t' -v p="$p" '$1 == p'
done)"

# --- Agreement with the labels, as a regression net ----------------------------------------

# AD3 keeps the query off the labels, so these are two independent derivations from the
# same LINK records and they must not drift. Asserted here rather than relied on: if this
# ever fails, one of the two is wrong, and the point of computing them separately is that
# the failure is visible instead of shared.
test_start "the orphan list equals the set of files the join labels absent"
assert_equals "$ORPHANS" "$(printf '%s\n' "$JOINED" | linkset_labels "$CHANGESET" \
  | awk -F'\t' '$3 == "absent" { print $2 }')"

# --- Counts --------------------------------------------------------------------------------

test_start "the counts report orphans against the change-set total, not alone"
assert_equals "1${TAB}4" "$(printf '%s\n' "$JOINED" | gap_orphan_counts "$CHANGESET")"

# --- No orphans, with a control ------------------------------------------------------------

test_start "a change set where every file is resolved yields no orphans"
stub_link_records \
  "INTENT${TAB}epic 42-03${TAB}open${TAB}Gap Queries" \
  "$(printf '%s\n' "$CHANGED_FILES" | while IFS= read -r p; do
       [ -n "$p" ] && printf 'LINK\t%s\tepic 42-03\tderived\n' "$p"
     done)"
stub2_link_records ""
linkset_reset && linkset_register stub
ALL_LINKED=$(linkset_join "$REPO" "$CHANGESET")
if [ -z "$CHANGED_FILES" ]; then
  test_fail "Positive control failed: the change set is empty, so an empty orphan list proves nothing"
elif [ "$(printf '%s\n' "$ALL_LINKED" | linkset_links | wc -l | tr -d ' ')" -ne "$(printf '%s\n' "$CHANGED_FILES" | wc -l | tr -d ' ')" ]; then
  test_fail "Positive control failed: not every file was linked, so an empty orphan list is not the case under test"
else
  assert_empty "$(printf '%s\n' "$ALL_LINKED" | gap_orphans "$CHANGESET")"
fi

# --- R9: every file is an orphan when nothing can resolve anything --------------------------

# Story 3 owns R9's degradation criteria; this is the orphan query's half of it, asserted
# here because the query is what has to produce the result and this is where it is built.
test_start "with no adapters registered every file in the change set is an orphan"
linkset_reset
BARE=$(linkset_join "$REPO" "$CHANGESET")
assert_equals "$CHANGED_FILES" "$(printf '%s\n' "$BARE" | gap_orphans "$CHANGESET")"

test_start "the counts say so too, rather than reporting zero of zero"
assert_equals "4${TAB}4" "$(printf '%s\n' "$BARE" | gap_orphan_counts "$CHANGESET")"

# --- Narrower change sets and bad input ------------------------------------------------------

# A caller may hand the query a narrower change set than the links were resolved against —
# reviewing one directory of an epic's work, say. A link naming a file outside that set
# must neither appear in the result nor suppress anything in it.
test_start "a link naming a file outside the change set neither appears nor suppresses"
NARROW="$TEST_TMPDIR/changeset-narrow"
grep -vF 'src/declared.txt' "$CHANGESET" > "$NARROW"
assert_equals "src/orphan.txt" "$(printf '%s\n' "$JOINED" | gap_orphans "$NARROW")"

test_start "a missing change set file errors rather than reporting no orphans"
printf '' | gap_orphans "$TEST_TMPDIR/no-such-changeset" >/dev/null 2>&1
assert_equals "1" "$?"

test_summary
