#!/bin/bash
# conventions-core.sh — emit a bounded extract of the shared skill conventions.
#
# Usage: bash conventions-core.sh <path-to-skill-conventions.md>
#
# Both SessionStart hooks inject the conventions, and both used to `cat` the file whole.
# It is 45 KB and growing, and past a size the harness does not document it stops inlining
# a hook's output and shows a short preview instead — so what a session actually received
# was the opening section and a piece of the second. The rest was persisted to a file
# nothing reads, which is absent in every way that matters and loud in none.
# Measurements, and what is known versus inferred: docs/maintenance/README.md.
#
# So this emits three things instead of the file:
#
#   1. The path, stated as a path, with an instruction to read it. A skill that says
#      "follow the shared X procedure" is naming a procedure that is NOT in context, and
#      a procedure followed from memory is a procedure invented.
#   2. The section index, one line each. Cheap, and it tells a reader what is on disk to
#      go and get — a pointer to a file whose contents are unguessable is a weak pointer.
#   3. The sections in CORE_SECTIONS, in full.
#
# CORE_SECTIONS is the answer to one question: which rules must hold in a session where
# no CPM skill is ever invoked? Conversational Output and Implementation Guidelines
# govern how every reply and every edit is made, skill or no skill. The closing note is
# about the two above it. Everything else in the file — Roster Loading, Library Check,
# the Retro procedures, Progress File Management, Numbering, Gate Presentation — is
# reached only from a skill that names it, and a skill that names it can read it.
#
# The order is the file's own. The closing note says it applies to everything above it,
# which stays true of an extract only while it is emitted last.

CONVENTIONS_FILE="$1"
[ -f "$CONVENTIONS_FILE" ] || exit 0

CORE_SECTIONS="Conversational Output
Implementation Guidelines
A Closing Note on Length and Tone"

# Emit one `## `-delimited section. Matches the heading exactly rather than by prefix, so
# `## Retro Awareness` cannot be served in place of `## Retro`.
emit_section() {
  awk -v want="## $2" '
    $0 == want { inside = 1; print; next }
    inside && /^## / { exit }
    inside { print }
  ' "$1"
}

echo ""
echo "# CPM Shared Skill Conventions"
echo ""
echo "The sections below apply whether or not a CPM skill is ever invoked. They are a"
echo "SUBSET. The rest are on disk and are NOT in your context:"
echo ""
echo "    $CONVENTIONS_FILE"
echo ""
echo "**When a skill says \"follow the shared X procedure\", read that file first** — the"
echo "procedure is there and not here, and one followed from memory is one invented. It"
# The index as running text rather than a bulleted list. It exists so a reader knows what
# is on disk to go and get, which one line per name does not do any better than commas do,
# and at 17 sections the list shape costs about 200 characters of pure indentation.
printf 'also holds: %s.\n' "$(grep '^## ' "$CONVENTIONS_FILE" | sed 's/^## //' | paste -sd, - | sed 's/,/, /g')"

while IFS= read -r section; do
  [ -z "$section" ] && continue
  echo ""
  emit_section "$CONVENTIONS_FILE" "$section"
done <<EOF
$CORE_SECTIONS
EOF
