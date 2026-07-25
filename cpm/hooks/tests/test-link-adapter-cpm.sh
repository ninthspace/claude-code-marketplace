#!/bin/bash
# test-link-adapter-cpm.sh — Tests the CPM link adapter.
#
# These back Epic 42-02 Story 3's `[integration]` acceptance criteria (spec 42 R7,
# R2 reverse direction, AD2).
#
# **The fixture builds real CPM documents rather than reusing this repository's.** Two
# reasons. Asserting against `docs/epics/` here would pin the tests to whatever epic
# happens to be in flight, so they would fail on a day nobody touched the adapter. And
# the must-NOT below needs two commits with the *same* timestamp and no co-commit between
# them — a shape the real history does not reliably contain and cannot be made to.
#
# **The must-NOT is the load-bearing test in this file.** AD2 rejects time-window
# derivation because CPM's own execution pattern makes it look correct: `cpm:do` runs a
# whole chain in one sitting, so every commit shares a date. An implementation that
# inferred from dates would pass every positive criterion in this story and be wrong in
# exactly the case the spec calls "the normal case, not an anomaly".

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/git-fixture-helpers.sh"
source "$SCRIPT_DIR/../lib/changeset.sh"
source "$SCRIPT_DIR/../lib/changeset-resolve.sh"
source "$SCRIPT_DIR/../lib/linkset.sh"
source "$SCRIPT_DIR/../lib/linkset-join.sh"
source "$SCRIPT_DIR/../lib/link-adapter-cpm.sh"
source "$SCRIPT_DIR/linkset-conformance.sh"

echo "Testing the CPM link adapter..."
echo ""

TAB="$LINKSET_TAB"

links_for() {
  printf '%s\n' "$1" | linkset_links \
    | awk -F'\t' -v p="$2" '$1 == p { print $2 "\t" $3 }' \
    | LC_ALL=C sort
}

# --- Fixture -----------------------------------------------------------------------------

EPIC_DOC='# Change-Set Resolution

**Source spec**: docs/specifications/42-spec-change-set-review.md
**Date**: 2026-07-25
**Status**: Complete
**Blocked by**: —

## Resolve git-anchored selectors to a change set
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: R1, AD5

**Acceptance Criteria**:

- A branch name resolves to a change-set structure [integration]

## Define intent resolution [plan]
**Story**: 3
**Status**: Pending
**Blocked by**: Story 2
**Satisfies**: R2

**Acceptance Criteria**:

- An intent-anchored selector resolves forward [integration]
'

COVERAGE_DOC='# Coverage Matrix: Change-Set Resolution

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | R1 | both resolve to one change-set structure | A branch name resolves to a change-set structure | Story 2 | `[integration]` | ✓ |
| 2 | R2 | Intent-anchored selectors resolve forward | An intent-anchored selector resolves forward | Story 3 | `[integration]` | |
'

REPO=$(git_fixture_create cpmadapter)
git_fixture_commit "$REPO" "chore: seed" -- README.md "seed"
BASE=$(git_fixture_git "$REPO" rev-parse HEAD)

# The co-commit: planning document and the code it describes, in one commit. This is the
# shape AD2 calls the strongest derived signal, and it exists because `cpm:do` updates
# planning documents in the same working tree as the code.
git_fixture_commit "$REPO" "Resolve git-anchored selectors" -- \
  docs/epics/42-01-epic-change-set-resolution.md "$EPIC_DOC" \
  docs/epics/42-01-coverage-change-set-resolution.md "$COVERAGE_DOC" \
  cpm/hooks/lib/changeset-resolve.sh "resolver" \
  cpm/hooks/tests/test-changeset-resolve.sh "tests"

CHANGESET="$TEST_TMPDIR/changeset"
changeset_resolve_git "$REPO" --since "$BASE" > "$CHANGESET"

linkset_reset
linkset_register cpm
OUT=$(linkset_join "$REPO" "$CHANGESET")

# --- Criterion: epic docs, Satisfies fields and coverage matrices resolve to intent
#     records carrying their criteria --------------------------------------------------

test_start "an epic doc resolves to intent records for the epic and each of its stories"
assert_equals "epic 42-01
spec 42 AD5
spec 42 R1
spec 42 R2
story 42-01.2
story 42-01.3" "$(printf '%s\n' "$OUT" | linkset_intent_ids | LC_ALL=C sort -u)"

test_start "each intent record carries the status its document states"
assert_equals "epic 42-01${TAB}done
story 42-01.2${TAB}done
story 42-01.3${TAB}open" "$(printf '%s\n' "$OUT" | linkset_intents | awk -F'\t' '$1 !~ /^spec /{print $1 "\t" $2}' | LC_ALL=C sort)"

test_start "a story's Satisfies field resolves to a requirement record per spec"
assert_equals "spec 42 AD5
spec 42 R1
spec 42 R2" "$(printf '%s\n' "$OUT" | linkset_intent_ids | grep '^spec ' | LC_ALL=C sort -u)"

# The criteria are what R4's unbacked-claims query is asked about, and they come from the
# coverage matrix rather than the story's own Status: a story marked Complete over an
# unverified row is precisely the gap the query exists to find.
test_start "the coverage matrix resolves to criteria carrying their verification state"
assert_equals "story 42-01.2${TAB}verified${TAB}A branch name resolves to a change-set structure
story 42-01.3${TAB}unverified${TAB}An intent-anchored selector resolves forward" \
  "$(printf '%s\n' "$OUT" | linkset_criteria | LC_ALL=C sort)"

test_start "an epic doc with no coverage matrix still resolves to intent records"
NOMATRIX=$(git_fixture_create nomatrix)
git_fixture_commit "$NOMATRIX" "chore: seed" -- README.md "seed"
NOMATRIX_BASE=$(git_fixture_git "$NOMATRIX" rev-parse HEAD)
git_fixture_commit "$NOMATRIX" "Work without a matrix" -- \
  docs/epics/50-01-epic-solo.md "$EPIC_DOC" src/solo.txt "solo"
changeset_resolve_git "$NOMATRIX" --since "$NOMATRIX_BASE" > "$TEST_TMPDIR/cs-nomatrix"
NOMATRIX_OUT=$(linkset_join "$NOMATRIX" "$TEST_TMPDIR/cs-nomatrix")
assert_equals "epic 50-01|" "$(printf '%s\n' "$NOMATRIX_OUT" | linkset_intent_ids | grep '^epic ')|$(printf '%s\n' "$NOMATRIX_OUT" | linkset_criteria)"

# --- Criterion: co-commit links a changed file to an intent record ----------------------

test_start "a file co-committed with an epic doc is linked to that epic, derived"
assert_equals "epic 42-01${TAB}derived" "$(links_for "$OUT" cpm/hooks/lib/changeset-resolve.sh | grep -F 'epic 42-01')"

test_start "co-commit links every non-document file in the commit, not just the first"
assert_equals "cpm/hooks/lib/changeset-resolve.sh
cpm/hooks/tests/test-changeset-resolve.sh" "$(printf '%s\n' "$OUT" | linkset_links \
  | awk -F'\t' '$2 == "epic 42-01" && $3 == "derived" { print $1 }' | LC_ALL=C sort)"

# The document is the record — no inference is involved — so these are the declared links
# this adapter makes, and they are what Story 4's precedence will prefer over a derived
# link naming the same pair.
test_start "the epic document is linked to its own record as declared, not derived"
assert_equals "epic 42-01${TAB}declared" "$(links_for "$OUT" docs/epics/42-01-epic-change-set-resolution.md)"

# A coverage matrix names its epic in its filename and its `**Epic**:` field. Treating it
# as ordinary co-committed evidence would put a planning artifact in the same confidence
# class as the code it happened to land beside.
test_start "a coverage matrix is linked to its epic as declared, not co-commit derived"
assert_equals "epic 42-01${TAB}declared" "$(links_for "$OUT" docs/epics/42-01-coverage-change-set-resolution.md)"

test_start "co-committed files also reach the requirement records the stories satisfy"
assert_equals "epic 42-01${TAB}derived
spec 42 AD5${TAB}derived
spec 42 R1${TAB}derived
spec 42 R2${TAB}derived
story 42-01.2${TAB}derived
story 42-01.3${TAB}derived" "$(links_for "$OUT" cpm/hooks/tests/test-changeset-resolve.sh)"

# --- must NOT infer a link from a time window -------------------------------------------

# `git_fixture_commit` derives each timestamp from the repository's commit count, so two
# of its commits are always a minute apart — which is the one shape this must-NOT cannot
# be tested with. The commits are therefore made directly, at a single stamp, because the
# claim is specifically about commits a time window would group.
commit_at() {
  local repo="$1" stamp="$2" subject="$3" path="$4" content="$5"
  mkdir -p "$repo/$(dirname "$path")"
  printf '%s\n' "$content" > "$repo/$path"
  git_fixture_git "$repo" add -- "$path" || return 1
  GIT_AUTHOR_DATE="$stamp" GIT_COMMITTER_DATE="$stamp" \
    git_fixture_git "$repo" commit -q -m "$subject"
}

WINDOW=$(git_fixture_create timewindow)
git_fixture_commit "$WINDOW" "chore: seed" -- README.md "seed"
WINDOW_BASE=$(git_fixture_git "$WINDOW" rev-parse HEAD)
SAME_STAMP="@1700009999 +0000"
commit_at "$WINDOW" "$SAME_STAMP" "Plan the work" docs/epics/60-01-epic-windowed.md "$EPIC_DOC"
commit_at "$WINDOW" "$SAME_STAMP" "Do the work" src/unrelated.txt "code"
changeset_resolve_git "$WINDOW" --since "$WINDOW_BASE" > "$TEST_TMPDIR/cs-window"
WINDOW_OUT=$(linkset_join "$WINDOW" "$TEST_TMPDIR/cs-window")

# Four facts, and the interesting one is only interesting given the other three. This is
# the exact case AD2 calls "the normal case, not an anomaly": a CPM chain executed in one
# sitting stamps every commit with the same date, so a time-window rule would link these
# two and would look right doing it.
test_start "a file committed separately from the epic doc is not linked to it, even at the same timestamp"
WINDOW_LATER=$(git_fixture_git "$WINDOW" show -s --format=%at HEAD)
WINDOW_EARLIER=$(git_fixture_git "$WINDOW" show -s --format=%at HEAD~1)
if [ "$WINDOW_LATER" != "$WINDOW_EARLIER" ]; then
  test_fail "Positive control failed: the two commits differ in time ($WINDOW_EARLIER vs $WINDOW_LATER), so no time window would have grouped them anyway"
elif [ -z "$(printf '%s\n' "$WINDOW_OUT" | linkset_intent_ids | grep -F 'epic 60-01')" ]; then
  test_fail "Positive control failed: the epic record was not resolved at all, so an absent link proves nothing"
elif ! printf '%s\n' "$WINDOW_OUT" | linkset_links | grep -qF 'docs/epics/60-01-epic-windowed.md'; then
  test_fail "Positive control failed: the epic doc itself was not linked, so the adapter did nothing here"
elif printf '%s\n' "$WINDOW_OUT" | linkset_links | grep -qF 'src/unrelated.txt'; then
  test_fail "Expected no link for a file committed separately: $(links_for "$WINDOW_OUT" src/unrelated.txt)"
else
  test_pass
fi

# --- The contract -------------------------------------------------------------------------

linkset_conformance_run cpm "$REPO" "$CHANGESET"

# A repository with no epic documents is not a channel this adapter can read. That has to
# be distinguishable from "read the documents, found no links" — it is the distinction
# R4 depends on, and the reason exit 2 is in the contract.
test_start "a repository with no epic documents is declined rather than answered empty"
BARE=$(git_fixture_create nocpm)
git_fixture_commit "$BARE" "chore: seed" -- README.md "seed"
cpm_link_changeset "$BARE" "$CHANGESET" >/dev/null 2>&1
assert_equals "2" "$?"

test_start "a directory that is not a git repository is declined, not failed"
mkdir -p "$TEST_TMPDIR/not-a-repo"
cpm_link_changeset "$TEST_TMPDIR/not-a-repo" "$CHANGESET" >/dev/null 2>&1
assert_equals "2" "$?"

# Legacy flat epics (`15-epic-slug.md`) coexist with the two-part shape permanently and
# are never migrated, so an adapter that recognised only the current shape would report
# every older epic's work as orphaned.
test_start "a legacy flat-numbered epic doc is recognised alongside the two-part shape"
LEGACY=$(git_fixture_create legacyepic)
git_fixture_commit "$LEGACY" "chore: seed" -- README.md "seed"
LEGACY_BASE=$(git_fixture_git "$LEGACY" rev-parse HEAD)
git_fixture_commit "$LEGACY" "Older work" -- docs/epics/15-epic-consult.md "$EPIC_DOC" src/old.txt "old"
changeset_resolve_git "$LEGACY" --since "$LEGACY_BASE" > "$TEST_TMPDIR/cs-legacy"
assert_equals "epic 15${TAB}derived" "$(links_for "$(linkset_join "$LEGACY" "$TEST_TMPDIR/cs-legacy")" src/old.txt | grep -F 'epic 15')"

test_summary
