#!/bin/bash
# test-hooks-integration.sh — Cross-hook integration for the classifier refactor
#
# Exercises the helper -> hook output contract end-to-end. A single shared,
# populated docs/plans fixture (current + fresh-other + stale-other progress
# files) is classified once by lib/progress-classify.sh to establish ground
# truth, then both hooks are run against that SAME fixture and their active-state
# decisions are asserted to agree with the helper's classification:
#
#   - CURRENT -> injected as active state by both hooks
#   - FRESH   -> never active state (informational in startup; not injected on clear)
#   - STALE   -> never active state (cleanup candidate in startup; not injected on clear)
#
# The "startup" source is driven through session-start.sh; the "clear" source
# through session-start-compact.sh.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

STARTUP_HOOK="$SCRIPT_DIR/../session-start.sh"
COMPACT_HOOK="$SCRIPT_DIR/../session-start-compact.sh"
CLASSIFIER="$SCRIPT_DIR/../lib/progress-classify.sh"

echo "Testing: cross-hook integration (helper -> session-start.sh / session-start-compact.sh)"
echo "======================================================================================="

# Distinct body markers so we can tell active-state injection (file body is cat'd)
# from mere metadata mention (skill/phase/path only).
CUR_ID="cur-session"
FRESH_ID="fresh-other"
STALE_ID="stale-other"

set_mtime_hours_ago() {
  local file="$1" hours="$2"
  touch -t "$(date -v-"${hours}"H +%Y%m%d%H%M.%S 2>/dev/null || date -d "${hours} hours ago" +%Y%m%d%H%M.%S 2>/dev/null)" "$file"
}

# Build the shared fixture and echo the project dir.
setup_shared_fixture() {
  local project_dir="$TEST_TMPDIR/integration-$$-$RANDOM"
  mkdir -p "$project_dir/docs/plans"
  local plans="$project_dir/docs/plans"

  printf '# CPM Session State\n\n**Skill**: cpm:do\n**Phase**: Task execution\n\nBODY-CUR-MARKER\n'    > "$plans/.cpm-progress-${CUR_ID}.md"
  printf '# CPM Session State\n\n**Skill**: cpm:party\n**Phase**: Discussion\n\nBODY-FRESH-MARKER\n'   > "$plans/.cpm-progress-${FRESH_ID}.md"
  printf '# CPM Session State\n\n**Skill**: cpm:spec\n**Phase**: Section 3\n\nBODY-STALE-MARKER\n'      > "$plans/.cpm-progress-${STALE_ID}.md"

  # fresh-other: recent (~0h). stale-other: 96h (>= 3-day threshold).
  set_mtime_hours_ago "$plans/.cpm-progress-${STALE_ID}.md" 96

  echo "$project_dir"
}

run_startup() {
  local project_dir="$1" session_id="$2"
  echo "{\"session_id\":\"$session_id\",\"source\":\"startup\"}" | CLAUDE_PROJECT_DIR="$project_dir" bash "$STARTUP_HOOK"
}

run_compact() {
  local project_dir="$1" session_id="$2" source="$3"
  echo "{\"session_id\":\"$session_id\",\"source\":\"$source\"}" | CLAUDE_PROJECT_DIR="$project_dir" bash "$COMPACT_HOOK"
}

# --- Ground truth: the helper classifies the shared fixture ---

test_start "Helper classifies the shared fixture: CUR=CURRENT, fresh=FRESH, stale=STALE"
PROJECT=$(setup_shared_fixture)
RECORDS=$(CPM_SESSION_ID="$CUR_ID" bash "$CLASSIFIER" "$PROJECT/docs/plans")
CUR_CLASS=$(echo "$RECORDS" | grep -F ".cpm-progress-${CUR_ID}.md" | cut -f1)
FRESH_CLASS=$(echo "$RECORDS" | grep -F ".cpm-progress-${FRESH_ID}.md" | cut -f1)
STALE_CLASS=$(echo "$RECORDS" | grep -F ".cpm-progress-${STALE_ID}.md" | cut -f1)
if [ "$CUR_CLASS" = "CURRENT" ] && [ "$FRESH_CLASS" = "FRESH" ] && [ "$STALE_CLASS" = "STALE" ]; then
  test_pass
else
  test_fail "Expected CURRENT/FRESH/STALE, got $CUR_CLASS/$FRESH_CLASS/$STALE_CLASS"
fi

# --- startup source (session-start.sh) matches the helper ---

test_start "startup: CURRENT file body is injected as active state"
PROJECT=$(setup_shared_fixture)
OUTPUT=$(run_startup "$PROJECT" "$CUR_ID")
assert_contains "$OUTPUT" "BODY-CUR-MARKER"
assert_contains "$OUTPUT" "--- CPM SESSION STATE"

test_start "startup: FRESH other-session file is informational, not active state"
PROJECT=$(setup_shared_fixture)
OUTPUT=$(run_startup "$PROJECT" "$CUR_ID")
assert_not_contains "$OUTPUT" "BODY-FRESH-MARKER"
assert_contains "$OUTPUT" "ACTIVE/RECENT PARALLEL SESSIONS"

test_start "startup: STALE other-session file is a cleanup candidate, not active state"
PROJECT=$(setup_shared_fixture)
OUTPUT=$(run_startup "$PROJECT" "$CUR_ID")
assert_not_contains "$OUTPUT" "BODY-STALE-MARKER"
assert_contains "$OUTPUT" "cleanup candidate"

test_start "startup: non-blocking (no BLOCKING/halt language) with mixed fixture"
PROJECT=$(setup_shared_fixture)
OUTPUT=$(run_startup "$PROJECT" "$CUR_ID")
assert_not_contains "$OUTPUT" "BLOCKING"
assert_not_contains "$OUTPUT" "MUST stop"

# --- clear source (session-start-compact.sh) matches the helper ---

test_start "clear (matching id): only the CURRENT file body is injected; fresh/stale are not"
PROJECT=$(setup_shared_fixture)
OUTPUT=$(run_compact "$PROJECT" "$CUR_ID" "clear")
assert_contains "$OUTPUT" "BODY-CUR-MARKER"
assert_not_contains "$OUTPUT" "BODY-FRESH-MARKER"
assert_not_contains "$OUTPUT" "BODY-STALE-MARKER"

test_start "clear (fresh new id, no match): no fixture file is injected as active state"
PROJECT=$(setup_shared_fixture)
OUTPUT=$(run_compact "$PROJECT" "brand-new-session" "clear")
assert_not_contains "$OUTPUT" "BODY-CUR-MARKER"
assert_not_contains "$OUTPUT" "BODY-FRESH-MARKER"
assert_not_contains "$OUTPUT" "BODY-STALE-MARKER"

# --- Both hooks agree on the CURRENT set for the same fixture ---

test_start "Both hooks inject the same CURRENT file as active state for the shared fixture"
PROJECT=$(setup_shared_fixture)
STARTUP_OUT=$(run_startup "$PROJECT" "$CUR_ID")
COMPACT_OUT=$(run_compact "$PROJECT" "$CUR_ID" "clear")
if echo "$STARTUP_OUT" | grep -qF "BODY-CUR-MARKER" && echo "$COMPACT_OUT" | grep -qF "BODY-CUR-MARKER"; then
  test_pass
else
  test_fail "Both hooks should inject the CURRENT file body"
fi

test_summary
