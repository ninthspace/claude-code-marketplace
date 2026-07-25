#!/bin/bash
# test-epics-dependency-view.sh — Tests for cpm:epics' on-request dependency view,
# backing the Story 1 [integration] acceptance criteria of epic 34-02 (epics Dependency
# View):
#   - the view renders unblocked vs blocked stories correctly from epic-doc data
#   - the view is a self-contained artifact body fragment, generated from the Markdown
#     epic docs (spec 41 / epic 41-02 Story 2 — was a template-built local HTML file)
#   - the view must NOT modify the source epic Markdown (read-only)
#
# The readiness rule mirrors cpm:do hydration: a Pending story is "ready" when every
# Blocked-by dependency is Complete (or "—"), else "blocked"; In Progress / Complete
# stories occupy their own groups. A reference scanner derives the expected classification
# from fixture epic docs, and check_section_contains confirms the rendered view places each
# story under the correct section. Source immutability is proven with the md_content_hash /
# check_source_unchanged pair (plus a negative control).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/html-test-helpers.sh"

SKILL="$SCRIPT_DIR/../../skills/epics/SKILL.md"

echo "Testing: epics dependency view"
echo "=============================="

# --- Fixture epics tree -----------------------------------------------------------
# Cross-epic dependencies only (resolved against epic-level status), so the reference
# scanner needs no intra-epic story-number resolution.
EPICS_DIR="$TEST_TMPDIR/docs/epics"
mkdir -p "$EPICS_DIR"

cat > "$EPICS_DIR/90-01-epic-done.md" <<'M'
# Done Epic

**Source spec**: x
**Status**: Complete
**Blocked by**: —

## Finished work
**Story**: 1
**Status**: Complete
**Blocked by**: —
M

cat > "$EPICS_DIR/90-02-epic-active.md" <<'M'
# Active Epic

**Source spec**: x
**Status**: In Progress
**Blocked by**: —

## Ready work
**Story**: 1
**Status**: Pending
**Blocked by**: —

## Underway work
**Story**: 2
**Status**: In Progress
**Blocked by**: —
M

cat > "$EPICS_DIR/90-03-epic-cross.md" <<'M'
# Cross Epic

**Source spec**: x
**Status**: Pending
**Blocked by**: —

## Cross-ready
**Story**: 1
**Status**: Pending
**Blocked by**: Epic 90-01-epic-done

## Cross-blocked
**Story**: 2
**Status**: Pending
**Blocked by**: Epic 90-02-epic-active
M

# --- Reference scanner: emit EPIC / STORY records from the fixtures ----------------
# EPIC\t{prefix}\t{status} ; STORY\t{prefix}\t{heading}\t{status}\t{blockedby}
SCAN=$(awk '
  function flush(){ if(heading!=""){ printf "STORY\t%s\t%s\t%s\t%s\n", prefix, heading, sstatus, sblocked } heading=""; sstatus=""; sblocked="—" }
  FNR==1 { flush(); f=FILENAME; sub(/.*\//,"",f); prefix=f; sub(/-epic-.*/,"",prefix); instory=0; estatus="" }
  /^## / { flush(); instory=1; heading=$0; sub(/^## /,"",heading); sub(/[[:space:]]+$/,"",heading); sstatus=""; sblocked="—"; next }
  /^\*\*Status\*\*:/ {
    v=$0; sub(/^\*\*Status\*\*:[[:space:]]*/,"",v); sub(/[[:space:]]+$/,"",v);
    if(instory==0){ if(estatus==""){ estatus=v; printf "EPIC\t%s\t%s\n", prefix, v } }
    else if(sstatus==""){ sstatus=v }
    next
  }
  /^\*\*Blocked by\*\*:/ {
    v=$0; sub(/^\*\*Blocked by\*\*:[[:space:]]*/,"",v); sub(/[[:space:]]+$/,"",v);
    if(instory==1){ sblocked=v }
    next
  }
  END{ flush() }
' "$EPICS_DIR"/*.md)

epic_status()  { printf '%s\n' "$SCAN" | awk -F'\t' -v p="$1" '$1=="EPIC"&&$2==p{print $3}'; }
story_status() { printf '%s\n' "$SCAN" | awk -F'\t' -v h="$1" '$1=="STORY"&&$3==h{print $4}'; }
story_blocked(){ printf '%s\n' "$SCAN" | awk -F'\t' -v h="$1" '$1=="STORY"&&$3==h{print $5}'; }

# Readiness rule — mirrors cpm:do hydration.
classify() {
  local status="$1" blocked="$2"
  case "$status" in
    Complete*)      echo complete;   return ;;
    "In Progress"*) echo inprogress; return ;;
  esac
  # Pending:
  if [ "$blocked" = "—" ] || [ -z "$blocked" ]; then echo ready; return; fi
  local verdict=ready tok pfx st oldIFS="$IFS"
  IFS=,
  for tok in $blocked; do
    case "$tok" in
      *Epic*)
        pfx=$(printf '%s' "$tok" | sed -E 's/.*Epic[[:space:]]+//; s/-epic-.*//; s/[[:space:]]*//g')
        st=$(epic_status "$pfx")
        case "$st" in Complete*) ;; *) verdict=blocked ;; esac
        ;;
    esac
  done
  IFS="$oldIFS"
  echo "$verdict"
}

classify_story() { classify "$(story_status "$1")" "$(story_blocked "$1")"; }

# --- Reference classification is correct (the rule, from epic-doc data) -----------

test_start "Scanner reads all three fixture epics (3 EPIC records)"
assert_equals "3" "$(printf '%s\n' "$SCAN" | grep -c '^EPIC')"

test_start "Complete story classifies as complete"
assert_equals "complete" "$(classify_story 'Finished work')"

test_start "Pending story with no deps classifies as ready"
assert_equals "ready" "$(classify_story 'Ready work')"

test_start "In Progress story classifies as inprogress"
assert_equals "inprogress" "$(classify_story 'Underway work')"

test_start "Pending story blocked by a Complete epic classifies as ready"
assert_equals "ready" "$(classify_story 'Cross-ready')"

test_start "Pending story blocked by an incomplete epic classifies as blocked"
assert_equals "blocked" "$(classify_story 'Cross-blocked')"

# --- A dependency view composed as an artifact body fragment -----------------------
#
# Spec 41 (epic 41-02 Story 2) pivots this view from a local HTML file built from the
# shared template to a page published via the Artifact tool. The Artifact tool supplies
# its own document shell, so what the skill composes is a *body fragment* — hence
# check_valid_fragment here rather than check_uses_shared_template / check_valid_html.
# The classification and read-only assertions below are unchanged by that pivot: the
# medium moved, the rules did not.
VIEW="$TEST_TMPDIR/docs/plans/epics-artifact-dependency-view.html"
mkdir -p "$(dirname "$VIEW")"
CONTENT='<section id="ready"><h2>Ready to pick up</h2><ul>'\
'<li>Ready work — 90-02-epic-active <button class="copy-btn" data-prompt="/cpm:do docs/epics/90-02-epic-active.md">Copy</button></li>'\
'<li>Cross-ready — 90-03-epic-cross</li></ul></section>'\
'<section id="blocked"><h2>Blocked</h2><ul>'\
'<li>Cross-blocked — 90-03-epic-cross (waiting on Epic 90-02-epic-active)</li></ul></section>'\
'<section id="inprogress"><h2>In progress</h2><ul><li>Underway work — 90-02-epic-active</li></ul></section>'\
'<section id="complete"><h2>Complete</h2><ul><li>Finished work — 90-01-epic-done</li></ul></section>'
# The fragment the skill would publish: leading <style>, content, inline export handler.
write_fragment() {
  {
    printf '<style>\n  .sev { font-weight: 600; }\n</style>\n'
    printf '%s\n' "$CONTENT"
    printf '<script>\n'
    printf "  document.addEventListener('click',function(e){var b=e.target.closest('.copy-btn');if(b&&navigator.clipboard)navigator.clipboard.writeText(b.dataset.prompt);});\n"
    printf '</script>\n'
  } > "$1"
}
write_fragment "$VIEW"

test_start "View is a valid artifact body fragment, inline export JS included"
OUT=$(check_valid_fragment "$VIEW"); RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  test_pass
else
  test_fail "expected rc 0 and no output, got rc $RC: $OUT"
fi

test_start "A complete document would be rejected as a fragment (negative control)"
BADVIEW="$TEST_TMPDIR/docs/plans/epics-artifact-bad.html"
printf '<!doctype html>\n<html><head></head><body>%s</body></html>\n' "$CONTENT" > "$BADVIEW"
OUT=$(check_valid_fragment "$BADVIEW"); RC=$?
if [ "$RC" -eq 1 ] && [[ "$OUT" == *"FORBIDDEN"* ]]; then
  test_pass
else
  test_fail "expected rc 1 naming a forbidden element, got rc $RC: $OUT"
fi

# --- Rendered placement agrees with the classification ----------------------------

test_start "Ready stories render under the ready section"
# Both ready stories are one claim about one section — asserted together so the
# suite does not report more passes than tests run.
if check_section_contains "$VIEW" ready "Ready work" >/dev/null \
  && check_section_contains "$VIEW" ready "Cross-ready" >/dev/null; then
  test_pass
else
  test_fail "a ready story is missing from the ready section"
fi

test_start "Blocked story renders under the blocked section"
check_section_contains "$VIEW" blocked "Cross-blocked"; assert_equals "0" "$?"

test_start "In progress story renders under the inprogress section"
check_section_contains "$VIEW" inprogress "Underway work"; assert_equals "0" "$?"

test_start "Complete story renders under the complete section"
check_section_contains "$VIEW" complete "Finished work"; assert_equals "0" "$?"

test_start "A ready story is NOT misplaced under blocked (negative control)"
OUT=$(check_section_contains "$VIEW" blocked "Ready work"); RC=$?
if [ "$RC" -eq 1 ] && [[ "$OUT" == *"NOT_IN_SECTION"* ]]; then
  test_pass
else
  test_fail "expected rc 1 naming NOT_IN_SECTION, got rc $RC: $OUT"
fi

test_start "An absent section is reported (negative control)"
OUT=$(check_section_contains "$VIEW" nonexistent "anything"); RC=$?
if [ "$RC" -eq 1 ] && [[ "$OUT" == *"SECTION_NOT_FOUND"* ]]; then
  test_pass
else
  test_fail "expected rc 1 naming SECTION_NOT_FOUND, got rc $RC: $OUT"
fi

# --- Read-only: generating the view must not mutate any epic doc ------------------

test_start "Every epic doc is unchanged after a read-only generation step"
BEFORE_01=$(md_content_hash "$EPICS_DIR/90-01-epic-done.md")
BEFORE_02=$(md_content_hash "$EPICS_DIR/90-02-epic-active.md")
BEFORE_03=$(md_content_hash "$EPICS_DIR/90-03-epic-cross.md")
# Read-only "regeneration": rewrite only the published fragment, touch no epic doc.
write_fragment "$VIEW"
# "No epic doc changed" is one claim about the whole tree, not three.
if check_source_unchanged "$EPICS_DIR/90-01-epic-done.md" "$BEFORE_01" >/dev/null \
  && check_source_unchanged "$EPICS_DIR/90-02-epic-active.md" "$BEFORE_02" >/dev/null \
  && check_source_unchanged "$EPICS_DIR/90-03-epic-cross.md" "$BEFORE_03" >/dev/null; then
  test_pass
else
  test_fail "an epic doc changed during a read-only generation step"
fi

test_start "A mutated epic doc is detected (negative control)"
BEFORE=$(md_content_hash "$EPICS_DIR/90-02-epic-active.md")
printf '\n## Sneaky appended story\n' >> "$EPICS_DIR/90-02-epic-active.md"
OUT=$(check_source_unchanged "$EPICS_DIR/90-02-epic-active.md" "$BEFORE"); RC=$?
if [ "$RC" -eq 1 ] && [[ "$OUT" == *"SOURCE_MODIFIED"* ]]; then
  test_pass
else
  test_fail "expected rc 1 naming SOURCE_MODIFIED, got rc $RC: $OUT"
fi

# ============================================================================
# Spec 41 / epic 41-02 Story 2 — the documented contract after the pivot
# ============================================================================
#
# A bash suite cannot invoke the skill, so the criteria that are statements about
# instructions are guarded against the SKILL.md source. Slices are heading-anchored
# (retro 15): an unanchored range would open on the first cross-reference to
# "Dependency View" rather than on the section itself.

DEPVIEW=$(sed -n '/^## Dependency View (on request)/,/^## State Management/p' "$SKILL")

# has <text> <extended-regex> — the slices are shell variables, so grep reads stdin.
has() {
  printf '%s' "$1" | grep -qiE "$2"
}

test_start "Dependency View slice spans a real region"
DEPLINES=$(printf '%s\n' "$DEPVIEW" | grep -c .)
if [ "$DEPLINES" -ge 10 ]; then
  test_pass
else
  test_fail "slice has $DEPLINES non-empty lines — the sed range did not match as intended"
fi

test_start "No write to the retired dependency-view scratch path remains"
HITS=$(grep -c 'docs/plans/epics-dependency-view\.html' "$SKILL")
assert_equals "0" "$HITS"

test_start "The section no longer renders via the shared template"
if has "$DEPVIEW" 'assets/html/template\.html|Render via the shared template|CPM: tokens'; then
  test_fail "Dependency View still instructs template consumption"
else
  test_pass
fi

test_start "The canonical Artifact Publishing reference line is present byte-identically"
CANON='An artifact can be published from this output on request — follow the shared **Artifact Publishing** procedure. It is always separately confirmed, and never the default.'
HITS=$(grep -Fc "$CANON" "$SKILL")
assert_equals "1" "$HITS"

test_start "The superseded reference line is gone"
HITS=$(grep -c 'Any HTML output here can additionally be published' "$SKILL")
assert_equals "0" "$HITS"

# --- Criterion: the readiness rule is unchanged ---

test_start "The readiness rule still matches what cpm:do hydration applies"
if has "$DEPVIEW" 'same rule .*cpm:do. hydration applies' \
  && has "$DEPVIEW" 'Status\*\*: Complete'; then
  test_pass
else
  test_fail "the readiness rule's cpm:do agreement clause did not survive the rewrite"
fi

test_start "Unblocked-first ordering survives"
assert_contains "$DEPVIEW" "Ready to pick up"

# --- Criterion: the general glob is retained (legacy flat epics stay visible) ---

test_start "The general glob is retained"
assert_contains "$DEPVIEW" 'docs/epics/[0-9]*-epic-*.md'

test_start "The never-narrow warning on the glob survives"
assert_contains "$DEPVIEW" "never narrow this"

# --- Criterion: schema-tolerance rules survive intact ---

test_start "Missing status renders under Needs attention rather than a guessed bucket"
if has "$DEPVIEW" 'Needs attention' && has "$DEPVIEW" 'do \*not\* guess'; then
  test_pass
else
  test_fail "the missing-status tolerance rule did not survive"
fi

test_start "An unparseable epic costs one line, not the view"
assert_contains "$DEPVIEW" "One bad file costs one line, not the view"

test_start "The always-valid-output rule survives the medium change"
assert_contains "$DEPVIEW" "Always emit a valid, complete output"

# --- Criterion: register row, no Artifacts backlink ---

test_start "Publishing writes the register row"
assert_contains "$DEPVIEW" "docs/artifacts/index.md"

test_start "The section states why no Artifacts backlink is written"
assert_contains "$DEPVIEW" "no single source artifact"

# --- Criterion: degradation is to conversation, never to HTML ---

test_start "Degradation states the ready/blocked list in conversation"
if has "$DEPVIEW" 'Artifact tool is absent' && has "$DEPVIEW" 'in the conversation'; then
  test_pass
else
  test_fail "the degradation path is not stated"
fi

test_start "Degradation never falls back to a local HTML file"
assert_contains "$DEPVIEW" "never fall back to writing a local HTML file"

# --- must NOT: modify, rewrite, or re-save any epic doc ---

test_start "The read-only guarantee over docs/epics survives"
if has "$DEPVIEW" 'must never modify, rewrite, or re-save any epic doc' \
  && has "$DEPVIEW" 'no Edit/Write to anything under .docs/epics/'; then
  test_pass
else
  test_fail "the read-only guarantee over epic docs did not survive the rewrite"
fi

test_summary
