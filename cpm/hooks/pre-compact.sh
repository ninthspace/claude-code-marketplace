#!/bin/bash
# pre-compact.sh — Guide compaction to preserve CPM planning state
#
# Fires before compaction. Stdout is appended to compaction instructions
# (but gets summarised along with everything else).

STATE_FILE="$CLAUDE_PROJECT_DIR/docs/plans/.cpm-progress.md"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Extract skill name and current phase from the state file
SKILL=$(grep '^\*\*Skill\*\*:' "$STATE_FILE" | head -1 | sed 's/\*\*Skill\*\*: //')
PHASE=$(grep '^\*\*Phase\*\*:' "$STATE_FILE" | head -1 | sed 's/\*\*Phase\*\*: //')

echo "When summarising, preserve CPM planning session state:"
echo "- Active skill: $SKILL"
echo "- Current phase: $PHASE"
echo "- All completed phase decisions and user answers"
echo "- The next action to take when resuming"
echo "- The output target path for the planning artifact"
