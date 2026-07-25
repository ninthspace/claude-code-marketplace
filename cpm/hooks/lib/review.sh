#!/bin/bash
# review.sh — The change-set review: what the model is given, and what it may hand back
#
# Spec 42 R5: produce findings with `file:line` citations, scoped to a change set rather
# than a path. That scoping is the entire distinction from `/cpm:audit`, which orients on
# `git log --oneline -200` plus six months of churn and pins to `git rev-parse HEAD` — so
# it cannot answer "review what this epic changed", and running it per-epic re-audits
# untouched code and drowns the real findings.
#
# **Nothing in this file reviews anything.** The review is model-driven and lives in the
# skill; what lives here is the deterministic scaffolding around it — which files are in
# scope and in what order, what payload is handed in, and whether what comes back is
# well-formed. All three are checkable, and none of them has an opinion about code.
#
# The split is not incidental. Every claim this file makes can be tested; no claim the
# review itself makes can be. Keeping them in separate places is what stops a green suite
# from reading as though the review had been verified.
#
# --- AD3, and the one distinction it is easy to get wrong --------------------------------
#
# "The review consumes the join's **data**, never its **labels**." This file is the only
# place in the system where that could be violated: the join *produces* confidence labels
# and, until now, nothing consumed them. So the boundary is enforced at the point where
# data crosses into the model's context, by construction — `review_payload` drops field 4
# of every LINK record, and there is no code path that carries it through.
#
# The reason is not squeamishness about a string. `declared` and `derived` are the join's
# *judgements*, and confidence is the one thing in this system with no oracle — no test can
# decide whether "epic 41-03 owns this file" is true. A model told that a link is
# `declared` will weight it, and it will be weighting a guess dressed as a fact. Told only
# that the link exists, it can weigh the underlying evidence itself.
#
# **A criterion's `verified` state is not a confidence label and is deliberately kept.**
# The vocabulary that AD3 excludes is declared / derived / absent — the join's assessment
# of how well it knows something. `verified` / `unverified` is a claim the *plan* makes
# about itself, which is data about the work under review and precisely what R4's gap query
# is built on. Conflating the two would strip the review of the thing it most needs.

REVIEW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! declare -f linkset_links >/dev/null 2>&1; then
  # shellcheck source=./linkset.sh
  source "$REVIEW_DIR/linkset.sh"
fi

REVIEW_TAB="$CHANGESET_TAB"

# The confidence vocabulary AD3 keeps out of the review's context. Named once, here, so the
# payload builder and the test that polices it cannot drift apart by editing one list.
REVIEW_FORBIDDEN_LABELS="declared derived absent"

# --- The payload -------------------------------------------------------------------------
#
# Read a resolved link set on stdin; print what the review is given.
#
#   review_payload <changeset-file>
#
#   FILE<TAB><path>                                  every file in the change set
#   FILEINTENT<TAB><path><TAB><intent-id>            which intents point at it, no confidence
#   INTENT<TAB><id><TAB><status><TAB><title>
#   CRITERION<TAB><intent-id><TAB><state><TAB><text>
#
# A file with no FILEINTENT lines is one nothing resolved. The review sees that as an
# absence — which is what it is — rather than as a label reading `absent`. Same fact, and
# the difference is that one of them is the join's word and the other is the reader's own
# inference from the data.
review_payload() {
  local changeset_file="$1"

  if [ -z "$changeset_file" ] || [ ! -f "$changeset_file" ]; then
    echo "review: no such change set file: $changeset_file" >&2
    return 1
  fi

  LC_ALL=C awk -F'\t' -v cs="$changeset_file" '
    BEGIN {
      while ((getline line < cs) > 0) {
        n = split(line, f, "\t")
        if (n >= 2 && f[1] == "FILE" && f[2] != "" && !(f[2] in seen)) {
          seen[f[2]] = 1
          order[++count] = f[2]
        }
      }
      close(cs)
    }

    # Field 4 is the confidence. It is read here only to be discarded, and the record is
    # rebuilt from fields 2 and 3 rather than reprinted — so a LINK record gaining a fifth
    # field later cannot smuggle anything through.
    $1 == "LINK" && ($2 in seen) {
      key = $2 "\t" $3
      if (!(key in emitted)) { emitted[key] = 1; fi[$2] = fi[$2] key "\n" }
      next
    }

    $1 == "INTENT"    { intents[++ni] = $2 "\t" $3 "\t" $4; next }
    $1 == "CRITERION" { crits[++nc]   = $2 "\t" $3 "\t" $4; next }

    END {
      for (i = 1; i <= count; i++) {
        p = order[i]
        printf "FILE\t%s\n", p
        if (p in fi) {
          n = split(fi[p], lines, "\n")
          for (j = 1; j <= n; j++)
            if (lines[j] != "") printf "FILEINTENT\t%s\n", lines[j]
        }
      }
      for (i = 1; i <= ni; i++) printf "INTENT\t%s\n", intents[i]
      for (i = 1; i <= nc; i++) printf "CRITERION\t%s\n", crits[i]
    }
  '
}

# --- Findings ------------------------------------------------------------------------------
#
# What the review hands back:
#
#   FINDING<TAB><path><TAB><line><TAB><text>
#
# `path` and `line` together are R5's `file:line` citation. They are two fields rather than
# one string because a Windows-style path contains a colon and splitting on the last one is
# the kind of rule that works until it does not.
review_emit_finding() {
  printf 'FINDING%s%s%s%s%s%s\n' \
    "$REVIEW_TAB" "$1" "$REVIEW_TAB" "$2" "$REVIEW_TAB" "$3"
}

# Read findings on stdin; print one diagnostic per malformed finding and exit 1 if any.
#
#   review_validate_findings <changeset-file>
#
# Four rules, and the last is the one that matters most:
#
#   * every record is a FINDING with four fields
#   * the citation names a file and a positive line number
#   * the text is not empty
#   * **the cited file is in the change set**
#
# The last is R1's scoping made enforceable. A review that cites a file outside the change
# set has stopped being a change-set review and become an audit, which is the tool CPM
# already has and the one this exists because of. Reported rather than filtered, for the
# same reason the join reports contract violations rather than dropping them: a quietly
# shorter findings list reads as a clean review.
review_validate_findings() {
  local changeset_file="$1"

  if [ -z "$changeset_file" ] || [ ! -f "$changeset_file" ]; then
    echo "review: no such change set file: $changeset_file" >&2
    return 1
  fi

  local bad
  bad=$(LC_ALL=C awk -F'\t' -v cs="$changeset_file" '
    BEGIN {
      while ((getline line < cs) > 0) {
        n = split(line, f, "\t")
        if (n >= 2 && f[1] == "FILE") known[f[2]] = 1
      }
      close(cs)
    }

    $0 == "" { next }

    $1 != "FINDING" {
      printf "NOT A FINDING RECORD: %s\n", $0
      next
    }

    NF != 4 {
      printf "FINDING NEEDS path, line AND text: %s\n", $0
      next
    }

    $2 == "" {
      printf "FINDING WITH NO FILE: %s\n", $0
      next
    }

    $3 !~ /^[0-9]+$/ || $3 + 0 < 1 {
      printf "FINDING WITH NO USABLE LINE NUMBER (%s): %s\n", $3, $2
      next
    }

    $4 == "" {
      printf "FINDING WITH NO TEXT: %s:%s\n", $2, $3
      next
    }

    !($2 in known) {
      printf "FINDING CITES A FILE OUTSIDE THE CHANGE SET: %s:%s\n", $2, $3
      next
    }
  ')

  [ -z "$bad" ] && return 0

  printf '%s\n' "$bad"
  return 1
}

# The findings as a human reads them, one per line: `path:line  text`.
review_render_findings() {
  LC_ALL=C awk -F'\t' '$1 == "FINDING" { printf "%s:%s  %s\n", $2, $3, $4 }'
}

# --- Scope selection and disclosure ---------------------------------------------------------
#
# The NFR: "the tool reviews what fits — prioritised by provenance signal, orphans first —
# and **prints an explicit list of the files it did not examine**."
#
# The disclosure is the requirement, not a courtesy attached to it. A review that silently
# samples reads as *clean* when it means *unexamined*, and the larger the change set the
# more confident that silence sounds. Refusing outright would be better than that; listing
# what was skipped is better than refusing.
#
# --- Prioritisation, and why availability is detected rather than assumed --------------------
#
# Orphans first when the gap queries are available, a deterministic file order when they are
# not. Both branches are real: Epic 42-04 is deliberately not blocked by 42-03, so this must
# work with no gap queries in the process at all, and "available" therefore means *this shell
# has them* rather than *they exist somewhere*.
#
# Detecting it through `declare -f` rather than a configuration flag is what keeps the two
# branches honest. A flag would be a thing a test sets and nothing else ever does; the
# function's presence is the same condition a real caller creates by sourcing (or not
# sourcing) `gap-queries.sh`.
_review_orphans_available() {
  declare -f gap_orphans >/dev/null 2>&1
}

# Read a link set on stdin; decide what fits and disclose what does not.
#
#   review_select <changeset-file> <budget>
#
#   ORDER<TAB>orphans-first|deterministic
#   EXAMINED<TAB><path>            zero or more, in review order
#   UNEXAMINED<TAB><path>          zero or more, in review order
#   COVERAGE<TAB><examined><TAB><total>
#   COMPLETE<TAB>yes|no
#
# The budget is a parameter, never a constant. What fits in one pass depends on the model,
# the files and the day, and a number compiled into this file would be wrong for every
# caller in a different way — and untestable besides, since a suite cannot construct a
# change set that overflows a limit it cannot name.
review_select() {
  local changeset_file="$1"
  local budget="$2"

  if [ -z "$changeset_file" ] || [ ! -f "$changeset_file" ]; then
    echo "review: no such change set file: $changeset_file" >&2
    return 1
  fi

  case "$budget" in
    '' | *[!0-9]* )
      echo "review: budget must be a whole number of files, got: $budget" >&2
      return 1
      ;;
  esac

  local records order files
  records=$(cat)
  files=$(changeset_files < "$changeset_file" | grep -v '^$')

  if _review_orphans_available; then
    order="orphans-first"
    # Orphans in change-set order, then everything else in change-set order. Stable within
    # each group, so the result is fully determined by the change set and the link set —
    # the priority reorders, it never randomises.
    local orphans
    orphans=$(printf '%s\n' "$records" | gap_orphans "$changeset_file") || return 1
    files=$(
      printf '%s\n' "$orphans" | grep -v '^$'
      LC_ALL=C comm -23 <(printf '%s\n' "$files" | LC_ALL=C sort) \
                        <(printf '%s\n' "$orphans" | grep -v '^$' | LC_ALL=C sort)
    )
  else
    order="deterministic"
  fi

  local total examined
  total=$(printf '%s\n' "$files" | grep -c '[^[:space:]]') || true
  total=${total:-0}
  examined=$total
  [ "$budget" -lt "$total" ] && examined="$budget"

  printf 'ORDER\t%s\n' "$order"

  printf '%s\n' "$files" | LC_ALL=C awk -v n="$examined" '
    $0 == "" { next }
    { printf "%s\t%s\n", (++i <= n ? "EXAMINED" : "UNEXAMINED"), $0 }
  '

  printf 'COVERAGE\t%s\t%s\n' "$examined" "$total"
  printf 'COMPLETE\t%s\n' "$([ "$examined" -ge "$total" ] && echo yes || echo no)"
}

# The coverage statement a human reads, from the records above on stdin.
#
# A partial review names every file it did not reach. Not a count, not a sample — the
# criterion says "listed explicitly", and a count is exactly the shape of disclosure that
# lets a reader move on without checking.
review_render_coverage() {
  local records
  records=$(cat)

  LC_ALL=C awk -F'\t' '
    $1 == "COVERAGE" { examined = $2; total = $3 }
    $1 == "COMPLETE" { complete = ($2 == "yes") }
    $1 == "UNEXAMINED" { skipped[++n] = $2 }
    END {
      if (total + 0 == 0) { print "no files in the change set"; exit }
      if (complete) {
        printf "reviewed all %d file(s) in the change set\n", total
        exit
      }
      printf "PARTIAL REVIEW - examined %d of %d file(s). Not examined:\n", examined, total
      for (i = 1; i <= n; i++) printf "  %s\n", skipped[i]
    }
  ' <<INNER
$records
INNER
}
