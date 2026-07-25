#!/bin/bash
# linkset.sh — The link-set structure produced by every intent adapter
#
# Spec 42 R7: the join "reads every intent channel present and **owns none of them**".
# `changeset.sh` is what changed; this is why. An adapter is handed a change set and
# returns a link set — the reverse direction of R2 (files → intent), and the pluggable
# seam AD2 depends on.
#
# It is settled before either adapter is written, for the same reason `changeset.sh` was
# settled before either resolver: the gap queries (Epic 42-03), the JSON record (Story 5)
# and the artifact page (Epic 42-05) are written once against this shape, which only
# holds if the git-native adapter and the CPM adapter emit the identical structure. The
# deferred issue-tracker adapters (Jira, GitHub, Linear) must be addable against it
# without reopening it.
#
# --- Record format --------------------------------------------------------------
#
# One record per line, tab-delimited, four fields:
#
#   INTENT<TAB><id><TAB><status><TAB><title>
#   CRITERION<TAB><intent-id><TAB><state><TAB><text>
#   LINK<TAB><path><TAB><intent-id><TAB><confidence>
#
#   status     : done | open | unknown
#   state      : verified | unverified
#   confidence : declared | derived
#
# Normalised order is INTENT, then CRITERION, then LINK; within each type, sorted under
# LC_ALL=C and deduplicated.
#
# --- Why the three record types, and not fewer -------------------------------------
#
# `changeset.sh` warns against inventing a field ahead of a caller, so each is named
# against the requirement that needs it:
#
# **INTENT** is the record R3's orphan query counts against: a file in the change set
# with no LINK is an orphan. `title` is carried because Story 5's JSON and Epic 42-05's
# page need a display label and the adapter is the only thing that knows it — deriving it
# at render time would mean re-reading the epic doc, which contradicts R6's "the JSON is
# the record".
#
# **CRITERION** is what makes R4's unbacked-claims query answerable: "intent records
# marked done or verified with no test naming them" needs the claim and its state, not
# just the record. It is emitted only by adapters that carry verification claims — the
# git-native adapter emits none, because commit trailers and branch names record *why* a
# change happened and never record a verification claim. That asymmetry is the reason the
# contract carries `exit 2` (see linkset-join.sh).
#
# **LINK** is the join's whole output: (file, intent, confidence).
#
# --- Why `absent` is not a confidence value here ------------------------------------
#
# R7 names three labels — declared, derived, absent — but an adapter can only ever claim
# the first two. `absent` means "no adapter resolves it; the file is an orphan", which is
# a fact about the *join's* whole result, not a claim any single adapter is in a position
# to make: an adapter that emitted `absent` would be asserting something about the
# adapters that ran beside it. The join synthesises it. `linkset_validate` rejects it, and
# the conformance harness proves the rejection.
#
# --- Determinism ------------------------------------------------------------------
#
# Every sort pins LC_ALL=C, for the reason `changeset.sh` gives: `sort` honours the
# caller's locale by default, so the same repository would otherwise produce different
# bytes on two machines. R6 requires byte-identical JSON across runs, and that property
# has to hold here first — the serialiser cannot recover an ordering the join lost.

CHANGESET_LINKSET_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$CHANGESET_TAB" ]; then
  # shellcheck source=./changeset.sh
  source "$CHANGESET_LINKSET_DIR/changeset.sh"
fi

LINKSET_TAB="$CHANGESET_TAB"

# --- Emitters -----------------------------------------------------------------------

# linkset_emit_intent <id> <status> <title>
linkset_emit_intent() {
  printf 'INTENT%s%s%s%s%s%s\n' \
    "$LINKSET_TAB" "$1" "$LINKSET_TAB" "$2" "$LINKSET_TAB" "$3"
}

# linkset_emit_criterion <intent-id> <state> <text>
linkset_emit_criterion() {
  printf 'CRITERION%s%s%s%s%s%s\n' \
    "$LINKSET_TAB" "$1" "$LINKSET_TAB" "$2" "$LINKSET_TAB" "$3"
}

# linkset_emit_link <path> <intent-id> <confidence>
linkset_emit_link() {
  printf 'LINK%s%s%s%s%s%s\n' \
    "$LINKSET_TAB" "$1" "$LINKSET_TAB" "$2" "$LINKSET_TAB" "$3"
}

# --- Accessors ------------------------------------------------------------------------

# Each prints the records of one type from a link set on stdin, in record order, with the
# type field stripped.

linkset_intents() {
  awk -F'\t' '$1 == "INTENT" { print $2 "\t" $3 "\t" $4 }'
}

linkset_criteria() {
  awk -F'\t' '$1 == "CRITERION" { print $2 "\t" $3 "\t" $4 }'
}

linkset_links() {
  awk -F'\t' '$1 == "LINK" { print $2 "\t" $3 "\t" $4 }'
}

# Print the intent IDs named by INTENT records, one per line, in record order.
linkset_intent_ids() {
  awk -F'\t' '$1 == "INTENT" { print $2 }'
}

# Print the file paths named by LINK records, one per line, in record order.
linkset_linked_files() {
  awk -F'\t' '$1 == "LINK" { print $2 }'
}

# Print the record counts, tab-delimited, as "intents<TAB>criteria<TAB>links".
linkset_counts() {
  awk -F'\t' '
    $1 == "INTENT"    { i++ }
    $1 == "CRITERION" { c++ }
    $1 == "LINK"      { l++ }
    END { printf "%d\t%d\t%d\n", i, c, l }
  '
}

# --- Normalisation ---------------------------------------------------------------------

# Deduplicate and order a link set on stdin: INTENT, then CRITERION, then LINK, each
# block sorted under LC_ALL=C.
#
# Ordering lives here rather than in each adapter for the same reason commit ordering
# lives in changeset-intent.sh rather than in each intent adapter: an adapter's internal
# ordering must not be able to reach the structure, or R6's byte-identical requirement
# becomes a property of how every adapter happens to iterate.
linkset_normalise() {
  local input
  input=$(cat)

  local type
  for type in INTENT CRITERION LINK; do
    printf '%s\n' "$input" | awk -F'\t' -v t="$type" '$1 == t' | LC_ALL=C sort -u
  done
}

# --- Validation --------------------------------------------------------------------------

# Validate a link set on stdin. Prints one line per offending record and returns 1 if any
# are found, 0 otherwise. Silence means the structure holds.
#
# This is the contract between adapters written in different stories by different authors,
# so it checks the enums rather than only the shape: a typo'd confidence value would
# otherwise flow into the JSON record and out to the page, where nothing would catch it.
linkset_validate() {
  awk -F'\t' '
    NF != 4 {
      printf "MALFORMED (expected 4 tab-separated fields): %s\n", $0
      bad = 1
      next
    }
    $1 != "INTENT" && $1 != "CRITERION" && $1 != "LINK" {
      printf "UNKNOWN RECORD TYPE: %s\n", $1
      bad = 1
      next
    }
    $2 == "" {
      printf "EMPTY IDENTIFIER in %s record\n", $1
      bad = 1
      next
    }
    $1 == "INTENT" && $3 != "done" && $3 != "open" && $3 != "unknown" {
      printf "UNKNOWN INTENT STATUS: %s\n", $3
      bad = 1
      next
    }
    $1 == "CRITERION" && $3 != "verified" && $3 != "unverified" {
      printf "UNKNOWN CRITERION STATE: %s\n", $3
      bad = 1
      next
    }
    $1 == "LINK" && $3 == "" {
      printf "EMPTY INTENT ID in LINK record for: %s\n", $2
      bad = 1
      next
    }
    # `absent` is deliberately named in the diagnostic rather than folded into the
    # generic unknown-confidence case below: it is the plausible mistake, being one of
    # the three labels R7 lists, so an adapter author who reaches for it is told why not.
    # (No apostrophes in this awk program — it is single-quoted in shell.)
    $1 == "LINK" && $4 == "absent" {
      printf "ADAPTER CLAIMED absent (only the join may label a file absent): %s\n", $2
      bad = 1
      next
    }
    $1 == "LINK" && $4 != "declared" && $4 != "derived" {
      printf "UNKNOWN CONFIDENCE: %s\n", $4
      bad = 1
      next
    }
    END { exit bad ? 1 : 0 }
  '
}
