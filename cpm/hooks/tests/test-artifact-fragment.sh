#!/bin/bash
# test-artifact-fragment.sh — Tests for check_valid_fragment in html-test-helpers.sh.
#
# These back Epic 41-01 Story 3's [integration] acceptance criteria (spec 41 R7).
#
# Spec 41 moves three outputs (status dashboard, epics dependency view, present
# communication) from local HTML files to pages published via the Artifact tool.
# A published page cannot be asserted against — it lives on claude.ai, not on disk.
# The one artefact that IS on disk is the body fragment written to the scratch path
# docs/plans/{skill}-artifact-{nn}-{slug}.html, so that fragment is where automated
# coverage of the artifact path has to live. Without this validator the pivot moves
# three outputs from validated to unvalidatable while the suite still reports green.
#
# Tests cover:
# - A well-formed fragment (leading <style>, content, no structural tags) passes
# - Each forbidden structural element is flagged individually
# - A fragment carrying an inline <script> export affordance still passes
# - External references are flagged (delegated to check_self_contained)
# - Returns 2 for a missing file

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/html-test-helpers.sh"

# assert_fragment_valid <file> <label> — check_valid_fragment accepts the file
# silently. rc and output are one claim, not two: a validator returning 0 while
# echoing a reason is as wrong as one returning 1, so they are asserted together
# under a single test_start. Splitting them would report more passes than tests
# run — the framework counts test_start once and every assert separately.
assert_fragment_valid() {
  test_start "$2"
  local out rc
  out=$(check_valid_fragment "$1"); rc=$?
  if [ "$rc" -eq 0 ] && [ -z "$out" ]; then
    test_pass
  else
    test_fail "expected rc 0 and no output, got rc $rc: $out"
  fi
}

# assert_fragment_rejects <file> <marker> <label> — the file is rejected AND the
# reason is named. The marker is what makes the assertion worth having: a
# validator failing for the wrong reason still satisfies a bare rc check.
assert_fragment_rejects() {
  test_start "$3"
  local out rc
  out=$(check_valid_fragment "$1"); rc=$?
  if [ "$rc" -eq 1 ] && [[ "$out" == *"$2"* ]]; then
    test_pass
  else
    test_fail "expected rc 1 containing '$2', got rc $rc: $out"
  fi
}

echo "Testing: check_valid_fragment (artifact body fragments)"
echo "======================================================="

# --- The happy path: a valid fragment ---

F="$TEST_TMPDIR/good.html"
cat > "$F" <<'EOF'
<style>
  :root { color-scheme: light dark; }
  .wrap { max-width: 60rem; margin: 0 auto; }
</style>
<main class="wrap">
  <h1>Project Status</h1>
  <p>7 of 9 epics complete.</p>
</main>
EOF
assert_fragment_valid "$F" "A leading <style> block plus content is a valid fragment"

# --- Each forbidden structural element ---

# The Artifact tool supplies its own document shell, so a fragment carrying any of
# these produces a structurally wrong published page. Checked one at a time so a
# failure names the specific element rather than "not a fragment".

F="$TEST_TMPDIR/doctype.html"
printf '<!doctype html>\n<style>body{}</style>\n<p>x</p>\n' > "$F"
assert_fragment_rejects "$F" "FORBIDDEN doctype" "A doctype declaration is forbidden"

F="$TEST_TMPDIR/html.html"
printf '<html lang="en">\n<style>body{}</style>\n' > "$F"
assert_fragment_rejects "$F" "FORBIDDEN <html>" "An opening <html> element is forbidden"

F="$TEST_TMPDIR/head.html"
printf '<head><title>x</title></head>\n<style>body{}</style>\n' > "$F"
assert_fragment_rejects "$F" "FORBIDDEN <head>" "A <head> element is forbidden"

F="$TEST_TMPDIR/body.html"
printf '<style>body{}</style>\n<body><p>x</p></body>\n' > "$F"
assert_fragment_rejects "$F" "FORBIDDEN <body>" "A <body> element is forbidden"

# The whole point of the validator: what check_valid_html accepts, this must reject.
F="$TEST_TMPDIR/document.html"
cat > "$F" <<'EOF'
<!doctype html>
<html lang="en">
<head><style>body{}</style></head>
<body><p>x</p></body>
</html>
EOF
assert_fragment_rejects "$F" "FORBIDDEN doctype" "A complete document is rejected as a fragment"

# --- Inline script is permitted; external resources are not ---

# Export affordances (copy-as-prompt / copy-as-JSON) are inline vanilla JS by
# convention. The CSP blocks external hosts, not inline script.
F="$TEST_TMPDIR/affordance.html"
cat > "$F" <<'EOF'
<style>.copy-btn { cursor: pointer; }</style>
<button type="button" class="copy-btn" data-prompt="/cpm:do docs/epics/05-epic-foo.md">Copy</button>
<script>
  document.addEventListener('click', function (e) {
    var b = e.target.closest('.copy-btn');
    if (b && navigator.clipboard) navigator.clipboard.writeText(b.dataset.prompt);
  });
</script>
EOF
assert_fragment_valid "$F" "An inline <script> export affordance is permitted"

F="$TEST_TMPDIR/external.html"
printf '<link rel="stylesheet" href="https://cdn.example.com/x.css">\n<p>x</p>\n' > "$F"
assert_fragment_rejects "$F" "EXTERNAL" "An external stylesheet is flagged"

F="$TEST_TMPDIR/datauri.html"
printf '<style>body{}</style>\n<img src="data:image/gif;base64,R0lGOD">\n' > "$F"
assert_fragment_valid "$F" "A data: URI image is not flagged"

# --- Missing file ---

# rc 2 rather than 1: a missing file is a caller error, not a malformed fragment.
# Kept inline — neither helper covers this third return code.
test_start "check_valid_fragment returns rc 2 for a missing file"
OUT=$(check_valid_fragment "$TEST_TMPDIR/no-such-file.html"); RC=$?
if [ "$RC" -eq 2 ] && [[ "$OUT" == *"FILE_NOT_FOUND"* ]]; then
  test_pass
else
  test_fail "expected rc 2 containing FILE_NOT_FOUND, got rc $RC: $OUT"
fi

# --- The scratch path the convention names ---

# docs/plans/{skill}-artifact-{nn}-{slug}.html — the path Artifact Publishing names.
mkdir -p "$TEST_TMPDIR/docs/plans"
F="$TEST_TMPDIR/docs/plans/status-artifact-41-project-dashboard.html"
printf '<style>.rag{}</style>\n<section id="at-a-glance"><h2>At a glance</h2></section>\n' > "$F"
assert_fragment_valid "$F" "A fragment at the documented scratch path validates"

test_summary
