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
#   CPM_SESSION_ID=<id> bash cleancheck-guard.sh [STATE_DIR] [RALPH_STATE]
#   (both default to paths under the resolved project root — see
#    lib/resolve-project-root.sh for the resolution chain; STATE_DIR defaults to
#    "<root>/docs/plans" and RALPH_STATE to "<root>/.claude/ralph-loop.local.md")
#
# Skills invoke this with no arguments and no $CLAUDE_PROJECT_DIR, so the root
# has to be resolved here rather than assumed. An unresolvable root yields
# SUPPRESS: the safety-net is advisory (worst case, leftover files linger) while
# a wrongly-permitted prompt can stall an autonomous run, which is the failure
# actually worth avoiding.

LIB_DIR="${0%/*}"
[ "$LIB_DIR" = "$0" ] && LIB_DIR="."
. "$LIB_DIR/resolve-project-root.sh"

if ! cpm_resolve_project_root "cleancheck-guard"; then
  echo "SUPPRESS"
  exit 0
fi

STATE_DIR="${1:-$CPM_PROJECT_ROOT/docs/plans}"
RALPH_STATE="${2:-$CPM_PROJECT_ROOT/.claude/ralph-loop.local.md}"

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
