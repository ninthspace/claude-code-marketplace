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
#   coverage_spec_scope_deferrals <spec-path>
#       LABEL, one per line, for every requirement label named in a bullet under the
#       spec's `## Scope` → `### Deferred` or `### Out of Scope` heading.
#   coverage_matrix_rows <matrix-path>
#       KIND<TAB>BASE<TAB>LABEL<TAB>SPEC_TEXT<TAB>COVERED_BY<TAB>VERIFIED<TAB>TAG, one record
#       per data row of the matrix's coverage table.
#   coverage_base_label <label>
#       The base requirement a possibly-qualified label refers to.
#   coverage_environmental_class <label>
#       `requirement` for an `ENVn` label, `restriction` for an `ENVXn` label, empty for
#       anything else. The single definition of the environmental class (spec 46, AD2).
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

# The requirement label a bullet opens with: uppercase letters then digits — `FR1`,
# `NFR10`. Empty when the bullet does not open with one, which is how a bold prose bullet
# is told apart from a requirement without a list of known prefixes to keep in step.
function cov_leading_label(s) {
  s = cov_trim(s)
  if (match(s, /^[A-Z]+[0-9]+/)) return substr(s, 1, RLENGTH)
  return ""
}

# The two halves of a label, for the one place that has to compare labels arithmetically:
# deciding whether `C1–C5` names a range. Everywhere else compares labels as exact strings,
# and these exist so that the range rule cannot be written by pulling a label apart a second
# way somewhere else.
function cov_label_prefix(s) {
  if (match(s, /^[A-Z]+/)) return substr(s, 1, RLENGTH)
  return ""
}

function cov_label_number(s) {
  if (match(s, /[0-9]+$/)) return substr(s, RSTART) + 0
  return -1
}

# Whether the text following a leading label contains a second label token. This is what
# tells a descriptive suffix apart from a label naming more than one requirement:
# `FR7 — Pence-exact remainder rule` carries prose, `ENV1–ENV5` and `ENV9, ENV10, ENV11`
# carry further labels.
#
# Tokens are accumulated by `index` into a character set rather than matched by a regex over
# the whole string, for the reason the scope scanner gives at length: the character either
# side of a label can be one byte of a multibyte dash, and handing that to a regex is what
# makes this awk abort with a conversion failure. Every byte outside the set simply ends the
# current token, so a dash of any width is a separator without being recognised as one.
#
# The completed token is offered to cov_leading_label and kept only when it matches in full,
# so the `[A-Z]+[0-9]+` grammar stays stated in one place. By then the token holds nothing but
# ASCII uppercase and digits, so no multibyte byte can reach that regex.
function cov_has_further_label(s,   i, c, tok) {
  tok = ""
  s = s " "
  for (i = 1; i <= length(s); i++) {
    c = substr(s, i, 1)
    if (index("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", c) > 0) {
      tok = tok c
      continue
    }
    if (tok != "" && cov_leading_label(tok) == tok) return 1
    tok = ""
  }
  return 0
}

# The base requirement a label refers to, or the empty string when there is not exactly one.
#
# Three shapes resolve. A bare `FR7` is itself. A qualified `FR1 (must NOT)` drops the
# qualifier. A label carrying a descriptive tail — `FR7 — Pence-exact remainder rule`, the
# form a coverage matrix is most likely to be written with — resolves to the code, because
# the tail describes the requirement rather than naming another one.
#
# A label naming **more than one** requirement resolves to nothing. `ENV1–ENV5` is the case
# that forces this: reducing it to `ENV1` would trace one requirement and silently drop four
# while a row on disk claims to cover all five, which is worse than not resolving at all
# because it fails invisibly. Comma and `and` lists refuse for the same reason. A matrix
# carries one row per requirement, so a label that names several is malformed and the roll-up
# reports it as unresolved rather than guessing which one was meant.
#
# A label with no leading code is returned unchanged. Story-originated rows are named in
# prose and have no requirement behind them, and the caller decides what that means.
#
# The result is an exact string, and every comparison against it downstream is string
# equality. Nothing here or later matches on a prefix, which is what keeps `FR10` from
# being read as `FR1`.
function cov_base_label(label,   n, p, lead) {
  label = cov_trim(label)
  n = length(label)
  if (n == 0) return ""
  if (substr(label, 1, 1) == "(") return ""
  if (substr(label, n, 1) == ")") {
    p = cov_rindex(label, " (")
    if (p > 1) {
      label = cov_trim(substr(label, 1, p - 1))
      n = length(label)
    }
  }

  lead = cov_leading_label(label)
  if (lead == "") return label
  if (lead == label) return label
  if (cov_has_further_label(substr(label, length(lead) + 1))) return ""
  return lead
}

# Whether a label names an environmental constraint, and which of the two classes it is.
# `ENV1` is an environmental requirement — something that must be available. `ENVX1` is a
# restriction — something that must not be required. Anything else returns the empty
# string, including labels that merely start with those letters.
#
# **The one definition.** Spec 46 AD2 requires that `coverage-rollup.sh` and `cpm:epics`
# decide "is this environmental" from a single place, because two copies will drift. This
# is that place: the roll-up prepends this library to its own awk program and calls the
# function, and epic 46-03 asserts that the prose in `cpm:epics` names the same two
# prefixes.
#
# **Prefix equality, not a prefix match.** The rule stated at the top of this file is that
# nothing matches on a prefix, which is what keeps `FR10` from being read as `FR1`. So the
# alpha prefix is extracted by `cov_label_prefix` and compared as an exact string. A regex
# such as `/^ENV[0-9]+/` would classify correctly today and be the very thing that rule
# forbids — and `ENVIRONMENT1`, a valid label under the `[A-Z]+[0-9]+` grammar of AD1, is
# the case that tells the two implementations apart.
#
# A bare `ENV` with no digits classifies as a requirement, and that is deliberate rather
# than overlooked. It is not a label at all under the grammar — `cov_leading_label` will
# not produce one — so no caller can reach here with it. Re-checking for digits would state
# the `[A-Z]+[0-9]+` grammar a second time, in a second place, which is the drift this
# function exists to prevent.
#
# Note for anyone editing the comments in this library: it is one single-quoted shell
# string, so a lone apostrophe closes it and every awk function after that point silently
# disappears. Write around it rather than escaping it.
#
# The same holds for every awk program below, each of which is single-quoted the same way.
# One possessive in one of their comments ends the quoting mid-program, and what happens
# next depends on what follows: a backtick or a `$` becomes a shell syntax error, anything
# else is accepted and mangles the program. Only the loud half announces itself, so the rule
# is the same everywhere in this file — no apostrophes inside an awk program, comments
# included. Write the possessive the long way round.
function cov_environmental_class(s,   p) {
  p = cov_label_prefix(cov_trim(s))
  if (p == "ENVX") return "restriction"
  if (p == "ENV")  return "requirement"
  return ""
}

# The boolean form, delegating rather than restating, so the two prefixes appear once.
function cov_is_environmental(s) {
  return cov_environmental_class(s) != ""
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

# Classify a single label as an environmental constraint.
#
# Usage: coverage_environmental_class "ENV1"          →  requirement
#        coverage_environmental_class "ENVX1"         →  restriction
#        coverage_environmental_class "ENVIRONMENT1"  →  (empty)
coverage_environmental_class() {
  printf '%s\n' "$1" | awk "$_COVERAGE_AWK_LIB"'{ print cov_environmental_class($0) }'
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

# Emit one label per requirement the spec's Scope section defers or rules out.
#
# Usage: coverage_spec_scope_deferrals docs/specifications/45-spec-delivery-autonomy.md
# Emits: LABEL, one per line, in first-appearance order, deduplicated.
#
# Returns 1 without emitting anything when the spec cannot be read. A spec with no `## Scope`
# section, or with one that names no labels, emits nothing and succeeds — that is the common
# case, not an error.
#
# --- Why this function exists at all --------------------------------------------
#
# `cpm:spec`'s output template says "not this iteration" in two places: the MoSCoW
# `### Won't Have (this iteration)` heading in its requirements section, and `### Deferred` /
# `### Out of Scope` under `## Scope`. Only the first was ever read, so a spec that deferred a
# Should Have the second way left it counted as untraced forever — and `cpm:ralph`'s spec mode
# reads a non-zero untraced count as "phase 1 unfinished", so the loop never advanced.
#
# --- What counts as naming a requirement ----------------------------------------
#
# A **bullet that leads with its labels**: `- S1, S2 and S5 — useful, but not needed yet`.
# Reading stops at the first text that is not a separator, so labels appearing later in the
# sentence are not read.
#
# That rule is not fussiness, it is the difference between deferring and mentioning. Spec 45's
# own Deferred section reads *"Nothing. FR12 was the one candidate for deferral … NFR6 forbids
# duplication"* — a bullet that names two requirements while saying neither was deferred. A
# scanner that read every label in the bullet excluded NFR6 and quietly shrank that spec's
# requirement count from 19 to 18. A bullet that opens with prose is prose.
#
# Separators between labels are a comma, `and`, `&`, `/`, or a dash; a leading fragment ending
# in `:` is allowed, so `- Deferred: S1, S2` reads the same as `- S1, S2`.
#
# Adjacent labels separated by nothing but a dash are a **range**: `C1–C5` names C1, C2, C3,
# C4 and C5. Hyphen, en dash and em dash all count, because all three occur in written specs
# and a reader means the same thing by each. A range whose ends disagree on prefix, or that
# runs backwards, is not a range — both ends are still emitted individually.
#
# The *decision* is not made here. This reports what the section names; the roll-up excludes
# only labels that are also real requirements in the spec's own list, and never excludes a
# Must Have on the strength of a Scope bullet.
coverage_spec_scope_deferrals() {
  local spec="$1"

  _coverage_require_readable coverage_spec_scope_deferrals spec "$spec" || return 1

  CPM_MD_SCOPE_HEADING='## Scope' \
  CPM_MD_DEFERRED='Deferred' \
  CPM_MD_OUT_OF_SCOPE='Out of Scope' \
  CPM_MD_EN_DASH='–' \
  CPM_MD_EM_DASH='—' \
  awk "$_COVERAGE_AWK_LIB"'
    BEGIN {
      SCOPE_HEADING = ENVIRON["CPM_MD_SCOPE_HEADING"]
      DEFERRED = ENVIRON["CPM_MD_DEFERRED"]
      OUT_OF_SCOPE = ENVIRON["CPM_MD_OUT_OF_SCOPE"]
      EN_DASH = ENVIRON["CPM_MD_EN_DASH"]
      EM_DASH = ENVIRON["CPM_MD_EM_DASH"]
      UPPER = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
      LOWER = "abcdefghijklmnopqrstuvwxyz"
      DIGITS = "0123456789"
      in_scope = 0
      in_defer = 0
      in_fence = 0
    }

    # The three dashes reach awk through ENVIRON for the same reason every other pattern in
    # this file does: the multibyte ones are compared as whole strings, so no assumption is
    # made about what this awk counts as a character.
    function is_dash(s) {
      s = cov_trim(s)
      return (s == "-" || s == EN_DASH || s == EM_DASH)
    }

    # Character tests by `index` into a set, never by a regex class. The character either
    # side of a label token can be a single *byte* of a multibyte dash, and handing that to
    # a regex is what makes this awk abort with a multibyte conversion failure — the same
    # hazard the file header describes, met from the other direction. `index` compares
    # strings, so a stray continuation byte simply is not in the set.
    function is_wordch(c) {
      if (c == "") return 0
      return index(UPPER LOWER DIGITS, c) > 0
    }

    function is_alpha(c) {
      if (c == "") return 0
      return index(UPPER LOWER, c) > 0
    }

    # Text between two labels that keeps the list going rather than ending it. Spaces and
    # commas are dropped first, so ", " and " and " and " , and " all reduce to the same
    # three answers.
    function is_separator(s,   g, i, c) {
      g = ""
      for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == " " || c == ",") continue
        g = g c
      }
      if (g == "") return 1
      if (g == "and" || g == "&" || g == "/" || g == "or") return 1
      return is_dash(g)
    }

    # Whether a bullet opens with its labels. Empty leading text does; so does a short
    # lead-in ending in a colon (`Deferred: S1, S2`). Anything else is a sentence that
    # happens to contain a label, which is not the same as a deferral.
    function leads(s) {
      s = cov_trim(s)
      if (s == "") return 1
      return (substr(s, length(s), 1) == ":")
    }

    function emit(label) {
      if (label in seen) return
      seen[label] = 1
      print label
    }

    /^```/ { in_fence = !in_fence; next }
    in_fence { next }

    /^## / {
      in_scope = (index($0, SCOPE_HEADING) == 1)
      in_defer = 0
      next
    }

    /^### / {
      if (!in_scope) { in_defer = 0; next }
      h = cov_trim(substr($0, 5))
      in_defer = (index(h, DEFERRED) == 1 || index(h, OUT_OF_SCOPE) == 1)
      next
    }

    {
      if (!in_scope || !in_defer) next

      line = cov_trim($0)
      if (substr(line, 1, 2) != "- ") next
      rest = substr(line, 3)

      # Collect the label tokens in this bullet along with the text that preceded each one,
      # so the range rule can ask what sits *between* two labels rather than re-scan the line.
      ntok = 0
      for (z in tok) delete tok[z]
      for (z in gap) delete gap[z]
      while (match(rest, /[A-Z]+[0-9]+/)) {
        lab = substr(rest, RSTART, RLENGTH)
        before = (RSTART > 1) ? substr(rest, RSTART - 1, 1) : ""
        after = substr(rest, RSTART + RLENGTH, 1)
        # A token welded to a word on either side is part of that word, not a label.
        if (!is_wordch(before) && !is_alpha(after)) {
          ntok++
          tok[ntok] = lab
          gap[ntok] = substr(rest, 1, RSTART - 1)
        }
        rest = substr(rest, RSTART + RLENGTH)
      }

      # Walk from the front while the list holds together, and stop at the first prose.
      for (i = 1; i <= ntok; i++) {
        if (i == 1) {
          if (!leads(gap[1])) break
        } else if (!is_separator(gap[i])) {
          break
        }

        emit(tok[i])
        if (i == ntok) continue
        if (!is_dash(gap[i + 1])) continue

        p = cov_label_prefix(tok[i])
        if (p == "" || p != cov_label_prefix(tok[i + 1])) continue

        from = cov_label_number(tok[i])
        to = cov_label_number(tok[i + 1])
        if (from < 0 || to <= from) continue

        for (k = from + 1; k < to; k++) emit(p k)
      }
    }
  ' "$spec"
}

# Emit one record per data row of a coverage matrix's table.
#
# Usage: coverage_matrix_rows docs/epics/44-01-coverage-coverage-rollup-script.md
# Emits: KIND<TAB>BASE<TAB>LABEL<TAB>SPEC_TEXT<TAB>COVERED_BY<TAB>VERIFIED<TAB>TAG
#
#   KIND     — `requirement` or `story-originated`
#   BASE     — the label with any qualifier resolved away (empty for story-originated)
#   LABEL    — column 2, verbatim
#   SPEC_TEXT— column 3, verbatim
#   COVERED_BY — column 5, verbatim
#   VERIFIED — `verified` or `unverified`
#   TAG      — column 6: the test approach the spec assigned, backticks stripped, or empty
#
# `✓` is the only value read as verified. Anything else in that cell — a note, a tick of
# a different codepoint, a stray word — reads as unverified, so a cell nobody meant as
# proof cannot become proof.
#
# --- Why the tag is extracted rather than left in the document ------------------
#
# `[target]` and `[manual]` are the two tags whose ticks rest on something other than a
# test having run: one on a human's judgement, the other on an environment nobody here
# has. Left unextracted they are invisible to every consumer, so a row ticked on a human
# verdict counts as ordinary verification and a reader is told only that the matrix is
# green. The tag is reported verbatim rather than classified here — what a tag *means* is
# a policy question, answered where the records are read, for the same reason the MoSCoW
# heading travels with the label rather than being resolved in the parser.
#
# It is emitted last because every existing consumer indexes positionally, and appending
# leaves those indices where they are. A field inserted mid-record shifts everything after
# it and each consumer keeps parsing without complaint.
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
      # Backticks are how the column renders a tag, not part of it. Stripping them is the
      # same normalisation `verified` gets from `✓`: a consumer comparing against `[target]`
      # would otherwise have to know the markup of the cell, and the one that forgets
      # matches nothing and reports every row as untagged.
      tag = $7
      gsub(/`/, "", tag)
      tag = cov_trim(tag)
      verified_cell = cov_trim($8)

      kind = "requirement"
      if (index(label, "(story-originated)") > 0 || spec_text == DASH) {
        kind = "story-originated"
      }

      base = (kind == "story-originated") ? "" : cov_base_label(label)
      verified = (verified_cell == TICK) ? "verified" : "unverified"

      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", kind, base, label, spec_text, covered_by, verified, tag
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
