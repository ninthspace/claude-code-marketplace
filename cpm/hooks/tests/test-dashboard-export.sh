#!/bin/bash
# test-dashboard-export.sh — Tests for the Tier 2 export affordances, backing the Story 1
# [integration] acceptance criteria of epic 34-03 (Dashboard Export & Interactivity):
#   - when present, an export action produces a valid, copy-pasteable prompt / well-formed JSON
#   - export uses inline vanilla JS only — no external script, framework, or build artifact
#   - no document interaction writes back to any source doc (read-only/export-only)
#
# The remaining criterion — "clicking export in a browser copies the expected content" — is
# [manual]; a browser/JS interaction harness is deferred per the spec, so it is verified by
# inspection at the gate, not here. These tests cover everything deterministic: the embedded
# payloads are well-formed, the script is inline-only, and the export path cannot write back.
#
# Exercises check_valid_json / extract_json_block (added to html-test-helpers.sh) plus the
# existing check_self_contained / check_uses_shared_template / check_valid_html and the
# md_content_hash / check_source_unchanged immutability pair.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/html-test-helpers.sh"

TEMPLATE="$SCRIPT_DIR/../../assets/html/template.html"

echo "Testing: dashboard export affordances (Tier 2)"
echo "=============================================="

# --- A tracking document with copy-as-prompt + copy-as-JSON export ----------------
# Built per the shared "Tier 2 export affordances" convention: a copy-as-prompt button
# carrying a runnable command in data-prompt, a copy-as-JSON button, an embedded
# <script type="application/json"> snapshot, and one inline delegated click handler whose
# only effect is navigator.clipboard.writeText — no external script, no write-back path.
DOC="$TEST_TMPDIR/docs/plans/status-dashboard.html"
mkdir -p "$(dirname "$DOC")"

JSON_SNAPSHOT='{"complete":3,"total":5,"ready":["05-epic-foo","06-epic-bar"]}'
CONTENT='<section id="next"><h2>Recommended next steps</h2>'\
'<button type="button" class="copy-btn" data-prompt="/cpm:do docs/epics/05-epic-foo.md">Copy next step</button>'\
'<button type="button" class="copy-btn" data-json-target="export-data">Copy as JSON</button>'\
'<script type="application/json" id="export-data">'"$JSON_SNAPSHOT"'</script>'\
'</section>'
EXPORT_JS='<script>'\
'document.addEventListener("click",function(e){'\
'var b=e.target.closest(".copy-btn");if(!b)return;'\
'var payload=b.dataset.jsonTarget?document.getElementById(b.dataset.jsonTarget).textContent:b.dataset.prompt;'\
'if(navigator.clipboard)navigator.clipboard.writeText(payload);'\
'});</script>'
sed "s#<!-- CPM:CONTENT -->#${CONTENT}#" "$TEMPLATE" \
  | sed "s#</head>#${EXPORT_JS}</head>#" \
  > "$DOC"

# --- Inline-JS-only / self-contained ----------------------------------------------

test_start "Export document consumes the shared template"
check_uses_shared_template "$DOC"; assert_equals "0" "$?"

test_start "Export document is valid HTML5"
check_valid_html "$DOC"; assert_equals "0" "$?"

test_start "Export uses inline JS only — document stays self-contained"
OUT=$(check_self_contained "$DOC"); RC=$?
assert_equals "0" "$RC"
assert_empty "$OUT"

test_start "No external script tag is present (inline-only)"
assert_not_contains "$(cat "$DOC")" "<script src"

test_start "An external export script would break self-containment (negative control)"
BADDOC="$TEST_TMPDIR/docs/plans/export-bad.html"
sed 's#</head>#<script src="https://cdn.example.com/export.js"></script></head>#' "$DOC" > "$BADDOC"
OUT=$(check_self_contained "$BADDOC"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "EXTERNAL script"

# --- Valid, copy-pasteable prompt -------------------------------------------------

test_start "Copy-as-prompt payload is a runnable /cpm: command"
assert_contains "$(cat "$DOC")" 'data-prompt="/cpm:do docs/epics/05-epic-foo.md"'

# --- Well-formed JSON export ------------------------------------------------------

test_start "Embedded JSON export block extracts and is well-formed"
JSON=$(extract_json_block "$DOC")
OUT=$(check_valid_json "$JSON"); RC=$?
assert_equals "0" "$RC"

test_start "Extracted JSON carries the expected snapshot data"
assert_contains "$JSON" '"ready"'

test_start "Malformed JSON is rejected (negative control)"
OUT=$(check_valid_json '{"ready": [unquoted,]}'); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "INVALID_JSON"

# --- Read-only / export-only ------------------------------------------------------
# The interaction's only effect is the clipboard: assert the handler uses writeText and
# carries no write-back / network constructs.

test_start "Export handler copies to the clipboard (writeText present)"
assert_contains "$(cat "$DOC")" "navigator.clipboard.writeText"

test_start "Export handler has no network/write-back path (no fetch)"
assert_not_contains "$(cat "$DOC")" "fetch("

test_start "Export handler has no XMLHttpRequest write-back path"
assert_not_contains "$(cat "$DOC")" "XMLHttpRequest"

# --- Source immutability: generating/exporting never mutates a source doc ---------
EPICS_DIR="$TEST_TMPDIR/docs/epics"
mkdir -p "$EPICS_DIR"
printf '# Foo\n\n**Status**: Pending\n\n## Story\n**Status**: Pending\n**Blocked by**: —\n' > "$EPICS_DIR/05-epic-foo.md"

test_start "Source epic doc is unchanged after a read-only generation step"
BEFORE=$(md_content_hash "$EPICS_DIR/05-epic-foo.md")
# Regenerate the export document; touch no source.
sed "s#<!-- CPM:CONTENT -->#${CONTENT}#" "$TEMPLATE" | sed "s#</head>#${EXPORT_JS}</head>#" > "$DOC"
check_source_unchanged "$EPICS_DIR/05-epic-foo.md" "$BEFORE"; assert_equals "0" "$?"

test_start "A mutated source is detected (negative control)"
BEFORE=$(md_content_hash "$EPICS_DIR/05-epic-foo.md")
printf '\nAppended.\n' >> "$EPICS_DIR/05-epic-foo.md"
OUT=$(check_source_unchanged "$EPICS_DIR/05-epic-foo.md" "$BEFORE"); RC=$?
assert_equals "1" "$RC"
assert_contains "$OUT" "SOURCE_MODIFIED"

test_summary
