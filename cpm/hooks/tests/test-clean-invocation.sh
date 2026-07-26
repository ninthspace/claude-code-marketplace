#!/bin/bash
# test-clean-invocation.sh — Tests for the classifier call documented in
# cpm/skills/clean/SKILL.md Step 1.
#
# The command is not read from a variable here — it is extracted from the skill
# file itself and executed verbatim. A test that re-typed the invocation would
# keep passing after the documented one drifted, which is exactly how the
# original defect survived: the skill passed "$CLAUDE_PROJECT_DIR/docs/plans",
# a variable that is unset for the Bash calls a skill issues, so the argument
# expanded to a bare "/docs/plans" and /cpm:clean reported an empty inventory
# every single time.
#
# Tests cover:
# - The documented command is findable in the skill file (guards the rest)
# - N progress files, CLAUDE_PROJECT_DIR unset -> N records
# - Zero files -> zero records
# - list-all mode survives the argument change (compact-summary companions
#   are still emitted, so "list-all" still lands in the mode slot)
# - Emitted paths sit under the real project root, not a bare /docs/plans
# - The skill file passes no "$CLAUDE_PROJECT_DIR"-derived path argument
# - Control: the old form really does return nothing, so the new form's
#   success is not incidental

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLEAN_SKILL="$PLUGIN_ROOT/skills/clean/SKILL.md"
CLASSIFIER="$PLUGIN_ROOT/hooks/lib/progress-classify.sh"

echo "Testing: /cpm:clean's documented classifier invocation"
echo "====================================================="

# The one line in the skill file that invokes the classifier as a command.
# The file mentions progress-classify.sh in prose too, so match on the
# invocation shape rather than the filename alone.
extract_clean_command() {
  grep -m1 -F 'bash "${CLAUDE_PLUGIN_ROOT}/hooks/lib/progress-classify.sh"' "$CLEAN_SKILL"
}

setup_root() {
  local d="$TEST_TMPDIR/clean-$$-$RANDOM"
  mkdir -p "$d/docs/plans"
  (cd "$d" && pwd -P)
}

make_progress_file() {
  printf '# CPM Session State\n\n**Skill**: cpm:do\n**Phase**: testing\n' \
    > "$1/docs/plans/.cpm-progress-$2.md"
}

make_compact_summary() {
  printf 'compaction summary\n' > "$1/docs/plans/.cpm-compact-summary-$2.md"
}

# Run the extracted command from inside `dir`, the way /cpm:clean reaches it:
# CLAUDE_PLUGIN_ROOT set, CLAUDE_PROJECT_DIR genuinely unset.
run_documented() {
  local dir="$1" session="$2" cmd
  cmd=$(extract_clean_command)
  ( cd "$dir" \
      && export CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" CPM_SESSION_ID="$session" \
      && run_without_env CLAUDE_PROJECT_DIR -- bash -c "$cmd" 2>/dev/null )
}

count_records() {
  if [ -z "$1" ]; then echo 0; else printf '%s\n' "$1" | grep -c .; fi
}

# --- The extraction itself ---

test_start "The documented classifier invocation is findable in clean/SKILL.md"
CMD=$(extract_clean_command)
if [ -n "$CMD" ]; then test_pass; else test_fail "No invocation matched in $CLEAN_SKILL"; fi

# --- Criterion 1: N files in, N records out ---

test_start "Two progress files with CLAUDE_PROJECT_DIR unset yield two records"
D=$(setup_root)
make_progress_file "$D" "sess-a"
make_progress_file "$D" "sess-b"
OUT=$(run_documented "$D" "sess-a")
assert_equals "2" "$(count_records "$OUT")"

test_start "No files yields no records"
D=$(setup_root)
OUT=$(run_documented "$D" "sess-a")
assert_equals "0" "$(count_records "$OUT")"

test_start "list-all mode survives the argument change — companions are still emitted"
D=$(setup_root)
make_progress_file "$D" "sess-a"
make_progress_file "$D" "sess-b"
make_compact_summary "$D" "sess-a"
OUT=$(run_documented "$D" "sess-a")
assert_equals "3" "$(count_records "$OUT")"

test_start "Emitted paths sit under the resolved project root"
D=$(setup_root)
make_progress_file "$D" "sess-a"
OUT=$(run_documented "$D" "sess-a")
assert_contains "$OUT" "$D/docs/plans/.cpm-progress-sess-a.md"

# --- Criterion 2 (must NOT) ---

test_start "The documented command passes no \$CLAUDE_PROJECT_DIR-derived path argument"
CMD=$(extract_clean_command)
assert_not_contains "$CMD" 'CLAUDE_PROJECT_DIR'

test_start "Control: the old argument form really does return nothing when the variable is unset"
# Without this, "the new form emits N records" could be true for reasons that
# have nothing to do with the fix. Here the argument expands to "/docs/plans".
D=$(setup_root)
make_progress_file "$D" "sess-a"
OUT=$( cd "$D" && export CPM_SESSION_ID=sess-a \
    && run_without_env CLAUDE_PROJECT_DIR -- \
       bash -c "bash '$CLASSIFIER' \"\$CLAUDE_PROJECT_DIR/docs/plans\" list-all" 2>/dev/null )
assert_equals "0" "$(count_records "$OUT")"

test_summary
