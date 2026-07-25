#!/bin/bash
# inspect-resolve.sh — Selector dispatch for /cpm:inspect
#
# Spec 42 AD5: "Intent-anchored selectors resolve forward (intent → commits → files).
# Git-anchored selectors resolve reverse (files → commits → intent). Both converge on one
# change-set structure before the join runs."
#
# Epic 42-01 built both traversals — `changeset_resolve_git` and `changeset_resolve_intent`
# — and nothing chose between them. This file is that choice, and nothing else: it decides
# a direction and hands the selector on unaltered.
#
# --- Why the decision is a separate function ---------------------------------------
#
# `inspect_selector_direction` exists so that which direction a selector takes is
# assertable directly, rather than inferred from a change set. The two questions "did it
# route correctly" and "did resolution work" fail for unrelated reasons, and a test that
# can only see the second reports a routing bug as a resolution bug.
#
# --- Why almost nothing is handled here --------------------------------------------
#
# An unresolvable selector fails inside the resolver, which already owns R1's must-NOT
# ("errors with the selector echoed back"). `changeset_resolve_git`'s header states the
# reason that rule lives in one place: a resolver that reported its own emptiness "would
# put the must-NOT in as many places as there are selector forms, and the next form added
# would be the one that forgot." A second echo-the-selector-back path in the dispatcher
# would be that duplication, one level up.
#
# So this file does not validate selectors and does not translate exit codes. It routes.
# It touches the repository once, to answer rule 3 below, and forms no opinion about it
# beyond whether a branch of that name is there.
#
# The single exception is **no selector at all**, which is this file's own failure rather
# than a resolver's: with nothing to inspect there is no direction, the dispatch matches
# no branch, and the run would return success having done nothing. That is the one outcome
# a router must not produce, so it is refused here.

INSPECT_RESOLVE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! declare -f changeset_resolve_git >/dev/null 2>&1; then
  # shellcheck source=./changeset-resolve.sh
  source "$INSPECT_RESOLVE_DIR/changeset-resolve.sh"
fi

if ! declare -f changeset_resolve_intent >/dev/null 2>&1; then
  # shellcheck source=./changeset-intent.sh
  source "$INSPECT_RESOLVE_DIR/changeset-intent.sh"
fi

# Which direction a selector resolves in. Prints `git` or `intent`.
#
# The order below is AD5 made executable. Rules 1 and 2 recognise syntax no intent record
# uses; rule 3 is the only ambiguous case.
#
# **Rule 3 resolves toward the branch, deliberately.** A bare token could name a branch or
# an intent record, and the tie is broken by which one this repository can be shown to
# have: `show-ref` either finds the branch or it does not, whereas "some adapter might
# understand this string" is a guess that cannot be checked without running every adapter
# and cannot be un-made once one of them answers. CPM intent ids carry a space
# (`epic 42-01`, `story 42-01.2`) and so never reach this rule; it decides for
# issue-tracker keys like `AUTH-4`, where a branch of the same name is the likelier
# meaning of someone typing it.
#
# A missing or unreadable repository routes `intent`, because rule 3 cannot be answered
# and rules 1 and 2 did not fire. The resolver reports the bad repository; a direction is
# not the place to discover it.
inspect_selector_direction() {
  local repo="$1"
  shift

  [ $# -gt 0 ] || return 1

  case "$1" in
    --*)   printf 'git\n';    return 0 ;;
    *..*)  printf 'git\n';    return 0 ;;
  esac

  if [ $# -eq 1 ] && [ -d "$repo" ] \
     && git -C "$repo" show-ref --verify --quiet "refs/heads/$1"; then
    printf 'git\n'
    return 0
  fi

  printf 'intent\n'
}

# Resolve any R1 selector form to change-set records on stdout.
#
# The two directions take the selector differently, and the difference is theirs rather
# than a choice made here. `changeset_resolve_git` parses an argument vector, because
# `--since` takes its ref as a second argument and re-joining the two would make this
# function the place that decides what `--since` means. `changeset_resolve_intent` takes
# one opaque string, because "the selector is opaque" is its contract — so a selector
# typed as several words is rejoined for it, and passed on unparsed.
inspect_resolve() {
  local repo="$1"
  shift

  if [ $# -eq 0 ]; then
    echo "inspect-resolve: no selector given" >&2
    return 1
  fi

  local direction
  direction=$(inspect_selector_direction "$repo" "$@")

  case "$direction" in
    git)    changeset_resolve_git "$repo" "$@" ;;
    intent) changeset_resolve_intent "$repo" "$*" ;;
  esac
}
