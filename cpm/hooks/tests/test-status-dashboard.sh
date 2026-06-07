#!/bin/bash
# test-status-dashboard.sh — Tests for cpm:status's optional full-picture HTML document,
# backing the Story 2 [integration] acceptance criteria of epic 34-01 (status Tracking
# Dashboard):
#   - the document is self-contained and uses the shared template, not a forked stylesheet
#   - the document's completion counts agree with the data the stdout narrative reports
#   - cpm:status still produces its stdout narrative; the default path is unchanged
#   - (supporting the [manual] ephemeral criterion) the document is not saved unless asked
#
# Spec 34 is Tier 2: the document MAY carry inline vanilla JS (a copy-as-prompt affordance).
# The self-containment section deliberately exercises a document that includes inline JS,
# proving inline scripts do not break the self-contained guarantee.
#
# Exercises check_counts_agree (added to html-test-helpers.sh) plus the existing
# check_self_contained / check_uses_shared_template / check_valid_html checks, and guards
# the stdout-unchanged / ephemeral-default contract against the skill source.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/html-test-helpers.sh"

TEMPLATE="$SCRIPT_DIR/../../assets/html/template.html"
SKILL="$SCRIPT_DIR/../../skills/status/SKILL.md"

echo "Testing: status full-picture HTML document"
echo "=========================================="

# --- A representative status document, generated from the shared template ---------
#
# The document substitutes the shared template's body tokens while leaving its <head>
# (and generator signature) intact, and — being Tier 2 — carries an inline copy-as-prompt
# <script>. Simulate that by copying the real template, substituting CPM:CONTENT with the
# dashboard body, and injecting an inline (src-less) script before </head>, exactly as the
# validation prototype did.
DOC="$TEST_TMPDIR/docs/plans/status-dashboard.html"
mkdir -p "$(dirname "$DOC")"
BODY='<p class="lede">3 of 5 epics complete.</p>'\
'<section id="rag"><h2>At a glance</h2><span class="sev sev-minor">3 complete</span></section>'\
'<section id="grid"><h2>Completion grid</h2><table><tr><td>01</td><td>2/2</td></tr></table></section>'\
'<section id="next"><h2>Next steps</h2>'\
'<button type="button" class="copy-btn" data-prompt="/cpm:do docs/epics/05-epic-x.md">Copy</button></section>'
sed "s#<!-- CPM:CONTENT -->#${BODY}#" "$TEMPLATE" \
  | sed "s#</head>#<script>document.addEventListener('click',function(e){var b=e.target.closest('.copy-btn');if(b\&\&navigator.clipboard)navigator.clipboard.writeText(b.dataset.prompt);});</script></head>#" \
  > "$DOC"

test_start "Status document consumes the shared template (bears signature)"
OUT=$(check_uses_shared_template "$DOC"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "Status document is self-contained even with inline Tier 2 JS (no external refs)"
OUT=$(check_self_contained "$DOC"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "Status document is valid HTML5"
OUT=$(check_valid_html "$DOC"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "An external script would break self-containment (negative control)"
BADDOC="$TEST_TMPDIR/docs/plans/status-bad.html"
sed 's#</head>#<script src="https://cdn.example.com/app.js"></script></head>#' "$DOC" > "$BADDOC"
OUT=$(check_self_contained "$BADDOC"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "EXTERNAL script"

# --- Count agreement: same scan data drives narrative and document ----------------
#
# Build a fixture epics tree, independently derive the completion counts from it the way
# the skill's scan does (total = epic docs; complete = those whose epic-level Status is
# Complete), then assert the document states that exact "{complete} of {total} epics
# complete" figure. A document rendering a different figure (a disagreement) must fail.
EPICS_DIR="$TEST_TMPDIR/docs/epics"
mkdir -p "$EPICS_DIR"
printf '# Alpha\n\n**Status**: Complete\n'    > "$EPICS_DIR/01-epic-alpha.md"
printf '# Bravo\n\n**Status**: Complete\n'    > "$EPICS_DIR/02-epic-bravo.md"
printf '# Charlie\n\n**Status**: Complete\n'  > "$EPICS_DIR/03-epic-charlie.md"
printf '# Delta\n\n**Status**: In Progress\n' > "$EPICS_DIR/04-epic-delta.md"
printf '# Echo\n\n**Status**: Pending\n'      > "$EPICS_DIR/05-epic-echo.md"

# Reference scanner — mirrors the skill's epic deep-read (epic-level Status field).
scan_epic_counts() {
  local dir="$1" total=0 complete=0 f
  for f in "$dir"/[0-9]*-epic-*.md; do
    [ -f "$f" ] || continue
    total=$((total + 1))
    if grep -qiE '^\*\*Status\*\*:[[:space:]]*Complete' "$f"; then
      complete=$((complete + 1))
    fi
  done
  echo "$complete $total"
}
read -r SCAN_COMPLETE SCAN_TOTAL < <(scan_epic_counts "$EPICS_DIR")

test_start "Reference scan over the fixtures yields the expected counts (3 of 5)"
assert_equals "3" "$SCAN_COMPLETE"
assert_equals "5" "$SCAN_TOTAL"

test_start "Document figure agrees with the scan-derived counts"
OUT=$(check_counts_agree "$DOC" "$SCAN_COMPLETE" "$SCAN_TOTAL"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "A disagreeing figure is flagged (negative control)"
OUT=$(check_counts_agree "$DOC" "2" "$SCAN_TOTAL"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "COUNTS_DISAGREE"

# --- Stdout-path-unchanged contract (guarded against the skill source) ------------
#
# The HTML document is an opt-in extra; cpm:status must still produce its stdout
# narrative by default, with no HTML on the default path. A bash suite cannot invoke the
# skill, so guard the contract documented in SKILL.md — this catches a future regression
# that makes HTML the default or drops the stdout report.

test_start "Skill source exists"
if [ -f "$SKILL" ]; then test_pass; else test_fail "Expected skill at $SKILL"; fi

test_start "Skill still mandates the stdout narrative (Report Format section present)"
assert_contains "$(cat "$SKILL")" "Print the report to stdout"

test_start "Skill marks the HTML document as opt-in, never the default"
# Phase 4 runs only on request; the default run produces no HTML.
assert_contains "$(cat "$SKILL")" "only when the HTML document was requested"

test_start "Skill instructs not to generate HTML unless requested"
assert_contains "$(cat "$SKILL")" "Do **not** generate the HTML document unless it is requested"

# --- Ephemeral-default contract (supports the [manual] ephemeral criterion) -------

test_start "Skill documents the ephemeral default (not persisted unless asked)"
assert_contains "$(cat "$SKILL")" "must NOT be persisted unless the user asks"

test_start "Skill names the ephemeral scratch path, not a tracked artifact"
assert_contains "$(cat "$SKILL")" "docs/plans/status-dashboard.html"

test_summary
