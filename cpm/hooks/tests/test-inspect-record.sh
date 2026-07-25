#!/bin/bash
# test-inspect-record.sh — Tests the deterministic JSON record.
#
# These back Epic 42-02 Story 5's acceptance criteria (spec 42 R6, AD3, AD4).
#
# **The JSON is validated by a parser this repository did not write.** `jq` or `python3`
# reads back what the awk serialiser produced, and the escaping test compares the parsed
# string to the original text. A writer checked only by its own author's assumptions about
# JSON is the exact shape of bug that produces a document which parses cleanly and means
# something else.
#
# **Determinism is asserted run-against-run, never against a checked-in document.** A
# golden file would go stale the first time the schema gained a field, and it would be
# testing the fixture rather than the property (retro 19). The stronger form is the
# registration-order test: the same records arriving in a different sequence must produce
# the same bytes, which is what would actually catch a missing sort.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/git-fixture-helpers.sh"
source "$SCRIPT_DIR/../lib/changeset.sh"
source "$SCRIPT_DIR/../lib/changeset-resolve.sh"
source "$SCRIPT_DIR/../lib/linkset.sh"
source "$SCRIPT_DIR/../lib/linkset-join.sh"
source "$SCRIPT_DIR/../lib/inspect-record.sh"
source "$SCRIPT_DIR/stub-link-adapter.sh"

echo "Testing the deterministic JSON record..."
echo ""

TAB="$LINKSET_TAB"

# An independent JSON parser, used as the oracle. Deliberately no silent skip: a validity
# check that quietly does nothing on a machine without a parser is worse than no check,
# because the suite still reports green.
if command -v jq >/dev/null 2>&1; then
  JSON_PARSER="jq"
elif command -v python3 >/dev/null 2>&1; then
  JSON_PARSER="python3"
else
  JSON_PARSER="none"
fi

json_is_valid() {
  case "$JSON_PARSER" in
    jq) printf '%s\n' "$1" | jq empty >/dev/null 2>&1 ;;
    python3) printf '%s\n' "$1" | python3 -c 'import json,sys; json.load(sys.stdin)' >/dev/null 2>&1 ;;
    *) return 2 ;;
  esac
}

# Read one value out of the document with the independent parser.
json_query() {
  local doc="$1" path="$2"
  case "$JSON_PARSER" in
    jq) printf '%s\n' "$doc" | jq -r "$path" 2>/dev/null ;;
    python3) printf '%s\n' "$doc" | python3 -c "
import json,sys
d = json.load(sys.stdin)
print(eval('d$path'))
" 2>/dev/null ;;
  esac
}

# --- Fixture -----------------------------------------------------------------------------

REPO=$(git_fixture_create inspect)
git_fixture_commit "$REPO" "chore: seed" -- README.md "seed"
BASE=$(git_fixture_git "$REPO" rev-parse HEAD)
git_fixture_commit "$REPO" "feat: two files" -- src/a.txt "a" src/b.txt "b"

CHANGESET="$TEST_TMPDIR/changeset"
changeset_resolve_git "$REPO" --since "$BASE" > "$CHANGESET"
CHANGED_FILES=$(changeset_files < "$CHANGESET")

# A criterion carrying the two characters that break a naive serialiser. Not an edge case:
# CPM criterion text routinely contains backticks and quoted values, and a path with a
# backslash is legal on the platforms this runs on.
NASTY_TEXT='He said "hello" and used a back\slash'

stub_link_records \
  "INTENT${TAB}epic 42-01${TAB}done${TAB}Change-Set Resolution" \
  "CRITERION${TAB}epic 42-01${TAB}verified${TAB}${NASTY_TEXT}" \
  "LINK${TAB}src/a.txt${TAB}epic 42-01${TAB}declared"
stub2_link_records \
  "INTENT${TAB}AUTH-7${TAB}open${TAB}Ticket seven" \
  "LINK${TAB}src/a.txt${TAB}AUTH-7${TAB}derived"

linkset_reset
linkset_register stub
linkset_register stub2
JOINED=$(linkset_join "$REPO" "$CHANGESET")
DOC=$(printf '%s\n' "$JOINED" | inspect_json "$REPO" "$CHANGESET" "epic 42-01")

# --- The emitted document is valid JSON ---------------------------------------------------

test_start "an independent JSON parser is available to validate against"
assert_equals "available" "$([ "$JSON_PARSER" = "none" ] && echo "none — install jq or python3" || echo "available")"

test_start "the emitted document is valid JSON"
if json_is_valid "$DOC"; then
  test_pass
else
  test_fail "The document did not parse: $(printf '%s\n' "$DOC" | head -5)"
fi

test_start "a criterion containing quotes and backslashes round-trips through that parser"
assert_equals "$NASTY_TEXT" "$(json_query "$DOC" '.intents[] | select(.id == "epic 42-01") | .criteria[0].text')"

test_start "the document reports the schema version its consumers key on"
assert_equals "$INSPECT_SCHEMA_VERSION" "$(json_query "$DOC" '.schema')"

test_start "the document records the selector it was produced for"
assert_equals "epic 42-01" "$(json_query "$DOC" '.selector')"

test_start "the change set reaches the document intact"
assert_equals "$CHANGED_FILES" "$(json_query "$DOC" '.changeset.files[]')"

# Not every array in this document is sorted, and the exception is deliberate: commits
# keep git's rev-list order because that order is the sequence the work happened in.
# Determinism does not require alphabetical, only that two runs agree — and asserting
# sortedness here would have locked in the wrong property.
test_start "commits keep git's rev-list order rather than being sorted alphabetically"
assert_equals "$(changeset_commits < "$CHANGESET")" "$(json_query "$DOC" '.changeset.commits[]')"

test_start "an intent with no criteria still emits an empty criteria array"
assert_equals "0" "$(json_query "$DOC" '.intents[] | select(.id == "AUTH-7") | .criteria | length')"

# AD3: the review consumes the join's data, never its labels. Keeping links and labels in
# separate arrays is what makes that boundary visible in the document itself.
test_start "links carry confidences and files carry labels, in separate arrays"
assert_equals "declared derived|declared" "$(json_query "$DOC" '[.links[].confidence] | sort | join(" ")')|$(json_query "$DOC" '.files[] | select(.path == "src/a.txt") | .label')"

test_start "a file no adapter resolved is recorded as absent"
assert_equals "absent" "$(json_query "$DOC" '.files[] | select(.path == "src/b.txt") | .label')"

# --- Two runs against the same repository state produce byte-identical JSON ---------------

test_start "two runs over the same state produce byte-identical JSON"
assert_equals "$DOC" "$(printf '%s\n' "$JOINED" | inspect_json "$REPO" "$CHANGESET" "epic 42-01")"

# The stronger form. Byte-identity across two identical runs would survive an unsorted
# array; identity across a different arrival order would not.
test_start "the same records in a different adapter order produce byte-identical JSON"
linkset_reset
linkset_register stub2
linkset_register stub
assert_equals "$DOC" "$(linkset_join "$REPO" "$CHANGESET" | inspect_json "$REPO" "$CHANGESET" "epic 42-01")"

# A timestamp or run identifier is the obvious thing to add to a record, and either would
# make every assertion above fail intermittently rather than immediately.
test_start "the document carries nothing that varies between runs"
assert_empty "$(printf '%s\n' "$DOC" | grep -niE '"(timestamp|generated|date|run_?id|created)"')"

# --- The record is written to docs/inspect/ ------------------------------------------------

test_start "the record is written under docs/inspect/ in the repository"
linkset_reset
linkset_register stub
linkset_register stub2
WRITTEN=$(linkset_join "$REPO" "$CHANGESET" | inspect_write "$REPO" "$CHANGESET" "epic 42-01")
assert_equals "docs/inspect/epic-42-01.json|yes" "$WRITTEN|$([ -f "$REPO/$WRITTEN" ] && echo yes || echo no)"

test_start "what was written is what the serialiser produced"
assert_equals "$DOC" "$(cat "$REPO/$WRITTEN")"

test_start "a git-anchored selector produces its own record rather than overwriting another"
SINCE_PATH=$(linkset_join "$REPO" "$CHANGESET" | inspect_write "$REPO" "$CHANGESET" "--since $BASE")
assert_equals "docs/inspect/since-$(printf '%s' "$BASE" | tr '[:upper:]' '[:lower:]').json|2" \
  "$SINCE_PATH|$(ls "$REPO/docs/inspect" | wc -l | tr -d ' ')"

# Rerunning the same selector overwrites in place, which is what makes the deferred
# run-to-run delta an ordinary `git diff` rather than a comparison someone constructs.
test_start "rerunning the same selector overwrites its record rather than adding one"
linkset_join "$REPO" "$CHANGESET" | inspect_write "$REPO" "$CHANGESET" "epic 42-01" >/dev/null
assert_equals "2" "$(ls "$REPO/docs/inspect" | wc -l | tr -d ' ')"

test_start "a selector that would escape docs/inspect/ is refused, writing nothing"
BEFORE=$(ls "$REPO/docs/inspect" | wc -l | tr -d ' ')
TRAVERSAL=$(linkset_join "$REPO" "$CHANGESET" | inspect_write "$REPO" "$CHANGESET" "../../etc/passwd" 2>/dev/null)
TRAVERSAL_RC=$?
if [ "$TRAVERSAL_RC" -eq 0 ] && [ -n "$TRAVERSAL" ]; then
  case "$TRAVERSAL" in
    docs/inspect/*) test_pass ;;
    *) test_fail "A traversing selector produced a path outside docs/inspect/: $TRAVERSAL" ;;
  esac
elif [ "$BEFORE" != "$(ls "$REPO/docs/inspect" | wc -l | tr -d ' ')" ]; then
  test_fail "A refused selector still changed the contents of docs/inspect/"
else
  test_pass
fi

test_start "a selector with no usable characters is refused rather than writing an unnamed file"
printf '' | inspect_write "$REPO" "$CHANGESET" "///" >/dev/null 2>&1
assert_equals "1" "$?"

# --- Degradation ---------------------------------------------------------------------------

# R9: "In a repository with no recognised intent source, the review still runs and every
# file is reported as an orphan." The record is where that has to survive to.
test_start "with no adapters the document is still valid and every file is absent"
linkset_reset
BARE_DOC=$(linkset_join "$REPO" "$CHANGESET" | inspect_json "$REPO" "$CHANGESET" "epic 42-01")
if ! json_is_valid "$BARE_DOC"; then
  test_fail "The zero-adapter document did not parse: $(printf '%s\n' "$BARE_DOC" | head -5)"
elif [ -z "$CHANGED_FILES" ]; then
  test_fail "Positive control failed: the change set has no files, so an all-absent list proves nothing"
else
  assert_equals "absent" "$(json_query "$BARE_DOC" '[.files[].label] | unique | join(" ")')"
fi

test_start "with no adapters the links and intents arrays are empty rather than missing"
assert_equals "0 0" "$(json_query "$BARE_DOC" '.links | length') $(json_query "$BARE_DOC" '.intents | length')"

test_start "a missing change set file errors rather than emitting an empty record"
printf '' | inspect_json "$REPO" "$TEST_TMPDIR/no-such-changeset" "epic 42-01" >/dev/null 2>&1
assert_equals "1" "$?"

test_summary
