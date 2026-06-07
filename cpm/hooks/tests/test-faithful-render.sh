#!/bin/bash
# test-faithful-render.sh — Tests for faithful artifact render, backing the Story 1
# [integration] acceptance criteria of epic 33-03 (Faithful Artifact Render):
#   - The render is written to docs/{type}/html/{nn}-{slug}.html and consumes the shared
#     template, not a forked stylesheet
#   - A render must NOT modify or replace the source Markdown file
#   - The render is self-contained — a single file with no external CSS/JS/image refs
#
# Exercises check_render_path (added to html-test-helpers.sh) plus the existing
# check_uses_shared_template / check_self_contained / check_valid_html and the
# md_content_hash / check_source_unchanged immutability pair.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/html-test-helpers.sh"

TEMPLATE="$SCRIPT_DIR/../../assets/html/template.html"

echo "Testing: faithful artifact render"
echo "================================="

# --- check_render_path: convention-conforming paths -------------------------------

test_start "Conventional spec render path passes"
check_render_path "docs/specifications/html/05-spec-foo.html"; RC=$?
assert_equals "0" "$RC"

test_start "Conventional architecture render path passes"
check_render_path "docs/architecture/html/12-session-storage.html"; RC=$?
assert_equals "0" "$RC"

test_start "Conventional review render path passes"
check_render_path "docs/reviews/html/03-auth-s2.html"; RC=$?
assert_equals "0" "$RC"

test_start "Three-digit number (>=100) render path passes"
check_render_path "docs/specifications/html/100-thing.html"; RC=$?
assert_equals "0" "$RC"

# --- check_render_path: violations ------------------------------------------------

test_start "Render path under assets/ (companion-asset dir) is flagged"
OUT=$(check_render_path "docs/specifications/assets/05-spec-foo.html"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "BAD_RENDER_PATH"

test_start "Render path without html/ segment is flagged"
OUT=$(check_render_path "docs/specifications/05-spec-foo.html"); RC=$?
assert_equals "1" "$RC"

test_start "Render path missing numeric prefix is flagged"
OUT=$(check_render_path "docs/specifications/html/spec-foo.html"); RC=$?
assert_equals "1" "$RC"

test_start "Render path with non-html extension is flagged"
OUT=$(check_render_path "docs/specifications/html/05-spec-foo.md"); RC=$?
assert_equals "1" "$RC"

# --- A render generated from the shared template ----------------------------------
#
# A faithful render substitutes the shared template's body tokens while leaving its
# <head> (and generator signature) intact. Simulate that by copying the real template
# and substituting CPM:CONTENT with rendered spec prose.
RENDER="$TEST_TMPDIR/docs/specifications/html/05-spec-foo.html"
mkdir -p "$(dirname "$RENDER")"
sed 's#<!-- CPM:CONTENT -->#<h2>Problem Summary</h2><p>Rendered from Markdown.</p><table><tr><td>x</td></tr></table>#' \
  "$TEMPLATE" > "$RENDER"

test_start "Render consumes the shared template (bears signature)"
OUT=$(check_uses_shared_template "$RENDER"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "Render is self-contained (no external refs)"
OUT=$(check_self_contained "$RENDER"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "Render is valid HTML5"
OUT=$(check_valid_html "$RENDER"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "Render lands at a conventional render path"
check_render_path "docs/specifications/html/05-spec-foo.html"; RC=$?
assert_equals "0" "$RC"

# --- Source immutability: generate-from-source, never replace ---------------------
#
# A render reads the source Markdown but must never mutate or replace it. Hash the
# source before "rendering", perform a read-only generation step (write HTML only),
# then confirm the source hash is unchanged.
SRC="$TEST_TMPDIR/docs/specifications/05-spec-foo.md"
cat > "$SRC" <<'M'
# Spec: Foo

## Problem Summary
The source of truth stays in Markdown.
M

test_start "Source hash is unchanged after a read-only render step"
BEFORE=$(md_content_hash "$SRC")
# Read-only render: write to the HTML path, leave the source untouched.
sed 's#<!-- CPM:CONTENT -->#<h2>Problem Summary</h2>#' "$TEMPLATE" > "$RENDER"
check_source_unchanged "$SRC" "$BEFORE"; RC=$?
assert_equals "0" "$RC"

test_start "A mutated source is detected (negative control)"
BEFORE=$(md_content_hash "$SRC")
printf '\nAccidentally appended line.\n' >> "$SRC"
OUT=$(check_source_unchanged "$SRC" "$BEFORE"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "SOURCE_MODIFIED"

# --- Regeneration in place (epic 33-03 Story 2) -----------------------------------
#
# Re-rendering after the source changes must update the existing HTML view rather than
# spawning a duplicate. The mechanism is a deterministic render path: docs/{type}/html/
# {nn}-{slug}.html, derived purely from the source's {nn}/{slug} (the {kind} infix —
# spec/adr/review — is dropped). A content edit does not change {nn}/{slug}, so the
# path is stable across re-renders and the second render overwrites the first.
#
# render_path_for models that mapping (the contract the skills follow):
#   docs/specifications/05-spec-foo.md -> docs/specifications/html/05-foo.html
render_path_for() {
  local src="$1" dir stem nn rest slug
  dir=$(dirname "$src")
  stem=$(basename "$src" .md)
  nn=${stem%%-*}        # leading number
  rest=${stem#*-}       # {kind}-{slug...}
  slug=${rest#*-}       # {slug...} (drop the kind infix; idempotent if absent)
  echo "$dir/html/$nn-$slug.html"
}

REGEN_DIR="$TEST_TMPDIR/regen/docs/specifications"
mkdir -p "$REGEN_DIR/html"
REGEN_SRC="$REGEN_DIR/07-spec-bar.md"
printf '# Spec: Bar\n\n## Problem Summary\nFirst version.\n' > "$REGEN_SRC"

test_start "Render path is a deterministic function of the source ({kind} dropped)"
P1=$(render_path_for "$REGEN_SRC")
assert_equals "$REGEN_DIR/html/07-bar.html" "$P1"

test_start "Path is stable across a source content change (same {nn}/{slug})"
# First render.
sed "s#<!-- CPM:CONTENT -->#<h2>Problem Summary</h2><p>First version.</p>#" "$TEMPLATE" > "$P1"
# Source content changes — but {nn}/{slug} (and therefore the path) do not.
printf '# Spec: Bar\n\n## Problem Summary\nSecond version, expanded.\n' > "$REGEN_SRC"
P2=$(render_path_for "$REGEN_SRC")
assert_equals "$P1" "$P2"

test_start "Re-render overwrites in place — exactly one HTML file, no duplicate"
sed "s#<!-- CPM:CONTENT -->#<h2>Problem Summary</h2><p>Second version, expanded.</p>#" "$TEMPLATE" > "$P2"
COUNT=$(find "$REGEN_DIR/html" -maxdepth 1 -name '*.html' | wc -l | tr -d ' ')
assert_equals "1" "$COUNT"

test_start "Re-rendered file carries the updated content, not the stale render"
assert_contains "$(cat "$P2")" "Second version, expanded."

test_start "Re-rendered file no longer carries the first-version content"
assert_not_contains "$(cat "$P2")" "First version."

test_summary
