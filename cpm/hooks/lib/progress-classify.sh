#!/bin/bash
# progress-classify.sh — Shared classifier for CPM progress files
#
# Single source of truth for the age + session-ID rules that decide whether a
# .cpm-progress-{id}.md file is the CURRENT session's active state, a FRESH
# parallel session, or a STALE leftover. Both SessionStart hooks and the
# /cpm:* skills (safety-net, /cpm:clean) consume its output so the rule can
# never drift across consumers.
#
# Usage:
#   CPM_SESSION_ID=<id> bash progress-classify.sh [STATE_DIR]
#   (STATE_DIR defaults to "$CLAUDE_PROJECT_DIR/docs/plans")
#
# Emits one tab-delimited record per progress file (nothing if none exist):
#   CLASSIFICATION<TAB>PATH<TAB>SKILL<TAB>PHASE<TAB>AGE_SECONDS<TAB>AGE_LABEL
# where CLASSIFICATION is one of CURRENT | FRESH | STALE.
#
#   CURRENT — file's session ID matches $CPM_SESSION_ID (active state, any age)
#   FRESH   — other session, younger than the staleness threshold
#   STALE   — other session, at or beyond the staleness threshold
#
# The helper is strictly read-only: it never deletes, moves, or writes a file.
# It never blocks — malformed/unreadable files are skipped and it always exits 0.

# Staleness threshold, as a single named constant (replaces the old inline
# 24-hour hours-based marker). Other-session files at or beyond this age are
# STALE; younger ones are FRESH. Overridable via the environment for testing.
CPM_STALE_THRESHOLD_DAYS="${CPM_STALE_THRESHOLD_DAYS:-3}"

STATE_DIR="${1:-$CLAUDE_PROJECT_DIR/docs/plans}"

# Cross-platform mtime in epoch seconds: BSD/macOS `stat -f %m`, GNU/Linux
# `stat -c %Y`. Prints nothing if both fail (caller treats that as a skip).
file_mtime() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null
}

# Human-readable age label from a raw age (seconds) and a staleness flag.
format_age() {
  local age="$1" is_stale="$2"
  if [ "$is_stale" = "stale" ]; then
    printf '%dd old — STALE' "$((age / 86400))"
  else
    local hours=$((age / 3600))
    if [ "$hours" -ge 1 ]; then
      printf '%dh old' "$hours"
    else
      printf '%dm old' "$((age / 60))"
    fi
  fi
}

now=$(date +%s)
threshold_seconds=$((CPM_STALE_THRESHOLD_DAYS * 86400))

for f in "$STATE_DIR"/.cpm-progress-*.md; do
  [ -f "$f" ] || continue          # glob matched nothing → literal pattern → skip
  [ -r "$f" ] || continue          # unreadable → skip, keep going

  # Session ID from the filename: .cpm-progress-{session_id}.md
  file_session_id=$(basename "$f" | sed 's/^\.cpm-progress-//; s/\.md$//')

  # Readable label fields from the file header (best-effort; never fatal).
  skill=$(grep -m1 '^\*\*Skill\*\*:' "$f" 2>/dev/null | sed 's/\*\*Skill\*\*: *//')
  phase=$(grep -m1 '^\*\*Phase\|^\*\*Step\|^\*\*Section\|^\*\*Current task' "$f" 2>/dev/null | sed 's/\*\*[^*]*\*\*: *//')
  skill="${skill:-unknown}"
  phase="${phase:-unknown}"

  # Age from mtime. If stat yields nothing (malformed/unreadable), skip the file.
  mtime=$(file_mtime "$f")
  [ -n "$mtime" ] || continue
  age=$((now - mtime))
  [ "$age" -lt 0 ] && age=0

  # Classify. The current session's file is CURRENT at ANY age — it must never
  # be labelled FRESH or STALE, so the session-ID check precedes the age check.
  if [ -n "$CPM_SESSION_ID" ] && [ "$file_session_id" = "$CPM_SESSION_ID" ]; then
    classification="CURRENT"
    age_label=$(format_age "$age" fresh)
  elif [ "$age" -ge "$threshold_seconds" ]; then
    classification="STALE"
    age_label=$(format_age "$age" stale)
  else
    classification="FRESH"
    age_label=$(format_age "$age" fresh)
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$classification" "$f" "$skill" "$phase" "$age" "$age_label"
done

exit 0
