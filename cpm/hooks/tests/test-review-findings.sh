#!/bin/bash
# test-review-findings.sh — Tests the review's two deterministic edges.
#
# These back Epic 42-04 Story 1's acceptance criteria (spec 42 R5, AD3).
#
# --- What this suite does NOT test --------------------------------------------------------
#
# **Whether a finding is correct, useful, or worth acting on.** There is no oracle for that,
# and none is attempted here. Every assertion below is structural: that a finding carries a
# citation, that the citation names a file in the change set, that the payload handed to the
# review contains the join's data and none of its confidence labels.
#
# A green run therefore means the review was well *formed*. It does not mean it was any
# good, and the 42-04 coverage matrix records the same gap at row level: "R5's usefulness is
# not covered by any row, and that is a known gap." Retro 17 is the reason this paragraph
# exists — a suite reporting a screen of green assertions reads like it verified the story,
# and the only defence is for the suite to say plainly what it left alone.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/git-fixture-helpers.sh"
source "$SCRIPT_DIR/../lib/changeset.sh"
source "$SCRIPT_DIR/../lib/changeset-resolve.sh"
source "$SCRIPT_DIR/../lib/linkset.sh"
source "$SCRIPT_DIR/../lib/linkset-join.sh"
source "$SCRIPT_DIR/../lib/review.sh"
source "$SCRIPT_DIR/stub-link-adapter.sh"

echo "Testing the change-set review's deterministic edges..."
echo ""

TAB="$REVIEW_TAB"

# --- Fixture -----------------------------------------------------------------------------

REPO=$(git_fixture_create review)
git_fixture_commit "$REPO" "chore: seed" -- README.md "seed"
BASE=$(git_fixture_git "$REPO" rev-parse HEAD)
git_fixture_commit "$REPO" "feat: three files" -- \
  src/a.sh "a" src/b.sh "b" src/lonely.sh "lonely"

CHANGESET="$TEST_TMPDIR/changeset"
changeset_resolve_git "$REPO" --since "$BASE" > "$CHANGESET"
CHANGED_FILES=$(changeset_files < "$CHANGESET")

# `src/a.sh` carries both confidences so the payload has something to strip; `src/lonely.sh`
# carries none so the payload has an absence to express without naming it.
stub_link_records \
  "INTENT${TAB}epic 42-04${TAB}done${TAB}Change-Set Review" \
  "CRITERION${TAB}epic 42-04${TAB}verified${TAB}Findings carry file:line citations" \
  "CRITERION${TAB}epic 42-04${TAB}unverified${TAB}The review discloses what it skipped" \
  "LINK${TAB}src/a.sh${TAB}epic 42-04${TAB}declared" \
  "LINK${TAB}src/b.sh${TAB}epic 42-04${TAB}derived"
stub2_link_records \
  "INTENT${TAB}AUTH-4${TAB}open${TAB}Ticket four" \
  "LINK${TAB}src/a.sh${TAB}AUTH-4${TAB}derived"

linkset_reset
linkset_register stub
linkset_register stub2
JOINED=$(linkset_join "$REPO" "$CHANGESET")
PAYLOAD=$(printf '%s\n' "$JOINED" | review_payload "$CHANGESET")

# --- Criterion: the review consumes the join's data, never its confidence labels -----------

# The control for every absence assertion below. If the join produced no confidences, the
# payload containing none would prove nothing at all.
test_start "the join really does carry confidence labels for the payload to drop"
assert_equals "declared derived" "$(printf '%s\n' "$JOINED" | linkset_links | cut -f3 | LC_ALL=C sort -u | tr '\n' ' ' | sed 's/ $//')"

# Every word of the forbidden vocabulary, from the variable the payload builder itself uses,
# so the test and the code cannot drift apart by someone editing one list.
test_start "no confidence label of any kind appears anywhere in the payload"
FOUND_LABELS=""
for label in $REVIEW_FORBIDDEN_LABELS; do
  if printf '%s\n' "$PAYLOAD" | LC_ALL=C grep -qw "$label"; then
    FOUND_LABELS="$FOUND_LABELS $label"
  fi
done
assert_empty "$FOUND_LABELS"

test_start "the vocabulary being policed is the full one AD3 names"
assert_equals "declared derived absent" "$REVIEW_FORBIDDEN_LABELS"

# The links themselves must survive — stripping the labels by dropping the data would
# satisfy every assertion above and defeat the point.
test_start "the links themselves reach the review, carrying file and intent"
assert_equals "src/a.sh${TAB}AUTH-4
src/a.sh${TAB}epic 42-04
src/b.sh${TAB}epic 42-04" \
  "$(printf '%s\n' "$PAYLOAD" | awk -F'\t' '$1 == "FILEINTENT" { print $2 "\t" $3 }' | LC_ALL=C sort)"

# A rebuilt record rather than a reprinted one: a LINK gaining a fifth field later must not
# reach the review through a path nobody looked at again.
test_start "a link record carrying an extra field cannot smuggle it through"
SMUGGLE=$(printf 'LINK\tsrc/a.sh\tepic 42-04\tdeclared\tsecret-label\n' | review_payload "$CHANGESET")
assert_empty "$(printf '%s\n' "$SMUGGLE" | grep -F 'secret-label')"

# The distinction the header calls easy to get wrong. `verified` is the plan's claim about
# itself, not the join's assessment of how well it knows something, and stripping it would
# take away exactly what the review needs.
test_start "a criterion's verified state is not a confidence label and survives"
assert_equals "epic 42-04${TAB}unverified${TAB}The review discloses what it skipped
epic 42-04${TAB}verified${TAB}Findings carry file:line citations" \
  "$(printf '%s\n' "$PAYLOAD" | awk -F'\t' '$1 == "CRITERION" { print $2 "\t" $3 "\t" $4 }' | LC_ALL=C sort)"

test_start "intent status and title reach the review intact"
assert_equals "AUTH-4${TAB}open${TAB}Ticket four
epic 42-04${TAB}done${TAB}Change-Set Review" \
  "$(printf '%s\n' "$PAYLOAD" | awk -F'\t' '$1 == "INTENT" { print $2 "\t" $3 "\t" $4 }' | LC_ALL=C sort)"

# A file nothing resolved appears with no FILEINTENT line. The review infers the absence
# from the data rather than being handed the join's word for it.
test_start "a file nothing resolved is present with no intent, rather than labelled absent"
assert_equals "present|0" \
  "$(printf '%s\n' "$PAYLOAD" | grep -qF "FILE${TAB}src/lonely.sh" && echo present)|$(printf '%s\n' "$PAYLOAD" | awk -F'\t' '$1 == "FILEINTENT" && $2 == "src/lonely.sh"' | wc -l | tr -d ' ')"

test_start "every file in the change set reaches the review"
assert_equals "$CHANGED_FILES" "$(printf '%s\n' "$PAYLOAD" | awk -F'\t' '$1 == "FILE" { print $2 }')"

# --- Criterion: findings carry file:line citations -------------------------------------------

FINDINGS=$(
  review_emit_finding "src/a.sh" "12" "duplicated parsing that src/b.sh already does"
  review_emit_finding "src/b.sh" "3" "unchecked exit status"
)

test_start "a well-formed finding validates"
printf '%s\n' "$FINDINGS" | review_validate_findings "$CHANGESET" >/dev/null 2>&1
assert_equals "0" "$?"

test_start "findings render as file:line followed by the text"
assert_equals "src/a.sh:12  duplicated parsing that src/b.sh already does
src/b.sh:3  unchecked exit status" "$(printf '%s\n' "$FINDINGS" | review_render_findings)"

# Each rule gets its own case, and each case asserts the *diagnostic*, not merely that
# something was rejected. A validator that rejected everything would pass a suite that only
# checked exit codes.
test_start "a finding with no line number is rejected, and says so"
assert_equals "FINDING WITH NO USABLE LINE NUMBER (): src/a.sh" \
  "$(printf 'FINDING\tsrc/a.sh\t\tsomething\n' | review_validate_findings "$CHANGESET")"

test_start "a finding with a non-numeric line is rejected"
assert_equals "FINDING WITH NO USABLE LINE NUMBER (top): src/a.sh" \
  "$(printf 'FINDING\tsrc/a.sh\ttop\tsomething\n' | review_validate_findings "$CHANGESET")"

test_start "a finding citing line zero is rejected, since files start at line one"
assert_equals "FINDING WITH NO USABLE LINE NUMBER (0): src/a.sh" \
  "$(printf 'FINDING\tsrc/a.sh\t0\tsomething\n' | review_validate_findings "$CHANGESET")"

test_start "a finding with no file is rejected"
assert_equals "FINDING WITH NO FILE: FINDING${TAB}${TAB}12${TAB}something" \
  "$(printf 'FINDING\t\t12\tsomething\n' | review_validate_findings "$CHANGESET")"

test_start "a finding with no text is rejected, since a citation alone says nothing"
assert_equals "FINDING WITH NO TEXT: src/a.sh:12" \
  "$(printf 'FINDING\tsrc/a.sh\t12\t\n' | review_validate_findings "$CHANGESET")"

# The arity branch, which no criterion asks for. A finding whose text contains a tab splits
# into five fields, and without this check it would validate with the text silently
# truncated at the tab — a citation attached to half a sentence.
test_start "a finding whose text contains a tab is rejected rather than silently truncated"
assert_equals "FINDING NEEDS path, line AND text: FINDING${TAB}src/a.sh${TAB}12${TAB}two${TAB}parts" \
  "$(printf 'FINDING\tsrc/a.sh\t12\ttwo\tparts\n' | review_validate_findings "$CHANGESET")"

test_start "a finding missing a field entirely is rejected"
assert_equals "FINDING NEEDS path, line AND text: FINDING${TAB}src/a.sh${TAB}12" \
  "$(printf 'FINDING\tsrc/a.sh\t12\n' | review_validate_findings "$CHANGESET")"

test_start "a record that is not a finding at all is rejected"
assert_equals "NOT A FINDING RECORD: NOTE${TAB}src/a.sh${TAB}12${TAB}something" \
  "$(printf 'NOTE\tsrc/a.sh\t12\tsomething\n' | review_validate_findings "$CHANGESET")"

# R1's scoping, made enforceable. This is the rule that keeps a change-set review from
# quietly becoming the whole-codebase audit CPM already has.
test_start "a finding citing a file outside the change set is rejected"
assert_equals "FINDING CITES A FILE OUTSIDE THE CHANGE SET: src/elsewhere.sh:9" \
  "$(printf 'FINDING\tsrc/elsewhere.sh\t9\tsomething\n' | review_validate_findings "$CHANGESET")"

# The control for the rule above: the same validator, the same change set, a file that is
# in it. Without this, "rejects out-of-scope files" is equally explained by a validator
# that rejects every file.
test_start "a file that is in the change set is not rejected as out of scope"
assert_empty "$(printf 'FINDING\tsrc/a.sh\t9\tsomething\n' | review_validate_findings "$CHANGESET")"

test_start "every malformed finding is reported, not just the first"
assert_equals "3" "$(printf 'FINDING\tsrc/a.sh\tx\tone\nFINDING\t\t2\ttwo\nFINDING\tsrc/gone.sh\t3\tthree\n' \
  | review_validate_findings "$CHANGESET" | wc -l | tr -d ' ')"

# A review that found nothing is a legitimate outcome and must not look like a broken one.
test_start "an empty findings list validates rather than erroring"
printf '' | review_validate_findings "$CHANGESET" >/dev/null 2>&1
assert_equals "0" "$?"

test_start "a missing change set errors rather than validating everything"
printf '%s\n' "$FINDINGS" | review_validate_findings "$TEST_TMPDIR/no-such-changeset" >/dev/null 2>&1
assert_equals "1" "$?"

test_summary
