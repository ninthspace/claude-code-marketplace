#!/bin/bash
# test-project-root-resolution.sh — Tests for shared project-root resolution
# in cpm/hooks/lib/{resolve-project-root.sh,cleancheck-guard.sh,progress-classify.sh}
#
# Both helpers used to build their paths from "$CLAUDE_PROJECT_DIR/..." with no
# fallback. That variable is set for hooks (Claude Code spawns them) but NOT for
# the Bash calls a /cpm:* skill issues, so from skill context the guard's ralph
# state path was "/.claude/ralph-loop.local.md" and the classifier's state dir
# was "/docs/plans" — SUPPRESS could never fire and /cpm:clean always saw zero
# progress files. These tests pin the resolution chain that fixes it.
#
# Tests cover:
# - The chain $CLAUDE_PROJECT_DIR -> git rev-parse --show-toplevel -> $PWD,
#   in that order, for both helpers
# - RALPH_STATE as a second positional argument to the guard
# - The resolved root validated as an existing directory and echoed to stderr
# - An unresolvable root yielding SUPPRESS plus a stderr warning that names
#   the resolution attempt
# - Fallback to $PWD outside a git work tree, with no external command needed
# - Unchanged stdout/exit/side-effects when CLAUDE_PROJECT_DIR *is* set
# - No deletion path introduced by the new code

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

GUARD="$SCRIPT_DIR/../lib/cleancheck-guard.sh"
CLASSIFIER="$SCRIPT_DIR/../lib/progress-classify.sh"
RESOLVER="$SCRIPT_DIR/../lib/resolve-project-root.sh"

echo "Testing: project-root resolution (resolve-project-root.sh)"
echo "=========================================================="

# A project fixture, returned as a *physical* path. macOS puts temp dirs under
# /var, a symlink to /private/var, and `git rev-parse --show-toplevel` reports
# the physical path — so comparing a logical fixture path against git's answer
# would fail for a reason that has nothing to do with the code under test.
setup_root() {
  local d="$TEST_TMPDIR/root-$$-$RANDOM"
  mkdir -p "$d/docs/plans"
  (cd "$d" && pwd -P)
}

make_ralph_active() {
  mkdir -p "$1/.claude"
  printf 'iteration: 1\nmax_iterations: 10\n' > "$1/.claude/ralph-loop.local.md"
}

make_progress_file() {
  local dir="$1" id="$2"
  printf '# CPM Session State\n\n**Skill**: cpm:do\n**Phase**: testing\n' \
    > "$dir/docs/plans/.cpm-progress-$id.md"
}

# Run a helper from inside `dir` with CLAUDE_PROJECT_DIR genuinely unset — the
# way a /cpm:* skill's Bash call reaches it. Stderr is discarded here; the
# stderr-specific tests capture it explicitly.
run_at() {
  local dir="$1" script="$2"; shift 2
  ( cd "$dir" && export CPM_SESSION_ID=sess-1 \
      && run_without_env CLAUDE_PROJECT_DIR -- bash "$script" "$@" 2>/dev/null )
}

# Same, but capturing stderr instead of stdout.
stderr_at() {
  local dir="$1" script="$2"; shift 2
  ( cd "$dir" && export CPM_SESSION_ID=sess-1 \
      && run_without_env CLAUDE_PROJECT_DIR -- bash "$script" "$@" 2>&1 >/dev/null )
}

# --- Criterion 1: the resolution chain, in order ---

test_start "Guard prefers CLAUDE_PROJECT_DIR over the git work tree it is standing in"
D=$(setup_root)
GITROOT=$(setup_root)
git -C "$GITROOT" init -q
make_ralph_active "$D"
# cwd is inside a git repo whose toplevel has no ralph state; the variable
# points elsewhere. SUPPRESS proves the variable won.
OUT=$( cd "$GITROOT" && CPM_SESSION_ID=sess-1 CLAUDE_PROJECT_DIR="$D" bash "$GUARD" 2>/dev/null )
assert_equals "SUPPRESS" "$OUT"

test_start "Guard falls back to the git work tree root when CLAUDE_PROJECT_DIR is unset"
D=$(setup_root)
git -C "$D" init -q
make_ralph_active "$D"
# Run from a subdirectory: the git toplevel is D, but PWD is D/docs/plans, so
# only a real `git rev-parse` can find the ralph state file.
OUT=$(run_at "$D/docs/plans" "$GUARD")
assert_equals "SUPPRESS" "$OUT"

test_start "Guard falls back to PWD outside any git work tree"
D=$(setup_root)
make_ralph_active "$D"
OUT=$(run_at "$D" "$GUARD")
assert_equals "SUPPRESS" "$OUT"

test_start "Classifier prefers CLAUDE_PROJECT_DIR over the git work tree it is standing in"
D=$(setup_root)
GITROOT=$(setup_root)
git -C "$GITROOT" init -q
make_progress_file "$D" "sess-1"
OUT=$( cd "$GITROOT" && CPM_SESSION_ID=sess-1 CLAUDE_PROJECT_DIR="$D" bash "$CLASSIFIER" 2>/dev/null )
assert_contains "$OUT" "CURRENT"

test_start "Classifier falls back to the git work tree root when CLAUDE_PROJECT_DIR is unset"
D=$(setup_root)
git -C "$D" init -q
make_progress_file "$D" "sess-1"
OUT=$(run_at "$D/docs/plans" "$CLASSIFIER")
assert_contains "$OUT" "CURRENT"

test_start "Classifier falls back to PWD outside any git work tree"
D=$(setup_root)
make_progress_file "$D" "sess-1"
OUT=$(run_at "$D" "$CLASSIFIER")
assert_contains "$OUT" "CURRENT"

test_start "An explicit STATE_DIR argument still overrides the resolved root"
D=$(setup_root)
ELSEWHERE=$(setup_root)
make_progress_file "$ELSEWHERE" "sess-1"
OUT=$(run_at "$D" "$CLASSIFIER" "$ELSEWHERE/docs/plans")
assert_contains "$OUT" "CURRENT"

# --- Criterion 2: RALPH_STATE argument override ---

test_start "A RALPH_STATE argument pointing at an existing file yields SUPPRESS"
D=$(setup_root)
printf 'iteration: 1\n' > "$D/elsewhere-ralph.md"
OUT=$(run_at "$D" "$GUARD" "$D/docs/plans" "$D/elsewhere-ralph.md")
assert_equals "SUPPRESS" "$OUT"

test_start "A RALPH_STATE argument pointing at no file overrides a present default state file"
D=$(setup_root)
make_ralph_active "$D"
# CLAUDE_PROJECT_DIR is set here on purpose: without the override the guard
# would find .claude/ralph-loop.local.md and answer SUPPRESS, so RUN can only
# come from the argument taking precedence.
OUT=$(CPM_SESSION_ID=sess-1 CLAUDE_PROJECT_DIR="$D" bash "$GUARD" "$D/docs/plans" "$D/no-such-ralph.md" 2>/dev/null)
assert_equals "RUN" "$OUT"

# --- Criterion 3: validated and echoed to stderr ---

test_start "Guard echoes the resolved project root to stderr"
D=$(setup_root)
ERR=$(stderr_at "$D" "$GUARD")
assert_contains "$ERR" "$D"

test_start "Guard names the source of the resolved root on stderr"
D=$(setup_root)
ERR=$(stderr_at "$D" "$GUARD")
assert_contains "$ERR" "PWD"

test_start "The guard's stdout stays a bare token — the diagnostic goes to stderr only"
D=$(setup_root)
OUT=$(run_at "$D" "$GUARD")
assert_equals "RUN" "$OUT"

test_start "Classifier echoes the resolved project root to stderr"
D=$(setup_root)
ERR=$(stderr_at "$D" "$CLASSIFIER")
assert_contains "$ERR" "$D"

test_start "Classifier's stdout carries no diagnostic text"
D=$(setup_root)
make_progress_file "$D" "sess-1"
OUT=$(run_at "$D" "$CLASSIFIER")
assert_not_contains "$OUT" "project root"

# --- Criterion 4: unresolvable root ---

# One name for the bad path, so the three assertions about it cannot drift apart.
MISSING="$TEST_TMPDIR/definitely-not-here"

test_start "A CLAUDE_PROJECT_DIR naming a nonexistent path yields SUPPRESS"
OUT=$(CPM_SESSION_ID=sess-1 CLAUDE_PROJECT_DIR="$MISSING" bash "$GUARD" 2>/dev/null)
assert_equals "SUPPRESS" "$OUT"

test_start "A CLAUDE_PROJECT_DIR naming a file rather than a directory yields SUPPRESS"
D=$(setup_root)
: > "$D/a-file"
OUT=$(CPM_SESSION_ID=sess-1 CLAUDE_PROJECT_DIR="$D/a-file" bash "$GUARD" 2>/dev/null)
assert_equals "SUPPRESS" "$OUT"

test_start "The unresolvable-root warning names the resolution attempt"
ERR=$(CPM_SESSION_ID=sess-1 CLAUDE_PROJECT_DIR="$MISSING" bash "$GUARD" 2>&1 >/dev/null)
assert_contains "$ERR" "CLAUDE_PROJECT_DIR"

test_start "The unresolvable-root warning names the rejected candidate path"
ERR=$(CPM_SESSION_ID=sess-1 CLAUDE_PROJECT_DIR="$MISSING" bash "$GUARD" 2>&1 >/dev/null)
assert_contains "$ERR" "$MISSING"

test_start "An unresolvable root leaves the classifier emitting no records"
OUT=$(CPM_SESSION_ID=sess-1 CLAUDE_PROJECT_DIR="$MISSING" bash "$CLASSIFIER" 2>/dev/null)
assert_empty "$OUT"

# --- Criterion 5: no command beyond the shell already in use ---

test_start "The guard resolves and answers with no external binary on PATH"
D=$(setup_root)
# PATH is emptied, so `git` cannot be found and no external helper is reachable.
# Resolution must still reach $PWD using shell builtins alone.
OUT=$( cd "$D" && export CPM_SESSION_ID=sess-path \
    && run_without_env CLAUDE_PROJECT_DIR -- env PATH=/nonexistent /bin/bash "$GUARD" 2>/dev/null )
assert_equals "RUN" "$OUT"

test_start "The resolver's only external command is git, and it is failure-tolerant"
# `git rev-parse` must be the sole non-builtin in the resolution chain, and must
# not leak its own error when the directory is not a work tree.
if [ -f "$RESOLVER" ] && grep -qF 'git rev-parse --show-toplevel 2>/dev/null' "$RESOLVER"; then
  test_pass
else
  test_fail "Expected a stderr-suppressed 'git rev-parse --show-toplevel' in $RESOLVER"
fi

# --- Criterion 6 (must NOT): hook-context callers unaffected ---

test_start "Hook-context guard call still returns RUN on a clean project"
D=$(setup_root)
OUT=$(CPM_SESSION_ID=sess-1 CLAUDE_PROJECT_DIR="$D" bash "$GUARD" "$D/docs/plans" 2>/dev/null)
assert_equals "RUN" "$OUT"

test_start "Hook-context guard call still writes the session sentinel"
D=$(setup_root)
CPM_SESSION_ID=sess-1 CLAUDE_PROJECT_DIR="$D" bash "$GUARD" "$D/docs/plans" >/dev/null 2>&1
if [ -f "$D/docs/plans/.cpm-cleancheck-sess-1" ]; then test_pass; else test_fail "sentinel not written"; fi

test_start "Hook-context classifier call emits the same records as before"
D=$(setup_root)
make_progress_file "$D" "sess-1"
OUT=$(CPM_SESSION_ID=sess-1 CLAUDE_PROJECT_DIR="$D" bash "$CLASSIFIER" "$D/docs/plans" 2>/dev/null)
assert_contains "$OUT" "CURRENT	$D/docs/plans/.cpm-progress-sess-1.md	cpm:do"

# --- Criterion 7 (must NOT): no deletion path ---

test_start "The shared resolver exists as one file both helpers can draw on"
# Guards the two source greps below, which a missing file would otherwise let
# pass vacuously.
if [ -f "$RESOLVER" ]; then test_pass; else test_fail "No resolver at $RESOLVER"; fi

test_start "The resolver never runs a delete (no 'rm' in the source)"
if [ -f "$RESOLVER" ] && grep -qE '(^|[^a-zA-Z])rm([[:space:]]|$)' "$RESOLVER"; then
  test_fail "Resolver source contains an 'rm' invocation"
else
  test_pass
fi

test_start "The guard still never runs a delete after gaining resolution"
if grep -qE '(^|[^a-zA-Z])rm([[:space:]]|$)' "$GUARD"; then
  test_fail "Guard source contains an 'rm' invocation"
else
  test_pass
fi

test_start "The classifier still never runs a delete after gaining resolution"
if grep -qE '(^|[^a-zA-Z])rm([[:space:]]|$)' "$CLASSIFIER"; then
  test_fail "Classifier source contains an 'rm' invocation"
else
  test_pass
fi

test_summary
