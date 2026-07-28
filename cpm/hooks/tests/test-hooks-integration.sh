#!/bin/bash
# test-hooks-integration.sh — Cross-hook integration for the classifier refactor
#
# Exercises the helper -> hook output contract end-to-end. A single shared,
# populated docs/plans fixture (current + fresh-other + stale-other progress
# files) is classified once by lib/progress-classify.sh to establish ground
# truth, then both hooks are run against that SAME fixture and their active-state
# decisions are asserted to agree with the helper's classification:
#
#   - CURRENT -> presented as active state by both hooks
#   - FRESH   -> never active state (informational in startup; absent on clear)
#   - STALE   -> never active state (cleanup candidate in startup; absent on clear)
#
# The "startup" source is driven through session-start.sh; the "clear" source
# through session-start-compact.sh.
#
# **What distinguishes active state from a mention.** Neither hook emits a progress file
# body — both name it, because a payload whose length is set by a document is a payload
# that gets truncated. So presence of a filename proves nothing on its own: the startup
# hook prints `File: {path}` for every stale and parallel file too. The discriminator is
# *placement* — a filename inside the `--- CPM SESSION STATE ... --- END ---` block is
# active state, and the same filename anywhere else is a mention. Every assertion below
# slices that block first and asks what is inside it, which is a stricter question than
# the body markers used to answer: a hook that named all three files in the state block
# would have passed the old check for CURRENT and fails this one.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

STARTUP_HOOK="$SCRIPT_DIR/../session-start.sh"
COMPACT_HOOK="$SCRIPT_DIR/../session-start-compact.sh"
CLASSIFIER="$SCRIPT_DIR/../lib/progress-classify.sh"

echo "Testing: cross-hook integration (helper -> session-start.sh / session-start-compact.sh)"
echo "======================================================================================="

# Distinct session ids, so each fixture file has a distinguishable filename. The filename
# is what the hooks emit, and which block it lands in is what the assertions read.
CUR_ID="cur-session"
FRESH_ID="fresh-other"
STALE_ID="stale-other"

# The active-state block, whichever hook produced it. Both open `--- CPM SESSION STATE`
# and close `--- END ---`; the startup form carries the skill and phase in its heading and
# the compact form says "recovered after compaction", so the opener is matched by prefix.
session_state_block() {
  awk '/^--- CPM SESSION STATE/ { inside = 1 }
       inside { print }
       inside && /^--- END ---$/ { inside = 0 }'
}

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

# The hooks pass the classifier's stderr through, and the classifier now reports
# its resolved project root there. These tests assert on hook stdout, so the
# diagnostic is dropped to keep the suite output readable.
run_startup() {
  local project_dir="$1" session_id="$2"
  echo "{\"session_id\":\"$session_id\",\"source\":\"startup\"}" | CLAUDE_PROJECT_DIR="$project_dir" bash "$STARTUP_HOOK" 2>/dev/null
}

run_compact() {
  local project_dir="$1" session_id="$2" source="$3"
  echo "{\"session_id\":\"$session_id\",\"source\":\"$source\"}" | CLAUDE_PROJECT_DIR="$project_dir" bash "$COMPACT_HOOK" 2>/dev/null
}

# --- Ground truth: the helper classifies the shared fixture ---

test_start "Helper classifies the shared fixture: CUR=CURRENT, fresh=FRESH, stale=STALE"
PROJECT=$(setup_shared_fixture)
RECORDS=$(CPM_SESSION_ID="$CUR_ID" bash "$CLASSIFIER" "$PROJECT/docs/plans" 2>/dev/null)
CUR_CLASS=$(echo "$RECORDS" | grep -F ".cpm-progress-${CUR_ID}.md" | cut -f1)
FRESH_CLASS=$(echo "$RECORDS" | grep -F ".cpm-progress-${FRESH_ID}.md" | cut -f1)
STALE_CLASS=$(echo "$RECORDS" | grep -F ".cpm-progress-${STALE_ID}.md" | cut -f1)
if [ "$CUR_CLASS" = "CURRENT" ] && [ "$FRESH_CLASS" = "FRESH" ] && [ "$STALE_CLASS" = "STALE" ]; then
  test_pass
else
  test_fail "Expected CURRENT/FRESH/STALE, got $CUR_CLASS/$FRESH_CLASS/$STALE_CLASS"
fi

# --- startup source (session-start.sh) matches the helper ---

test_start "startup: the CURRENT file is named inside the active-state block"
PROJECT=$(setup_shared_fixture)
OUTPUT=$(run_startup "$PROJECT" "$CUR_ID")
assert_contains "$OUTPUT" "--- CPM SESSION STATE"
assert_contains "$(echo "$OUTPUT" | session_state_block)" ".cpm-progress-${CUR_ID}.md"

# The other side of the discriminator. Both other-session files are named elsewhere in this
# same output, so without this pair the assertion above would also pass a hook that put
# every file in the state block.
test_start "startup: the FRESH and STALE files are named, but NOT inside the active-state block"
BLOCK=$(echo "$OUTPUT" | session_state_block)
assert_contains "$OUTPUT" ".cpm-progress-${FRESH_ID}.md"
assert_contains "$OUTPUT" ".cpm-progress-${STALE_ID}.md"
assert_not_contains "$BLOCK" ".cpm-progress-${FRESH_ID}.md"
assert_not_contains "$BLOCK" ".cpm-progress-${STALE_ID}.md"

# Payload bounding, asserted where it can regress: no progress file body, of any
# classification, reaches the output. A `cat` restored anywhere in the hook fires this.
test_start "startup: no progress file body is emitted, for any classification"
assert_not_contains "$OUTPUT" "BODY-CUR-MARKER"
assert_not_contains "$OUTPUT" "BODY-FRESH-MARKER"
assert_not_contains "$OUTPUT" "BODY-STALE-MARKER"

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

test_start "clear (matching id): only the CURRENT file is named; fresh/stale are not named at all"
PROJECT=$(setup_shared_fixture)
OUTPUT=$(run_compact "$PROJECT" "$CUR_ID" "clear")
assert_contains "$(echo "$OUTPUT" | session_state_block)" ".cpm-progress-${CUR_ID}.md"
assert_not_contains "$OUTPUT" ".cpm-progress-${FRESH_ID}.md"
assert_not_contains "$OUTPUT" ".cpm-progress-${STALE_ID}.md"

test_start "clear (matching id): no progress file body is emitted"
assert_not_contains "$OUTPUT" "BODY-CUR-MARKER"
assert_not_contains "$OUTPUT" "BODY-FRESH-MARKER"
assert_not_contains "$OUTPUT" "BODY-STALE-MARKER"

test_start "clear (fresh new id, no match): no fixture file is presented as active state"
PROJECT=$(setup_shared_fixture)
OUTPUT=$(run_compact "$PROJECT" "brand-new-session" "clear")
assert_not_contains "$OUTPUT" ".cpm-progress-${CUR_ID}.md"
assert_not_contains "$OUTPUT" ".cpm-progress-${FRESH_ID}.md"
assert_not_contains "$OUTPUT" ".cpm-progress-${STALE_ID}.md"
assert_not_contains "$OUTPUT" "BODY-CUR-MARKER"

# --- Both hooks agree on the CURRENT set for the same fixture ---

test_start "Both hooks name the same CURRENT file as active state for the shared fixture"
PROJECT=$(setup_shared_fixture)
STARTUP_BLOCK=$(run_startup "$PROJECT" "$CUR_ID" | session_state_block)
COMPACT_BLOCK=$(run_compact "$PROJECT" "$CUR_ID" "clear" | session_state_block)
STARTUP_NAMED=$(printf '%s' "$STARTUP_BLOCK" | grep -o '\.cpm-progress-[a-z-]*\.md' | head -1)
COMPACT_NAMED=$(printf '%s' "$COMPACT_BLOCK" | grep -o '\.cpm-progress-[a-z-]*\.md' | head -1)
# Read out of each hook rather than compared to a literal, so a fixture rename that both
# hooks follow stays green and one hook drifting apart from the other fails.
assert_agrees "the file each hook presents as active state" \
  "session-start.sh" "$STARTUP_NAMED" \
  "session-start-compact.sh" "$COMPACT_NAMED"

# --- The classifier reaches the same fixture from skill context ---
#
# Everything above runs the classifier the way the hooks do: explicit state dir,
# CLAUDE_PROJECT_DIR set. A /cpm:* skill calls it with neither. This case must
# not export the variable — the unset environment is the requirement.

test_start "Classifier reaches the shared fixture with no argument and CLAUDE_PROJECT_DIR unset"
PROJECT=$(cd "$(setup_shared_fixture)" && pwd -P)
RECORDS=$( cd "$PROJECT" && export CPM_SESSION_ID="$CUR_ID" \
    && run_without_env CLAUDE_PROJECT_DIR -- bash "$CLASSIFIER" 2>/dev/null )
assert_equals "CURRENT" "$(echo "$RECORDS" | grep -F ".cpm-progress-${CUR_ID}.md" | cut -f1)"

# --- Dual path: one project root, both call shapes, same docs/plans ---
#
# The hook arm (variable set, explicit state dir) and the skill arm (variable
# absent, no argument) must land on the same directory. "Both locate the same
# docs/plans" is only worth asserting once the two arms are known to be
# genuinely different and each to have located something — otherwise it passes
# by comparing one empty result to another, or one arm to itself. The four
# assertions below establish that before the comparison is made.

DUAL=$(cd "$(setup_shared_fixture)" && pwd -P)

test_start "dual-path: the hook arm really does run with CLAUDE_PROJECT_DIR set"
PROBE=$(CLAUDE_PROJECT_DIR="$DUAL" bash -c 'printf "%s" "${CLAUDE_PROJECT_DIR+set}"')
assert_equals "set" "$PROBE"

test_start "dual-path: the skill arm really does run with CLAUDE_PROJECT_DIR unset"
PROBE=$(run_without_env CLAUDE_PROJECT_DIR -- bash -c 'printf "%s" "${CLAUDE_PROJECT_DIR+set}"')
assert_equals "" "$PROBE"

test_start "dual-path: the hook-context call locates a progress file"
HOOK_PATH=$(CPM_SESSION_ID="$CUR_ID" CLAUDE_PROJECT_DIR="$DUAL" bash "$CLASSIFIER" "$DUAL/docs/plans" 2>/dev/null \
  | grep -F ".cpm-progress-${CUR_ID}.md" | cut -f2)
if [ -n "$HOOK_PATH" ]; then test_pass; else test_fail "hook-context call located nothing"; fi

test_start "dual-path: the skill-context call locates a progress file"
SKILL_PATH=$( cd "$DUAL" && export CPM_SESSION_ID="$CUR_ID" \
    && run_without_env CLAUDE_PROJECT_DIR -- bash "$CLASSIFIER" 2>/dev/null \
    | grep -F ".cpm-progress-${CUR_ID}.md" | cut -f2 )
if [ -n "$SKILL_PATH" ]; then test_pass; else test_fail "skill-context call located nothing"; fi

test_start "dual-path: both arms locate the same docs/plans"
assert_equals "$HOOK_PATH" "$SKILL_PATH"

test_start "dual-path: the shared path is the fixture's own docs/plans"
assert_equals "$DUAL/docs/plans/.cpm-progress-${CUR_ID}.md" "$HOOK_PATH"

test_summary
