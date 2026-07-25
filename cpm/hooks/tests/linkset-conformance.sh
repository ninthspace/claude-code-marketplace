#!/bin/bash
# linkset-conformance.sh — The conformance harness every link adapter must pass.
#
# Backs Epic 42-02 Story 1's second acceptance criterion: "a conformance suite exercises
# the contract, and any adapter must pass it". This is a library, not a suite — its
# filename does not match the `test-*.sh` glob, so run-all-tests.sh never runs it
# standalone. Stories 2 and 3 source it and run their real adapters through it.
#
# **What it is for.** AD2 makes the adapter set open-ended: two ship in this epic and the
# issue-tracker adapters (Jira, GitHub, Linear) are deferred rather than rejected. A
# per-adapter suite proves that adapter reads its own channel correctly; only a shared
# harness proves the *contract* holds, which is what makes a fourth adapter cheap to add
# later. Everything asserted here is true of any adapter regardless of what it reads.
#
# **What it deliberately does not check.** Whether a link is *true* — "42-01.3 owns this
# file" — has no oracle, as the spec says of R7's precedence row. The harness checks the
# shape of an adapter's answer, never its content, and a suite that appeared to check the
# latter would be the more dangerous of the two.
#
# **Why the checks go beyond the story's criteria.** Retro 20 (Testing Gaps): a suite
# written from acceptance criteria is complete with respect to those criteria and silent
# about every other branch the code has. The three criteria name the contract, the
# harness and the zero-adapter path; the eight checks below are the contract's actual
# surface. The one that caught a real defect last epic — an unnamed third exit code —
# is check 2 here.
#
# --- Two layers -----------------------------------------------------------------------
#
#   linkset_conformance_check <adapter> <repo> <changeset-file>
#     Pure: prints one line per violation, returns 1 if any. No test-helpers dependency.
#     Used by the positive controls in test-linkset.sh, which need the harness to *fail*.
#
#   linkset_conformance_run <adapter> <repo> <changeset-file>
#     Wraps the above in a single test_start/test_pass/test_fail. This is what an
#     adapter's own suite calls. One assertion, not eight, per retro 15's 1:1 ratio.

if [ -z "$TEST_TMPDIR" ]; then
  echo "linkset-conformance.sh: TEST_TMPDIR is not set — source test-helpers.sh first." >&2
  return 1 2>/dev/null || exit 1
fi

LINKSET_CONFORMANCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! declare -f linkset_join >/dev/null 2>&1; then
  # shellcheck source=../lib/linkset-join.sh
  source "$LINKSET_CONFORMANCE_DIR/../lib/linkset-join.sh"
fi

# Print any intent ID referenced by a LINK or CRITERION record with no INTENT record to
# match. A dangling reference survives into the JSON as a link to a record that is not
# there, which the artifact page renders as a blank.
_linkset_conformance_dangling() {
  local records="$1"

  local ids referenced
  referenced=$(printf '%s\n' "$records" \
    | awk -F'\t' '$1 == "LINK" { print $3 } $1 == "CRITERION" { print $2 }' \
    | LC_ALL=C sort -u | grep -v '^$')
  [ -n "$referenced" ] || return 0

  ids=$(printf '%s\n' "$records" | linkset_intent_ids | LC_ALL=C sort -u | grep -v '^$')

  LC_ALL=C comm -23 <(printf '%s\n' "$referenced") <(printf '%s\n' "$ids")
}

# The contract, checked. Prints one line per violation; returns 1 if any were found.
linkset_conformance_check() {
  local adapter="$1"
  local repo="$2"
  local changeset_file="$3"

  local violations=""
  _note() { violations="${violations}${1}"$'\n'; }

  # 1 — the adapter exists at all. Everything below would otherwise report a shell error
  #     as a contract violation.
  if ! declare -f "${adapter}_link_changeset" >/dev/null 2>&1; then
    echo "NOT DEFINED: ${adapter}_link_changeset"
    return 1
  fi

  local out rc
  out=$("${adapter}_link_changeset" "$repo" "$changeset_file" 2>/dev/null)
  rc=$?

  # 2 — the contract names exactly three exit codes. An adapter returning anything else
  #     is making a claim the join has no reading for, and the join's `case` would treat
  #     it as an error, so an adapter using 3 to mean "nothing found" would fail loudly
  #     and confusingly rather than quietly. Named here so it fails clearly instead.
  case "$rc" in
    0 | 1 | 2) ;;
    *) _note "INVALID EXIT CODE: $rc (contract allows 0, 1, 2)" ;;
  esac

  # 3 — exit 2 means "no channel here", which is a statement, not a partial answer.
  #     Output alongside it would be records the join is about to discard.
  if [ "$rc" -eq 2 ] && [ -n "$out" ]; then
    _note "EXIT 2 WITH OUTPUT: $(printf '%s' "$out" | head -1)"
  fi

  if [ "$rc" -eq 0 ] && [ -n "$out" ]; then
    # 4 — the structure holds. This is also where an adapter claiming `absent` is
    #     caught: linkset_validate rejects it with its own diagnostic, so the harness
    #     does not repeat the check with a second, drifting copy of the rule.
    #
    #     The empty-output guard on the branch above mirrors the join's `[ -n "$out" ]`
    #     rather than filtering blank lines out of the input, and the difference is not
    #     cosmetic: filtering would let this harness certify an adapter that emits a
    #     stray blank line, which the join then rejects at runtime as a malformed record.
    #     A harness that passes adapters the join refuses is worse than no harness.
    local invalid
    invalid=$(printf '%s\n' "$out" | linkset_validate)
    [ -n "$invalid" ] && _note "INVALID RECORD: $(printf '%s' "$invalid" | head -1)"

    # 5 — no link names a file outside the change set. Uses the join's own function
    #     rather than a copy, so an adapter can never be certified against a rule the
    #     join does not actually apply.
    local foreign
    foreign=$(printf '%s\n' "$out" | _linkset_foreign_paths "$changeset_file")
    [ -n "$foreign" ] && _note "FOREIGN PATH: $(printf '%s' "$foreign" | head -1)"

    # 6 — every referenced intent record is present.
    local dangling
    dangling=$(_linkset_conformance_dangling "$out")
    [ -n "$dangling" ] && _note "DANGLING INTENT ID: $(printf '%s' "$dangling" | head -1)"

    # 7 — two runs over the same change set agree. Compared *normalised*, because order
    #     is explicitly not part of the contract: an adapter is free to iterate however
    #     it likes, and the join sorts. What must not vary is which records come back.
    local again
    again=$("${adapter}_link_changeset" "$repo" "$changeset_file" 2>/dev/null)
    if [ "$(printf '%s\n' "$out" | linkset_normalise)" != "$(printf '%s\n' "$again" | linkset_normalise)" ]; then
      _note "NON-DETERMINISTIC: two runs over the same change set returned different records"
    fi
  fi

  # 8 — an empty change set is answered, not errored. Nothing changed is a legitimate
  #     state, and R9 turns on the join surviving repositories that tell it nothing.
  local empty_cs empty_rc
  empty_cs=$(mktemp "$TEST_TMPDIR/linkset-conformance-empty-XXXXXX")
  : > "$empty_cs"
  "${adapter}_link_changeset" "$repo" "$empty_cs" >/dev/null 2>&1
  empty_rc=$?
  [ "$empty_rc" -eq 1 ] && _note "ERRORED ON EMPTY CHANGE SET (exit 1)"
  rm -f "$empty_cs"

  unset -f _note

  [ -n "$violations" ] || return 0
  printf '%s' "$violations" | grep -v '^$'
  return 1
}

# The suite-facing entry point. One assertion covering the whole contract — the multiple
# facts are reported together in the failure message rather than split across eight
# test_start calls that would inflate the pass/test ratio (retro 15).
linkset_conformance_run() {
  local adapter="$1"

  test_start "adapter '$adapter' conforms to the link-adapter contract"

  local violations
  if violations=$(linkset_conformance_check "$@"); then
    test_pass
  else
    test_fail "Contract violations from '$adapter':
$violations"
  fi
}
