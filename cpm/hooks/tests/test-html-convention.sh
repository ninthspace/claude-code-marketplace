#!/bin/bash
# test-html-convention.sh — Tests for the shape of the shared HTML Output and
# Artifact Publishing conventions in cpm/shared/skill-conventions.md.
#
# These back Epic 41-01 Story 1's [integration] acceptance criteria. Spec 41
# reduces HTML Output from three roles to one (companion assets) and moves the
# human-facing interpretations to published artifacts.
#
# Every assertion here is STRUCTURAL — role counts, section presence, table row
# counts, ordering. None pins a prose string. Retro 14's testing gap was two
# assertions pinning a version literal that had been silently stale for months;
# a convention's wording is edited far more often than a version is bumped, so
# pinned prose would rot faster still.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

CONV="$SCRIPT_DIR/../../shared/skill-conventions.md"

# assert_section_survives <heading-prefix> <label> — a subsection protected by a
# must-NOT criterion is present exactly once. Exactly-once rather than at-least-
# once: a duplicated heading means a rewrite reintroduced a section rather than
# moving it, which is the same defect as losing it.
assert_section_survives() {
  test_start "$2 survives"
  local hits
  hits=$(grep -c "^$1" "$CONV")
  assert_equals "1" "$hits"
}

echo "Testing: HTML Output / Artifact Publishing convention shape"
echo "==========================================================="

test_start "skill-conventions.md exists"
if [ -f "$CONV" ]; then test_pass; else test_fail "Not found: $CONV"; fi

# --- Criterion: the opening names one role, not three ---

# The retired roles are named as bounded HTML *roles*. "faithful render" must be
# gone entirely; "present HTML communication" likewise. Companion assets stay.

test_start "HTML Output opening names companion assets"
OPENING=$(sed -n '/^## HTML Output/,/^### /p' "$CONV")
assert_contains "$OPENING" "companion assets"

test_start "HTML Output opening does not name faithful renders as a role"
assert_not_contains "$OPENING" "faithful render"

test_start "No faithful-render role survives anywhere in the convention"
HITS=$(grep -ic "faithful render" "$CONV")
assert_equals "0" "$HITS"

# --- Criterion: the storage table retains one row ---

# Count body rows of the storage table: lines starting with "| " inside the
# Storage & reference paths section, minus the header and separator rows.

test_start "Storage table has exactly one body row"
# The separator row starts "|---" rather than "| ", so it is not counted here:
# header row + 1 body row = 2. A second role reappearing would make this 3.
ROWS=$(sed -n '/^### Storage & reference paths/,/^### /p' "$CONV" \
  | grep -c '^| ' )
assert_equals "2" "$ROWS"

test_start "The surviving storage row is the companion-asset row"
STORAGE=$(sed -n '/^### Storage & reference paths/,/^### /p' "$CONV")
assert_contains "$STORAGE" "Companion asset"

test_start "No docs/{type}/html render path survives in the convention"
HITS=$(grep -c 'docs/{type}/html' "$CONV")
assert_equals "0" "$HITS"

# --- Criterion: the Tier vocabulary is retired ---

test_start "No Tier 1 / Tier 2 vocabulary in any skill or shared markdown"
HITS=$(grep -rl "Tier 1\|Tier 2" "$SCRIPT_DIR/../.." --include="*.md" 2>/dev/null | wc -l | tr -d ' ')
assert_equals "0" "$HITS"

# --- Criterion: the export-affordance pattern is RELOCATED, not deleted ---

# This is the criterion that a phrase-shaped sweep would have failed. Retiring
# the Tier vocabulary must not take the copy-as-prompt/copy-as-JSON pattern with
# it — Epic 41-02 Story 4 depends on it surviving. Assert both that it exists
# and that it now sits inside Artifact Publishing.

# Anchor on the heading, not on any mention of the phrase: cross-references to
# "Artifact Publishing" appear earlier in the file, and an unanchored sed range
# would start at the first of those and close at the heading itself.
PUBLISHING=$(sed -n '/^## Artifact Publishing/,/^## A Closing Note/p' "$CONV")

test_start "Artifact Publishing carries an Export affordances subsection"
assert_contains "$PUBLISHING" "Export affordances"

test_start "The canonical copy-button pattern survives"
HITS=$(grep -c 'copy-btn' "$CONV")
if [ "$HITS" -ge 1 ]; then test_pass; else test_fail "copy-btn pattern not found — relocation lost it"; fi

test_start "Copy-as-prompt affordance is still named"
assert_contains "$PUBLISHING" "Copy-as-prompt"

test_start "Copy-as-JSON affordance is still named"
assert_contains "$PUBLISHING" "Copy-as-JSON"

test_start "The copy-button pattern sits inside Artifact Publishing, not above it"
PUB_LINE=$(grep -n "Artifact Publishing" "$CONV" | head -1 | cut -d: -f1)
BTN_LINE=$(grep -n "copy-btn" "$CONV" | head -1 | cut -d: -f1)
if [ "$BTN_LINE" -gt "$PUB_LINE" ]; then
  test_pass
else
  test_fail "copy-btn at line $BTN_LINE precedes Artifact Publishing at line $PUB_LINE"
fi

# --- must NOT: protected subsections survive ---

assert_section_survives '### Self-contained rule' "Self-contained rule"
assert_section_survives '### Generate-from-source, never replace' "Generate-from-source rule"
assert_section_survives '### Companion-asset content' "Shared-chrome vs system-specific-mockup subsection"

test_start "The deliverable-mockup carve-out still names frontend-design"
CHROME=$(sed -n '/^### Companion-asset content/,/^### /p' "$CONV")
assert_contains "$CHROME" "frontend-design"

# ============================================================================
# Story 2 — Artifact Publishing is a top-level section with a canonical line
# ============================================================================

# --- Criterion: promoted to top level ---

assert_section_survives '## Artifact Publishing' "Artifact Publishing top-level section"

test_start "Artifact Publishing is no longer nested under HTML Output"
HITS=$(grep -c '^### Publishing as an artifact' "$CONV")
assert_equals "0" "$HITS"

assert_section_survives '### Mechanics' "Mechanics subsection"
assert_section_survives '### Export affordances' "Export affordances subsection"
assert_section_survives '### Recording is part of publishing' "Recording subsection"

# --- Criterion: mechanics compose per artifact-design, not the template (AD2) ---

test_start "Publishing mechanics name the artifact-design skill"
assert_contains "$PUBLISHING""artifact-design"

test_start "Publishing mechanics no longer re-emit the shared template"
# The template governs local companion assets only. "re-emission of" was the
# phrasing that bound published pages to it.
HITS=$(printf '%s' "$PUBLISHING"| grep -c 're-emission of')
assert_equals "0" "$HITS"

# --- Criterion: one canonical reference line, recorded in a fenced block ---

# Recorded inside a fence so the exact bytes are copyable. A propagator that
# "improves" the wording is the failure this guards against, so assert the line
# appears exactly once in the convention — a second copy means it was restated
# rather than referenced.

CANON='An artifact can be published from this output on request'

test_start "The canonical reference line is recorded exactly once"
HITS=$(grep -c "$CANON" "$CONV")
assert_equals "1" "$HITS"

test_start "The canonical line sits inside a fenced block"
LINE=$(grep -n "$CANON" "$CONV" | cut -d: -f1)
FENCE_BEFORE=$(sed -n "$((LINE - 1))p" "$CONV")
assert_contains "$FENCE_BEFORE" '```'

test_start "The canonical line keeps the separate-confirmation clause"
assert_contains "$PUBLISHING""always separately confirmed, and never the default"

test_start "The superseded reference line is gone from the convention"
# Scoped to skill-conventions.md: the six SKILL.md sites are owned by epics
# 41-03 (which replaces the line) and 41-04 (which deletes their host sections).
HITS=$(grep -c 'Any HTML output here can additionally be published' "$CONV")
assert_equals "0" "$HITS"

# --- Criterion: register + backlink are part of publishing (R5) ---

test_start "Publishing names the artifact register path"
assert_contains "$PUBLISHING""docs/artifacts/index.md"

test_start "Publishing names the source-artifact backlink field"
assert_contains "$PUBLISHING"'**Artifacts**:'

test_start "Recording is stated as part of publishing, not a follow-up"
assert_contains "$PUBLISHING""not a follow-up"

test_summary
