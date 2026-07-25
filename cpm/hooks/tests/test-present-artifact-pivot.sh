#!/bin/bash
# test-present-artifact-pivot.sh — Tests for cpm:present's pivot from a local HTML
# sibling to a published artifact.
#
# These back Epic 41-02 Story 3's [integration] acceptance criteria (spec 41 R2, R5,
# AD1). It replaces test-present-html.sh, which validated the local HTML output that
# no longer exists — its path-shape validator (since removed with the rest of the
# retired mechanism in epic 41-04) plus the template/self-containment checks. Nothing
# in that suite tested behaviour surviving the pivot.
#
# AD1 is what most of this file guards: artifacts change the medium, never the record.
# present is the one pivoted skill with a durable Markdown output, and the fields that
# make regeneration and update-in-place work live in it. Losing **Source artifacts**
# or **Artifact** would trade a durable record for a link — silently, and only
# noticeably on the *next* run.
#
# Slices are heading-anchored (retro 15); assertions with two halves that form one
# claim share a test_start (retro 15) so the reported count stays honest.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

SKILL="$SCRIPT_DIR/../../skills/present/SKILL.md"

# has <text> <extended-regex> — slices are shell variables, so grep reads stdin.
has() {
  printf '%s' "$1" | grep -qiE "$2"
}

echo "Testing: present — artifact pivot"
echo "================================="

test_start "Skill source exists"
if [ -f "$SKILL" ]; then test_pass; else test_fail "Expected skill at $SKILL"; fi

BODY=$(cat "$SKILL")

# --- Criterion: no write to the local communication HTML path remains ---

test_start "No write to docs/communications/{nn}-{format}-{slug}.html remains"
# The scratch fragment under docs/plans/ is a build intermediate and is expected;
# what must be gone is the .html sibling inside docs/communications/.
if has "$BODY" 'docs/communications/\{nn\}-\{format\}-\{slug\}\.html'; then
  test_fail "the local communication HTML path is still written"
else
  test_pass
fi

test_start "The shared template is no longer consumed"
if has "$BODY" 'Consume the shared template|CPM:CONTENT|cpm-memo'; then
  test_fail "present still substitutes the shared template's tokens"
else
  test_pass
fi

test_start "The optional-HTML offer is gone"
if has "$BODY" 'Also produce an HTML version|HTML output \(optional\)'; then
  test_fail "present still offers a local HTML version"
else
  test_pass
fi

# --- Criterion: the canonical reference line, byte-identical ---

test_start "The canonical Artifact Publishing reference line is present byte-identically"
CANON='An artifact can be published from this output on request — follow the shared **Artifact Publishing** procedure. It is always separately confirmed, and never the default.'
HITS=$(grep -Fc "$CANON" "$SKILL")
assert_equals "1" "$HITS"

test_start "The superseded reference line is gone"
HITS=$(grep -c 'Any HTML output here can additionally be published' "$SKILL")
assert_equals "0" "$HITS"

# --- Criterion / must NOT: the Markdown output and its fields are retained (AD1) ---

test_start "The Markdown output path is retained"
assert_contains "$BODY" 'docs/communications/{nn}-{format}-{slug}.md'

test_start "The **Source artifacts** field is retained in the output format"
assert_contains "$BODY" '**Source artifacts**'

test_start "The **Source artifacts** field is still tied to regeneration"
# The field's value is that re-running with the same sources updates the output.
# Retaining the field while dropping its stated purpose would pass a bare grep.
assert_contains "$BODY" 'The `**Source artifacts**` field enables regeneration'

test_start "The Markdown is stated as the record, not a byproduct of publishing"
if has "$BODY" 'record of what was communicated' && has "$BODY" 'publishing never replaces it'; then
  test_pass
else
  test_fail "the Markdown's standing as the record of what was communicated is not stated"
fi

# --- Criterion: the **Artifact** field is retained for update-in-place ---

test_start "The **Artifact** field is retained in the output format"
assert_contains "$BODY" '**Artifact**: {published URL'

test_start "Regeneration republishes to the recorded URL rather than minting a second"
if has "$BODY" 'update in place' && has "$BODY" 'recorded in the .\*\*Artifact\*\*. field'; then
  test_pass
else
  test_fail "regeneration no longer reads the **Artifact** field for the existing URL"
fi

test_start "Regeneration covers two outputs, not three"
# With the local HTML gone the paragraph must not still promise to update it.
if has "$BODY" 'the HTML output \(if produced\)'; then
  test_fail "regeneration still offers to update a local HTML output that is not produced"
else
  test_pass
fi

# --- Criterion: register row AND backlink (present has a source artifact) ---

test_start "Publishing records the register row, with **Artifact** serving as the backlink"
# R5 wants the relationship to read from both ends: register → source, source → URL.
# present's pre-existing singular **Artifact** field already provides the second half,
# so it satisfies the backlink obligation rather than sitting alongside a duplicate.
if has "$BODY" 'register' && has "$BODY" 'this skill.s backlink'; then
  test_pass
else
  test_fail "the register row and/or **Artifact**'s role as the backlink are not stated"
fi

test_start "The skill forbids adding a duplicate **Artifacts** field beside **Artifact**"
assert_contains "$BODY" 'Do **not** add a second `**Artifacts**:` field beside it'

# --- Criterion: the branding prohibition survives ---

test_start "The prohibition on misattributed communications survives"
assert_contains "$BODY" 'presents itself as issued by an organisation the user does not represent'

test_start "The prohibition still resolves to keeping it local and not offering publishing"
assert_contains "$BODY" 'keep it local and do not offer publishing'

# --- AD3: degradation is to the Markdown, never to HTML ---

test_start "Tool absence degrades to the Markdown without hard-failing"
if has "$BODY" 'Artifact tool is absent' \
  && has "$BODY" 'do not write a local HTML file in its place'; then
  test_pass
else
  test_fail "the degradation path is not stated, or still permits a local HTML fallback"
fi

test_summary
