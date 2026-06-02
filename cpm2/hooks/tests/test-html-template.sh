#!/bin/bash
# test-html-template.sh — Tests for the shared HTML template asset
# (cpm2/assets/html/template.html) and the check_valid_html validity check in
# html-test-helpers.sh. These back the Story 2 [integration] acceptance criteria:
# the asset exists, is valid self-contained HTML, and requires no external resource.
#
# Tests cover:
# - The real shared template asset exists, is valid HTML, and is self-contained
# - The template carries the placeholder tokens consumers substitute (the contract)
# - check_valid_html passes a well-formed doc and flags missing structural elements
# - check_valid_html returns 2 for a missing file

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/html-test-helpers.sh"

TEMPLATE="$SCRIPT_DIR/../../assets/html/template.html"

echo "Testing: shared HTML template asset + check_valid_html"
echo "======================================================"

# --- The real shared template asset ---

test_start "Shared template asset exists"
if [ -f "$TEMPLATE" ]; then test_pass; else test_fail "Not found: $TEMPLATE"; fi

test_start "Shared template asset is self-contained (no external refs)"
OUT=$(check_self_contained "$TEMPLATE"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "Shared template asset is valid HTML5"
OUT=$(check_valid_html "$TEMPLATE"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "Shared template asset declares no JavaScript (Tier 1 static)"
# Self-contained Tier-1 output is static — there must be no <script> element.
SCRIPTS=$(grep -icE '<script' "$TEMPLATE")
assert_equals "0" "$SCRIPTS"

test_start "Shared template asset carries all placeholder tokens"
for token in \
  '<!-- CPM:TITLE -->' \
  '<!-- CPM:SUBTITLE -->' \
  '<!-- CPM:META -->' \
  '<!-- CPM:NAV -->' \
  '<!-- CPM:CONTENT -->' \
  '<!-- CPM:FOOTER -->'; do
  assert_contains "$(cat "$TEMPLATE")" "$token"
done

# --- check_valid_html unit fixtures ---

test_start "check_valid_html passes a well-formed document"
F="$TEST_TMPDIR/valid.html"
cat > "$F" <<'H'
<!DOCTYPE html><html lang="en"><head><style>body{}</style></head><body><p>Hi</p></body></html>
H
OUT=$(check_valid_html "$F"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "check_valid_html flags a missing <body>"
F="$TEST_TMPDIR/nobody.html"
echo '<!DOCTYPE html><html><head><style>body{}</style></head></html>' > "$F"
OUT=$(check_valid_html "$F"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "MISSING <body>"

test_start "check_valid_html flags a missing inline <style>"
F="$TEST_TMPDIR/nostyle.html"
echo '<!DOCTYPE html><html><head></head><body></body></html>' > "$F"
OUT=$(check_valid_html "$F"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "MISSING inline <style>"

test_start "check_valid_html flags a missing doctype"
F="$TEST_TMPDIR/nodoctype.html"
echo '<html><head><style>body{}</style></head><body></body></html>' > "$F"
OUT=$(check_valid_html "$F"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "MISSING doctype"

test_start "check_valid_html returns rc 2 for a missing file"
OUT=$(check_valid_html "$TEST_TMPDIR/no-such-file.html"); RC=$?
assert_equals "2" "$RC"
assert_contains "$OUT" "FILE_NOT_FOUND"

test_summary
