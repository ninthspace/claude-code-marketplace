#!/bin/bash
# git-fixture-helpers.sh — Synthetic git repositories for CPM test suites.
#
# These back Epic 42-01 Story 1's [integration] acceptance criteria (spec 42, Testing
# Strategy → Test Infrastructure). They are a library, not a test suite: source this
# file *after* test-helpers.sh. The filename does not match the `test-*.sh` glob, so
# run-all-tests.sh never executes it standalone.
#
# Every existing hook suite operates on flat files in TEST_TMPDIR. Spec 42 needs
# fixtures that are *real repositories* — known commits, trailers, branch names and
# co-committed planning documents — because change-set resolution and the git-native
# adapter parse git's own output. Nothing here can be faked with a directory of files.
#
# Provided functions:
#   git_fixture_create [<label>]              — build an empty repo, print its path
#   git_fixture_commit <repo> <subject> [--trailer "Key: Value"]... [--] [<path> <content>]...
#                                             — commit one or more files in one commit
#   git_fixture_branch <repo> <name>          — create a branch and switch to it
#   git_fixture_checkout <repo> <name>        — switch to an existing branch
#   git_fixture_git <repo> <args>...          — run git in the repo under fixture isolation
#   git_fixture_destroy <repo>                — remove one fixture repository
#   git_fixture_destroy_all                   — remove every fixture built this run
#   git_fixture_root                           — print the directory fixtures live under
#   git_fixture_count                          — print how many fixture repos exist
#
# --- The four commit shapes -----------------------------------------------------
#
# Spec 42 AD2's git-native adapter reads three signals, and AD2's derivation rule adds
# a fourth. The fixture vocabulary is fixed here rather than grown per suite, so every
# suite that exercises the adapter builds the same shapes the same way:
#
#   commit trailers            git_fixture_commit "$r" "subject" --trailer "Refs: epic 41-03" ...
#   conventional subjects      git_fixture_commit "$r" "fix(auth): handle expiry" ...
#   branch names               git_fixture_branch "$r" "feature/AUTH-123"
#   co-committed files         git_fixture_commit "$r" "subject" docs/e.md "..." src/a.txt "..."
#
# Only two of the four need code. A conventional-commit subject is just a subject
# string, so it is passed through verbatim and no builder is provided — one would only
# add a second way to spell what the adapter has to parse from raw text anyway. A
# co-commit is the multi-pair form of an ordinary commit, which is what makes co-commit
# the *strongest derived signal* in AD2: one commit carrying both a change and a
# reference to intent links them without either side declaring anything.
#
# --- Why there is no trap in this file -----------------------------------------
#
# The no-leftovers guarantee is inherited, not re-implemented. test-helpers.sh ends
# with:
#
#     TEST_TMPDIR=$(mktemp -d)
#     trap 'rm -rf "$TEST_TMPDIR"' EXIT
#
# Fixtures are created *inside* TEST_TMPDIR, so that single trap removes them however
# the suite ends — clean exit, `test_summary`'s `exit 1`, or an error partway through.
# Registering a second `trap ... EXIT` here would silently *replace* that one rather
# than compose with it, so the helper deliberately adds none. Explicit teardown is
# available for tests that need to observe removal (git_fixture_destroy), but no test
# has to call it for the suite to leave nothing behind.
#
# --- Isolation ------------------------------------------------------------------
#
# A fixture must not read the host's git configuration and must never touch the host
# repository. Three things enforce that:
#
#   1. Fixtures live under TEST_TMPDIR, which mktemp places outside the working tree.
#   2. GIT_CONFIG_GLOBAL and GIT_CONFIG_SYSTEM are pointed at /dev/null, so signing
#      keys, `init.templateDir`, `core.hooksPath`, url rewrites and aliases from the
#      developer's machine cannot reach a fixture. Without this, a contributor with
#      `commit.gpgsign=true` set globally gets a fixture that fails to commit.
#   3. Identity and dates are supplied explicitly, so a machine with no user.email
#      configured behaves identically to one that has it set.
#
# No function here clones, fetches, pushes, or resolves a remote — the fixtures are
# built entirely from local `git init` and `git commit`, which is what the Offline
# Integrity requirement demands of the harness as well as the tool.
#
# --- Determinism ----------------------------------------------------------------
#
# Commit timestamps are derived from the repository's own commit count rather than the
# wall clock, so the same fixture recipe produces the same commit SHAs on every run and
# on every machine. That is what lets later stories assert byte-identical JSON (spec 42
# R6) without pinning a literal SHA anywhere.

# Fail loudly rather than scattering fixtures into the working tree: this library has
# no temp directory of its own by design (see "Why there is no trap in this file").
if [ -z "$TEST_TMPDIR" ]; then
  echo "git-fixture-helpers.sh: TEST_TMPDIR is not set — source test-helpers.sh first." >&2
  return 1 2>/dev/null || exit 1
fi

GIT_FIXTURE_ROOT="$TEST_TMPDIR/git-fixtures"

# Fixed base timestamp; each commit in a repo advances one minute from it. Any epoch
# would do — what matters is that it does not come from the clock.
_GIT_FIXTURE_EPOCH=1700000000

git_fixture_root() {
  echo "$GIT_FIXTURE_ROOT"
}

# Run git against a fixture repo with the host's configuration held off.
# Usage: git_fixture_git <repo> <git args>...
git_fixture_git() {
  local repo="$1"
  shift
  GIT_CONFIG_GLOBAL=/dev/null \
  GIT_CONFIG_SYSTEM=/dev/null \
  GIT_TERMINAL_PROMPT=0 \
    git -C "$repo" "$@"
}

# Build an empty repository under the fixture root and print its path.
# Usage: repo=$(git_fixture_create [<label>])
#
# Uniqueness comes from mktemp rather than a counter. The intended call form puts this
# function inside a command substitution, which runs it in a subshell — so any variable
# it incremented would be discarded, and every call would return the same path. Two
# fixtures built for a comparison would then silently be one fixture, and a test
# comparing them would pass for the wrong reason.
git_fixture_create() {
  local label="${1:-repo}"
  mkdir -p "$GIT_FIXTURE_ROOT" || return 1

  local repo
  repo=$(mktemp -d "$GIT_FIXTURE_ROOT/${label}-XXXXXX") || return 1

  # Routed through git_fixture_git so the isolation environment is defined in exactly
  # one place; `init` is the call that most needs it, since init.templateDir and
  # core.hooksPath take effect before any repo-local config exists to override them.
  git_fixture_git "$repo" -c init.defaultBranch=main init -q || return 1

  # Repo-local identity: committed into .git/config, so it survives any later call
  # that does not go through git_fixture_git.
  git_fixture_git "$repo" config user.name "CPM Fixture" || return 1
  git_fixture_git "$repo" config user.email "fixture@example.invalid" || return 1
  git_fixture_git "$repo" config commit.gpgsign false || return 1

  echo "$repo"
}

# Commit one or more files in a single commit.
# Usage: git_fixture_commit <repo> <subject> [--trailer "Key: Value"]... [--] [<path> <content>]...
#
# Paths are relative to the repo root and may include directories, which are created
# as needed. Passing several pairs produces a co-commit — one commit touching several
# files — which is the shape the derived-provenance signal depends on (spec 42 AD2).
#
# Trailers are assembled into the message body by hand — subject, blank line, then one
# `Key: Value` per line — rather than passed to `git commit --trailer`, which only
# exists from git 2.32. The assembled form is precisely what git's trailer parser
# consumes, so `git log --format='%(trailers)'` reads it back identically either way,
# and the fixture does not impose a git version floor on the suites that use it.
#
# `--` ends option parsing, for the rare file path that would otherwise look like a flag.
git_fixture_commit() {
  local repo="$1"
  local subject="$2"
  shift 2

  if [ ! -d "$repo/.git" ]; then
    echo "git_fixture_commit: not a fixture repository: $repo" >&2
    return 1
  fi

  local trailers=""
  local end_of_options=0

  while [ $# -gt 0 ]; do
    if [ "$end_of_options" -eq 0 ]; then
      case "$1" in
        --)
          end_of_options=1
          shift
          continue
          ;;
        --trailer)
          if [ $# -lt 2 ]; then
            echo "git_fixture_commit: --trailer needs a 'Key: Value' argument" >&2
            return 1
          fi
          case "$2" in
            *": "*) ;;
            *)
              echo "git_fixture_commit: trailer must be 'Key: Value', got: $2" >&2
              return 1
              ;;
          esac
          trailers="${trailers}$2"$'\n'
          shift 2
          continue
          ;;
      esac
    fi

    if [ $# -lt 2 ]; then
      echo "git_fixture_commit: file arguments must be <path> <content> pairs" >&2
      return 1
    fi
    local path="$1"
    local content="$2"
    shift 2

    mkdir -p "$repo/$(dirname "$path")"
    printf '%s\n' "$content" > "$repo/$path"
    git_fixture_git "$repo" add -- "$path" || return 1
  done

  local message="$subject"
  if [ -n "$trailers" ]; then
    message="$subject"$'\n\n'"$trailers"
  fi

  # Derive the timestamp from how many commits already exist, so the clock never
  # enters the fixture and the same recipe yields the same SHAs every run.
  local existing
  existing=$(git_fixture_git "$repo" rev-list --count HEAD 2>/dev/null || echo 0)
  local stamp="@$((_GIT_FIXTURE_EPOCH + existing * 60)) +0000"

  GIT_AUTHOR_DATE="$stamp" GIT_COMMITTER_DATE="$stamp" \
    git_fixture_git "$repo" commit -q -m "$message" || return 1
}

# Create a branch and switch to it. Works on an unborn HEAD too, so a fixture can name
# its first branch before it has any commits.
# Usage: git_fixture_branch <repo> feature/AUTH-123
git_fixture_branch() {
  local repo="$1"
  local name="$2"
  git_fixture_git "$repo" checkout -q -b "$name"
}

# Switch to an existing branch.
git_fixture_checkout() {
  local repo="$1"
  local name="$2"
  git_fixture_git "$repo" checkout -q "$name"
}

# Remove a single fixture repository.
#
# The prefix check is textual, so `..` is rejected outright: a path like
# "$GIT_FIXTURE_ROOT/../elsewhere" starts with the root and points outside it, and this
# function ends in `rm -rf`.
git_fixture_destroy() {
  local repo="$1"
  case "$repo" in
    *..*)
      echo "git_fixture_destroy: refusing a path containing '..': $repo" >&2
      return 1
      ;;
    "$GIT_FIXTURE_ROOT"/*) rm -rf "$repo" ;;
    *)
      echo "git_fixture_destroy: refusing to remove a path outside the fixture root: $repo" >&2
      return 1
      ;;
  esac
}

# Remove every fixture repository built this run.
git_fixture_destroy_all() {
  rm -rf "$GIT_FIXTURE_ROOT"
}

# Count the fixture repositories currently on disk. Used by tests that need a positive
# control before asserting an absence — "nothing left behind" is satisfied equally by a
# clean teardown and by a helper that never created anything.
git_fixture_count() {
  if [ ! -d "$GIT_FIXTURE_ROOT" ]; then
    echo 0
    return 0
  fi
  find "$GIT_FIXTURE_ROOT" -mindepth 2 -maxdepth 2 -type d -name .git 2>/dev/null | wc -l | tr -d ' '
}
