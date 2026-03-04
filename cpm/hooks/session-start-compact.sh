#!/bin/bash
# session-start-compact.sh — Re-inject CPM state after compaction
#
# Fires on SessionStart source: "compact" or "clear".
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

# Resolve user name: $CPM_USER_NAME env → git config first name → silent fallback
if [ -n "$CPM_USER_NAME" ]; then
  USER_NAME="$CPM_USER_NAME"
else
  GIT_NAME=$(git config user.name 2>/dev/null)
  if [ -n "$GIT_NAME" ]; then
    USER_NAME="${GIT_NAME%% *}"
  fi
fi
if [ -n "$USER_NAME" ]; then
  echo "CPM_USER_NAME: $USER_NAME"
  echo "When addressing the user in conversation, use their name \"$USER_NAME\" instead of \"the user\"."
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
