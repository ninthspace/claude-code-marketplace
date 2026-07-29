#!/bin/bash
# test-ralph-promise.sh — Tests for `cpm:ralph`'s script-backed completion promise
# (Epic 44-03 Story 1, spec 44 FR8 / NFR5 / AD4) and for the invocations that change must
# not disturb (Story 2, FR9).
#
# Both stories live here because Story 2's subject *is* Story 1's change: it fences what the
# completion clause could have broken. Splitting them would put a third copy of the template
# extraction in the tree, and that extraction is the AD5-critical part — a re-typed copy is
# how a documented invocation drifted from the real one for months.
#
# --- What has an oracle here ------------------------------------------------------------
#
# The strong assertion is that the command the template tells the loop to run is **extracted
# from the template and actually executed**, against fixtures built for the purpose — one
# epic with every row verified, one with a row outstanding — and returns the exit codes the
# template's own instruction branches on. A clause instructing the loop to branch on an exit
# code that the script never returns would read perfectly and do nothing, and that is the
# failure no amount of grepping the prose can see.
#
# The paired assertion is the story's first criterion, and it is deliberately one assertion
# about two sites: the promise instruction and the script invocation must land together, so
# neither can ship alone. Its controls run the identical predicate over mutated copies with
# one side removed.
#
# The rest are regression nets over prose, and are labelled as such below.
#
# --- What this suite does not test -------------------------------------------------------
#
# Whether the loop actually stops. That needs the ralph-wiggum stop hook, a live session and
# a completed epic run; nothing here launches a loop. What is checkable — and checked — is
# that the instruction is in the operative site, that the command it names works, and that
# the promise text stays exactly what the stop hook compares against.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/coverage-fixture-helpers.sh"

RALPH_SKILL="$SCRIPT_DIR/../../skills/ralph/SKILL.md"
ROLLUP="$SCRIPT_DIR/../lib/coverage-rollup.sh"

echo "Testing: ralph's script-backed completion promise (Epic 44-03 Story 1)"
echo "======================================================================"

# The generated prompt template: the single line beginning "Run /cpm:do on epics".
# Extracted rather than re-typed — a re-typed copy is how a documented invocation drifted
# from the real one for months (spec 43, epic 43-01).
prompt_line() { grep -F 'Run /cpm:do on epics' "$1"; }

PROMPT=$(prompt_line "$RALPH_SKILL")

# Everything below reads $PROMPT. An empty extraction makes each of those assertions hold
# for whatever the file says, so it is refused here rather than absorbed silently.
test_start "the prompt template line is extractable"
if [ -n "$PROMPT" ]; then
  test_pass
else
  test_fail "no 'Run /cpm:do on epics' line in $RALPH_SKILL"
fi

# --- Criterion 1: the promise and the invocation land together ---------------------------

# The marker is the *affirmative* branch, trailing semicolon included. A looser
# `output ALL_EPICS_COMPLETE` also matches the template's prohibition — "never output
# ALL_EPICS_COMPLETE without having run that command" — so a template that had lost its emit
# instruction entirely still satisfied the pair, on the strength of the sentence forbidding
# the thing. Retro 21 again: the rule and its violation share their tokens.
PROMISE_MARKER='then output ALL_EPICS_COMPLETE;'
INVOCATION_MARKER='--epic {epic_glob} --verdict'

# One predicate over one file, so the real file and the mutated fixtures below are judged by
# identical logic. The pairing is the claim: a promise instruction without the invocation is
# the unbacked promise FR8 removes, and an invocation without the promise runs a check whose
# answer nothing consumes.
has_both() {
  local line
  line=$(prompt_line "$1")
  case "$line" in
    *"$PROMISE_MARKER"*) ;;
    *) return 1 ;;
  esac
  case "$line" in
    *"$INVOCATION_MARKER"*) ;;
    *) return 1 ;;
  esac
  return 0
}

test_start "the promise instruction and the script invocation are both in the template"
if has_both "$RALPH_SKILL"; then
  test_pass
else
  case "$PROMPT" in
    *"$PROMISE_MARKER"*) test_fail "the promise instruction is present but the invocation is not" ;;
    *) test_fail "the script invocation is present but the promise instruction is not" ;;
  esac
fi

# Controls: the same predicate over copies with one side removed. Without these, the pairing
# assertion proves only that the file contains two strings someone put there.
sed 's/--epic {epic_glob} --verdict/--epic {epic_glob}/' "$RALPH_SKILL" > "$TEST_TMPDIR/no-verdict.md"
sed 's/then output ALL_EPICS_COMPLETE/then stop/' "$RALPH_SKILL" > "$TEST_TMPDIR/no-promise.md"

test_start "control: the pair is detected as broken when the invocation loses --verdict"
if has_both "$TEST_TMPDIR/no-verdict.md"; then
  test_fail "the predicate accepted a template whose invocation asks for no verdict"
else
  test_pass
fi

test_start "control: the pair is detected as broken when the promise is removed"
if has_both "$TEST_TMPDIR/no-promise.md"; then
  test_fail "the predicate accepted a template that never emits the promise"
else
  test_pass
fi

# --- Criterion 3: the instruction is in the template, not only in the override table ------
#
# The stop hook feeds the template line back verbatim on each iteration and the loop never
# reads the table (retro 21). A table-only change documents a behaviour the loop lacks.
#
# The table moved to docs/maintenance/README.md on 2026-07-28 — it is a maintenance
# record, and it was being loaded on every invocation. The claim here is untouched by that:
# the record and the template must agree. Only the file the row half is read from changed.

RALPH_COUPLING="$SCRIPT_DIR/../../../docs/maintenance/README.md"
TABLE_ROW='| Step 8 — Completion of the last epic'

test_start "the override table records the completion behaviour"
assert_contains "$(grep -F -- "$TABLE_ROW" "$RALPH_COUPLING")" "coverage-rollup.sh"

# The discriminating control: the record carrying the row while the template clause is
# stripped is exactly the shape a table-only change takes, and it must not pass.
sed 's/run bash {rollup_script} --epic {epic_glob} --verdict and let its exit code decide: //' \
  "$RALPH_SKILL" > "$TEST_TMPDIR/table-only.md"

test_start "control: a table row without the template clause does not satisfy the pair"
if has_both "$TEST_TMPDIR/table-only.md"; then
  test_fail "the predicate accepted a change that lives only in the override table"
else
  test_pass
fi

# Confirms the fixture above is the *table-only* shape rather than the nothing shape: the
# mutation strips the skill's clause and must leave the record's row standing.
test_start "control: the record still carries the row the mutation did not touch"
assert_contains "$(grep -F -- "$TABLE_ROW" "$RALPH_COUPLING")" "coverage-rollup.sh"

test_start "and the skill no longer carries that row itself"
assert_empty "$(grep -F -- "$TABLE_ROW" "$RALPH_SKILL")"

# --- The command the template names actually behaves as the template says ----------------
#
# The template branches on exit 0 and exit 3. This runs the command it names — with the two
# placeholders substituted the way Step 2 substitutes them — against fixtures built to
# produce each outcome. A clause branching on a code the script never returns would read
# perfectly and never fire.

R_DIR=$(coverage_fixture_dir ralph-promise)

coverage_fixture_matrix 80-01-coverage-done "docs/specifications/80-spec-ralph.md" \
  --dir "$R_DIR" --epic "$R_DIR/80-01-epic-done.md" \
  --row FR1 "a requirement" "the FR1 criterion" "Story 1" '✓' >/dev/null
coverage_fixture_matrix 80-02-coverage-open "docs/specifications/80-spec-ralph.md" \
  --dir "$R_DIR" --epic "$R_DIR/80-02-epic-open.md" \
  --row FR1 "a requirement" "the FR1 criterion" "Story 1" '' >/dev/null
coverage_fixture_matrix 80-03-coverage-target "docs/specifications/80-spec-ralph.md" \
  --dir "$R_DIR" --epic "$R_DIR/80-03-epic-target.md" \
  --tag '[target]' \
  --row NFR1 "a requirement about the production host" "the NFR1 criterion" "Story 1" '' >/dev/null
: > "$R_DIR/80-01-epic-done.md"
: > "$R_DIR/80-02-epic-open.md"
: > "$R_DIR/80-03-epic-target.md"

# Substitute the template's placeholders and run what is left, with CLAUDE_PROJECT_DIR unset
# — the environment a model-issued Bash call actually has (AD5).
run_templated() {
  local cmd
  cmd=$(printf '%s\n' "$PROMPT" |
    sed -n 's/.*\(run bash {rollup_script} --epic {epic_glob} --verdict\).*/\1/p' |
    sed -e 's/^run //' -e "s|{rollup_script}|$ROLLUP|" -e "s|{epic_glob}|$1|")
  RUN_CMD="$cmd"
  RUN_RC=0
  run_without_env CLAUDE_PROJECT_DIR -- bash -c "$cmd" >/dev/null 2>&1 || RUN_RC=$?
}

test_start "the invocation is recoverable from the template as a runnable command"
run_templated "$R_DIR/80-01-epic-done.md"
assert_contains "$RUN_CMD" "coverage-rollup.sh"

RC_DELIVERED="$RUN_RC"
run_templated "$R_DIR/80-02-epic-open.md"
RC_OUTSTANDING="$RUN_RC"
run_templated "$R_DIR/80-03-epic-target.md"
RC_TARGET="$RUN_RC"

test_start "the command the template names exits 0 when every row is verified"
assert_equals "0" "$RC_DELIVERED"

test_start "and exits 3 when a row is not"
assert_equals "3" "$RC_OUTSTANDING"

test_start "and a third code when the only unverified row is [target]"
if [ "$RC_TARGET" != "$RC_DELIVERED" ] && [ "$RC_TARGET" != "$RC_OUTSTANDING" ]; then
  test_pass
else
  test_fail "the target-only fixture returned $RC_TARGET, the same as delivered or outstanding"
fi

test_start "control: the two fixtures produce different codes, so the pair means something"
if [ "$RC_DELIVERED" != "$RC_OUTSTANDING" ]; then
  test_pass
else
  test_fail "both fixtures returned $RC_DELIVERED — the codes below compare against one value"
fi

# The correspondence, which is the point of running the command at all: the codes the
# template *branches on* are read out of the template and compared to the codes the script
# *returned*. Without this, changing the template's "on 3" to "on 4" left every assertion
# above passing — the script still exited 3, the template still read like a correct
# instruction, and the branch could never fire. Asserting the script's behaviour and the
# template's prose separately does not assert that they refer to the same thing.
TEMPLATE_OK_CODE=$(printf '%s\n' "$PROMPT" | sed -n 's/.*let its exit code decide: on \([0-9]*\),.*/\1/p')
TEMPLATE_OPEN_CODE=$(printf '%s\n' "$PROMPT" | sed -n 's/.*; on \([0-9]*\), do not output it, name the unverified.*/\1/p')
TEMPLATE_TARGET_CODE=$(printf '%s\n' "$PROMPT" | sed -n 's/.*; on \([0-9]*\), do not output it, print TARGET-ONLY.*/\1/p')

test_start "the template's emit branch names the code the script returns when delivered"
assert_equals "$RC_DELIVERED" "$TEMPLATE_OK_CODE"

test_start "the template's keep-working branch names the code it returns when outstanding"
assert_equals "$RC_OUTSTANDING" "$TEMPLATE_OPEN_CODE"

# The branch a stated character budget cannot defend. Removing it moves the template's
# length, so the budget assertion fires — but it fires for every edit, which makes it a
# change detector rather than an oracle for this branch. This compares the branch to a code
# the script was just observed returning.
test_start "the template's target-only branch names the code it returns for a [target] row"
assert_equals "$RC_TARGET" "$TEMPLATE_TARGET_CODE"

test_start "control: all three codes were actually extracted from the template"
if [ -n "$TEMPLATE_OK_CODE" ] && [ -n "$TEMPLATE_OPEN_CODE" ] && [ -n "$TEMPLATE_TARGET_CODE" ]; then
  test_pass
else
  test_fail "extracted '[$TEMPLATE_OK_CODE]' '[$TEMPLATE_OPEN_CODE]' '[$TEMPLATE_TARGET_CODE]' — an empty one compares against nothing"
fi

# The branch has to end the run rather than route it somewhere else, and "stop the loop" is
# inert unless the template also says what stopping does — the template is the only thing the
# loop reads, so a definition living in the skill's prose would never reach it.
test_start "the target-only branch stops the loop by naming the state file"
TARGET_BRANCH=$(printf '%s\n' "$PROMPT" | grep -oE 'on 5,[^;]*')
if printf '%s\n' "$TARGET_BRANCH" | grep -qF 'do not output it' &&
   printf '%s\n' "$TARGET_BRANCH" | grep -qF 'active: false in .claude/ralph-loop.local.md' &&
   printf '%s\n' "$TARGET_BRANCH" | grep -qF 'delete that file instead'; then
  test_pass
else
  test_fail "the target-only branch reads: $TARGET_BRANCH"
fi

# --- Criterion 2: the promise carries its evidence ---------------------------------------
#
# Regression nets. Whether a log reads as falsifiable is judgement; what is checkable is that
# the template still tells the loop to print the counts, and still tells it where.

test_start "regression net: the template instructs printing the coverage counts"
assert_contains "$PROMPT" "COVERAGE: N of M rows marked verified across K matrices"

test_start "regression net: the counts go beside the promise, not inside the tag"
assert_contains "$PROMPT" "never inside the promise tag the stop hook matches"

# The stop hook compares the tag's text to `completion_promise` with literal string equality
# (`[[ "$PROMISE_TEXT" = "$COMPLETION_PROMISE" ]]`, after whitespace normalisation). Evidence
# placed *inside* the tag would never match, and the loop would run to its iteration cap on a
# completed epic. This is why AD4's "the tag carries its evidence" is implemented as evidence
# beside the tag.
# The template writes no `<promise>` tag of its own: Step 2 rules XML out of the prompt (the
# stop hook feeds it back verbatim), and the tag instruction reaches the model from the
# hook's own per-iteration system message. So the template names the bare token, and the
# evidence clause has to keep it bare.
test_start "the template writes no promise tag of its own"
assert_not_contains "$PROMPT" "<promise>"

test_start "regression net: the template forbids deriving the verdict without the script"
assert_contains "$PROMPT" "Never work that verdict out yourself"

test_start "regression net: and forbids emitting the promise without running the command"
assert_contains "$PROMPT" "without having run that command in the same turn"

test_start "regression net: the template says what to do on the other exit codes"
assert_contains "$PROMPT" "on any other code, do not output it and say the check could not run"

# --- Criterion 4 (NFR5): ralph calls the script and does not reimplement it ---------------
#
# Negative regression nets. A reimplementation would need matrix discovery and a Verified
# column read; their absence is evidence, not proof.

test_start "regression net: ralph globs for no coverage matrices of its own"
assert_empty "$(grep -n 'coverage-\*\|\*-coverage' "$RALPH_SKILL")"

test_start "regression net: ralph reads no Verified column"
assert_empty "$(grep -n 'Verified column' "$RALPH_SKILL")"

# This one was a file-wide ban on the word `untraced` until epic 44-03's Story 3, which had
# to *name* the measurement in order to say `cpm:ralph` cannot produce it; it was then a ban
# with two allowed phrasings until spec 45 made the word load-bearing a third way — spec
# mode's phase predicate reads `untraced` out of the script's own SUMMARY record, so a ban on
# the token bans the contract along with the caution. Retro 21's shape for the fifth time in
# two specs, and retro 26's finding that the net pins the defect: what it is *for* is that
# `ralph` never derives requirement state itself, and that is a question about which inputs
# it reads, not which words it writes. Rewritten against the inputs.
#
# Deriving an untraced count means comparing a spec's requirement list to matrix rows, so it
# needs all three of: the matrices (netted above), the Verified column (netted above), and
# the requirement bullets. This is the third. Evidence, not proof — a skill could describe
# the comparison without naming any of them — which is what the operative-site assertion
# below is for.
test_start "regression net: the operative template names no requirement-state vocabulary"
assert_empty "$(printf '%s\n' "$PROMPT" | grep -oE 'in-progress requirement')"

test_start "regression net: ralph reads no requirement list of its own"
assert_empty "$(grep -nE 'MoSCoW|Must Have|Should Have|requirement bullets' "$RALPH_SKILL")"

# There was a fourth net here: every line mentioning `untraced` had to match one of a short
# list of allowed phrasings. It is **deleted rather than extended**, and that is the finding
# worth recording. Spec 45 gives spec mode a phase predicate whose whole subject is the
# untraced count, so legitimate sentences about it now appear throughout the skill and each
# one needed a new phrasing added to the list. A net that grows a clause per sentence has
# stopped being a rule and become a transcript of the file — it would pass on anything already
# written and fail only on wording, which is the failure retro 26 named. What it was for is
# covered without vocabulary by the three structural nets above, and sharply by
# `test-ralph-phase-predicate.sh`, which reads the contract section sentence by sentence with
# its denials. Scanning the whole file that way was tried and abandoned: "an untraced count"
# and "count the rows" differ by part of speech, not by tokens.

# --- The resolved script path (AD5 applied to the loop's own environment) -----------------
#
# The prompt is fed back as a plain user turn, not run inside a skill, so a plugin-relative
# variable is not guaranteed to be set when the completion check runs — and an unset one
# expands to a bare `/hooks/lib/coverage-rollup.sh`. That is spec 43's defect. The path is
# resolved at assembly time instead, like every other placeholder.

# Slice the skill between two heading patterns. Named because three sections are read here
# and an inline `sed` repeated per assertion is how one of them silently becomes a different
# range from its neighbour.
section() { sed -n "/$1/,/$2/p" "$RALPH_SKILL"; }

# The two-sided bound this suite introduced now lives in test-helpers.sh as
# `assert_slice_bounded`, so the pattern is available to every suite rather than to this
# one — retro 24 recommendation 4. Each range is still guarded once, where it is defined.
PREFLIGHT_1F=$(section '^#### 1f\.' '^#### 1g\.')

test_start "slice: the roll-up pre-flight step spans its own section and no more"
assert_slice_bounded "$RALPH_SKILL" '^#### 1f\.' '^#### 1g\.' 4 30

test_start "the template passes a resolved placeholder, not a runtime variable"
assert_not_contains "$PROMPT" "CLAUDE_PLUGIN_ROOT"

test_start "pre-flight resolves that placeholder to an absolute path"
assert_contains "$PREFLIGHT_1F" "absolute path"

test_start "and fails loudly when the script is not there"
assert_contains "$PREFLIGHT_1F" "was not found at"

# --- The exit-code contract is readable where assembly needs it --------------------------
#
# Both completion clauses and the phase predicate branch on this script's exit code, so the
# assembling agent needs the semantics as *guidance*. Stating them only inside the template
# — the text being assembled — sent a live run grepping the script for `exit 1|2|3|4`.
#
# These are not prose greps. Each code is read out of `coverage-rollup.sh` and the skill is
# required to document that number, so renumbering a constant in the script fails the suite
# rather than leaving the skill quietly wrong. The pairing is what makes it an oracle: a
# skill listing codes the script does not return would read perfectly and misroute the loop.

rollup_const() { grep -m1 "^$1=" "$ROLLUP" | cut -d= -f2; }

USAGE_CODE=$(rollup_const EXIT_USAGE)
OUTSTANDING_CODE=$(rollup_const EXIT_OUTSTANDING)
NO_MATRIX_CODE=$(rollup_const EXIT_NO_MATRIX)
TARGET_ONLY_CODE=$(rollup_const EXIT_TARGET_ONLY)

test_start "control: the script defines the four named exit constants this reads"
if [ -n "$USAGE_CODE" ] && [ -n "$OUTSTANDING_CODE" ] && [ -n "$NO_MATRIX_CODE" ] &&
   [ -n "$TARGET_ONLY_CODE" ]; then
  test_pass
else
  test_fail "could not read exit constants from $ROLLUP (usage='$USAGE_CODE' outstanding='$OUTSTANDING_CODE' no-matrix='$NO_MATRIX_CODE' target-only='$TARGET_ONLY_CODE')"
fi

# 0 and 1 have no named constant — they are `exit 0` and `exit 1` literals — so they are
# listed here rather than derived. Every code a caller can observe must appear.
for code in 0 1 "$USAGE_CODE" "$OUTSTANDING_CODE" "$NO_MATRIX_CODE" "$TARGET_ONLY_CODE"; do
  test_start "pre-flight documents exit code $code"
  assert_contains "$PREFLIGHT_1F" "\`$code\`"
done

# The containment, checked against the script's own numbers rather than literals. Both of the
# `--verdict`-only codes are named, so adding one to the script without documenting the
# containment fails here rather than silently leaving the table one code short.
test_start "pre-flight names both --verdict-only codes as reachable only with the flag"
assert_contains "$PREFLIGHT_1F" \
  "\`$NO_MATRIX_CODE\` and \`$TARGET_ONLY_CODE\` are reachable only with \`--verdict\`"

# The terminal state is the one that broke in the field: exit 3 kept a run alive across 34
# iterations of finished work. `5` earns its row only if the row says the run ends there.
test_start "the target-only code is documented as terminal"
assert_contains "$PREFLIGHT_1F" "**Terminal.**"

# The must-NOT: the whole point is that the agent stops re-deriving this from the source.
test_start "and pre-flight tells the reader not to re-derive it from the script"
assert_contains "$PREFLIGHT_1F" "Do not re-derive"

# The phase predicate's exit-4 rule and this table must name the same code. Two sites
# stating a routing decision is how they drift apart.
test_start "the phase predicate branches on the same no-matrix code"
assert_contains "$(section '^#### The phase predicate' '^#### ')" \
  "Exit \`$NO_MATRIX_CODE\` is the only code that sends the loop into"

test_start "the placeholder is listed among the prompt's interpolated variables"
assert_contains "$(section '^### Step 2: Prompt Assembly' '^\*\*Template\*\*')" \
  '`{rollup_script}`'

# --- Criterion 5: the stated length matches the template ---------------------------------
#
# Also asserted by `test-ralph-autonomous-wiring.sh`. Both extract and compare rather than
# pinning a literal, so they cannot disagree — and the criterion belongs to this story, so a
# reader of this suite should see it verified here rather than inferred from another file.

test_start "the stated character budget matches the template's actual length"
STATED=$(grep -oE '\*\*Length: [0-9]+ characters\*\*' "$RALPH_SKILL" | grep -oE '[0-9]+')
assert_equals "${#PROMPT}" "$STATED"

test_start "control: a stated budget that disagrees with the template is detected"
sed 's/\*\*Length: [0-9]* characters\*\*/**Length: 1100 characters**/' "$RALPH_SKILL" \
  > "$TEST_TMPDIR/bad-budget.md"
BAD_STATED=$(grep -oE '\*\*Length: [0-9]+ characters\*\*' "$TEST_TMPDIR/bad-budget.md" | grep -oE '[0-9]+')
BAD_PROMPT=$(prompt_line "$TEST_TMPDIR/bad-budget.md")
if [ "${#BAD_PROMPT}" = "$BAD_STATED" ]; then
  test_fail "the comparison accepted a file stating 1100 against a ${#BAD_PROMPT}-character template"
else
  test_pass
fi

# --- Story 2 (FR9): the existing invocations still behave as documented ------------------
#
# Nothing here launches a loop, so "behaves as documented" is checked where the behaviour is
# defined: the Input section's argument forms, Step 1a's auto-discovery procedure, and the
# one place Story 1 could genuinely have broken a shape — the completion command, which
# takes `{epic_glob}` and so must work for every shape that produces one.

INPUT_SECTION=$(section '^## Input' '^## Process')
DISCOVERY=$(section '^#### 1a\. Epic Discovery' '^#### 1b\.')

test_start "slice: the Input section spans its own section and no more"
assert_slice_bounded "$RALPH_SKILL" '^## Input' '^## Process' 6 16

# Widened from 8-20 when epic 45-02 Story 1 added mode resolution to this step. The bound is
# two-sided so a slice that swallows its neighbour is caught; it is not a size budget, and
# raising it to fit a section that genuinely grew is the maintenance it was built for.
test_start "slice: the epic-discovery step spans its own section and no more"
assert_slice_bounded "$RALPH_SKILL" '^#### 1a\. Epic Discovery' '^#### 1b\.' 8 32

# Story 1 (epic 45-02) rewrote this sentence: a spec path is not an epic path, so the old
# wording sent spec mode down the auto-discovery branch — FR2's failure mode stated as FR1's
# bug. The assertion tracks the sentence because FR2's claim is about *this* fallback.
test_start "no path at all still falls through to auto-discovery"
assert_contains "$INPUT_SECTION" "If no path of any kind is provided, auto-discover all incomplete epics"

test_start "auto-discovery still globs every epic shape"
assert_contains "$DISCOVERY" 'docs/epics/*-epic-*.md'

test_start "auto-discovery still filters out complete and retired epics"
assert_contains "$DISCOVERY" "not \`Complete\`/\`Done\`"

test_start "auto-discovery still stops when there is nothing to run"
assert_contains "$DISCOVERY" "No incomplete epics found. Nothing to run."

# The four documented argument forms. Named individually so a failure says which one went.
for form in '**Epic paths**' '**`--max-iterations N`**' '**`--story-filter`**' '**`--dry-run`**'; do
  test_start "the Input section still documents $form"
  assert_contains "$INPUT_SECTION" "$form"
done

# Story 1 added a pre-flight step. A new step that *stops* on a missing script would turn a
# working invocation into a failing one, which is what the must-NOT rules out. It warns and
# offers to continue, the same shape as the stop-hook detection step beside it.
test_start "the new pre-flight step degrades rather than aborting"
assert_contains "$PREFLIGHT_1F" '"Continue anyway" or "Stop"'

# A pre-flight step that ran only for some argument shapes would make Story 1's change
# shape-dependent, which is what the must-NOT rules out. Position is the checkable form of
# "runs for every invocation": inside Step 1, after discovery, before assembly.
ln_1a=$(grep -n '^#### 1a\. Epic Discovery' "$RALPH_SKILL" | cut -d: -f1)
ln_1f=$(grep -n '^#### 1f\. ' "$RALPH_SKILL" | cut -d: -f1)
ln_step2=$(grep -n '^### Step 2: Prompt Assembly' "$RALPH_SKILL" | cut -d: -f1)

test_start "the new pre-flight step sits in the sequence every invocation runs"
if [ -n "$ln_1a" ] && [ -n "$ln_1f" ] && [ -n "$ln_step2" ] &&
   [ "$ln_1a" -lt "$ln_1f" ] && [ "$ln_1f" -lt "$ln_step2" ]; then
  test_pass
else
  test_fail "expected 1a < 1f < Step 2, got 1a=$ln_1a 1f=$ln_1f step2=$ln_step2"
fi

# The single genuine coupling between Story 1 and the input shapes: the completion command
# takes `{epic_glob}`. All three shapes resolve to a path list, so the command has to work
# for a list of more than one — the range and multi-path shapes produce exactly that. A
# third fixture so the all-delivered list is two distinct epics rather than one repeated.
coverage_fixture_matrix 80-03-coverage-done "docs/specifications/80-spec-ralph.md" \
  --dir "$R_DIR" --epic "$R_DIR/80-03-epic-done.md" \
  --row FR2 "a second requirement" "the FR2 criterion" "Story 1" '✓' >/dev/null
: > "$R_DIR/80-03-epic-done.md"

test_start "the completion command works for a multi-epic list, as a range produces"
run_templated "$R_DIR/80-01-epic-done.md $R_DIR/80-02-epic-open.md"
assert_equals "3" "$RUN_RC"

test_start "control: a two-epic list with both delivered exits 0"
run_templated "$R_DIR/80-01-epic-done.md $R_DIR/80-03-epic-done.md"
assert_equals "0" "$RUN_RC"

# `{epic_glob}` was a decorative parenthetical until Story 1 made it a command argument, and
# the skill had never said what form it takes. Story 2 defined it; these assert the
# definition exists and that the template's use matches it.
test_start "the skill defines {epic_glob} as a resolved path list, not a pattern"
assert_contains "$DISCOVERY" "a path list, not a pattern"

test_start "and says every input shape resolves to that one list"
assert_contains "$DISCOVERY" "Every input shape resolves to one epic list"

test_summary
