#!/bin/bash
# cleancheck-guard.sh — Once-per-session gate for the Stale-Progress Check
#
# Decides whether a /cpm:* skill should run the stale-progress safety-net this
# session, printing exactly one token:
#
#   SUPPRESS — an active ralph loop is present (.claude/ralph-loop.local.md);
#              the safety-net must be fully silent during autonomous runs.
#   SKIP     — this session already ran the check (its sentinel exists).
#   RUN      — the check should run now; the sentinel is written so subsequent
#              skills in the same session get SKIP.
#
# Precedence: SUPPRESS > SKIP > RUN. The sentinel is
# docs/plans/.cpm-cleancheck-{session_id} — a distinct prefix from
# .cpm-progress-*.md so the classifier's glob never picks it up.
#
# Fail-safe: the guard never deletes anything, and a sentinel write failure
# still yields RUN (prefer running the check once over crashing) — a sentinel
# problem must never cause or block a deletion.
#
# Usage:
#   CPM_SESSION_ID=<id> bash cleancheck-guard.sh [STATE_DIR]
#   (STATE_DIR defaults to "$CLAUDE_PROJECT_DIR/docs/plans";
#    the ralph state file is "$CLAUDE_PROJECT_DIR/.claude/ralph-loop.local.md")

STATE_DIR="${1:-$CLAUDE_PROJECT_DIR/docs/plans}"
RALPH_STATE="$CLAUDE_PROJECT_DIR/.claude/ralph-loop.local.md"

# 1. Autonomous run — fully suppressed, regardless of sentinel state.
if [ -f "$RALPH_STATE" ]; then
  echo "SUPPRESS"
  exit 0
fi

# Without a session id the sentinel cannot be keyed; fail safe to RUN (the check
# runs, nothing is written, nothing is deleted) rather than crash.
if [ -z "$CPM_SESSION_ID" ]; then
  echo "RUN"
  exit 0
fi

SENTINEL="$STATE_DIR/.cpm-cleancheck-$CPM_SESSION_ID"

# 2. Already checked this session.
if [ -f "$SENTINEL" ]; then
  echo "SKIP"
  exit 0
fi

# 3. First run this session — record the sentinel, then RUN. A write failure is
# non-fatal and silent: still RUN (fail safe), never delete. The redirect error
# from an unwritable target is captured by grouping the redirection under
# 2>/dev/null (a bare `: > file 2>/dev/null` would still leak the open error).
{ : > "$SENTINEL"; } 2>/dev/null || true
echo "RUN"
exit 0
