#!/bin/bash
# session-start.sh — Re-inject CPM state on session startup/resume
#
# Fires on SessionStart source: "startup" or "resume".
# Stdout is injected into the session context.
# Includes a note prompting Claude to offer continuation or cleanup.

STATE_FILE="$CLAUDE_PROJECT_DIR/docs/plans/.cpm-progress.md"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

echo "NOTE: An incomplete CPM planning session was found from a previous session."
echo "Review the state below and ask the user whether they want to continue where they left off or discard it and start fresh."
echo "If discarding, delete the file at: $STATE_FILE"
echo ""
cat "$STATE_FILE"
