#!/bin/bash
# session-start-compact.sh — Re-inject CPM state after compaction
#
# Fires after compaction completes (SessionStart source: "compact").
# Reads session_id from JSON on stdin and injects the matching
# session-scoped progress file. Falls back to injecting all progress
# files if no match is found or JSON parsing fails.
# Stdout is injected into the fresh post-compaction context.

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)

# Always echo session ID if available
if [ -n "$SESSION_ID" ]; then
  echo "CPM_SESSION_ID: $SESSION_ID"
fi

STATE_DIR="$CLAUDE_PROJECT_DIR/docs/plans"

# Try exact match first
if [ -n "$SESSION_ID" ] && [ -f "$STATE_DIR/.cpm-progress-${SESSION_ID}.md" ]; then
  cat "$STATE_DIR/.cpm-progress-${SESSION_ID}.md"
  exit 0
fi

# Fallback: inject all progress files (handles no-match and parse failures)
found=0
for f in "$STATE_DIR"/.cpm-progress-*.md; do
  [ -f "$f" ] || continue
  found=1
  cat "$f"
done

# Legacy support: check for old single-file format
if [ "$found" -eq 0 ] && [ -f "$STATE_DIR/.cpm-progress.md" ]; then
  cat "$STATE_DIR/.cpm-progress.md"
fi
