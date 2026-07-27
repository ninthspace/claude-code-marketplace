#!/bin/bash
# test-ralph-plan-strip-transition.sh — Stripping `[plan]` at the phase transition
# (Epic 45-03 Story 6, spec 45 FR13 and its two must-NOTs).
#
# --- What has an oracle here ------------------------------------------------------------
#
# Pre-flight step 1b strips `[plan]` from the epics it resolved, which covers the three input
# shapes whose epics are on disk at launch. Spec mode's are not: phase 1 writes them, so
# nothing had stripped them and `/cpm:do` would reach `EnterPlanMode` with nobody there to
# approve. The clause added by this story is the strip at the point of use.
#
# Two things are checkable and one is not:
#
#   * **Ordering** — the strip is instructed *before* the phase-2 `/cpm:do`, which is a fact
#     about where the sentence sits in the clause and is measured as a character offset, not
#     read. Reordering the two sentences moves the number.
#   * **Bounded write surface** — the clause says which docs it may touch. This is asserted
#     positively (it names the epics the run generated) and negatively (nothing in the clause
#     widens it to the directory), with a mutation control for each.
#   * **Not checkable**: that a live loop strips anything. Nothing here launches one, and the
#     epic's Notes say so. What is asserted is that the instruction is present, ordered, and
#     bounded — evidence, not proof.
#
# Retro 21 governs the negatives: the clause implementing this rule has to write `[plan]`
# repeatedly, so a must-NOT phrased against the token would be unsatisfiable the moment it was
# written. The negative that *is* meaningful is about the surface the clause claims, not about
# whether the token appears.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

RALPH_SKILL="$SCRIPT_DIR/../../skills/ralph/SKILL.md"

echo "Testing: [plan] is stripped at the phase transition (Epic 45-03 Story 6)"
echo "========================================================================"

phase_clause() { grep -F 'Work spec {spec_path} to completion.' "$1"; }
PHASE=$(phase_clause "$RALPH_SKILL")

strip_sentence() {
  printf '%s\n' "$1" | grep -oE 'Before the first /cpm:do of phase 2[^.]*\.'
}

STRIP=$(strip_sentence "$PHASE")

test_start "the phase clause carries a strip instruction"
if [ -n "$STRIP" ]; then test_pass; else test_fail "no strip sentence in the phase clause"; fi

# --- Criterion 1: stripped by the same rule step 1b applies ---------------------------------
#
# "The same rule" is a reference, not a restatement — the clause must point at 1b rather than
# describe a second procedure that can drift from it. Both halves are asserted: the pointer,
# and that step 1b is really there to be pointed at.

test_start "the clause defers to pre-flight step 1b rather than restating its procedure"
assert_contains "$STRIP" "by the rule ralph pre-flight step 1b applies"

test_start "control: step 1b exists and is the procedure being referenced"
assert_contains "$(grep -c '^#### 1b\. Strip `\[plan\]` Tags' "$RALPH_SKILL")" "1"

# The referenced rule has two observable parts — remove the tag from headings, log one line
# per strip — and the clause names both, so a reader of the prompt alone knows what "the same
# rule" produces.
test_start "the clause names what the referenced rule does"
if printf '%s\n' "$STRIP" | grep -qF 'remove the tag from any story heading carrying it' &&
   printf '%s\n' "$STRIP" | grep -qF 'log one line per strip'; then
  test_pass
else
  test_fail "the clause references 1b without naming its effect: $STRIP"
fi

# --- must NOT begin phase 2 while a generated epic still carries the tag ---------------------
#
# Ordering, measured as position. The strip sentence must start before the sentence that runs
# /cpm:do over the epics, and both offsets come from the clause itself.

offset_of() { printf '%s' "$1" | grep -bo "$2" | head -1 | cut -d: -f1; }

STRIP_AT=$(offset_of "$PHASE" 'Before the first /cpm:do of phase 2')
WORK_AT=$(offset_of "$PHASE" 'In phase 2, run /cpm:do on every epic doc')

test_start "control: both sentences were located in the clause"
if [ -n "$STRIP_AT" ] && [ -n "$WORK_AT" ]; then
  test_pass
else
  test_fail "offsets read as strip='$STRIP_AT' work='$WORK_AT'"
fi

test_start "must NOT begin phase 2 before the strip: the instruction comes first"
if [ "$STRIP_AT" -lt "$WORK_AT" ]; then
  test_pass
else
  test_fail "the strip is instructed at $STRIP_AT, after the phase-2 work at $WORK_AT"
fi

test_start "control: the ordering check moves when the two sentences are swapped"
SWAPPED="$TEST_TMPDIR/ralph-strip-after-work.md"
python3 - "$RALPH_SKILL" "$SWAPPED" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
out = []
for line in open(src):
    if line.startswith('Work spec {spec_path} to completion.'):
        strip = line[line.index('Before the first /cpm:do of phase 2'):line.index('In phase 2, run /cpm:do')]
        work = line[line.index('In phase 2, run /cpm:do'):]
        line = line[:line.index('Before the first /cpm:do of phase 2')] + work.rstrip('\n') + ' ' + strip.rstrip() + '\n'
    out.append(line)
open(dst, 'w').writelines(out)
PY
SWAPPED_PHASE=$(phase_clause "$SWAPPED")
if [ "$(offset_of "$SWAPPED_PHASE" 'Before the first /cpm:do of phase 2')" -gt \
     "$(offset_of "$SWAPPED_PHASE" 'In phase 2, run /cpm:do on every epic doc')" ]; then
  test_pass
else
  test_fail "swapping the sentences did not change their order"
fi

# --- must NOT strip tags from epic docs the run did not generate -----------------------------
#
# The bounded surface, asserted positively and then negatively. The positive is that the
# clause names the epics this run wrote; the negative is that it never widens to "every epic
# doc" or the directory — the wrong edit being a clause that strips whatever it finds, which
# would silently rewrite a doc a human is mid-way through planning.

test_start "the clause bounds the strip to the docs this run generated"
assert_contains "$STRIP" "the epic docs this run generated"

test_start "and says explicitly that nothing else is touched"
assert_contains "$STRIP" "touching no epic doc this run did not write"

test_start "must NOT widen the surface to the epics directory or to every doc"
assert_empty "$(printf '%s\n' "$STRIP" | grep -oE 'docs/epics/|every epic doc on disk|all epic docs')"

test_start "control: a widened surface is detected"
WIDE="$TEST_TMPDIR/ralph-wide-strip.md"
sed 's|strip \[plan\] tags from the epic docs this run generated|strip [plan] tags from all epic docs in docs/epics/|' \
  "$RALPH_SKILL" > "$WIDE"
WIDE_STRIP=$(strip_sentence "$(phase_clause "$WIDE")")
if [ -n "$(printf '%s\n' "$WIDE_STRIP" | grep -oE 'docs/epics/|every epic doc on disk|all epic docs')" ]; then
  test_pass
else
  test_fail "the widened clause read as bounded: $WIDE_STRIP"
fi

# The boundary the second must-NOT protects is only meaningful if the run *has* a way to tell
# its own epics from anyone else's. It does: phase 1 writes them from {spec_path}, and phase 2
# selects by source spec. Asserted here so the bound is not merely stated but reachable.
test_start "the run can tell its own epics apart, so the bound is applicable"
assert_contains "$PHASE" "every epic doc naming {spec_path} as its source spec"

test_summary
