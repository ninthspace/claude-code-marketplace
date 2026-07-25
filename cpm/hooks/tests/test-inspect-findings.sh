#!/bin/bash
# test-inspect-findings.sh — Tests the durable findings sidecar.
#
# The review's findings are the one output of `/cpm:inspect` that no other tool produces:
# the provenance join can be re-derived from git and the planning documents at any time, but
# a reading of the code exists only if it was written down. Until this sidecar they were
# rendered into the conversation and lost.
#
# --- What these assertions are really defending ---------------------------------------
#
# Two properties that pull against each other, which is why both are asserted against the
# same file rather than in separate suites:
#
#   * the sidecar round-trips — a page composed from it gets structure, not prose
#   * the record stays byte-identical while the sidecar changes — R6 survives the addition
#
# The second is the one worth being suspicious of. It would be satisfied trivially by a
# sidecar that never held anything, so it is asserted alongside a control that the two runs
# it compares really did produce different findings.
#
# --- What this suite does NOT test ----------------------------------------------------
#
# **Whether the findings are any good.** Nothing here reads code or judges a review. The
# suite exercises the storage: that what the review emitted is what a later reader gets back.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/git-fixture-helpers.sh"
source "$SCRIPT_DIR/../lib/changeset.sh"
source "$SCRIPT_DIR/../lib/changeset-resolve.sh"
source "$SCRIPT_DIR/../lib/review.sh"
source "$SCRIPT_DIR/../lib/inspect-record.sh"
source "$SCRIPT_DIR/../lib/inspect-findings.sh"
source "$SCRIPT_DIR/stub-link-adapter.sh"

echo "Testing the durable findings sidecar..."
echo ""

TAB=$(printf '\t')
SELECTOR="--since HEAD~1"

REPO=$(git_fixture_create findings)
git_fixture_commit "$REPO" "chore: seed" -- README.md "seed"
git_fixture_commit "$REPO" "feat: work" -- src/a.sh "a" "src/odd:name.sh" "b"

emit_two() {
  review_emit_finding "src/a.sh" "12" "the retry loop swallows the error it should report"
  review_emit_finding "src/odd:name.sh" "3" "duplicated parsing — see src/a.sh"
}

# --- Round-trip ---------------------------------------------------------------------------

test_start "writing findings prints the sidecar path, beside the record"
SIDECAR=$(emit_two | inspect_findings_write "$REPO" "$SELECTOR")
assert_equals "docs/inspect/$(inspect_slug "$SELECTOR").findings.md" "$SIDECAR"

test_start "the file is actually on disk"
assert_equals "yes" "$([ -f "$REPO/$SIDECAR" ] && echo yes)"

test_start "what the review emitted is what a later reader gets back, record for record"
assert_equals "$(emit_two)" "$(inspect_findings_read "$REPO/$SIDECAR")"

# The citation is two fields for a reason `review.sh` states, and a path containing a colon
# is the case that reason names. Asserted on its own, because the round-trip above would
# still pass if the colon path were dropped entirely and only the clean one survived.
test_start "a path containing a colon survives the round-trip intact"
assert_equals "src/odd:name.sh" \
  "$(inspect_findings_read "$REPO/$SIDECAR" | awk -F'\t' 'NR == 2 { print $2 }')"

test_start "and its line number is not absorbed into the path"
assert_equals "3" "$(inspect_findings_read "$REPO/$SIDECAR" | awk -F'\t' 'NR == 2 { print $3 }')"

# Its own selector, so it writes its own file. One file per selector overwritten in place is
# the intended behaviour — asserted below — which makes reusing a selector here a way to
# quietly destroy the fixture the assertions above depend on.
test_start "finding text containing the field separator is not truncated at it"
SEP_SIDECAR=$(review_emit_finding "src/a.sh" "1" "reads as done — but the flag — is never set" \
  | inspect_findings_write "$REPO" "main")
assert_equals "reads as done — but the flag — is never set" \
  "$(inspect_findings_read "$REPO/$SEP_SIDECAR" | awk -F'\t' '{ print $4 }')"

test_start "the sidecar is human-readable — it names the file and the line in prose"
assert_contains "$(cat "$REPO/$SIDECAR")" 'line 12'

test_start "and it points back at the record it belongs to"
assert_contains "$(cat "$REPO/$SIDECAR")" "docs/inspect/$(inspect_slug "$SELECTOR").json"

# --- Prose is not data ----------------------------------------------------------------------

test_start "a bulleted line that is not a finding is not read back as one"
printf '# Notes\n\n- a plain bullet about something else\n- **`src/a.sh`** but no line number\n' \
  > "$REPO/docs/inspect/prose.findings.md"
assert_empty "$(inspect_findings_read "$REPO/docs/inspect/prose.findings.md")"

test_start "the control: the same reader does return records from a real sidecar"
assert_equals "2" "$(inspect_findings_read "$REPO/$SIDECAR" | grep -c '^FINDING')"

# --- Nothing found is not the same as not reviewed --------------------------------------------

test_start "a review that found nothing still writes a file"
EMPTY_SIDECAR=$(printf '' | inspect_findings_write "$REPO" "--working-tree")
assert_equals "yes" "$([ -f "$REPO/$EMPTY_SIDECAR" ] && echo yes)"

test_start "which says so in words rather than being an empty file"
assert_contains "$(cat "$REPO/$EMPTY_SIDECAR")" "No findings"

test_start "and reads back as no findings at all"
assert_empty "$(inspect_findings_read "$REPO/$EMPTY_SIDECAR")"

test_start "a selector never reviewed leaves no file, which is the distinction"
assert_empty "$(ls "$REPO/docs/inspect/"*never-reviewed* 2>/dev/null)"

# --- R6 survives the addition ------------------------------------------------------------------
#
# The findings had to go somewhere other than the record, and this is the assertion that says
# why. Two runs over an identical tree, differing only in what the review concluded.

CHANGESET="$TEST_TMPDIR/changeset"
changeset_resolve_git "$REPO" --since HEAD~1 > "$CHANGESET"
LINKSET="$TEST_TMPDIR/linkset"
linkset_reset
linkset_register stub
linkset_join "$REPO" "$CHANGESET" > "$LINKSET"

RECORD_A=$(inspect_write "$REPO" "$CHANGESET" "$SELECTOR" < "$LINKSET")
HASH_A=$(cksum < "$REPO/$RECORD_A")
emit_two | inspect_findings_write "$REPO" "$SELECTOR" >/dev/null
FINDINGS_A=$(cksum < "$REPO/$SIDECAR")

RECORD_B=$(inspect_write "$REPO" "$CHANGESET" "$SELECTOR" < "$LINKSET")
HASH_B=$(cksum < "$REPO/$RECORD_B")
review_emit_finding "src/a.sh" "99" "a different reading of the same code" \
  | inspect_findings_write "$REPO" "$SELECTOR" >/dev/null
FINDINGS_B=$(cksum < "$REPO/$SIDECAR")

test_start "the record is byte-identical across the two runs — R6 holds"
assert_equals "$HASH_A" "$HASH_B"

test_start "the control: the findings genuinely differed between them"
if [ "$FINDINGS_A" = "$FINDINGS_B" ]; then
  test_fail "Both sidecars hashed the same, so R6 above was not actually under any pressure"
else
  test_pass
fi

test_start "and both runs wrote to the same two paths, so neither accumulates copies"
assert_equals "$RECORD_A" "$RECORD_B"

# --- Refusals ------------------------------------------------------------------------------------

test_start "a missing repository is refused rather than written somewhere else"
printf '' | inspect_findings_write "$TEST_TMPDIR/no-such-repo" "$SELECTOR" >/dev/null 2>&1
assert_equals "1" "$?"

test_start "an empty selector is refused — the slug is the identity and cannot be guessed"
printf '' | inspect_findings_write "$REPO" "" >/dev/null 2>&1
assert_equals "1" "$?"

test_start "reading a file that does not exist errors rather than returning nothing"
inspect_findings_read "$TEST_TMPDIR/absent.md" >/dev/null 2>&1
assert_equals "1" "$?"

test_start "the sidecar path is derived from the selector, not accepted from a caller"
assert_equals "$(inspect_findings_path "$(inspect_slug "$SELECTOR")")" "$SIDECAR"

test_summary
