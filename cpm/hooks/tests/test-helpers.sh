#!/bin/bash
# test-helpers.sh — Minimal bash test framework for CPM hook scripts

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST=""

test_start() {
  CURRENT_TEST="$1"
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "  PASS: $CURRENT_TEST"
}

test_fail() {
  TESTS_FAILED=$((TESTS_FAILED + 1))
  echo "  FAIL: $CURRENT_TEST"
  if [ -n "$1" ]; then
    echo "        $1"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if echo "$haystack" | grep -qF -- "$needle"; then
    test_pass
  else
    test_fail "Expected output to contain: '$needle'"
    echo "        Got: $(echo "$haystack" | head -5)"
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  if echo "$haystack" | grep -qF -- "$needle"; then
    test_fail "Expected output NOT to contain: '$needle'"
  else
    test_pass
  fi
}

assert_empty() {
  local value="$1"
  if [ -z "$value" ]; then
    test_pass
  else
    test_fail "Expected empty output, got: $(echo "$value" | head -3)"
  fi
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  if [ "$expected" = "$actual" ]; then
    test_pass
  else
    test_fail "Expected: '$expected', got: '$actual'"
  fi
}

# assert_agrees <what> <a-name> <a-value> <b-name> <b-value>
#
# A correspondence assertion: two values derived independently from the documents that own
# them, compared to each other rather than to a literal. Emits three assertions in the order
# that makes them mean anything — each side non-empty, then the two compared.
#
# The ordering is the contract, and it is the reason this is a function. Retro 30 records what
# happens without it: an extraction stops matching, both sides come back empty, empty equals
# empty, and the suite reports green while checking nothing. Worse, the comparison there had
# been written as a count of distinct values (`sort -u | grep -c .`, expect 1), which skips the
# empty line, so even a *one-sided* empty still counted 1 and passed. Both failure modes are
# invisible in a green run and neither is obvious when writing the next one.
#
# The non-empty guard is deliberately non-empty and nothing more. Reaching for the stronger
# `assert_contains "$a_value" "<some known member>"` pins a value on each side and fails on a
# consistent rename of both — exactly the change a correspondence assertion exists to permit.
# What the values should contain is a separate question, asked separately by an inventory
# assertion where the criterion asks it.
#
# Usage: assert_agrees "the blocking classes" \
#          "epics/SKILL.md" "$EPICS_BLOCKING" "coverage-rollup.sh" "$ROLLUP_BLOCKING"
assert_agrees() {
  local what="$1" a_name="$2" a_value="$3" b_name="$4" b_value="$5"

  test_start "control: $what could be read from $a_name"
  assert_equals "non-empty" "$( [ -n "$a_value" ] && echo non-empty || echo empty )"

  test_start "control: $what could be read from $b_name"
  assert_equals "non-empty" "$( [ -n "$b_value" ] && echo non-empty || echo empty )"

  test_start "$what agree between $a_name and $b_name"
  assert_equals "$a_value" "$b_value"
}

# assert_slice_bounded <file> <start-regex> <end-regex> <min> <max>
#
# A `sed` range is asymmetric, and only one direction fails loudly: a range matching
# nothing makes every assert_contains over it fail, while a range matching a *wider*
# region than intended passes on text belonging to another section. Bounding both ends
# is the only form that catches the second, and the failure message names the count so
# a renamed heading reads as a widened slice rather than as a content regression.
#
# Retro 24 recommendation 4 — this belongs anywhere a sed/awk range feeds assert_contains.
assert_slice_bounded() {
  local file="$1" start="$2" end="$3" min="$4" max="$5" lines
  lines=$(sed -n "/$start/,/$end/p" "$file" | grep -c .)
  if [ "$lines" -ge "$min" ] && [ "$lines" -le "$max" ]; then
    test_pass
  else
    test_fail "slice /$start/,/$end/ is $lines non-blank lines (expected $min-$max)"
  fi
}

# skill_template <skill-file> <first-line-regex>
#
# The fenced output template a SKILL.md documents, sliced from the template's own first line
# rather than from its ```markdown fence.
#
# The fence is the obvious anchor and the wrong one. A SKILL.md typically holds two fenced
# markdown blocks — the output template, and the progress-file format under State Management
# — and a sed range *restarts*, so `/^```markdown$/,/^```$/` yields both concatenated rather
# than the first. Measured on `spec/SKILL.md` and `brief/SKILL.md`: 8 `## ` headings against
# the 6 the template actually has, the extras being `## Completed Sections` and
# `## Next Action` from the progress format. Nothing announces the difference — an inventory
# assertion written against the wider slice simply lists eight sections and passes, and
# assert_slice_bounded confirms a slice of a plausible size either way.
#
# That is the contract held here, and the reason this is a function rather than a sed range
# open-coded at each site — the third caller is the one that would lose it without noticing.
#
# Usage: skill_template "$SKILLS_DIR/spec/SKILL.md"  '^# Spec: {Title}$'
#        skill_template "$SKILLS_DIR/brief/SKILL.md" '^# Product Brief: {Title}$'
skill_template() {
  local fence='^```$'
  sed -n "/$2/,/$fence/p" "$1"
}

# Run a command with the named environment variables removed from its
# environment — removed, not set to empty. The distinction matters: the shared
# conventions' guard invocation reaches the helpers with CLAUDE_PROJECT_DIR
# genuinely unset, and `${VAR-default}` resolves differently for unset than for
# empty. Setting the variable to "" would test a case that never occurs.
#
# `env -u` is available on both BSD (macOS) and GNU coreutils.
# The command runs in a child process, so the caller's own environment is
# untouched by construction rather than by convention.
#
# Usage: run_without_env VAR [VAR...] -- command [args...]
run_without_env() {
  local env_args=()
  while [ $# -gt 0 ] && [ "$1" != "--" ]; do
    env_args+=(-u "$1")
    shift
  done
  [ "${1-}" = "--" ] && shift
  env ${env_args[@]+"${env_args[@]}"} "$@"
}

# The two counters measure different things and must not be printed as a fraction.
# TESTS_RUN counts test_start — test cases. TESTS_PASSED counts test_pass, which every
# assert_* helper calls — assertions. A test case holding three assertions contributes 1
# and 3, so `21/19` was a routine result and not the impossibility it read as. Name the
# units instead: an `X/Y` with X > Y invites exactly one reading, and it is the wrong one.
test_summary() {
  echo ""
  echo "Results: $TESTS_PASSED assertions passed in $TESTS_RUN tests, $TESTS_FAILED failed"
  if [ "$TESTS_FAILED" -gt 0 ]; then
    exit 1
  fi
}

# Create a temp directory for test fixtures; cleaned up on exit
TEST_TMPDIR=$(mktemp -d)
trap 'rm -rf "$TEST_TMPDIR"' EXIT
