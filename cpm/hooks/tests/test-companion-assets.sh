#!/bin/bash
# test-companion-assets.sh — Tests for companion-asset storage and reference, backing
# the Story 1 [integration] acceptance criteria of epic 33-02 (Companion Asset
# Generation):
#   - Generated assets land at the convention path docs/{type}/assets/{nn}-{slug}-{label}.html
#   - The relative path written into the Markdown resolves to the asset on disk
#   - Documentation diagrams consume the shared template asset
#   - Deliverable-functionality mockups are self-contained without the shared template
#
# Exercises the path/reference/template helpers added to html-test-helpers.sh:
#   check_asset_path, check_reference_resolves, check_uses_shared_template — plus the
# existing check_self_contained / check_valid_html for the two mockup kinds.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/html-test-helpers.sh"

TEMPLATE="$SCRIPT_DIR/../../assets/html/template.html"

echo "Testing: companion-asset storage and reference"
echo "=============================================="

# --- check_asset_path: convention-conforming paths --------------------------------

test_start "Conventional spec asset path passes"
check_asset_path "docs/specifications/assets/05-spec-foo-booking.html"; RC=$?
assert_equals "0" "$RC"

test_start "Conventional architecture asset path passes"
check_asset_path "docs/architecture/assets/12-adr-session-storage-flow.html"; RC=$?
assert_equals "0" "$RC"

test_start "Three-digit number (>=100) asset path passes"
check_asset_path "docs/specifications/assets/100-spec-thing-mockup.html"; RC=$?
assert_equals "0" "$RC"

# --- check_asset_path: violations -------------------------------------------------

test_start "Missing assets/ segment is flagged"
OUT=$(check_asset_path "docs/specifications/05-spec-foo-booking.html"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "BAD_ASSET_PATH"

test_start "Missing {label} (only {nn}-{slug}) is flagged"
OUT=$(check_asset_path "docs/specifications/assets/05-foo.html"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "BAD_ASSET_PATH"

test_start "Missing numeric prefix is flagged"
OUT=$(check_asset_path "docs/specifications/assets/spec-foo-booking.html"); RC=$?
assert_equals "1" "$RC"

test_start "Non-html extension is flagged"
OUT=$(check_asset_path "docs/specifications/assets/05-spec-foo-booking.md"); RC=$?
assert_equals "1" "$RC"

test_start "Path outside docs/ is flagged"
OUT=$(check_asset_path "specifications/assets/05-spec-foo-booking.html"); RC=$?
assert_equals "1" "$RC"

# --- check_reference_resolves: the Markdown->asset seam ---------------------------

# Build a realistic fixture tree:
#   docs/specifications/05-spec-foo.md  -- references assets/05-spec-foo-mockup.html
#   docs/specifications/assets/05-spec-foo-mockup.html
mkdir -p "$TEST_TMPDIR/docs/specifications/assets"
MD="$TEST_TMPDIR/docs/specifications/05-spec-foo.md"
ASSET="$TEST_TMPDIR/docs/specifications/assets/05-spec-foo-mockup.html"
cat > "$MD" <<'M'
# Spec: Foo

- The booking screen is inherently visual.
  See mockup: [booking screen](assets/05-spec-foo-mockup.html)
  Companion mockup: the multi-step flow's screen states are clearer shown than described.
M
echo '<!DOCTYPE html><html><head><style>body{}</style></head><body><h1>Mockup</h1></body></html>' > "$ASSET"

test_start "Relative reference that resolves on disk passes"
check_reference_resolves "$MD" "assets/05-spec-foo-mockup.html"; RC=$?
assert_equals "0" "$RC"

test_start "Reference present in Markdown but asset missing is flagged"
OUT=$(check_reference_resolves "$MD" "assets/05-spec-foo-missing.html"); RC=$?
assert_equals "1" "$RC"
# absent from the Markdown -> REF_ABSENT (this path was never written into the .md)
assert_contains "$OUT" "REF_ABSENT"

test_start "Reference written in Markdown but file absent on disk is flagged"
# Add a reference line whose target does not exist, then resolve it.
printf '  Orphan ref: [x](assets/05-spec-foo-orphan.html)\n' >> "$MD"
OUT=$(check_reference_resolves "$MD" "assets/05-spec-foo-orphan.html"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "REF_UNRESOLVED"

test_start "check_reference_resolves returns rc 2 for a missing Markdown file"
OUT=$(check_reference_resolves "$TEST_TMPDIR/docs/specifications/no-such.md" "assets/x.html"); RC=$?
assert_equals "2" "$RC"
assert_contains "$OUT" "FILE_NOT_FOUND"

# --- Documentation diagram: consumes the shared template --------------------------
#
# A documentation diagram that explains an artifact is produced by substituting the
# shared template's body tokens while leaving its <head> (and generator signature)
# intact. Simulate that by copying the real template and substituting CPM:CONTENT.
DOC_DIAGRAM="$TEST_TMPDIR/docs/architecture/assets/12-adr-foo-flow.html"
mkdir -p "$(dirname "$DOC_DIAGRAM")"
sed 's#<!-- CPM:CONTENT -->#<figure class="cpm-figure"><svg viewBox="0 0 10 10"><rect width="10" height="10"/></svg><figcaption>Request flow</figcaption></figure>#' \
  "$TEMPLATE" > "$DOC_DIAGRAM"

test_start "Documentation diagram consumes the shared template (bears signature)"
OUT=$(check_uses_shared_template "$DOC_DIAGRAM"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "Documentation diagram is self-contained"
OUT=$(check_self_contained "$DOC_DIAGRAM"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "Documentation diagram is valid HTML5"
OUT=$(check_valid_html "$DOC_DIAGRAM"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "Documentation diagram lands at a conventional asset path"
check_asset_path "docs/architecture/assets/12-adr-foo-flow.html"; RC=$?
assert_equals "0" "$RC"

# --- Deliverable-functionality mockup: self-contained, NOT the shared template ----
#
# A mockup previewing the UI of the system being built wears the target system's own
# design — built standalone with bespoke inline CSS, no shared-template signature —
# but is still a single self-contained file (the carve-out in the shared convention).
DELIV_MOCKUP="$TEST_TMPDIR/docs/specifications/assets/05-spec-foo-booking.html"
cat > "$DELIV_MOCKUP" <<'H'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Booking — Acme</title>
  <style>
    :root { --brand: #2b6cb0; }
    body { font-family: "Inter", system-ui, sans-serif; margin: 0; background: #fff; }
    .app-bar { background: var(--brand); color: #fff; padding: 1rem; }
    .cta { background: var(--brand); color: #fff; border: 0; padding: .75rem 1.5rem; }
  </style>
</head>
<body>
  <header class="app-bar">Acme Bookings</header>
  <main><button class="cta">Book now</button></main>
</body>
</html>
H

test_start "Deliverable mockup is self-contained"
OUT=$(check_self_contained "$DELIV_MOCKUP"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "Deliverable mockup does NOT bear the shared-template signature (carve-out)"
OUT=$(check_uses_shared_template "$DELIV_MOCKUP"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "NO_SHARED_TEMPLATE"

test_start "Deliverable mockup is valid HTML5"
OUT=$(check_valid_html "$DELIV_MOCKUP"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "Deliverable mockup lands at the same conventional asset path"
check_asset_path "docs/specifications/assets/05-spec-foo-booking.html"; RC=$?
assert_equals "0" "$RC"

test_summary
