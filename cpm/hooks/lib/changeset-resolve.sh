#!/bin/bash
# changeset-resolve.sh — Git-anchored selector resolution (spec 42 R1, AD5)
#
# Resolves the four git-anchored selector forms to the change-set structure defined in
# changeset.sh. This is AD5's *reverse* traversal — files ← commits ← selector. Forward
# resolution from an intent-anchored selector lands in Story 3 and converges on the same
# structure, which is what lets the join, the gap queries and the review be written once.
#
# Usage (library):
#   source changeset.sh; source changeset-resolve.sh
#   changeset_resolve_git <repo> --since <ref>
#   changeset_resolve_git <repo> <A>..<B>          # or <A>...<B>
#   changeset_resolve_git <repo> <branch>
#   changeset_resolve_git <repo> --working-tree
#
# Usage (command):
#   bash changeset-resolve.sh <repo> <selector>...
#
# Emits change-set records on stdout. Diagnostics go to stderr and the exit status is
# non-zero, so a caller can never mistake a failure for an empty result.
#
# --- The four forms ---------------------------------------------------------------
#
#   --since <ref>      commits reachable from HEAD but not from <ref>
#   <A>..<B>           exactly that range, passed to git unchanged
#   <branch>           commits made on <branch> since it split from wherever it was cut
#   --working-tree     uncommitted changes; no commits, by definition
#
# **What a branch name means is a decision, not a reading.** R1 names "a branch" as a
# selector without saying what it is measured against, and the readings are not close:
# the branch's whole history (for a feature branch, the entire repository) or what the
# branch has added since it split. This resolves the second, against the branch's actual
# **fork point** — see _changeset_fork_point.
#
# Measuring against the default branch instead would be right only for branches cut from
# the default branch. A branch stacked on another feature branch would report its parent
# branch's commits as its own, which is a wrong answer that looks entirely plausible.
# When a branch has no fork point at all, the selector errors and says so rather than
# falling back to the whole history.
#
# --- Why the file set is the union of what the commits touched ----------------------
#
# Files could be derived either as the net diff across the range or as the union of the
# files each commit touched. The union is used, and the reason is R2 rather than taste:
# it makes the file set a pure function of the commit set. Both resolution directions
# reach the same commits by different traversals, so deriving files from commits alone
# is what makes "an intent-anchored run and a git-anchored run over the same commits
# yield the same file set" true by construction rather than by coincidence.
#
# The visible consequence is that a file touched and later reverted within the range
# stays in the change set. That is the right answer for a provenance tool — the work
# happened, and a reviewer asking "what did this touch" is not helped by a file
# disappearing because its final state matched its first.
#
# Merge commits contribute no files of their own: `git diff-tree` reports nothing for a
# merge without an explicit strategy, and a merge that introduces content not present in
# either parent is a conflict resolution, not the common case. They remain in the commit
# set, where an adapter can still read their trailers.

CHANGESET_RESOLVE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! declare -f changeset_emit_commit >/dev/null 2>&1; then
  # shellcheck source=./changeset.sh
  source "$CHANGESET_RESOLVE_DIR/changeset.sh"
fi

_changeset_die() {
  echo "changeset-resolve: $1" >&2
  return 1
}

# Print the commit a branch split from, or nothing if it split from nothing.
#
# The fork point is found rather than assumed: the merge base is taken against every
# other ref, and the closest of those — the one with the most ancestors — is where this
# branch left the line it was cut from. A branch stacked on another feature branch
# therefore measures against that feature branch, not against the default branch, which
# is the case a default-branch assumption gets wrong.
#
# A merge base equal to the branch's own tip means the other ref *contains* this branch
# rather than this branch having split from it, so those candidates are dropped. When
# none survive, the branch has nothing to have split from and the caller errors.
#
# Ties are resolved by ref order, which `for-each-ref` sorts by refname — so a repository
# in a given state always yields the same fork point.
_changeset_fork_point() {
  local repo="$1"
  local branch="$2"

  local tip
  tip=$(git -C "$repo" rev-parse "refs/heads/$branch" 2>/dev/null) || return 1

  local best="" best_count=-1
  local ref base count

  while IFS= read -r ref; do
    [ "$ref" = "refs/heads/$branch" ] && continue
    base=$(git -C "$repo" merge-base "$tip" "$ref" 2>/dev/null) || continue
    [ -n "$base" ] && [ "$base" != "$tip" ] || continue
    count=$(git -C "$repo" rev-list --count "$base" 2>/dev/null) || continue
    if [ "$count" -gt "$best_count" ]; then
      best_count="$count"
      best="$base"
    fi
  done < <(git -C "$repo" for-each-ref --format='%(refname)' refs/heads refs/remotes)

  [ -n "$best" ] || return 1
  echo "$best"
}

# Print the files touched by each commit read from stdin, one path per line, unsorted
# and possibly repeated — changeset_emit_files sorts and deduplicates.
_changeset_files_for_commits() {
  local repo="$1"
  while IFS= read -r sha; do
    [ -n "$sha" ] || continue
    git -C "$repo" diff-tree --no-commit-id --name-only -r --root "$sha" 2>/dev/null
  done
}

# Emit a change set from commit SHAs on stdin, in the order given.
#
# This is where AD5's "both converge on one change-set structure" is actually made true.
# Reverse resolution (below) and forward resolution (changeset-intent.sh) reach their
# commits by opposite traversals and then hand them here, so the structure is produced
# by one implementation rather than by two that have to be kept in agreement.
changeset_emit_from_commits() {
  local repo="$1"

  local commits
  commits=$(cat)
  [ -n "$commits" ] || return 0

  printf '%s\n' "$commits" | while IFS= read -r sha; do
    [ -n "$sha" ] && changeset_emit_commit "$sha"
  done

  printf '%s\n' "$commits" | _changeset_files_for_commits "$repo" | changeset_emit_files
}

# Emit a change set from a git revision expression (anything `git rev-list` accepts).
_changeset_from_revs() {
  local repo="$1"
  local selector="$2"
  shift 2

  local commits
  if ! commits=$(git -C "$repo" rev-list "$@" 2>/dev/null); then
    _changeset_die "selector does not resolve in this repository: $selector"
    return 1
  fi

  printf '%s\n' "$commits" | changeset_emit_from_commits "$repo"
}

# Emit a change set from the uncommitted state of the working tree.
_changeset_from_working_tree() {
  local repo="$1"

  local status
  if ! status=$(git -C "$repo" status --porcelain 2>/dev/null); then
    _changeset_die "not a git repository: $repo"
    return 1
  fi

  [ -n "$status" ] || return 0

  # Porcelain v1: two status characters, a space, then the path. A rename reports
  # "old -> new"; the new path is the one that exists to be reviewed.
  printf '%s\n' "$status" \
    | sed -e 's/^...//' -e 's/.* -> //' -e 's/^"\(.*\)"$/\1/' \
    | changeset_emit_files
}

# Resolve a git-anchored selector to change-set records on stdout.
#
# Each form's resolver returns an empty change set when its selector matched nothing;
# turning that into R1's error is done here, once, for every form. A resolver that
# reported its own emptiness would put the must-NOT in as many places as there are
# selector forms, and the next form added would be the one that forgot.
changeset_resolve_git() {
  local repo="$1"
  shift

  if [ -z "$repo" ] || [ ! -d "$repo" ]; then
    _changeset_die "no such repository directory: $repo"
    return 1
  fi

  if [ $# -eq 0 ]; then
    _changeset_die "no selector given"
    return 1
  fi

  local selector="$1"
  local records

  case "$1" in
    --working-tree)
      records=$(_changeset_from_working_tree "$repo") || return 1
      ;;
    --since)
      if [ $# -lt 2 ] || [ -z "$2" ]; then
        _changeset_die "--since needs a ref"
        return 1
      fi
      selector="--since $2"
      records=$(_changeset_from_revs "$repo" "$selector" "$2..HEAD") || return 1
      ;;
    --*)
      _changeset_die "unknown selector: $1"
      return 1
      ;;
    *..*)
      records=$(_changeset_from_revs "$repo" "$1" "$1") || return 1
      ;;
    *)
      local branch="$1"
      if ! git -C "$repo" show-ref --verify --quiet "refs/heads/$branch"; then
        _changeset_die "no such branch: $branch"
        return 1
      fi

      local fork
      if ! fork=$(_changeset_fork_point "$repo" "$branch"); then
        _changeset_die "'$branch' has no fork point — nothing in this repository shows where it split from, so pass an explicit range or --since instead"
        return 1
      fi

      records=$(_changeset_from_revs "$repo" "$branch" "$fork..$branch") || return 1
      ;;
  esac

  if [ -z "$records" ]; then
    _changeset_die "selector matched no changes: $selector"
    return 1
  fi

  printf '%s\n' "$records"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  changeset_resolve_git "$@"
fi
