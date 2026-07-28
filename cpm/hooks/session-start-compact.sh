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
# After progress file injection, names the compact summary file
# (written by post-compact.sh) if one exists — providing narrative
# context alongside structured state.
# Stdout is injected into the fresh post-compaction context.
#
# --- Why the recovery files are named rather than inlined ------------------------
#
# The harness inlines only the first 2 KB of an oversized hook payload and persists the
# rest to a file nothing reads. This hook used to emit the whole of skill-conventions.md
# followed by the progress file and the compact summary, which reached 86 KB on a real
# session — so the 2 KB that arrived was the session id, the user name, and the first one
# and a half sections of the conventions. The progress state and the summary, the two
# things a post-compaction context exists to recover, sat 40 KB past the cut.
#
# Naming a file costs a line and the agent reads it. Inlining a file costs its length and,
# past the threshold, delivers nothing. So the recovery pointers come first, before the
# conventions extract, because after compaction they are the urgent output — and nothing
# emitted here has a length set by a document.

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

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$CLAUDE_PROJECT_DIR/docs/plans"
CLASSIFIER="$HOOK_DIR/lib/progress-classify.sh"

# --- Progress file ---
# Name ONLY the current session's file (classifier says CURRENT). There is no
# blanket name-them-all fallback: other-session/stale files are never presented as
# active state, so /clear cannot silently resurrect them. On compaction the
# session id is unchanged, so the matching file is still recovered.

progress_found=0
progress_path=""
if [ -f "$CLASSIFIER" ]; then
  records=$(CPM_SESSION_ID="$SESSION_ID" bash "$CLASSIFIER" "$STATE_DIR")
  while IFS=$'\t' read -r classification path skill phase age age_label; do
    [ "$classification" = "CURRENT" ] || continue
    progress_path="$path"
    progress_found=1
  done <<EOF
$records
EOF
fi

# Legacy support: check for old single-file format (pre session-scoped naming).
if [ "$progress_found" -eq 0 ] && [ -f "$STATE_DIR/.cpm-progress.md" ]; then
  progress_path="$STATE_DIR/.cpm-progress.md"
  progress_found=1
fi

# --- Compact summary ---
# Named after the progress file (structured state first, narrative supplement after).
# If no progress file exists, the summary is named alone as fallback.

summary_path=""
if [ -n "$SESSION_ID" ] && [ -f "$STATE_DIR/.cpm-compact-summary-${SESSION_ID}.md" ]; then
  summary_path="$STATE_DIR/.cpm-compact-summary-${SESSION_ID}.md"
elif [ -f "$STATE_DIR/.cpm-compact-summary.md" ]; then
  # Legacy/fallback: unsuffixed compact summary
  summary_path="$STATE_DIR/.cpm-compact-summary.md"
fi

# The recovery pointers, first: the context this replaces is gone, and these files are what
# is left of it. Two blocks, structured state before narrative summary, each with its own
# delimiters — a reader (and the suite) can tell which file is which, and a run with no
# summary emits no summary block at all rather than an empty one.
if [ "$progress_found" -eq 1 ]; then
  echo ""
  echo "--- CPM SESSION STATE (recovered after compaction) ---"
  echo "Context was compacted. This session's CPM state survives on disk, NOT in this"
  echo "context. Read this file now, before answering — it records which skill is running"
  echo "and which step it reached:"
  echo "  $progress_path"
  echo "--- END ---"
fi

# The summary is written by post-compact.sh from the harness's own `compact_summary` field,
# so its length is set by how much was compacted — 31 KB on one observed session. Naming it
# is what keeps this hook's payload independent of that.
if [ -n "$summary_path" ]; then
  echo ""
  echo "--- CPM COMPACT SUMMARY ---"
  echo "A narrative summary of the work before compaction was saved. Read it for what was"
  echo "being done and why:"
  echo "  $summary_path"
  echo "--- END COMPACT SUMMARY ---"
fi

# Shared conventions: a bounded core and a pointer to the rest. Both SessionStart hooks
# emit the same extract, so the choice of what is in it lives in one place.
PLUGIN_ROOT="$(cd "$HOOK_DIR/.." && pwd)"
bash "$HOOK_DIR/lib/conventions-core.sh" "$PLUGIN_ROOT/shared/skill-conventions.md"
