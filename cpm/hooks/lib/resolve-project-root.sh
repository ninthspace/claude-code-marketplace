#!/bin/bash
# resolve-project-root.sh — Shared project-root resolution for CPM helpers
#
# $CLAUDE_PROJECT_DIR is set for hooks, because Claude Code spawns them. It is
# NOT set for the Bash calls a /cpm:* skill issues, so helpers that built their
# paths from "$CLAUDE_PROJECT_DIR/..." alone silently addressed "/docs/plans"
# and "/.claude/ralph-loop.local.md" whenever a skill invoked them. Both paths
# exist on no machine, so the guard could never see an active ralph loop and
# /cpm:clean could never see a progress file — for months, with no error.
#
# This file is the single implementation both helpers draw on. Keeping it in
# one place is what makes "the guard and the classifier resolve identically"
# true by construction rather than by two copies staying in step.
#
# Usage:
#   source "${0%/*}/resolve-project-root.sh"
#   cpm_resolve_project_root "my-label" || { ...degraded path... }
#   # on success $CPM_PROJECT_ROOT holds the resolved, validated root
#
# Resolution order: $CLAUDE_PROJECT_DIR -> git rev-parse --show-toplevel -> $PWD.
# The first non-empty candidate wins; it is then validated as an existing
# directory. A candidate that fails validation is a failure, not a reason to try
# the next source — a CLAUDE_PROJECT_DIR pointing somewhere that does not exist
# means the environment is wrong, and guessing past it would hide that.
#
# Every outcome, degraded or not, is reported on stderr. Callers emit their
# results on stdout, so the diagnostic never contaminates what they parse.
#
# `git` is the only non-builtin used, its stderr is suppressed, and its failure
# is expected rather than exceptional — outside a work tree resolution reaches
# $PWD, a shell builtin, so the chain completes with no external binary at all.
# Nothing here reads, writes, moves, or deletes a file.

cpm_resolve_project_root() {
  local label="${1:-cpm}"
  local candidate="" origin=""

  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    candidate="$CLAUDE_PROJECT_DIR"
    origin="CLAUDE_PROJECT_DIR"
  else
    candidate=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$candidate" ]; then
      origin="git rev-parse --show-toplevel"
    else
      candidate="$PWD"
      origin="PWD"
    fi
  fi

  if [ -n "$candidate" ] && [ -d "$candidate" ]; then
    CPM_PROJECT_ROOT="$candidate"
    echo "$label: project root $candidate (via $origin)" >&2
    return 0
  fi

  CPM_PROJECT_ROOT=""
  echo "$label: cannot resolve a project root — tried CLAUDE_PROJECT_DIR, then git rev-parse --show-toplevel, then PWD; candidate from $origin was '$candidate', which is not an existing directory" >&2
  return 1
}
