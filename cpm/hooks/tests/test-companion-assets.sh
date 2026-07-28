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

# --- R6 carve-out: the two protected consumer sites (epic 41-04 Story 3) ----------
#
# Story 3's criteria were phrased against `git diff`, which stops meaning anything the
# moment the work is committed. These assertions make the same guarantee durable:
# they name the rules the two blocks exist to carry, so a future edit that removes or
# softens them fails here rather than passing unnoticed.
#
# The risk is specific. Spec 41 moved three outputs from repo files to published URLs;
# companion assets are the one HTML role deliberately left behind, because `cpm:do`
# opens them mid-execution and a URL would make a pipeline step depend on network
# reachability. The carve-out is a boundary in a pivot, which is exactly the kind of
# exception a later sweep "tidies up".

DO_SKILL="$SCRIPT_DIR/../../skills/do/SKILL.md"
EPICS_SKILL="$SCRIPT_DIR/../../skills/epics/SKILL.md"
CONV_FILE="$SCRIPT_DIR/../../shared/skill-conventions.md"

test_start "cpm:do still treats a companion asset as a visual design target"
# Two halves of one claim: the asset is opened as a design target, AND it is not
# parsed for requirements. Either half alone permits the wrong behaviour.
if grep -qF 'visual design target' "$DO_SKILL" \
  && grep -qF 'Do **not** parse the companion HTML to extract requirements' "$DO_SKILL"; then
  test_pass
else
  test_fail "the companion-asset awareness block lost one of its two rules"
fi

test_start "cpm:do reaches companion assets by relative path, not URL"
assert_empty "$(grep -nE 'https?://' "$DO_SKILL")"

test_start "cpm:epics still tags mockup-conformance criteria manual, never automated"
if grep -qF 'design target' "$EPICS_SKILL" \
  && grep -qF 'Never write an automated markup-parsing test' "$EPICS_SKILL"; then
  test_pass
else
  test_fail "the mockup-referencing-criteria block lost one of its two rules"
fi

# The rule covers two kinds of asset and only one of them is built. Read literally without
# this split, a data-flow diagram earns a `[manual]` visual-conformance criterion — a
# criterion with no deliverable to conform to, unverifiable in both directions.
test_start "cpm:epics distinguishes a mockup from a diagram"
if grep -qF 'A **mockup**' "$EPICS_SKILL" && grep -qF 'A **diagram**' "$EPICS_SKILL"; then
  test_pass
else
  test_fail "the companion-asset rule no longer branches on which kind of asset it is"
fi

test_start "and a diagram earns no criterion rather than a manual one"
assert_contains "$(cat "$EPICS_SKILL")" 'no criterion at all'

# The must-NOT, stated positively because a reader hitting an unreferenced diagram will
# otherwise read it as a coverage hole and add the criterion the rule above forbids.
test_start "an unreferenced diagram is named as the correct outcome, not a gap"
assert_contains "$(cat "$EPICS_SKILL")" 'not a coverage gap'

test_start "The convention still states companion assets are not published"
# The reason is asserted with the rule: a rule whose rationale is deleted is a rule
# the next sweep reads as arbitrary.
CONV_TEXT=$(cat "$CONV_FILE")
if printf '%s' "$CONV_TEXT" | grep -qF 'Companion assets stay repo files' \
  && printf '%s' "$CONV_TEXT" | grep -qF 'depend on network reachability'; then
  test_pass
else
  test_fail "the carve-out rule or its rationale is missing from the convention"
fi

test_start "The companion-asset storage path survives in the convention"
assert_contains "$CONV_TEXT" 'docs/{type}/assets/{nn}-{slug}-{label}.html'

test_summary
