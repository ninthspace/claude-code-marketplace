#!/bin/bash
# test-spec-requirement-labels.sh — cpm:spec's output template must produce functional
# requirements the coverage roll-up can see.
#
# --- What went wrong ------------------------------------------------------------------
#
# The template's `## Functional Requirements` section wrote its bullets as `- {requirement}`
# with no label, while `## Non-Functional Requirements` — rewritten for spec 46 — wrote
# `- **NFR1 — {Title}.**` and explained why the label mattered. `coverage-parse.sh` traces a
# requirement only when the bullet opens with one: `cov_leading_label` matches `^[A-Z]+[0-9]+`
# and returns empty otherwise, which is how a bold prose bullet is told apart from a
# requirement without keeping a list of known prefixes in step.
#
# A spec written to that template therefore had *no traceable functional requirements at all*.
# Run end to end it produced `SUMMARY spec 3 0 3 0` and exit 0 — three NFR/ENV requirements,
# zero untraced — with both functional requirements absent from the record set. Not untraced:
# absent. That is the one failure mode nothing downstream can report, because a requirement
# no record mentions cannot be counted as missing, and under `cpm:ralph` spec mode the phase
# predicate reads exactly that count and stops.
#
# Every spec in `docs/specifications/` parses, because every one was labelled by hand — 40-42
# as `Rn`, 43-46 as `FRn`, both accepted since the parser is prefix-agnostic. The convention
# was real and the instruction was missing, which is why nothing caught it.
#
# --- What has an oracle here ----------------------------------------------------------
#
# The parser is a real executable and the template is a real document, so the assertion is a
# correspondence between them rather than a pin on wording: each requirement bullet in the
# template is passed through `cov_leading_label` — the function the roll-up itself calls — and
# asserted to yield a label. Rename the labels on both sides and this stays green; drop one
# and it fires. No sentence is quoted.
#
# The Won't Have bullet is asserted to yield *no* label, which is what keeps the check from
# degenerating into "every bullet parses". Won't Have entries are items ruled out rather than
# requirements to satisfy, and `coverage-fixture-helpers.sh` builds its fixtures that way
# deliberately: an unlabelled Won't Have bullet is prose the parser should skip.
#
# --- What this suite does not test ----------------------------------------------------
#
# That any spec on disk is labelled. Those are already-written documents, and this is about
# the instruction that produces the next one.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/../lib/coverage-parse.sh"

SPEC_SKILL="$SCRIPT_DIR/../../skills/spec/SKILL.md"

echo "Testing: cpm:spec's requirement labels reach the coverage parser"
echo "==============================================================="

spec_template() {
  skill_template "$SPEC_SKILL" '^# Spec: {Title}$'
}

# The bullets under one `###` MoSCoW heading inside the template's functional section.
moscow_bullets() {
  spec_template | awk -v want="$1" '
    /^## / { in_fr = ($0 == "## Functional Requirements"); heading = ""; next }
    !in_fr { next }
    /^### / { heading = substr($0, 5); next }
    heading == want && /^- / { print substr($0, 3) }'
}

# The label the parser reads off a bullet, obtained by putting that bullet in a spec and
# asking the roll-up's own public entry point what it found.
#
# The first version of this called `cov_leading_label` directly by prepending
# `_COVERAGE_AWK_LIB` to an awk program. That reaches into a name the library marks private,
# and it failed silently in the direction that matters: when awk could not resolve the
# function it wrote nothing to stdout, so every *negative* assertion passed on the crash. A
# helper whose failure mode is an empty string cannot be used to assert an empty string.
label_of() {
  local spec
  spec=$(mktemp -t spec-label-XXXXXX)
  {
    printf '# Spec: One\n\n## Functional Requirements\n\n### Must Have\n'
    printf -- '- %s\n' "$1"
  } > "$spec"
  coverage_spec_requirements "$spec" | cut -f1
  rm -f "$spec"
}

# --- Non-vacuity ----------------------------------------------------------------------

test_start "control: the spec output template slice is bounded"
assert_slice_bounded "$SPEC_SKILL" '^# Spec: {Title}$' '^```$' 30 90

test_start "control: the template has a Must Have bullet to read"
assert_equals "1" "$(moscow_bullets 'Must Have' | grep -c .)"

# --- The three satisfiable headings carry labels ---------------------------------------

for heading in 'Must Have' 'Should Have' 'Could Have'; do
  BULLET=$(moscow_bullets "$heading" | head -1)

  test_start "control: the template shows a bullet under $heading"
  assert_contains "$BULLET" "{requirement}"

  test_start "the $heading bullet opens with a label the parser reads"
  LABEL=$(label_of "$BULLET")
  if [ -n "$LABEL" ]; then
    test_pass
  else
    test_fail "'$BULLET' yields no label, so a spec written to it traces nothing"
  fi
done

# The numbering runs once across the three headings rather than restarting under each — three
# bullets, three distinct labels. A template restarting at FR1 under every heading would give
# two requirements the same identifier and the matrix could not tell them apart.
test_start "the three labels are distinct, so the numbering runs across the headings"
ALL_LABELS=$(for h in 'Must Have' 'Should Have' 'Could Have'; do
  label_of "$(moscow_bullets "$h" | head -1)"
done | grep . | LC_ALL=C sort -u | grep -c .)
assert_equals "3" "$ALL_LABELS"

# --- The ruled-out heading deliberately does not ----------------------------------------

test_start "control: the template shows a bullet under Won't Have"
WONT=$(moscow_bullets "Won't Have (this iteration)" | head -1)
assert_contains "$WONT" "{item}"

test_start "the Won't Have bullet carries no label, so the parser reads it as prose"
assert_empty "$(label_of "$WONT")"

# --- The facilitation half says the same thing as the template half ---------------------
#
# Section 2 is where requirements are agreed. A template that shows labels and a facilitation
# step that never mentions them drift the moment someone writes the list before the document.

section_2() {
  sed -n '/^### Section 2: Functional Requirements$/,/^### Section 3:/p' "$SPEC_SKILL"
}

test_start "control: the Section 2 slice is bounded"
assert_slice_bounded "$SPEC_SKILL" '^### Section 2: Functional Requirements$' '^### Section 3:' 5 40

test_start "Section 2 asks for the label during facilitation, not at write-up"
assert_contains "$(section_2)" '`FRn`'

# --- End to end: a spec written to the template is traced --------------------------------
#
# The template with its placeholders filled in, through the real parser. This is the
# assertion that would have caught the original defect, and the one that stays true only
# while the template and the parser agree.

FIXTURE=$(mktemp -t spec-labels-XXXXXX)
trap 'rm -f "$FIXTURE"' EXIT

{
  printf '# Spec: Thing\n\n## Functional Requirements\n\n'
  for heading in 'Must Have' 'Should Have' 'Could Have'; do
    printf '### %s\n' "$heading"
    printf -- '- %s\n\n' "$(moscow_bullets "$heading" | head -1 \
      | sed -e 's/{Title}/A title/' -e 's/{requirement}/the requirement text/')"
  done
  printf "### Won't Have (this iteration)\n"
  printf -- '- %s\n' "$(printf '%s' "$WONT" | sed 's/{item}/a ruled-out item/')"
} > "$FIXTURE"

REQS=$(coverage_spec_requirements "$FIXTURE")

test_start "a spec written to the template yields one record per satisfiable requirement"
assert_equals "3" "$(printf '%s\n' "$REQS" | grep -c .)"

test_start "and each record carries the MoSCoW heading its bullet sat under"
HEADINGS=$(printf '%s\n' "$REQS" | cut -f2 | tr '\n' '|')
assert_equals "Must Have|Should Have|Could Have|" "$HEADINGS"

test_start "and the ruled-out item produces no record at all"
assert_empty "$(printf '%s\n' "$REQS" | grep 'ruled-out item')"

# The control that makes the three assertions above mean something: strip the labels, which
# is the shape the template had, and the same fixture traces nothing.
UNLABELLED=$(printf '%s\n' "$REQS" >/dev/null; sed -E 's/^- \*\*[A-Z]+[0-9]+ — [^*]*\*\* /- /' "$FIXTURE")
printf '%s\n' "$UNLABELLED" > "$FIXTURE"

test_start "control: the same fixture with the labels stripped traces nothing"
assert_empty "$(coverage_spec_requirements "$FIXTURE")"

# --- Every class the roll-up counts must be a class Section 6b gives criteria to ----------
#
# The same shape as the failure this suite was written for, one column over. There the parser
# counted a class the template did not label; here it counts a class Section 6b did not
# require a criterion for. `coverage_spec_requirements` emits `NFRn` records alongside `FRn`,
# so a spec-mode loop has to trace every NFR to a matrix row before it can leave phase 1 —
# while Step 6b asked for tags on must-have *functional* requirements only. An NFR with no
# acceptance criterion was therefore admissible to `cpm:spec` and blocking to `cpm:ralph`.
#
# Observed: an NFR reading "git and a POSIX shell, nothing else" reached the epics with no
# criterion, `cpm:epics` closed the gap with a row carrying an empty test approach, and the
# phase-1 predicate was satisfied by a row nothing could verify against.
#
# The oracle is the parser, not the prose: assert it really does count the class, then assert
# the instruction covers it. Either half alone passes on a version where the two disagree.
NFR_FIXTURE=$(mktemp -t spec-nfr-XXXXXX)
{
  printf '# Spec: NFR reach\n\n## Functional Requirements\n\n### Must Have\n\n'
  printf -- '- **FR1 — A thing.** It does the thing.\n\n'
  printf '## Non-Functional Requirements\n\n'
  printf -- '- **NFR1 — No dependencies.** Nothing beyond a POSIX shell.\n'
} > "$NFR_FIXTURE"

test_start "control: the roll-up counts a non-functional requirement as a requirement"
assert_equals "NFR1" "$(coverage_spec_requirements "$NFR_FIXTURE" | awk -F'\t' '$1 ~ /^NFR/ { print $1 }')"

SPEC_TEXT=$(cat "$SPEC_SKILL")
TAG_STEP=$(sed -n '/^#### Step 6b:/,/^#### /p' "$SPEC_SKILL")

test_start "and Step 6b asks for a criterion on that class, not only on functional ones"
assert_contains "$TAG_STEP" "non-functional requirement"

# The named trap. A requirement phrased as an absence is the one with no artefact to point a
# criterion at, and it is the shape that reaches the epics untagged — so the guidance has to
# say what to do rather than only that the class is included.
test_start "and it says how to give an absence an observable"
assert_contains "$TAG_STEP" "the absence itself is not"

test_start "the output template's coverage note names the class too"
assert_contains "$SPEC_TEXT" "each non-functional requirement has at least one testable criterion"

test_summary
