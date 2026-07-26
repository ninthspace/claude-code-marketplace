#!/bin/bash
# test-cleancheck-guard.sh — Tests for cpm/hooks/lib/cleancheck-guard.sh
#
# Tests cover:
# - RUN when no sentinel and no ralph loop; writes the sentinel
# - SKIP when the current session's sentinel exists (never RUN in that case)
# - SUPPRESS when the ralph state file is present, regardless of sentinel state
# - Sentinel path .cpm-cleancheck-{id} sits outside the .cpm-progress-*.md glob
# - Sentinel write failure fails safe (RUN); guard never deletes (no rm)
# - Empty session id fails safe to RUN
# - All three tokens under the skills' own calling convention: the invocation
#   extracted from shared/skill-conventions.md, run with CLAUDE_PROJECT_DIR
#   genuinely unset

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GUARD="$SCRIPT_DIR/../lib/cleancheck-guard.sh"
CLASSIFIER="$SCRIPT_DIR/../lib/progress-classify.sh"
CONVENTIONS="$PLUGIN_ROOT/shared/skill-conventions.md"

echo "Testing: cleancheck-guard.sh"
echo "============================"

# Build a project dir with docs/plans; echo its path.
setup_project_dir() {
  local project_dir="$TEST_TMPDIR/guard-$$-$RANDOM"
  mkdir -p "$project_dir/docs/plans"
  echo "$project_dir"
}

# Run the guard with a session id against a project dir. The guard reports its
# resolved project root on stderr; these tests assert on the token it prints to
# stdout, so the diagnostic is dropped here to keep the output readable.
# test-project-root-resolution.sh is where that stderr line is asserted.
run_guard() {
  local session_id="$1" project_dir="$2"
  CPM_SESSION_ID="$session_id" CLAUDE_PROJECT_DIR="$project_dir" bash "$GUARD" "$project_dir/docs/plans" 2>/dev/null
}

make_ralph_active() {
  local project_dir="$1"
  mkdir -p "$project_dir/.claude"
  printf 'iteration: 1\nmax_iterations: 10\n' > "$project_dir/.claude/ralph-loop.local.md"
}

# The guard invocation as shared/skill-conventions.md documents it, lifted out
# of the file rather than re-typed. Every /cpm:* skill runs this exact line, and
# a re-typed copy would keep passing after the documented one drifted — which is
# how a guard that could never return SUPPRESS or SKIP from skill context sat
# behind a green suite for months.
extract_guard_command() {
  grep -m1 -F 'bash "${CLAUDE_PLUGIN_ROOT}/hooks/lib/cleancheck-guard.sh"' "$CONVENTIONS" \
    | sed -e 's/^[[:space:]]*`//' -e 's/`[[:space:]]*$//'
}

# Run that command the way a skill does: CLAUDE_PLUGIN_ROOT set, cwd inside the
# project, and CLAUDE_PROJECT_DIR *removed* from the environment. The unset case
# is the requirement, so nothing here may export it.
run_guard_as_skill() {
  local project_dir="$1" session_id="$2" cmd
  cmd=$(extract_guard_command)
  ( cd "$project_dir" \
      && export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" CPM_SESSION_ID="$session_id" \
      && run_without_env CLAUDE_PROJECT_DIR -- bash -c "$cmd" 2>/dev/null )
}

# --- RUN / sentinel write ---

test_start "RUN when no sentinel and no ralph loop"
PROJECT=$(setup_project_dir)
OUT=$(run_guard "sess-1" "$PROJECT")
assert_equals "RUN" "$OUT"

test_start "RUN writes the session sentinel"
PROJECT=$(setup_project_dir)
run_guard "sess-1" "$PROJECT" >/dev/null
if [ -f "$PROJECT/docs/plans/.cpm-cleancheck-sess-1" ]; then test_pass; else test_fail "sentinel not written"; fi

# --- SKIP ---

test_start "SKIP when the current session's sentinel already exists"
PROJECT=$(setup_project_dir)
: > "$PROJECT/docs/plans/.cpm-cleancheck-sess-1"
OUT=$(run_guard "sess-1" "$PROJECT")
assert_equals "SKIP" "$OUT"

test_start "must NOT RUN when the current session's sentinel exists"
PROJECT=$(setup_project_dir)
: > "$PROJECT/docs/plans/.cpm-cleancheck-sess-1"
OUT=$(run_guard "sess-1" "$PROJECT")
assert_not_contains "$OUT" "RUN"

test_start "A different session's sentinel does not cause SKIP"
PROJECT=$(setup_project_dir)
: > "$PROJECT/docs/plans/.cpm-cleancheck-other-session"
OUT=$(run_guard "sess-1" "$PROJECT")
assert_equals "RUN" "$OUT"

# --- SUPPRESS ---

test_start "SUPPRESS when the ralph state file is present (no sentinel)"
PROJECT=$(setup_project_dir)
make_ralph_active "$PROJECT"
OUT=$(run_guard "sess-1" "$PROJECT")
assert_equals "SUPPRESS" "$OUT"

test_start "SUPPRESS regardless of sentinel state (ralph active AND sentinel present)"
PROJECT=$(setup_project_dir)
make_ralph_active "$PROJECT"
: > "$PROJECT/docs/plans/.cpm-cleancheck-sess-1"
OUT=$(run_guard "sess-1" "$PROJECT")
assert_equals "SUPPRESS" "$OUT"

test_start "SUPPRESS does not write a sentinel"
PROJECT=$(setup_project_dir)
make_ralph_active "$PROJECT"
run_guard "sess-1" "$PROJECT" >/dev/null
if [ -f "$PROJECT/docs/plans/.cpm-cleancheck-sess-1" ]; then test_fail "sentinel written during SUPPRESS"; else test_pass; fi

# --- Sentinel sits outside the classifier's progress glob ---

test_start "Sentinel is not picked up by the classifier's .cpm-progress-*.md glob"
PROJECT=$(setup_project_dir)
run_guard "sess-1" "$PROJECT" >/dev/null   # writes .cpm-cleancheck-sess-1
RECORDS=$(CPM_SESSION_ID="sess-1" bash "$CLASSIFIER" "$PROJECT/docs/plans" 2>/dev/null)
assert_not_contains "$RECORDS" "cleancheck"

# --- Fail-safe & never-delete ---

test_start "Sentinel write failure fails safe to RUN"
PROJECT=$(setup_project_dir)
chmod 555 "$PROJECT/docs/plans"
if [ -w "$PROJECT/docs/plans" ]; then
  # Running as root (perms ignored) — cannot exercise the write-failure path; skip.
  chmod 755 "$PROJECT/docs/plans"
  test_pass
else
  OUT=$(run_guard "sess-1" "$PROJECT")
  chmod 755 "$PROJECT/docs/plans"
  assert_equals "RUN" "$OUT"
fi

test_start "Guard never runs a delete (no 'rm' in the source)"
if grep -qE '(^|[^a-zA-Z])rm([[:space:]]|$)' "$GUARD"; then
  test_fail "Guard source contains an 'rm' invocation"
else
  test_pass
fi

test_start "Empty session id fails safe to RUN"
PROJECT=$(setup_project_dir)
OUT=$(run_guard "" "$PROJECT")
assert_equals "RUN" "$OUT"

test_start "Empty session id writes no sentinel"
PROJECT=$(setup_project_dir)
run_guard "" "$PROJECT" >/dev/null
if ls "$PROJECT"/docs/plans/.cpm-cleancheck-* >/dev/null 2>&1; then test_fail "sentinel written for empty session id"; else test_pass; fi

# --- The skills' own calling convention (CLAUDE_PROJECT_DIR unset) ---

test_start "The documented guard invocation is findable in skill-conventions.md"
CMD=$(extract_guard_command)
if [ -n "$CMD" ]; then test_pass; else test_fail "No invocation matched in $CONVENTIONS"; fi

test_start "The documented invocation passes no path argument at all"
CMD=$(extract_guard_command)
assert_not_contains "$CMD" "docs/plans"

test_start "SUPPRESS fires from the documented invocation with CLAUDE_PROJECT_DIR unset"
PROJECT=$(setup_project_dir)
make_ralph_active "$PROJECT"
OUT=$(run_guard_as_skill "$PROJECT" "sess-unset-1")
assert_equals "SUPPRESS" "$OUT"

test_start "First documented call with CLAUDE_PROJECT_DIR unset returns RUN"
PROJECT=$(setup_project_dir)
OUT=$(run_guard_as_skill "$PROJECT" "sess-unset-2")
assert_equals "RUN" "$OUT"

test_start "Second documented call, same session and still unset, returns SKIP"
PROJECT=$(setup_project_dir)
run_guard_as_skill "$PROJECT" "sess-unset-3" >/dev/null
OUT=$(run_guard_as_skill "$PROJECT" "sess-unset-3")
assert_equals "SKIP" "$OUT"

test_start "The once-per-session sentinel lands inside the project, not at a bare /docs/plans"
PROJECT=$(setup_project_dir)
run_guard_as_skill "$PROJECT" "sess-unset-4" >/dev/null
if [ -f "$PROJECT/docs/plans/.cpm-cleancheck-sess-unset-4" ]; then
  test_pass
else
  test_fail "sentinel not written under $PROJECT/docs/plans"
fi

test_summary
