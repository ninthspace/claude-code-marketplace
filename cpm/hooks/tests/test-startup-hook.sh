#!/bin/bash
# test-startup-hook.sh — Tests for session-start.sh
#
# Tests cover:
# - JSON parsing (session_id extraction)
# - CPM_SESSION_ID echo
# - Multi-file globbing with delimiters and labels
# - Label extraction from file headers (skill, phase)
# - Zero-file graceful handling
# - Legacy single-file support

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

HOOK_SCRIPT="$SCRIPT_DIR/../session-start.sh"

echo "Testing: session-start.sh"
echo "========================="

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

create_progress_file() {
  local project_dir="$1"
  local session_id="$2"
  local skill="$3"
  local phase="$4"
  cat > "$project_dir/docs/plans/.cpm-progress-${session_id}.md" <<EOF
# CPM Session State

**Skill**: $skill
**Phase**: $phase
**Topic**: Test topic

## Next Action
Continue.
EOF
}

# --- Tests ---

test_start "Parses session_id from valid JSON and echoes CPM_SESSION_ID"
PROJECT=$(setup_project_dir)
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"abc-123","source":"startup"}')
assert_contains "$OUTPUT" "CPM_SESSION_ID: abc-123"

test_start "Echoes CPM_SESSION_ID as first non-empty line"
PROJECT=$(setup_project_dir)
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"abc-123","source":"startup"}')
FIRST_LINE=$(echo "$OUTPUT" | head -1)
assert_equals "CPM_SESSION_ID: abc-123" "$FIRST_LINE"

test_start "Globs all session-scoped progress files"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "sess-1" "cpm:do" "Task execution"
create_progress_file "$PROJECT" "sess-2" "cpm:party" "Discussion in progress"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"sess-1","source":"startup"}')
assert_contains "$OUTPUT" "cpm:do"

test_start "Other-session files are classified as orphans, not injected"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "sess-1" "cpm:do" "Task execution"
create_progress_file "$PROJECT" "sess-2" "cpm:party" "Discussion in progress"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"sess-1","source":"startup"}')
assert_not_contains "$OUTPUT" "--- CPM SESSION STATE (cpm:party"
assert_contains "$OUTPUT" "ORPHAN"

test_start "Each file has delimiter markers"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "sess-1" "cpm:do" "Task execution"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"sess-1","source":"startup"}')
assert_contains "$OUTPUT" "--- CPM SESSION STATE"

test_start "Each file has END delimiter"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "sess-1" "cpm:do" "Task execution"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"sess-1","source":"startup"}')
assert_contains "$OUTPUT" "--- END ---"

test_start "Label includes skill name"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "sess-1" "cpm:do" "Task execution"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"sess-1","source":"startup"}')
assert_contains "$OUTPUT" "(cpm:do"

test_start "Label includes phase"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "sess-1" "cpm:do" "Task execution"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"sess-1","source":"startup"}')
assert_contains "$OUTPUT" "Task execution"

test_start "Label includes filename for identification"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "sess-1" "cpm:do" "Task execution"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"sess-1","source":"startup"}')
assert_contains "$OUTPUT" ".cpm-progress-sess-1.md"

test_start "Zero files: outputs CPM_SESSION_ID without any progress file content"
PROJECT=$(setup_project_dir)
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"abc-123","source":"startup"}')
assert_contains "$OUTPUT" "CPM_SESSION_ID: abc-123"
assert_not_contains "$OUTPUT" "CPM SESSION STATE"

test_start "Zero files: no delimiter markers"
PROJECT=$(setup_project_dir)
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"abc-123","source":"startup"}')
assert_not_contains "$OUTPUT" "--- CPM SESSION STATE"

test_start "Handles malformed JSON gracefully — files still visible"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "sess-1" "cpm:do" "Task execution"
OUTPUT=$(run_hook "$PROJECT" 'not valid json')
assert_contains "$OUTPUT" "cpm:do"  # File appears somewhere (orphan section when no session ID parsed)

test_start "Legacy support: injects .cpm-progress.md when no session files exist"
PROJECT=$(setup_project_dir)
echo "# Legacy state" > "$PROJECT/docs/plans/.cpm-progress.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"abc-123","source":"startup"}')
assert_contains "$OUTPUT" "# Legacy state"

test_start "Legacy file ignored when session-scoped files exist"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "sess-1" "cpm:do" "Task execution"
echo "# Legacy state" > "$PROJECT/docs/plans/.cpm-progress.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"sess-1","source":"startup"}')
assert_not_contains "$OUTPUT" "# Legacy state"

test_start "Shows continuation note when files are found"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "sess-1" "cpm:do" "Task execution"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"sess-1","source":"startup"}')
assert_contains "$OUTPUT" "NOTE: Found CPM session state"

# --- User name injection tests ---

run_hook_with_env() {
  local project_dir="$1"
  local stdin_input="$2"
  shift 2
  echo "$stdin_input" | env "$@" CLAUDE_PROJECT_DIR="$project_dir" bash "$HOOK_SCRIPT"
}

test_start "Outputs CPM_USER_NAME from env var when set"
PROJECT=$(setup_project_dir)
OUTPUT=$(run_hook_with_env "$PROJECT" '{"session_id":"abc-123","source":"startup"}' CPM_USER_NAME="Alice")
assert_contains "$OUTPUT" "CPM_USER_NAME: Alice"

test_start "Outputs behavioural directive with user name"
PROJECT=$(setup_project_dir)
OUTPUT=$(run_hook_with_env "$PROJECT" '{"session_id":"abc-123","source":"startup"}' CPM_USER_NAME="Alice")
assert_contains "$OUTPUT" 'use their name "Alice"'

test_start "Env var takes priority over git config"
PROJECT=$(setup_project_dir)
OUTPUT=$(run_hook_with_env "$PROJECT" '{"session_id":"abc-123","source":"startup"}' CPM_USER_NAME="Override")
assert_contains "$OUTPUT" "CPM_USER_NAME: Override"

test_start "Falls back to git config first name when env var is unset"
PROJECT=$(setup_project_dir)
# Use current git config — test just confirms name is resolved
OUTPUT=$(run_hook_with_env "$PROJECT" '{"session_id":"abc-123","source":"startup"}' CPM_USER_NAME=)
GIT_FIRST=$(git config user.name 2>/dev/null | awk '{print $1}')
if [ -n "$GIT_FIRST" ]; then
  assert_contains "$OUTPUT" "CPM_USER_NAME: $GIT_FIRST"
else
  # No git config available — should not output CPM_USER_NAME
  assert_not_contains "$OUTPUT" "CPM_USER_NAME"
fi

test_summary
