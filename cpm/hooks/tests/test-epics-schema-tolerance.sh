#!/bin/bash
# test-epics-schema-tolerance.sh — Tests for the dependency view's graceful schema
# tolerance, backing the Story 2 [integration] acceptance criterion of epic 34-02:
#   - Given an epic doc with a missing or partial field, the view renders what it can and
#     visibly flags the gap rather than erroring
#
# Two halves: (1) the parser tolerates drift — scanning a partial / unparseable epic tree
# does not error and a missing-status story is surfaced as "unknown" (not silently bucketed
# as ready/blocked); (2) the rendered view stays a valid, self-contained document and places
# the gaps in a visible "Needs attention" group naming both the flagged story and the
# unparseable file.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/html-test-helpers.sh"

TEMPLATE="$SCRIPT_DIR/../../assets/html/template.html"

echo "Testing: epics dependency view — schema tolerance"
echo "================================================="

# --- Fixture epics tree with drift ------------------------------------------------
EPICS_DIR="$TEST_TMPDIR/docs/epics"
mkdir -p "$EPICS_DIR"

# A partial epic: one well-formed story, one story missing its **Status** field.
cat > "$EPICS_DIR/91-01-epic-partial.md" <<'M'
# Partial Epic

**Source spec**: x
**Status**: Pending
**Blocked by**: —

## Good story
**Story**: 1
**Status**: Pending
**Blocked by**: —

## Headless story
**Story**: 2
**Blocked by**: —
M

# An unparseable epic: no ## stories at all.
cat > "$EPICS_DIR/91-02-epic-empty.md" <<'M'
# Empty Epic

Some prose, but no stories at all.
M

# --- Parser tolerates drift -------------------------------------------------------
# Same compact scanner the dependency-view suite uses; here the point is it neither errors
# nor invents a status for the headless story.
scan() {
  awk '
    function flush(){ if(heading!=""){ printf "STORY\t%s\t%s\t%s\t%s\n", prefix, heading, sstatus, sblocked } heading=""; sstatus=""; sblocked="—" }
    FNR==1 { flush(); f=FILENAME; sub(/.*\//,"",f); prefix=f; sub(/-epic-.*/,"",prefix); instory=0; estatus="" }
    /^## / { flush(); instory=1; heading=$0; sub(/^## /,"",heading); sub(/[[:space:]]+$/,"",heading); sstatus=""; sblocked="—"; next }
    /^\*\*Status\*\*:/ {
      v=$0; sub(/^\*\*Status\*\*:[[:space:]]*/,"",v); sub(/[[:space:]]+$/,"",v);
      if(instory==0){ if(estatus==""){ estatus=v } } else if(sstatus==""){ sstatus=v }
      next
    }
    /^\*\*Blocked by\*\*:/ { v=$0; sub(/^\*\*Blocked by\*\*:[[:space:]]*/,"",v); sub(/[[:space:]]+$/,"",v); if(instory==1){ sblocked=v } next }
    END{ flush() }
  ' "$EPICS_DIR"/*.md
}

test_start "Scanning a partial / unparseable tree exits cleanly (no error)"
SCAN=$(scan); RC=$?
assert_equals "0" "$RC"

test_start "Well-formed story is still parsed with its status"
assert_contains "$SCAN" "$(printf 'STORY\t91-01\tGood story\tPending\t')"

test_start "Missing-status story is surfaced with an empty status, not a guessed one"
# The headless story appears as a record whose status field is empty (tab-tab), so the
# renderer routes it to Needs-attention rather than mis-bucketing it as ready/blocked.
assert_contains "$SCAN" "$(printf 'STORY\t91-01\tHeadless story\t\t')"

# Readiness rule must yield neither ready nor blocked for an unknown status.
classify() {
  case "$1" in Complete*) echo complete;; "In Progress"*) echo inprogress;; Pending*) echo pending;; *) echo unknown;; esac
}
test_start "Empty status classifies as unknown (never silently ready/blocked)"
assert_equals "unknown" "$(classify "")"

# --- Rendered view degrades gracefully --------------------------------------------
# A view built from this tree: the good story under ready, the gaps under needs-attention
# (the headless story flagged "status unparsed", the empty epic named "Could not parse").
VIEW="$TEST_TMPDIR/docs/plans/epics-dependency-view.html"
mkdir -p "$(dirname "$VIEW")"
CONTENT='<section id="ready"><h2>Ready to pick up</h2><ul><li>Good story — 91-01-epic-partial</li></ul></section>'\
'<section id="needs-attention"><h2>Needs attention</h2>'\
'<div class="cpm-callout cpm-callout--warn">'\
'<p><span class="sev sev-major">status unparsed</span> Headless story — 91-01-epic-partial</p>'\
'<p>Could not parse: 91-02-epic-empty.md</p></div></section>'
sed "s#<!-- CPM:CONTENT -->#${CONTENT}#" "$TEMPLATE" > "$VIEW"

test_start "View renders a valid HTML5 document despite the malformed input"
OUT=$(check_valid_html "$VIEW"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "View is self-contained despite the malformed input"
OUT=$(check_self_contained "$VIEW"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "View consumes the shared template"
check_uses_shared_template "$VIEW"; assert_equals "0" "$?"

test_start "Missing-status story is flagged under Needs attention"
check_section_contains "$VIEW" needs-attention "Headless story"; assert_equals "0" "$?"

test_start "The gap is visibly flagged (status unparsed badge present)"
check_section_contains "$VIEW" needs-attention "status unparsed"; assert_equals "0" "$?"

test_start "The unparseable file is named under Needs attention"
check_section_contains "$VIEW" needs-attention "91-02-epic-empty.md"; assert_equals "0" "$?"

test_start "The well-formed story still renders under ready (partial data preserved)"
check_section_contains "$VIEW" ready "Good story"; assert_equals "0" "$?"

test_start "The flagged story is NOT mis-bucketed as ready (negative control)"
OUT=$(check_section_contains "$VIEW" ready "Headless story"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "NOT_IN_SECTION"

test_summary
