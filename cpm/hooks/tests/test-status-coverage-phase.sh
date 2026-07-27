#!/bin/bash
# test-status-coverage-phase.sh — Tests for cpm:status's spec coverage roll-up phase
# (Epic 44-02 Story 1)
#
# --- What is an oracle here, and what is only a regression net ----------------------
#
# This story's deliverable is prose: instructions a model follows. Two of its criteria
# have real oracles and three do not, and the difference is stated here rather than
# blurred, because a test that greps a skill file for a phrase it was just given is
# measuring nothing.
#
# Oracles:
#   - The documented invocation is extracted from `status/SKILL.md` and run *verbatim*
#     with `CLAUDE_PROJECT_DIR` unset. That is the environment a skill's Bash call
#     actually has, and a re-typed copy is the exact defect spec 43 spent an epic on.
#   - Every requirement's text in the records is byte-identical to the spec's own bullet.
#     Verbatim is checkable, and it is the criterion that stops what a stakeholder asked
#     for from drifting away from what was built.
#
# Regression nets, and named as such:
#   - The rendering rules the phase states — MoSCoW grouping, untraced first, aggregation
#     labelled as aggregation. Whether the model's prose honours them is judgement, and it
#     is resolved at the story's gate by reading the section. What these assertions catch
#     is a *later* edit dropping a rule, which is worth catching and is not the same claim.
#   - What the phase does not contain: no matrix glob, no `**Source spec**` matching. A
#     reimplementation would need both, so their absence is evidence the skill still calls
#     the script rather than proof that it does.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/coverage-fixture-helpers.sh"

PLUGIN_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
STATUS_SKILL="$PLUGIN_ROOT/skills/status/SKILL.md"

echo "Testing: cpm:status's spec coverage roll-up phase (Epic 44-02 Story 1)"

# The one line in the skill file that invokes the roll-up as a command. The file names the
# script in prose too, so match on the invocation shape rather than the filename alone.
extract_rollup_command() {
  grep -m1 -F 'bash "${CLAUDE_PLUGIN_ROOT}/hooks/lib/coverage-rollup.sh" --spec' "$STATUS_SKILL"
}

# Only Phase 3b, so an assertion about this phase cannot be satisfied by text elsewhere in
# the file. Bounded by the next `###` heading.
phase_3b() {
  awk '/^### Phase 3b:/ { in_phase = 1; next } /^### / { in_phase = 0 } in_phase' "$STATUS_SKILL"
}

test_start "the skill file is readable"
if [ -r "$STATUS_SKILL" ]; then test_pass; else test_fail "Not readable: $STATUS_SKILL"; fi

test_start "the skill documents exactly one roll-up invocation"
INVOCATION_COUNT=$(grep -c -F 'coverage-rollup.sh" --spec' "$STATUS_SKILL")
assert_equals "1" "$INVOCATION_COUNT"

# Everything below runs whatever `extract_rollup_command` returns. If it returns nothing —
# the invocation renamed, reworded, or removed — `bash -c ""` exits 0 with no output, and
# the run assertions would hold for a skill that invokes nothing at all. This is the
# assertion that turns that vacuity into a visible failure, so state it before them.
test_start "the invocation is extractable — later assertions run something"
assert_contains "$(extract_rollup_command)" "coverage-rollup.sh"

# --- A project the roll-up can be run against, built rather than found ------------------
#
# The invocation searches `<project root>/docs/epics`, so the fixture is a project, not a
# loose pair of files. Building it here rather than pointing the test at this repository
# keeps the expected values derivable from the fixture instead of from whatever state the
# repository's own specs happen to be in.

PROJ=$(coverage_fixture_dir status-project)
mkdir -p "$PROJ/docs/specifications" "$PROJ/docs/epics"

MUST_LABELS="FR1 FR2 FR3"
spec_args=()
for label in $MUST_LABELS; do
  spec_args+=(--must "$label" "the verbatim text of $label, with **emphasis** and \`code\` in it")
done

# The fixture carries one of every shape the records can take — a delivered requirement, an
# in-progress one, untraced ones, a ruled-out one, and a story-originated row. Assertions
# below range over the record types the run actually produced, so a thinner fixture would
# quietly narrow what they cover rather than failing.
FIX_SPEC=$(coverage_fixture_spec 60-spec-presentation \
  --dir "$PROJ/docs/specifications" "${spec_args[@]}" \
  --should FR9 "a should-have requirement" \
  --wont-labelled FR12 "a requirement ruled out for this iteration" \
  --nfr NFR1 "Read-only.")

coverage_fixture_matrix 60-01-coverage-presentation "docs/specifications/60-spec-presentation.md" \
  --dir "$PROJ/docs/epics" \
  --row FR1 "the verbatim text of FR1" "the FR1 criterion" "Story 1" '✓' \
  --row FR2 "the verbatim text of FR2" "the FR2 criterion" "Story 2" '' \
  --row "(story-originated)" "—" "a criterion with no requirement behind it" "Story 2" '' >/dev/null

# Run the extracted command exactly as written, from inside the fixture project, with
# CLAUDE_PROJECT_DIR genuinely unset — `env -u` removes it rather than emptying it, and
# `${VAR-default}` resolves differently for the two.
run_documented() {
  local cmd
  cmd=$(extract_rollup_command)
  ( cd "$PROJ" && run_without_env CLAUDE_PROJECT_DIR -- \
      env CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" SPEC_PATH="$1" bash -c "$cmd" )
}

# --- Criterion 1: the documented invocation runs with CLAUDE_PROJECT_DIR unset ----------

test_start "the documented invocation resolves the project root it was run in"
ROOT_DIAG=$(run_documented "$FIX_SPEC" 2>&1 >/dev/null)
assert_contains "$ROOT_DIAG" "$PROJ"

# One run, both assertions. Two runs would let "it emitted records" and "it exited zero"
# be true of different invocations, which is not what the criterion claims.
DOC_RC=0
DOCUMENTED_OUT=$(run_documented "$FIX_SPEC" 2>/dev/null) || DOC_RC=$?

test_start "the documented invocation produces records"
if [ "$(printf '%s\n' "$DOCUMENTED_OUT" | grep -c .)" -gt 0 ]; then
  test_pass
else
  test_fail "The invocation as documented emitted nothing"
fi

test_start "and that same run exits zero"
assert_equals "0" "$DOC_RC"

# Control: the shape spec 43 shipped for months — a path built from $CLAUDE_PROJECT_DIR,
# which a skill's Bash call does not have. It addresses `/docs/...`, which exists nowhere.
test_start "control: the CLAUDE_PROJECT_DIR-derived form really does fail"
OLD_FORM_RC=0
run_without_env CLAUDE_PROJECT_DIR -- bash -c \
  "bash \"$PLUGIN_ROOT/hooks/lib/coverage-rollup.sh\" --spec \"\${CLAUDE_PROJECT_DIR}/docs/specifications/60-spec-presentation.md\"" \
  >/dev/null 2>&1 || OLD_FORM_RC=$?
if [ "$OLD_FORM_RC" != "0" ]; then
  test_pass
else
  test_fail "The old form succeeded, so the new form's success proves nothing"
fi

test_start "the documented invocation passes no CLAUDE_PROJECT_DIR-derived path"
assert_not_contains "$(extract_rollup_command)" "CLAUDE_PROJECT_DIR"

# --- Criterion 3: each requirement is presented with its verbatim spec text -------------
#
# Checked against the spec file itself, not against the string the fixture was given, so
# the assertion holds over whatever the builder wrote rather than over what it was told.

test_start "every REQ record's text appears verbatim in the spec file"
MISMATCHED=""
while IFS= read -r req_text; do
  [ -n "$req_text" ] || continue
  if ! grep -qF -- "$req_text" "$FIX_SPEC"; then
    MISMATCHED="$MISMATCHED [$req_text]"
  fi
done <<EOF
$(printf '%s\n' "$DOCUMENTED_OUT" | awk -F'\t' '$1 == "REQ" { print $4 }')
EOF
assert_empty "$MISMATCHED"

test_start "the verbatim text keeps markup the spec wrote"
assert_contains "$DOCUMENTED_OUT" '**emphasis**'

# Control: text the spec does not carry is not reported as verbatim, so the check above is
# comparing something.
test_start "control: a string absent from the spec is absent from the records"
assert_not_contains "$DOCUMENTED_OUT" "a paraphrase of FR1"

# --- Criterion 2: the records support MoSCoW grouping with untraced first ---------------
#
# The section can only render what the records carry. These assert the two properties that
# make the criterion reachable: a heading on every requirement, and untraced states ahead
# of the rest. Whether the rendered prose honours them is the gate's judgement.

test_start "every REQ record carries a MoSCoW heading"
assert_empty "$(printf '%s\n' "$DOCUMENTED_OUT" | awk -F'\t' '$1 == "REQ" && $3 == ""')"

test_start "the headings are the spec's own, in the spec's order"
HEADINGS=$(printf '%s\n' "$DOCUMENTED_OUT" | awk -F'\t' '$1 == "REQ" { print $3 }' |
  awk '!seen[$0]++' | tr '\n' '|')
assert_equals "Must Have|Should Have|Won't Have (this iteration)|Non-Functional|" "$HEADINGS"

test_start "untraced requirements come before any other state"
FIRST_STATE=$(printf '%s\n' "$DOCUMENTED_OUT" | awk -F'\t' '$1 == "STATE" { print $4; exit }')
assert_equals "untraced" "$FIRST_STATE"

test_start "control: the fixture does contain both untraced and non-untraced requirements"
DISTINCT_STATES=$(printf '%s\n' "$DOCUMENTED_OUT" |
  awk -F'\t' '$1 == "STATE" { print $4 }' | sort -u | grep -c .)
if [ "$DISTINCT_STATES" -gt 1 ]; then
  test_pass
else
  test_fail "Ordering holds trivially when every requirement shares one state"
fi

# Regression net, not an oracle: the phase states the rules the rendering depends on.
test_start "regression net: the phase states that untraced requirements come first"
assert_contains "$(phase_3b)" "Untraced requirements first"

test_start "regression net: the phase states the MoSCoW grouping"
assert_contains "$(phase_3b)" "grouped under the spec's own MoSCoW headings"

test_start "regression net: the phase states that the text is quoted verbatim"
assert_contains "$(phase_3b)" "Quote each requirement's verbatim text"

test_start "regression net: the phase states that a proportion is never reported"
assert_contains "$(phase_3b)" "Never a proportion"

test_start "regression net: the phase says what to do on a non-zero exit"
assert_contains "$(phase_3b)" "non-zero exit"

# --- Criterion 4 (NFR5): status calls the script and does not reimplement it ------------

test_start "the phase names the script as the way to get the roll-up"
assert_contains "$(phase_3b)" "coverage-rollup.sh"

test_start "the phase says not to compute it in the skill"
assert_contains "$(phase_3b)" "Never compute this yourself"

# Regression net: a reimplementation needs its own matrix discovery. If a later edit adds
# one to this phase, these fire.
test_start "regression net: the phase globs for no matrices of its own"
assert_not_contains "$(phase_3b)" "docs/epics/*-coverage-"

test_start "regression net: the phase gives no instruction to match **Source spec** itself"
assert_not_contains "$(phase_3b)" "read each matrix's"

# --- Criterion 5 (must NOT): the existing project-wide view is unchanged ----------------

test_start "must NOT remove any existing phase"
EXISTING_PHASES=$(grep -c '^### Phase [1234]:' "$STATUS_SKILL")
assert_equals "4" "$EXISTING_PHASES"

test_start "the new phase is additive — Phases 1-3 still feed the same report"
assert_contains "$(phase_3b)" "changes nothing about Phases 1–3"

test_start "the new phase runs only for a spec path"
assert_contains "$(phase_3b)" "only when \`\$ARGUMENTS\` resolves to a path under \`docs/specifications/\`"

test_start "the Input section names the spec-path trigger and no other"
assert_contains "$(grep -A2 'that path is a \*\*spec\*\*' "$STATUS_SKILL")" "no other focus produces it"

test_start "the report format block still carries the project-wide sections"
assert_contains "$(sed -n '/^## Report Format/,/^## Guidelines/p' "$STATUS_SKILL")" "Recommended Next Steps"

# --- FR7: aggregation is labelled as aggregation, not verification ----------------------
#
# Story 3 sweeps every site and owns this criterion; the assertion here guards the site
# this story created. The read is the oracle — both the correct and the incorrect phrasing
# contain any token this looks for — so what it catches is the statement being dropped.

test_start "regression net: the phase states that aggregation is not verification"
assert_contains "$(phase_3b)" "aggregation, not verification"

test_start "regression net: and says which part of the section discriminates"
assert_contains "$(phase_3b)" "The untraced count is the part of this section that discriminates"

# --- Story 2: the stakeholder page ------------------------------------------------------
#
# Publishing itself cannot be exercised from a shell — the Artifact tool is a model
# capability, and the deliverable is again instructions. But "no second publishing path" is
# structural, and structure is checkable: the shared reference line is defined byte-for-byte
# by the convention, so it can be extracted from `skill-conventions.md` at run time and
# compared, rather than re-typed here as a literal that would agree with itself forever.

SHARED_CONVENTIONS="$PLUGIN_ROOT/shared/skill-conventions.md"

# The subsection alone, bounded by the next heading of any level. Story 2's assertions must
# not be satisfiable by Phase 4's artifact text further down the file.
stakeholder_page() {
  awk '/^#### The stakeholder page/ { in_sec = 1; next } /^#+ / { in_sec = 0 } in_sec' "$STATUS_SKILL"
}

# The canonical reference line, read from the fenced block the convention publishes it in.
canonical_artifact_line() {
  awk '
    /^Skills reference this procedure with exactly this line/ { armed = 1; next }
    armed && /^```/ { fence++; next }
    armed && fence == 1 { print; exit }
  ' "$SHARED_CONVENTIONS"
}

test_start "the shared conventions publish a canonical reference line"
CANONICAL=$(canonical_artifact_line)
assert_contains "$CANONICAL" "Artifact Publishing"

test_start "the stakeholder page section carries that line byte-for-byte"
assert_contains "$(stakeholder_page)" "$CANONICAL"

# "No second publishing path", stated structurally: every site in this skill that references
# publishing uses the one canonical line, with nothing reworded around it. A second path
# would have to introduce a second wording to describe itself.
test_start "every publishing reference in the skill is the canonical line, unmodified"
DIVERGENT=$(grep -n 'shared \*\*Artifact Publishing\*\* procedure' "$STATUS_SKILL" |
  while IFS= read -r hit; do
    [ "${hit#*:}" = "$CANONICAL" ] || printf '%s\n' "$hit"
  done)
assert_empty "$DIVERGENT"

test_start "control: the canonical line is not vacuously matching every line"
assert_not_contains "$CANONICAL" "Phase 4"

# Two pages, two deterministic scratch paths. One path for both would have them overwrite
# each other, which is the collision the shared convention's per-output path rule exists to
# prevent — and it is what a genuine "second publishing path" would look like in practice.
test_start "the spec page and the full-picture page use different scratch paths"
SCRATCH_PATHS=$(grep -o 'docs/plans/status-artifact-[a-z{}0-9-]*\.html' "$STATUS_SKILL" | sort -u)
assert_equals "2" "$(printf '%s\n' "$SCRATCH_PATHS" | grep -c .)"

test_start "the spec page's scratch path is numbered and slugged from the spec"
assert_contains "$SCRATCH_PATHS" 'docs/plans/status-artifact-{nn}-{slug}.html'

# Criterion 2, as far as it can be checked: every record type the page is told to render is
# one the script actually emits. The expected set is taken from the fixture run, so a record
# type renamed in the script and not in the skill is a failure rather than a stale literal.
test_start "every record type the page names is one the script emits"
EMITTED_TYPES=$(printf '%s\n' "$DOCUMENTED_OUT" | awk -F'\t' '{ print $1 }' | sort -u)
UNKNOWN_TYPES=""
for named in $(stakeholder_page | grep -o '`[A-Z][A-Z]*`' | tr -d '`' | sort -u); do
  printf '%s\n' "$EMITTED_TYPES" | grep -qx "$named" || UNKNOWN_TYPES="$UNKNOWN_TYPES $named"
done
assert_empty "$UNKNOWN_TYPES"

test_start "control: the fixture run emitted more than one record type to compare against"
if [ "$(printf '%s\n' "$EMITTED_TYPES" | grep -c .)" -gt 1 ]; then
  test_pass
else
  test_fail "One record type makes the comparison above hold for almost anything"
fi

# The page's rules live in Phase 3b and are referenced, not copied. These four assert the
# copies are absent — the only form in which "do not restate the rules" is checkable.
test_start "the page section does not restate the verbatim-text rule"
assert_not_contains "$(stakeholder_page)" "Quote each requirement's verbatim text"

test_start "the page section does not restate the never-a-proportion rule"
assert_not_contains "$(stakeholder_page)" "Never a proportion"

test_start "the page section does not restate the ruled-out rule"
assert_not_contains "$(stakeholder_page)" "List ruled-out requirements separately"

test_start "the page section does not restate the summary-last rule"
assert_not_contains "$(stakeholder_page)" "Close with the \`SUMMARY\` counts"

test_start "control: those rules are stated in the phase the page section defers to"
assert_contains "$(phase_3b)" "List ruled-out requirements separately"

# Regression nets for criterion 3. The canonical line already carries "separately confirmed,
# and never the default" and is asserted byte-for-byte above; these guard the two local
# statements that make it operational for this page rather than restating the rule.
test_start "regression net: the page is marked on-request-only in its heading"
assert_contains "$(grep '^#### The stakeholder page' "$STATUS_SKILL")" "(on request only)"

test_start "regression net: a page request on a spec asks which page rather than choosing"
assert_contains "$(sed -n '/^## Input/,/^## State Management/p' "$STATUS_SKILL")" \
  "ask which is wanted rather than choosing"

test_start "regression net: neither page's confirmation carries the other"
assert_contains "$(sed -n '/^## Input/,/^## State Management/p' "$STATUS_SKILL")" \
  "publishing one is never confirmation for the other"

test_start "regression net: the aggregation statement is carried onto the page"
assert_contains "$(stakeholder_page)" "Carry the aggregation statement onto the page"

test_summary
