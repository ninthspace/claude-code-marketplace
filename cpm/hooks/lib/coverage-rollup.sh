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
#   4  the spec was readable and no matrix names it — spec scope only
#   1  an input could not be read
#   2  usage error
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
#   ROW        matrix-path, base, label, covered-by, verified|unverified (both scopes)
#   CRITERION  matrix-path, label, covered-by, verified|unverified       (both scopes)
#
# `CRITERION` carries the story-originated rows — rows with no requirement behind them.
# They are reported separately rather than as a `ROW` with an empty base, so nothing
# downstream can count one toward a requirement.
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

usage() {
  cat >&2 <<'EOF'
Usage:
  coverage-rollup.sh --spec <spec-path> [--matrix-dir <dir>] [--verdict]
  coverage-rollup.sh --epic <epic-path> [<epic-path>...] [--verdict]

Emits tab-separated coverage records. Spec scope discovers matrices by their
**Source spec** field; epic scope reports row states for the named epics only.

--verdict changes only the exit code, never the output: 0 when nothing is
outstanding, 3 when the computation completed but work remains, 4 when the spec
is readable and no matrix names it, 1 on a read failure, 2 on a usage error.
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
  printf 'ROW\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5"
}

emit_criterion() {
  printf 'CRITERION\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"
}

# Emit every row of one matrix, splitting requirement rows from story-originated ones.
#
# `coverage_matrix_rows` reports both kinds and leaves the base empty for the second. The
# split into two record types happens here rather than there because it is a reporting
# decision, not an extraction one — and keeping story-originated rows in their own type is
# what stops a consumer counting one toward a requirement by accident.
emit_matrix_rows() {
  local matrix_abs="$1" matrix_rel="$2"
  local line rest kind base label covered verified
  local tab
  tab="$(printf '\t')"

  coverage_matrix_rows "$matrix_abs" | while IFS= read -r line; do
    # Split on tabs by hand rather than with `IFS=<tab> read`. Tab is IFS *whitespace*, so
    # `read` collapses a run of tabs into a single delimiter — and a story-originated row
    # carries an empty base, which is exactly a run of two. Every field after it would
    # shift left, silently, and the record would still look well-formed.
    kind="${line%%$tab*}";  rest="${line#*$tab}"
    base="${rest%%$tab*}";  rest="${rest#*$tab}"
    label="${rest%%$tab*}"; rest="${rest#*$tab}"
    rest="${rest#*$tab}"                     # spec text: neither record type carries it
    covered="${rest%%$tab*}"
    verified="${rest#*$tab}"

    if [ "$kind" = "story-originated" ]; then
      emit_criterion "$matrix_rel" "$label" "$covered" "$verified"
    else
      emit_row "$matrix_rel" "$base" "$label" "$covered" "$verified"
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
# **Won't Have entries are excluded, visibly.** A requirement the spec has explicitly
# ruled out will never have a matrix row, and calling it untraced would report the spec
# working as intended as though it were a gap. `coverage_spec_requirements` deliberately
# carries the MoSCoW heading rather than dropping those bullets, so that the policy
# question is answered exactly once — here. They still appear, as `EXCLUDED`; a silent
# omission would be the same false-clean result by a quieter route.
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
    for m in "$@"; do
      coverage_matrix_rows "$m" | awk -F'\t' '$1 == "requirement" { printf "W\t%s\t%s\n", $2, $6 }'
    done
  } | awk -F'\t' '
    # A MoSCoW heading naming the spec Won'"'"'t Have section. Matched on the words rather
    # than the exact string so a typographic apostrophe reads the same as an ASCII one.
    function is_wont(h) {
      return (index(h, "Won") == 1 && index(h, "Have") > 0)
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
        if (is_wont(heading[label])) {
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

  if [ ! -d "$MATRIX_DIR" ]; then
    echo "coverage-rollup: matrix directory does not exist: $MATRIX_DIR" >&2
    return 1
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
rollup_outstanding() {
  # Field numbers count the record type as field 1, so a `ROW`'s five documented fields sit
  # at $2..$6 and its verified cell is $6, not $5. Reading the record format's own numbering
  # straight into awk puts every test one field to the left, where a verified row compares
  # unequal to "verified" and every verdict comes back outstanding.
  printf '%s\n' "$1" | awk -F'\t' '
    $1 == "ROW"       && $6 != "verified" { outstanding = 1 }
    $1 == "CRITERION" && $5 != "verified" { outstanding = 1 }
    $1 == "STATE"     && $4 == "untraced" { outstanding = 1 }
    END { exit outstanding ? 0 : 1 }
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
# "nothing outstanding" from "computed cleanly, work remains" (AD4, epic 44-03). Buffering is
# what makes the verdict provably a reading of the emitted output; the bytes on stdout are
# identical either way, which is NFR4's one-output-format rule holding across the flag.
ROLLUP_OUTPUT="$(rollup_run_scope)"
ROLLUP_RC=$?

[ -n "$ROLLUP_OUTPUT" ] && printf '%s\n' "$ROLLUP_OUTPUT"

# A read failure keeps its own code. Overwriting it with the outstanding verdict would tell
# a caller that work remains when the truth is that the check never ran.
if [ "$ROLLUP_RC" -ne 0 ]; then
  exit "$ROLLUP_RC"
fi

if rollup_outstanding "$ROLLUP_OUTPUT"; then
  exit "$EXIT_OUTSTANDING"
fi
exit 0
