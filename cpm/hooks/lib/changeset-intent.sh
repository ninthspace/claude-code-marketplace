#!/bin/bash
# changeset-intent.sh — Intent-anchored (forward) resolution and the adapter contract
#
# Spec 42 AD5: intent-anchored selectors resolve forward (intent → commits → files);
# git-anchored selectors resolve reverse. Both converge on the change-set structure from
# changeset.sh before the join runs. changeset-resolve.sh is the reverse direction; this
# is the forward one, and the contract every intent adapter implements.
#
# --- The adapter contract ---------------------------------------------------------
#
# An adapter is a shell function. Registering the name `foo` means `foo_intent_commits`
# exists and behaves as follows:
#
#   foo_intent_commits <repo> <selector>
#
#     stdout : zero or more full 40-character commit SHAs, one per line, any order
#     exit 0 : answered — the adapter understands this class of selector, and what it
#              printed (possibly nothing) is its complete answer
#     exit 2 : cannot answer — this selector is not a kind of thing this adapter knows
#              about. Not an error, and not the same as finding nothing
#     exit 1 : error — the adapter understood the selector but failed to resolve it
#
# **Order is not part of the contract.** An adapter may return SHAs however it finds
# them; this file normalises them before they reach the structure, so a change to an
# adapter's internal ordering can never change the output.
#
# **The selector is opaque.** R7 requires that the join "reads every intent channel
# present and owns none of them", so nothing here parses, validates or rewrites the
# selector — it is passed to every adapter verbatim. `epic 41-03` means whatever the CPM
# adapter says it means, and `AUTH-123` means whatever an issue-tracker adapter would
# say, and this file has no opinion about either. That is what keeps the deferred
# issue-tracker adapters cheap to add later.
#
# **Why exit 2 exists before anything needs it.** R4 (Epic 42-03) requires that "none
# found" and "not answerable" render differently, because commit trailers and branch
# names record *why* a change happened and never record a verification claim — so an
# unbacked-claims query is answerable only by an adapter that carries such claims. With
# a commits-only contract those two outcomes are indistinguishable, and adding the
# channel later would reopen the contract that Epic 42-01 Story 3 exists to freeze,
# after 42-02 has already implemented against it.
#
# --- Degradation --------------------------------------------------------------------
#
# Zero registered adapters is a supported state, not a misconfiguration: R7 says the
# join "must produce a usable result with zero cooperating channels". For an *intent*
# selector there is nothing usable to produce — no channel can say what `epic 41-03`
# refers to — so it errors with the selector echoed back, per R1's must-NOT. R9's
# "the review still runs and every file is an orphan" applies to a change set that was
# resolved some other way, which is the git-anchored direction's business.

CHANGESET_INTENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! declare -f changeset_emit_from_commits >/dev/null 2>&1; then
  # shellcheck source=./changeset-resolve.sh
  source "$CHANGESET_INTENT_DIR/changeset-resolve.sh"
fi

CHANGESET_INTENT_ADAPTERS=""

# Register an adapter by name. Registration is explicit rather than discovered by naming
# convention, so which channels are active is a statement a caller makes rather than an
# accident of what happens to be sourced.
changeset_intent_register() {
  local name="$1"

  if ! declare -f "${name}_intent_commits" >/dev/null 2>&1; then
    echo "changeset-intent: no such adapter: ${name}_intent_commits is not defined" >&2
    return 1
  fi

  case " $CHANGESET_INTENT_ADAPTERS " in
    *" $name "*) return 0 ;;
  esac

  CHANGESET_INTENT_ADAPTERS="${CHANGESET_INTENT_ADAPTERS}${CHANGESET_INTENT_ADAPTERS:+ }$name"
}

# Forget every registered adapter.
changeset_intent_reset() {
  CHANGESET_INTENT_ADAPTERS=""
}

# Print the registered adapter names, one per line, in registration order.
changeset_intent_adapters() {
  local name
  for name in $CHANGESET_INTENT_ADAPTERS; do
    echo "$name"
  done
}

# Report whether any registered adapter can answer this selector at all.
#   0 — at least one adapter answered (whatever it found)
#   2 — adapters are registered but none can answer this class of selector
#   1 — no adapters are registered
#
# Exposed separately from resolution because Epic 42-03's gap queries need the
# distinction without wanting the change set.
#
# Only exit 0 counts as an answer. An adapter that errors has told us nothing about
# whether the question was answerable, and reporting it as answered would let a broken
# adapter turn "not answerable" into "none found" — the exact conflation R4 forbids.
changeset_intent_answerable() {
  local repo="$1"
  local selector="$2"

  [ -n "$CHANGESET_INTENT_ADAPTERS" ] || return 1

  local name
  for name in $CHANGESET_INTENT_ADAPTERS; do
    if "${name}_intent_commits" "$repo" "$selector" >/dev/null 2>&1; then
      return 0
    fi
  done

  return 2
}

# Resolve an intent-anchored selector to change-set records on stdout.
changeset_resolve_intent() {
  local repo="$1"
  local selector="$2"

  if [ -z "$repo" ] || [ ! -d "$repo" ]; then
    echo "changeset-intent: no such repository directory: $repo" >&2
    return 1
  fi

  if [ -z "$selector" ]; then
    echo "changeset-intent: no selector given" >&2
    return 1
  fi

  local shas="" answered=0
  local name out rc stray

  for name in $CHANGESET_INTENT_ADAPTERS; do
    out=$("${name}_intent_commits" "$repo" "$selector" 2>/dev/null)
    rc=$?

    case "$rc" in
      0)
        # A contract violation is reported against the adapter that committed it.
        # Filtering stray output instead would turn a broken adapter into an empty
        # change set, and "selector matched no changes" is a plausible-looking lie.
        stray=$(printf '%s' "$out" | grep -vE '^[0-9a-f]{40}$' | grep -v '^$')
        if [ -n "$stray" ]; then
          echo "changeset-intent: adapter '$name' returned a value that is not a full commit SHA: $(printf '%s' "$stray" | head -1)" >&2
          return 1
        fi
        answered=1
        shas="${shas}${out}"$'\n'
        ;;
      2) ;;
      *)
        echo "changeset-intent: adapter '$name' failed on selector: $selector" >&2
        return 1
        ;;
    esac
  done

  if [ "$answered" -eq 0 ]; then
    echo "changeset-intent: no adapter can answer this selector: $selector" >&2
    return 1
  fi

  # Normalise: deduplicate, then let git order the set exactly as it orders a range, so
  # forward and reverse resolution of the same commits are byte-identical.
  local ordered=""
  local unique
  unique=$(printf '%s' "$shas" | grep -E '^[0-9a-f]{40}$' | LC_ALL=C sort -u)

  if [ -n "$unique" ]; then
    # shellcheck disable=SC2086
    if ! ordered=$(git -C "$repo" rev-list --no-walk $unique 2>/dev/null); then
      echo "changeset-intent: an adapter named a commit that is not in this repository, for selector: $selector" >&2
      return 1
    fi
  fi

  local records
  records=$(printf '%s\n' "$ordered" | changeset_emit_from_commits "$repo")

  if [ -z "$records" ]; then
    echo "changeset-intent: selector matched no changes: $selector" >&2
    return 1
  fi

  printf '%s\n' "$records"
}
