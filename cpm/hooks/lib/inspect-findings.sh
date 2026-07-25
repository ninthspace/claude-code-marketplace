#!/bin/bash
# inspect-findings.sh — Persist the review's findings beside the record
#
# Spec 42 R5 produces findings; nothing in Epics 42-01 to 42-05 wrote them anywhere. They
# were rendered into the conversation by `review_render_findings` and died with the shell.
# This is where they become durable.
#
# --- Why they are not in the record ---------------------------------------------------
#
# R6 requires `docs/inspect/<slug>.json` to be byte-identical across runs of the same
# selector, and that determinism is the whole basis of the run-to-run delta: a diff between
# two records is a change in the work, never a change in the weather. Findings are produced
# by a model reading code. Two runs over an identical tree will phrase them differently,
# order them differently, and legitimately disagree about how many there are. Putting them
# in the record would mean every record differed from every other for reasons that have
# nothing to do with the repository, which is the one thing R6 exists to prevent.
#
# So they go in a sidecar, following the precedent `inspect_sidecar_write` already set for
# the published URL — same problem, same shape, same reason. The record stays the record;
# this file stays honest about being something else.
#
# --- Why Markdown rather than JSON -----------------------------------------------------
#
# The record is the machine-readable half and already exists. What was missing is a form a
# person can open six months later without the tool that wrote it, in the repository where
# the work happened. A second JSON file would have added durability and no readability.
#
# It round-trips anyway — `inspect_findings_read` returns the same `FINDING` records
# `review.sh` emits — so a page composed from this file gets structure, not prose it has to
# re-parse. Readable and parseable were not in tension here; they would have been if the
# citation had been written the obvious way (see below).
#
# --- The citation format, and the colon ------------------------------------------------
#
#   - **`path/to/file.sh`** line 42 — the finding text
#
# R5 calls for `file:line`, and `review_render_findings` prints exactly that for a human
# reading the terminal. This file deliberately does *not*, because it has to read its own
# output back. `review.sh` keeps path and line as separate fields for a stated reason — "a
# Windows-style path contains a colon and splitting on the last one is the kind of rule that
# works until it does not" — and writing `path:line` here would re-introduce precisely that
# rule at the parse step. The path is delimited by backticks and the line number is a
# separate token, so neither has to be recovered by guessing where the other ended.
#
# The one parsing rule worth stating: the text begins after the *first* ` — `, so a finding
# whose text contains that sequence survives intact.

INSPECT_FINDINGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! declare -f inspect_slug >/dev/null 2>&1; then
  # shellcheck source=./inspect-record.sh
  source "$INSPECT_FINDINGS_DIR/inspect-record.sh"
fi

INSPECT_FINDINGS_TAB=$(printf '\t')

# The findings sidecar path for a slug, relative to the repository root.
#   inspect_findings_path <slug>
inspect_findings_path() {
  local slug="$1"

  if [ -z "$slug" ]; then
    echo "inspect-findings: no slug given" >&2
    return 1
  fi

  printf 'docs/inspect/%s.findings.md\n' "$slug"
}

# Write the findings sidecar and print its path, relative to the repository root.
#   inspect_findings_write <repo> <selector> < FINDING records
#
# The slug is computed from the selector by `inspect_slug`, never accepted as an argument,
# so this file and the record it sits beside cannot end up named for different runs.
inspect_findings_write() {
  local repo="$1"
  local selector="$2"

  if [ -z "$repo" ] || [ ! -d "$repo" ]; then
    echo "inspect-findings: no such repository directory: $repo" >&2
    return 1
  fi

  if [ -z "$selector" ]; then
    echo "inspect-findings: no selector given" >&2
    return 1
  fi

  local slug
  slug=$(inspect_slug "$selector") || return 1
  if [ -z "$slug" ]; then
    echo "inspect-findings: selector yields no usable slug: $selector" >&2
    return 1
  fi

  local rel
  rel=$(inspect_findings_path "$slug") || return 1

  local records
  records=$(cat)

  # A run that found nothing writes the file anyway, saying so in words. The alternative is
  # an absent file, which is indistinguishable from a run that was never done — and "no
  # findings" and "not reviewed" are the same distinction R4 draws between "none found" and
  # "not answerable", for the same reason.
  local count
  count=$(printf '%s\n' "$records" | grep -c '^FINDING'"$INSPECT_FINDINGS_TAB" || true)

  mkdir -p "$repo/docs/inspect" || return 1

  {
    printf '# Review findings for `%s`\n\n' "$selector"
    printf '**Record**: `docs/inspect/%s.json`\n\n' "$slug"
    printf 'The record is the durable, byte-stable half of this run. These findings are not:\n'
    printf 'they are a reading of the code at a point in time, and a later run may reasonably\n'
    printf 'reach different ones. That is why they live here rather than in the record.\n\n'

    if [ "$count" -eq 0 ]; then
      printf 'No findings. The review ran and reported nothing — this is not the same as the\n'
      printf 'review not having run, which would leave no file here at all.\n'
    else
      printf '## Findings (%s)\n\n' "$count"
      printf '%s\n' "$records" | LC_ALL=C awk -F'\t' '
        $1 == "FINDING" { printf "- **`%s`** line %s — %s\n", $2, $3, $4 }
      '
    fi
  } > "$repo/$rel" || return 1

  printf '%s\n' "$rel"
}

# Read a findings sidecar back as `FINDING` records — the same shape `review.sh` emits, so
# anything that consumes the review's output consumes this identically.
#   inspect_findings_read <path>
inspect_findings_read() {
  local file="$1"

  if [ -z "$file" ] || [ ! -f "$file" ]; then
    echo "inspect-findings: no such findings file: $file" >&2
    return 1
  fi

  LC_ALL=C awk '
    # Anchored on the whole bullet shape rather than on "starts with a dash", so prose that
    # happens to be written as a list cannot be read back as a finding.
    /^- \*\*`.*`\*\* line [0-9]+ — / {
      line = $0

      p1 = index(line, "`")
      rest = substr(line, p1 + 1)
      p2 = index(rest, "`")
      path = substr(rest, 1, p2 - 1)

      after = substr(rest, p2 + 1)
      sub(/^\*\* line /, "", after)

      sp = index(after, " ")
      lineno = substr(after, 1, sp - 1)

      # The text starts after the FIRST separator, so a finding containing one keeps it.
      sep = index(after, " — ")
      text = substr(after, sep + length(" — "))

      printf "FINDING\t%s\t%s\t%s\n", path, lineno, text
    }
  ' "$file"
}
