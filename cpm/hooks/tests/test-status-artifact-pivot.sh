#!/bin/bash
# test-status-artifact-pivot.sh — Tests for the status skill's pivot from a local
# HTML dashboard to a published artifact.
#
# These back Epic 41-02 Story 1's [integration] acceptance criteria (spec 41 R2,
# R5, AD1, AD3).
#
# Two conventions carried from retro 15, both deliberate:
#
# 1. Every sed range is anchored to heading syntax (^## / ^###), never a bare
#    phrase. A range opened on a phrase matches the first cross-reference to it
#    rather than the section itself, and sed's range-restart behaviour can make
#    that pass for the wrong reason.
# 2. Where a check has two halves that are one claim (a section contains X and
#    does not contain Y), they are asserted together under one test_start via a
#    helper. test_start counts once and each assert counts separately, so
#    splitting one claim across two asserts reports more passes than tests run.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

SKILL="$SCRIPT_DIR/../../skills/status/SKILL.md"

# Section slices, all heading-anchored. Extracted once and reused.
PHASE4=$(sed -n '/^### Phase 4:/,/^## Report Format/p' "$SKILL")
INPUT=$(sed -n '/^## Input/,/^## State Management/p' "$SKILL")
STATE=$(sed -n '/^## State Management/,/^## Stale-Progress Check/p' "$SKILL")
FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$SKILL")

# has <text> <extended-regex> — true when the slice matches, case-insensitively.
# Wraps the printf|grep idiom this suite would otherwise repeat a dozen times;
# the slices are shell variables rather than files, so grep needs them on stdin.
has() {
  printf '%s' "$1" | grep -qiE "$2"
}

echo "Testing: status — full-picture artifact pivot"
echo "============================================="

# --- The slices themselves must be sound (retro 15) ---

# A slice that silently comes back empty makes every assertion over it vacuous.
# Check each one spans a real region before trusting anything asserted against it.

assert_slice_spans() {
  test_start "Slice '$2' spans a real region"
  local lines
  lines=$(printf '%s\n' "$1" | grep -c .)
  if [ "$lines" -ge 3 ]; then
    test_pass
  else
    test_fail "slice '$2' has $lines non-empty lines — the sed range did not match as intended"
  fi
}

assert_slice_spans "$PHASE4" "Phase 4"
assert_slice_spans "$INPUT" "Input"
assert_slice_spans "$STATE" "State Management"

# --- Criterion: Phase 4 contains no instruction to write a local HTML file ---

test_start "Phase 4 does not instruct writing a local dashboard file"
# The retired path, and the template consumption that produced it. The scratch
# fragment lives in State Management as a build intermediate, not here.
if has "$PHASE4" 'status-dashboard\.html|assets/html/template\.html|Consume the shared template'; then
  test_fail "Phase 4 still instructs local HTML generation"
else
  test_pass
fi

test_start "Phase 4 publishes rather than generates"
assert_contains "$PHASE4" "Artifact Publishing"

test_start "Phase 4 carries the canonical reference line byte-identically"
CANON='An artifact can be published from this output on request — follow the shared **Artifact Publishing** procedure. It is always separately confirmed, and never the default.'
# Counted within the Phase 4 slice, which is what this assertion has always claimed to
# check. It counted the whole file until epic 44-02 added a second publishable output —
# the spec coverage page in Phase 3b — at which point the file-wide count started
# reporting 2 and the failure pointed at Phase 4, which had not changed. A file-wide
# count passing for a Phase 4 claim was luck, not coverage: it would equally have passed
# had the line sat only in Phase 3b.
HITS=$(printf '%s\n' "$PHASE4" | grep -Fc "$CANON")
assert_equals "1" "$HITS"

test_start "The superseded reference line is gone"
HITS=$(grep -c 'Any HTML output here can additionally be published' "$SKILL")
assert_equals "0" "$HITS"

# --- Criterion: the five sections survive as artifact content ---

# Named individually so a failure says which section was dropped in the rewrite.

assert_section_listed() {
  test_start "Phase 4 retains the '$1' section"
  assert_contains "$PHASE4" "$1"
}

assert_section_listed "At a glance (RAG)"
assert_section_listed "In progress & blocked"
assert_section_listed "Epic / story completion grid"
assert_section_listed "Recent git activity"
assert_section_listed "Recommended next steps"

# --- Criterion: the canonical agreement statement survives ---

test_start "The agreement statement '{complete} of {total} epics complete' survives"
assert_contains "$PHASE4" '{complete} of {total} epics complete'

test_start "The agreement statement is still tied to the stdout narrative's count"
assert_contains "$PHASE4" "must match the count the stdout narrative reports"

# --- Criterion: schema tolerance survives the medium change ---

test_start "The graceful schema tolerance rule survives in the completion grid"
assert_contains "$PHASE4" "graceful schema tolerance"

# --- Criterion: register row written, no Artifacts backlink ---

# Narrowed during execution: status has no single source artifact, and writing a
# backlink into every scanned epic would break its read-only guarantee. The
# register row is therefore the only durable trace and must not also be dropped.

test_start "Publishing writes the register row"
assert_contains "$PHASE4" "docs/artifacts/index.md"

test_start "Phase 4 states why no Artifacts backlink is written"
assert_contains "$PHASE4" "no single source artifact"

# --- must NOT: hard-fail when the Artifact tool is absent (AD3) ---

test_start "Phase 4 states the degradation path when the Artifact tool is absent"
assert_contains "$PHASE4" "Artifact tool is absent"

test_start "Degradation is to the stdout narrative, never to local HTML"
# AD3: no local-HTML fallback path exists. Both halves are one claim — that the
# fallback is the narrative AND that it is not a file — so they share a test.
if has "$PHASE4" 'no local-HTML fallback' && has "$PHASE4" 'Phases 1–3'; then
  test_pass
else
  test_fail "Phase 4 does not state narrative-not-HTML degradation"
fi

test_start "Phase 4 forbids hard-failing on tool absence"
assert_contains "$PHASE4" "Never hard-fail"

# --- Criterion: all four secondary sites updated ---

test_start "Secondary site 1 — the frontmatter description names publishing, not HTML"
# Deliberately NOT a bare grep for "artifact": the description opens "Scans CPM
# artifacts", so that word is present whether or not the pivot happened. Assert
# the verb the pivot introduces instead.
if has "$FRONTMATTER" 'publish' && ! has "$FRONTMATTER" 'HTML'; then
  test_pass
else
  test_fail "frontmatter description still describes an HTML dashboard"
fi

test_start "Secondary site 2 — the summary paragraph describes publishing a page"
SUMMARY=$(grep -m1 '^\*\*Optional full-picture' "$SKILL")
if [ -n "$SUMMARY" ] && has "$SUMMARY" 'publish' && ! has "$SUMMARY" 'HTML document'; then
  test_pass
else
  test_fail "summary paragraph not updated: $SUMMARY"
fi

test_start "Secondary site 3 — 'html' is retired as a trigger word"
# Retro 12 applied: judged by what the rule does, not by the phrase. 'html' stops
# being meaningful because no HTML file is produced; 'dashboard' does not, because
# it still names what the reader wants. The section must therefore drop one and
# keep the other — asserting only the drop would pass on a sweep that deleted both.
if has "$INPUT" 'no longer a trigger word' && has "$INPUT" 'dashboard'; then
  test_pass
else
  test_fail "trigger-word list did not retire 'html' while retaining 'dashboard'"
fi

test_start "Secondary site 4 — State Management describes no dashboard write path"
if has "$STATE" 'status-dashboard\.html'; then
  test_fail "State Management still writes the retired dashboard path"
else
  test_pass
fi

test_start "State Management names the scratch fragment as a build intermediate"
if has "$STATE" 'status-artifact-full-picture\.html' && has "$STATE" 'build intermediate'; then
  test_pass
else
  test_fail "State Management does not identify the scratch path as a build intermediate"
fi

test_start "State Management states the register row is the one durable write"
assert_contains "$STATE" "docs/artifacts/index.md"

# --- The read-only guarantee is reconciled, not contradicted ---

# The Guidelines bullet claimed "All files and git state remain untouched", which
# the register row falsifies. A surviving absolute claim would be a false premise
# of exactly the kind structural tests miss, so it is asserted here directly.

test_start "The read-only guideline accounts for the register row"
GUIDELINES=$(sed -n '/^## Guidelines/,$p' "$SKILL")
if has "$GUIDELINES" 'All files and git state remain untouched'; then
  test_fail "Guidelines still claim no file is ever written — the register row contradicts it"
else
  test_pass
fi

test_summary
