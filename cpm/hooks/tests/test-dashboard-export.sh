#!/bin/bash
# test-dashboard-export.sh — Tests for the export affordances a published artifact
# carries: copy-as-prompt and copy-as-JSON.
#
# Originally written for epic 34-03, where the affordances lived on a local HTML
# tracking document built from cpm/assets/html/template.html. Spec 41 moved the host:
# the status full picture and the epics dependency view are now pages published via
# the Artifact tool, composed per `artifact-design` as **body fragments** that never
# consume the shared template. Reworked here in epic 41-04 rather than deleted,
# because the affordances themselves survive the pivot — only what they sit inside
# changed.
#
# What changed with the host, and what did not:
# - Dropped: check_uses_shared_template and check_valid_html. Both asserted the
#   retired document shape. A fragment has no <head> to carry the template signature
#   and no <!doctype> to validate; asserting either now would fail a correct artifact.
# - Kept: payload well-formedness, inline-JS-only, no write-back, and source
#   immutability. These are properties of the export affordance, not of its host.
#
# The clipboard path these assertions describe is verified working in-frame as of
# 2026-07-25 (epic 41-02 published a probe page; both copy controls wrote successfully
# inside the cross-origin artifact frame). Notably `permissions.query("clipboard-write")`
# reported unsupported on that engine while writeText succeeded — which is why the
# handler asserted below guards on `navigator.clipboard` and never on the permissions
# query.
#
# The remaining criterion — "clicking export in a browser copies the expected content"
# — is [manual]; it is now answered by that probe rather than by a harness here.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/html-test-helpers.sh"

echo "Testing: artifact export affordances"
echo "===================================="

# --- A body fragment with copy-as-prompt + copy-as-JSON export --------------------
# Built per the shared "Artifact Publishing → Export affordances" convention: a
# copy-as-prompt button carrying a runnable command in data-prompt, a copy-as-JSON
# button, an embedded <script type="application/json"> snapshot, and one inline
# delegated click handler whose only effect is navigator.clipboard.writeText — no
# external script, no write-back path.
#
# The path is the scratch path the convention specifies for the fragment that gets
# published: docs/plans/{skill}-artifact-{nn}-{slug}.html. It is a build intermediate,
# which is exactly why it is the one on-disk artefact these tests can assert against.
DOC="$TEST_TMPDIR/docs/plans/status-artifact-full-picture.html"
mkdir -p "$(dirname "$DOC")"

JSON_SNAPSHOT='{"complete":3,"total":5,"ready":["05-epic-foo","06-epic-bar"]}'
cat > "$DOC" <<EOF
<style>
  :root { color-scheme: light dark; }
  .wrap { max-width: 60rem; margin: 0 auto; }
</style>
<main class="wrap">
  <section id="next"><h2>Recommended next steps</h2>
  <button type="button" class="copy-btn" data-prompt="/cpm:do docs/epics/05-epic-foo.md">Copy next step</button>
  <button type="button" class="copy-btn" data-json-target="export-data">Copy as JSON</button>
  <script type="application/json" id="export-data">${JSON_SNAPSHOT}</script>
  </section>
</main>
<script>
document.addEventListener("click",function(e){
var b=e.target.closest(".copy-btn");if(!b)return;
var payload=b.dataset.jsonTarget?document.getElementById(b.dataset.jsonTarget).textContent:b.dataset.prompt;
if(navigator.clipboard)navigator.clipboard.writeText(payload);
});
</script>
EOF

# --- The host is a valid fragment, not a document ---------------------------------

test_start "Export page is a valid body fragment"
# rc and output are one claim: a validator returning 0 while naming a reason is as
# wrong as one returning 1.
OUT=$(check_valid_fragment "$DOC"); RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  test_pass
else
  test_fail "expected rc 0 and no output, got rc $RC: $OUT"
fi

test_start "A fragment carrying structural tags is rejected (negative control)"
# Guards the rework itself: if this fixture drifted back to a full document, the
# fragment assertion above would be the thing that noticed.
BADFRAG="$TEST_TMPDIR/docs/plans/full-document.html"
{ printf '<!doctype html>\n<html><head><title>x</title></head><body>\n'; cat "$DOC"; printf '\n</body></html>\n'; } > "$BADFRAG"
OUT=$(check_valid_fragment "$BADFRAG"); RC=$?
if [ "$RC" -eq 1 ] && [ -n "$OUT" ]; then
  test_pass
else
  test_fail "expected rc 1 with a reason, got rc $RC: $OUT"
fi

# --- Inline-JS-only / self-contained ----------------------------------------------
# The artifact CSP blocks every external host, so self-containment stopped being a
# convention and became an enforcement: an external script does not degrade, it fails.

test_start "Export uses inline JS only — page stays self-contained"
OUT=$(check_self_contained "$DOC"); RC=$?
if [ "$RC" -eq 0 ] && [ -z "$OUT" ]; then
  test_pass
else
  test_fail "expected rc 0 and no output, got rc $RC: $OUT"
fi

test_start "No external script tag is present (inline-only)"
assert_not_contains "$(cat "$DOC")" "<script src"

test_start "An external export script would break self-containment (negative control)"
BADDOC="$TEST_TMPDIR/docs/plans/export-bad.html"
{ printf '<script src="https://cdn.example.com/export.js"></script>\n'; cat "$DOC"; } > "$BADDOC"
OUT=$(check_self_contained "$BADDOC"); RC=$?
if [ "$RC" -eq 1 ] && [[ "$OUT" == *"EXTERNAL script"* ]]; then
  test_pass
else
  test_fail "expected rc 1 naming EXTERNAL script, got rc $RC: $OUT"
fi

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
if [ "$RC" -eq 1 ] && [[ "$OUT" == *"INVALID_JSON"* ]]; then
  test_pass
else
  test_fail "expected rc 1 naming INVALID_JSON, got rc $RC: $OUT"
fi

# --- Read-only / export-only ------------------------------------------------------
# The interaction's only effect is the clipboard: assert the handler uses writeText and
# carries no write-back / network constructs.

test_start "Export handler copies to the clipboard (writeText present)"
assert_contains "$(cat "$DOC")" "navigator.clipboard.writeText"

test_start "Export handler guards on navigator.clipboard, not the permissions query"
# The 41-02 probe found permissions.query("clipboard-write") unsupported on an engine
# where writeText worked. Branching on it would disable a working control.
if grep -qF 'if(navigator.clipboard)' "$DOC" && ! grep -qF 'permissions.query' "$DOC"; then
  test_pass
else
  test_fail "handler is missing the navigator.clipboard guard, or gates on permissions.query"
fi

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
# Rewrite the fragment from the same inputs; touch no source.
touch "$DOC"
check_source_unchanged "$EPICS_DIR/05-epic-foo.md" "$BEFORE"; assert_equals "0" "$?"

test_start "A mutated source is detected (negative control)"
BEFORE=$(md_content_hash "$EPICS_DIR/05-epic-foo.md")
printf '\nAppended.\n' >> "$EPICS_DIR/05-epic-foo.md"
OUT=$(check_source_unchanged "$EPICS_DIR/05-epic-foo.md" "$BEFORE"); RC=$?
if [ "$RC" -eq 1 ] && [[ "$OUT" == *"SOURCE_MODIFIED"* ]]; then
  test_pass
else
  test_fail "expected rc 1 naming SOURCE_MODIFIED, got rc $RC: $OUT"
fi

test_summary
