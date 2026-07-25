#!/bin/bash
# stub-link-adapter.sh — A test double for the link-adapter contract.
#
# Backs Epic 42-02 Story 1. This is a library, not a suite — its filename does not match
# the `test-*.sh` glob, so run-all-tests.sh never runs it standalone.
#
# **The stub is deliberately ignorant**, for the same reason `stub-intent-adapter.sh` is:
# it links every file in the change set it was handed to a fixed intent record, and knows
# nothing about commit trailers, conventional-commit subjects, epic docs or coverage
# matrices. A stub that understood trailers would be an early draft of Story 2's
# git-native adapter, and a harness exercising it would be proving things about that
# adapter rather than about the contract.
#
# Two independent adapters (`stub` and `stub2`) are provided because "every registered
# adapter is queried" and "output from several adapters merges into one link set" are
# properties of the join that a single adapter cannot exhibit. `stub` emits `derived`
# links and `stub2` emits `declared` ones, so their outputs stay distinguishable — and so
# Story 4 inherits a ready-made precedence pair.
#
# **The break modes are the point.** A conformance harness that only ever sees conforming
# adapters proves that it ran, not that it works — the same gap retro 18 named for
# absence assertions and retro 20 named for a fixture that could not tell two readings
# apart. `stub_link_break <mode>` produces one violation class on demand, so every check
# in `linkset-conformance.sh` has a positive control proving it can fail.
#
# State lives in files rather than associative arrays: bash 3.2 ships on macOS and has
# none, and the adapter is invoked in a subshell by `$(...)`, so an in-memory counter
# would not survive the call anyway.
#
# Test-facing helpers:
#   stub_link_records <record>...  — return exactly these records (overrides the default)
#   stub_link_break <mode>         — emit one violation class; see MODES below
#   stub_link_exit <code>          — force this exit code, emitting nothing
#   stub_link_reset                — back to the conforming default
#   stub_link_seen                 — change-set paths received, one per line
#   stub_link_reset_seen           — clear the received log
#   (and the same six as stub2_*)
#
# MODES: exit-code · exit2-output · invalid-record · blank-line · absent · foreign-path ·
#        dangling · nondeterministic · error-on-empty

if [ -z "$TEST_TMPDIR" ]; then
  echo "stub-link-adapter.sh: TEST_TMPDIR is not set — source test-helpers.sh first." >&2
  return 1 2>/dev/null || exit 1
fi

STUB_LINK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! declare -f linkset_emit_link >/dev/null 2>&1; then
  # shellcheck source=../lib/linkset.sh
  source "$STUB_LINK_DIR/../lib/linkset.sh"
fi

STUB_LINK_STATE="$TEST_TMPDIR/stub-link"
STUB2_LINK_STATE="$TEST_TMPDIR/stub2-link"

_stub_link_init() {
  local state="$1"
  : > "${state}-records"
  : > "${state}-mode"
  : > "${state}-exit"
  : > "${state}-seen"
  : > "${state}-counter"
}

_stub_link_init "$STUB_LINK_STATE"
_stub_link_init "$STUB2_LINK_STATE"

# The contract itself. Everything else in this file is scaffolding; this is the shape
# Stories 2 and 3 must match.
_stub_link_changeset() {
  local state="$1"
  local intent="$2"
  local confidence="$3"
  # $4 is the repository. A real adapter reads it; this one has no use for it, and
  # accepting it anyway is part of matching the contract's arity.
  local changeset_file="$5"

  local mode forced
  mode=$(cat "${state}-mode" 2>/dev/null)
  forced=$(cat "${state}-exit" 2>/dev/null)

  local files
  files=$(changeset_files < "$changeset_file" 2>/dev/null | grep -v '^$')

  printf '%s\n' "$files" | grep -v '^$' >> "${state}-seen"

  if [ -n "$forced" ]; then
    return "$forced"
  fi

  case "$mode" in
    exit-code)
      return 3
      ;;
    error-on-empty)
      [ -n "$files" ] || return 1
      ;;
  esac

  # An explicit record list wins over the derived default, for tests that need to control
  # exactly what the join receives.
  local records
  records=$(cat "${state}-records" 2>/dev/null)

  if [ -z "$records" ]; then
    [ -n "$files" ] || return 0
    records=$(linkset_emit_intent "$intent" "open" "Stub intent $intent")
    local path
    while IFS= read -r path; do
      [ -n "$path" ] || continue
      records="${records}"$'\n'"$(linkset_emit_link "$path" "$intent" "$confidence")"
    done <<EOF
$files
EOF
  fi

  case "$mode" in
    invalid-record)
      records="${records}"$'\n'"LINK${LINKSET_TAB}only-two-fields"
      ;;
    # Interleaved rather than appended: command substitution strips trailing newlines, so
    # a blank line at the end of the output could never reach a caller to be judged.
    blank-line)
      records="${records%%$'\n'*}"$'\n\n'"${records#*$'\n'}"
      ;;
    absent)
      records="${records}"$'\n'"$(linkset_emit_link "${files%%$'\n'*}" "$intent" "absent")"
      ;;
    foreign-path)
      records="${records}"$'\n'"$(linkset_emit_link "not/in/the/change/set.txt" "$intent" "$confidence")"
      ;;
    dangling)
      records="${records}"$'\n'"$(linkset_emit_link "${files%%$'\n'*}" "NO-SUCH-INTENT" "$confidence")"
      ;;
    nondeterministic)
      local n
      n=$(cat "${state}-counter" 2>/dev/null)
      n=$(( ${n:-0} + 1 ))
      printf '%s' "$n" > "${state}-counter"
      records="${records}"$'\n'"$(linkset_emit_intent "STUB-VARY-$n" "open" "Varies per call")"
      ;;
    exit2-output)
      printf '%s\n' "$records"
      return 2
      ;;
  esac

  printf '%s\n' "$records"
  return 0
}

stub_link_changeset() {
  _stub_link_changeset "$STUB_LINK_STATE" "STUB-1" "derived" "$@"
}

stub2_link_changeset() {
  _stub_link_changeset "$STUB2_LINK_STATE" "STUB-2" "declared" "$@"
}

# --- Test-facing helpers ---------------------------------------------------------------

_stub_link_set_records() {
  local state="$1"; shift
  : > "${state}-records"
  local record
  for record in "$@"; do
    printf '%s\n' "$record" >> "${state}-records"
  done
}

stub_link_records()  { _stub_link_set_records "$STUB_LINK_STATE" "$@"; }
stub2_link_records() { _stub_link_set_records "$STUB2_LINK_STATE" "$@"; }

stub_link_break()  { printf '%s' "$1" > "$STUB_LINK_STATE-mode"; }
stub2_link_break() { printf '%s' "$1" > "$STUB2_LINK_STATE-mode"; }

stub_link_exit()  { printf '%s' "$1" > "$STUB_LINK_STATE-exit"; }
stub2_link_exit() { printf '%s' "$1" > "$STUB2_LINK_STATE-exit"; }

stub_link_reset()  { _stub_link_init "$STUB_LINK_STATE"; }
stub2_link_reset() { _stub_link_init "$STUB2_LINK_STATE"; }

stub_link_seen()  { cat "$STUB_LINK_STATE-seen"; }
stub2_link_seen() { cat "$STUB2_LINK_STATE-seen"; }

stub_link_reset_seen()  { : > "$STUB_LINK_STATE-seen"; }
stub2_link_reset_seen() { : > "$STUB2_LINK_STATE-seen"; }
