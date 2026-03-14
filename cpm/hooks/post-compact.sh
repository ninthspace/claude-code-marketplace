#!/bin/bash
# post-compact.sh — Save compact summary after compaction
#
# Fires on PostCompact. Reads session_id and compact_summary from
# JSON on stdin and writes the summary to a companion file alongside
# the progress file. SessionStart (compact) will re-inject this
# summary into fresh post-compaction context.
# If compact_summary is missing or empty, no file is written.

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
COMPACT_SUMMARY=$(echo "$INPUT" | jq -r '.compact_summary // empty' 2>/dev/null)
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "unknown"' 2>/dev/null)

# Nothing to save if no summary
if [ -z "$COMPACT_SUMMARY" ]; then
  exit 0
fi

STATE_DIR="$CLAUDE_PROJECT_DIR/docs/plans"

# Determine filename — session-scoped if available, fallback otherwise
if [ -n "$SESSION_ID" ]; then
  SUMMARY_FILE="$STATE_DIR/.cpm-compact-summary-${SESSION_ID}.md"
else
  SUMMARY_FILE="$STATE_DIR/.cpm-compact-summary.md"
fi

# Ensure directory exists
mkdir -p "$STATE_DIR"

# Write summary with minimal header
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
cat > "$SUMMARY_FILE" <<EOF
# Compact Summary (PostCompact)
**Captured**: $TIMESTAMP
**Trigger**: $TRIGGER

$COMPACT_SUMMARY
EOF
