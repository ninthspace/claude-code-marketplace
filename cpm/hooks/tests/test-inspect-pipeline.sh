#!/bin/bash
# test-inspect-pipeline.sh — End-to-end tests for a single /cpm:inspect invocation.
#
# These back Epic 42-05 Story 3's `[integration]` acceptance criteria (spec 42 R9), and
# complete Epic 42-03's coverage row 5, which that epic could verify only as far as "the run
# completes and every file is an orphan" because the review did not exist yet.
#
# --- What this suite does NOT test ------------------------------------------------------
#
# **Whether any finding is produced, or whether it is any good.** `inspect_run` deliberately
# stops short of R5's review: emitting a finding needs a model. What is asserted is that the
# review's *inputs* are prepared and that what a review hands back validates — which is the
# whole of the pipeline that can be checked without one.
#
# **Anything the component suites already own.** Resolution, the join, each gap query and the
# review scaffolding each have their own suite. This one asserts that they compose: that one
# call produces every artifact, in an order where a failure leaves no record behind, and that
# the degraded run reaches the same end rather than a different one.
#
# --- The two criteria are run against the same pipeline ------------------------------------
#
# The degraded run is the *same function* with the same arguments in a repository that has
# nothing to say, not a second code path. That is what makes "and a review still produced"
# a claim about degradation rather than about a fixture: if the zero-channel case took a
# different route, both could pass while the real one was broken.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/git-fixture-helpers.sh"
source "$SCRIPT_DIR/../lib/changeset.sh"
source "$SCRIPT_DIR/../lib/link-adapter-git.sh"
source "$SCRIPT_DIR/../lib/link-adapter-cpm.sh"
source "$SCRIPT_DIR/../lib/inspect-run.sh"
source "$SCRIPT_DIR/../lib/inspect-project.sh"

echo "Testing a single /cpm:inspect invocation, end to end..."
echo ""

TAB=$(printf '\t')

manifest_of() { printf '%s\n' "$1" | awk -F'\t' -v k="$2" '$1 == k { print $2 }'; }

# --- Fixture: a repository with something to say ------------------------------------------
#
# A CPM-shaped repository: an epic doc, a coverage matrix, a commit carrying a trailer, and
# a file committed on its own with nothing pointing at it. Both adapters have material, and
# there is a genuine orphan for R3 to find rather than a change set where everything or
# nothing resolves.

REPO=$(git_fixture_create pipeline)
git_fixture_commit "$REPO" "chore: seed" -- README.md "seed"
BASE=$(git_fixture_git "$REPO" rev-parse HEAD)

git_fixture_commit "$REPO" "feat: the tracked work" --trailer "Refs: epic 42-05" -- \
  docs/epics/42-05-epic-worked.md '# Worked

**Status**: Complete

## A story
**Story**: 1
**Status**: Complete

**Acceptance Criteria**:

- Something observable happens [integration]
' \
  src/tracked.sh "tracked"

git_fixture_commit "$REPO" "chore: tidy up while I was here" -- src/untracked.sh "untracked"

WORK="$TEST_TMPDIR/work"
MANIFEST=$(inspect_run "$REPO" "$WORK" 10 --since "$BASE")
RC=$?

# --- Criterion: one invocation does all of it, in one pass ----------------------------------

test_start "the invocation succeeds"
assert_equals "0" "$RC"

test_start "it reports the selector and the direction it resolved in"
assert_equals "--since $BASE|git" "$(manifest_of "$MANIFEST" SELECTOR)|$(manifest_of "$MANIFEST" DIRECTION)"

test_start "it names the adapters that actually ran"
assert_equals "gitnative
cpm" "$(printf '%s\n' "$MANIFEST" | awk -F'\t' '$1 == "ADAPTER" { print $2 }')"

# Every artifact the manifest promises, asserted as a set rather than one at a time: a
# pipeline that produced five of six would otherwise pass every individual check that
# happened to be written.
test_start "every stage named in the manifest produced a file"
MISSING=""
for key in CHANGESET LINKSET GAPS SELECTION PAYLOAD; do
  path=$(manifest_of "$MANIFEST" "$key")
  if [ -z "$path" ] || [ ! -s "$path" ]; then
    MISSING="$MISSING $key"
  fi
done
assert_empty "$MISSING"

test_start "and the record landed in the repository, at the path the manifest gives"
RECORD=$(manifest_of "$MANIFEST" RECORD)
assert_equals "docs/inspect/since-$(printf '%s' "$BASE" | tr '[:upper:]' '[:lower:]').json|yes" \
  "$RECORD|$([ -s "$REPO/$RECORD" ] && echo yes)"

test_start "the counts it reports are the change set it resolved"
assert_equals "$(changeset_commits < "$WORK/changeset" | grep -c .)|$(changeset_files < "$WORK/changeset" | grep -c .)" \
  "$(manifest_of "$MANIFEST" COMMITS)|$(manifest_of "$MANIFEST" FILES)"

# The join ran and found something. Without this the orphan assertions below would be
# equally explained by a join that resolved nothing at all.
test_start "the join resolved at least one file to the intent record"
assert_contains "$(cat "$WORK/linkset")" "LINK${TAB}src/tracked.sh${TAB}epic 42-05"

test_start "both gap queries are answered in the one pass"
assert_equals "1|1|1" \
  "$(grep -c '^ORPHANS' "$WORK/gaps")|$(grep -c '^ANSWERABILITY' "$WORK/gaps")|$(grep -c '^CLAIMS' "$WORK/gaps")"

test_start "R3 found the file that nothing accounts for"
assert_equals "src/untracked.sh" "$(awk -F'\t' '$1 == "ORPHAN" { print $2 }' "$WORK/gaps")"

test_start "and did not call the tracked file an orphan"
assert_empty "$(awk -F'\t' '$1 == "ORPHAN" && $2 == "src/tracked.sh"' "$WORK/gaps")"

test_start "the review has an examination order and a completeness verdict to work from"
assert_equals "$(changeset_files < "$WORK/changeset" | LC_ALL=C sort)|COMPLETE${TAB}yes" \
  "$(awk -F'\t' '$1 == "EXAMINED" { print $2 }' "$WORK/selection" | LC_ALL=C sort)|$(grep '^COMPLETE' "$WORK/selection")"

test_start "the payload carries the join's data"
assert_contains "$(cat "$WORK/payload")" "FILEINTENT${TAB}src/tracked.sh${TAB}epic 42-05"

# AD3 at the far end of the pipeline. Each library asserts it locally; this is the one place
# it is checked on what a full run actually hands the review.
test_start "and none of its confidence labels"
LEAKED=""
for label in $REVIEW_FORBIDDEN_LABELS; do
  if LC_ALL=C grep -qw "$label" "$WORK/payload"; then LEAKED="$LEAKED $label"; fi
done
assert_empty "$LEAKED"

test_start "the control: both labels are in the link set the payload was built from"
assert_equals "declared derived" "$(awk -F'\t' '$1 == "LINK" { print $4 }' "$WORK/linkset" | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ $//')"

# The record is the pipeline's output of record, so the projection over it must describe the
# same run rather than a subset of it.
test_start "the record describes the run the manifest reported"
PROJECTION=$(inspect_projection "$REPO/$RECORD")
assert_equals "--since $BASE|$(manifest_of "$MANIFEST" FILES)" \
  "$(printf '%s\n' "$PROJECTION" | awk -F'\t' '$1 == "SELECTOR" { print $2 }')|$(printf '%s\n' "$PROJECTION" | awk -F'\t' '$1 == "COUNT" && $2 == "files" { print $3 }')"

test_start "the record's orphans agree with the gap query's"
assert_equals "$(awk -F'\t' '$1 == "ORPHAN" { print $2 }' "$WORK/gaps" | LC_ALL=C sort)" \
  "$(printf '%s\n' "$PROJECTION" | awk -F'\t' '$1 == "ORPHAN" { print $2 }' | LC_ALL=C sort)"

# Determinism reaching the end of the pipeline, not just the writer: a second full run over
# the same commits must produce the same record byte for byte.
test_start "a second run of the same selector rewrites the same record identically"
BEFORE=$(cat "$REPO/$RECORD")
inspect_run "$REPO" "$TEST_TMPDIR/work2" 10 --since "$BASE" >/dev/null
assert_equals "$BEFORE" "$(cat "$REPO/$RECORD")"

# --- Criterion: a repository with no intent sources -------------------------------------------
#
# Epic 42-03's coverage row 5 finally becomes fully verifiable here. Same function, same
# arguments, a repository with no epic docs, no coverage matrices and no trailers.

BARE=$(git_fixture_create pipeline-bare)
git_fixture_commit "$BARE" "chore: seed" -- README.md "seed"
BARE_BASE=$(git_fixture_git "$BARE" rev-parse HEAD)
git_fixture_commit "$BARE" "some work" -- src/a.py "a" src/b.py "b" src/c.py "c"

# Asserted *before* the run, not after. The run writes its record into `docs/inspect/`, so
# a control checking for the absence of `docs/` afterwards finds the directory the run just
# created and fails for a reason that has nothing to do with the fixture.
test_start "the repository has no CPM artifacts — the control, checked before the run"
assert_empty "$(ls -d "$BARE/docs" 2>/dev/null)"

test_start "and no commit trailers either, so neither adapter has anything to read"
assert_empty "$(git_fixture_git "$BARE" log --format='%(trailers)' | grep '[^[:space:]]')"

BARE_WORK="$TEST_TMPDIR/bare-work"
BARE_MANIFEST=$(inspect_run "$BARE" "$BARE_WORK" 10 --since "$BARE_BASE")
BARE_RC=$?

test_start "the run completes rather than failing"
assert_equals "0" "$BARE_RC"

test_start "the adapters ran and found nothing, which is not the same as not running"
assert_equals "gitnative
cpm" "$(printf '%s\n' "$BARE_MANIFEST" | awk -F'\t' '$1 == "ADAPTER" { print $2 }')"

test_start "no link was invented"
assert_empty "$(awk -F'\t' '$1 == "LINK"' "$BARE_WORK/linkset")"

test_start "every file is an orphan"
assert_equals "$(changeset_files < "$BARE_WORK/changeset")" \
  "$(awk -F'\t' '$1 == "ORPHAN" { print $2 }' "$BARE_WORK/gaps")"

test_start "the orphan count is the whole change set, stated as such"
assert_equals "ORPHANS${TAB}3${TAB}3" "$(grep '^ORPHANS' "$BARE_WORK/gaps")"

# R4 degrades into a refusal where R3 degrades into a finding, and the difference is the
# whole of why `gap_report` carries an answerability line at all.
test_start "R4 reports itself unanswerable rather than clean"
assert_equals "ANSWERABILITY${TAB}unanswerable" "$(grep '^ANSWERABILITY' "$BARE_WORK/gaps")"

# "and a review still produced" — the half Epic 42-03 could not reach.
test_start "a review is still produced, over every file"
assert_equals "$(changeset_files < "$BARE_WORK/changeset" | LC_ALL=C sort)" \
  "$(awk -F'\t' '$1 == "EXAMINED" { print $2 }' "$BARE_WORK/selection" | LC_ALL=C sort)"

test_start "and it does not present itself as partial"
assert_equals "COMPLETE${TAB}yes" "$(grep '^COMPLETE' "$BARE_WORK/selection")"

test_start "the payload reaches the review with every file in it"
assert_equals "$(changeset_files < "$BARE_WORK/changeset")" \
  "$(awk -F'\t' '$1 == "FILE" { print $2 }' "$BARE_WORK/payload")"

test_start "a finding produced over the degraded run still validates"
review_emit_finding "src/a.py" "3" "unchecked exit status" \
  | review_validate_findings "$BARE_WORK/changeset" >/dev/null 2>&1
assert_equals "0" "$?"

test_start "the record is written even though it has nothing to link"
BARE_RECORD=$(manifest_of "$BARE_MANIFEST" RECORD)
assert_equals "yes|3" \
  "$([ -s "$BARE/$BARE_RECORD" ] && echo yes)|$(inspect_projection "$BARE/$BARE_RECORD" | grep -c '^ORPHAN')"

# The comparison that makes this a degradation test rather than two unrelated fixtures: the
# same call reached the same end state in both, differing only in what it could resolve.
test_start "both runs produced the same set of stages, one with links and one without"
STAGES_OF() { printf '%s\n' "$1" | awk -F'\t' '$1 ~ /^(CHANGESET|LINKSET|GAPS|SELECTION|PAYLOAD|RECORD)$/ { print $1 }'; }
assert_equals "$(STAGES_OF "$MANIFEST")" "$(STAGES_OF "$BARE_MANIFEST")"

test_start "and they differ where they should: links resolved in one, none in the other"
if [ -z "$(awk -F'\t' '$1 == "LINK"' "$WORK/linkset")" ]; then
  test_fail "Positive control failed: the CPM-shaped run resolved no links either"
elif [ -n "$(awk -F'\t' '$1 == "LINK"' "$BARE_WORK/linkset")" ]; then
  test_fail "The bare run resolved links it has no source for"
else
  test_pass
fi

# --- An adapter that was never sourced ------------------------------------------------------------
#
# The condition a caller creates by not sourcing `link-adapter-cpm.sh`, which is what makes
# "zero cooperating channels" a supported state rather than a misconfiguration. Run in a
# subshell so the adapter is gone for this run only, and against the CPM-shaped fixture —
# where the missing adapter has material it *would* have found, so its absence has to show.

test_start "an adapter whose function is not defined is skipped, not registered"
PARTIAL_WORK="$TEST_TMPDIR/partial-work"
PARTIAL_MANIFEST=$( unset -f cpm_link_changeset; inspect_run "$REPO" "$PARTIAL_WORK" 10 --since "$BASE" )
assert_equals "gitnative" "$(printf '%s\n' "$PARTIAL_MANIFEST" | awk -F'\t' '$1 == "ADAPTER" { print $2 }')"

test_start "and the run still completes, producing every stage"
assert_equals "$(STAGES_OF "$MANIFEST")" "$(STAGES_OF "$PARTIAL_MANIFEST")"

# The control: if the CPM adapter contributed nothing to the full run either, dropping it
# would prove nothing about skipping.
test_start "the dropped adapter really did contribute links to the full run"
if [ "$(awk -F'\t' '$1 == "LINK"' "$WORK/linkset" | wc -l)" \
   -le "$(awk -F'\t' '$1 == "LINK"' "$PARTIAL_WORK/linkset" | wc -l)" ]; then
  test_fail "Dropping the CPM adapter lost no links, so the skip is unproven"
else
  test_pass
fi

# --- Failure ordering ---------------------------------------------------------------------------

# The record is written last on purpose. A run that dies in resolution must not leave a
# document behind describing a change set that was never established.
test_start "a selector that matches nothing fails and writes no record"
FAIL_WORK="$TEST_TMPDIR/fail-work"
inspect_run "$BARE" "$FAIL_WORK" 10 --since HEAD >/dev/null 2>&1
assert_equals "1|0" "$?|$(ls "$BARE/docs/inspect" 2>/dev/null | grep -c 'head')"

test_start "no selector is refused"
inspect_run "$REPO" "$TEST_TMPDIR/none" 10 >/dev/null 2>&1
assert_equals "1" "$?"

test_start "a non-numeric budget is refused"
BUDGET_WORK="$TEST_TMPDIR/budget-work"
inspect_run "$REPO" "$BUDGET_WORK" "lots" --since "$BASE" >/dev/null 2>&1
assert_equals "1" "$?"

# The assertion that actually pins the write to the *end* of the pipeline. The failures above
# happen during resolution, before any plausible write position, so they hold however early
# the record is written. This one resolves successfully and dies afterwards, in the review
# selection — the only window where "written last" and "written early" differ.
test_start "a run that resolves and then fails leaves no record behind"
printf 'dirty\n' > "$BARE/src/uncommitted.py"
LATE_WORK="$TEST_TMPDIR/late-work"
inspect_run "$BARE" "$LATE_WORK" "lots" --working-tree >/dev/null 2>&1
assert_equals "1|0" "$?|$(ls "$BARE/docs/inspect" 2>/dev/null | grep -c 'working-tree')"

# The control for it: the same selector with a usable budget does write that record, so the
# absence above is the failure and not the selector.
test_start "the control: the same selector succeeds and does write one"
inspect_run "$BARE" "$TEST_TMPDIR/late-ok" 10 --working-tree >/dev/null 2>&1
assert_equals "0|1" "$?|$(ls "$BARE/docs/inspect" 2>/dev/null | grep -c 'working-tree')"

test_summary
