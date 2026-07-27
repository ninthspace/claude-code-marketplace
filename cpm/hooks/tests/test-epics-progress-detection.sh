#!/bin/bash
# test-epics-progress-detection.sh — Epic 45-04 Story 2: detect a leftover `cpm:epics`
# progress file across sessions (spec 45 FR12 and its must-NOT).
#
# --- The situation, and why the safety-net cannot see it -------------------------------
#
# A spec-mode ralph run that dies during phase 1 leaves two files behind: the loop's own
# `.claude/ralph-loop.local.md`, which only a clean finish removes, and the
# `docs/plans/.cpm-progress-{id}.md` that `cpm:epics` was keeping. The second records how far
# generation got. On relaunch the shared Stale-Progress Check is silent about it, because
# `cleancheck-guard.sh` returns `SUPPRESS` the moment that ralph state file exists — the FR11
# autonomous carve-out, which is correct and is not what this story changes.
#
# --- What has an oracle here ----------------------------------------------------------
#
# The criterion itself, and it is genuinely mechanical. One fixture project is built holding
# *both* leftovers, and then two real scripts are run against that same fixture:
#
#   * `cleancheck-guard.sh` returns `SUPPRESS` — the negative control the epic doc names by
#     hand. If this story is ever "fixed" by teaching the guard a ralph exemption, this fires
#     and the carve-out is gone for every other skill during every run.
#   * `progress-classify.sh` still emits a record for the leftover, with its `SKILL` field
#     reading `cpm:epics` and a classification that is not `CURRENT`.
#
# Those two together are criterion 1 asserted by structure rather than by reading the skill:
# the detection path is *available* in exactly the state where the safety-net is silent. Retro
# 29's remedy — build a fixture in the situation and run the real script for its real answer —
# applies here, and unlike epic 46-03 the executable exists to run.
#
# --- What is a regression net over prose ----------------------------------------------
#
# Pre-flight step 1e runs nothing in this repository, so the assertions that it calls the
# classifier, that it does *not* call the guard, that it matches on `**Input source**`, and
# that it never deletes are pinned wording over a bounded slice. The must-NOT is scoped the way
# retro 23 requires: the sentence forbidding deletion has to write the word "delete", so the
# assertion looks for an *imperative to remove* rather than for the token.
#
# --- What this suite does not test ----------------------------------------------------
#
# That a relaunch obeys any of it. Nothing here launches a loop. It also does not re-test the
# guard's or the classifier's own contracts — `test-cleancheck-guard.sh` and
# `test-progress-classify.sh` own those; this suite only asserts the one combination FR12 turns
# on, which neither of them puts together.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GUARD="$SCRIPT_DIR/../lib/cleancheck-guard.sh"
CLASSIFIER="$SCRIPT_DIR/../lib/progress-classify.sh"
RALPH_SKILL="$PLUGIN_ROOT/skills/ralph/SKILL.md"

echo "Testing: cross-session cpm:epics progress detection (Epic 45-04 Story 2)"
echo "======================================================================="

# --- Fixtures ---------------------------------------------------------------------------
#
# The same shapes `test-cleancheck-guard.sh` and `test-progress-classify.sh` build, rather
# than new ones: a project directory with docs/plans, a ralph state file that makes the guard
# suppress, and progress files carrying the headers the classifier reads.

setup_project_dir() {
  local project_dir="$TEST_TMPDIR/epics-detect-$$-$RANDOM"
  mkdir -p "$project_dir/docs/plans"
  echo "$project_dir"
}

make_ralph_active() {
  mkdir -p "$1/.claude"
  printf 'iteration: 1\nmax_iterations: 10\n' > "$1/.claude/ralph-loop.local.md"
}

# A `cpm:epics` progress file in the shape that skill's State Management documents — the
# `**Input source**` field is the one naming the spec, and the `## Epic Files` table is the
# resume state FR12 asks to be passed back.
create_epics_progress() {
  local dir="$1" session_id="$2" source_spec="$3"
  cat > "$dir/docs/plans/.cpm-progress-${session_id}.md" <<EOF
# CPM Session State

**Skill**: cpm:epics
**Step**: 3 of 4 — Break into Stories
**Input source**: $source_spec

## Epic Files

| # | Slug | Path | Status |
|---|------|------|--------|
| 79-01 | alpha | docs/epics/79-01-epic-alpha.md | Written |
| 79-02 | beta | docs/epics/79-02-epic-beta.md | Pending |

## Next Action
Continue.
EOF
}

create_do_progress() {
  local dir="$1" session_id="$2"
  cat > "$dir/docs/plans/.cpm-progress-${session_id}.md" <<EOF
# CPM Session State

**Skill**: cpm:do
**Step**: Task execution

## Next Action
Continue.
EOF
}

run_guard() {
  CPM_SESSION_ID="$2" CLAUDE_PROJECT_DIR="$1" bash "$GUARD" "$1/docs/plans" 2>/dev/null
}

run_classify() {
  CPM_SESSION_ID="$2" bash "$CLASSIFIER" "$1/docs/plans" 2>/dev/null
}

# One record's field, located by the session id in its path.
field_for() {
  printf '%s\n' "$1" | grep -F ".cpm-progress-$2.md" | cut -f"$3"
}

# --- The oracle: suppressed and still detectable ----------------------------------------

SPEC="docs/specifications/79-spec-partial-generation.md"

PROJECT=$(setup_project_dir)
make_ralph_active "$PROJECT"
create_epics_progress "$PROJECT" "dead-loop-session" "$SPEC"

GUARD_OUT=$(run_guard "$PROJECT" "relaunch-session")
CLASSIFY_OUT=$(run_classify "$PROJECT" "relaunch-session")

test_start "the guard suppresses the safety-net while the dead loop's state file remains"
assert_equals "SUPPRESS" "$GUARD_OUT"

test_start "and the classifier still emits a record for the leftover progress file"
assert_equals "1" "$(printf '%s\n' "$CLASSIFY_OUT" | grep -cF '.cpm-progress-dead-loop-session.md')"

test_start "that record names cpm:epics as the skill, so the filter has something to select on"
assert_equals "cpm:epics" "$(field_for "$CLASSIFY_OUT" dead-loop-session 3)"

test_start "and does not classify another session's file as this session's own state"
CLASS=$(field_for "$CLASSIFY_OUT" dead-loop-session 1)
if [ "$CLASS" = "FRESH" ] || [ "$CLASS" = "STALE" ]; then
  test_pass
else
  test_fail "classification was '$CLASS', so step 6's not-CURRENT filter would drop it"
fi

test_start "the spec the leftover names is readable from the file the record points at"
assert_contains "$(cat "$PROJECT/docs/plans/.cpm-progress-dead-loop-session.md")" "**Input source**: $SPEC"

# Without this the SKILL assertion above would pass on a classifier that printed `cpm:epics`
# for everything, and the pre-flight filter would select files it has no business resuming.
create_do_progress "$PROJECT" "unrelated-session"
CLASSIFY_OUT=$(run_classify "$PROJECT" "relaunch-session")

test_start "control: a cpm:do progress file in the same directory reads cpm:do, not cpm:epics"
assert_equals "cpm:do" "$(field_for "$CLASSIFY_OUT" unrelated-session 3)"

# And the not-CURRENT filter has to be able to exclude something, or it is decoration.
create_epics_progress "$PROJECT" "relaunch-session" "$SPEC"
CLASSIFY_OUT=$(run_classify "$PROJECT" "relaunch-session")

test_start "control: this session's own file classifies CURRENT, so the filter can exclude it"
assert_equals "CURRENT" "$(field_for "$CLASSIFY_OUT" relaunch-session 1)"

# --- The pre-flight step, as prose --------------------------------------------------------
#
# Bounded at both ends. A `sed` range that runs past 1e picks up 1f's roll-up resolution and
# the assertions below would then be reading a different step (retro 24 recommendation 4).

SLICE_START='^#### 1e\. Resume Detection'
SLICE_END='^#### 1f\.'

test_start "control: the 1e slice is bounded"
assert_slice_bounded "$RALPH_SKILL" "$SLICE_START" "$SLICE_END" 8 30

STEP_1E=$(sed -n "/$SLICE_START/,/$SLICE_END/p" "$RALPH_SKILL")

test_start "the spec-mode sub-step calls the classifier"
assert_contains "$STEP_1E" 'hooks/lib/progress-classify.sh'

test_start "and does not route the decision through the suppression guard"
assert_not_contains "$STEP_1E" 'bash "${CLAUDE_PLUGIN_ROOT}/hooks/lib/cleancheck-guard.sh"'

test_start "it matches the leftover to this run's spec by the field that names it"
assert_contains "$STEP_1E" '**Input source**'

test_start "and passes back the epic-file state rather than only the file's path"
assert_contains "$STEP_1E" '## Epic Files'

# --- The must-NOT: surfaced, never removed -----------------------------------------------
#
# Retro 23's trap in its usual place: the sentence that forbids deleting the file must itself
# write "delete", so an `assert_not_contains` on that word would fail on correct text. What is
# checkable is the absence of an *instruction* to remove it.

test_start "the sub-step issues no instruction to remove the leftover"
REMOVALS=$(printf '%s\n' "$STEP_1E" | grep -oE 'rm -|delete it|remove it|delete the file|remove the file')

if [ -z "$REMOVALS" ]; then
  test_pass
else
  test_fail "the slice instructs removal: $(printf '%s' "$REMOVALS" | tr '\n' ' ')"
fi

test_start "control: an instruction to remove it would be detected"
MUTATED=$(printf '%s\n' "$STEP_1E" | sed 's/never delete or overwrite it/delete it once the run is armed/')
if [ "$MUTATED" != "$STEP_1E" ] &&
   printf '%s\n' "$MUTATED" | grep -qE 'rm -|delete it|remove it|delete the file|remove the file'; then
  test_pass
else
  test_fail "the mutation did not apply, so the check above is untested"
fi

test_start "and the sub-step defers to the shared user-confirmed deletion rule"
assert_contains "$STEP_1E" 'no path auto-executes a delete'

test_summary
