#!/bin/bash
# html-test-helpers.sh — Reusable HTML validation checks for CPM HTML artifacts.
#
# These checks back the [integration] acceptance criteria for HTML output across
# the projection epics (33-02/03/04) and Spec 2's dashboards. They are a library,
# not a test suite: source this file *after* test-helpers.sh. The filename does not
# match the `test-*.sh` glob, so run-all-tests.sh never executes it standalone.
#
# Provided checks:
#   check_self_contained <file>            — fail if the HTML loads external CSS/JS/image/font resources
#   md_content_hash <file>                 — print a content hash for a source file
#   check_source_unchanged <file> <hash>   — fail if the file's content changed since <hash> was taken
#   check_valid_html <file>                — fail if the file is not a well-formed HTML5 document
#
# Each check prints offending findings to stdout and signals via exit status, so it
# is usable both inside the bash test framework and as a standalone guard in tooling.

# --- Self-containment validator -------------------------------------------------
#
# A self-contained HTML file inlines everything it needs to render: styles, scripts,
# images, and fonts. It may still hyperlink to external sites (<a href>) — navigation
# does not affect rendering — and may embed resources as data: URIs.
#
# check_self_contained scans for resource-loading constructs that would require a
# network or filesystem fetch to render:
#   - <script src="...">        external/relative script
#   - <link href="...">         stylesheet, icon, preconnect, font link
#   - <img src="...">           external/relative image
#   - CSS url(...)              background images, @font-face sources
#   - @import "..."             imported stylesheets
#
# A reference is allowed only when it is a data: URI (inlined) or a pure #fragment.
# Any other value — absolute (http://, https://, //) or relative (styles.css) — is a
# violation, because a self-contained file must not depend on a sibling resource.
#
# Returns: 0 if self-contained, 1 if any external reference found (each printed as
# "EXTERNAL <kind>: <ref>"), 2 if the file does not exist.

_html_extract_refs() {
  # Emits "kind|value" lines for every resource-loading reference in the file.
  local file="$1"
  local value='("[^"]*"|'\''[^'\'']*'\''|[^[:space:]>]+)'

  # <script ... src=VALUE>
  grep -ioE "<script[^>]*src=$value" "$file" 2>/dev/null \
    | sed -E 's/.*[sS][rR][cC]=//; s/^["'\'']//; s/["'\'']$//' \
    | sed 's/^/script|/'

  # <link ... href=VALUE>
  grep -ioE "<link[^>]*href=$value" "$file" 2>/dev/null \
    | sed -E 's/.*[hH][rR][eE][fF]=//; s/^["'\'']//; s/["'\'']$//' \
    | sed 's/^/link|/'

  # <img ... src=VALUE>
  grep -ioE "<img[^>]*src=$value" "$file" 2>/dev/null \
    | sed -E 's/.*[sS][rR][cC]=//; s/^["'\'']//; s/["'\'']$//' \
    | sed 's/^/img|/'

  # CSS url(VALUE) — backgrounds, @font-face sources
  grep -ioE 'url\([^)]*\)' "$file" 2>/dev/null \
    | sed -E 's/^url\(//I; s/\)$//; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^["'\'']//; s/["'\'']$//' \
    | sed 's/^/css-url|/'

  # @import "VALUE"  or  @import VALUE
  grep -ioE '@import[[:space:]]+("[^"]*"|'\''[^'\'']*'\'')' "$file" 2>/dev/null \
    | sed -E 's/@import[[:space:]]+//I; s/^["'\'']//; s/["'\'']$//' \
    | sed 's/^/import|/'
}

check_self_contained() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "FILE_NOT_FOUND: $file"
    return 2
  fi

  local found=0
  local kind value
  while IFS='|' read -r kind value; do
    [ -z "$value" ] && continue
    case "$value" in
      data:*) ;;   # inlined resource — self-contained
      "#"*)   ;;   # pure fragment — no fetch
      *) echo "EXTERNAL $kind: $value"; found=1 ;;
    esac
  done < <(_html_extract_refs "$file")

  return $found
}

# --- Source-immutability check --------------------------------------------------
#
# Enforces "generate-from-source, never replace": an HTML generation step must read
# the source Markdown but never mutate or replace it. The check is hash-based — take
# a content hash before generation, run the step, then confirm the hash is unchanged.
#
#   before=$(md_content_hash spec.md)
#   ... run the HTML generation step ...
#   check_source_unchanged spec.md "$before"   # rc 0 = untouched, 1 = mutated
#
# md_content_hash prefers sha256sum (Linux) and falls back to `shasum -a 256` (macOS),
# emitting only the hex digest. Returns 2 if neither tool is available.

md_content_hash() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "FILE_NOT_FOUND: $file"
    return 2
  fi
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    echo "NO_HASH_TOOL"
    return 2
  fi
}

# Returns: 0 if the file's current content hash matches <before_hash> (unchanged),
# 1 if it differs (the source was mutated), 2 if the file is missing or unhashable.
check_source_unchanged() {
  local file="$1"
  local before="$2"
  local after
  after=$(md_content_hash "$file") || return 2
  if [ "$after" = "$before" ]; then
    return 0
  fi
  echo "SOURCE_MODIFIED: $file"
  echo "  before: $before"
  echo "  after:  $after"
  return 1
}

# --- HTML validity check --------------------------------------------------------
#
# A lightweight well-formedness check for the kind of self-contained document CPM2
# generates — not a full HTML validator, but enough to catch a truncated or
# structurally broken template/render. Confirms the document declares HTML5 and
# carries the core structural elements: a doctype, an <html> element (opened and
# closed), <head>, <body>, and an inline <style> block (every CPM2 HTML file styles
# itself inline, since external stylesheets are forbidden by the self-contained rule).
#
# Returns: 0 if all required markers are present, 1 if any are missing (each printed
# as "MISSING <marker>"), 2 if the file does not exist.

check_valid_html() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "FILE_NOT_FOUND: $file"
    return 2
  fi

  local missing=0
  # marker label | case-insensitive extended regex it must match
  local checks='doctype|<!doctype html
opening <html>|<html[^>]*>
closing </html>|</html>
<head>|<head[^>]*>
<body>|<body[^>]*>
inline <style>|<style[^>]*>'

  local label pattern
  while IFS='|' read -r label pattern; do
    [ -z "$label" ] && continue
    if ! grep -iqE "$pattern" "$file"; then
      echo "MISSING $label"
      missing=1
    fi
  done <<EOF
$checks
EOF

  return $missing
}

# --- Companion-asset path convention --------------------------------------------
#
# Companion assets are stored at docs/{type}/assets/{nn}-{slug}-{label}.html, where
# {type} is the artifact directory (specifications, architecture, …), {nn} is the
# source artifact's number, and {slug}/{label} are kebab-case. {label} distinguishes
# multiple assets for one artifact, so the filename carries a numeric prefix followed
# by at least two kebab segments (the slug and the label).
#
# This is a pure string check on the path shape — it does not require the file to
# exist (see check_reference_resolves for on-disk resolution).
#
# Returns: 0 if <path> matches the convention, 1 if not (printing "BAD_ASSET_PATH").
check_asset_path() {
  local path="$1"
  if printf '%s\n' "$path" | grep -qE '^docs/[a-z0-9_-]+/assets/[0-9]+(-[a-z0-9]+){2,}\.html$'; then
    return 0
  fi
  echo "BAD_ASSET_PATH: $path (expected docs/{type}/assets/{nn}-{slug}-{label}.html)"
  return 1
}

# --- Companion-asset reference resolution ---------------------------------------
#
# A companion asset is referenced from its Markdown artifact by a stable relative
# path. This is the seam epics/do rely on: the path written into the Markdown must
# resolve to the asset on disk. Given the Markdown file and a relative reference,
# this confirms (1) the reference text appears in the Markdown, and (2) the reference
# resolves to an existing file when taken relative to the Markdown file's directory.
#
#   check_reference_resolves spec.md "assets/05-spec-foo-mockup.html"
#
# Returns: 0 if the ref is present and resolves, 1 if it is absent or unresolved,
# 2 if the Markdown file does not exist.
check_reference_resolves() {
  local md="$1" ref="$2"
  if [ ! -f "$md" ]; then
    echo "FILE_NOT_FOUND: $md"
    return 2
  fi
  if ! grep -qF -- "$ref" "$md"; then
    echo "REF_ABSENT: '$ref' not referenced in $md"
    return 1
  fi
  local dir resolved
  dir="$(cd "$(dirname "$md")" && pwd)"
  resolved="$dir/$ref"
  if [ -f "$resolved" ]; then
    return 0
  fi
  echo "REF_UNRESOLVED: '$ref' -> $resolved (no such file)"
  return 1
}

# --- Shared-template consumption check ------------------------------------------
#
# Output that PRESENTS a CPM2 artifact — faithful renders, present communications,
# and documentation diagrams that *explain* an artifact — must consume the one shared
# template (cpm/assets/html/template.html), not a forked stylesheet. The template
# stamps a stable signature into its <head>: <meta name="generator"
# content="CPM2 shared HTML template">. Consumers substitute the body tokens but leave
# the <head> intact, so the signature survives.
#
# This check also expresses the inverse contract for the deliverable-functionality
# mockup carve-out: a system-specific mockup is built standalone and must NOT bear the
# shared signature (it wears the target system's design, not CPM2's documentation
# chrome). Such a mockup is still self-contained — assert that with check_self_contained.
#
# Returns: 0 if the file bears the shared-template signature, 1 if not, 2 if missing.
check_uses_shared_template() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "FILE_NOT_FOUND: $file"
    return 2
  fi
  if grep -iqE '<meta[^>]*name=["'\'']?generator["'\'']?[^>]*content=["'\'']?CPM2 shared HTML template' "$file"; then
    return 0
  fi
  echo "NO_SHARED_TEMPLATE: $file"
  return 1
}

# --- Faithful-render path convention --------------------------------------------
#
# A faithful render — a navigable HTML view of a whole spec / ADR / review — is stored
# at docs/{type}/html/{nn}-{slug}.html, where {type} is the artifact directory
# (specifications, architecture, reviews, …) and {nn}/{slug} match the source Markdown's
# number and slug. Unlike a companion asset (which carries a distinguishing {label},
# so {nn}-{slug}-{label}), a render mirrors a single source artifact, so its filename is
# just {nn}-{slug} — a number plus the slug.
#
# This is a pure string check on the path shape; it does not require the file to exist.
#
# Returns: 0 if <path> matches the convention, 1 if not (printing "BAD_RENDER_PATH").
check_render_path() {
  local path="$1"
  if printf '%s\n' "$path" | grep -qE '^docs/[a-z0-9_-]+/html/[0-9]+(-[a-z0-9]+)+\.html$'; then
    return 0
  fi
  echo "BAD_RENDER_PATH: $path (expected docs/{type}/html/{nn}-{slug}.html)"
  return 1
}

# --- Section membership check ---------------------------------------------------
#
# Tracking documents group items into <section id="..."> blocks (e.g. a dependency view's
# "ready" vs "blocked" sections, a status grid's panels). This check confirms a given item
# is rendered under the expected section — the oracle for "renders X vs Y correctly" without
# a browser. It extracts the block from the element bearing id="<section>" up to the next
# </section> close, then looks for <needle> (a fixed string) within that block.
#
#   check_section_contains view.html ready "Ready work"     # 0 if "Ready work" is under id=ready
#
# Pair the positive assertion with a negative one (the same needle must NOT appear under the
# opposite section) to prove correct placement, not mere presence.
#
# Returns: 0 if <needle> appears within the section, 1 if the section exists but lacks it
# (NOT_IN_SECTION) or the section is absent (SECTION_NOT_FOUND), 2 if the file is missing.
check_section_contains() {
  local file="$1" section="$2" needle="$3"
  if [ ! -f "$file" ]; then
    echo "FILE_NOT_FOUND: $file"
    return 2
  fi
  # Flatten newlines first so extraction is newline-agnostic — works on both
  # pretty-printed and minified single-line HTML.
  local flat block
  flat=$(tr '\n' ' ' < "$file")
  case "$flat" in
    *"id=\"$section\""*) ;;
    *) echo "SECTION_NOT_FOUND: id=$section in $file"; return 1 ;;
  esac
  # block = substring from the id marker up to the first </section> that follows it.
  block=${flat#*id=\"$section\"}
  block=${block%%</section>*}
  if printf '%s' "$block" | grep -qF -- "$needle"; then
    return 0
  fi
  echo "NOT_IN_SECTION: '$needle' not found under id=$section"
  return 1
}

# --- Tracking-document count agreement ------------------------------------------
#
# A `status` full-picture HTML document and the stdout narrative are synthesised from
# one read-only scan, so their figures must agree (Spec 34, [integration]). The document
# states the headline figure in a canonical form — "{complete} of {total} epics complete"
# — and this check confirms that exact pairing is present for the expected counts. Pass
# the counts derived from the same scan/fixtures; a document that rendered a different
# figure (a disagreement, or a generation bug) fails the check.
#
#   check_counts_agree dashboard.html 46 50
#
# Returns: 0 if the document states "<complete> of <total> epics complete", 1 if it does
# not (printing "COUNTS_DISAGREE"), 2 if the file does not exist.
check_counts_agree() {
  local file="$1" complete="$2" total="$3"
  if [ ! -f "$file" ]; then
    echo "FILE_NOT_FOUND: $file"
    return 2
  fi
  if grep -qE "${complete}[[:space:]]+of[[:space:]]+${total}[[:space:]]+epics[[:space:]]+complete" "$file"; then
    return 0
  fi
  echo "COUNTS_DISAGREE: expected '${complete} of ${total} epics complete' in $file"
  return 1
}

# --- JSON validity (Tier 2 copy-as-JSON export) ---------------------------------
#
# A Tier 2 tracking document's copy-as-JSON export must produce well-formed JSON. This
# validates a JSON string, preferring python3 and falling back to node (the self-contained
# documents ship no JSON tool of their own — validation is a test-time concern).
#
#   check_valid_json '{"ready": ["05-epic-foo"]}'
#
# Returns: 0 if <text> parses as JSON, 1 if it does not (printing INVALID_JSON),
# 2 if neither python3 nor node is available (printing NO_JSON_TOOL).
check_valid_json() {
  local text="$1"
  if command -v python3 >/dev/null 2>&1; then
    if printf '%s' "$text" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; then
      return 0
    fi
    echo "INVALID_JSON"; return 1
  elif command -v node >/dev/null 2>&1; then
    if printf '%s' "$text" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{JSON.parse(s)}catch(e){process.exit(1)}})' 2>/dev/null; then
      return 0
    fi
    echo "INVALID_JSON"; return 1
  fi
  echo "NO_JSON_TOOL"; return 2
}

# --- Extract an embedded JSON export block --------------------------------------
#
# Tier 2 copy-as-JSON export embeds its snapshot at generation time in a
# <script type="application/json">…</script> block (read by the inline handler, never
# fetched). This prints the content of the first such block so a test can validate it with
# check_valid_json. Tolerant of attribute order/spacing and multi-line content; prints
# nothing if no such block exists.
extract_json_block() {
  local file="$1"
  awk 'BEGIN{RS="</script>"}
    /type="application\/json"/ { sub(/.*type="application\/json"[^>]*>/,""); print; exit }' "$file"
}

# --- present HTML communication path convention ---------------------------------
#
# `present`'s HTML output is written alongside its Markdown communication at
# docs/communications/{nn}-{format}-{slug}.html — {nn} is the communication's number,
# {format} the kebab format name (summary-memo, onboarding-guide, …), and {slug} a short
# content slug. The filename therefore carries a number plus at least two kebab segments
# (the format and the slug). Unlike a faithful render, the communications directory is
# flat (no per-type html/ subdir), since present output is not per-artifact-type.
#
# This is a pure string check on the path shape; it does not require the file to exist.
#
# Returns: 0 if <path> matches the convention, 1 if not (printing "BAD_COMMUNICATION_PATH").
check_communication_path() {
  local path="$1"
  if printf '%s\n' "$path" | grep -qE '^docs/communications/[0-9]+(-[a-z0-9]+){2,}\.html$'; then
    return 0
  fi
  echo "BAD_COMMUNICATION_PATH: $path (expected docs/communications/{nn}-{format}-{slug}.html)"
  return 1
}
