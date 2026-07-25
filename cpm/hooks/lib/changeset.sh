#!/bin/bash
# changeset.sh — The change-set structure produced by both resolution directions
#
# Spec 42 R1 says an intent-anchored selector and a git-anchored selector "both resolve
# to one change-set structure: a set of commits and a set of files". AD5 adds that the
# two directions "converge on one change-set structure before the join runs". This file
# is that structure: the record format, the accessors, and the validator.
#
# It is deliberately settled before either direction is implemented. Forward resolution
# (Story 3) and reverse resolution (Story 2) are opposite traversals of the same graph,
# and the whole point of converging early is that the join, the gap queries and the
# review are written once — which only holds if both directions emit the identical
# shape, byte for byte.
#
# --- Record format --------------------------------------------------------------
#
# One record per line, tab-delimited, two fields:
#
#   COMMIT<TAB><40-character sha>
#   FILE<TAB><repository-relative path>
#
# COMMIT records come first, in `git rev-list` order — newest first. FILE records
# follow, sorted under LC_ALL=C and deduplicated. A change set may legitimately have
# zero COMMIT records: the working-tree selector describes changes that are not
# committed yet.
#
# Two sets, and only two. The file-to-commit association that AD2's co-commit signal
# depends on is not carried here, because it is recoverable from the commit set at any
# point and the spec defines the structure as two sets. An adapter in Epic 42-02 that
# needs the association reads it from git rather than from a field this file invented
# ahead of a caller.
#
# --- Why tab-delimited rather than JSON ------------------------------------------
#
# R6's deterministic JSON document is the *record the join emits*, one layer up. This
# is the intermediate both resolvers produce and the join consumes, and it matches the
# house format already used by `progress-classify.sh` — line-oriented, tab-delimited,
# readable by `cut`/`awk`/`grep` without a parser. Emitting JSON here would put a second
# serialisation between the resolvers and the join for no gain.
#
# --- Determinism ------------------------------------------------------------------
#
# Every sort in this file pins LC_ALL=C. `sort` honours the caller's locale by default,
# so the same repository and the same selector would otherwise produce different byte
# output on two machines — which is exactly the property R6 needs and the run-to-run
# delta depends on.

CHANGESET_TAB=$'\t'

# Emit a COMMIT record.
changeset_emit_commit() {
  printf 'COMMIT%s%s\n' "$CHANGESET_TAB" "$1"
}

# Emit FILE records from paths on stdin, sorted and deduplicated.
# Usage: printf '%s\n' "$paths" | changeset_emit_files
changeset_emit_files() {
  LC_ALL=C sort -u | while IFS= read -r path; do
    [ -n "$path" ] || continue
    printf 'FILE%s%s\n' "$CHANGESET_TAB" "$path"
  done
}

# Print the commit SHAs from a change set on stdin, in record order.
changeset_commits() {
  awk -F'\t' '$1 == "COMMIT" { print $2 }'
}

# Print the file paths from a change set on stdin, in record order.
changeset_files() {
  awk -F'\t' '$1 == "FILE" { print $2 }'
}

# Print the number of COMMIT and FILE records, tab-delimited, as "commits<TAB>files".
changeset_counts() {
  awk -F'\t' '
    $1 == "COMMIT" { c++ }
    $1 == "FILE"   { f++ }
    END { printf "%d\t%d\n", c, f }
  '
}

# Validate a change set on stdin. Prints one line per offending record and returns 1 if
# any are found, 0 otherwise. Silence means the structure holds.
#
# A validator earns its place here because this shape is a contract between two
# resolvers written in different stories: without it, "both directions produce the same
# structure" is asserted only by whichever assertions each story happened to write.
changeset_validate() {
  awk -F'\t' '
    NF != 2 {
      printf "MALFORMED (expected 2 tab-separated fields): %s\n", $0
      bad = 1
      next
    }
    $1 != "COMMIT" && $1 != "FILE" {
      printf "UNKNOWN RECORD TYPE: %s\n", $1
      bad = 1
      next
    }
    $1 == "COMMIT" && $2 !~ /^[0-9a-f]{40}$/ {
      printf "NOT A FULL SHA: %s\n", $2
      bad = 1
      next
    }
    $1 == "FILE" && $2 == "" {
      printf "EMPTY FILE PATH\n"
      bad = 1
      next
    }
    END { exit bad ? 1 : 0 }
  '
}
