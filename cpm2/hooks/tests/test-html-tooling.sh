#!/bin/bash
# test-html-tooling.sh — Tests for the shared HTML validation checks in
# html-test-helpers.sh: the self-containment validator and the source-immutability
# check. These back the [integration] acceptance criteria for HTML output across the
# projection epics (33-02/03/04).
#
# Tests cover:
# - check_self_contained passes a clean inlined document
# - check_self_contained flags each external reference kind (script/link/img/url/@import)
# - data: URIs and #fragments and <a href> hyperlinks are NOT flagged
# - check_self_contained returns 2 for a missing file
# - md_content_hash / check_source_unchanged detect a mutated source vs an untouched one
# - a read-only generation step leaves the source hash unchanged

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/html-test-helpers.sh"

echo "Testing: shared HTML validation checks (html-test-helpers.sh)"
echo "============================================================"

# --- Self-containment validator: clean input ---

test_start "Self-contained document passes (rc 0, no output)"
F="$TEST_TMPDIR/clean.html"
cat > "$F" <<'H'
<!DOCTYPE html><html><head>
<style>body{font-family:sans-serif;background:url(data:image/png;base64,AAAA)}</style>
</head><body>
<h1>Title</h1>
<a href="https://example.com">external link is fine</a>
<a href="#section">fragment is fine</a>
<img src="data:image/gif;base64,R0lGODlhAQABAAAAACw=">
</body></html>
H
OUT=$(check_self_contained "$F"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

# --- Self-containment validator: each external reference kind ---

test_start "External <script src> is flagged"
F="$TEST_TMPDIR/ext-script.html"
echo '<html><head><script src="app.js"></script></head><body></body></html>' > "$F"
OUT=$(check_self_contained "$F"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "EXTERNAL script: app.js"

test_start "External <link href> stylesheet is flagged"
F="$TEST_TMPDIR/ext-link.html"
echo '<html><head><link rel="stylesheet" href="https://cdn.example.com/x.css"></head><body></body></html>' > "$F"
OUT=$(check_self_contained "$F"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "EXTERNAL link: https://cdn.example.com/x.css"

test_start "External <img src> is flagged"
F="$TEST_TMPDIR/ext-img.html"
echo '<html><body><img src="/images/logo.png"></body></html>' > "$F"
OUT=$(check_self_contained "$F"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "EXTERNAL img: /images/logo.png"

test_start "External CSS url(...) is flagged"
F="$TEST_TMPDIR/ext-url.html"
echo '<html><head><style>.x{background:url("bg.png")}</style></head><body></body></html>' > "$F"
OUT=$(check_self_contained "$F"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "EXTERNAL css-url: bg.png"

test_start "External @import is flagged"
F="$TEST_TMPDIR/ext-import.html"
echo '<html><head><style>@import "theme.css";</style></head><body></body></html>' > "$F"
OUT=$(check_self_contained "$F"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "EXTERNAL import: theme.css"

test_start "Multiple external references are all reported"
F="$TEST_TMPDIR/ext-multi.html"
cat > "$F" <<'H'
<html><head>
<link rel="stylesheet" href="style.css">
<script src="app.js"></script>
</head><body><img src="pic.jpg"></body></html>
H
OUT=$(check_self_contained "$F"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "EXTERNAL link: style.css"
assert_contains "$OUT" "EXTERNAL script: app.js"
assert_contains "$OUT" "EXTERNAL img: pic.jpg"

# --- Self-containment validator: allowances ---

test_start "data: URI script is not flagged"
F="$TEST_TMPDIR/data-script.html"
echo '<html><head><script src="data:text/javascript;base64,YWxlcnQoMSk="></script></head><body></body></html>' > "$F"
OUT=$(check_self_contained "$F"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "Hyperlinks (<a href>) are not flagged"
F="$TEST_TMPDIR/anchor.html"
echo '<html><body><a href="https://example.com/page">read more</a><a href="report.md">source</a></body></html>' > "$F"
OUT=$(check_self_contained "$F"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

# --- Self-containment validator: missing file ---

test_start "Missing file returns rc 2"
OUT=$(check_self_contained "$TEST_TMPDIR/does-not-exist.html"); RC=$?
assert_equals "2" "$RC"
assert_contains "$OUT" "FILE_NOT_FOUND"

# --- Source-immutability check ---

test_start "Unchanged source after a read-only generation step (rc 0)"
SRC="$TEST_TMPDIR/spec.md"
printf '# Spec\n\nRequirements here.\n' > "$SRC"
BEFORE=$(md_content_hash "$SRC")
# Simulate a generation step: read the source, write an HTML output elsewhere,
# never touch the source.
RENDER="$TEST_TMPDIR/spec.html"
{ echo "<html><body>"; cat "$SRC"; echo "</body></html>"; } > "$RENDER"
OUT=$(check_source_unchanged "$SRC" "$BEFORE"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "Mutated source is detected (rc 1)"
SRC="$TEST_TMPDIR/spec2.md"
printf '# Spec\n\nOriginal.\n' > "$SRC"
BEFORE=$(md_content_hash "$SRC")
printf '# Spec\n\nReplaced by a generation step (bug).\n' > "$SRC"
OUT=$(check_source_unchanged "$SRC" "$BEFORE"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "SOURCE_MODIFIED"

test_start "Identical content yields identical hash"
A="$TEST_TMPDIR/a.md"; B="$TEST_TMPDIR/b.md"
printf 'same bytes\n' > "$A"; printf 'same bytes\n' > "$B"
assert_equals "$(md_content_hash "$A")" "$(md_content_hash "$B")"

test_start "md_content_hash on missing file returns rc 2"
OUT=$(md_content_hash "$TEST_TMPDIR/nope.md"); RC=$?
assert_equals "2" "$RC"
assert_contains "$OUT" "FILE_NOT_FOUND"

test_summary
