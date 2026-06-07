#!/bin/bash
# test-epics-dependency-view.sh — Tests for cpm:epics' on-request dependency view,
# backing the Story 1 [integration] acceptance criteria of epic 34-02 (epics Dependency
# View):
#   - the view renders unblocked vs blocked stories correctly from epic-doc data
#   - the view is a self-contained HTML file using the Spec 1 shared template, generated
#     from the Markdown epic docs
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

TEMPLATE="$SCRIPT_DIR/../../assets/html/template.html"

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

# --- A dependency view rendered from the shared template --------------------------
# Built to reflect the reference classification above: each story under its section.
VIEW="$TEST_TMPDIR/docs/plans/epics-dependency-view.html"
mkdir -p "$(dirname "$VIEW")"
CONTENT='<section id="ready"><h2>Ready to pick up</h2><ul>'\
'<li>Ready work — 90-02-epic-active <button class="copy-btn" data-prompt="/cpm:do docs/epics/90-02-epic-active.md">Copy</button></li>'\
'<li>Cross-ready — 90-03-epic-cross</li></ul></section>'\
'<section id="blocked"><h2>Blocked</h2><ul>'\
'<li>Cross-blocked — 90-03-epic-cross (waiting on Epic 90-02-epic-active)</li></ul></section>'\
'<section id="inprogress"><h2>In progress</h2><ul><li>Underway work — 90-02-epic-active</li></ul></section>'\
'<section id="complete"><h2>Complete</h2><ul><li>Finished work — 90-01-epic-done</li></ul></section>'
sed "s#<!-- CPM:CONTENT -->#${CONTENT}#" "$TEMPLATE" \
  | sed "s#</head>#<script>document.addEventListener('click',function(e){var b=e.target.closest('.copy-btn');if(b\&\&navigator.clipboard)navigator.clipboard.writeText(b.dataset.prompt);});</script></head>#" \
  > "$VIEW"

test_start "View consumes the shared template (bears signature)"
OUT=$(check_uses_shared_template "$VIEW"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "View is self-contained even with inline Tier 2 JS (no external refs)"
OUT=$(check_self_contained "$VIEW"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "View is valid HTML5"
OUT=$(check_valid_html "$VIEW"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

# --- Rendered placement agrees with the classification ----------------------------

test_start "Ready stories render under the ready section"
check_section_contains "$VIEW" ready "Ready work"; assert_equals "0" "$?"
check_section_contains "$VIEW" ready "Cross-ready"; assert_equals "0" "$?"

test_start "Blocked story renders under the blocked section"
check_section_contains "$VIEW" blocked "Cross-blocked"; assert_equals "0" "$?"

test_start "In progress story renders under the inprogress section"
check_section_contains "$VIEW" inprogress "Underway work"; assert_equals "0" "$?"

test_start "Complete story renders under the complete section"
check_section_contains "$VIEW" complete "Finished work"; assert_equals "0" "$?"

test_start "A ready story is NOT misplaced under blocked (negative control)"
OUT=$(check_section_contains "$VIEW" blocked "Ready work"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "NOT_IN_SECTION"

test_start "An absent section is reported (negative control)"
OUT=$(check_section_contains "$VIEW" nonexistent "anything"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "SECTION_NOT_FOUND"

# --- Read-only: generating the view must not mutate any epic doc ------------------

test_start "Every epic doc is unchanged after a read-only generation step"
BEFORE_01=$(md_content_hash "$EPICS_DIR/90-01-epic-done.md")
BEFORE_02=$(md_content_hash "$EPICS_DIR/90-02-epic-active.md")
BEFORE_03=$(md_content_hash "$EPICS_DIR/90-03-epic-cross.md")
# Read-only "regeneration": rewrite only the HTML view, touch no epic doc.
sed "s#<!-- CPM:CONTENT -->#${CONTENT}#" "$TEMPLATE" > "$VIEW"
check_source_unchanged "$EPICS_DIR/90-01-epic-done.md" "$BEFORE_01"; R1=$?
check_source_unchanged "$EPICS_DIR/90-02-epic-active.md" "$BEFORE_02"; R2=$?
check_source_unchanged "$EPICS_DIR/90-03-epic-cross.md" "$BEFORE_03"; R3=$?
assert_equals "0" "$R1"
assert_equals "0" "$R2"
assert_equals "0" "$R3"

test_start "A mutated epic doc is detected (negative control)"
BEFORE=$(md_content_hash "$EPICS_DIR/90-02-epic-active.md")
printf '\n## Sneaky appended story\n' >> "$EPICS_DIR/90-02-epic-active.md"
OUT=$(check_source_unchanged "$EPICS_DIR/90-02-epic-active.md" "$BEFORE"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "SOURCE_MODIFIED"

test_summary
