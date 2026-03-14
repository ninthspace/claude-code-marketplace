#!/bin/bash
# test-compact-hook.sh — Tests for session-start-compact.sh
#
# Tests cover:
# - JSON parsing (session_id extraction)
# - CPM_SESSION_ID echo
# - Exact session match (outputs correct file)
# - Fallback to all files when no match
# - Graceful degradation on malformed JSON
# - Legacy single-file support

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

HOOK_SCRIPT="$SCRIPT_DIR/../session-start-compact.sh"

echo "Testing: session-start-compact.sh"
echo "================================="

# --- Setup helpers ---

setup_project_dir() {
  local project_dir="$TEST_TMPDIR/project-$$-$RANDOM"
  mkdir -p "$project_dir/docs/plans"
  echo "$project_dir"
}

run_hook() {
  local project_dir="$1"
  local stdin_input="$2"
  echo "$stdin_input" | CLAUDE_PROJECT_DIR="$project_dir" bash "$HOOK_SCRIPT"
}

# --- Tests ---

test_start "Parses session_id from valid JSON and echoes CPM_SESSION_ID"
PROJECT=$(setup_project_dir)
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"abc-123","source":"compact"}')
assert_contains "$OUTPUT" "CPM_SESSION_ID: abc-123"

test_start "Outputs matching session-scoped progress file"
PROJECT=$(setup_project_dir)
echo "# State for abc-123" > "$PROJECT/docs/plans/.cpm-progress-abc-123.md"
echo "# State for def-456" > "$PROJECT/docs/plans/.cpm-progress-def-456.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"abc-123","source":"compact"}')
assert_contains "$OUTPUT" "# State for abc-123"

test_start "Does not output non-matching session files on exact match"
PROJECT=$(setup_project_dir)
echo "# State for abc-123" > "$PROJECT/docs/plans/.cpm-progress-abc-123.md"
echo "# State for def-456" > "$PROJECT/docs/plans/.cpm-progress-def-456.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"abc-123","source":"compact"}')
assert_not_contains "$OUTPUT" "# State for def-456"

test_start "Falls back to all files when session_id has no matching file"
PROJECT=$(setup_project_dir)
echo "# State for def-456" > "$PROJECT/docs/plans/.cpm-progress-def-456.md"
echo "# State for ghi-789" > "$PROJECT/docs/plans/.cpm-progress-ghi-789.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"no-match","source":"compact"}')
assert_contains "$OUTPUT" "# State for def-456"

test_start "Fallback includes all session files"
PROJECT=$(setup_project_dir)
echo "# State for def-456" > "$PROJECT/docs/plans/.cpm-progress-def-456.md"
echo "# State for ghi-789" > "$PROJECT/docs/plans/.cpm-progress-ghi-789.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"no-match","source":"compact"}')
assert_contains "$OUTPUT" "# State for ghi-789"

test_start "Handles malformed JSON gracefully (falls back to all files)"
PROJECT=$(setup_project_dir)
echo "# State for abc" > "$PROJECT/docs/plans/.cpm-progress-abc.md"
OUTPUT=$(run_hook "$PROJECT" 'not valid json')
assert_contains "$OUTPUT" "# State for abc"

test_start "Handles empty stdin gracefully"
PROJECT=$(setup_project_dir)
echo "# State for abc" > "$PROJECT/docs/plans/.cpm-progress-abc.md"
OUTPUT=$(echo "" | CLAUDE_PROJECT_DIR="$PROJECT" bash "$HOOK_SCRIPT")
assert_contains "$OUTPUT" "# State for abc"

test_start "Handles missing session_id field in JSON"
PROJECT=$(setup_project_dir)
echo "# State for abc" > "$PROJECT/docs/plans/.cpm-progress-abc.md"
OUTPUT=$(run_hook "$PROJECT" '{"source":"compact"}')
assert_contains "$OUTPUT" "# State for abc"

test_start "Produces no progress file output when no progress files exist"
PROJECT=$(setup_project_dir)
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"abc-123","source":"compact"}')
assert_contains "$OUTPUT" "CPM_SESSION_ID: abc-123"
assert_not_contains "$OUTPUT" "CPM SESSION STATE"

test_start "Legacy support: falls back to .cpm-progress.md when no session files exist"
PROJECT=$(setup_project_dir)
echo "# Legacy state" > "$PROJECT/docs/plans/.cpm-progress.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"abc-123","source":"compact"}')
assert_contains "$OUTPUT" "# Legacy state"

test_start "Handles clear source identically to compact (silent injection, no orphan detection)"
PROJECT=$(setup_project_dir)
echo "# State for old-session" > "$PROJECT/docs/plans/.cpm-progress-old-session.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"new-session","source":"clear"}')
assert_contains "$OUTPUT" "CPM_SESSION_ID: new-session"
assert_contains "$OUTPUT" "# State for old-session"
assert_not_contains "$OUTPUT" "ORPHAN"
assert_not_contains "$OUTPUT" "BLOCKING"

test_start "Legacy file ignored when session-scoped files exist"
PROJECT=$(setup_project_dir)
echo "# Session state" > "$PROJECT/docs/plans/.cpm-progress-abc-123.md"
echo "# Legacy state" > "$PROJECT/docs/plans/.cpm-progress.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"abc-123","source":"compact"}')
assert_not_contains "$OUTPUT" "# Legacy state"

# --- User name injection tests ---

run_hook_with_env() {
  local project_dir="$1"
  local stdin_input="$2"
  shift 2
  echo "$stdin_input" | env "$@" CLAUDE_PROJECT_DIR="$project_dir" bash "$HOOK_SCRIPT"
}

test_start "Outputs CPM_USER_NAME from env var when set"
PROJECT=$(setup_project_dir)
OUTPUT=$(run_hook_with_env "$PROJECT" '{"session_id":"abc-123","source":"compact"}' CPM_USER_NAME="Alice")
assert_contains "$OUTPUT" "CPM_USER_NAME: Alice"

test_start "Outputs behavioural directive with user name"
PROJECT=$(setup_project_dir)
OUTPUT=$(run_hook_with_env "$PROJECT" '{"session_id":"abc-123","source":"compact"}' CPM_USER_NAME="Alice")
assert_contains "$OUTPUT" 'use their name "Alice"'

test_start "Falls back to git config first name when env var is unset"
PROJECT=$(setup_project_dir)
OUTPUT=$(run_hook_with_env "$PROJECT" '{"session_id":"abc-123","source":"compact"}' CPM_USER_NAME=)
GIT_FIRST=$(git config user.name 2>/dev/null | awk '{print $1}')
if [ -n "$GIT_FIRST" ]; then
  assert_contains "$OUTPUT" "CPM_USER_NAME: $GIT_FIRST"
else
  assert_not_contains "$OUTPUT" "CPM_USER_NAME"
fi

# --- Compact summary injection tests ---

test_start "Injects compact summary after progress file when both exist"
PROJECT=$(setup_project_dir)
echo "# Progress state" > "$PROJECT/docs/plans/.cpm-progress-abc-123.md"
echo "# Compact Summary (PostCompact)" > "$PROJECT/docs/plans/.cpm-compact-summary-abc-123.md"
echo "This is the narrative." >> "$PROJECT/docs/plans/.cpm-compact-summary-abc-123.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"abc-123","source":"compact"}')
assert_contains "$OUTPUT" "# Progress state"
assert_contains "$OUTPUT" "This is the narrative."

test_start "Compact summary appears after progress file content"
PROJECT=$(setup_project_dir)
echo "# Progress state" > "$PROJECT/docs/plans/.cpm-progress-abc-123.md"
echo "# Compact Summary (PostCompact)" > "$PROJECT/docs/plans/.cpm-compact-summary-abc-123.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"abc-123","source":"compact"}')
# Progress content should come before the summary delimiter
PROGRESS_POS=$(echo "$OUTPUT" | grep -n "# Progress state" | head -1 | cut -d: -f1)
SUMMARY_POS=$(echo "$OUTPUT" | grep -n "CPM COMPACT SUMMARY" | head -1 | cut -d: -f1)
if [ -n "$PROGRESS_POS" ] && [ -n "$SUMMARY_POS" ] && [ "$PROGRESS_POS" -lt "$SUMMARY_POS" ]; then
  test_pass
else
  test_fail "Progress file should appear before compact summary"
fi

test_start "Compact summary injection uses clear header/separator"
PROJECT=$(setup_project_dir)
echo "# Progress state" > "$PROJECT/docs/plans/.cpm-progress-abc-123.md"
echo "Summary content." > "$PROJECT/docs/plans/.cpm-compact-summary-abc-123.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"abc-123","source":"compact"}')
assert_contains "$OUTPUT" "--- CPM COMPACT SUMMARY ---"
assert_contains "$OUTPUT" "--- END COMPACT SUMMARY ---"

test_start "Injects compact summary alone when no progress file exists"
PROJECT=$(setup_project_dir)
echo "Summary without progress." > "$PROJECT/docs/plans/.cpm-compact-summary-abc-123.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"abc-123","source":"compact"}')
assert_contains "$OUTPUT" "Summary without progress."
assert_contains "$OUTPUT" "--- CPM COMPACT SUMMARY ---"

test_start "Skips compact summary when no summary file exists"
PROJECT=$(setup_project_dir)
echo "# Progress only" > "$PROJECT/docs/plans/.cpm-progress-abc-123.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"abc-123","source":"compact"}')
assert_contains "$OUTPUT" "# Progress only"
assert_not_contains "$OUTPUT" "CPM COMPACT SUMMARY"

test_start "Falls back to unsuffixed compact summary file"
PROJECT=$(setup_project_dir)
echo "Fallback summary." > "$PROJECT/docs/plans/.cpm-compact-summary.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"no-match","source":"compact"}')
assert_contains "$OUTPUT" "Fallback summary."

test_summary
