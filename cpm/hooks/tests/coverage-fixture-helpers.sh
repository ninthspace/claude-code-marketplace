#!/bin/bash
# coverage-fixture-helpers.sh — Synthetic specs and coverage matrices for CPM test suites.
#
# These back Epic 44-01 Story 1's [unit] acceptance criteria (spec 44, Testing Strategy →
# Test Infrastructure: "fixture specs and matrices built under TEST_TMPDIR, so partition
# and fail-closed cases can be constructed rather than found"). They are a library, not a
# test suite: source this file *after* test-helpers.sh. The filename does not match the
# `test-*.sh` glob, so run-all-tests.sh never executes it standalone.
#
# --- Why fixtures rather than the repository's own documents --------------------
#
# The roll-up script's interesting cases are the ones this repository does not contain.
# A spec whose requirement appears in no matrix, a matrix naming a spec that does not
# exist, a matrix whose rows are half verified — each has to be *built* to be tested.
# Asserting against `docs/specifications/` would test the state of the repo on the day
# the test was written, which is a snapshot, and spec 44's testing strategy rules that
# out explicitly.
#
# Provided functions:
#   coverage_fixture_root                     — print the directory fixtures live under
#   coverage_fixture_dir [<label>]            — mint a fresh fixture directory, print its path
#   coverage_fixture_spec <slug> [--dir <path>]
#                                [--must <label> <text>]...
#                                [--should <label> <text>]...
#                                [--wont <text>]...
#                                             — write a spec, print its path
#   coverage_fixture_matrix <slug> <source-spec> [--dir <path>] [--epic <path>]
#                                [--row <label> <spec-text> <criterion> <covered-by> <verified>]...
#                                             — write a coverage matrix, print its path
#   coverage_fixture_count                    — print how many fixture directories exist
#   coverage_rollup_run <arg>...              — run coverage-rollup.sh, print its records
#   coverage_rollup_rc <arg>...               — the same run, print its exit code instead
#   coverage_count_type <output> <type>       — count records of one type in a captured run
#   coverage_states_in <output> <state>       — the sorted labels a run put in one state
#   coverage_partition_errors <output> [tag]  — how REQ = STATE ∪ EXCLUDED fails, if it does
#
# There is deliberately no `coverage_fixture_destroy`. git-fixture-helpers.sh has one
# because a test there observes removal; nothing in spec 44 does, and an untested `rm -rf`
# path — however carefully guarded — is not worth shipping for a caller that does not
# exist. `coverage_fixture_dir` already gives an empty directory to any test that needs
# one, and the inherited trap clears everything at exit.
#
# --- Why `--dir` exists ---------------------------------------------------------
#
# Each builder mints its own directory by default, which is what a single-document test
# wants. Spec scope, though, is about *several* matrices sitting together — one naming
# this spec, one naming another — so those tests need to place documents side by side.
# `coverage_fixture_dir` mints a directory once and `--dir` writes into it, rather than
# each builder guessing at a shared location.
#
# --- Why there is no trap in this file ------------------------------------------
#
# Inherited, not re-implemented — the same reasoning as git-fixture-helpers.sh.
# test-helpers.sh ends with `TEST_TMPDIR=$(mktemp -d)` and a single `trap ... EXIT`.
# Fixtures are created *inside* TEST_TMPDIR, so that one trap removes them however the
# suite ends. A second `trap ... EXIT` here would silently replace that one rather than
# compose with it.
#
# --- Uniqueness -----------------------------------------------------------------
#
# Each call gets its own `mktemp -d` directory, so two calls with the same slug produce
# two distinct files. A counter would not: the intended call form
# `spec=$(coverage_fixture_spec ...)` runs the function in a *subshell*, so any variable
# it incremented is discarded and every call returns the same path. Two fixtures built
# for a comparison would silently be one fixture, and the comparison would pass for the
# wrong reason (retro 20, `git_fixture_create`).

# Fail loudly rather than scattering fixtures into the working tree: this library has no
# temp directory of its own by design (see "Why there is no trap in this file").
if [ -z "$TEST_TMPDIR" ]; then
  echo "coverage-fixture-helpers.sh: TEST_TMPDIR is not set — source test-helpers.sh first." >&2
  return 1 2>/dev/null || exit 1
fi

COVERAGE_FIXTURE_ROOT="$TEST_TMPDIR/coverage-fixtures"

coverage_fixture_root() {
  echo "$COVERAGE_FIXTURE_ROOT"
}

# Reject any slug that could place a file outside the fixture root. The check is textual
# and runs before mktemp, so a caller cannot reach the working tree through a path
# component — this is what makes "must NOT write outside TEST_TMPDIR" a property of the
# builder rather than a convention its callers are trusted to keep.
_coverage_fixture_check_slug() {
  local slug="$1"
  case "$slug" in
    "")
      echo "coverage fixture: slug must not be empty" >&2
      return 1
      ;;
    */*|*..*)
      echo "coverage fixture: refusing a slug containing '/' or '..': $slug" >&2
      return 1
      ;;
  esac
  return 0
}

# Reject a --dir that is not inside the fixture root. Both builders end in a redirect to
# a path built from this value, so the same containment rule that guards the slug has to
# guard the directory.
_coverage_fixture_check_dir() {
  local dir="$1"
  case "$dir" in
    *..*)
      echo "coverage fixture: refusing a --dir containing '..': $dir" >&2
      return 1
      ;;
    "$COVERAGE_FIXTURE_ROOT"|"$COVERAGE_FIXTURE_ROOT"/*) ;;
    *)
      echo "coverage fixture: refusing a --dir outside the fixture root: $dir" >&2
      return 1
      ;;
  esac
  if [ ! -d "$dir" ]; then
    echo "coverage fixture: --dir does not exist: $dir" >&2
    return 1
  fi
  return 0
}

# Resolve where a builder should write: the caller's --dir when given (validated), or a
# freshly minted directory named for the slug. Both builders make the same choice, so it
# is made in one place — a second copy would be a second chance to forget the validation.
# Prints the directory.
_coverage_fixture_resolve_dir() {
  local dir="$1"
  local slug="$2"
  if [ -n "$dir" ]; then
    _coverage_fixture_check_dir "$dir" || return 1
    echo "$dir"
    return 0
  fi
  coverage_fixture_dir "$slug"
}

# Mint a fresh fixture directory and print its path. Use when several documents have to
# sit together — a spec and the matrices that name it, or two matrices naming different
# specs.
coverage_fixture_dir() {
  local label="${1:-fixture}"
  _coverage_fixture_check_slug "$label" || return 1
  mkdir -p "$COVERAGE_FIXTURE_ROOT" || return 1
  mktemp -d "$COVERAGE_FIXTURE_ROOT/${label}-XXXXXX"
}

# Build a spec document and print its path.
#
# Usage:
#   spec=$(coverage_fixture_spec 44-spec-fixture \
#            --must   FR1 "A script under cpm/hooks/lib/ accepts either a spec path…" \
#            --must   FR2 "Untraced-requirement detection…" \
#            --should FR10 "Counts stable enough to compare between runs…" \
#            --could  FR11 "Dark mode…" \
#            --wont   "Autonomous cpm:epics" \
#            --wont-labelled FR12 "A requirement ruled out for this iteration" \
#            --nfr    NFR1 "Read-only." \
#            --deferred "FR10, FR11 — not needed to prove the engine." \
#            --out-of-scope "Anything requiring a payment provider.")
#
# The slug is the filename stem, so callers control the shape the roll-up script will
# see (`44-spec-fixture.md`). Requirement bullets are written in the form the script
# parses — `- **FRn** — text` — under the MoSCoW headings a real spec uses.
#
# A section heading is emitted only when that section has entries. A spec with no
# should-haves has no "### Should Have" heading, which is what a hand-written spec looks
# like and therefore what the parser must tolerate. `## Functional Requirements` is
# always emitted, because a spec with no requirements at all is still a spec — and it is
# the fail-closed case Story 5 needs to construct.
#
# `--wont` entries carry no label: spec 44's own Won't Have section is prose items, not
# `FRn` bullets, and a requirement the parser should *not* pick up is only a useful fixture
# if it is shaped the way the real one is. `--wont-labelled` writes the other shape — a
# ruled-out requirement that *does* carry a label — which is what the roll-up has to
# recognise and exclude rather than report as an untraced gap.
coverage_fixture_spec() {
  local slug="$1"
  shift

  _coverage_fixture_check_slug "$slug" || return 1

  local must_labels=() must_texts=()
  local should_labels=() should_texts=()
  local could_labels=() could_texts=()
  local wont_texts=()
  local wont_labels=() wont_labelled_texts=()
  local nfr_labels=() nfr_texts=()
  local deferred_bullets=() out_of_scope_bullets=()
  local dir=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --dir)
        if [ $# -lt 2 ]; then
          echo "coverage_fixture_spec: --dir needs a path" >&2
          return 1
        fi
        dir="$2"
        shift 2
        ;;
      --must)
        if [ $# -lt 3 ]; then
          echo "coverage_fixture_spec: --must needs <label> <text>" >&2
          return 1
        fi
        must_labels+=("$2")
        must_texts+=("$3")
        shift 3
        ;;
      --should)
        if [ $# -lt 3 ]; then
          echo "coverage_fixture_spec: --should needs <label> <text>" >&2
          return 1
        fi
        should_labels+=("$2")
        should_texts+=("$3")
        shift 3
        ;;
      --wont)
        if [ $# -lt 2 ]; then
          echo "coverage_fixture_spec: --wont needs <text>" >&2
          return 1
        fi
        wont_texts+=("$2")
        shift 2
        ;;
      --wont-labelled)
        if [ $# -lt 3 ]; then
          echo "coverage_fixture_spec: --wont-labelled needs <label> <text>" >&2
          return 1
        fi
        wont_labels+=("$2")
        wont_labelled_texts+=("$3")
        shift 3
        ;;
      --could)
        if [ $# -lt 3 ]; then
          echo "coverage_fixture_spec: --could needs <label> <text>" >&2
          return 1
        fi
        could_labels+=("$2")
        could_texts+=("$3")
        shift 3
        ;;
      --nfr)
        if [ $# -lt 3 ]; then
          echo "coverage_fixture_spec: --nfr needs <label> <text>" >&2
          return 1
        fi
        nfr_labels+=("$2")
        nfr_texts+=("$3")
        shift 3
        ;;
      --deferred)
        if [ $# -lt 2 ]; then
          echo "coverage_fixture_spec: --deferred needs <bullet text>" >&2
          return 1
        fi
        deferred_bullets+=("$2")
        shift 2
        ;;
      --out-of-scope)
        if [ $# -lt 2 ]; then
          echo "coverage_fixture_spec: --out-of-scope needs <bullet text>" >&2
          return 1
        fi
        out_of_scope_bullets+=("$2")
        shift 2
        ;;
      *)
        echo "coverage_fixture_spec: unknown argument: $1" >&2
        return 1
        ;;
    esac
  done

  dir=$(_coverage_fixture_resolve_dir "$dir" "$slug") || return 1

  local path="$dir/${slug}.md"
  local i

  {
    printf '# Spec: %s\n\n' "$slug"
    printf '**Date**: 2026-01-01\n\n'
    printf '## Problem Summary\n\nFixture spec built by coverage_fixture_spec.\n\n'
    printf '## Functional Requirements\n\n'

    if [ "${#must_labels[@]}" -gt 0 ]; then
      printf '### Must Have\n\n'
      i=0
      while [ "$i" -lt "${#must_labels[@]}" ]; do
        printf -- '- **%s** — %s\n' "${must_labels[$i]}" "${must_texts[$i]}"
        i=$((i + 1))
      done
      printf '\n'
    fi

    if [ "${#should_labels[@]}" -gt 0 ]; then
      printf '### Should Have\n\n'
      i=0
      while [ "$i" -lt "${#should_labels[@]}" ]; do
        printf -- '- **%s** — %s\n' "${should_labels[$i]}" "${should_texts[$i]}"
        i=$((i + 1))
      done
      printf '\n'
    fi

    if [ "${#could_labels[@]}" -gt 0 ]; then
      printf '### Could Have\n\n'
      i=0
      while [ "$i" -lt "${#could_labels[@]}" ]; do
        printf -- '- **%s** — %s\n' "${could_labels[$i]}" "${could_texts[$i]}"
        i=$((i + 1))
      done
      printf '\n'
    fi

    if [ "${#wont_texts[@]}" -gt 0 ] || [ "${#wont_labels[@]}" -gt 0 ]; then
      printf '### Won'"'"'t Have (this iteration)\n\n'
      i=0
      while [ "$i" -lt "${#wont_texts[@]}" ]; do
        printf -- '- %s\n' "${wont_texts[$i]}"
        i=$((i + 1))
      done
      i=0
      while [ "$i" -lt "${#wont_labels[@]}" ]; do
        printf -- '- **%s** — %s\n' "${wont_labels[$i]}" "${wont_labelled_texts[$i]}"
        i=$((i + 1))
      done
      printf '\n'
    fi

    # The non-functional section carries no MoSCoW subheadings, and its bullets put the
    # label and a summary inside one bold span — `- **NFR1 — Read-only.** text` — which is
    # a different shape from the functional bullets. Both shapes occur in this repository's
    # specs, so a fixture that only produced one would leave the other untested.
    if [ "${#nfr_labels[@]}" -gt 0 ]; then
      printf '## Non-Functional Requirements\n\n'
      i=0
      while [ "$i" -lt "${#nfr_labels[@]}" ]; do
        printf -- '- **%s — %s**\n' "${nfr_labels[$i]}" "${nfr_texts[$i]}"
        i=$((i + 1))
      done
      printf '\n'
    fi

    # The Scope section is written verbatim from whatever the caller passed, because the
    # rule under test is about the *shape of the sentence* — a bullet that leads with its
    # labels defers them, one that merely mentions them does not. A builder that assembled
    # the bullet from labels could only ever produce the first shape, and the second is
    # where the interesting failure lives.
    if [ "${#deferred_bullets[@]}" -gt 0 ] || [ "${#out_of_scope_bullets[@]}" -gt 0 ]; then
      printf '## Scope\n\n'

      if [ "${#out_of_scope_bullets[@]}" -gt 0 ]; then
        printf '### Out of Scope\n\n'
        i=0
        while [ "$i" -lt "${#out_of_scope_bullets[@]}" ]; do
          printf -- '- %s\n' "${out_of_scope_bullets[$i]}"
          i=$((i + 1))
        done
        printf '\n'
      fi

      if [ "${#deferred_bullets[@]}" -gt 0 ]; then
        printf '### Deferred\n\n'
        i=0
        while [ "$i" -lt "${#deferred_bullets[@]}" ]; do
          printf -- '- %s\n' "${deferred_bullets[$i]}"
          i=$((i + 1))
        done
        printf '\n'
      fi
    fi
  } > "$path" || return 1

  echo "$path"
}

# Build a coverage matrix and print its path.
#
# Usage:
#   matrix=$(coverage_fixture_matrix 44-01-coverage-fixture "$spec" \
#              --row FR1 "spec text" "story criterion" "Story 3" '✓' \
#              --row "FR1 (must NOT)" "must NOT …" "must NOT …" "Story 3" '' \
#              --row "(story-originated)" "—" "a criterion with no requirement" "Story 1" '')
#
# The second positional argument becomes the `**Source spec**` field verbatim — including
# a path to a file that does not exist, which is the input Story 5's fail-closed cases
# and Story 6's invariant assertion both need to be able to construct.
#
# Row numbers are assigned in order of appearance. Everything else is written exactly as
# given: the label, spec text, criterion and covered-by cells are passed through, so a
# qualifier-bearing label (`FR1 (must NOT)`), a `(story-originated)` row carrying `—`
# spec text, and an ordinary row are all just different argument values rather than
# different code paths. That is deliberate — a builder with a special case per row shape
# would be asserting the shapes it was told about instead of accepting the ones the
# parser has to handle.
#
# The Verified cell accepts `✓` (verified) or empty / `-` (unverified) and rejects
# anything else. A typo would otherwise become a silently unverified row, and a test
# about verification state would pass for the wrong reason.
#
# The Spec Test Approach column is fixed at `—`. Nothing in spec 44's requirement list
# reads it, and a fixture knob nothing exercises is a knob that rots; adding it is a
# one-line change if a later story needs one.
coverage_fixture_matrix() {
  local slug="$1"
  local source_spec="$2"
  shift 2

  _coverage_fixture_check_slug "$slug" || return 1

  if [ -z "$source_spec" ]; then
    echo "coverage_fixture_matrix: needs a **Source spec** value as its second argument" >&2
    return 1
  fi

  local dir=""
  local epic=""
  local row_labels=() row_spec_texts=() row_criteria=() row_covered=() row_verified=()

  while [ $# -gt 0 ]; do
    case "$1" in
      --dir)
        if [ $# -lt 2 ]; then
          echo "coverage_fixture_matrix: --dir needs a path" >&2
          return 1
        fi
        dir="$2"
        shift 2
        ;;
      --epic)
        if [ $# -lt 2 ]; then
          echo "coverage_fixture_matrix: --epic needs a path" >&2
          return 1
        fi
        epic="$2"
        shift 2
        ;;
      --row)
        if [ $# -lt 6 ]; then
          echo "coverage_fixture_matrix: --row needs <label> <spec-text> <criterion> <covered-by> <verified>" >&2
          return 1
        fi
        case "$6" in
          '✓') row_verified+=('✓') ;;
          ''|'-') row_verified+=('') ;;
          *)
            echo "coverage_fixture_matrix: verified cell must be '✓', '' or '-', got: $6" >&2
            return 1
            ;;
        esac
        row_labels+=("$2")
        row_spec_texts+=("$3")
        row_criteria+=("$4")
        row_covered+=("$5")
        shift 6
        ;;
      *)
        echo "coverage_fixture_matrix: unknown argument: $1" >&2
        return 1
        ;;
    esac
  done

  if [ -n "$dir" ]; then
    _coverage_fixture_check_dir "$dir" || return 1
  else
    dir=$(coverage_fixture_dir "$slug") || return 1
  fi

  [ -n "$epic" ] || epic="docs/epics/${slug}.md"

  local path="$dir/${slug}.md"
  local i=0

  {
    printf '# Coverage Matrix: %s\n\n' "$slug"
    printf '**Source spec**: %s\n' "$source_spec"
    printf '**Epic**: %s\n' "$epic"
    printf '**Date**: 2026-01-01\n\n'
    printf '> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.\n\n'
    printf '| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |\n'
    printf '|---|---|---|---|---|---|---|\n'
    local verified_cell
    while [ "$i" -lt "${#row_labels[@]}" ]; do
      # `| ✓ |` when verified, `| |` when not — the exact pair cpm:do's proof recording
      # edits between. A fixture that wrote `|  |` would still parse under any sane
      # whitespace handling, and would stop being a faithful stand-in for the documents
      # the script actually reads.
      if [ -n "${row_verified[$i]}" ]; then
        verified_cell=" ✓ "
      else
        verified_cell=" "
      fi
      printf '| %s | %s | %s | %s | %s | — |%s|\n' \
        "$((i + 1))" \
        "${row_labels[$i]}" \
        "${row_spec_texts[$i]}" \
        "${row_criteria[$i]}" \
        "${row_covered[$i]}" \
        "$verified_cell"
      i=$((i + 1))
    done
  } > "$path" || return 1

  echo "$path"
}

# Count the fixture directories currently on disk. Used by tests that need a positive
# control before asserting an absence — "nothing written outside TEST_TMPDIR" is
# satisfied equally by a correct builder and by one that wrote nothing at all.
coverage_fixture_count() {
  if [ ! -d "$COVERAGE_FIXTURE_ROOT" ]; then
    echo 0
    return 0
  fi
  find "$COVERAGE_FIXTURE_ROOT" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' '
}

# --- Exercising the roll-up against those fixtures ------------------------------
#
# Everything above builds the documents a roll-up test feeds in. These three run the
# script over them and read what came back, which is the other half of the same job — a
# suite that sources this file to build a fixture always then has to run something
# against it.
#
# **Why they are here rather than copied into each suite.** The hazard is not two copies
# disagreeing; two test runners that differ produce no wrong answers. It is a *third*
# suite calling `bash coverage-rollup.sh` plainly and never learning that the environment
# matters — the run would pass while testing a condition no skill is ever in. Promoted at
# the second call site (test-coverage-rollup.sh and test-environmental-untraced.sh) rather
# than the third, per retro 25.

COVERAGE_ROLLUP_SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/coverage-rollup.sh"

# Run coverage-rollup.sh the way a skill does: with CLAUDE_PROJECT_DIR genuinely unset,
# which is the environment a /cpm:* Bash call actually has (AD5, spec 43's defect). That
# unsetting is the contract this function exists to carry. Diagnostics go to stderr and
# are dropped, so only records reach the caller's assertions.
coverage_rollup_run() {
  run_without_env CLAUDE_PROJECT_DIR -- bash "$COVERAGE_ROLLUP_SCRIPT" "$@" 2>/dev/null
}

# The same run, reporting its exit code instead of its records — for the `--verdict`
# cases, where the code is the thing under test and the output is not.
coverage_rollup_rc() {
  run_without_env CLAUDE_PROJECT_DIR -- bash "$COVERAGE_ROLLUP_SCRIPT" "$@" >/dev/null 2>&1
  echo $?
}

# How many records of one type a captured run emitted. Records are tab-separated with the
# type in field 1 (spec 44, NFR4), so this reads the format rather than the text.
coverage_count_type() {
  printf '%s\n' "$1" | awk -F'\t' -v t="$2" '$1 == t { n++ } END { print n + 0 }'
}

# The labels of every requirement a captured run put in one state -- untraced, delivered
# or in-progress -- sorted, so a caller can compare against a set rather than probing for
# memberships one at a time. Set equality is the stronger assertion: it fails on a label
# that should not be in the state as well as one that should.
coverage_states_in() {
  printf '%s\n' "$1" | awk -F'\t' -v want="$2" \
    '$1 == "STATE" && $4 == want { print $2 }' | LC_ALL=C sort
}

# Every way `REQ = STATE ∪ EXCLUDED` fails to be an exact partition of a captured run, one
# per line, empty when it holds (spec 44 NFR2, spec 46 NFR4). The optional second argument
# labels each line, for callers checking many runs in a loop.
#
# Reported as errors rather than as a boolean because the three failures mean different
# things: a label in neither set was silently dropped, a label in both is double-counted,
# and a STATE or EXCLUDED with no REQ behind it came from nowhere. A caller asserting the
# result is empty gets told which of the three it hit.
coverage_partition_errors() {
  printf '%s\n' "$1" | awk -F'\t' -v spec="${2:-}" '
    BEGIN { prefix = (spec == "") ? "" : spec ": " }
    $1 == "REQ"      { req[$2] = 1 }
    $1 == "STATE"    { st[$2]++ }
    $1 == "EXCLUDED" { ex[$2]++ }
    END {
      for (l in req) {
        c = st[l] + ex[l]
        if (c != 1) printf "%s%s appears in %d of STATE/EXCLUDED\n", prefix, l, c
      }
      for (l in st) if (!(l in req)) printf "%s%s has a STATE but no REQ\n", prefix, l
      for (l in ex) if (!(l in req)) printf "%s%s is EXCLUDED but has no REQ\n", prefix, l
    }
  '
}
