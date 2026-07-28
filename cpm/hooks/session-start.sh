#!/bin/bash
# session-start.sh — Re-inject CPM state on session startup/resume
#
# Fires on SessionStart source: "startup" or "resume".
# Reads session_id from JSON on stdin and echoes CPM_SESSION_ID.
# Globs all session-scoped progress files and classifies each by
# session ID: current-session files are named as active state,
# other-session files are collected as orphan candidates for cleanup.
# Stdout is injected into the session context.
#
# --- Why this output is kept small ----------------------------------------------
#
# Hook stdout is capped at 10,000 characters. Past that, Claude Code does not
# trim to the cap — it persists the whole output to a file and inlines a ~2 KB
# preview instead. The content survives on disk and the notice gives its path,
# but it does not reach context, the notice is descriptive rather than
# imperative, and nothing says which parts are missing. So an over-long payload
# fails silently. This hook used to emit whole documents and hit exactly that.
# Both halves are open upstream bugs, not settled behaviour:
# anthropics/claude-code#44086 (2 KB, not 10 KB, on breach) and #55750 (the
# SessionStart case specifically). Measurements: docs/maintenance/README.md.
#
# So size is a correctness property here, not a courtesy. Four rules keep it one:
#
#   1. **Nothing whose length is set by a document is emitted in full.** Progress
#      files are named, with the fields a reader needs to decide whether to open
#      them; the conventions are represented by a bounded core and a pointer.
#   2. **Nothing whose length is set by a count is emitted unbounded.** The
#      other-session lists stop at CPM_LIST_CAP and report what they left out.
#   3. **Output is ordered by what a session cannot afford to lose**, so position
#      is insurance against the 2 KB case: the ralph warning, then the session's
#      own state, then the conventions. The first two can cost a user work; the
#      third names a file that is still on disk either way.
#   4. **The rules are asserted, not trusted.** test-session-start-budget.sh pins
#      the payload's independence from document size (the property rule 1 exists
#      to produce), the ordering in rule 3, and CPM_PAYLOAD_BUDGET behind both.
#
# Sections named in CORE_SECTIONS are the ones that must apply in a session where
# no skill is ever invoked. Everything else is skill-scoped and is read from disk
# at the point a skill defers to it.

# The ceiling this hook's stdout is held under, in CHARACTERS — the unit the 10,000 limit
# is stated in, and not the same as bytes once an em dash is involved. Nothing here reads
# it; it is declared so the budget has one home rather than living only in a test file,
# where a reader of this script would never meet it.
#
# **The margin is thin: ~9.2k measured worst case against a 10k hard limit.** Over half of
# it is the CORE_SECTIONS extract, so adding a section to that list is not a free change —
# re-measure before doing it. See docs/maintenance/README.md.
CPM_PAYLOAD_BUDGET=9600

# Most of this output has a fixed size, but the other-session lists are as long as the
# project has leftover progress files, and a repo that has been through a few interrupted
# runs accumulates them. A count is not a document, so rule 1 does not catch it — this
# does. Past the cap the files are counted rather than listed, which is all the enumeration
# was doing for a reader who is being asked to confirm a bulk delete anyway.
CPM_LIST_CAP=3

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

# Check for active ralph loop state file. First, deliberately: it is the only output here
# that can prevent a user losing work, and it is worthless if anything can push it down.
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

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$HOOK_DIR/.." && pwd)"
STATE_DIR="$CLAUDE_PROJECT_DIR/docs/plans"
CLASSIFIER="$HOOK_DIR/lib/progress-classify.sh"

# Classification is delegated to the shared helper — the single source of truth
# for the age + session-ID rules. No inline duplicate of that logic lives here.
records=""
if [ -f "$CLASSIFIER" ]; then
  records=$(CPM_SESSION_ID="$SESSION_ID" bash "$CLASSIFIER" "$STATE_DIR")
fi

found=0
current_output=""
stale_count=0
stale_output=""
fresh_count=0
fresh_output=""
while IFS=$'\t' read -r classification path skill phase age age_label; do
  [ -z "$classification" ] && continue
  found=1

  case "$classification" in
    CURRENT)
      # Current session — the state this session is resuming into. Named, not inlined:
      # a progress file grows with the work it records, so emitting it in full makes the
      # payload a function of how much has been done — which is exactly how the whole
      # injection used to end up past the truncation point and reach nobody.
      # Collected rather than printed, so it can be emitted ahead of the conventions.
      label="${skill:-unknown}"
      if [ -n "$phase" ] && [ "$phase" != "unknown" ]; then
        label="$label — $phase"
      fi
      current_output="${current_output}\n--- CPM SESSION STATE (${label}) [$(basename "$path")] ---\nThis session has work in progress. Read this file before continuing:\n  ${path}\n--- END ---\n"
      ;;
    STALE)
      # Other session, at/over the staleness threshold — cleanup candidate
      stale_count=$((stale_count + 1))
      if [ "$stale_count" -le "$CPM_LIST_CAP" ]; then
        stale_output="${stale_output}  ${stale_count}. ${skill:-unknown} · ${phase:-unknown} · ${age_label}\n     ${path}\n"
      fi
      ;;
    FRESH)
      # Other session, under the threshold — active/recent parallel session
      fresh_count=$((fresh_count + 1))
      if [ "$fresh_count" -le "$CPM_LIST_CAP" ]; then
        fresh_output="${fresh_output}  ${fresh_count}. ${skill:-unknown} · ${phase:-unknown} · ${age_label}\n     ${path}\n"
      fi
      ;;
  esac
done <<EOF
$records
EOF

# Legacy support: check for old single-file format
if [ "$found" -eq 0 ] && [ -f "$STATE_DIR/.cpm-progress.md" ]; then
  current_output="\n--- CPM SESSION STATE (legacy single-file format) ---\nAn incomplete CPM planning session was found. Read this file, then ask the user whether\nto continue where they left off or discard it and start fresh:\n  ${STATE_DIR}/.cpm-progress.md\nIf discarding, delete that file.\n--- END ---\n"
  found=1
fi

# --- Output, ordered by what a session cannot afford to lose -------------------------
#
# The harness truncates an over-long payload to a 2 KB preview, so position is a form of
# insurance: whatever is emitted first survives a truncation that should not happen. The
# ralph warning (above) can prevent losing a session's work, and this block tells a resumed
# session that it has state at all — both come before the conventions, which name a file
# that will still be on disk whether or not this output arrives.
printf "%b" "$current_output"

# Shared conventions: a bounded core and a pointer to the rest. Both SessionStart hooks
# emit the same extract, so the choice of what is in it lives in one place.
bash "$HOOK_DIR/lib/conventions-core.sh" "$PLUGIN_ROOT/shared/skill-conventions.md"

# --- Other sessions' files, last ------------------------------------------------------
#
# One row per file rather than a delimited block each. The fields are the same; a row of
# metadata is not a document and does not need a document's framing, and at the cap this
# is the difference between roughly 250 characters per file and roughly 110.

# Stale other-session files — offered for cleanup. Non-blocking: the session
# continues; cleanup is presented as an option, never forced.
if [ "$stale_count" -gt 0 ]; then
  echo ""
  echo "--- STALE PROGRESS FILES (cleanup candidates) ---"
  echo "Found ${stale_count} stale progress file(s) from other sessions (3+ days old), likely"
  echo "leftovers from interrupted or abandoned sessions. You may offer to delete them,"
  echo "removing only files the user explicitly confirms. This is non-blocking: carry on with"
  echo "the user's request and raise cleanup when it fits."
  printf "%b" "$stale_output"
  if [ "$stale_count" -gt "$CPM_LIST_CAP" ]; then
    echo "(Listing the first ${CPM_LIST_CAP} of ${stale_count}. Glob ${STATE_DIR}/.cpm-progress-*.md for the rest.)"
  fi
  echo "--- END ---"
fi

# Fresh other-session files — informational only. Never a cleanup candidate,
# never presented as active state.
if [ "$fresh_count" -gt 0 ]; then
  echo ""
  echo "--- ACTIVE/RECENT PARALLEL SESSIONS (informational) ---"
  echo "Found ${fresh_count} recent progress file(s) from other sessions (under 3 days old),"
  echo "likely active or recent parallel sessions, and shown for awareness only."
  echo "Do not offer them for deletion."
  printf "%b" "$fresh_output"
  if [ "$fresh_count" -gt "$CPM_LIST_CAP" ]; then
    echo "(Listing the first ${CPM_LIST_CAP} of ${fresh_count}.)"
  fi
  echo "--- END ---"
fi

if [ "$found" -gt 0 ] && [ "$stale_count" -eq 0 ] && [ "$fresh_count" -eq 0 ]; then
  echo ""
  echo "NOTE: Found CPM session state from a previous session. Read the file named above and ask the user whether they want to continue where they left off or discard it."
fi
