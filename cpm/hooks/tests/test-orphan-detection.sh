#!/bin/bash
# test-orphan-detection.sh — Tests for orphan detection in session-start.sh
#
# Tests cover session ID matching for orphan classification:
# - Files from other session IDs are flagged as orphans
# - Files matching current session ID are NOT flagged
# - No cleanup output when no orphans exist
# - Orphan output includes skill, phase, age, and file path
# - Age-based visual hints (STALE marker for >24h)
# - Each orphan is a separate block
# - No auto-executing delete commands

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
  # Set mtime to 72 hours ago (>24h threshold)
  local file="$1"
  touch -t "$(date -v-72H +%Y%m%d%H%M.%S 2>/dev/null || date -d '72 hours ago' +%Y%m%d%H%M.%S 2>/dev/null)" "$file"
}

# --- Orphan detection by session ID ---

test_start "Other-session file is flagged as orphan"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "ORPHAN"

test_start "Other-session file includes skill name in orphan block"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "Skill: cpm:spec"

test_start "Other-session file includes phase in orphan block"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "Phase: Section 3"

test_start "Other-session file includes age in orphan block"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "Age:"

test_start "Other-session file includes file path in orphan block"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "File:"
assert_contains "$OUTPUT" ".cpm-progress-old-session.md"

test_start "Current-session file is NOT flagged as orphan"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "my-session" "cpm:do" "Task execution"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"my-session","source":"startup"}')
assert_not_contains "$OUTPUT" "ORPHAN"

test_start "Current-session file is injected as active state"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "my-session" "cpm:do" "Task execution"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"my-session","source":"startup"}')
assert_contains "$OUTPUT" "--- CPM SESSION STATE"

test_start "No cleanup guidance when no orphan files exist"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "my-session" "cpm:do" "Task execution"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"my-session","source":"startup"}')
assert_not_contains "$OUTPUT" "ORPHAN CLEANUP REQUIRED"

test_start "No cleanup guidance when no files exist at all"
PROJECT=$(setup_project_dir)
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"my-session","source":"startup"}')
assert_not_contains "$OUTPUT" "ORPHAN"

# --- Orphan output never includes auto-executing commands ---

test_start "Orphan output does not auto-execute deletion"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_not_contains "$OUTPUT" "rm "
assert_not_contains "$OUTPUT" "rm -"

test_start "Orphan output instructs not to delete without confirmation"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "Do NOT delete"

test_start "Orphan output is marked as BLOCKING"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "BLOCKING"

test_start "Orphan output instructs to stop before proceeding"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "MUST stop"
assert_contains "$OUTPUT" "Do NOT proceed"

# --- Per-file blocks ---

test_start "Each orphan file is a separate block with delimiters"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-1" "cpm:spec" "Section 3"
create_progress_file "$PROJECT" "old-2" "cpm:do" "Task execution"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "--- ORPHAN FILE 1 ---"
assert_contains "$OUTPUT" "--- ORPHAN FILE 2 ---"
assert_contains "$OUTPUT" "--- END ORPHAN ---"

test_start "Orphan files and active files handled separately"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "current-session" "cpm:do" "Task execution"
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "--- CPM SESSION STATE (cpm:do"
assert_contains "$OUTPUT" "--- ORPHAN FILE 1 ---"

test_start "Orphan block for other-session file is NOT injected as active state"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_not_contains "$OUTPUT" "--- CPM SESSION STATE"

# --- Age-based visual hints ---

test_start "Fresh orphan file shows age without STALE marker"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-session" "cpm:do" "Task execution"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "Age:"
assert_not_contains "$OUTPUT" "STALE"

test_start "Stale orphan file (>24h) shows STALE marker"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-session.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "STALE"

test_start "Stale orphan file shows age in days"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-session.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "d old"

# --- Unified structure ---

test_start "Fresh and stale orphans use same block structure"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-1" "cpm:do" "Task execution"
create_progress_file "$PROJECT" "old-2" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-2.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
# Both should have ORPHAN FILE blocks with Skill/Phase/Age/File fields
assert_contains "$OUTPUT" "--- ORPHAN FILE 1 ---"
assert_contains "$OUTPUT" "--- ORPHAN FILE 2 ---"

test_summary
