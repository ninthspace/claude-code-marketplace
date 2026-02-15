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

test_start "Produces no output when no progress files exist"
PROJECT=$(setup_project_dir)
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"abc-123","source":"compact"}')
# Should only have the CPM_SESSION_ID line, no file content
assert_equals "CPM_SESSION_ID: abc-123" "$(echo "$OUTPUT" | tr -s '\n')"

test_start "Legacy support: falls back to .cpm-progress.md when no session files exist"
PROJECT=$(setup_project_dir)
echo "# Legacy state" > "$PROJECT/docs/plans/.cpm-progress.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"abc-123","source":"compact"}')
assert_contains "$OUTPUT" "# Legacy state"

test_start "Legacy file ignored when session-scoped files exist"
PROJECT=$(setup_project_dir)
echo "# Session state" > "$PROJECT/docs/plans/.cpm-progress-abc-123.md"
echo "# Legacy state" > "$PROJECT/docs/plans/.cpm-progress.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"abc-123","source":"compact"}')
assert_not_contains "$OUTPUT" "# Legacy state"

test_summary
