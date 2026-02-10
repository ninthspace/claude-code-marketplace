#!/bin/bash
# session-start-compact.sh — Re-inject CPM state after compaction
#
# Fires after compaction completes (SessionStart source: "compact").
# Stdout is injected into the fresh post-compaction context.
# This is the primary mechanism for seamless continuation.

STATE_FILE="$CLAUDE_PROJECT_DIR/docs/plans/.cpm-progress.md"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

cat "$STATE_FILE"
