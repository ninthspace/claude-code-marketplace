#!/bin/bash
# session-start-compact.sh — Re-inject CPM state after compaction
#
# Fires on SessionStart source: "compact" or "clear".
# Reads session_id from JSON on stdin and injects ONLY the current session's
# progress file as active state, using the shared classifier (lib/progress-
# classify.sh) as the single source of truth for "current". Other-session and
# stale files are never injected here: on compaction (same session id) the
# matching file is recovered; on /clear (a fresh session id) nothing old is
# silently resurrected as active state.
# After progress file injection, injects the compact summary file
# (written by post-compact.sh) if one exists — providing narrative
# context alongside structured state.
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

# Load shared skill conventions into context
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONVENTIONS_FILE="$PLUGIN_ROOT/shared/skill-conventions.md"
if [ -f "$CONVENTIONS_FILE" ]; then
  echo ""
  cat "$CONVENTIONS_FILE"
fi

STATE_DIR="$CLAUDE_PROJECT_DIR/docs/plans"
CLASSIFIER="$(cd "$(dirname "$0")" && pwd)/lib/progress-classify.sh"

# --- Progress file injection ---
# Inject ONLY the current session's file (classifier says CURRENT). There is no
# blanket cat-all fallback: other-session/stale files are never injected as
# active state, so /clear cannot silently resurrect them. On compaction the
# session id is unchanged, so the matching file is still recovered.

progress_found=0
if [ -f "$CLASSIFIER" ]; then
  records=$(CPM_SESSION_ID="$SESSION_ID" bash "$CLASSIFIER" "$STATE_DIR")
  while IFS=$'\t' read -r classification path skill phase age age_label; do
    [ "$classification" = "CURRENT" ] || continue
    cat "$path"
    progress_found=1
  done <<EOF
$records
EOF
fi

# Legacy support: check for old single-file format (pre session-scoped naming).
if [ "$progress_found" -eq 0 ] && [ -f "$STATE_DIR/.cpm-progress.md" ]; then
  cat "$STATE_DIR/.cpm-progress.md"
  progress_found=1
fi

# --- Compact summary injection ---
# Injected after progress file (structured state first, narrative supplement after).
# If no progress file exists, the summary is injected alone as fallback.

if [ -n "$SESSION_ID" ] && [ -f "$STATE_DIR/.cpm-compact-summary-${SESSION_ID}.md" ]; then
  echo ""
  echo "--- CPM COMPACT SUMMARY ---"
  cat "$STATE_DIR/.cpm-compact-summary-${SESSION_ID}.md"
  echo "--- END COMPACT SUMMARY ---"
elif [ -f "$STATE_DIR/.cpm-compact-summary.md" ]; then
  # Legacy/fallback: unsuffixed compact summary
  echo ""
  echo "--- CPM COMPACT SUMMARY ---"
  cat "$STATE_DIR/.cpm-compact-summary.md"
  echo "--- END COMPACT SUMMARY ---"
fi
