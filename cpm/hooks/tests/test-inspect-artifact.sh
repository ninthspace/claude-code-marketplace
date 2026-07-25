#!/bin/bash
# test-inspect-artifact.sh — Tests the artifact projection, its backlink and its register row.
#
# These back Epic 42-05 Story 2's `[integration]` acceptance criteria (spec 42 R8, AD4, and
# the NFR "Offline Integrity").
#
# --- What this suite does NOT test ------------------------------------------------------
#
# **Anything about a published page.** Nothing here calls the Artifact tool, composes HTML,
# or reaches the network. Publishing is a model-and-tool step governed by the shared
# **Artifact Publishing** convention; what is testable is the boundary underneath it — that
# the material handed to the composer comes from the record and from nothing else, that the
# build path is the same on every publish of the same run, and that the two recording sites
# refuse to record a URL that does not exist.
#
# **Whether the page is any good.** `artifact-design` governs that and there is no oracle
# for it here.
#
# --- Why the must-NOT is testable at all --------------------------------------------------
#
# "must NOT embed source content in the published page" would be unfalsifiable if the page
# were the unit under test — a page could always be written that happened not to quote a
# file. It becomes checkable one level down: `inspect_projection` opens the record and never
# the repository, so the assertion is that a distinctive string living only inside a source
# file cannot appear in the projection. A page composed from the projection inherits that
# by construction, which is the design AD4 asks for.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/git-fixture-helpers.sh"
source "$SCRIPT_DIR/../lib/changeset.sh"
source "$SCRIPT_DIR/../lib/changeset-resolve.sh"
source "$SCRIPT_DIR/../lib/linkset.sh"
source "$SCRIPT_DIR/../lib/linkset-join.sh"
source "$SCRIPT_DIR/../lib/inspect-record.sh"
source "$SCRIPT_DIR/../lib/inspect-project.sh"
source "$SCRIPT_DIR/stub-link-adapter.sh"

echo "Testing the inspect artifact projection, backlink and register row..."
echo ""

TAB="$INSPECT_PROJECT_TAB"
SENTINEL="SENTINEL_SOURCE_TEXT_MUST_NOT_BE_PUBLISHED"

# --- Fixture -----------------------------------------------------------------------------
#
# `src/linked.sh` carries the sentinel *inside the file*, and is also the file the record
# names — so "the path appears, the contents do not" is a distinction the projection has to
# actually make rather than one the fixture makes for it.

REPO=$(git_fixture_create artifact)
git_fixture_commit "$REPO" "chore: seed" -- README.md "seed"
BASE=$(git_fixture_git "$REPO" rev-parse HEAD)
git_fixture_commit "$REPO" "feat: two files" -- \
  src/linked.sh "$SENTINEL" src/orphan.sh "plain"

CHANGESET="$TEST_TMPDIR/changeset"
changeset_resolve_git "$REPO" --since "$BASE" > "$CHANGESET"

stub_link_records \
  "INTENT${TAB}epic 42-05${TAB}done${TAB}Skill Assembly and Artifact" \
  "CRITERION${TAB}epic 42-05${TAB}verified${TAB}The page is projected from the JSON record" \
  "CRITERION${TAB}epic 42-05${TAB}unverified${TAB}A criterion whose text has a \"quote\", a \\backslash and a , comma" \
  "LINK${TAB}src/linked.sh${TAB}epic 42-05${TAB}declared"

linkset_reset
linkset_register stub
JOINED=$(linkset_join "$REPO" "$CHANGESET")

RECORD="$TEST_TMPDIR/record.json"
printf '%s\n' "$JOINED" | inspect_json "$REPO" "$CHANGESET" "epic 42-05" > "$RECORD"
PROJECTION=$(inspect_projection "$RECORD")

field() { printf '%s\n' "$PROJECTION" | awk -F'\t' -v k="$1" '$1 == k { print $2 }'; }

# --- Criterion: the page is projected from the JSON record --------------------------------
#
# A round trip, not a comparison against a golden projection. The record was written from
# `$JOINED`, so projecting it back must reproduce what went in — which is the property that
# keeps this reader and `inspect_json`'s writer from drifting apart, and it holds whatever
# the fixture becomes later.

test_start "the links survive the round trip through the record"
assert_equals "$(printf '%s\n' "$JOINED" | awk -F'\t' '$1 == "LINK" { print $2 "\t" $3 "\t" $4 }' | LC_ALL=C sort)" \
  "$(printf '%s\n' "$PROJECTION" | awk -F'\t' '$1 == "LINK" { print $2 "\t" $3 "\t" $4 }' | LC_ALL=C sort)"

test_start "the intents survive the round trip"
assert_equals "$(printf '%s\n' "$JOINED" | awk -F'\t' '$1 == "INTENT" { print $2 "\t" $3 "\t" $4 }' | LC_ALL=C sort)" \
  "$(printf '%s\n' "$PROJECTION" | awk -F'\t' '$1 == "INTENT" { print $2 "\t" $3 "\t" $4 }' | LC_ALL=C sort)"

test_start "the criteria survive the round trip, including their punctuation"
assert_equals "$(printf '%s\n' "$JOINED" | awk -F'\t' '$1 == "CRITERION" { print $2 "\t" $3 "\t" $4 }' | LC_ALL=C sort)" \
  "$(printf '%s\n' "$PROJECTION" | awk -F'\t' '$1 == "CRITERION" { print $2 "\t" $3 "\t" $4 }' | LC_ALL=C sort)"

# The control for the three above. If the fixture produced no criteria, "they survive"
# would be a comparison of two empty sets.
test_start "the fixture really carries links, intents and criteria to lose"
assert_equals "1|1|2" \
  "$(printf '%s\n' "$PROJECTION" | grep -c '^LINK')|$(printf '%s\n' "$PROJECTION" | grep -c '^INTENT')|$(printf '%s\n' "$PROJECTION" | grep -c '^CRITERION')"

test_start "a criterion containing a quote and a backslash reads back unmangled"
assert_contains "$PROJECTION" 'A criterion whose text has a "quote", a \backslash and a , comma'

test_start "every file in the change set reaches the projection with its label"
assert_equals "src/linked.sh${TAB}declared
src/orphan.sh${TAB}absent" \
  "$(printf '%s\n' "$PROJECTION" | awk -F'\t' '$1 == "FILE" { print $2 "\t" $3 }')"

test_start "the selector and schema are carried, so a reader knows what it is holding"
assert_equals "epic 42-05|cpm.inspect/1" "$(field SELECTOR)|$(field SCHEMA)"

test_start "the counts match the change set the record was built from"
assert_equals "$(changeset_commits < "$CHANGESET" | grep -c .)|$(changeset_files < "$CHANGESET" | grep -c .)" \
  "$(printf '%s\n' "$PROJECTION" | awk -F'\t' '$1 == "COUNT" && $2 == "commits" { print $3 }')|$(printf '%s\n' "$PROJECTION" | awk -F'\t' '$1 == "COUNT" && $2 == "files" { print $3 }')"

# Orphans are derived here rather than re-queried, so the derivation is worth asserting
# against the labels it comes from rather than against a list.
test_start "the orphans are exactly the files labelled absent"
assert_equals "$(printf '%s\n' "$PROJECTION" | awk -F'\t' '$1 == "FILE" && $3 == "absent" { print $2 }')" \
  "$(printf '%s\n' "$PROJECTION" | awk -F'\t' '$1 == "ORPHAN" { print $2 }')"

test_start "and there is a non-orphan for them to be distinguished from"
assert_equals "1" "$(printf '%s\n' "$PROJECTION" | awk -F'\t' '$1 == "FILE" && $3 != "absent"' | wc -l | tr -d ' ')"

# --- Criterion (must NOT): no source content in the page ------------------------------------

test_start "the sentinel really is in the source file — the control for the must-NOT"
assert_contains "$(cat "$REPO/src/linked.sh")" "$SENTINEL"

test_start "the record does not carry file contents"
assert_empty "$(grep -F "$SENTINEL" "$RECORD")"

test_start "and neither does the projection the page is composed from"
assert_empty "$(printf '%s\n' "$PROJECTION" | grep -F "$SENTINEL")"

# The other half of the must-NOT: stripping content by dropping the file would satisfy the
# assertion above and defeat the point.
test_start "the file the sentinel lives in is still named, by path"
assert_contains "$PROJECTION" "src/linked.sh"

# The structural reason the must-NOT holds, rather than an accident of this fixture: the
# projection is a function of the record alone, so a repository that has moved on cannot
# change it.
test_start "the projection depends on the record alone, not on the repository"
BEFORE="$PROJECTION"
printf 'rewritten after the record was written\n' > "$REPO/src/linked.sh"
rm -f "$REPO/src/orphan.sh"
assert_equals "$BEFORE" "$(inspect_projection "$RECORD")"

# --- Criterion: re-publishing the same run redeploys to the same URL --------------------------
#
# The mechanism is the build path, which is a pure function of the slug. Same run, same
# path, same artifact; a different run must not land on it.

test_start "the build path is the same on every publish of the same run"
assert_equals "$(inspect_artifact_path "$(inspect_slug 'epic 42-05')")" \
  "$(inspect_artifact_path "$(inspect_slug 'epic 42-05')")"

test_start "a different selector builds to a different path"
if [ "$(inspect_artifact_path "$(inspect_slug 'epic 42-05')")" \
   = "$(inspect_artifact_path "$(inspect_slug 'epic 42-04')")" ]; then
  test_fail "Two selectors share one build path, so re-publishing either would overwrite the other"
else
  test_pass
fi

test_start "the build path is a scratch location, not a storage directory"
assert_equals "docs/plans/inspect-artifact-epic-42-05.html" \
  "$(inspect_artifact_path "$(inspect_slug 'epic 42-05')")"

test_start "a path is refused without a slug rather than defaulting to a shared one"
inspect_artifact_path "" >/dev/null 2>&1
assert_equals "1" "$?"

# --- Criterion: the register row and the backlink ------------------------------------------

SLUG=$(inspect_slug "epic 42-05")
URL="https://claude.ai/code/artifact/0000-1111"

test_start "the backlink is written beside the record, not inside it"
SIDECAR=$(inspect_sidecar_write "$REPO" "$SLUG" "$URL")
assert_equals "docs/inspect/epic-42-05.artifacts.md" "$SIDECAR"

test_start "it carries the Artifacts field the invariant names, with the URL"
assert_contains "$(cat "$REPO/$SIDECAR")" "**Artifacts**: $URL"

test_start "and names the record it belongs to, so the link reads from both ends"
assert_contains "$(cat "$REPO/$SIDECAR")" "docs/inspect/epic-42-05.json"

# The reason the sidecar exists at all: the record must not move when a page is published.
test_start "publishing leaves the record byte-identical"
assert_equals "$(printf '%s\n' "$JOINED" | inspect_json "$REPO" "$CHANGESET" "epic 42-05")" "$(cat "$RECORD")"

test_start "the register row uses the register's column order"
assert_equals "| Provenance for epic 42-05 | $URL | 2026-07-25 | \`docs/inspect/epic-42-05.json\` | Shows what traced to what |" \
  "$(inspect_register_row "$URL" "Provenance for epic 42-05" "2026-07-25" "docs/inspect/epic-42-05.json" "Shows what traced to what")"

# --- Criterion: the run does not fail when the Artifact tool is unavailable ---------------------
#
# With no tool there is no URL, and the failure to guard against is a recording site that
# writes the *shape* of a backlink around an absent value — which greps as "published" and
# leaves the absence visible nowhere.

test_start "a backlink with no URL is refused rather than written empty"
inspect_sidecar_write "$REPO" "$SLUG" "" >/dev/null 2>&1
assert_equals "1" "$?"

test_start "a register row with no URL is refused"
inspect_register_row "" "name" "2026-07-25" "src" "why" >/dev/null 2>&1
assert_equals "1" "$?"

test_start "a register row missing any other fact is refused too"
inspect_register_row "$URL" "name" "2026-07-25" "src" "" >/dev/null 2>&1
assert_equals "1" "$?"

# The positive half: the run's own output is untouched by the absence. A projection is still
# produced, which is what "the run does not fail" means at this level.
test_start "the projection is still produced when nothing is ever published"
assert_equals "$PROJECTION" "$(inspect_projection "$RECORD")"

# --- Edges ---------------------------------------------------------------------------------------

test_start "a record with no links or intents projects rather than erroring"
EMPTY_RECORD="$TEST_TMPDIR/empty.json"
linkset_reset
printf '' | inspect_json "$REPO" "$CHANGESET" "--since $BASE" > "$EMPTY_RECORD"
EMPTY_PROJECTION=$(inspect_projection "$EMPTY_RECORD")
assert_equals "src/linked.sh
src/orphan.sh" "$(printf '%s\n' "$EMPTY_PROJECTION" | awk -F'\t' '$1 == "ORPHAN" { print $2 }')"

test_start "and reports no adapters rather than omitting the fact"
assert_empty "$(printf '%s\n' "$EMPTY_PROJECTION" | grep '^ADAPTER')"

test_start "a missing record errors rather than projecting nothing"
inspect_projection "$TEST_TMPDIR/no-such-record.json" >/dev/null 2>&1
assert_equals "1" "$?"

test_summary
