#!/bin/bash
# session-start.sh — Re-inject CPM state on session startup/resume
#
# Fires on SessionStart source: "startup" or "resume".
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

# Check for active ralph loop state file
RALPH_STATE="$CLAUDE_PROJECT_DIR/.claude/ralph-loop.local.md"
if [ -f "$RALPH_STATE" ]; then
  ralph_iteration=$(grep -m1 '^iteration:' "$RALPH_STATE" 2>/dev/null | sed 's/iteration: *//')
  ralph_max=$(grep -m1 '^max_iterations:' "$RALPH_STATE" 2>/dev/null | sed 's/max_iterations: *//')
  ralph_promise=$(grep -m1 '^completion_promise:' "$RALPH_STATE" 2>/dev/null | sed 's/completion_promise: *//' | sed 's/^"\(.*\)"$/\1/')
  echo ""
  echo "WARNING — ACTIVE RALPH LOOP DETECTED"
  echo "====================================="
  echo "A ralph loop is active on this repo (.claude/ralph-loop.local.md)."
  echo "Iteration: ${ralph_iteration:-unknown}, Max: ${ralph_max:-unknown}, Promise: ${ralph_promise:-unknown}"
  echo ""
  echo "The ralph-wiggum stop hook will intercept ALL session exits on this repo,"
  echo "not just the session that started the loop. Any work in this session will"
  echo "be hijacked by the ralph loop when you try to exit."
  echo ""
  echo "IMPORTANT: Warn the user about this immediately. Recommend either:"
  echo "  1. Work in a different repo until the loop completes"
  echo "  2. Delete .claude/ralph-loop.local.md to deactivate the loop (will stop the running loop too)"
  echo "  3. Continue at your own risk — the stop hook WILL intercept your session exit"
  echo ""
fi

STATE_DIR="$CLAUDE_PROJECT_DIR/docs/plans"
CLASSIFIER="$(cd "$(dirname "$0")" && pwd)/lib/progress-classify.sh"

# Classification is delegated to the shared helper — the single source of truth
# for the age + session-ID rules. No inline duplicate of that logic lives here.
records=""
if [ -f "$CLASSIFIER" ]; then
  records=$(CPM_SESSION_ID="$SESSION_ID" bash "$CLASSIFIER" "$STATE_DIR")
fi

found=0
stale_count=0
stale_output=""
fresh_count=0
fresh_output=""
while IFS=$'\t' read -r classification path skill phase age age_label; do
  [ -z "$classification" ] && continue
  found=1

  case "$classification" in
    CURRENT)
      # Current session — inject as active state
      label="${skill:-unknown}"
      if [ -n "$phase" ] && [ "$phase" != "unknown" ]; then
        label="$label — $phase"
      fi
      echo ""
      echo "--- CPM SESSION STATE ($label) [$(basename "$path")] ---"
      cat "$path"
      echo "--- END ---"
      ;;
    STALE)
      # Other session, at/over the staleness threshold — cleanup candidate
      stale_count=$((stale_count + 1))
      stale_output="${stale_output}--- STALE FILE ${stale_count} ---\nSkill: ${skill:-unknown}\nPhase: ${phase:-unknown}\nAge: ${age_label}\nFile: ${path}\n--- END ---\n\n"
      ;;
    FRESH)
      # Other session, under the threshold — active/recent parallel session
      fresh_count=$((fresh_count + 1))
      fresh_output="${fresh_output}--- PARALLEL SESSION ${fresh_count} ---\nSkill: ${skill:-unknown}\nPhase: ${phase:-unknown}\nAge: ${age_label}\nFile: ${path}\n--- END ---\n\n"
      ;;
  esac
done <<EOF
$records
EOF

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

# Stale other-session files — offered for cleanup. Non-blocking: the session
# continues; cleanup is presented as an option, never forced.
if [ "$stale_count" -gt 0 ]; then
  echo ""
  echo "--- STALE PROGRESS FILES (cleanup candidates) ---"
  echo "Found ${stale_count} stale progress file(s) from other sessions (3+ days old)."
  echo "These are likely leftovers from interrupted or abandoned sessions."
  echo "You may offer to delete them, removing only files the user explicitly confirms."
  echo "This is non-blocking: carry on with the user's request and raise cleanup when it fits."
  echo ""
  printf "%b" "$stale_output"
fi

# Fresh other-session files — informational only. Never a cleanup candidate,
# never injected as active state.
if [ "$fresh_count" -gt 0 ]; then
  echo ""
  echo "--- ACTIVE/RECENT PARALLEL SESSIONS (informational) ---"
  echo "Found ${fresh_count} recent progress file(s) from other sessions (under 3 days old)."
  echo "These likely belong to active or recent parallel sessions and are shown for awareness only."
  echo "Do not offer them for deletion."
  echo ""
  printf "%b" "$fresh_output"
fi

if [ "$found" -gt 0 ] && [ "$stale_count" -eq 0 ] && [ "$fresh_count" -eq 0 ]; then
  echo ""
  echo "NOTE: Found CPM session state from a previous session. Review the state above and ask the user whether they want to continue where they left off or discard it."
fi
