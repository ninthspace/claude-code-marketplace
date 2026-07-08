#!/bin/bash
# test-progress-classify.sh — Tests for cpm/hooks/lib/progress-classify.sh
#
# Tests cover:
# - Classification: CURRENT (session match), FRESH (<3d other), STALE (>=3d other)
# - Current session is CURRENT at any age (never FRESH/STALE)
# - Threshold boundary: 3d0h -> STALE, 2d23h -> FRESH
# - Labelled records carry path, skill, phase, age
# - The 3-day threshold is a single named constant (not STALE_HOURS)
# - One record per file; no output when no files exist
# - Robustness: cross-platform stat, malformed/unreadable skip, never runs rm

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

HELPER="$SCRIPT_DIR/../lib/progress-classify.sh"

echo "Testing: progress-classify.sh"
echo "============================="

# --- Setup helpers ---

setup_state_dir() {
  local d="$TEST_TMPDIR/plans-$$-$RANDOM"
  mkdir -p "$d"
  echo "$d"
}

create_progress_file() {
  local dir="$1" session_id="$2" skill="$3" phase="$4"
  cat > "$dir/.cpm-progress-${session_id}.md" <<EOF
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

run_classify() {
  local session_id="$1" dir="$2"
  CPM_SESSION_ID="$session_id" bash "$HELPER" "$dir"
}

# Classification (field 1) of the record for a given file basename.
classification_for() {
  local output="$1" needle="$2"
  echo "$output" | grep -F "$needle" | cut -f1
}

# --- Classification ---

test_start "Current-session file is classified CURRENT"
DIR=$(setup_state_dir)
create_progress_file "$DIR" "sess-current" "cpm:do" "Task execution"
OUT=$(run_classify "sess-current" "$DIR")
assert_equals "CURRENT" "$(classification_for "$OUT" ".cpm-progress-sess-current.md")"

test_start "Other-session file younger than 3 days is FRESH"
DIR=$(setup_state_dir)
create_progress_file "$DIR" "sess-other" "cpm:spec" "Section 3"
set_mtime_hours_ago "$DIR/.cpm-progress-sess-other.md" 1
OUT=$(run_classify "sess-current" "$DIR")
assert_equals "FRESH" "$(classification_for "$OUT" ".cpm-progress-sess-other.md")"

test_start "Other-session file 3 days or older is STALE"
DIR=$(setup_state_dir)
create_progress_file "$DIR" "sess-old" "cpm:spec" "Section 3"
set_mtime_hours_ago "$DIR/.cpm-progress-sess-old.md" 96
OUT=$(run_classify "sess-current" "$DIR")
assert_equals "STALE" "$(classification_for "$OUT" ".cpm-progress-sess-old.md")"

test_start "Current-session file is CURRENT even when very old (never FRESH/STALE)"
DIR=$(setup_state_dir)
create_progress_file "$DIR" "sess-current" "cpm:do" "Task execution"
set_mtime_hours_ago "$DIR/.cpm-progress-sess-current.md" 240  # 10 days old
OUT=$(run_classify "sess-current" "$DIR")
assert_equals "CURRENT" "$(classification_for "$OUT" ".cpm-progress-sess-current.md")"

# --- Threshold boundary ---

test_start "Boundary: exactly 3 days (72h) is STALE"
DIR=$(setup_state_dir)
create_progress_file "$DIR" "b1" "cpm:do" "x"
set_mtime_hours_ago "$DIR/.cpm-progress-b1.md" 72
OUT=$(run_classify "cur" "$DIR")
assert_equals "STALE" "$(classification_for "$OUT" ".cpm-progress-b1.md")"

test_start "Boundary: 2d23h (71h) is FRESH"
DIR=$(setup_state_dir)
create_progress_file "$DIR" "b2" "cpm:do" "x"
set_mtime_hours_ago "$DIR/.cpm-progress-b2.md" 71
OUT=$(run_classify "cur" "$DIR")
assert_equals "FRESH" "$(classification_for "$OUT" ".cpm-progress-b2.md")"

# --- Labelled records ---

test_start "Record carries path, skill, and phase"
DIR=$(setup_state_dir)
create_progress_file "$DIR" "sess-1" "cpm:party" "Discussion in progress"
OUT=$(run_classify "cur" "$DIR")
LINE=$(echo "$OUT" | grep -F ".cpm-progress-sess-1.md")
assert_contains "$LINE" ".cpm-progress-sess-1.md"
assert_contains "$LINE" "cpm:party"
assert_contains "$LINE" "Discussion in progress"

test_start "Record carries a numeric age (seconds) field"
DIR=$(setup_state_dir)
create_progress_file "$DIR" "sess-1" "cpm:do" "x"
set_mtime_hours_ago "$DIR/.cpm-progress-sess-1.md" 5
OUT=$(run_classify "cur" "$DIR")
AGE=$(echo "$OUT" | grep -F ".cpm-progress-sess-1.md" | cut -f5)
if echo "$AGE" | grep -qE '^[0-9]+$'; then test_pass; else test_fail "age field not numeric: '$AGE'"; fi

# --- Named threshold constant ---

test_start "Threshold is a single named constant (CPM_STALE_THRESHOLD_DAYS), not STALE_HOURS"
if grep -qF "CPM_STALE_THRESHOLD_DAYS=" "$HELPER" && ! grep -qF "STALE_HOURS" "$HELPER"; then
  test_pass
else
  test_fail "Expected CPM_STALE_THRESHOLD_DAYS constant and no STALE_HOURS in helper"
fi

# --- Record cardinality ---

test_start "Emits one record per progress file"
DIR=$(setup_state_dir)
create_progress_file "$DIR" "a" "cpm:do" "x"
create_progress_file "$DIR" "b" "cpm:spec" "y"
OUT=$(run_classify "a" "$DIR")
COUNT=$(echo "$OUT" | grep -c "cpm-progress-")
assert_equals "2" "$COUNT"

test_start "No progress files: emits no output"
DIR=$(setup_state_dir)
OUT=$(run_classify "cur" "$DIR")
assert_empty "$OUT"

# --- Robustness & cross-platform ---

test_start "Cross-platform stat: helper uses both 'stat -f %m' and 'stat -c %Y'"
if grep -qF "stat -f %m" "$HELPER" && grep -qF "stat -c %Y" "$HELPER"; then
  test_pass
else
  test_fail "Expected both BSD (stat -f %m) and GNU (stat -c %Y) stat forms"
fi

test_start "Helper never runs a delete (no 'rm' in the source)"
if grep -qE '(^|[^a-zA-Z])rm([[:space:]]|$)' "$HELPER"; then
  test_fail "Helper source contains an 'rm' invocation"
else
  test_pass
fi

test_start "Malformed entry (broken symlink) is skipped; valid file still classified"
DIR=$(setup_state_dir)
create_progress_file "$DIR" "good" "cpm:do" "x"
ln -s "$DIR/nonexistent-target.md" "$DIR/.cpm-progress-broken.md"
OUT=$(run_classify "good" "$DIR")
assert_contains "$OUT" ".cpm-progress-good.md"
assert_not_contains "$OUT" ".cpm-progress-broken.md"

test_start "Unreadable file is skipped; helper still exits cleanly (exit 0)"
DIR=$(setup_state_dir)
create_progress_file "$DIR" "good" "cpm:do" "x"
create_progress_file "$DIR" "locked" "cpm:spec" "y"
chmod 000 "$DIR/.cpm-progress-locked.md"
if [ -r "$DIR/.cpm-progress-locked.md" ]; then
  # Running as root (perms ignored) — cannot exercise the unreadable path; skip.
  chmod 644 "$DIR/.cpm-progress-locked.md"
  test_pass
else
  OUT=$(run_classify "good" "$DIR"); RC=$?
  chmod 644 "$DIR/.cpm-progress-locked.md"
  if [ "$RC" -eq 0 ] && echo "$OUT" | grep -qF ".cpm-progress-good.md" && ! echo "$OUT" | grep -qF ".cpm-progress-locked.md"; then
    test_pass
  else
    test_fail "Expected exit 0, good file classified, locked file skipped (rc=$RC)"
  fi
fi

test_start "Missing state dir: no output, exits cleanly (exit 0)"
OUT=$(CPM_SESSION_ID="cur" bash "$HELPER" "$TEST_TMPDIR/does-not-exist"); RC=$?
if [ "$RC" -eq 0 ]; then
  assert_empty "$OUT"
else
  test_fail "Expected clean exit 0 for missing state dir (rc=$RC)"
fi

test_start "Legacy unsuffixed .cpm-progress.md is not matched by the glob"
DIR=$(setup_state_dir)
echo "# Legacy" > "$DIR/.cpm-progress.md"
OUT=$(run_classify "cur" "$DIR")
assert_empty "$OUT"

# --- list-all mode (compact-summary companions, for /cpm:clean) ---

create_compact_summary() {
  local dir="$1" session_id="$2"
  cat > "$dir/.cpm-compact-summary-${session_id}.md" <<EOF
# Compact Summary (PostCompact)
**Captured**: 2026-07-08 11:06:06
**Trigger**: auto

<analysis>
Test compact-summary body.
</analysis>
EOF
}

run_classify_list_all() {
  local session_id="$1" dir="$2"
  CPM_SESSION_ID="$session_id" bash "$HELPER" "$dir" list-all
}

test_start "Default mode does NOT emit compact-summary records (hook output unchanged)"
DIR=$(setup_state_dir)
create_progress_file "$DIR" "p1" "cpm:do" "x"
create_compact_summary "$DIR" "p1"
OUT=$(run_classify "p1" "$DIR")
assert_contains "$OUT" ".cpm-progress-p1.md"
assert_not_contains "$OUT" ".cpm-compact-summary-p1.md"

test_start "list-all mode emits a record for a compact-summary companion alongside its progress file"
DIR=$(setup_state_dir)
create_progress_file "$DIR" "p1" "cpm:do" "x"
create_compact_summary "$DIR" "p1"
OUT=$(run_classify_list_all "p1" "$DIR")
assert_contains "$OUT" ".cpm-progress-p1.md"
assert_contains "$OUT" ".cpm-compact-summary-p1.md"

test_start "list-all classifies a compact-summary by session id (CURRENT for match)"
DIR=$(setup_state_dir)
create_compact_summary "$DIR" "cur"
OUT=$(run_classify_list_all "cur" "$DIR")
assert_equals "CURRENT" "$(classification_for "$OUT" ".cpm-compact-summary-cur.md")"

test_start "list-all: an old other-session compact-summary is STALE"
DIR=$(setup_state_dir)
create_compact_summary "$DIR" "old"
set_mtime_hours_ago "$DIR/.cpm-compact-summary-old.md" 96
OUT=$(run_classify_list_all "cur" "$DIR")
assert_equals "STALE" "$(classification_for "$OUT" ".cpm-compact-summary-old.md")"

test_start "list-all: compact-summary record carries path + numeric age; SKILL reads 'unknown'"
DIR=$(setup_state_dir)
create_compact_summary "$DIR" "s1"
OUT=$(run_classify_list_all "cur" "$DIR")
LINE=$(echo "$OUT" | grep -F ".cpm-compact-summary-s1.md")
assert_contains "$LINE" ".cpm-compact-summary-s1.md"
assert_contains "$LINE" "unknown"
AGE=$(echo "$LINE" | cut -f5)
if echo "$AGE" | grep -qE '^[0-9]+$'; then test_pass; else test_fail "age field not numeric: '$AGE'"; fi

test_start "list-all with no files: emits no output, exits cleanly (exit 0)"
DIR=$(setup_state_dir)
OUT=$(run_classify_list_all "cur" "$DIR"); RC=$?
if [ "$RC" -eq 0 ]; then assert_empty "$OUT"; else test_fail "expected clean exit (rc=$RC)"; fi

test_summary
