#!/bin/bash
# link-adapter-git.sh — The git-native link adapter
#
# Spec 42 AD2: "the **baseline adapter is git-native** — commit trailers,
# conventional-commit subjects, and branch names — and works in any repository with no
# configuration." It implements the contract in `linkset-join.sh`; register it with
# `linkset_register gitnative`.
#
# This is the adapter that makes the tool useful outside CPM. Everything it reads is
# already in the repository because people write commit messages, so there is nothing to
# configure, adopt, or back-fill — which is the whole argument for AD2 treating "planning
# artifact" as a role rather than a file type.
#
# --- What it reads and what it claims ---------------------------------------------
#
#   Refs:/Closes: trailer      →  declared   per commit
#   conventional-commit scope  →  derived    per commit
#   branch name                →  derived    per change set (see "The branch signal")
#
# **Why a trailer is declared and a scope is not.** R7 defines declared as "an explicit
# marker names the intent record". `Refs: AUTH-123` is exactly that: a field whose only
# purpose is to name an intent record. `fix(auth):` names a *scope* — a component, an
# area of the code — and treating it as a reference to an intent record called `auth` is
# an inference, a good one but still an inference. The Confidence Integrity requirement
# says a derived link must never be presented as declared, and the plausible way to break
# it is not a bug but a judgement call like this one, made once and then invisible.
#
# --- Intent status and title --------------------------------------------------------
#
# Every intent record this adapter emits carries status `unknown` and takes its own ID as
# its title, because git has neither channel: a commit trailer records *why* a change
# happened and never records whether the thing it references was completed or verified,
# and nothing in git knows what `AUTH-123` is called. This is not a gap to be filled with
# a guess — it is the exact asymmetry that puts `exit 2` in the contract, and the reason
# R4's unbacked-claims query cannot be answered from git alone.
#
# **Two adapters may therefore emit INTENT records with the same ID and different status
# and title.** Reconciling them is the join's job, not an adapter's — for the same reason
# precedence is: an adapter that adjusted its own output to anticipate another adapter
# would make the result depend on which adapters happen to be registered. Each reports
# what its own channel knows. See Story 4.
#
# --- What it deliberately does not do -----------------------------------------------
#
# It does not resolve what a reference *means*. `AUTH-123` becomes an intent record with
# that ID and nothing more; looking it up in an issue tracker needs the network, which
# the Offline Integrity requirement forbids, and the spec lists that resolution under
# Won't Have for this iteration.

LINK_ADAPTER_GIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! declare -f linkset_emit_link >/dev/null 2>&1; then
  # shellcheck source=./linkset.sh
  source "$LINK_ADAPTER_GIT_DIR/linkset.sh"
fi

# The trailer keys AD2 names. Matched case-insensitively at the start of a body line,
# which is where git's own trailer parser looks for them.
GITNATIVE_TRAILER_KEYS="Refs|Closes"

# Print the intent IDs a commit message declares through trailers, one per line.
#
# A trailer value may name several records — `Refs: epic 41-03, AUTH-124` — so values are
# split on commas and trimmed. They are *not* split on whitespace: the spec's own example
# of an intent-anchored reference is `epic 41-03`, and a splitter that broke on spaces
# would turn one record into two that name nothing.
_gitnative_trailer_ids() {
  grep -iE "^[[:space:]]*($GITNATIVE_TRAILER_KEYS):" \
    | sed -E "s/^[[:space:]]*[A-Za-z]+:[[:space:]]*//" \
    | tr ',' '\n' \
    | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' \
    | grep -v '^$'
}

# Print the scope of a conventional-commit subject, or nothing.
#
# `fix(auth): handle expiry` yields `auth`; `feat: add handler` yields nothing, because a
# scopeless conventional commit names no area at all and inventing a link from the type
# (`feat`, `fix`) would group every unrelated feature in the repository under one record.
# A `!` breaking-change marker before the colon is accepted and ignored.
_gitnative_subject_scope() {
  sed -nE 's/^[a-zA-Z]+\(([^)]+)\)!?:.*/\1/p' \
    | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' \
    | grep -v '^$'
}

# Emit an INTENT record plus one LINK per file, for one intent ID at one confidence.
_gitnative_emit_for() {
  local intent="$1"
  local confidence="$2"
  local files="$3"

  [ -n "$intent" ] && [ -n "$files" ] || return 0

  # Title is the ID: see the header. Repeated INTENT records for the same ID are byte
  # identical and collapse in `linkset_normalise`, so emitting one per commit costs
  # nothing and keeps this function independent of what other commits found.
  linkset_emit_intent "$intent" "unknown" "$intent"

  local path
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    linkset_emit_link "$path" "$intent" "$confidence"
  done <<EOF
$files
EOF
}

# --- The branch signal ------------------------------------------------------------------
#
# Kept apart from the two commit-message signals above because it behaves differently in
# three ways, and folding it in would hide all three.
#
# **It is a property of the change set, not of a commit.** Trailers and subjects travel
# with the commit that carries them; the branch name is read from HEAD and applies to
# everything in the change set at once. There is no per-file or per-commit precision to
# be had.
#
# **It is destroyed by a squash merge.** `feature/AUTH-123` merged into `main` as one
# squashed commit leaves no branch and no trace of the name — so this signal is available
# exactly while the work is in flight and gone afterwards, which is the opposite of the
# trailer signal's lifetime. A tool that treated the two as interchangeable would report
# steadily *less* provenance the longer a repository lived, without saying why.
#
# **A branch name is usually not an intent reference at all.** `main`, `develop`, a
# detached HEAD: linking a change set to an intent record called `main` would make every
# file look provenanced and empty R3's orphan list of its meaning, which is the one
# output people act on. So the signal is taken only from a namespaced branch — a `/` in
# the name, whose last segment is the reference — and integration branches are refused by
# name even when namespaced.
GITNATIVE_NON_INTENT_BRANCHES="main|master|develop|development|trunk|release|staging|production"

# Print the intent ID the current branch names, or nothing.
_gitnative_branch_id() {
  local repo="$1"

  local branch
  # Detached HEAD has no branch to read, which is a legitimate state during a bisect or a
  # rebase and not an error; symbolic-ref fails and the signal is simply absent.
  branch=$(git -C "$repo" symbolic-ref --short HEAD 2>/dev/null) || return 0
  [ -n "$branch" ] || return 0

  case "$branch" in
    */*) ;;
    *) return 0 ;;
  esac

  local id="${branch##*/}"
  [ -n "$id" ] || return 0

  # Refused after the split as well as before it: `release/main` is still an integration
  # branch, and a prefix check alone would let it through.
  printf '%s\n' "$id" | grep -qiE "^($GITNATIVE_NON_INTENT_BRANCHES)$" && return 0

  printf '%s\n' "$id"
}

# The contract. See linkset-join.sh.
gitnative_link_changeset() {
  local repo="$1"
  local changeset_file="$2"

  [ -n "$repo" ] && [ -d "$repo" ] || return 1
  [ -n "$changeset_file" ] && [ -f "$changeset_file" ] || return 1

  # A directory that is not a git repository is not a channel this adapter can read.
  # That is exit 2 — "no channel here" — and emphatically not exit 1: an error would
  # mean the git channel exists and could not be read, which would stop the join over a
  # repository that simply has no git history to consult.
  git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 || return 2

  local known
  known=$(changeset_files < "$changeset_file" | LC_ALL=C sort -u | grep -v '^$')
  [ -n "$known" ] || return 0

  # The branch signal covers the whole change set, so it is emitted before the commit
  # walk and independently of it — a working-tree change set has no commits at all, and
  # the branch is the only provenance git has to offer there.
  _gitnative_emit_for "$(_gitnative_branch_id "$repo")" "derived" "$known"

  local commits
  commits=$(changeset_commits < "$changeset_file" | grep -v '^$')
  [ -n "$commits" ] || return 0

  local sha commit_files linked body scope id
  while IFS= read -r sha; do
    [ -n "$sha" ] || continue

    commit_files=$(git -C "$repo" diff-tree --no-commit-id --name-only -r --root "$sha" 2>/dev/null \
      | LC_ALL=C sort -u | grep -v '^$')
    [ -n "$commit_files" ] || continue

    # Only files that are both in this commit and in the change set. The contract forbids
    # an adapter adding to the change set, and a commit routinely touches files that a
    # narrower selector left out.
    linked=$(LC_ALL=C comm -12 <(printf '%s\n' "$commit_files") <(printf '%s\n' "$known"))
    [ -n "$linked" ] || continue

    body=$(git -C "$repo" show -s --format=%B "$sha" 2>/dev/null)

    while IFS= read -r id; do
      _gitnative_emit_for "$id" "declared" "$linked"
    done <<EOF
$(printf '%s\n' "$body" | _gitnative_trailer_ids)
EOF

    scope=$(printf '%s\n' "$body" | head -1 | _gitnative_subject_scope)
    _gitnative_emit_for "$scope" "derived" "$linked"
  done <<EOF
$commits
EOF

  return 0
}
