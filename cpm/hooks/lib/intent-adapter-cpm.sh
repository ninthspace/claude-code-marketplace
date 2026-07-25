#!/bin/bash
# intent-adapter-cpm.sh — The CPM intent adapter (forward direction)
#
# Spec 42 R1's intent half and R2's forward direction. It implements the contract in
# `changeset-intent.sh`; register it with `changeset_intent_register cpm`.
#
# `link-adapter-cpm.sh` runs the *reverse* direction — given files, which intent records
# do they belong to. This runs the forward one: given `epic 42-05`, which commits produced
# it. Same channels, opposite traversal, and they are separate files because the join
# consumes one and resolution consumes the other; a single adapter answering both would
# be registered in two registries for two unrelated reasons.
#
# --- Why this file exists later than it should have ---------------------------------
#
# The `<name>_intent_commits` contract was frozen in Epic 42-01 Story 3 and verified
# against `cpm/hooks/tests/stub-intent-adapter.sh` — a table lookup with no repository
# behind it. The spec's In-Scope list names the git-native and CPM *link* adapters and
# never scheduled a forward one, so `/cpm:inspect epic 41-03` — the spec's own worked
# example — had nothing to answer it until Epic 42-05 Story 4. Recorded here because a
# reader comparing this file with 42-01's coverage rows would otherwise conclude the rows
# were always about a real channel.
#
# --- The three channels ---------------------------------------------------------------
#
#   the epic document      docs/epics/NN-MM-epic-*.md      — commits that touched it
#   the coverage matrix    docs/epics/NN-MM-coverage-*.md  — commits that touched it
#   the commit message     `epic NN-MM`, `story NN-MM.K`   — commits that name the id
#
# The first two are the CPM link adapter's artifacts read in the other direction. The third
# is not: commit messages are the *git-native* adapter's channel, and reading them here means
# a repository with planning documents and one with only commit conventions are both
# answerable. What R2 requires — "one join, two entry points" — is not established by that
# overlap but by both directions converging on `changeset_emit_from_commits`; the round-trip
# assertion in `test-intent-adapter-cpm.sh` is what checks it.
#
# **Document channels answer for the epic, never for a story.** Touching an epic doc says
# the *epic* moved; which story it moved is in the diff, not the path, and a story
# selector that inherited its epic's document commits would quietly return the whole
# epic's work while looking like it had resolved one story. Story resolution is
# message-only, and finding nothing is the correct answer when nothing names the story.
#
# **No time-window derivation**, for AD2's reason, restated forward: every epic and every
# commit in a chain `cpm:do` executes in one sitting carries the same date, so a window
# would sweep in the neighbouring epics rather than narrow anything.
#
# --- What it declines -----------------------------------------------------------------
#
# Exit 2 — "not a kind of thing I know about" — covers everything outside the two shapes
# `epic NN-MM` and `story NN-MM.K` (with `NN` alone for the flat legacy epic filenames
# that coexist permanently). That includes issue keys like `AUTH-4`, which belong to the
# issue-tracker adapters the spec defers, and **spec-level ids**: `epic 42` is the flat
# epic 42, never "every epic in spec 42's chain". Answering a spec id by unioning its
# chain is a defensible feature and is not this one — it would make `epic 15` mean
# different things depending on which files happen to exist.

INTENT_ADAPTER_CPM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! declare -f changeset_intent_register >/dev/null 2>&1; then
  # shellcheck source=./changeset-intent.sh
  source "$INTENT_ADAPTER_CPM_DIR/changeset-intent.sh"
fi

# An id number is `42-05` (two-part, what `cpm:epics` writes) or `15` (flat legacy).
CPM_INTENT_ID_PATTERN='[0-9]+(-[0-9]+)?'

# The trailing guard on every message pattern below. Without it `epic 42-05` also matches
# `epic 42-051` and `epic 42-05-2`, so a selector would collect a neighbouring epic's
# commits — the failure mode that is hardest to notice, because the answer still looks
# like an answer.
_CPM_INTENT_END='([^0-9-]|$)'

# Print the id number for a selector, or nothing if the selector is not this adapter's
# shape. Two spellings, matching the vocabulary R1 uses and `link-adapter-cpm.sh` emits.
_cpm_intent_epic_id() {
  printf '%s' "$1" | sed -nE "s/^epic ($CPM_INTENT_ID_PATTERN)\$/\1/p"
}

_cpm_intent_story_epic() {
  printf '%s' "$1" | sed -nE "s/^story ($CPM_INTENT_ID_PATTERN)\.[0-9]+\$/\1/p"
}

# `\2`, not `\1`: CPM_INTENT_ID_PATTERN carries a group of its own (`(-[0-9]+)?`) for the
# optional second half of a two-part id, so the story number is the *second* group here.
# Interpolating a pattern shifts capture numbering — the reason the two helpers above take
# the id from group 1 and this one does not.
_cpm_intent_story_number() {
  printf '%s' "$1" | sed -nE "s/^story $CPM_INTENT_ID_PATTERN\.([0-9]+)\$/\2/p"
}

# Commits whose message names this id, in either spelling a CPM document uses.
#
# `-i` because subjects capitalise freely (`Story 3`, `epic 42-05`), and `-E` for the
# alternation — the bracket expression in the guard would work under a basic regex, the
# `(a|b)` around it would not. Both spellings go in one pattern rather than two `--grep`
# arguments (which git ORs, so either form would work) so the trailing guard is written once
# and cannot end up applied to one alternative and not the other.
_cpm_intent_grep() {
  local repo="$1"
  local pattern="$2"
  git -C "$repo" log --format='%H' -i -E --grep="$pattern" 2>/dev/null
}

# Commits that touched the epic's own planning documents. Quoted so git does the globbing
# — an unquoted pattern would expand against the *caller's* working directory, which is
# not the repository being inspected and would usually expand to nothing.
_cpm_intent_docs() {
  local repo="$1"
  local id="$2"
  git -C "$repo" log --format='%H' -- \
    "docs/epics/${id}-epic-"'*.md' \
    "docs/epics/${id}-coverage-"'*.md' 2>/dev/null
}

# The adapter. See changeset-intent.sh for the contract this implements.
cpm_intent_commits() {
  local repo="$1"
  local selector="$2"

  if [ -z "$repo" ] || [ ! -d "$repo" ]; then
    echo "intent-adapter-cpm: no such repository directory: $repo" >&2
    return 1
  fi

  local epic_id story_epic story_no
  epic_id=$(_cpm_intent_epic_id "$selector")
  story_epic=$(_cpm_intent_story_epic "$selector")
  story_no=$(_cpm_intent_story_number "$selector")

  if [ -z "$epic_id" ] && [ -z "$story_epic" ]; then
    return 2
  fi

  if ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
    echo "intent-adapter-cpm: not a git repository: $repo" >&2
    return 1
  fi

  # An unborn HEAD is "answered: nothing" rather than an error. Nothing has been
  # committed, so no commit produced this epic — which is exactly what the caller is
  # asking, and `git log` would only fail at it.
  git -C "$repo" rev-parse --verify -q HEAD >/dev/null 2>&1 || return 0

  local found=""

  if [ -n "$epic_id" ]; then
    # A story id counts towards its epic: a commit that names `story 42-05.2` and nothing
    # else is still work on epic 42-05, and an epic selector that missed it would report the
    # epic's own document commits as the whole of the epic's work.
    found=$(
      _cpm_intent_grep "$repo" "(epic|story)[[:space:]]+${epic_id}${_CPM_INTENT_END}"
      _cpm_intent_docs "$repo" "$epic_id"
    )
  else
    found=$(_cpm_intent_grep "$repo" \
      "(story[[:space:]]+${story_epic}\.${story_no}|epic[[:space:]]+${story_epic}[[:space:]]+story[[:space:]]+${story_no})${_CPM_INTENT_END}")
  fi

  # `sort -u` is here for the `-u`; the ordering it happens to impose is incidental and
  # nothing should depend on it. Order is explicitly not part of the contract, and
  # `changeset_resolve_intent` re-orders through `git rev-list` so that forward and reverse
  # resolution of the same commits come out byte-identical.
  #
  # `return 0` rather than falling off the end: the pipeline's status is `grep`'s, which is
  # 1 when it matched nothing — and "found no commits" is an answer under this contract, not
  # an error.
  printf '%s\n' "$found" | grep -E '^[0-9a-f]{40}$' | LC_ALL=C sort -u
  return 0
}
