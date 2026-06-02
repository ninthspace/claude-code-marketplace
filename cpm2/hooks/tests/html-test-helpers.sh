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
