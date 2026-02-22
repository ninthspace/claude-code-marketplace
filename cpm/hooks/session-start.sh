#!/bin/bash
# session-start.sh — Re-inject CPM state on session startup/resume
#
# Fires on SessionStart source: "startup", "resume", or "clear".
# Reads session_id from JSON on stdin and echoes CPM_SESSION_ID.
# Globs all session-scoped progress files and classifies each by
# session ID: current-session files are injected as active state,
# other-session files are collected as orphan candidates for cleanup.
# Stdout is injected into the session context.

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)

# Always echo session ID if available
if [ -n "$SESSION_ID" ]; then
  echo "CPM_SESSION_ID: $SESSION_ID"
fi

STATE_DIR="$CLAUDE_PROJECT_DIR/docs/plans"
NOW=$(date +%s)
STALE_HOURS=24  # Files older than this get a STALE marker

# Collect all session-scoped progress files
found=0
orphan_count=0
orphan_output=""
for f in "$STATE_DIR"/.cpm-progress-*.md; do
  [ -f "$f" ] || continue
  found=1

  # Extract session ID from filename: .cpm-progress-{session_id}.md
  file_session_id=$(basename "$f" | sed 's/^\.cpm-progress-//; s/\.md$//')

  # Extract skill and phase from file header for a readable label
  skill=$(grep -m1 '^\*\*Skill\*\*:' "$f" 2>/dev/null | sed 's/\*\*Skill\*\*: *//')
  phase=$(grep -m1 '^\*\*Phase\|^\*\*Step\|^\*\*Section\|^\*\*Current task' "$f" 2>/dev/null | sed 's/\*\*[^*]*\*\*: *//')
  label="${skill:-unknown}"
  if [ -n "$phase" ]; then
    label="$label — $phase"
  fi

  # Calculate file age
  file_mtime=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null)
  age=0
  age_label="unknown age"
  if [ -n "$file_mtime" ]; then
    age=$((NOW - file_mtime))
    age_hours=$((age / 3600))
    if [ "$age_hours" -ge "$STALE_HOURS" ]; then
      age_days=$((age_hours / 24))
      age_label="${age_days}d old — STALE"
    elif [ "$age_hours" -ge 1 ]; then
      age_label="${age_hours}h old"
    else
      age_minutes=$((age / 60))
      age_label="${age_minutes}m old"
    fi
  fi

  # Classify: current session vs. orphan (by session ID matching)
  if [ -n "$SESSION_ID" ] && [ "$file_session_id" = "$SESSION_ID" ]; then
    # Current session — inject as active state
    echo ""
    echo "--- CPM SESSION STATE ($label) [$(basename "$f")] ---"
    cat "$f"
    echo "--- END ---"
  else
    # Other session — orphan candidate
    orphan_count=$((orphan_count + 1))
    orphan_output="${orphan_output}--- ORPHAN FILE ${orphan_count} ---\nSkill: ${skill:-unknown}\nPhase: ${phase:-unknown}\nAge: ${age_label}\nFile: ${f}\n--- END ORPHAN ---\n\n"
  fi
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

# Report orphan files for cleanup — each as a separate block
if [ "$orphan_count" -gt 0 ]; then
  echo ""
  echo "BLOCKING — ORPHAN CLEANUP REQUIRED"
  echo "==================================="
  echo "Found ${orphan_count} orphaned progress file(s) from other sessions."
  echo "These are from sessions that were interrupted, abandoned, or completed without cleanup."
  echo ""
  echo "IMPORTANT: You MUST stop and resolve this cleanup BEFORE doing anything else."
  echo "Do NOT proceed with the user's request until orphan cleanup is complete."
  echo "Do NOT mention the orphans and then carry on — the user must actively decide."
  echo ""
  echo "ACTION REQUIRED:"
  echo "1. Present each orphaned file to the user (skill, phase, age)."
  echo "2. Ask which ones to delete. Wait for their answer."
  echo "3. Delete only the files the user confirms."
  echo "4. Only THEN proceed with whatever the user originally asked."
  echo ""
  echo "Do NOT delete any files without explicit user confirmation."
  echo ""
  printf "%b" "$orphan_output"
fi

if [ "$found" -gt 0 ] && [ "$orphan_count" -eq 0 ]; then
  echo ""
  echo "NOTE: Found CPM session state from a previous session. Review the state above and ask the user whether they want to continue where they left off or discard it."
elif [ "$found" -gt 0 ] && [ "$orphan_count" -gt 0 ]; then
  echo ""
  echo "NOTE: Found both active CPM session state and orphaned files (see above). Handle the BLOCKING orphan cleanup first, then ask the user about continuation."
fi
