#!/bin/bash
# coverage-rollup.sh — Spec-level coverage roll-up.
#
# Answers "is this spec fully delivered?" by unioning a spec's coverage matrices back
# against the spec's own requirements. Coverage otherwise lives per-epic — `cpm:epics`
# writes one matrix per epic and `cpm:do` fills its `✓` marks — and no artefact spans a
# spec's epics.
#
# Executed, not sourced, following `progress-classify.sh`:
#
#   bash coverage-rollup.sh --spec <spec-path>
#   bash coverage-rollup.sh --epic <epic-path> [<epic-path>...]
#   bash coverage-rollup.sh --spec <spec-path> --matrix-dir <dir>
#   bash coverage-rollup.sh --epic <epic-path>... --verdict
#
# Exactly one of `--spec` / `--epic`. `--matrix-dir` overrides where spec scope looks for
# matrices (default `<project root>/docs/epics`); it exists so fixtures built under
# `TEST_TMPDIR` can be searched, the same environment-overridable-for-testing precedent as
# `CPM_STALE_THRESHOLD_DAYS` in `progress-classify.sh`.
#
# --- Exit codes -----------------------------------------------------------------
#
# Without `--verdict` (the default, unchanged since epic 44-01):
#
#   0  the computation completed — every input read, every record emitted
#   1  an input could not be read; the message on stderr names the file
#   2  usage error
#
# Zero here does **not** mean the spec is delivered. That is a separate judgement, and
# reading it into the exit code would make a read failure indistinguishable from an honest
# report of incomplete work.
#
# With `--verdict` (epic 44-03, for `cpm:ralph`'s completion promise), further codes
# separate those things:
#
#   0  the computation completed **and** nothing is outstanding
#   3  the computation completed cleanly, but work is outstanding
#   5  the only outstanding rows are `[target]` — nothing here can close them
#   4  the spec was readable and no matrix names it — spec scope only
#   1  an input could not be read
#   2  usage error
#
# Code 5 exists because 3 has no reachable exit for a caller that cannot reach the
# deployment target. A `[target]` row is unverifiable here **by definition** — `cpm:epics`
# says so directly: it "withholds a criterion from verification permanently". So a spec
# naming any production-host requirement could never return 0 from a development machine,
# and 3's "keep working" was advice about work that did not exist. Splitting it gives that
# state a name a caller can terminate on, and leaves 0 meaning what it always meant, so a
# run against the real host can still say a spec is fully verified.
#
# **5 reads both tag columns, and that is not a refinement.** A spec that mis-tags a
# checkable requirement `[target]` — collapsed ranges such as `ENV6–ENV8` make it a single
# careless cell — does not stop `cpm:epics`, which leaves the spec alone and writes criteria
# that check the thing properly. The resulting row says `[target]` in the spec column and
# `[integration]` in the criterion. Deciding 5 from the spec column alone declares that row
# unverifiable and terminates a run with work genuinely left to do, which is the same
# failure as the livelock 5 was introduced to end, reached from the opposite side and much
# harder to see afterwards: the run stops cleanly and reports a reason. So the withholding
# test requires both columns to agree, and a disagreement resolves toward keeping working.
#
# Code 4 exists because a loop working from a spec starts with no matrices at all, and that
# is iteration 1 rather than a failure (spec 45, FR7 / AD2). Before it, that state and a
# genuine read failure were both exit 1, so a loop could not tell "keep working" from "stop".
# It is confined to `--verdict`: the default path still reports it as 1, unchanged since
# epic 44-01, which is what `cpm:status` reads.
#
# The flag is opt-in precisely so that `cpm:status`, which wants "did this compute?", and
# `cpm:ralph`, which wants "is this done?", can ask different questions of one script
# without either answer being overloaded onto the other's exit code. AD4 puts the verdict
# in the script rather than in the caller: the model relays it instead of deriving it.
#
# **Outstanding** means any emitted `ROW` or `CRITERION` that is not `verified`, or — spec
# scope only — any requirement in the `untraced` state. The verdict is computed from
# exactly the records that were emitted, so it can never disagree with the output a reader
# is looking at.
#
# **Target-only** is outstanding that nothing here can close. A `[target]` criterion is
# checkable only against the real deployment target, so an unverified one is not work
# waiting to be done — it is work this environment is not entitled to do. Reported as its
# own exit code because the two demand opposite responses: outstanding means keep working,
# target-only means stop. Collapsing them into 3 gave a caller no reachable terminal state,
# and an autonomous loop met that by re-running a finished test suite for three hours.
#
# The split is on the tag alone, never on how many rows carry it: one unverified `[target]`
# row alongside genuine outstanding work is still 3, because the ordinary work is still
# there to do. Only when *every* remaining unverified row is `[target]` does the verdict
# become 5. A ticked `[target]` row still counts as verified exactly as before — this reads
# the tag to decide what an *unverified* row means, and changes nothing about a verified one.
#
# Relative paths resolve against the project root, which comes from
# `lib/resolve-project-root.sh` — the same chain the guard and the classifier use.
# `CLAUDE_PROJECT_DIR` is set for hooks but *not* for the Bash calls a `/cpm:*` skill
# issues, which is why the resolver is sourced rather than the variable read directly.
#
# Strictly read-only: it never writes, moves or modifies any document. A measurement that
# mutates its subject cannot be trusted about it.
#
# --- Record format --------------------------------------------------------------
#
# Tab-separated, one record per line, via `printf`. Field 1 is the record type, so a
# consumer filters on it; every type has a fixed number of fields.
#
#   MATRIX     path, source-spec                                        (both scopes)
#   REQ        label, moscow, text                                      (spec scope)
#   STATE      label, moscow, delivered|in-progress|untraced            (spec scope)
#   EXCLUDED   label, moscow                                            (spec scope)
#   SUMMARY    scope, requirements, untraced, delivered, in-progress    (spec scope)
#   ROW        matrix-path, base, label, covered-by, verified|unverified, tag, criterion tag
#   CRITERION  matrix-path, label, covered-by, verified|unverified, tag       (both scopes)
#   UNRESOLVED matrix-path, label, covered-by                                 (both scopes)
#
# `CRITERION` carries the story-originated rows — rows with no requirement behind them.
# They are reported separately rather than as a `ROW` with an empty base, so nothing
# downstream can count one toward a requirement.
#
# The `tag` on `ROW` and `CRITERION` is the matrix's Spec Test Approach cell — the test
# approach the spec assigned — with its backticks removed, and empty when the column is
# blank or absent. The `criterion tag` beside it is the tags written inline in the Story
# Criterion cell, which is what `cpm:epics` assigned to the criterion it actually wrote.
# They are reported separately because they do not have to agree, and the disagreement is
# load-bearing: see the note on code 5 below.
#
# Neither changes what a tick means — a tick is a tick whatever tags sit beside it, and the
# delivered/in-progress counts are what they always were. What they let a reader do is
# separate the ticks a test produced from the ones resting on a human's judgement
# (`[manual]`) or on an environment nobody here has (`[target]`) — a distinction that was
# previously stated only in the matrix and invisible to everything reading it, so a wall of
# green could not be told apart from a wall of self-assessment.
#
# `UNRESOLVED` carries a row that names a requirement the label cannot be resolved to —
# in practice a label naming several, such as `ENV1–ENV5`. It is a record rather than a
# silence because the alternative failure is invisible: the row sits on disk claiming
# coverage while every requirement it names reads untraced, and nothing says why. It counts
# as outstanding, so a matrix containing one cannot reach a clean verdict.
#
# One format, for both readers: a model parses it into a promise decision and a human
# reads it in a terminal. There is no second rendering mode and no flag that adds one.

set -u

LIB_DIR="${0%/*}"
[ "$LIB_DIR" = "$0" ] && LIB_DIR="."
. "$LIB_DIR/resolve-project-root.sh"
. "$LIB_DIR/coverage-parse.sh"

EXIT_USAGE=2
EXIT_OUTSTANDING=3
EXIT_NO_MATRIX=4
EXIT_TARGET_ONLY=5

usage() {
  cat >&2 <<'EOF'
Usage:
  coverage-rollup.sh --spec <spec-path> [--matrix-dir <dir>] [--verdict]
  coverage-rollup.sh --epic <epic-path> [<epic-path>...] [--verdict]

Emits tab-separated coverage records. Spec scope discovers matrices by their
**Source spec** field; epic scope reports row states for the named epics only.

--verdict changes only the exit code, never the output: 0 when nothing is
outstanding, 3 when the computation completed but work remains, 5 when the only
work left is [target] and so cannot be checked from this environment, 4 when the
spec is readable and no matrix names it, 1 on a read failure, 2 on a usage error.
EOF
}

# --- Argument parsing -----------------------------------------------------------
#
# The two scopes are named rather than inferred from the path. Inferring would re-derive
# a relationship from a directory name, which is the coupling AD2 rejects for matrix
# discovery; there is no reason to accept it here instead.

MODE=""
SPEC_PATH=""
MATRIX_DIR=""
VERDICT="no"
EPIC_PATHS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --spec)
      if [ "$MODE" = "epic" ]; then
        echo "coverage-rollup: --spec and --epic are alternatives, not a pair" >&2
        exit "$EXIT_USAGE"
      fi
      if [ $# -lt 2 ]; then
        echo "coverage-rollup: --spec needs a spec path" >&2
        exit "$EXIT_USAGE"
      fi
      MODE="spec"
      SPEC_PATH="$2"
      shift 2
      ;;
    --epic)
      if [ "$MODE" = "spec" ]; then
        echo "coverage-rollup: --spec and --epic are alternatives, not a pair" >&2
        exit "$EXIT_USAGE"
      fi
      MODE="epic"
      shift
      # Consume every following argument that is not itself a flag, so several epics can
      # be given as `--epic a.md b.md c.md`.
      while [ $# -gt 0 ] && [ "${1#--}" = "$1" ]; do
        EPIC_PATHS+=("$1")
        shift
      done
      if [ ${#EPIC_PATHS[@]} -eq 0 ]; then
        echo "coverage-rollup: --epic needs at least one epic path" >&2
        exit "$EXIT_USAGE"
      fi
      ;;
    --matrix-dir)
      if [ $# -lt 2 ]; then
        echo "coverage-rollup: --matrix-dir needs a directory" >&2
        exit "$EXIT_USAGE"
      fi
      MATRIX_DIR="$2"
      shift 2
      ;;
    --verdict)
      VERDICT="yes"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "coverage-rollup: unrecognised argument: $1" >&2
      usage
      exit "$EXIT_USAGE"
      ;;
  esac
done

if [ -z "$MODE" ]; then
  echo "coverage-rollup: no scope given — pass --spec or --epic" >&2
  usage
  exit "$EXIT_USAGE"
fi

# Epic scope derives each matrix from its epic path, so it never searches a directory. A
# `--matrix-dir` given alongside `--epic` would be silently ignored, and a flag that looks
# like it took effect is worse than one that was refused.
if [ "$MODE" = "epic" ] && [ -n "$MATRIX_DIR" ]; then
  echo "coverage-rollup: --matrix-dir applies to --spec only; epic scope derives each matrix from its epic path" >&2
  exit "$EXIT_USAGE"
fi

# An unresolvable root means every relative path below would address somewhere that does
# not exist. That is a failure, not a reason to carry on with a guess.
if ! cpm_resolve_project_root "coverage-rollup"; then
  exit 1
fi

# Whether the caller named the directory, captured before the default fills it in. The two
# cases mean different things when the directory turns out not to exist: a caller who named
# one and got it wrong has made a mistake worth reporting, while the default being absent is
# an ordinary state of a repository nobody has run `cpm:epics` in yet.
MATRIX_DIR_EXPLICIT=0
[ -n "$MATRIX_DIR" ] && MATRIX_DIR_EXPLICIT=1

MATRIX_DIR="${MATRIX_DIR:-$CPM_PROJECT_ROOT/docs/epics}"

# Absolute form of a caller-supplied path. A relative path is taken against the resolved
# project root rather than $PWD, so the same invocation means the same thing whether a
# hook, a skill, or a person runs it.
rollup_abs_path() {
  case "$1" in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s\n' "$CPM_PROJECT_ROOT/$1" ;;
  esac
}

# Project-relative form of a path, for the records. A path under the project root is
# reported relative to it — that is the form the documents themselves use for cross
# references, and it keeps output identical between machines, which is what makes two
# runs comparable. Anything outside the root is reported as given.
rollup_rel_path() {
  case "$1" in
    "$CPM_PROJECT_ROOT"/*) printf '%s\n' "${1#"$CPM_PROJECT_ROOT"/}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

# --- Record emitters ------------------------------------------------------------
#
# Every record leaves through one of these four functions, so the field order and count
# of a type is stated once. Both scopes emit through the same set: a format that differed
# by scope would be two contracts for the consumers to track, and NFR4 asks for one.
#
# `printf` with explicit `\t` separators and no interpretation of the values — no colour,
# no alignment, no markup. A model parses it; a human reads it in a terminal. There is no
# flag that selects a different rendering, because a second rendering is a second format.

emit_matrix() {
  printf 'MATRIX\t%s\t%s\n' "$1" "$2"
}

emit_req() {
  printf 'REQ\t%s\t%s\t%s\n' "$1" "$2" "$3"
}

emit_row() {
  printf 'ROW\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" "$6" "$7"
}

emit_criterion() {
  printf 'CRITERION\t%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" "$6"
}

# No verified field: whether an unresolvable row carries a tick is not a fact worth
# reporting. The row does not resolve to a requirement, so a tick on it verifies nothing.
emit_unresolved() {
  printf 'UNRESOLVED\t%s\t%s\t%s\n' "$1" "$2" "$3"
}

# Emit every row of one matrix, splitting requirement rows from story-originated ones.
#
# `coverage_matrix_rows` reports both kinds and leaves the base empty for the second. The
# split into two record types happens here rather than there because it is a reporting
# decision, not an extraction one — and keeping story-originated rows in their own type is
# what stops a consumer counting one toward a requirement by accident.
emit_matrix_rows() {
  local matrix_abs="$1" matrix_rel="$2"
  local line rest kind base label covered verified tag crit_tag
  local tab
  tab="$(printf '\t')"

  coverage_matrix_rows "$matrix_abs" | while IFS= read -r line; do
    # Split on tabs by hand rather than with `IFS=<tab> read`. Tab is IFS *whitespace*, so
    # `read` collapses a run of tabs into a single delimiter — and a story-originated row
    # carries an empty base, which is exactly a run of two. Every field after it would
    # shift left, silently, and the record would still look well-formed.
    #
    # Every field is taken with `%%` — the *shortest* leading match — including the last two.
    # `verified` previously used `#*` to take everything remaining, which is correct only
    # while it is the final field; appending the tag would have parked it inside `verified`
    # and left a record that still looked well-formed. The trailing field is the one that
    # silently absorbs whatever is added after it, so it is not written that way.
    kind="${line%%$tab*}";  rest="${line#*$tab}"
    base="${rest%%$tab*}";  rest="${rest#*$tab}"
    label="${rest%%$tab*}"; rest="${rest#*$tab}"
    rest="${rest#*$tab}"                     # spec text: neither record type carries it
    covered="${rest%%$tab*}"; rest="${rest#*$tab}"
    verified="${rest%%$tab*}"; rest="${rest#*$tab}"
    tag="${rest%%$tab*}"
    crit_tag="${rest#*$tab}"
    # A record with no criterion tag ends at `tag`, so `#*` finds no tab and returns the
    # whole of `rest` — which is `tag` again. Reading it back as the criterion's own tag
    # would make every untagged criterion inherit the spec's, and `[target]` is exactly the
    # value that must not spread that way.
    [ "$crit_tag" = "$tag" ] && case "$rest" in *"$tab"*) ;; *) crit_tag="" ;; esac

    if [ "$kind" = "story-originated" ]; then
      emit_criterion "$matrix_rel" "$label" "$covered" "$verified" "$tag" "$crit_tag"
    elif [ -z "$base" ]; then
      # A requirement row whose label resolved to nothing. Kept out of `ROW` because a ROW
      # with an empty base would join against no requirement while still counting as a row,
      # which is the silent version of this failure.
      emit_unresolved "$matrix_rel" "$label" "$covered"
    else
      emit_row "$matrix_rel" "$base" "$label" "$covered" "$verified" "$tag" "$crit_tag"
    fi
  done
}

# --- Derived records ------------------------------------------------------------
#
# Everything above reports what the documents say. This reports what follows from them:
# each requirement's state, and — the load-bearing measurement — which requirements no
# matrix mentions at all.
#
#   STATE      label, moscow, delivered|in-progress|untraced
#   EXCLUDED   label, moscow
#   SUMMARY    scope, requirements, untraced, delivered, in-progress
#
# Spec scope only. Untraced detection compares a requirement list against the rows, and
# epic scope has no list; an empty untraced section there would read as "nothing is
# missing" when the truth is "nothing was checked".
#
# **Three states, never a proportion.** All of a requirement's rows verified is
# *delivered*; no rows at all is *untraced*; anything else — including none of several
# rows verified — is *in progress*. No ratio is computed or emitted anywhere, because a
# requirement that is 4/5 verified is not four-fifths delivered.
#
# **Untraced first.** FR2 makes untraced the headline output, so the untraced records are
# emitted before the others rather than left for a consumer to sort into place.
#
# **Requirements the spec has ruled out are excluded, visibly.** Such a requirement will
# never have a matrix row, and calling it untraced would report the spec working as intended
# as though it were a gap. `coverage_spec_requirements` deliberately carries the MoSCoW
# heading rather than dropping those bullets, so that the policy question is answered exactly
# once — here. They still appear, as `EXCLUDED`; a silent omission would be the same
# false-clean result by a quieter route.
#
# There are **two routes out of the count**, because `cpm:spec` writes "not this iteration"
# in two places: the `Won't Have` MoSCoW heading, and a `### Deferred` / `### Out of Scope`
# bullet under `## Scope`. Only the first was read until a live `cpm:ralph` spec-mode run hung
# on the second — a spec that deferred its Should Haves in the Scope section left them
# untraced forever, and spec mode reads a non-zero untraced count as "phase 1 unfinished".
# `coverage_spec_scope_deferrals` supplies the second route; both land in `EXCLUDED`, and the
# record keeps its two fields so a consumer written against the first route still reads.
#
# **A Must Have is never excluded by the Scope route.** A spec that lists a requirement as
# Must Have and then defers it in Scope contradicts itself, and the reading that stays
# visible is the safe one: it remains untraced. The alternative would let one sentence in a
# Scope section retire a must-have requirement and report the spec delivered without it.
#
# **Nor is an environmental constraint** — spec 46, FR6. An `ENVn` requirement or `ENVXn`
# restriction names something about the target host, and a Scope bullet deferring it does
# not change the host; it only stops the roll-up saying so. That is precisely the failure
# spec 46 exists for: a matrix reading fully verified while the software cannot run where
# it has to. The `Won't Have` route still excludes one, because that is an explicit
# ruling-out written where a reader looks for it — AD2 draws the boundary exactly there,
# between the deliberate route and the quiet one. The class check is `cov_is_environmental`
# from `coverage-parse.sh`, which is the one definition shared with `cpm:epics`; no prefix
# is restated in this file.
#
# `REQ` is still emitted for every requirement bullet, Won't Have included, so
# `REQ = STATE ∪ EXCLUDED` is an exact partition a test can assert without trusting either
# side of it.
#
# A row naming a requirement the spec does not carry — the inverse gap — gets no record
# type of its own; FR2 asks only about the untraced direction. Nothing is hidden by that:
# every row is emitted as a `ROW`, so the join against `REQ` is available to any consumer
# that wants it.
rollup_emit_derived() {
  local spec_abs="$1"
  shift

  local m
  {
    coverage_spec_requirements "$spec_abs" | awk -F'\t' '{ printf "R\t%s\t%s\n", $1, $2 }'
    coverage_spec_scope_deferrals "$spec_abs" | awk '{ printf "X\t%s\n", $1 }'
    for m in "$@"; do
      coverage_matrix_rows "$m" | awk -F'\t' '$1 == "requirement" { printf "W\t%s\t%s\n", $2, $6 }'
    done
  } | awk -F'\t' "$_COVERAGE_AWK_LIB"'
    # A MoSCoW heading naming the spec Won'"'"'t Have section. Matched on the words rather
    # than the exact string so a typographic apostrophe reads the same as an ASCII one.
    function is_wont(h) {
      return (index(h, "Won") == 1 && index(h, "Have") > 0)
    }

    # The same shape, for the heading a scope deferral may never override.
    function is_must(h) {
      return (index(h, "Must") == 1 && index(h, "Have") > 0)
    }

    function emit_states(want,   i, label) {
      for (i = 1; i <= n; i++) {
        label = order[i]
        if (label in excluded) continue
        if (state_of[label] != want) continue
        printf "STATE\t%s\t%s\t%s\n", label, heading[label], want
      }
    }

    BEGIN { n = 0 }

    $1 == "R" {
      if (!($2 in seen)) {
        seen[$2] = 1
        order[++n] = $2
        heading[$2] = $3
      }
      next
    }

    $1 == "X" {
      if ($2 != "") deferred[$2] = 1
      next
    }

    $1 == "W" {
      if ($2 == "") next
      rows[$2]++
      if ($3 == "verified") verified[$2]++
      next
    }

    END {
      total = 0
      for (i = 1; i <= n; i++) {
        label = order[i]
        # Two routes out of the count, and two kinds of label that may not take the second.
        # A Must Have named in the Scope section as deferred is a spec contradicting itself,
        # and the safe reading of a contradiction is the one that stays visible: it remains
        # untraced, so the roll-up reports a gap rather than reporting the spec delivered
        # on the strength of the sentence that abandoned it.
        #
        # An environmental constraint is the second kind, for that reason read one step
        # further (spec 46, FR6). A deferred ENV1 does not become less true for being
        # deferred: the host still lacks the thing and the software still will not run
        # there. The Won'"'"'t Have route may still exclude it -- an explicit ruling-out,
        # written where a reader looks for one, which is the boundary AD2 draws.
        #
        # cov_is_environmental comes from _COVERAGE_AWK_LIB. It is the definition cpm:epics
        # shares, so neither prefix appears in this file.
        if (is_wont(heading[label]) ||
            ((label in deferred) &&
             !is_must(heading[label]) &&
             !cov_is_environmental(label))) {
          excluded[label] = 1
          continue
        }
        total++
        r = (label in rows) ? rows[label] : 0
        v = (label in verified) ? verified[label] : 0
        if (r == 0) {
          state_of[label] = "untraced"
        } else if (v == r) {
          state_of[label] = "delivered"
        } else {
          state_of[label] = "in-progress"
        }
        count[state_of[label]]++
      }

      emit_states("untraced")
      emit_states("in-progress")
      emit_states("delivered")

      for (i = 1; i <= n; i++) {
        label = order[i]
        if (label in excluded) printf "EXCLUDED\t%s\t%s\n", label, heading[label]
      }

      printf "SUMMARY\tspec\t%d\t%d\t%d\t%d\n", \
        total, count["untraced"] + 0, count["delivered"] + 0, count["in-progress"] + 0
    }
  '
}

# --- Spec scope -----------------------------------------------------------------
#
# One record per requirement in the spec, plus the rows of every matrix that names it.
#
# Discovery reads each candidate's `**Source spec**` field (AD2) and never a filename
# prefix. The filename route would re-derive a relationship the document already states,
# and the epic naming convention already has two shapes.
#
# Matching compares basenames. Specs are uniquely numbered within `docs/specifications/`,
# so the basename is the identity, and comparing it tolerates the caller passing an
# absolute, relative or `./`-prefixed form of the same path without a second rule for
# each. A matrix naming a *different* spec fails the comparison and contributes nothing —
# that is the whole of the must-NOT.
rollup_spec_scope() {
  local spec_abs spec_base source_spec m
  local matrices=()

  spec_abs="$(rollup_abs_path "$SPEC_PATH")"
  if [ ! -r "$spec_abs" ]; then
    echo "coverage-rollup: cannot read spec: $spec_abs" >&2
    return 1
  fi
  spec_base="${spec_abs##*/}"

  # A missing default directory and a directory holding no matching matrix are the same
  # statement — *no matrix names this spec* — so they share an exit code. Splitting them
  # stopped spec mode dead on its first iteration: a repository that has never run
  # `cpm:epics` has no `docs/epics/`, the loop read the resulting 1 as "the check could not
  # run, stop", and phase 1 could never begin in the one situation phase 1 exists for.
  #
  # A directory the caller *named* keeps the read-failure code. There the absence is
  # evidence about the argument rather than about the repository, and answering a typo with
  # "no matrix names this spec yet" would send a loop off to generate epics into a path that
  # will never be looked at again.
  if [ ! -d "$MATRIX_DIR" ]; then
    if [ "$MATRIX_DIR_EXPLICIT" = "1" ]; then
      echo "coverage-rollup: matrix directory does not exist: $MATRIX_DIR" >&2
      return 1
    fi
    echo "coverage-rollup: no matrix directory at $MATRIX_DIR — nothing names $spec_base as its source spec" >&2
    return "$EXIT_NO_MATRIX"
  fi

  for m in "$MATRIX_DIR"/*-coverage-*.md; do
    [ -f "$m" ] || continue
    coverage_is_matrix_name "${m##*/}" || continue
    if [ ! -r "$m" ]; then
      echo "coverage-rollup: cannot read matrix: $m" >&2
      return 1
    fi
    source_spec="$(coverage_matrix_source_spec "$m")"
    [ -n "$source_spec" ] || continue
    [ "${source_spec##*/}" = "$spec_base" ] || continue
    matrices+=("$m")
  done

  # No matrices is *not* full coverage — it is a spec nothing has been broken down for,
  # or a discovery that failed. Reporting it as a clean run would be complete by default.
  #
  # It is also not a *read failure*, and spec 45's FR7 needs those two apart: for a loop
  # working from a spec, "no matrix names this yet" is iteration 1 and means keep going,
  # while "an input could not be read" means stop. The distinction leaves this function as a
  # return code rather than a variable because the caller runs it inside `$( )` — a global
  # set here could not reach the parent. The non-`--verdict` path maps it straight back to 1,
  # so epic 44-01's contract is unchanged (AD2).
  if [ ${#matrices[@]} -eq 0 ]; then
    echo "coverage-rollup: no matrix in $MATRIX_DIR names $spec_base as its source spec" >&2
    return "$EXIT_NO_MATRIX"
  fi

  for m in "${matrices[@]}"; do
    emit_matrix "$(rollup_rel_path "$m")" "$(coverage_matrix_source_spec "$m")"
  done

  # A spec whose requirement list comes out empty is the same false-clean result as no
  # matrices: nothing is untraced because nothing was compared. Whether that is a spec
  # with no requirements or a parser that failed to recognise its bullets, the computation
  # did not happen, and reporting it as a clean run would be complete by default.
  local spec_requirements
  spec_requirements="$(coverage_spec_requirements "$spec_abs")"
  if [ -z "$spec_requirements" ]; then
    echo "coverage-rollup: no requirements found in $spec_abs — expected '- **FRn** — …' bullets under '## Functional Requirements'" >&2
    return 1
  fi

  local line rest label moscow text tab
  tab="$(printf '\t')"
  printf '%s\n' "$spec_requirements" | while IFS= read -r line; do
    # Split by hand for the same reason `emit_matrix_rows` does: `read` with a tab IFS
    # collapses a run of tabs, and a bullet under no MoSCoW heading has an empty middle
    # field.
    label="${line%%$tab*}";  rest="${line#*$tab}"
    moscow="${rest%%$tab*}"
    text="${rest#*$tab}"
    emit_req "$label" "$moscow" "$text"
  done

  rollup_emit_derived "$spec_abs" "${matrices[@]}"

  for m in "${matrices[@]}"; do
    emit_matrix_rows "$m" "$(rollup_rel_path "$m")"
  done
}

# --- Epic scope -----------------------------------------------------------------
#
# Row states for the named epics' matrices, and nothing else. No requirement records and
# no untraced section: untraced detection compares a spec's requirement list against the
# rows, and with no spec there is no list to compare against. Emitting an empty untraced
# section here would read as "nothing is missing" when the truth is "nothing was checked".
#
# The matrix is derived from the epic path by the `-epic-` → `-coverage-` substitution the
# epic filename convention defines. Every path is derived and checked before anything is
# emitted, so a bad path fails before it can produce a partial report.
rollup_epic_scope() {
  local i epic epic_abs epic_base matrix_abs
  local matrices=()

  i=0
  while [ "$i" -lt ${#EPIC_PATHS[@]} ]; do
    epic="${EPIC_PATHS[$i]}"
    epic_abs="$(rollup_abs_path "$epic")"
    epic_base="${epic_abs##*/}"

    case "$epic_base" in
      *-epic-*) : ;;
      *)
        echo "coverage-rollup: not an epic path — no '-epic-' in the filename: $epic" >&2
        return 1
        ;;
    esac

    matrix_abs="${epic_abs%/*}/${epic_base/-epic-/-coverage-}"
    if [ ! -r "$matrix_abs" ]; then
      echo "coverage-rollup: cannot read the matrix for $epic — looked for $matrix_abs" >&2
      return 1
    fi

    matrices+=("$matrix_abs")
    i=$((i + 1))
  done

  local m
  for m in "${matrices[@]}"; do
    emit_matrix "$(rollup_rel_path "$m")" "$(coverage_matrix_source_spec "$m")"
  done

  for m in "${matrices[@]}"; do
    emit_matrix_rows "$m" "$(rollup_rel_path "$m")"
  done
}

rollup_run_scope() {
  if [ "$MODE" = "spec" ]; then
    rollup_spec_scope
  else
    rollup_epic_scope
  fi
}

# Read the verdict out of records already emitted. It takes the output rather than
# recomputing from the documents so that the exit code and the records a reader is looking
# at cannot disagree — a verdict derived from a second pass could differ from the first if
# a file changed underneath, and would then be reporting on something nobody saw.
#
# `CRITERION` counts alongside `ROW`. A story-originated criterion is not a requirement, so
# it never reaches a `STATE` record, and leaving it out would let a promise fire with
# unverified work sitting in the matrix it just read.
#
# `UNRESOLVED` counts unconditionally — it has no verified field to test. In spec scope the
# requirements behind it are already untraced, so the verdict would be outstanding either
# way; in epic scope there is no spec to compare against and nothing else would notice, and
# a matrix nobody can join against is not a clean run in either scope.
# Prints one of `clean`, `target-only`, or `outstanding` — one awk pass, so the two
# questions ("is anything left?" and "is any of it doable here?") cannot come to disagree
# the way two predicates over the same buffer eventually would.
rollup_verdict() {
  # Field numbers count the record type as field 1, so a `ROW`'s five documented fields sit
  # at $2..$6 and its verified cell is $6, not $5 — its spec tag is $7 and its criterion tag
  # $8. `CRITERION` has one field fewer, so the same cells are $5, $6 and $7. Reading the
  # record format's own numbering straight into awk puts every test one field to the left,
  # where a verified row compares unequal to "verified" and every verdict comes back
  # outstanding.
  #
  # `actionable` wins over `target` whenever both are set: a run with real work left is
  # outstanding however many target rows sit beside it.
  printf '%s\n' "$1" | awk -F'\t' '
    # Only a tag that is target-and-nothing-checkable withholds a row from this environment.
    # A row carrying `[target]` *and* an automated tag is contradictory tagging, and the
    # safe reading is the one that keeps working: stopping early is the worse failure, since
    # it ends a run with work genuinely left to do and looks like completion afterwards.
    function target_only(tag) {
      return tag ~ /\[target\]/ && tag !~ /\[(unit|integration|feature)\]/
    }
    # Both columns, and either one offering an automated tag is enough to keep the row in
    # play. The spec column alone is not the answer: when a spec mis-tags a checkable
    # requirement `[target]`, `cpm:epics` leaves the spec alone and writes criteria that
    # check it properly, so the row reads `[target]` from the spec and `[integration]` from
    # the criterion. Believing only the spec calls that row unverifiable here and stops a
    # run that had work left -- the failure this whole verdict exists to avoid, arrived at
    # from the other side.
    function withheld(spec_tag, crit_tag) {
      if (crit_tag != "") return target_only(spec_tag) && target_only(crit_tag)
      return target_only(spec_tag)
    }
    $1 == "ROW"        && $6 != "verified" { if (withheld($7, $8)) target = 1; else actionable = 1 }
    $1 == "CRITERION"  && $5 != "verified" { if (withheld($6, $7)) target = 1; else actionable = 1 }
    $1 == "STATE"      && $4 == "untraced" { actionable = 1 }
    $1 == "UNRESOLVED"                     { actionable = 1 }
    END {
      if (actionable)   print "outstanding"
      else if (target)  print "target-only"
      else              print "clean"
    }
  '
}

# The exit status is the scope function's, stated rather than inherited from whatever ran
# last. Without `--verdict` it reports whether the *computation completed*: zero means every
# input was read and every record emitted, non-zero means it was not, and the message on
# stderr names the file. That is the contract epic 44-01 shipped and `cpm:status` reads, and
# nothing below changes it.
if [ "$VERDICT" = "no" ]; then
  rollup_run_scope
  DEFAULT_RC=$?
  # The no-matrix case is a read failure on this path, exactly as it was before spec 45.
  # Confining the new code to `--verdict` is AD2's containment, and this line is where it is
  # enforced rather than assumed.
  [ "$DEFAULT_RC" = "$EXIT_NO_MATRIX" ] && DEFAULT_RC=1
  exit "$DEFAULT_RC"
fi

# With `--verdict`, the same records are emitted and the exit code additionally distinguishes
# "nothing outstanding" from "computed cleanly, work remains" (AD4, epic 44-03) and from
# "what remains cannot be checked here". Buffering is what makes the verdict provably a
# reading of the emitted output; the bytes on stdout are identical either way, which is
# NFR4's one-output-format rule holding across the flag.
ROLLUP_OUTPUT="$(rollup_run_scope)"
ROLLUP_RC=$?

[ -n "$ROLLUP_OUTPUT" ] && printf '%s\n' "$ROLLUP_OUTPUT"

# A read failure keeps its own code. Overwriting it with the outstanding verdict would tell
# a caller that work remains when the truth is that the check never ran.
if [ "$ROLLUP_RC" -ne 0 ]; then
  exit "$ROLLUP_RC"
fi

case "$(rollup_verdict "$ROLLUP_OUTPUT")" in
  outstanding) exit "$EXIT_OUTSTANDING" ;;
  target-only) exit "$EXIT_TARGET_ONLY" ;;
  *)           exit 0 ;;
esac
