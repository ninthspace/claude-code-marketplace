#!/bin/bash
# gap-queries.sh — The two questions the join exists to answer
#
# Spec 42's case for building any of this rests on two queries, and the spec is explicit
# that rendering a diff is not one of them: "Rendering a diff is a mirror and earns
# nothing — git, GitHub and the IDE all do it better." What no diff and no epic doc can
# show is where the plan and the work came apart:
#
#   R3  ORPHAN CHANGES   files that changed with no acceptance criterion behind them,
#                        where unreviewed scope creep hides
#   R4  UNBACKED CLAIMS  criteria marked verified with no test naming them — the inverse
#                        gap, which `/cpm:do` structurally cannot catch because it
#                        self-assesses
#
# This file implements both, and `gap_report` runs them together as the one review a
# caller actually invokes. The three are not interchangeable: R3 answers from the absence
# of links, R4 answers only through an adapter carrying verification claims, and the
# combined report is where the difference between those two has to survive to a reader.
#
# What is *not* here is any judgement about the code itself. Epic 42-04's model-driven
# review consumes these findings; nothing in this file forms an opinion, and AD3's split
# is what keeps it that way.
#
# --- Why the orphan query reads links and not labels --------------------------------
#
# `linkset_labels` already computes a per-file label, and one of its three values is
# `absent` — which is, set-for-set, the orphan list. Reusing it would be the shorter
# route and it is deliberately not taken.
#
# AD3 draws a hard line: the review "consumes the join's **data**, never its **labels**".
# The line is drawn at the *stream*, not at each value in it — `absent` happens to be the
# one label that embeds no confidence judgement, so an orphan query reading it would not
# actually be inheriting an unverifiable claim. It would, though, be the first consumer to
# reach across the line, and AD3 is worth more as a rule with no exceptions than as one
# with a defensible first exception. The check is also mechanical this way: a query that
# never touches a LABEL record cannot come to depend on a confidence value later, and one
# that already reads the stream can.
#
# The two answers must nonetheless agree, and `test-gap-orphans.sh` asserts that they do.
# That assertion is a **regression net, not the guarantee** — the guarantee is that each
# is derived independently from the same LINK records, so a drift between them is a real
# defect rather than a cosmetic one.
#
# --- Presence, not strength ----------------------------------------------------------
#
# The must-NOT — "must NOT list a file as an orphan when any active adapter resolves it" —
# is the reason this file never inspects field 4 of a LINK record. A file with nothing but
# a *derived* link is not an orphan. It is weakly attributed, which is a different finding
# and belongs to whoever reads the confidence labels; R3 asks only whether anything at all
# points at the file.
#
# That distinction is worth stating because the wrong implementation passes the story's
# first criterion. "A file with no adapter link appears in the orphan list; a file with a
# declared link does not" is satisfied exactly as well by `orphan = not declared`, and the
# only case that separates the two readings is a file carrying a lone derived link.

GAP_QUERIES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! declare -f linkset_links >/dev/null 2>&1; then
  # shellcheck source=./linkset.sh
  source "$GAP_QUERIES_DIR/linkset.sh"
fi

# Read a resolved link set on stdin; print the path of every change-set file that no
# active adapter resolved, one per line, in change-set order.
#
#   gap_orphans <changeset-file>
#
# Change-set order rather than a fresh sort: `changeset.sh` already emits FILE records
# sorted and deduplicated, so preserving that order is both deterministic and free, and it
# keeps the orphan list lined up with the `files` array of the JSON record.
gap_orphans() {
  local changeset_file="$1"

  if [ -z "$changeset_file" ] || [ ! -f "$changeset_file" ]; then
    echo "gap-queries: no such change set file: $changeset_file" >&2
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

    # Field 4 is the confidence and is deliberately not consulted: any link at all
    # disqualifies a file from the orphan list, however weakly it was inferred.
    #
    # The `$2 in seen` guard means a LINK naming a file outside the change set cannot
    # affect the result. The join already rejects such a record as a contract violation,
    # so this is not a second line of defence against adapters — it is what makes the
    # query correct when it is handed a *narrower* change set than the one the links were
    # resolved against, which is an ordinary thing for a caller to do.
    $1 == "LINK" && ($2 in seen) { linked[$2] = 1 }

    END {
      for (i = 1; i <= count; i++)
        if (!(order[i] in linked)) print order[i]
    }
  '
}

# How many files the change set holds, and how many of them are orphans:
#
#   <orphans><TAB><total>
#
# Both numbers, never the count alone. "3 orphans" is unreadable without a denominator —
# 3 of 4 and 3 of 400 are different findings — and the caller that has to render R3 should
# not have to recompute the total from a second source to say so.
gap_orphan_counts() {
  local changeset_file="$1"

  local records total orphans
  records=$(cat)

  total=$(changeset_files < "$changeset_file" | grep -c '[^[:space:]]') || true
  orphans=$(printf '%s\n' "$records" | gap_orphans "$changeset_file" | grep -c '[^[:space:]]') || true

  printf '%s\t%s\n' "${orphans:-0}" "${total:-0}"
}

# --- R4: unbacked claims ---------------------------------------------------------------
#
# "Report intent records marked done or verified with no test naming them. This is the
# inverse gap, and the one `/cpm:do` structurally cannot catch because it self-assesses."
#
# A **claim** is an intent record that asserts the work is finished: status `done`, or
# carrying at least one criterion in state `verified`. Both, because the two say different
# things and R4 names both — a story marked Complete over an unverified row is exactly the
# shape the CPM adapter was built to surface.
#
# --- What counts as a test naming a claim ----------------------------------------------
#
# Settled at Story 2's gate, and the permissive of the available readings: **any mention
# of the intent ID inside a test file counts**, wherever in the file it appears. The
# alternative — parsing a leading header comment, the convention CPM-generated suites
# follow — was rejected because it only works where that convention holds, and R9 requires
# this to work in repositories that have never heard of CPM.
#
# The failure direction is worth stating plainly, because it is the unsafe one: a passing
# mention in an unrelated comment backs a claim that nothing actually tests, so **a real
# gap can go unreported**. The stricter reading fails the other way, listing genuinely
# tested claims and costing a reviewer time. Neither is free; this one was chosen for
# portability and the cost is recorded here rather than discovered later.
#
# --- Spelling ----------------------------------------------------------------------------
#
# Intent IDs are matched case-insensitively, because a test header writes "These back Epic
# 42-01 Story 1's ..." where the adapter emits `epic 42-01`.
#
# Story IDs get one extra spelling. The adapter emits `story 42-02.6`; the CPM header
# convention writes "Epic 42-02 Story 6", and a suite following it would otherwise back the
# epic and not the story. Without the alternate form every story-level claim in a
# CPM-generated repository would report unbacked, and R4's output would be noise rather
# than a finding. This normalises one documented convention and infers nothing: a
# repository spelling its stories some third way still reports them unbacked, which is the
# recoverable direction.
_gap_id_spellings() {
  local id="$1"
  printf '%s\n' "$id"
  case "$id" in
    story\ *.*)
      local rest="${id#story }"
      printf 'epic %s Story %s\n' "${rest%.*}" "${rest##*.}"
      ;;
  esac
}

# Paths this query is willing to treat as evidence. Deliberately broad — a repository that
# names its tests in a way this misses reports its claims as unbacked, which is the
# recoverable direction, and the pattern is a variable so a project can widen it.
GAP_TEST_PATH_PATTERN='(^|/)(tests?|spec|specs|__tests__)/|(^|/)test[-_][^/]*$|[-_.](test|spec)\.[A-Za-z0-9]+$|Test\.php$'

# Tracked test files, one per line, relative to the repository root.
#
# `git ls-files` rather than `find`: it is offline, and it respects the repository's own
# idea of what is tracked — so an untracked `node_modules` or build directory cannot
# contribute a vendored test that names an intent it knows nothing about. A repository that
# tracks its dependencies gets no such protection, and would want to narrow
# `GAP_TEST_PATH_PATTERN` instead.
#
# A path containing a newline arrives quoted from `git ls-files` and will not match the
# pattern, so the file is skipped. That costs evidence rather than inventing it: the effect
# is a claim reported unbacked, which is the recoverable direction.
_gap_test_files() {
  git -C "$1" ls-files 2>/dev/null | LC_ALL=C grep -E "$GAP_TEST_PATH_PATTERN"
}

# The intent records that assert completion. Reads a link set on stdin; prints one ID per
# line, sorted and deduplicated.
gap_claims() {
  LC_ALL=C awk -F'\t' '
    $1 == "INTENT"    && $3 == "done"     { claim[$2] = 1; next }
    $1 == "CRITERION" && $3 == "verified" { claim[$2] = 1; next }
    END { for (id in claim) print id }
  ' | LC_ALL=C sort -u
}

# Read a link set on stdin; print every claim no test names, one per line, sorted.
#   gap_unbacked <repo> <changeset-file>
#
# The change set is not consulted for evidence, and that is deliberate: a criterion
# verified three commits ago still has its test, and searching only the files this change
# set touched would report it unbacked every time the epic doc was edited afterwards. The
# claims come from the change set; the evidence may come from anywhere in the repository.
gap_unbacked() {
  local repo="$1"

  if [ -z "$repo" ] || [ ! -d "$repo" ]; then
    echo "gap-queries: no such repository directory: $repo" >&2
    return 1
  fi

  local claims
  claims=$(gap_claims)
  [ -n "$claims" ] || return 0

  local files corpus
  files=$(_gap_test_files "$repo")

  # No test files at all means nothing can back anything, and every claim is unbacked.
  # That is a finding, not an error — it is R4 working in a repository with no tests.
  if [ -z "$files" ]; then
    printf '%s\n' "$claims"
    return 0
  fi

  # Read the corpus once. One `grep` per claim over a concatenated copy beats re-reading
  # every test file per claim, and the worked example already runs to 31 intent records
  # against a suite of 34 files.
  corpus=$(mktemp) || return 1
  ( cd "$repo" && printf '%s\n' "$files" | tr '\n' '\0' | xargs -0 cat 2>/dev/null ) > "$corpus"

  local id spelling backed
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    backed=""
    while IFS= read -r spelling; do
      [ -n "$spelling" ] || continue
      if LC_ALL=C grep -qiF -- "$spelling" "$corpus"; then
        backed=1
        break
      fi
    done <<EOF
$(_gap_id_spellings "$id")
EOF
    [ -n "$backed" ] || printf '%s\n' "$id"
  done <<EOF
$claims
EOF

  rm -f "$corpus"
}

# --- R4's answerability half ---------------------------------------------------------
#
# The must-NOT: "must NOT report an empty unbacked list as 'none found' when the active
# adapters cannot answer the query — 'none found' and 'not answerable' must render
# differently."
#
# The asymmetry is real and it is not a rendering nicety. Commit trailers and branch names
# record *why* a change happened; they never record *and here is the criterion it
# satisfies, marked verified*. So R4 is answerable only through an adapter that carries
# verification claims — in this iteration, the CPM adapter alone. In a repository with no
# planning documents, "no unbacked claims" and "I cannot see any claims from here" are the
# same empty list and opposite findings, and the first is a lie told most confidently in
# exactly the repositories a reader would most trust it.
#
# --- The capability convention -----------------------------------------------------------
#
# An adapter may define an optional companion to its contract function:
#
#   foo_link_capabilities
#     stdout : zero or more capability tokens, one per line
#              `criteria` — this adapter can carry verification claims
#
# Absent means no capabilities, so every adapter written before this existed keeps working
# and answers R4 with "not from me". That is what makes this an addition to Epic 42-02's
# contract rather than a reopening of it: nothing an existing adapter does changes meaning.
_gap_claims_capable() {
  local name
  for name in $(linkset_adapters); do
    declare -f "${name}_link_capabilities" >/dev/null 2>&1 || continue
    "${name}_link_capabilities" 2>/dev/null | LC_ALL=C grep -qx 'criteria' && printf '%s\n' "$name"
  done
}

# Can the active adapters answer R4 here?
#   gap_r4_answerability <repo> <changeset-file>  →  answerable | unanswerable
#
# Capability is necessary and not sufficient: an adapter that *could* carry claims but
# found no channel in this repository (`exit 2`) cannot answer either. So the capable
# adapters are actually run, and only `exit 0` counts.
#
# **`exit 1` does not count as an answer.** Retro 20 found precisely this conflation in
# `changeset_intent_answerable` two epics before R4 existed to be defeated by it: an
# erroring adapter treated as having answered turns "not answerable" into "none found",
# which is the one outcome this criterion forbids. No criterion in this story names the
# error branch — the contract has three exit codes and the criteria name two — which is
# why it is asserted here rather than left to be discovered.
#
# The cost is one extra invocation of each capable adapter. Paid deliberately: the
# alternative is inferring answerability from whether any CRITERION record came back, and
# that cannot tell "answered, and this repository has no verified criteria" from "declined
# to answer" — which is the distinction the whole must-NOT is about.
gap_r4_answerability() {
  local repo="$1"
  local changeset_file="$2"

  local name rc
  for name in $(_gap_claims_capable); do
    "${name}_link_changeset" "$repo" "$changeset_file" >/dev/null 2>&1
    rc=$?
    [ "$rc" -eq 0 ] && { printf 'answerable\n'; return 0; }
  done

  printf 'unanswerable\n'
}

# Read a link set on stdin; print R4's finding as records.
#   gap_unbacked_report <repo> <changeset-file>
#
#   ANSWERABILITY<TAB>answerable|unanswerable
#   CLAIMS<TAB><unbacked-count><TAB><claim-total>
#   UNBACKED<TAB><intent-id>            zero or more
#
# The counts carry a denominator for the same reason `gap_orphan_counts` does: "0 unbacked"
# is unreadable without knowing whether 0 or 400 claims were examined, and R4's whole
# subject is the difference between finding nothing and having nothing to look at.
gap_unbacked_report() {
  local repo="$1"
  local changeset_file="$2"

  local records answerable claims unbacked
  records=$(cat)

  answerable=$(gap_r4_answerability "$repo" "$changeset_file")
  claims=$(printf '%s\n' "$records" | gap_claims | grep -c '[^[:space:]]') || true
  unbacked=$(printf '%s\n' "$records" | gap_unbacked "$repo") || return 1

  printf 'ANSWERABILITY\t%s\n' "$answerable"
  printf 'CLAIMS\t%s\t%s\n' "$(printf '%s\n' "$unbacked" | grep -c '[^[:space:]]')" "${claims:-0}"

  # `if` rather than `[ -n "$id" ] && printf`, and the difference is not style. With an
  # empty list, `printf '%s\n' ""` still emits one blank line, the guard fails on it, and
  # the `&&` leaves the loop — and therefore this function, and therefore `gap_report` —
  # exiting 1. A review that found nothing would report itself as having failed, which is
  # precisely what R9's must-NOT forbids.
  printf '%s\n' "$unbacked" | while IFS= read -r id; do
    if [ -n "$id" ]; then printf 'UNBACKED\t%s\n' "$id"; fi
  done
}

# One line a human reads, from the records above on stdin. This is where the must-NOT is
# actually discharged — the record shape keeps the two states apart, and this keeps them
# apart *on the page*, which is what the criterion asks for. Epics 42-04 and 42-05 may
# render it more elaborately; neither may collapse these two sentences into one.
gap_unbacked_render() {
  LC_ALL=C awk -F'\t' '
    $1 == "ANSWERABILITY" { answerable = ($2 == "answerable") }
    $1 == "CLAIMS"        { unbacked = $2; total = $3 }
    END {
      if (!answerable) {
        print "not answerable - no active adapter carries verification claims"
      } else if (unbacked + 0 == 0) {
        printf "no unbacked claims - all %d verified claim(s) are named by a test\n", total
      } else {
        printf "%d of %d verified claim(s) are named by no test\n", unbacked, total
      }
    }
  '
}

# --- R9: the whole review, however little it can say -------------------------------------
#
# "In a repository with no recognised intent source, the review still runs and every file
# is reported as an orphan. Absence of provenance is never a failure."
#
# The two queries in one record, so that a caller producing a review never has to run them
# separately and risk rendering one without the other:
#
#   ORPHANS<TAB><orphan-count><TAB><file-total>
#   ORPHAN<TAB><path>                     zero or more, in change-set order
#   ANSWERABILITY<TAB>answerable|unanswerable
#   CLAIMS<TAB><unbacked-count><TAB><claim-total>
#   UNBACKED<TAB><intent-id>              zero or more, sorted
#
# --- Why R3 has no answerability line and R4 does ----------------------------------------
#
# The asymmetry is deliberate and it is the whole of R9. With no adapter resolving
# anything, "every file is an orphan" is the *correct answer* to R3 — the spec says so in
# as many words — because an orphan is defined by the absence of a link, and absence is
# exactly what a silent channel establishes. R4 is the opposite: "no unbacked claims"
# asserts that claims were examined, and a channel that carries no claims has examined
# nothing. So R3 degrades into a finding and R4 degrades into a refusal, and a review that
# rendered them the same way would be wrong about one of them.
gap_report() {
  local repo="$1"
  local changeset_file="$2"

  if [ -z "$repo" ] || [ ! -d "$repo" ]; then
    echo "gap-queries: no such repository directory: $repo" >&2
    return 1
  fi

  if [ -z "$changeset_file" ] || [ ! -f "$changeset_file" ]; then
    echo "gap-queries: no such change set file: $changeset_file" >&2
    return 1
  fi

  # Read once. Every query below needs the same records, and a link set arrives on stdin
  # exactly once.
  local records
  records=$(cat)

  local orphans counts
  orphans=$(printf '%s\n' "$records" | gap_orphans "$changeset_file") || return 1
  counts=$(printf '%s\n' "$records" | gap_orphan_counts "$changeset_file") || return 1

  printf 'ORPHANS\t%s\n' "$counts"
  # See the note in `gap_unbacked_report`: an `&&` guard here makes an empty list exit 1.
  printf '%s\n' "$orphans" | while IFS= read -r path; do
    if [ -n "$path" ]; then printf 'ORPHAN\t%s\n' "$path"; fi
  done

  printf '%s\n' "$records" | gap_unbacked_report "$repo" "$changeset_file" || return 1
}

# The review a human reads, from the records above on stdin. Two lines, always both —
# R9's "the review still runs" is not satisfied by a review that omits the half it has
# nothing to say about.
gap_render() {
  local records
  records=$(cat)

  LC_ALL=C awk -F'\t' '
    $1 == "ORPHANS" {
      if ($3 + 0 == 0)
        print "no files in the change set"
      else if ($2 + 0 == 0)
        printf "no orphan changes - all %d file(s) have an intent behind them\n", $3
      else
        printf "%d of %d file(s) changed with no intent behind them\n", $2, $3
    }
  ' <<INNER
$records
INNER

  printf '%s\n' "$records" | gap_unbacked_render
}
