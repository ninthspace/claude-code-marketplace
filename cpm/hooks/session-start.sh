#!/bin/bash
# session-start.sh — Re-inject CPM state on session startup/resume
#
# Fires on SessionStart source: "startup", "resume", or "clear".
# Reads session_id from JSON on stdin and echoes CPM_SESSION_ID.
# Globs all session-scoped progress files and injects each with
# delimiters and readable labels extracted from file headers.
# Detects orphaned files (>48h old) and suggests cleanup.
# Stdout is injected into the session context.

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)

# Always echo session ID if available
if [ -n "$SESSION_ID" ]; then
  echo "CPM_SESSION_ID: $SESSION_ID"
fi

STATE_DIR="$CLAUDE_PROJECT_DIR/docs/plans"
STALE_THRESHOLD=$((48 * 60 * 60))  # 48 hours in seconds
NOW=$(date +%s)

# Collect all session-scoped progress files
found=0
stale_files=""
for f in "$STATE_DIR"/.cpm-progress-*.md; do
  [ -f "$f" ] || continue
  found=1

  # Extract skill and phase from file header for a readable label
  skill=$(grep -m1 '^\*\*Skill\*\*:' "$f" 2>/dev/null | sed 's/\*\*Skill\*\*: *//')
  phase=$(grep -m1 '^\*\*Phase\|^\*\*Step\|^\*\*Section\|^\*\*Current task' "$f" 2>/dev/null | sed 's/\*\*[^*]*\*\*: *//')
  label="${skill:-unknown}"
  if [ -n "$phase" ]; then
    label="$label — $phase"
  fi

  # Check if file is stale (>48h old)
  file_mtime=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null)
  if [ -n "$file_mtime" ]; then
    age=$((NOW - file_mtime))
    if [ "$age" -gt "$STALE_THRESHOLD" ]; then
      stale_files="${stale_files}STALE: $label — file: $f ($(( age / 3600 ))h old). To remove: delete $f\n"
      continue
    fi
  fi

  echo ""
  echo "--- CPM SESSION STATE ($label) [$(basename "$f")] ---"
  cat "$f"
  echo "--- END ---"
done

# Legacy support: check for old single-file format
if [ "$found" -eq 0 ] && [ -f "$STATE_DIR/.cpm-progress.md" ]; then
  echo ""
  echo "NOTE: An incomplete CPM planning session was found from a previous session."
  echo "Review the state below and ask the user whether they want to continue where they left off or discard it and start fresh."
  echo "If discarding, delete the file at: $STATE_DIR/.cpm-progress.md"
  echo ""
  cat "$STATE_DIR/.cpm-progress.md"
  found=1
fi

# Report stale files separately
if [ -n "$stale_files" ]; then
  echo ""
  echo "WARNING: The following CPM session files appear to be orphaned (older than 48 hours)."
  echo "These are likely from sessions that were interrupted or abandoned."
  echo "Ask the user if they want to delete them."
  echo ""
  printf "%b" "$stale_files"
fi

if [ "$found" -gt 0 ] && [ -z "$stale_files" ]; then
  echo ""
  echo "NOTE: Found CPM session state from a previous session. Review the state above and ask the user whether they want to continue where they left off or discard it."
elif [ "$found" -gt 0 ] && [ -n "$stale_files" ]; then
  echo ""
  echo "NOTE: Found CPM session state from a previous session (some files are stale — see warnings above). Review the active state and ask the user about continuation and cleanup."
fi
