#!/bin/bash
# make-coverage-baseline.sh — Epic 46-01 Task 1.1: the pre-change record baseline.
#
# Runs `coverage-rollup.sh --spec` over every spec in the repository and writes one line
# per emitted record, keyed by the spec's basename and the run's exit code:
#
#   <spec-basename>\t<exit>\t<record line>
#
# NFR1 asks that a spec written before spec 46's change produces the same records
# afterwards. That is a diff, and a diff needs a "before" — which can only be taken while
# the "before" still exists. Running this after `coverage-rollup.sh` changes would compare
# the change to itself and pass unconditionally.
#
# **Both directories, deliberately.** Spec 46's NFR1 says "all 45 existing specs in
# `docs/specifications/`". That directory holds 7; the other 39 are in
# `docs/archive/specifications/`. A baseline over the live directory alone covers 7 of 46
# and would report clean while the rest regressed. The spec's clause was corrected during
# work breakdown; this script is what the corrected wording describes.
#
# **Why the exit code is in the key rather than dropped.** An archived spec has no matrix
# under `docs/epics/`, so the roll-up emits nothing and exits 1 — `EXIT_NO_MATRIX` is
# deliberately mapped to 1 on the non-`--verdict` path (`coverage-rollup.sh:606`, spec 45's
# AD2 containment), so 1 here is the documented no-matrix result and not a crash. For those
# specs the exit code is the *only* observable, and a baseline that recorded records alone
# would be 39 identical empty entries — satisfied by a script that had stopped working.
#
# **stdout only, stderr deliberately discarded.** The roll-up's stderr names the resolved
# project root as an absolute path, which would pin this baseline to one machine's
# filesystem. NFR1 asks about the records and the count; those are on stdout.
#
# Output is sorted so the diff is line-oriented and order-independent: the roll-up's
# emission order is deterministic today, but this baseline is about the records, not the
# order they arrive in.
#
# --- Two modes, because the records answer two different questions ---------------
#
# By default only `REQ` and `EXCLUDED` records are emitted, plus the `<no records>` entries.
# Those three depend on the **spec document** alone — which requirements it carries, and
# which it ruled out — so they are a function of the parser and nothing else. That is what
# NFR1 actually claims: *a spec written before this change produces the same `REQ` set
# afterwards*. A fixture built from them stays true for as long as the parser behaves, and
# fails the moment it does not.
#
# `--all` additionally emits `STATE`, `SUMMARY`, `ROW`, `MATRIX` and `CRITERION`. Those
# depend on **matrix contents**, which move as work proceeds: ticking one `✓` in a coverage
# matrix takes a requirement from `in-progress` to `delivered` and changes the `SUMMARY`
# line of the spec it belongs to. Committing them would make the fixture measure the
# repository's work in progress as well as the parser, and every epic worked in this repo
# would break it in a way indistinguishable from a regression.
#
# So `--all` is for a **within-change** comparison — capture, change something, capture
# again, diff — which is the only setting where a moving record is informative. Epic 46-01
# Task 3.1 used it exactly that way: 45 of the 46 specs came back byte-identical across all
# record types, and the 46th was spec 46, whose own coverage matrix the epic was editing.
#
# Usage:
#   bash cpm/hooks/tests/make-coverage-baseline.sh > cpm/hooks/tests/fixtures/coverage-baseline-46.tsv
#   bash cpm/hooks/tests/make-coverage-baseline.sh --all > /tmp/before.tsv   # within-change diff

set -u

EMIT_ALL=no
for arg in "$@"; do
  case "$arg" in
    --all) EMIT_ALL=yes ;;
    *)
      echo "make-coverage-baseline.sh: unrecognised argument: $arg" >&2
      echo "usage: make-coverage-baseline.sh [--all]" >&2
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

ROLLUP="$REPO_ROOT/cpm/hooks/lib/coverage-rollup.sh"

if [[ ! -f "$ROLLUP" ]]; then
  echo "make-coverage-baseline.sh: cannot find coverage-rollup.sh at $ROLLUP" >&2
  exit 1
fi

specs=()
for dir in "$REPO_ROOT/docs/specifications" "$REPO_ROOT/docs/archive/specifications"; do
  [[ -d "$dir" ]] || continue
  for spec in "$dir"/*.md; do
    [[ -f "$spec" ]] && specs+=("$spec")
  done
done

if [[ ${#specs[@]} -eq 0 ]]; then
  echo "make-coverage-baseline.sh: no specs found under $REPO_ROOT/docs" >&2
  exit 1
fi

for spec in "${specs[@]}"; do
  base="${spec##*/}"
  output=$( cd "$REPO_ROOT" && bash "$ROLLUP" --spec "$spec" 2>/dev/null )
  code=$?

  if [[ -z "$output" ]]; then
    # An exit-code-only entry. Named rather than omitted, so a spec that stops emitting
    # records is a changed line rather than a vanished one.
    printf '%s\t%d\t<no records>\n' "$base" "$code"
    continue
  fi

  # Filtering on the record type, which is field 1 of every record (spec 44, NFR4), rather
  # than on the text of the line. A record type is the contract; the text is not.
  kept=$( printf '%s\n' "$output" \
    | awk -F'\t' -v all="$EMIT_ALL" 'all == "yes" || $1 == "REQ" || $1 == "EXCLUDED"' )

  if [[ -z "$kept" ]]; then
    # The spec produced records, but none of the durable kinds — a spec carrying no
    # requirement bullets at all. Given its own marker rather than left out, for the same
    # reason as `<no records>` above and with a different word so the two cases stay
    # distinguishable in a diff.
    printf '%s\t%d\t<no durable records>\n' "$base" "$code"
    continue
  fi

  printf '%s\n' "$kept" | while IFS= read -r line; do
    printf '%s\t%d\t%s\n' "$base" "$code" "$line"
  done
done | LC_ALL=C sort
