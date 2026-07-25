#!/bin/bash
# test-faithful-render-retired.sh — Tests that the faithful-render mechanism is gone
# from the skill surface, and that the companion-asset carve-out survived the deletion.
#
# These back Epic 41-04 Story 1's [integration] acceptance criteria (spec 41 R1, R6).
#
# It replaces `test-faithful-render.sh`, which asserted the mechanism *works*; that
# suite is deleted in Story 2. The pairing matters: a deletion story with no test
# leaves nothing to stop the sections coming back, and a test that only greps for
# absence cannot tell "deleted" from "renamed". So every absence assertion here has a
# matching presence assertion for the thing that was supposed to survive — the
# Companion Assets sections, whose prose is adjacent to what was removed and whose
# accidental deletion is the realistic failure.
#
# Assertions are absence-of-a-behaviour, not absence-of-a-word: the render is defined
# by a write path (`docs/{type}/html/…`) and a section heading, so both are checked,
# rather than banning "render", which the skills use for unrelated things (rendering a
# document in the message body).
#
# Slices are heading-anchored (retro 15) and asserted to span a real region — deleting
# a section changes what a loose range matches next, which is this epic's specific
# exposure to that failure mode.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

SKILLS_DIR="$SCRIPT_DIR/../../skills"
CONV="$SCRIPT_DIR/../../shared/skill-conventions.md"

# The three skills that carried a faithful-render section, with the write path each one
# owned. Checking the path as well as the heading is what makes this a behavioural
# assertion: a section renamed but still writing to docs/reviews/html/ is not retired.
RENDER_SKILLS="spec architect review"

render_path_for() {
  case "$1" in
    spec)      echo 'docs/specifications/html/' ;;
    architect) echo 'docs/architecture/html/' ;;
    review)    echo 'docs/reviews/html/' ;;
  esac
}

# has_section <file> <heading-regex> — the heading exists at any `#` depth.
has_section() {
  grep -qE "^#+ $2" "$1"
}

echo "Testing: faithful render retired"
echo "================================"

# --- Criterion: zero "Faithful Render" hits in Markdown ---

test_start "No 'Faithful Render' heading survives in any skill or shared Markdown"
assert_empty "$(grep -rn 'Faithful Render' "$SCRIPT_DIR/../.." --include='*.md')"

# --- Criterion: no docs/{type}/html write path remains in any skill ---

for skill in $RENDER_SKILLS; do
  file="$SKILLS_DIR/$skill/SKILL.md"
  path=$(render_path_for "$skill")

  test_start "$skill writes nothing to $path"
  if [ ! -f "$file" ]; then
    test_fail "Expected skill at $file"
    continue
  fi
  assert_not_contains "$(cat "$file")" "$path"
done

test_start "No per-type html/ write path remains anywhere in the skills"
# The generic form as well as the three concrete ones — a fourth skill acquiring a
# render would be invisible to the per-skill checks above.
assert_empty "$(grep -rnE 'docs/[a-z]+/html/|docs/\{type\}/html' "$SKILLS_DIR" --include='*.md')"

# --- Criterion: the storage-path row is absent from the shared convention ---

test_start "Storage & reference paths slice spans a real region"
STORAGE=$(sed -n '/^### Storage & reference paths/,/^### Self-contained rule/p' "$CONV")
if [ "$(printf '%s\n' "$STORAGE" | grep -c .)" -gt 3 ]; then
  test_pass
else
  test_fail "slice did not span the section: $(printf '%s' "$STORAGE" | head -2)"
fi

test_start "No render storage row survives in the convention"
assert_not_contains "$STORAGE" 'html/'

test_start "The one surviving storage row is the companion-asset row"
# Two halves of one claim: the companion-asset row is present, and it is the only body
# row. Either alone permits the wrong outcome — a second role could reappear beside it.
# The `|---|---|` separator does not match `^| `, so a one-role table counts 2.
ROWS=$(printf '%s\n' "$STORAGE" | grep -c '^| ')
if printf '%s' "$STORAGE" | grep -qF 'Companion asset' && [ "$ROWS" -eq 2 ]; then
  test_pass
else
  test_fail "expected header + 1 body row (2), got $ROWS"
fi

# --- must NOT delete the Companion Assets sections ---
# The realistic failure of this story: the render section sat directly below the
# companion-asset section in both files, sharing its subject matter.

test_start "spec retains its Companion Assets section"
if has_section "$SKILLS_DIR/spec/SKILL.md" 'Companion Assets'; then
  test_pass
else
  test_fail "the Companion Assets section was removed from spec"
fi

test_start "architect retains its Companion Assets section"
if has_section "$SKILLS_DIR/architect/SKILL.md" 'Companion Assets'; then
  test_pass
else
  test_fail "the Companion Assets section was removed from architect"
fi

for skill in spec architect; do
  test_start "$skill still writes companion assets to the assets/ path"
  assert_contains "$(cat "$SKILLS_DIR/$skill/SKILL.md")" "docs/$( [ "$skill" = spec ] && echo specifications || echo architecture )/assets/"
done

test_start "The companion-asset earns-its-place heuristic survives in both"
# One claim: the carve-out is only intact if the discipline that governs it is too.
if grep -qF 'has not earned its place' "$SKILLS_DIR/spec/SKILL.md" \
  && grep -qF 'has not earned its place' "$SKILLS_DIR/architect/SKILL.md"; then
  test_pass
else
  test_fail "the conservative heuristic is missing from one of the two skills"
fi

# --- Secondary sites: nothing still advertises the deleted feature ---
# architect's frontmatter described "an on-request HTML render" and survived the
# section deletion; found by reading, not by any assertion above.

test_start "No skill frontmatter still advertises an on-request HTML render"
assert_empty "$(grep -rniE 'on-request html|html (render|version|view)' "$SKILLS_DIR" --include='*.md')"

# --- Negative controls ---

FIXTURES="$TEST_TMPDIR/fixtures"
mkdir -p "$FIXTURES"

# A renamed section that still writes to the render path — absence of the heading
# alone would call this retired.
printf '#### HTML Projection (on request)\n\n3. Write it to `docs/reviews/html/{nn}-{slug}.html`.\n' \
  > "$FIXTURES/renamed.md"

test_start "Negative control: a renamed section still writing to html/ is detected"
if grep -qE 'docs/[a-z]+/html/' "$FIXTURES/renamed.md"; then
  test_pass
else
  test_fail "the write-path check missed a renamed render section"
fi

test_start "Negative control: a heading-only check would have missed it"
# States the reason the path assertion exists, by showing the weaker check passing on
# a file that is plainly not retired.
if ! grep -q 'Faithful Render' "$FIXTURES/renamed.md"; then
  test_pass
else
  test_fail "fixture unexpectedly contains the old heading"
fi

# A convention with a second storage row — the shape the row-count check rejects.
cat > "$FIXTURES/two-rows.md" <<'EOF'
### Storage & reference paths

| Role | Path | Notes |
|------|------|-------|
| Companion asset | `docs/{type}/assets/{nn}-{slug}-{label}.html` | … |
| Faithful render | `docs/{type}/html/{nn}-{slug}.html` | … |

### Self-contained rule
EOF

test_start "Negative control: a second storage row is rejected"
FX=$(sed -n '/^### Storage & reference paths/,/^### Self-contained rule/p' "$FIXTURES/two-rows.md")
if [ "$(printf '%s\n' "$FX" | grep -c '^| ')" -ne 2 ]; then
  test_pass
else
  test_fail "the row-count check accepted a convention with two roles"
fi

test_summary
