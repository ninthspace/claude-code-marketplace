#!/bin/bash
# test-unset-env-fixture.sh — Tests for run_without_env in test-helpers.sh
#
# The fixture exists so suites can exercise the helpers the way a /cpm:* skill
# actually invokes them: with CLAUDE_PROJECT_DIR genuinely absent from the
# environment. Setting it to "" would test a case that never occurs, so the
# unset-vs-empty distinction below is the point of the fixture, not a detail.
#
# Tests cover:
# - A named variable is unset (not empty) inside the command
# - Unset and empty are distinguishable, and the fixture produces unset
# - Variables that were not named are left alone
# - Several named variables are all removed
# - The caller's own environment survives the call unaltered
# - The command's exit code and trailing arguments pass through

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "Testing: run_without_env (test-helpers.sh)"
echo "=========================================="

# A probe that reports whether the variable is SET, whatever its value.
# `${VAR+set}` expands to "set" for an empty-but-set variable and to nothing
# when the variable is absent — which is the only expansion that tells the two
# apart. `${VAR:-}` and friends cannot.
PROBE='printf "%s" "${FIXTURE_PROBE+set}"'

# --- The variable is removed, not emptied ---

test_start "A named variable is absent inside the command"
export FIXTURE_PROBE="a value"
OUT=$(run_without_env FIXTURE_PROBE -- bash -c "$PROBE")
assert_equals "" "$OUT"

test_start "An empty-but-set variable reports as set (the case the fixture must not produce)"
export FIXTURE_PROBE=""
OUT=$(bash -c "$PROBE")
assert_equals "set" "$OUT"

test_start "The fixture produces unset, not empty, for that same variable"
export FIXTURE_PROBE=""
OUT=$(run_without_env FIXTURE_PROBE -- bash -c "$PROBE")
assert_equals "" "$OUT"

# --- Scope: only what was named ---

test_start "A variable that was not named is left set inside the command"
export FIXTURE_PROBE="a value"
export FIXTURE_OTHER="another value"
OUT=$(run_without_env FIXTURE_PROBE -- bash -c 'printf "%s" "${FIXTURE_OTHER-missing}"')
assert_equals "another value" "$OUT"

test_start "Several named variables are all removed"
export FIXTURE_PROBE="a value"
export FIXTURE_OTHER="another value"
OUT=$(run_without_env FIXTURE_PROBE FIXTURE_OTHER -- bash -c 'printf "%s%s" "${FIXTURE_PROBE+p}" "${FIXTURE_OTHER+o}"')
assert_equals "" "$OUT"

# --- The caller is untouched ---

test_start "The caller's variable is still set after the helper returns"
export FIXTURE_PROBE="a value"
run_without_env FIXTURE_PROBE -- true
assert_equals "set" "${FIXTURE_PROBE+set}"

test_start "The caller's value is unchanged after the helper returns"
export FIXTURE_PROBE="a value"
run_without_env FIXTURE_PROBE -- true
assert_equals "a value" "$FIXTURE_PROBE"

# --- Passthrough ---

test_start "The command's exit code passes through"
run_without_env FIXTURE_PROBE -- bash -c 'exit 7'
assert_equals "7" "$?"

test_start "Arguments after the command are passed to it"
OUT=$(run_without_env FIXTURE_PROBE -- printf '%s-%s' one two)
assert_equals "one-two" "$OUT"

unset FIXTURE_PROBE FIXTURE_OTHER

test_summary
