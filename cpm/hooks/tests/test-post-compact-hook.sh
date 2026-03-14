#!/bin/bash
# test-post-compact-hook.sh — Tests for post-compact.sh
#
# Tests cover:
# - JSON parsing (session_id, compact_summary, trigger extraction)
# - File writing with header (source, timestamp, trigger)
# - Graceful handling of malformed/empty JSON
# - No file written when compact_summary is missing or empty

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

HOOK_SCRIPT="$SCRIPT_DIR/../post-compact.sh"

echo "Testing: post-compact.sh"
echo "========================"

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

test_start "Writes compact summary file for valid JSON input"
PROJECT=$(setup_project_dir)
run_hook "$PROJECT" '{"session_id":"abc-123","compact_summary":"This is the summary.","trigger":"auto"}'
assert_contains "$(cat "$PROJECT/docs/plans/.cpm-compact-summary-abc-123.md" 2>/dev/null)" "This is the summary."

test_start "File includes source label header"
PROJECT=$(setup_project_dir)
run_hook "$PROJECT" '{"session_id":"abc-123","compact_summary":"Summary text.","trigger":"auto"}'
assert_contains "$(cat "$PROJECT/docs/plans/.cpm-compact-summary-abc-123.md" 2>/dev/null)" "# Compact Summary (PostCompact)"

test_start "File includes trigger type in header"
PROJECT=$(setup_project_dir)
run_hook "$PROJECT" '{"session_id":"abc-123","compact_summary":"Summary text.","trigger":"manual"}'
assert_contains "$(cat "$PROJECT/docs/plans/.cpm-compact-summary-abc-123.md" 2>/dev/null)" "**Trigger**: manual"

test_start "File includes timestamp in header"
PROJECT=$(setup_project_dir)
run_hook "$PROJECT" '{"session_id":"abc-123","compact_summary":"Summary text.","trigger":"auto"}'
assert_contains "$(cat "$PROJECT/docs/plans/.cpm-compact-summary-abc-123.md" 2>/dev/null)" "**Captured**:"

test_start "Extracts session_id for filename"
PROJECT=$(setup_project_dir)
run_hook "$PROJECT" '{"session_id":"def-456","compact_summary":"Summary.","trigger":"auto"}'
[ -f "$PROJECT/docs/plans/.cpm-compact-summary-def-456.md" ]
assert_equals "0" "$?"

test_start "No file written when compact_summary is missing"
PROJECT=$(setup_project_dir)
run_hook "$PROJECT" '{"session_id":"abc-123","trigger":"auto"}'
FILES=$(ls "$PROJECT/docs/plans/"/.cpm-compact-summary-* 2>/dev/null)
assert_empty "$FILES"

test_start "No file written when compact_summary is empty string"
PROJECT=$(setup_project_dir)
run_hook "$PROJECT" '{"session_id":"abc-123","compact_summary":"","trigger":"auto"}'
FILES=$(ls "$PROJECT/docs/plans/"/.cpm-compact-summary-* 2>/dev/null)
assert_empty "$FILES"

test_start "Handles malformed JSON gracefully — no crash, no file written"
PROJECT=$(setup_project_dir)
run_hook "$PROJECT" 'not valid json'
EXIT_CODE=$?
FILES=$(ls "$PROJECT/docs/plans/"/.cpm-compact-summary-* 2>/dev/null)
assert_empty "$FILES"

test_start "Handles empty stdin gracefully — no crash"
PROJECT=$(setup_project_dir)
echo "" | CLAUDE_PROJECT_DIR="$PROJECT" bash "$HOOK_SCRIPT"
EXIT_CODE=$?
assert_equals "0" "$EXIT_CODE"

test_start "Falls back to unsuffixed filename when session_id is missing"
PROJECT=$(setup_project_dir)
run_hook "$PROJECT" '{"compact_summary":"Summary without session.","trigger":"auto"}'
assert_contains "$(cat "$PROJECT/docs/plans/.cpm-compact-summary.md" 2>/dev/null)" "Summary without session."

test_start "Overwrites existing summary file on subsequent compaction"
PROJECT=$(setup_project_dir)
run_hook "$PROJECT" '{"session_id":"abc-123","compact_summary":"First summary.","trigger":"auto"}'
run_hook "$PROJECT" '{"session_id":"abc-123","compact_summary":"Second summary.","trigger":"auto"}'
assert_contains "$(cat "$PROJECT/docs/plans/.cpm-compact-summary-abc-123.md" 2>/dev/null)" "Second summary."

test_start "Overwritten file does not contain old summary"
PROJECT=$(setup_project_dir)
run_hook "$PROJECT" '{"session_id":"abc-123","compact_summary":"First summary.","trigger":"auto"}'
run_hook "$PROJECT" '{"session_id":"abc-123","compact_summary":"Second summary.","trigger":"auto"}'
assert_not_contains "$(cat "$PROJECT/docs/plans/.cpm-compact-summary-abc-123.md" 2>/dev/null)" "First summary."

test_summary
