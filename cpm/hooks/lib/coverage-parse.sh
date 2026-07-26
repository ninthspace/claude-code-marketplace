#!/bin/bash
# coverage-parse.sh — Extraction primitives for the spec-level coverage roll-up.
#
# Reads the two document shapes the roll-up compares: a spec's requirement list, and a
# coverage matrix's rows. Nothing here decides anything — no states, no untraced set, no
# exit codes. Extraction is separated from judgement so the parsing can be exercised on
# its own, and so Story 3's record emission has one place to get its inputs from.
#
# Sourced, not executed: `. lib/coverage-parse.sh`. Strictly read-only.
#
# Provided functions:
#   coverage_spec_requirements <spec-path>
#       LABEL<TAB>MOSCOW<TAB>TEXT, one record per `- **FRn** — text` bullet under a
#       MoSCoW heading in the spec's Functional Requirements section.
#   coverage_matrix_rows <matrix-path>
#       KIND<TAB>BASE<TAB>LABEL<TAB>SPEC_TEXT<TAB>COVERED_BY<TAB>VERIFIED, one record per
#       data row of the matrix's coverage table.
#   coverage_base_label <label>
#       The base requirement a possibly-qualified label refers to.
#   coverage_matrix_source_spec <matrix-path>
#       The `**Source spec**` a matrix names, or empty when the field is absent.
#   coverage_is_matrix_name <basename>
#       Whether a filename is a coverage matrix's, by the epic filename convention.
#
# --- Why the MoSCoW heading travels with the label ------------------------------
#
# A Won't Have entry is a requirement the spec has explicitly ruled out, so it will never
# have a matrix row — and reporting it as untraced would be reporting the spec working as
# intended. Rather than drop those bullets here, extraction stays faithful to the document
# and carries the heading each label appeared under. What a heading *means* is a policy
# question, and it is answered once, where the states are derived, instead of being
# smuggled into the parser as a silent omission.
#
# --- Why patterns go through ENVIRON --------------------------------------------
#
# Every pattern in this file that contains `**` reaches awk through `ENVIRON[...]`, never
# `awk -v`. `awk -v` applies escape processing to its value, so `\*\*` arrives collapsed
# to `**` and a pattern built that way silently matches nothing — a failure invisible in
# the pattern itself (retro 21). ENVIRON does no such processing, and the extraction is
# written with `index`/`substr` against a plain string rather than as a regex at all,
# which sidesteps the class entirely.

# --- Shared awk helpers ---------------------------------------------------------
#
# Held in one variable and prepended to every awk program in this file, so a label is
# resolved to its base requirement by exactly one piece of code. Two copies — one for
# single labels and one for matrix rows — would be two chances for `FR10` to start
# matching `FR1`, and only one of them would be under test.
_COVERAGE_AWK_LIB='
function cov_trim(s) {
  while (substr(s, 1, 1) == " ") { s = substr(s, 2) }
  while (length(s) > 0 && substr(s, length(s), 1) == " ") { s = substr(s, 1, length(s) - 1) }
  return s
}

# Position of the last occurrence of t in s, or 0. awk has no rindex.
function cov_rindex(s, t,   i, p, last) {
  last = 0
  i = 1
  while (1) {
    p = index(substr(s, i), t)
    if (p == 0) break
    last = i + p - 1
    i = last + 1
  }
  return last
}

# The base requirement a label refers to. `FR1 (must NOT)` and `FR6 (cross-site)` resolve
# to `FR1` and `FR6`; a label that is nothing but a qualifier — `(story-originated)` —
# resolves to the empty string, because there is no requirement behind it.
#
# The result is an exact string, and every comparison against it downstream is string
# equality. Nothing here or later matches on a prefix, which is what keeps `FR10` from
# being read as `FR1`.
# The requirement label a bullet opens with: uppercase letters then digits — `FR1`,
# `NFR10`. Empty when the bullet does not open with one, which is how a bold prose bullet
# is told apart from a requirement without a list of known prefixes to keep in step.
function cov_leading_label(s) {
  s = cov_trim(s)
  if (match(s, /^[A-Z]+[0-9]+/)) return substr(s, 1, RLENGTH)
  return ""
}

function cov_base_label(label,   n, p) {
  label = cov_trim(label)
  n = length(label)
  if (n == 0) return ""
  if (substr(label, 1, 1) == "(") return ""
  if (substr(label, n, 1) == ")") {
    p = cov_rindex(label, " (")
    if (p > 1) return cov_trim(substr(label, 1, p - 1))
  }
  return label
}
'

# Reject a path this library cannot read, naming the caller and the file.
#
# Both extractors guard their input the same way, and NFR2 requires every failure path to
# name what could not be read — so the naming lives in one place rather than being restated
# at each call site, where one of the two copies could drift into a silent return.
#
# Usage: _coverage_require_readable coverage_spec_requirements spec "$path" || return 1
_coverage_require_readable() {
  local fn="$1" noun="$2" path="$3"

  if [ -z "$path" ]; then
    echo "$fn: no $noun path given" >&2
    return 1
  fi
  if [ ! -r "$path" ]; then
    echo "$fn: cannot read $noun: $path" >&2
    return 1
  fi
  return 0
}

# Resolve a single label to its base requirement.
#
# Usage: coverage_base_label "FR1 (must NOT)"   →  FR1
#        coverage_base_label "(story-originated)" →  (empty)
coverage_base_label() {
  printf '%s\n' "$1" | awk "$_COVERAGE_AWK_LIB"'{ print cov_base_label($0) }'
}

# Emit one record per requirement bullet in a spec's Functional Requirements section.
#
# Usage: coverage_spec_requirements docs/specifications/44-spec-coverage-rollup.md
# Emits: LABEL<TAB>MOSCOW<TAB>TEXT   (e.g. "FR1<TAB>Must Have<TAB>A script under…")
#
# Returns 1 without emitting anything when the spec cannot be read. The caller decides
# what that means; this function only reports that it could not do its job.
#
# Fence-aware: a fenced code block inside the requirements section may legitimately show
# an example bullet, and an example is not a requirement.
coverage_spec_requirements() {
  local spec="$1"

  _coverage_require_readable coverage_spec_requirements spec "$spec" || return 1

  CPM_MD_BOLD='**' \
  CPM_MD_FR_HEADING='## Functional Requirements' \
  CPM_MD_NFR_HEADING='## Non-Functional Requirements' \
  CPM_MD_NFR_SECTION='Non-Functional' \
  awk "$_COVERAGE_AWK_LIB"'
    BEGIN {
      BOLD = ENVIRON["CPM_MD_BOLD"]
      FR_HEADING = ENVIRON["CPM_MD_FR_HEADING"]
      NFR_HEADING = ENVIRON["CPM_MD_NFR_HEADING"]
      NFR_SECTION = ENVIRON["CPM_MD_NFR_SECTION"]
      BULLET = "- " BOLD
      DASH = "—"
      in_req = 0
      in_fence = 0
      heading = ""
    }

    /^```/ { in_fence = !in_fence; next }
    in_fence { next }

    # A new second-level section opens a requirement block or closes one. The
    # non-functional section carries no MoSCoW subheadings, so its bullets take the
    # section name as their heading rather than an empty one — every record carries a
    # heading, and a consumer never has to know which section it came from to read it.
    /^## / {
      if (index($0, NFR_HEADING) == 1) {
        in_req = 1
        heading = NFR_SECTION
      } else if (index($0, FR_HEADING) == 1) {
        in_req = 1
        heading = ""
      } else {
        in_req = 0
        heading = ""
      }
      next
    }

    /^### / {
      if (in_req) { heading = substr($0, 5) }
      next
    }

    {
      if (!in_req) next
      if (substr($0, 1, length(BULLET)) != BULLET) next

      span = substr($0, length(BULLET) + 1)
      close_at = index(span, BOLD)
      if (close_at == 0) next

      # Reassemble the bullet with only its *opening* bold markers removed. Where the
      # label sits inside the span varies between specs — `**FR1** — text`,
      # `**NFR1 — Read-only.** text` and `**NFR5 Net reduction** in text` all occur — so
      # the label is read from the front of the reassembled line instead of from the span,
      # and one rule covers all three. Removing every `**` on the line would be simpler and
      # wrong: emphasis inside a requirement is part of its text, and the matrices quote
      # that text verbatim.
      rest = substr(span, close_at + length(BOLD))
      body = substr(span, 1, close_at - 1) rest

      label = cov_leading_label(body)
      if (label == "") next

      text = cov_trim(substr(body, length(label) + 1))
      # Trim the separator by string comparison rather than a regex, so a multibyte em
      # dash is measured in whatever unit this awk uses for both length() and substr().
      if (substr(text, 1, length(DASH)) == DASH) { text = substr(text, length(DASH) + 1) }
      text = cov_trim(text)

      printf "%s\t%s\t%s\n", label, heading, text
    }
  ' "$spec"
}

# Emit one record per data row of a coverage matrix's table.
#
# Usage: coverage_matrix_rows docs/epics/44-01-coverage-coverage-rollup-script.md
# Emits: KIND<TAB>BASE<TAB>LABEL<TAB>SPEC_TEXT<TAB>COVERED_BY<TAB>VERIFIED
#
#   KIND     — `requirement` or `story-originated`
#   BASE     — the label with any qualifier resolved away (empty for story-originated)
#   LABEL    — column 2, verbatim
#   SPEC_TEXT— column 3, verbatim
#   COVERED_BY — column 5, verbatim
#   VERIFIED — `verified` or `unverified`
#
# `✓` is the only value read as verified. Anything else in that cell — a note, a tick of
# a different codepoint, a stray word — reads as unverified, so a cell nobody meant as
# proof cannot become proof.
#
# A row is `story-originated` when its label carries the `(story-originated)` qualifier
# *or* its spec text is `—`. Either signal alone is enough: a row with no spec text has no
# requirement behind it whatever its label says, and CPM's matrices carry both markers
# together precisely because they mean the same thing. Such rows still emit — they are
# reported separately, not dropped — but they carry no BASE, so nothing downstream can
# count one toward a requirement's state.
#
# Returns 1 without emitting anything when the matrix cannot be read.
#
# Fence-aware: a matrix's Notes section may quote an example row.
coverage_matrix_rows() {
  local matrix="$1"

  _coverage_require_readable coverage_matrix_rows matrix "$matrix" || return 1

  awk "$_COVERAGE_AWK_LIB"'
    BEGIN {
      FS = "|"
      TICK = "✓"
      DASH = "—"
      in_fence = 0
    }

    /^```/ { in_fence = !in_fence; next }
    in_fence { next }

    {
      # A leading pipe makes $1 empty, so the table columns are $2..$8. The header row
      # ($2 is "#") and the separator ($2 is dashes) both fail the numeric test below,
      # which is what distinguishes a data row without pinning the header text.
      if (NF < 8) next

      num = cov_trim($2)
      if (num !~ /^[0-9]+$/) next

      label = cov_trim($3)
      spec_text = cov_trim($4)
      covered_by = cov_trim($6)
      verified_cell = cov_trim($8)

      kind = "requirement"
      if (index(label, "(story-originated)") > 0 || spec_text == DASH) {
        kind = "story-originated"
      }

      base = (kind == "story-originated") ? "" : cov_base_label(label)
      verified = (verified_cell == TICK) ? "verified" : "unverified"

      printf "%s\t%s\t%s\t%s\t%s\t%s\n", kind, base, label, spec_text, covered_by, verified
    }
  ' "$matrix"
}

# The `**Source spec**` a matrix names — the field's value with surrounding space removed
# and nothing else changed. Empty when the field is absent: a matrix without one belongs to
# no spec, and spec-scoped discovery simply will not match it.
coverage_matrix_source_spec() {
  grep -m1 '^\*\*Source spec\*\*:' "$1" 2>/dev/null |
    sed -e 's/^\*\*Source spec\*\*:[[:space:]]*//' -e 's/[[:space:]]*$//'
}

# True when a basename is a coverage matrix's, by the epic filename convention:
# `{parent}-coverage-{slug}.md` (legacy flat) or `{parent}-{seq}-coverage-{slug}.md`.
#
# The obvious test — does the name contain `-coverage-` — is wrong, and wrong on this very
# spec: `44-01-epic-coverage-rollup-script.md` is an *epic* whose slug happens to begin
# with "coverage". Epic docs carry a `**Source spec**` field too, so a name test that lets
# one through is not caught by the field match either; it reports the epic's own rows twice
# over. What distinguishes a matrix is that `-coverage-` follows the numeric prefix and
# nothing else.
coverage_is_matrix_name() {
  local base="$1" prefix="${1%%-coverage-*}"

  [ "$prefix" != "$base" ] || return 1        # no `-coverage-` anywhere
  case "$prefix" in
    [0-9]*) : ;;
    *) return 1 ;;                            # must start with the number
  esac
  case "$prefix" in
    *[!0-9-]*) return 1 ;;                    # digits and hyphens only
    *-) return 1 ;;                           # a trailing hyphen means an empty field
    *-*-*) return 1 ;;                        # at most {parent}-{seq}
  esac
  return 0
}
