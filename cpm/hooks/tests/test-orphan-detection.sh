#!/bin/bash
# test-orphan-detection.sh — Tests for three-way progress-file presentation in
# session-start.sh (post classifier refactor, spec 38).
#
# session-start.sh classifies every session-scoped progress file via the shared
# helper (lib/progress-classify.sh) and presents three ways, non-blocking:
#   - CURRENT (current session)      -> injected as active state
#   - STALE   (other session, >=3d)  -> cleanup candidate, offered (not forced)
#   - FRESH   (other session, <3d)   -> active/recent parallel session, informational
#
# Tests cover:
# - Stale other-session file -> cleanup-candidate section, STALE label, record fields
# - Fresh other-session file -> informational parallel-session section, never offered
# - Current-session file -> active state, not in stale/fresh sections
# - No BLOCKING / halt language anywhere
# - Output derives from the helper's 3-day threshold (a 2-day file is FRESH, not stale)
# - No auto-executing deletion in the cleanup output

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

HOOK_SCRIPT="$SCRIPT_DIR/../session-start.sh"

echo "Testing: three-way progress-file presentation in session-start.sh"
echo "================================================================="

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

# Set a file's mtime to N hours ago (cross-platform: BSD then GNU date).
set_mtime_hours_ago() {
  local file="$1" hours="$2"
  touch -t "$(date -v-"${hours}"H +%Y%m%d%H%M.%S 2>/dev/null || date -d "${hours} hours ago" +%Y%m%d%H%M.%S 2>/dev/null)" "$file"
}

make_stale() {
  # 72h ago = 3 days = at/over the staleness threshold -> STALE
  set_mtime_hours_ago "$1" 72
}

# --- Stale other-session files (cleanup candidates) ---

test_start "Stale other-session file is presented as a cleanup candidate"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-session.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "STALE PROGRESS FILES"

test_start "Stale other-session file carries the STALE age label"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-session.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "STALE"

test_start "Stale record includes skill, phase, age, and file path"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-session.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "Skill: cpm:spec"
assert_contains "$OUTPUT" "Phase: Section 3"
assert_contains "$OUTPUT" "Age:"
assert_contains "$OUTPUT" ".cpm-progress-old-session.md"

# --- Fresh other-session files (informational parallel sessions) ---

test_start "Fresh other-session file is presented as an informational parallel session"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "other-session" "cpm:party" "Discussion"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "PARALLEL SESSION"
assert_contains "$OUTPUT" "informational"

test_start "Fresh other-session file is explicitly not offered for deletion"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "other-session" "cpm:party" "Discussion"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "Do not offer them for deletion"

test_start "Fresh-only: no stale cleanup-candidate section appears"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "other-session" "cpm:party" "Discussion"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_not_contains "$OUTPUT" "STALE PROGRESS FILES"

# --- Current-session file (active state) ---

test_start "Current-session file is injected as active state"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "my-session" "cpm:do" "Task execution"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"my-session","source":"startup"}')
assert_contains "$OUTPUT" "--- CPM SESSION STATE"

test_start "Current-session file is not treated as stale or parallel"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "my-session" "cpm:do" "Task execution"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"my-session","source":"startup"}')
assert_not_contains "$OUTPUT" "STALE PROGRESS FILES"
assert_not_contains "$OUTPUT" "PARALLEL SESSION"

# --- Non-blocking: no BLOCKING / halt language ---

test_start "Stale files present: output has no BLOCKING/halt language"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-session.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_not_contains "$OUTPUT" "BLOCKING"
assert_not_contains "$OUTPUT" "MUST stop"
assert_not_contains "$OUTPUT" "Do NOT proceed"
assert_not_contains "$OUTPUT" "ORPHAN CLEANUP REQUIRED"

test_start "Stale files present: output stays non-blocking (says carry on)"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-session.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "non-blocking"

# --- Derived from the helper's 3-day threshold ---

test_start "Uses helper's 3-day threshold: a 2-day-old other-session file is FRESH, not stale"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "two-day" "cpm:do" "Task execution"
set_mtime_hours_ago "$PROJECT/docs/plans/.cpm-progress-two-day.md" 48
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "ACTIVE/RECENT PARALLEL SESSIONS"
assert_not_contains "$OUTPUT" "STALE PROGRESS FILES"

# --- Combinations ---

test_start "Both stale and fresh present: both sections appear"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "fresh-1" "cpm:do" "Task execution"
create_progress_file "$PROJECT" "stale-1" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-stale-1.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "STALE PROGRESS FILES"
assert_contains "$OUTPUT" "ACTIVE/RECENT PARALLEL SESSIONS"

test_start "Current + stale present: active state and cleanup candidate, still non-blocking"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "current-session" "cpm:do" "Task execution"
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-session.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_contains "$OUTPUT" "--- CPM SESSION STATE (cpm:do"
assert_contains "$OUTPUT" "STALE PROGRESS FILES"
assert_not_contains "$OUTPUT" "BLOCKING"

# --- No files / no cleanup output ---

test_start "No files: no stale or parallel sections"
PROJECT=$(setup_project_dir)
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
assert_not_contains "$OUTPUT" "STALE PROGRESS FILES"
assert_not_contains "$OUTPUT" "PARALLEL SESSION"

test_start "Only current file: no stale or parallel sections"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "my-session" "cpm:do" "Task execution"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"my-session","source":"startup"}')
assert_not_contains "$OUTPUT" "STALE PROGRESS FILES"
assert_not_contains "$OUTPUT" "PARALLEL SESSION"

# --- Cleanup output never auto-executes a delete ---

test_start "Stale cleanup output does not auto-execute deletion"
PROJECT=$(setup_project_dir)
create_progress_file "$PROJECT" "old-session" "cpm:spec" "Section 3"
make_stale "$PROJECT/docs/plans/.cpm-progress-old-session.md"
OUTPUT=$(run_hook "$PROJECT" '{"session_id":"current-session","source":"startup"}')
# Scope to the stale section — the shared conventions doc injected earlier
# legitimately shows an `rm` example unrelated to stale-file handling.
STALE_SECTION=$(echo "$OUTPUT" | sed -n '/STALE PROGRESS FILES/,$p')
assert_not_contains "$STALE_SECTION" "rm "
assert_not_contains "$STALE_SECTION" "rm -"

test_summary
