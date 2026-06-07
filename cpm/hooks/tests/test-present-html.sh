#!/bin/bash
# test-present-html.sh — Tests for cpm:present's HTML output, backing the Story 1
# [integration] acceptance criteria of epic 33-04 (present HTML Output):
#   - present HTML output is self-contained and uses the shared template, not a fork
#   - present HTML output is written alongside its Markdown output in docs/communications/
#
# Exercises check_communication_path (added to html-test-helpers.sh) plus the existing
# check_uses_shared_template / check_self_contained / check_valid_html checks.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/html-test-helpers.sh"

TEMPLATE="$SCRIPT_DIR/../../assets/html/template.html"

echo "Testing: present HTML output"
echo "============================"

# --- check_communication_path: convention-conforming paths ------------------------

test_start "Conventional summary-memo communication path passes"
check_communication_path "docs/communications/03-summary-memo-q1-progress.html"; RC=$?
assert_equals "0" "$RC"

test_start "Conventional onboarding-guide communication path passes"
check_communication_path "docs/communications/11-onboarding-guide-auth-system.html"; RC=$?
assert_equals "0" "$RC"

test_start "Three-digit number (>=100) communication path passes"
check_communication_path "docs/communications/100-changelog-release.html"; RC=$?
assert_equals "0" "$RC"

# --- check_communication_path: violations -----------------------------------------

test_start "Missing {slug} (only {nn}-{format}) is flagged"
OUT=$(check_communication_path "docs/communications/03-changelog.html"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "BAD_COMMUNICATION_PATH"

test_start "Wrong directory (not communications/) is flagged"
OUT=$(check_communication_path "docs/specifications/03-summary-memo-q1.html"); RC=$?
assert_equals "1" "$RC"

test_start "Nested html/ subdir is flagged (communications dir is flat)"
OUT=$(check_communication_path "docs/communications/html/03-summary-memo-q1.html"); RC=$?
assert_equals "1" "$RC"

test_start "Missing numeric prefix is flagged"
OUT=$(check_communication_path "docs/communications/summary-memo-q1.html"); RC=$?
assert_equals "1" "$RC"

test_start "Non-html extension is flagged"
OUT=$(check_communication_path "docs/communications/03-summary-memo-q1.md"); RC=$?
assert_equals "1" "$RC"

# --- present HTML generated from the shared template ------------------------------
#
# present HTML reframes the communication using the shared chrome: substitute the body
# tokens, leave the <head> (and generator signature) intact. Simulate by copying the
# real template and substituting CPM:CONTENT with a memo body.
COMMS_DIR="$TEST_TMPDIR/docs/communications"
mkdir -p "$COMMS_DIR"
MD="$COMMS_DIR/03-summary-memo-q1-progress.md"
HTML="$COMMS_DIR/03-summary-memo-q1-progress.html"
cat > "$MD" <<'M'
# Q1 Progress — Executive Summary

**Audience**: Executives
**Format**: Summary memo
**Source artifacts**:
- docs/epics/01-epic-foo.md

---

Delivery is on track.
M
sed 's#<!-- CPM:CONTENT -->#<div class="cpm-memo"><p>Delivery is on track.</p></div>#' \
  "$TEMPLATE" > "$HTML"

test_start "present HTML consumes the shared template (bears signature)"
OUT=$(check_uses_shared_template "$HTML"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "present HTML is self-contained (no external refs)"
OUT=$(check_self_contained "$HTML"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "present HTML is valid HTML5"
OUT=$(check_valid_html "$HTML"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "present HTML lands at a conventional communication path"
check_communication_path "docs/communications/03-summary-memo-q1-progress.html"; RC=$?
assert_equals "0" "$RC"

test_start "present HTML sits alongside its Markdown (same dir + stem)"
# Both files share the directory and the {nn}-{format}-{slug} stem, differing only in extension.
assert_equals "${MD%.md}.html" "$HTML"
test_start "Both the Markdown and HTML communication files exist side by side"
if [ -f "$MD" ] && [ -f "$HTML" ]; then test_pass; else test_fail "Expected both $MD and $HTML"; fi

test_summary
