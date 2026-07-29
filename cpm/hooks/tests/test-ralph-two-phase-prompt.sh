#!/bin/bash
# test-ralph-two-phase-prompt.sh — Tests for spec mode's two-phase prompt
# (Epic 45-03 Story 3, spec 45 FR6, FR7, NFR1 and NFR5).
#
# --- What has an oracle here ------------------------------------------------------------
#
# The story's substance is a branch table written in prose: four exit codes, two of which mean
# keep working and two of which mean stop, and a completion tag reachable from exactly one of
# them. So the assertions parse that table out of the two clause blocks and check its shape,
# rather than grepping for sentences:
#
#   * **The codes are extracted, not re-typed** — from the clause that names them — and
#     compared to the code set the script's own usage text documents. Epic 44-03 changed a
#     template's `on 3` to `on 4`, a code the script never returned, and every assertion
#     stayed green because nothing compared the two sides. Story 5 runs the command; this
#     suite compares the sets.
#   * **The must-NOT is a disjointness, not an absence.** "Do not treat a read failure as
#     phase 1 not started" is checkable as: the codes routed to phase 1 and the codes routed
#     to stop share no member. A wrong edit that merges them changes the sets, where a grep
#     for the word "stop" would not.
#   * **The tag is located, not counted.** The completion clause names `SPEC_DELIVERED` three
#     times — once to emit it and twice to forbid emitting it — so the assertion is that the
#     only branch which *emits* is the one for code 0, and that the phase clause, where
#     phase 1 lives, never names the tag at all. Retro 21: the sentences forbidding the tag
#     have to write it, so the negative is scoped to the block where writing it would be an
#     instruction.
#
# --- What this suite does not test ---------------------------------------------------------
#
# That the loop obeys any of it. Nothing here launches one. It also does not run the roll-up:
# the codes are compared against the script's documented set, and Story 5 is what executes the
# command the prompt names and compares the values it actually returns.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

RALPH_SKILL="$SCRIPT_DIR/../../skills/ralph/SKILL.md"
ROLLUP="$SCRIPT_DIR/../lib/coverage-rollup.sh"

echo "Testing: spec mode's two-phase conditional prompt (Epic 45-03 Story 3)"
echo "======================================================================"

# --- The two clause blocks ------------------------------------------------------------------
#
# Located by their opening words, the same way the four existing suites locate the epic-mode
# template. Extracted rather than re-typed: a re-typed clause tests the copy in the test.

phase_clause()      { grep -F 'Work spec {spec_path} to completion.' "$1"; }
completion_clause() { grep -F 'When phase 2 has no epic left to work' "$1"; }

PHASE=$(phase_clause "$RALPH_SKILL")
COMPLETION=$(completion_clause "$RALPH_SKILL")

test_start "the skill carries exactly one phase clause and one completion clause"
if [ "$(printf '%s\n' "$PHASE" | grep -c .)" = "1" ] &&
   [ "$(printf '%s\n' "$COMPLETION" | grep -c .)" = "1" ]; then
  test_pass
else
  test_fail "found $(printf '%s\n' "$PHASE" | grep -c .) phase and $(printf '%s\n' "$COMPLETION" | grep -c .) completion clauses"
fi

# --- Criterion 1: the two predicates are stated, and stated separately ----------------------

test_start "phase 1's predicate is the untraced count reaching 0"
assert_contains "$PHASE" "An untraced count of 0 means phase 2"

test_start "phase 2's predicate is the roll-up's own verdict, not a count the loop makes"
assert_contains "$COMPLETION" "run bash {rollup_script} --spec {spec_path} --verdict and let its exit code decide"

# "Separately" is the criterion's word, and two predicates in one sentence would satisfy every
# assertion above. They are stated in different blocks, which is the strongest form of it.
test_start "the two predicates are stated in different clauses, not one sentence"
if ! printf '%s\n' "$PHASE" | grep -qF 'SPEC_DELIVERED' &&
   ! printf '%s\n' "$COMPLETION" | grep -qF 'untraced count'; then
  test_pass
else
  test_fail "the phase and completion predicates appear in the same block"
fi

# --- Criteria 3 and 4: the branch table, and the two codes that must not collapse -----------
#
# The completion clause is a list of `on N, ...` branches separated by semicolons. Each is
# read as a code and the action it names.

branches() { printf '%s\n' "$1" | sed 's/.*let its exit code decide: //' | tr ';' '\n'; }

branch_codes() { branches "$1" | sed -n 's/^ *on \([0-9]*\),.*/\1/p' | sort -u | tr '\n' ' '; }

# The codes the phase clause routes: `Exit 4 ... means phase 1`, `Exit 1 or 2 means ... stop`.
# The label is removed *before* the digits are read. Reading digits out of the whole match
# returns the `1` in "phase 1" as well as the code, which put a read-failure code in the
# phase-1 set and made the disjointness assertion below fail against a correct document —
# the extractor matched more than the thing it was extracting.
codes_routed_to() {
  local label="$2"
  printf '%s\n' "$1" | grep -oE "Exit [0-9]+( or [0-9]+)? means $label" |
    sed "s/ means $label\$//; s/^Exit //; s/ or / /" |
    tr ' ' '\n' | grep -E '^[0-9]+$' | sort -u | tr '\n' ' '
}
phase1_codes() { codes_routed_to "$1" 'phase 1'; }
stop_codes()   { codes_routed_to "$1" 'the check could not run'; }

PHASE1_CODES=$(phase1_codes "$PHASE")
STOP_CODES=$(stop_codes "$PHASE")

test_start "the phase clause routes a code to phase 1 not started"
assert_equals "4 " "$PHASE1_CODES"

test_start "and routes the read-failure codes to stop"
assert_equals "1 2 " "$STOP_CODES"

# The must-NOT, as a set relation rather than a word search: nothing may be in both.
test_start "must NOT treat a read failure as phase 1 not started"
OVERLAP=""
for c in $PHASE1_CODES; do
  case " $STOP_CODES " in *" $c "*) OVERLAP="$OVERLAP$c " ;; esac
done
assert_empty "$OVERLAP"

# The wrong edit named first, then the measurement chosen for it (retro 26): the collapse this
# must-NOT forbids is a read failure being *routed* to phase 1 while the stop branch survives,
# which is what someone writes when they think 1 means "nothing there yet". Mutating the
# phase-1 sentence rather than deleting the stop one is what puts a code in both sets.
test_start "control: the disjointness check reports an overlap when there is one"
MERGED="$TEST_TMPDIR/ralph-merged-codes.md"
sed 's/Exit 4 means phase 1/Exit 1 means phase 1/' "$RALPH_SKILL" > "$MERGED"
MERGED_PHASE=$(phase_clause "$MERGED")
MERGED_OVERLAP=""
for c in $(phase1_codes "$MERGED_PHASE"); do
  case " $(stop_codes "$MERGED_PHASE") " in *" $c "*) MERGED_OVERLAP="$MERGED_OVERLAP$c " ;; esac
done
if [ -n "$MERGED_OVERLAP" ]; then
  test_pass
else
  test_fail "phase-1 set '$(phase1_codes "$MERGED_PHASE")' and stop set '$(stop_codes "$MERGED_PHASE")' were reported disjoint"
fi

# Correspondence with the script: every code the completion clause branches on is a code the
# script documents returning, and between them the branches account for all of them.
DOCUMENTED=$(run_without_env CLAUDE_PROJECT_DIR -- bash "$ROLLUP" 2>&1 >/dev/null |
  sed -n '/^--verdict changes only the exit code/,/usage error\./p' |
  grep -oE '(^|[^0-9])[0-9]([^0-9]|$)' | grep -oE '[0-9]' | sort -u | tr '\n' ' ')
BRANCHED=$(branch_codes "$COMPLETION")

test_start "control: the script documents a code set at all"
if [ "$(printf '%s' "$DOCUMENTED" | wc -w | tr -d ' ')" = "6" ]; then
  test_pass
else
  test_fail "read '$DOCUMENTED' from the usage text"
fi

# The clause names 0, 3, 4 and 5 explicitly and covers 1 and 2 with its catch-all, so the
# explicit set is a subset — a branch on a code the script never returns is what fails here.
test_start "every code the completion clause names is one the script documents"
UNKNOWN=""
for c in $BRANCHED; do
  case " $DOCUMENTED " in *" $c "*) ;; *) UNKNOWN="$UNKNOWN$c " ;; esac
done
assert_empty "$UNKNOWN"

test_start "control: a branch on a code the script never returns is detected"
BOGUS="$TEST_TMPDIR/ralph-bogus-code.md"
sed 's/on 4, do not output it and go back to phase 1/on 7, do not output it and go back to phase 1/' \
  "$RALPH_SKILL" > "$BOGUS"
BOGUS_UNKNOWN=""
for c in $(branch_codes "$(completion_clause "$BOGUS")"); do
  case " $DOCUMENTED " in *" $c "*) ;; *) BOGUS_UNKNOWN="$BOGUS_UNKNOWN$c " ;; esac
done
if [ -n "$BOGUS_UNKNOWN" ]; then
  test_pass
else
  test_fail "the mutated clause branched on $(branch_codes "$(completion_clause "$BOGUS")") and nothing was reported"
fi

# --- Criterion 2: the tag is reachable from exactly one branch ------------------------------

emitting_branches() {
  branches "$1" | grep -F 'SPEC_DELIVERED' | grep -vF 'do not output it'
}

test_start "exactly one branch of the completion clause emits the tag"
assert_equals "1" "$(emitting_branches "$COMPLETION" | grep -c .)"

test_start "and it is the branch for the delivered code"
assert_contains "$(emitting_branches "$COMPLETION")" "on 0,"

test_start "must NOT emit the completion tag while any requirement is untraced"
assert_not_contains "$PHASE" "SPEC_DELIVERED"

test_start "control: a tag emission added to a keep-working branch is detected"
LEAKY="$TEST_TMPDIR/ralph-leaky-tag.md"
sed 's/on 3, do not output it, name the untraced/on 3, output SPEC_DELIVERED, name the untraced/' \
  "$RALPH_SKILL" > "$LEAKY"
if [ "$(emitting_branches "$(completion_clause "$LEAKY")" | grep -c .)" -gt 1 ]; then
  test_pass
else
  test_fail "the leaked emission was not counted"
fi

# --- Criterion 5: fail closed ---------------------------------------------------------------

test_start "every branch other than the delivered one withholds the tag"
WITHHOLDING=$(branches "$COMPLETION" | grep -c 'do not output it')
NON_DELIVERED=$(( $(branches "$COMPLETION" | grep -c '^ *on ') - 1 ))
assert_equals "$NON_DELIVERED" "$WITHHOLDING"

test_start "and an unrecognised code reaches a catch-all rather than falling through"
assert_contains "$COMPLETION" "on any other code, do not output it and say the check could not run"

test_start "control: removing the catch-all is detected"
NO_CATCH="$TEST_TMPDIR/ralph-no-catchall.md"
sed 's/; on any other code, do not output it and say the check could not run//' \
  "$RALPH_SKILL" > "$NO_CATCH"
if ! completion_clause "$NO_CATCH" | grep -qF 'on any other code'; then
  test_pass
else
  test_fail "the catch-all survived the mutation"
fi

# --- Criterion 6 (NFR5): each stated figure matches the block it describes -------------------
#
# Two blocks, two figures, and the epic-mode template's own figure asserted by two other
# suites. Stating a number is only worth doing if something compares it (retro 24), and the
# comparison has to read the number out of the document rather than carry it.

stated_for() { sed -n "s/^\*\*$1\*\* (spec mode; \*\*\([0-9]*\) characters\*\*.*/\1/p" "$2"; }

test_start "the phase clause's stated length matches its actual length"
assert_equals "${#PHASE}" "$(stated_for 'Phase clause' "$RALPH_SKILL")"

test_start "the completion clause's stated length matches its actual length"
assert_equals "${#COMPLETION}" "$(stated_for 'Completion clause' "$RALPH_SKILL")"

# The figure to mutate is read out of the document rather than written here. A pinned literal
# turns every legitimate re-measurement into a control that silently stops mutating anything —
# which is exactly what happened when Story 6's strip clause changed the phase clause's length.
test_start "control: a stated figure that disagrees with its block is detected"
BAD_LEN="$TEST_TMPDIR/ralph-bad-clause-length.md"
sed "s/(spec mode; \*\*$(stated_for 'Phase clause' "$RALPH_SKILL") characters\*\*/(spec mode; **1100 characters**/" \
  "$RALPH_SKILL" > "$BAD_LEN"
if [ "$(stated_for 'Phase clause' "$BAD_LEN")" != "${#PHASE}" ]; then
  test_pass
else
  test_fail "the mutated figure still compared equal to ${#PHASE}"
fi

# --- Liveness: a phase that cannot progress stops rather than repeating ----------------------
#
# Added after the first live spec-mode run, which never left phase 1. The clause read "Exit 4
# means phase 1, and so does any untraced count that is not 0", so a spec whose epics did not
# cover every requirement sent the loop back to `/cpm:epics` every iteration — and because
# sub-numbers are `max + 1`, each pass wrote a *fresh* set of epic docs rather than completing
# the previous one. Fifty iterations, fifty generations of epics, no story worked.
#
# The whole branch table was already asserted when that shipped, and every assertion passed:
# the codes were extracted, the sets were disjoint, the tag was reachable from one branch
# only. What none of them asked was whether a branch could be *reached twice with the same
# input*. That is the shape this section adds, and it is a different question from routing.

# The generation step, isolated by the instruction that performs it rather than by the token
# `/cpm:epics` — which the guard sentence must also write in order to forbid the second run.
generation_instruction() {
  printf '%s\n' "$1" | grep -oF 'run /cpm:epics on {spec_path}'
}

test_start "the phase clause instructs a /cpm:epics run exactly once"
assert_equals "1" "$(generation_instruction "$PHASE" | grep -c .)"

# The sentence carrying that instruction is the exit-4 sentence, and no other. Sentences are
# split on the full stops that separate them; the clause has no abbreviations to confuse it.
sentence_with() {
  printf '%s\n' "$1" | tr '.' '\n' | grep -F "$2" | head -1
}

test_start "generation is instructed in the exit-4 branch, where no matrix names the spec"
GEN_SENTENCE=$(sentence_with "$PHASE" 'run /cpm:epics on {spec_path}')
assert_contains "$GEN_SENTENCE" "Exit 4"

# The situation the live run was in: epics exist, and they do not cover the spec. The code is
# taken from the script rather than assumed, so a future change to what that situation returns
# fails here instead of leaving the clause branching on a code nothing produces (retro 27).
source "$SCRIPT_DIR/coverage-fixture-helpers.sh"

L_DIR=$(coverage_fixture_dir liveness)
L_SPEC=$(coverage_fixture_spec 78-spec-partly-covered --dir "$L_DIR" \
  --must FR1 "a requirement an epic covers" \
  --must FR2 "a requirement no epic covers")
coverage_fixture_matrix 78-01-coverage-partly-covered \
  "docs/specifications/78-spec-partly-covered.md" --dir "$L_DIR" \
  --row FR1 "a requirement an epic covers" "the FR1 criterion" "Story 1" '✓' >/dev/null

L_RC=0
run_without_env CLAUDE_PROJECT_DIR -- bash "$ROLLUP" \
  --spec "$L_SPEC" --matrix-dir "$L_DIR" --verdict >/dev/null 2>&1 || L_RC=$?

test_start "control: a spec whose epics leave a requirement untraced is not the exit-4 case"
if [ "$L_RC" != "4" ] && [ "$L_RC" != "0" ]; then
  test_pass
else
  test_fail "the fixture returned $L_RC, so it does not exercise the branch under test"
fi

test_start "that situation is routed to a stop, not to another generation"
STUCK=$(sentence_with "$PHASE" 'on any other code')
if [ -n "$STUCK" ] && printf '%s\n' "$STUCK" | grep -qF 'stop' &&
   [ -z "$(generation_instruction "$STUCK")" ]; then
  test_pass
else
  test_fail "the non-converging branch reads: $STUCK"
fi

test_start "and the clause forbids a second generation run outright"
assert_contains "$PHASE" "never run /cpm:epics twice in one run"

test_start "control: the pre-fix wording routes the same situation back to generation"
OLD=$(printf '%s\n' "$PHASE" |
  sed 's/Exit 4 means phase 1 and no epics exist for this spec yet: run/Exit 4 means phase 1, and so does any untraced count that is not 0: run/')
OLD_STUCK=$(sentence_with "$OLD" 'not 0')
if [ -n "$(generation_instruction "$OLD_STUCK")" ]; then
  test_pass
else
  test_fail "the reverted clause did not send the non-converging case back to /cpm:epics"
fi

# Phase 2's mirror hole: "keep working" with nothing left to work on is the same loop by
# another door. Its exit-3 branch has to bound the continuation, and the bound has to name
# an action — a live run spent 34 iterations re-running a finished suite because its exit-3
# branch said to stop without saying what stopping consisted of, and ending a turn is the
# one thing a Stop hook intercepts.
test_start "the completion clause's exit-3 branch bounds how long it keeps working"
KEEP=$(printf '%s\n' "$COMPLETION" | grep -oE 'on 3,[^;]*;')
if printf '%s\n' "$KEEP" | grep -qF 'only while an epic still has unfinished work' &&
   printf '%s\n' "$KEEP" | grep -qF 'stop the loop'; then
  test_pass
else
  test_fail "the exit-3 branch reads: $KEEP"
fi

test_start "control: an unbounded 'keep working' is detected"
UNBOUNDED=$(printf '%s\n' "$KEEP" |
  sed 's/ only while an epic still has unfinished work -- if none has, stop the loop, since another pass over epics that are already complete cannot change the verdict//')
if printf '%s\n' "$UNBOUNDED" | grep -qF 'only while an epic'; then
  test_fail "the mutation left the bound in place: $UNBOUNDED"
else
  test_pass
fi

# "Stop the loop" is a phrase in three branches and would be inert without a definition of
# what stopping *does*. The clause carries one, and it has to be an instruction to act on
# a file rather than an instruction to end the turn.
test_start "the clause defines what stopping the loop consists of"
if printf '%s\n' "$COMPLETION" | grep -qF 'Stop the loop means:' &&
   printf '%s\n' "$COMPLETION" | grep -qF 'active: false in .claude/ralph-loop.local.md'; then
  test_pass
else
  test_fail "the completion clause names no mechanism for stopping"
fi

test_start "and it carries a fallback for a plugin that ignores that field"
if printf '%s\n' "$COMPLETION" | grep -qF 'delete .claude/ralph-loop.local.md'; then
  test_pass
else
  test_fail "no fallback for a plugin that does not read active:"
fi

test_start "control: a definition-less 'stop the loop' is detected"
NO_MECH=$(printf '%s\n' "$COMPLETION" | sed 's/Stop the loop means:[^.]*\.//')
if printf '%s\n' "$NO_MECH" | grep -qF 'Stop the loop means:'; then
  test_fail "the mutation left the definition in place"
else
  test_pass
fi

# The new terminal branch, asserted the same way as the others: it withholds the promise,
# reports what it could not check, and stops — the three things that make it terminal
# rather than another route back into the loop.
test_start "the exit-5 branch withholds the promise, reports, and stops"
TARGET_BRANCH=$(printf '%s\n' "$COMPLETION" | grep -oE 'on 5,[^;]*;')
if printf '%s\n' "$TARGET_BRANCH" | grep -qF 'do not output it' &&
   printf '%s\n' "$TARGET_BRANCH" | grep -qF 'TARGET-ONLY' &&
   printf '%s\n' "$TARGET_BRANCH" | grep -qF 'stop the loop'; then
  test_pass
else
  test_fail "the exit-5 branch reads: $TARGET_BRANCH"
fi

test_start "and it does not send the run back to phase 1, which 4 does"
assert_not_contains "$TARGET_BRANCH" "phase 1"

test_summary
