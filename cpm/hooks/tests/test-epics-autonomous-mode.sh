#!/bin/bash
# test-epics-autonomous-mode.sh — Tests for `cpm:epics`' autonomous branch
# (Epic 45-01, all four stories — spec 45 FR4, FR5, NFR3, NFR4).
#
# All four stories share this file because each one's subject is the previous one's text:
# Story 2 replaces the placeholder Story 1 shipped, Story 3 extends the same section, and
# Story 4 counts what Stories 1 and 2 between them produced. Splitting them would put four
# copies of the section extraction in the tree (retro 24).
#
# --- What has an oracle here ------------------------------------------------------------
#
# Nothing here launches `cpm:epics`, autonomously or otherwise. Every criterion in this epic
# is prose asserted across a boundary, so the strongest form available is **correspondence**
# — reading a name out of one artefact and looking for it in the other, so that renaming
# either side fails. Three assertions take that form, and they are the ones no single
# artefact can satisfy alone (retro 24: two separately-correct halves are not a working
# whole):
#
#   1. the branch name `cpm:ralph`'s template cites, looked up as a heading in `cpm:epics`;
#   2. the breadcrumb field the branch defines, looked for at the Step 3 site that must
#      qualify its own interactive instruction;
#   3. the breadcrumb's stated format against the example given beneath it.
#
# The six-site criterion is arithmetic rather than judgement (retro 22). Two counts are
# derived from opposite ends — gate sites from the skill's body, dispositions from the
# branch — and asserted equal. A seventh gate raises the first and not the second; a deleted
# disposition lowers the second and not the first. Both directions have a control.
#
# Every control runs the identical predicate over a one-line mutation of the real file, and
# each mutation was checked by diff to change exactly the line it claims (retro 24: a
# control that fails a *broad* set of assertions is as uninformative as one that fails none).
#
# --- What this suite does not test -------------------------------------------------------
#
# Whether an autonomous run actually takes any of these dispositions. That needs a live
# `cpm:ralph` loop reaching a `cpm:epics` gate, and today's template only ever runs
# `/cpm:do` — the referencing clause is conditional and inert until epic 45-03 adds the
# phase-1 branch. Nor does it test that the write surface is honoured at runtime: NFR3 is
# asserted here as an instruction present and unambiguous, not as a filesystem observation.
# What is checkable is that the branch exists, that it covers every gate site with a stated
# disposition, that the prompt points at it by a name that resolves, and that the boundary
# and breadcrumb are stated in the operative section rather than only in commentary.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

EPICS_SKILL="$SCRIPT_DIR/../../skills/epics/SKILL.md"
RALPH_SKILL="$SCRIPT_DIR/../../skills/ralph/SKILL.md"

echo "Testing: cpm:epics autonomous branch (Epic 45-01, Stories 1-4)"
echo "=============================================================="

# --- Predicates, defined once and run over both the real files and the fixtures ----------

# The branch's bounds, named once. Three predicates below slice on them and one asserts
# their width; an inline copy per predicate is how one of them silently becomes a different
# range from its neighbours. The width assertion is two-sided because a range matching
# nothing fails every assert_contains loudly, while one matching *wider* than intended
# passes on text belonging to the next section (retro 24).
BRANCH_START='^### Autonomous Mode'
BRANCH_END='^### Stale-Progress Check'

auto_section() { sed -n "/$BRANCH_START/,/$BRANCH_END/p" "$1"; }

# The disposition table's data rows — the header is excluded by name rather than by
# position, so inserting a row above it cannot silently become a data row.
data_rows() { auto_section "$1" | grep '^| ' | grep -v '^| Gate |'; }

# The third cell of the row whose first cell contains <label>, trimmed. Empty when the row
# is absent *or* present with nothing in its disposition cell — the two failures this
# criterion has to tell apart from a pass. The pattern travels via ENVIRON, not `-v`, which
# applies escape processing to its value (retro 21).
disposition_cell() {
  local file="$1"
  export LBL="$2"
  auto_section "$file" | awk -F'|' '
    index($2, ENVIRON["LBL"]) { c = $4; gsub(/^[ \t]+|[ \t]+$/, "", c); print c; exit }'
}

# The generated prompt template: extracted, never re-typed (spec 43 AD5).
prompt_line() { grep -F 'Run /cpm:do on epics' "$1"; }

# The branch name the template cites, read back out of the template itself.
cited_branch() { prompt_line "$1" | grep -oE "cpm:epics' [A-Za-z ]+ branch" | sed "s/^cpm:epics' //; s/ branch\$//"; }

# The correspondence predicate: the cited name resolves to a heading in the defining skill.
# Takes both files so a fixture can mutate either side.
reference_resolves() {
  local ralph="$1" epics="$2" name
  name=$(cited_branch "$ralph")
  [ -n "$name" ] && grep -qF "### $name" "$epics"
}

PROMPT=$(prompt_line "$RALPH_SKILL")

# --- Slice guards ------------------------------------------------------------------------

test_start "the prompt template line is extractable"
if [ -n "$PROMPT" ]; then
  test_pass
else
  test_fail "no 'Run /cpm:do on epics' line in $RALPH_SKILL"
fi

test_start "slice: the autonomous branch spans its own section and no more"
assert_slice_bounded "$EPICS_SKILL" "$BRANCH_START" "$BRANCH_END" 10 26

# --- Criterion 2: each of the five gate sites has a stated autonomous disposition ---------
#
# The five sites spec 45 names by line number (`:81`, `:178`, `:214`, `:231`, `:282`).
# Line numbers drift, so each is identified here by the interactive text at its site — which
# is also what makes the existence half meaningful: a gate that is renamed or deleted fails
# here rather than leaving a table row describing a gate that is gone.

check_gate() {  # <table label> <interactive text at the site>
  local label="$1" question="$2" cell

  test_start "gate site still exists in cpm:epics: $label"
  if grep -qF "$question" "$EPICS_SKILL"; then
    test_pass
  else
    test_fail "no site in $EPICS_SKILL matching: $question"
  fi

  test_start "and has a stated autonomous disposition: $label"
  cell=$(disposition_cell "$EPICS_SKILL" "$label")
  if [ -n "$cell" ]; then
    test_pass
  else
    test_fail "no non-empty disposition cell for '$label'"
  fi
}

check_gate "Step 2 — Identify Epics"                   "Approve this grouping?"
check_gate "Step 3 — Break into Stories"               "Approve these stories?"
check_gate "Step 3b — Identify Tasks within Stories"   "Approve these tasks?"
check_gate "Step 3c — Integration Testing Story"       "Confirm with the user via AskUserQuestion"
check_gate "Step 4 — Confirm"                          "Use AskUserQuestion for final confirmation"

test_start "the branch states exactly five dispositions — no more, no fewer"
assert_equals "5" "$(data_rows "$EPICS_SKILL" | grep -c .)"

test_start "control: a table with a row removed fails the count"
grep -v '^| Step 3b ' "$EPICS_SKILL" > "$TEST_TMPDIR/gate-removed.md"
assert_equals "4" "$(data_rows "$TEST_TMPDIR/gate-removed.md" | grep -c .)"

test_start "control: and that same removal empties its disposition cell"
assert_empty "$(disposition_cell "$TEST_TMPDIR/gate-removed.md" "Step 3b — Identify Tasks within Stories")"

# A row present with nothing in its disposition cell is the failure a presence-only check
# cannot see: the gate is listed, the count is right, and the loop is told nothing.
test_start "control: a listed gate with an empty disposition cell is detected"
sed 's/^\(| Step 4 — Confirm |[^|]*|\)[^|]*|/\1 |/' "$EPICS_SKILL" > "$TEST_TMPDIR/gate-blank.md"
assert_equals "5" "$(data_rows "$TEST_TMPDIR/gate-blank.md" | grep -c .)"

test_start "control: and the count still passes while the cell check fails"
assert_empty "$(disposition_cell "$TEST_TMPDIR/gate-blank.md" "Step 4 — Confirm")"

# --- Criterion 1: defined in cpm:epics, referenced — not restated — by ralph's prompt -----

test_start "the branch is defined in cpm:epics, not in cpm:ralph"
assert_contains "$(auto_section "$EPICS_SKILL")" "single source"

test_start "ralph's prompt template carries the reference"
assert_contains "$PROMPT" "Autonomous Mode"

# The strong half: the name is read out of the template and looked up in the other file, so
# renaming the section in either place fails. Asserting each side separately would leave a
# reference to a heading that no longer exists reading perfectly (retro 24).
test_start "the name the template cites resolves to a heading in cpm:epics"
if reference_resolves "$RALPH_SKILL" "$EPICS_SKILL"; then
  test_pass
else
  test_fail "template cites '$(cited_branch "$RALPH_SKILL")', which is no heading in $EPICS_SKILL"
fi

test_start "control: renaming the section in cpm:epics breaks the correspondence"
sed 's/^### Autonomous Mode$/### Unattended Mode/' "$EPICS_SKILL" > "$TEST_TMPDIR/renamed-epics.md"
if reference_resolves "$RALPH_SKILL" "$TEST_TMPDIR/renamed-epics.md"; then
  test_fail "the correspondence held against a file whose section was renamed"
else
  test_pass
fi

test_start "control: renaming it in ralph's template breaks it too"
sed "s/cpm:epics' Autonomous Mode branch/cpm:epics' Unattended Mode branch/" "$RALPH_SKILL" \
  > "$TEST_TMPDIR/renamed-ralph.md"
if reference_resolves "$TEST_TMPDIR/renamed-ralph.md" "$EPICS_SKILL"; then
  test_fail "the correspondence held against a template citing a name with no heading"
else
  test_pass
fi

# The must-NOT half of the criterion — "references it rather than restating it". The haystack
# is the template line alone, not the whole of ralph/SKILL.md: the paragraph under the
# `cpm:do` gate table legitimately names the branch to record that its gates are not rows
# there, and a file-wide ban would catch that explanation rather than an instruction
# (retro 21, applied on sight rather than on failure — retro 24).
restates_a_disposition() {
  prompt_line "$1" | grep -oE 'Approve this grouping|Approve these stories|Approve these tasks|rendered grouping|refine round'
}

test_start "the template does not restate the branch's dispositions"
assert_empty "$(restates_a_disposition "$RALPH_SKILL")"

test_start "control: the same predicate catches a template that does restate one"
sed 's/take cpm:epics'"'"' Autonomous Mode branch/approve the rendered grouping with no refine round/' \
  "$RALPH_SKILL" > "$TEST_TMPDIR/restating-ralph.md"
if [ -n "$(restates_a_disposition "$TEST_TMPDIR/restating-ralph.md")" ]; then
  test_pass
else
  test_fail "the predicate missed a template that restated a disposition verbatim"
fi

# --- Story 2 (FR5 / AD5): the sixth gate's rule ------------------------------------------
#
# Story 2's subject *is* Story 1's placeholder — the "no disposition yet" paragraph the
# branch shipped with — so its assertions live here rather than in a second file that would
# need its own copy of the section extraction (retro 24).
#
# The strong assertion is again correspondence, not presence: the name of the field the
# branch says to record is read *out of the branch* and looked for at the Step 3 site, so
# renaming it in one place fails. Two separately-correct halves are not a working whole, and
# retro 21 found three sites stating one conditional rule three different ways.

# The sixth gate's rule: the tail of the branch, from its own bolded lead. Bounded on both
# ends by construction — auto_section is already guarded above.
sixth_gate_rule() { auto_section "$1" | sed -n '/^\*\*The sixth gate/,$p'; }

# Everything outside the branch. Used so the site-pointer assertions cannot be satisfied by
# the branch's own text.
outside_branch() { sed "/$BRANCH_START/,/$BRANCH_END/d" "$1"; }

# The breadcrumb field the branch names, read back out of the branch itself.
recorded_field() { sixth_gate_rule "$1" | grep -oE '\*\*Must-NOT proposed \(unreviewed\)\*\*' | head -1; }

field_agrees_across_sites() {
  local field
  field=$(recorded_field "$1")
  [ -n "$field" ] && outside_branch "$1" | grep -qF "$field"
}

test_start "slice: the sixth gate's rule is a bounded part of the branch"
RULE_LINES=$(sixth_gate_rule "$EPICS_SKILL" | grep -c .)
if [ "$RULE_LINES" -ge 5 ] && [ "$RULE_LINES" -le 12 ]; then
  test_pass
else
  test_fail "sixth-gate rule is $RULE_LINES non-blank lines (expected 5-12)"
fi

test_start "the sixth gate is identified by the site it governs"
assert_contains "$(sixth_gate_rule "$EPICS_SKILL")" "Must-NOT clause suggestion"

test_start "its site still exists in cpm:epics"
assert_contains "$(outside_branch "$EPICS_SKILL")" "Present them via AskUserQuestion"

# --- Criterion 1: spec-originated propagated, others recorded rather than attached --------

test_start "the rule propagates what the source spec already carries"
assert_contains "$(sixth_gate_rule "$EPICS_SKILL")" "Propagate every must-NOT line the source spec already carries"

test_start "and names propagation as transcription, not judgement"
assert_contains "$(sixth_gate_rule "$EPICS_SKILL")" "transcription"

test_start "the rest are recorded under a named field rather than dropped"
assert_contains "$(sixth_gate_rule "$EPICS_SKILL")" "Must-NOT proposed (unreviewed)"

test_start "and recorded is stated to be distinct from attached"
assert_contains "$(sixth_gate_rule "$EPICS_SKILL")" "Recorded is not attached"

# The correspondence half. A branch that defines a breadcrumb no other site mentions reads
# perfectly and leaves the gate's own reader with the interactive instruction unqualified.
test_start "the field the branch names is the field the Step 3 site names"
if field_agrees_across_sites "$EPICS_SKILL"; then
  test_pass
else
  test_fail "branch names '$(recorded_field "$EPICS_SKILL")', which appears nowhere outside the branch"
fi

test_start "control: renaming the field inside the branch breaks the correspondence"
awk '/^### Autonomous Mode/{i=1} /^### Stale-Progress Check/{i=0}
     i{gsub(/Must-NOT proposed \(unreviewed\)/, "Must-NOT deferred (unreviewed)")} {print}' \
  "$EPICS_SKILL" > "$TEST_TMPDIR/field-renamed-branch.md"
if field_agrees_across_sites "$TEST_TMPDIR/field-renamed-branch.md"; then
  test_fail "the correspondence held after the branch's field name was changed"
else
  test_pass
fi

test_start "control: renaming it at the Step 3 site breaks it too"
awk '/^### Autonomous Mode/{i=1} /^### Stale-Progress Check/{i=0}
     !i{gsub(/Must-NOT proposed \(unreviewed\)/, "Must-NOT deferred (unreviewed)")} {print}' \
  "$EPICS_SKILL" > "$TEST_TMPDIR/field-renamed-site.md"
if field_agrees_across_sites "$TEST_TMPDIR/field-renamed-site.md"; then
  test_fail "the correspondence held after the Step 3 site's field name was changed"
else
  test_pass
fi

# The interactive text at the site says "Present them via AskUserQuestion ... to accept,
# modify, or reject". Without the qualifier beside it, an autonomous run reads an
# instruction the branch contradicts — the five-defect shape retro 21 recorded, where every
# site was present and two of them disagreed.
test_start "the Step 3 site says this gate is not an approve-your-own-proposal one"
assert_contains "$(outside_branch "$EPICS_SKILL")" \
  "does not take the approve-your-own-proposal disposition"

test_start "control: the qualifier is absent from a copy with that paragraph removed"
grep -v '^\*\*Under an autonomous run this gate' "$EPICS_SKILL" > "$TEST_TMPDIR/no-pointer.md"
assert_not_contains "$(outside_branch "$TEST_TMPDIR/no-pointer.md")" \
  "does not take the approve-your-own-proposal disposition"

# --- Criterion 2 (must NOT): nothing attached that the spec cannot be quoted for ----------
#
# The forbidden behaviour and the sentence forbidding it are written in the same vocabulary,
# so a bare `assert_not_contains` over this prose would catch the prohibition itself
# (retro 21, four occurrences in spec 44 — applied here on sight rather than on failure).
# The haystack is therefore the numbered disposition list, where the string would be an
# instruction, and the assertions on it are positive: the rule has to *state* the boundary
# and *define* what makes a clause citable.

test_start "the rule forbids attaching a clause the spec cannot be quoted for"
assert_contains "$(sixth_gate_rule "$EPICS_SKILL")" \
  "Attach nothing that cannot be quoted from the source spec"

test_start "and defines citable against a named location in the spec"
assert_contains "$(sixth_gate_rule "$EPICS_SKILL")" "Acceptance Criteria Coverage table"

test_start "and refuses the reasonable-looking clause explicitly"
assert_contains "$(sixth_gate_rule "$EPICS_SKILL")" "however reasonable it looks"

test_start "control: the boundary is detectably absent once its sentence is removed"
grep -v 'Attach nothing that cannot be quoted from the source spec' "$EPICS_SKILL" \
  > "$TEST_TMPDIR/no-boundary.md"
assert_not_contains "$(sixth_gate_rule "$TEST_TMPDIR/no-boundary.md")" \
  "Attach nothing that cannot be quoted from the source spec"

# Retro 21's hazard, recorded at the site rather than only in the retro: auto-accepting is
# not the cautious option, because an invented clause can be unsatisfiable as written and
# then blocks cpm:do with nobody watching. Without this the rule reads as over-caution and
# is the first thing a later editor relaxes.
test_start "the rule records why auto-accepting is not the safe default"
assert_contains "$(sixth_gate_rule "$EPICS_SKILL")" "unsatisfiable as written"

test_start "and names the consequence for the loop, not just for the document"
assert_contains "$(sixth_gate_rule "$EPICS_SKILL")" "unable to close the story"

# --- The recording field claims no consumer it does not have ------------------------------
#
# Two epics running, a field's documented consumer turned out not to consume it (retro 21's
# `cpm:status`, retro 22's "drift detection"), and both survived because a named consumer
# reads as evidence rather than as an assertion. The first assertion checks the sentence;
# the second checks the *fact* it asserts, which is the half that cannot rot. If a skill
# ever does start reading this field, the second fails and the sentence has to be corrected
# — which is the intended failure, not a false one.

test_start "the recording field names no consumer that does not read it"
assert_contains "$(sixth_gate_rule "$EPICS_SKILL")" "Nothing parses this field today"

test_start "and that claim is true — no other skill reads the field"
assert_empty "$(grep -rl 'Must-NOT proposed' "$SCRIPT_DIR/../../skills/" 2>/dev/null |
  grep -v 'epics/SKILL.md' || true)"

# --- Story 3 (NFR3 / NFR4): the write surface and the audit trail -------------------------

test_start "the branch names the three kinds of file an autonomous run may write"
assert_contains "$(auto_section "$EPICS_SKILL")" "docs/epics/"

test_start "including its own progress file's directory"
assert_contains "$(auto_section "$EPICS_SKILL")" "docs/plans/"

test_start "and states the boundary as a path, not as a concept"
assert_contains "$(auto_section "$EPICS_SKILL")" "It writes nothing under \`docs/specifications/\`"

# The must-NOT. A bare `assert_not_contains "docs/specifications/"` over the branch is
# unsatisfiable on arrival, because the sentence stating the prohibition contains the path
# it prohibits — retro 21 recorded this exact failure for this exact criterion, and spec 45
# phrased the criterion against a path rather than the word "spec" for the same reason. The
# haystack is therefore the branch *minus* its prohibition sentence: what remains is where
# the path would be an instruction rather than a boundary.
branch_minus_prohibition() { auto_section "$1" | grep -v 'It writes nothing under'; }

test_start "must NOT: the branch instructs no write under docs/specifications/"
assert_empty "$(branch_minus_prohibition "$EPICS_SKILL" | grep -oF 'docs/specifications/')"

test_start "control: the same predicate catches a branch that does instruct one"
awk -v line='Write the corrected requirement back to `docs/specifications/` before continuing.' \
  '{print} /^\*\*Write surface/{print ""; print line}' \
  "$EPICS_SKILL" > "$TEST_TMPDIR/writes-spec.md"
if [ -n "$(branch_minus_prohibition "$TEST_TMPDIR/writes-spec.md" | grep -oF 'docs/specifications/')" ]; then
  test_pass
else
  test_fail "the predicate missed an added instruction to write under docs/specifications/"
fi

test_start "a source gap is recorded rather than repaired"
assert_contains "$(auto_section "$EPICS_SKILL")" "recorded, not repaired"

# Termination — Blocker offers "flag the gap for resolution via cpm:pivot **or a spec
# update**". Half of that is the remedy the write surface forbids, and the condition is
# written around a user who is not present. Citing it as precedent without naming the
# divergence is how two sites end up both present and contradicting each other (retro 21).
test_start "and the half of Termination — Blocker it does not inherit is named"
assert_contains "$(auto_section "$EPICS_SKILL")" "the one remedy an autonomous run may not take"

test_start "control: Termination — Blocker really does offer the forbidden alternative"
assert_contains "$(outside_branch "$EPICS_SKILL")" "or a spec update"

# --- The breadcrumb: named field, stated format, and an example that matches it -----------

# The field name is read out of the *format* line, then looked for in the example beneath it.
# A format and an example that disagree is the same two-correct-halves failure as a prompt
# branching on an exit code the script never returns (retro 24).
breadcrumb_format() { auto_section "$1" | grep -F '`**Autonomous gate**: {gate}'; }
breadcrumb_example() { auto_section "$1" | grep -F 'for example `**Autonomous gate**:'; }

test_start "the breadcrumb has a stated format"
if [ -n "$(breadcrumb_format "$EPICS_SKILL")" ]; then
  test_pass
else
  test_fail "no \`**Autonomous gate**: {gate}\` format line in the branch"
fi

test_start "the format names both the gate and the choice"
assert_contains "$(breadcrumb_format "$EPICS_SKILL")" "{gate} · {what was chosen}"

test_start "and an example is given that uses the same field"
if [ -n "$(breadcrumb_example "$EPICS_SKILL")" ]; then
  test_pass
else
  test_fail "no example using the field the format line names"
fi

test_start "the example carries a real gate name and a real choice, not placeholders"
assert_not_contains "$(breadcrumb_example "$EPICS_SKILL")" "{gate}"

test_start "control: renaming the field in the format alone is detected"
sed 's/`\*\*Autonomous gate\*\*: {gate}/`**Autonomous decision**: {gate}/' "$EPICS_SKILL" \
  > "$TEST_TMPDIR/format-renamed.md"
assert_empty "$(breadcrumb_format "$TEST_TMPDIR/format-renamed.md")"

test_start "control: and renaming it in the example alone is detected too"
sed 's/for example `\*\*Autonomous gate\*\*:/for example `**Autonomous decision**:/' "$EPICS_SKILL" \
  > "$TEST_TMPDIR/example-renamed.md"
assert_empty "$(breadcrumb_example "$TEST_TMPDIR/example-renamed.md")"

test_start "the breadcrumb's place in the epic doc is stated"
assert_contains "$(auto_section "$EPICS_SKILL")" 'below `**Blocked by**`'

# NFR4 says auditable *without re-running*. The progress file does not survive the run, so a
# gate firing before any epic doc exists needs somewhere else to land or the audit trail has
# a hole exactly where the first decision was made.
test_start "a gate that fires before any epic doc exists still lands somewhere durable"
assert_contains "$(auto_section "$EPICS_SKILL")" "recorded on every epic that run produced"

test_start "and the reason is stated — the progress file does not outlive the run"
assert_contains "$(auto_section "$EPICS_SKILL")" "progress file is deleted when the run finishes"

# --- Story 4 (FR4, integration): all six sites, counted rather than judged ----------------
#
# Five of the six are Story 1's and the sixth is Story 2's, so "all six" is only true once
# both have landed — which is why this lives here and not in either. Retro 22: a rule
# inventory taken before the first edit turns a must-NOT into arithmetic. The inventory was
# taken before this epic's first edit and recorded 7 `AskUserQuestion` mentions in
# `epics/SKILL.md`, of which 6 are gates and one — the Facilitation depth paragraph — is
# prose *about* the gates. A count over raw mentions would therefore be wrong by exactly one,
# which is the kind of off-by-one a judgement call makes and arithmetic does not.
#
# The two counts below are derived from opposite ends: gate sites from the skill's body,
# dispositions from the branch. Asserting they are equal is what makes the must-NOT
# ("leave no gate site without a disposition") checkable — a seventh gate raises the first
# count and not the second, and fails until someone classifies it.

# Gate sites: every AskUserQuestion mention outside the branch, less the mentions already
# classified as prose. Each exclusion is by its own line, so adding one is a visible edit.
gate_sites() {
  outside_branch "$1" | grep -F 'AskUserQuestion' | grep -v '^\*\*Facilitation depth\*\*'
}

# Dispositions: the five table rows plus the sixth gate's rule, which is not a row because
# its disposition is the opposite one.
disposition_count() {
  local rows sixth
  rows=$(data_rows "$1" | grep -c .)
  sixth=0
  [ -n "$(sixth_gate_rule "$1")" ] && sixth=1
  echo $((rows + sixth))
}

test_start "the skill has six gate sites"
assert_equals "6" "$(gate_sites "$EPICS_SKILL" | grep -c .)"

test_start "the branch states six dispositions — five rows and the sixth gate's rule"
assert_equals "6" "$(disposition_count "$EPICS_SKILL")"

test_start "must NOT: no gate site is left without a disposition — the counts agree"
assert_equals "$(gate_sites "$EPICS_SKILL" | grep -c .)" "$(disposition_count "$EPICS_SKILL")"

test_start "control: a seventh gate raises the site count and not the disposition count"
awk '{print} /^### Step 4: Confirm/{print ""; print "Then use AskUserQuestion to confirm the coverage matrix."}' \
  "$EPICS_SKILL" > "$TEST_TMPDIR/seventh-gate.md"
if [ "$(gate_sites "$TEST_TMPDIR/seventh-gate.md" | grep -c .)" = "$(disposition_count "$TEST_TMPDIR/seventh-gate.md")" ]; then
  test_fail "the counts agreed after a seventh gate was added with no disposition"
else
  test_pass
fi

test_start "control: removing a disposition row breaks the agreement from the other side"
if [ "$(gate_sites "$TEST_TMPDIR/gate-removed.md" | grep -c .)" = "$(disposition_count "$TEST_TMPDIR/gate-removed.md")" ]; then
  test_fail "the counts agreed after a disposition row was removed"
else
  test_pass
fi

# The count alone would be satisfied by six dispositions for the wrong six gates. Each of the
# five table gates is already matched to its site by name above (check_gate); this pairs the
# sixth, which is the one the count would otherwise let float.
test_start "the sixth gate's site is matched to the sixth gate's rule by name"
assert_contains "$(gate_sites "$EPICS_SKILL")" "Present them via AskUserQuestion"

test_start "and the excluded mention really is prose about the gates, not a gate"
assert_contains "$(outside_branch "$EPICS_SKILL" | grep '^\*\*Facilitation depth\*\*')" \
  "converges in 1-2 rounds of AskUserQuestion"

test_summary
