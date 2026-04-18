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

test_summary() {
  echo ""
  echo "Results: $TESTS_PASSED/$TESTS_RUN passed, $TESTS_FAILED failed"
  if [ "$TESTS_FAILED" -gt 0 ]; then
    exit 1
  fi
}

# Create a temp directory for test fixtures; cleaned up on exit
TEST_TMPDIR=$(mktemp -d)
trap 'rm -rf "$TEST_TMPDIR"' EXIT
