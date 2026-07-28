#!/bin/bash
# test-ralph-test-runner-source.sh — spec mode reads the spec before the config files.
#
# --- The failure this covers --------------------------------------------------------
#
# Pre-flight step 1d discovered the test runner by checking `composer.json`,
# `package.json`, `Makefile`, `pyproject.toml` and `Cargo.toml`. In a greenfield spec-mode
# run none of those exist — the application is what the run is about to build — so the
# check could not succeed in the case spec mode exists for. It reported "no test runner
# discovered" and assembled a prompt telling `/cpm:do` to find one at runtime, while the
# answer sat in the spec the same pre-flight had already resolved as `{spec_path}`.
#
# The spec is not merely a second source. `cpm:spec` Step 3a is the *only* place a spec
# captures test tooling, and it records it as labelled `ENVn` entries so the roll-up traces
# them. A field-test spec named Pest, a browser driver, an isolated test database and a Node
# toolchain in that block; `cpm:epics` read them correctly and ralph reported nothing found.
#
# --- Which assertions are oracles ---------------------------------------------------
#
# **The label-family correspondence is.** The label ralph tells a reader to look for is
# extracted from its own prose and handed to `coverage_environmental_class`, the single
# definition of what an environmental label is. Renaming the family in both places stays
# green; naming a family the parser does not recognise fails, which is what an instruction
# pointing at a block nothing writes would look like.
#
# **The ordering assertion is structural.** Step 1d is a numbered list, and which item
# number carries which source is the whole finding — a step that names the spec somewhere
# and still checks config files first has not been fixed.
#
# **The rest is a regression net.** Whether the wording is clear is not checkable here.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/../lib/coverage-parse.sh"

RALPH_SKILL="$SCRIPT_DIR/../../skills/ralph/SKILL.md"

echo "Testing that ralph's test-runner discovery reads the spec first in spec mode"

step_1d() {
  sed -n '/^#### 1d\. Test Runner Discovery$/,/^#### 1e\./p' "$RALPH_SKILL"
}

# The numbered list only, so "which source comes first" is read off the list rather than off
# the prose around it — a rationale paragraph mentioning config files earlier in the file
# would otherwise decide the ordering assertion.
numbered_steps() {
  step_1d | grep -E '^[0-9]+\. '
}

# The item number of the first step mentioning a given thing.
step_number_matching() {
  numbered_steps | grep -n -- "$1" | head -1 | cut -d: -f1
}

test_start "control: the Step 1d slice is bounded, not the whole file"
assert_slice_bounded "$RALPH_SKILL" '^#### 1d\. Test Runner Discovery$' '^#### 1e\.' 5 20

test_start "control: Step 1d is a numbered list with several items"
assert_equals "yes" "$( [ "$(numbered_steps | grep -c .)" -ge 3 ] && echo yes || echo no )"

# --- The ordering: the spec before the config files -------------------------------------

SPEC_STEP=$(step_number_matching 'spec')
CONFIG_STEP=$(step_number_matching 'composer.json')

test_start "control: both sources are named in the numbered list"
assert_equals "both" \
  "$( [ -n "$SPEC_STEP" ] && [ -n "$CONFIG_STEP" ] && echo both || echo "spec=$SPEC_STEP config=$CONFIG_STEP" )"

test_start "the spec is consulted before the project config files"
if [ "$SPEC_STEP" -lt "$CONFIG_STEP" ]; then
  test_pass
else
  test_fail "config files are step $CONFIG_STEP and the spec is step $SPEC_STEP, which is the original ordering"
fi

# The must-NOT that keeps the change scoped. Epic mode runs against a project that already
# exists, where a config file is the better evidence, so the config-file step has to survive
# rather than being replaced.
test_start "control: the config-file step still lists the manifests it always checked"
CONFIG_LINE=$(numbered_steps | grep -- 'composer.json')
MISSING_MANIFESTS=""
for manifest in 'package.json' 'Makefile' 'pyproject.toml' 'Cargo.toml'; do
  case "$CONFIG_LINE" in
    *"$manifest"*) : ;;
    *) MISSING_MANIFESTS="$MISSING_MANIFESTS $manifest" ;;
  esac
done
if [ -n "$MISSING_MANIFESTS" ]; then
  test_fail "the config-file step no longer mentions:$MISSING_MANIFESTS"
else
  test_pass
fi

test_start "the spec step is scoped to spec mode rather than applying to every run"
assert_contains "$(numbered_steps | head -1)" "spec mode"

# --- The oracle: the label family ralph names is one the parser recognises ---------------
#
# `coverage_environmental_class` is the single definition of the environmental label grammar
# (spec 46, AD2). An instruction to read `ENVn` entries is worth nothing if the labels a spec
# actually writes are called something else, and this is the only artefact in a position to
# say which is which.

# Every family token the step names, not the first one. The pattern is the *shape* of a
# family — capitals followed by the placeholder `n` — rather than the string `ENV`: an
# extractor spelling the family it is checking cannot fail when the step names a different
# one, and taking only the first hides the case where two mentions disagree. Both of those
# were true of the first version of this check, and it passed a mutation that renamed the
# family in one of its two mentions.
LABEL_FAMILIES=$(step_1d | grep -o '`[A-Z][A-Z]*n`' | tr -d '`' | LC_ALL=C sort -u)

test_start "control: a label family was named in Step 1d"
assert_equals "non-empty" "$( [ -n "$LABEL_FAMILIES" ] && echo non-empty || echo empty )"

test_start "every label family Step 1d names is one coverage-parse classifies as environmental"
UNKNOWN_FAMILIES=""
for family in $LABEL_FAMILIES; do
  [ -n "$(coverage_environmental_class "${family%n}1")" ] \
    || UNKNOWN_FAMILIES="$UNKNOWN_FAMILIES $family"
done
assert_empty "$UNKNOWN_FAMILIES"

test_start "control: the classifier refuses a family it does not know, so it is not accepting anything"
assert_equals "" "$(coverage_environmental_class "TOOLING1")"

# --- Regression net over the rationale --------------------------------------------------

test_start "Step 1d says why the config files cannot answer in a greenfield run"
assert_contains "$(step_1d)" "about to build"

test_start "and names the spec block as the single capture site rather than a second opinion"
assert_contains "$(step_1d)" "single site"

test_summary
