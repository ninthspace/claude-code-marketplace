#!/bin/bash
# test-orphan-detection.sh — Tests for orphan detection in session-start.sh
#
# Tests cover:
# - Fresh files are not flagged as stale
# - Stale files (>48h) are flagged
# - Stale files show readable context (skill, phase)
# - Stale files include file path for deletion
# - Mixed fresh and stale files handled correctly
# - Stale files are not injected as active state

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

HOOK_SCRIPT="$SCRIPT_DIR/../session-start.sh"

echo "Testing: orphan detection in session-start.sh"
echo "=============================================="

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

make_stale() {
  # Set mtime to 72 hours ago
  local file="$1"
  touch -t "$(date -v-72H +%Y%m%d%H%M.%S 2>/dev/null || date -d '72 hours ago' +%Y%m%d%H%M.%S 2>/dev/null)" "$file"
}

# --- Tests ---

test_start "Fresh files are not flagged as stale"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "fresh-1" "cpm:do" "Task execution"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"other","source":"startup"}')
assert_not_contains "$OUTPUT" "STALE"

test_start "Fresh files are not flagged with WARNING"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "fresh-1" "cpm:do" "Task execution"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"other","source":"startup"}')
assert_not_contains "$OUTPUT" "WARNING"

test_start "Stale files are flagged with STALE prefix"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-1" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-1.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"other","source":"startup"}')
assert_contains "$OUTPUT" "STALE:"

test_start "Stale file message includes skill name"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-1" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-1.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"other","source":"startup"}')
assert_contains "$OUTPUT" "cpm:spec"

test_start "Stale file message includes phase"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-1" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-1.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"other","source":"startup"}')
assert_contains "$OUTPUT" "Section 3"

test_start "Stale file message includes file path for deletion"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-1" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-1.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"other","source":"startup"}')
assert_contains "$OUTPUT" ".cpm-progress-old-1.md"

test_start "Stale file message includes age in hours"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-1" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-1.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"other","source":"startup"}')
assert_contains "$OUTPUT" "h old"

test_start "Stale files show WARNING header"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-1" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-1.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"other","source":"startup"}')
assert_contains "$OUTPUT" "WARNING"

test_start "Stale files suggest asking user about deletion"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-1" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-1.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"other","source":"startup"}')
assert_contains "$OUTPUT" "delete"

test_start "Stale files are NOT injected as active session state"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-1" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-1.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"other","source":"startup"}')
assert_not_contains "$OUTPUT" "--- CPM SESSION STATE"

test_start "Mixed: fresh file injected, stale file flagged separately"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "fresh-1" "cpm:do" "Task execution"
create_progress_file "$PROJECT" "old-1" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-1.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"other","source":"startup"}')
assert_contains "$OUTPUT" "--- CPM SESSION STATE (cpm:do"

test_start "Mixed: stale file flagged but not in active state section"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "fresh-1" "cpm:do" "Task execution"
create_progress_file "$PROJECT" "old-1" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-1.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"other","source":"startup"}')
assert_contains "$OUTPUT" "STALE: cpm:spec"

test_summary
