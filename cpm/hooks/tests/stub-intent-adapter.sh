#!/bin/bash
# stub-intent-adapter.sh — A test double for the intent-adapter contract.
#
# Backs Epic 42-01 Story 3's third acceptance criterion: "the intent-resolution interface
# is exercised against a stub adapter, so the real adapters in Epic 42-02 implement a
# contract that already has tests". This is a library, not a suite — its filename does
# not match the `test-*.sh` glob, so run-all-tests.sh never executes it standalone.
#
# **The stub is deliberately ignorant.** It resolves a selector by looking it up in a
# table the test writes, and knows nothing about git, commit trailers, conventional
# commits, or CPM planning documents. That is the entire point: a stub that understood
# trailers would be an early draft of Epic 42-02's git-native adapter, and a suite
# exercising it would be making claims about that adapter rather than about the contract.
# What this file demonstrates is that an adapter needs to supply *only* what the contract
# asks for — SHAs and an answerability signal — and nothing about how it found them.
#
# Two independent adapters are provided (`stub` and `stub2`) because "every registered
# adapter is queried" and "overlapping results are deduplicated" are properties of the
# registry that a single adapter cannot exhibit.
#
# State lives in files rather than associative arrays: bash 3.2 ships on macOS and has
# none, and this must run wherever the rest of the suite runs.
#
# Test-facing helpers:
#   stub_intent_map <selector> <sha>...   — this selector resolves to these commits
#   stub_intent_unanswerable <selector>   — this selector gets exit 2 (cannot answer)
#   stub_intent_broken <selector>         — this selector gets exit 1 (adapter error)
#   stub_intent_seen                       — selectors received, one per line
#   stub_intent_reset_seen                 — clear the received-selector log
#   (and the same five as stub2_*)

if [ -z "$TEST_TMPDIR" ]; then
  echo "stub-intent-adapter.sh: TEST_TMPDIR is not set — source test-helpers.sh first." >&2
  return 1 2>/dev/null || exit 1
fi

STUB_INTENT_MAP_FILE="$TEST_TMPDIR/stub-intent-map"
STUB_INTENT_SEEN_FILE="$TEST_TMPDIR/stub-intent-seen"
STUB2_INTENT_MAP_FILE="$TEST_TMPDIR/stub2-intent-map"
STUB2_INTENT_SEEN_FILE="$TEST_TMPDIR/stub2-intent-seen"

: > "$STUB_INTENT_MAP_FILE"
: > "$STUB_INTENT_SEEN_FILE"
: > "$STUB2_INTENT_MAP_FILE"
: > "$STUB2_INTENT_SEEN_FILE"

# Replace this selector's entry. Values are SHAs, or the literal UNANSWERABLE.
_stub_intent_set() {
  local map_file="$1"
  local selector="$2"
  shift 2

  local remaining
  remaining=$(grep -vF "$selector$(printf '\t')" "$map_file" 2>/dev/null)
  : > "$map_file"
  [ -n "$remaining" ] && printf '%s\n' "$remaining" >> "$map_file"

  local value
  for value in "$@"; do
    printf '%s\t%s\n' "$selector" "$value" >> "$map_file"
  done
}

# The contract itself. Everything above is scaffolding; this is the shape Epic 42-02's
# adapters must match.
_stub_intent_lookup() {
  local map_file="$1"
  local seen_file="$2"
  # $3 is the repository. A real adapter reads it; a table lookup has no use for it, and
  # accepting it anyway is part of matching the contract's arity.
  local selector="$4"

  printf '%s\n' "$selector" >> "$seen_file"

  local values
  values=$(awk -F'\t' -v s="$selector" '$1 == s { print $2 }' "$map_file")

  case "$values" in
    *UNANSWERABLE*) return 2 ;;
    *BROKEN*) return 1 ;;
  esac

  [ -n "$values" ] && printf '%s\n' "$values"
  return 0
}

stub_intent_commits() {
  _stub_intent_lookup "$STUB_INTENT_MAP_FILE" "$STUB_INTENT_SEEN_FILE" "$@"
}

stub2_intent_commits() {
  _stub_intent_lookup "$STUB2_INTENT_MAP_FILE" "$STUB2_INTENT_SEEN_FILE" "$@"
}

stub_intent_map()        { _stub_intent_set "$STUB_INTENT_MAP_FILE" "$@"; }
stub2_intent_map()       { _stub_intent_set "$STUB2_INTENT_MAP_FILE" "$@"; }

stub_intent_unanswerable()  { _stub_intent_set "$STUB_INTENT_MAP_FILE" "$1" UNANSWERABLE; }
stub2_intent_unanswerable() { _stub_intent_set "$STUB2_INTENT_MAP_FILE" "$1" UNANSWERABLE; }

stub_intent_broken()        { _stub_intent_set "$STUB_INTENT_MAP_FILE" "$1" BROKEN; }
stub2_intent_broken()       { _stub_intent_set "$STUB2_INTENT_MAP_FILE" "$1" BROKEN; }

stub_intent_seen()       { cat "$STUB_INTENT_SEEN_FILE"; }
stub2_intent_seen()      { cat "$STUB2_INTENT_SEEN_FILE"; }

stub_intent_reset_seen()  { : > "$STUB_INTENT_SEEN_FILE"; }
stub2_intent_reset_seen() { : > "$STUB2_INTENT_SEEN_FILE"; }
