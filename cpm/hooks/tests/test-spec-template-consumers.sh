#!/bin/bash
# test-spec-template-consumers.sh — `cpm:spec`'s output template may not claim a downstream
# consumer it does not have.
#
# The defect this generalises from: `### Test Infrastructure` told the reader "Items listed
# here become stories in `cpm:epics`", and `cpm:epics` had no step that read it. Nothing was
# wrong with the sentence except that it was false, and it stayed false through several specs
# because a promise is not a behaviour and no suite was looking at it. Worse, the section sat
# under `## Testing Strategy` as a `###`, and `coverage-parse.sh` reads requirements only from
# `## Functional Requirements` and `## Non-Functional Requirements` — so a tooling need
# recorded there could not reach the coverage matrix either. A spec could name Pest and
# Playwright and roll up fully verified with neither installed.
#
# --- What has an oracle here -----------------------------------------------------------
#
# The strong assertion is criterion 2, and it is the one that generalises: for every template
# section that *claims to be consumed* by a named skill, that skill must actually read the
# section. Both sides are derived — the claims from the template, the readership from the
# skill files — so a section renamed consistently in both places stays green, and a new
# unbacked promise fires the first time it is written.
#
# Detecting a claim is the part that needs care, because "names a skill" and "claims to be
# read by one" are different sentences and the template contains one of each:
#
#   ### Test Infrastructure  "Items listed here become stories in `cpm:epics`."   <- a claim
#   ### Unit Testing         "handled at the `cpm:do` task level"                 <- not one
#
# The second says where the *work* happens. It makes no assertion about this section being an
# input to anything, and a test that flagged it would be demanding a consumer for a sentence
# that never promised one. The discriminator used below is deliberately narrow and stated
# rather than inferred: a claim needs both a skill reference *and* a deictic pointing at the
# section's own contents (`here`, `these`, `this section`, `listed`). It is a heuristic, and
# assertion 3 is what keeps it honest — it runs the detector over a fixture of each shape and
# fails if the detector cannot tell them apart.
#
# --- What this suite does not test ------------------------------------------------------
#
# That Step 6d's reconciliation is actually performed — whether an agent, having tagged a
# criterion `[feature]`, notices that no `ENVn` covers the browser runner. That is a model
# behaviour, not a file state. What is checkable, and checked, is that the step routes to
# Step 3a rather than recording locally, and that no second capture site exists for it to
# record into.
#
# One assertion per test_start (retro 15), so the ratio stays honest.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

SPEC_SKILL="$SCRIPT_DIR/../../skills/spec/SKILL.md"
SKILLS_DIR="$SCRIPT_DIR/../../skills"

echo "Testing: cpm:spec's template claims no consumer it does not have"
echo "================================================================"

# The output template: the fenced block opening `# Spec: {Title}`. Extracted rather than
# re-typed — the whole point is to read what the skill actually ships.
template() {
  awk '/^# Spec: \{Title\}$/{f=1} f&&/^```$/{exit} f' "$1"
}

TEMPLATE=$(template "$SPEC_SKILL")

test_start "control: the output template is extractable"
if [ -n "$TEMPLATE" ]; then
  test_pass
else
  test_fail "no '# Spec: {Title}' template block found in $SPEC_SKILL"
fi

test_start "control: the template slice is bounded"
# Brace unescaped: `assert_slice_bounded` goes through `sed`, where BSD reads `\{` as the
# start of a repetition count and errors out. The awk extraction above escapes it because awk
# reads it as an ERE interval. Same literal, two dialects.
assert_slice_bounded "$SPEC_SKILL" '^# Spec: {Title}$' '^```$' 30 90

# --- Criterion 1: the defect itself is gone ---------------------------------------------

test_start "the template carries no Test Infrastructure section"
assert_empty "$(printf '%s\n' "$TEMPLATE" | grep -c '^### Test Infrastructure$' | grep -v '^0$')"

test_start "control: the sections either side of it are still present"
# Guards the assertion above. A mangled extraction returns nothing and would satisfy it.
assert_equals "2" "$(printf '%s\n' "$TEMPLATE" | grep -cE '^### (Integration Boundaries|Unit Testing)$')"

test_start "and the skill has no Test Infrastructure step either"
assert_empty "$(grep -n 'Test Infrastructure' "$SPEC_SKILL")"

# --- Criterion 2: the correspondence — claimed consumers are real consumers --------------
#
# claimed_consumers <template-text> — one `heading<TAB>skill` record per consumption claim.
#
# A claim is a `###` section whose body names a `cpm:{skill}` *and* points at its own contents
# with a deictic. Both conditions, because either alone misfires: the deictic alone catches
# ordinary prose, and the skill reference alone catches `### Unit Testing`.
claimed_consumers() {
  awk '
    # The section is judged once, whole, at its closing boundary. Deciding mid-accumulation
    # would let the first line that happened to satisfy both conditions end the section early
    # and hide any skill named after it.
    function flush(   rest, skill) {
      if (heading == "") return
      # Case-insensitive, and bounded by non-letters: an unbounded "here" also matches
      # "there" and "where", which is most of English prose.
      if (tolower(body) ~ /(^|[^a-z])(here|these|this section|listed)([^a-z]|$)/) {
        rest = body
        # Every skill the section names, not just the first — a claim pointing at two
        # consumers has to be honoured by both.
        while (match(rest, /cpm:[a-z]+/)) {
          skill = substr(rest, RSTART + 4, RLENGTH - 4)
          print heading "\t" skill
          rest = substr(rest, RSTART + RLENGTH)
        }
      }
      heading = ""; body = ""
    }
    /^### /       { flush(); heading = substr($0, 5); next }
    /^## /        { flush(); next }
    heading != "" { body = body " " $0 }
    END           { flush() }
  '
}

# reading_skills — the headings any *other* skill actually greps for, as `heading<TAB>skill`.
# Derived by asking each skill file whether it names the heading, so a consistent rename on
# both sides stays green.
readership() {
  local heading skill
  while IFS=$'\t' read -r heading skill; do
    [ -n "$heading" ] || continue
    if grep -qF -- "$heading" "$SKILLS_DIR/$skill/SKILL.md" 2>/dev/null; then
      printf '%s\t%s\n' "$heading" "$skill"
    fi
  done
}

CLAIMED=$(printf '%s\n' "$TEMPLATE" | claimed_consumers | LC_ALL=C sort -u)
HONOURED=$(printf '%s\n' "$CLAIMED" | readership | LC_ALL=C sort -u)

test_start "every consumption claim in the template is honoured by the skill it names"
if [ "$CLAIMED" = "$HONOURED" ]; then
  test_pass
else
  test_fail "claimed but not read: $(comm -23 <(printf '%s\n' "$CLAIMED") <(printf '%s\n' "$HONOURED") | tr '\n' ' ')"
fi

# --- Criterion 3: the claim detector can tell the two sentence shapes apart --------------
#
# Without this, criterion 2 passes on an empty CLAIMED set — which is exactly what it returns
# today, because the defect it was written for has been fixed. An oracle that cannot fail is
# not an oracle, so the detector is exercised against fixtures of each shape.

FIXTURE_CLAIM='### Test Infrastructure
{Testing infrastructure the project needs. Items listed here become stories in `cpm:epics`.}'

FIXTURE_NOT_CLAIM='### Unit Testing
Unit testing of individual components is handled at the `cpm:do` task level — each story'"'"'s acceptance criteria drive test coverage during implementation.'

test_start "the detector sees a section that claims to be consumed"
assert_contains "$(printf '%s\n' "$FIXTURE_CLAIM" | claimed_consumers)" "Test Infrastructure"

test_start "and names the skill that claim points at"
assert_contains "$(printf '%s\n' "$FIXTURE_CLAIM" | claimed_consumers)" "epics"

test_start "the detector sees a claim whose deictic opens the sentence"
# A live bug in this suite's first version: the deictic test was case-sensitive, so a body
# reading "These rows are read by `cpm:epics`" was not detected as a claim at all — and the
# correspondence assertion then passed it, on nothing. An undetected claim is the one failure
# mode that looks identical to an honoured one.
assert_contains "$(printf '### Coverage Notes\n{These rows become stories in `cpm:epics`.}\n' \
  | claimed_consumers)" "Coverage Notes"

test_start "the detector does not fire on a section that merely names a skill"
assert_empty "$(printf '%s\n' "$FIXTURE_NOT_CLAIM" | claimed_consumers)"

test_start "control: an unbounded deictic would have fired here, and does not"
# "there"/"where" contain "here". Without the non-letter bounds the detector would call this
# prose a claim, and every ordinary sentence mentioning a skill would demand a consumer.
assert_empty "$(printf '### Somewhere Else\n{Where this applies is decided by `cpm:do` at run time.}\n' \
  | claimed_consumers)"

test_start "control: that fixture does name a skill, so the non-fire is the deictic's doing"
assert_contains "$FIXTURE_NOT_CLAIM" 'cpm:do'

test_start "the real template still contains the shape the detector spares"
# Ties the fixture above to the shipped file: if `### Unit Testing` is ever reworded into a
# consumption claim, criterion 2 starts judging it and this records that the spare was real.
assert_contains "$TEMPLATE" 'handled at the `cpm:do` task level'

# --- Criterion 4: test tooling is captured once, in the place that traces it -------------

step_3a() {
  awk '/^#### Step 3a: Environmental Constraints$/{f=1;next} f&&/^### Section 4:/{exit} f' "$SPEC_SKILL"
}

step_6d() {
  awk '/^#### Step 6d:/{f=1;next} f&&/^#### Step 6e:/{exit} f' "$SPEC_SKILL"
}

STEP_3A=$(step_3a)
STEP_6D=$(step_6d)

test_start "control: the Step 3a slice is bounded"
assert_slice_bounded "$SPEC_SKILL" '^#### Step 3a: Environmental Constraints$' '^### Section 4:' 15 60

test_start "control: the Step 6d slice is bounded"
assert_slice_bounded "$SPEC_SKILL" '^#### Step 6d:' '^#### Step 6e:' 4 16

test_start "Step 3a's development row names a test runner"
assert_contains "$STEP_3A" "test runner"

test_start "Step 3a's development row names browser automation"
assert_contains "$STEP_3A" "browser automation"

test_start "Step 3a absorbs the fixtures the retired step listed"
assert_contains "$STEP_3A" "test database or fixtures"

test_start "Step 3a absorbs the CI configuration the retired step listed"
assert_contains "$STEP_3A" "CI that runs the suite"

test_start "Step 3a absorbs the mock/stub libraries the retired step listed"
assert_contains "$STEP_3A" "mock/stub libraries"

test_start "Step 3a states it is the only capture site for test tooling"
assert_contains "$STEP_3A" "only place test tooling is captured"

# --- Criterion 5: Step 6d routes back rather than recording ------------------------------

test_start "Step 6d sends missing tooling back to Step 3a"
assert_contains "$STEP_6D" "go back to Step 3a and add it there"

test_start "Step 6d asks for the label that reaches the coverage matrix"
assert_contains "$STEP_6D" '`ENVn`'

test_start "Step 6d asks for the tag that stops a sandbox self-pass"
assert_contains "$STEP_6D" '`[target]`'

test_start "must NOT: Step 6d records nothing of its own"
assert_contains "$STEP_6D" "Record nothing here"

test_start "must NOT: Step 6d creates no section in the spec"
# Retro 23's trap: the sentence forbidding an output has to name one, so this cannot assert on
# the token. It asserts the step defines no template section — the file fact that would follow
# if it did.
assert_empty "$(printf '%s\n' "$STEP_6D" | grep -E '^#{2,3} ')"

test_summary
