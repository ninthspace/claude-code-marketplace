#!/bin/bash
# linkset-join.sh — The adapter registry and the join
#
# Spec 42 R7: the join "reads every intent channel present and **owns none of them**".
# `linkset.sh` is the structure adapters produce; this is what runs them and merges the
# result. AD2's pluggable seam is these two files together.
#
# --- The adapter contract ---------------------------------------------------------
#
# An adapter is a shell function. Registering the name `foo` means `foo_link_changeset`
# exists and behaves as follows:
#
#   foo_link_changeset <repo> <changeset-file>
#
#     stdout : zero or more link-set records (see linkset.sh), any order
#     exit 0 : answered — this adapter's channel is present in this repository, and what
#              it printed (possibly nothing) is its complete answer
#     exit 2 : cannot answer — this adapter has no channel here at all. Not an error, and
#              not the same as having a channel that linked nothing
#     exit 1 : error — the channel is present but the adapter failed to read it
#
# **Order is not part of the contract.** An adapter may emit records however it finds
# them; `linkset_normalise` orders them before they leave the join, so a change to an
# adapter's internal iteration can never change the output. R6 needs byte-identical runs,
# and that must not depend on how each adapter happens to walk a directory.
#
# **The change set is read-only input, and adapters may not add to it.** An adapter that
# emitted a LINK for a path outside the change set would put a phantom file into R3's
# orphan report, which is the output people act on. The join rejects it, attributed to
# the adapter that did it — see `_linkset_foreign_paths`.
#
# **Why exit 2 exists.** The two adapters this epic ships are asymmetric in a way that
# matters two epics downstream: the CPM adapter carries verification claims (coverage
# matrices) and the git-native adapter structurally cannot — commit trailers and branch
# names record *why* a change happened, never whether it was verified. R4's
# unbacked-claims query must therefore distinguish "no unbacked claims" from "no channel
# here can tell you about claims", and a two-outcome contract cannot express that. This
# mirrors the same channel on the intent contract in `changeset-intent.sh`, so both seams
# share one exit-code vocabulary rather than each inventing its own.
#
# --- Zero adapters is a supported state -------------------------------------------
#
# `linkset_join` with nothing registered succeeds and emits nothing. R7 requires the join
# to "produce a usable result with **zero** cooperating channels", and R9 says what that
# result is: "the review still runs and every file is reported as an orphan".
#
# This is the one place this contract deliberately differs from the intent contract next
# door, which *errors* on zero adapters — and the difference is not an inconsistency. An
# intent selector with no adapters has nothing usable to produce: no channel can say what
# `epic 41-03` refers to, so R1's must-NOT applies and it errors with the selector echoed
# back. Here the change set has already been resolved by other means; zero links over a
# known set of files is a complete and correct answer, and it is exactly the answer R9
# asks for.

LINKSET_JOIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! declare -f linkset_validate >/dev/null 2>&1; then
  # shellcheck source=./linkset.sh
  source "$LINKSET_JOIN_DIR/linkset.sh"
fi

LINKSET_ADAPTERS=""

# --- Registry ------------------------------------------------------------------------

# Register an adapter by name. Registration is explicit rather than discovered by naming
# convention, so which channels are active is a statement a caller makes rather than an
# accident of what happens to be sourced.
linkset_register() {
  local name="$1"

  if ! declare -f "${name}_link_changeset" >/dev/null 2>&1; then
    echo "linkset-join: no such adapter: ${name}_link_changeset is not defined" >&2
    return 1
  fi

  case " $LINKSET_ADAPTERS " in
    *" $name "*) return 0 ;;
  esac

  LINKSET_ADAPTERS="${LINKSET_ADAPTERS}${LINKSET_ADAPTERS:+ }$name"
}

# Forget every registered adapter.
linkset_reset() {
  LINKSET_ADAPTERS=""
}

# Print the registered adapter names, one per line, in registration order.
linkset_adapters() {
  local name
  for name in $LINKSET_ADAPTERS; do
    echo "$name"
  done
}

# --- Shared enforcement ----------------------------------------------------------------

# Read a link set on stdin; print any LINK path that is not a FILE in the given change
# set, one per line. Silence means every link names a file that actually changed.
#
# Exposed rather than inlined into the join because the conformance harness needs the
# same check per-adapter. One implementation, two callers — a second copy in the harness
# could drift and would then be certifying adapters against a rule the join does not
# actually apply.
_linkset_foreign_paths() {
  local changeset_file="$1"

  local linked known
  linked=$(linkset_linked_files | LC_ALL=C sort -u | grep -v '^$')
  [ -n "$linked" ] || return 0

  known=$(changeset_files < "$changeset_file" | LC_ALL=C sort -u | grep -v '^$')

  LC_ALL=C comm -23 <(printf '%s\n' "$linked") <(printf '%s\n' "$known")
}

# --- Precedence ---------------------------------------------------------------------------

# Collapse a link set on stdin so that each (file, intent) pair and each intent ID appears
# once. R7: "A declared marker always wins over a derived one for the same (file, intent)
# pair."
#
# **This runs in the join and nowhere else.** Every adapter feeds it and none implements
# it, which is what makes precedence a property of the system rather than an agreement
# between adapters that happen to be registered together. An adapter cannot resolve
# precedence even in principle: it sees only its own channel, and the whole question is
# what happens when two channels disagree.
#
# Two collapses, because two things can be said twice:
#
# **(file, intent)** — declared wins, per R7. Nothing else can happen: `absent` never
# reaches here (linkset_validate rejects it from an adapter), so the only contest is
# declared against derived, and it has one right answer.
#
# **intent ID** — the criteria are silent on this and it needs an answer anyway: the
# git-native adapter emits `unknown` status with the ID as the title because git knows
# neither, while the CPM adapter reads both from the document. A record that says nothing
# must not be able to overwrite one that says something, so a known status outranks
# `unknown`; ties break on LC_ALL=C order so the result never depends on registration
# order. This is *not* the confidence model — it is deduplication with a tie-break, and
# it deliberately makes no claim about which adapter is more trustworthy.
linkset_resolve_precedence() {
  LC_ALL=C awk -F'\t' '
    $1 == "LINK" {
      key = $2 "\t" $3
      if (!(key in link) || $4 == "declared") link[key] = $4
      next
    }
    $1 == "INTENT" {
      id = $2
      rank = ($3 == "unknown") ? 0 : 1
      if (!(id in irank) \
          || rank > irank[id] \
          || (rank == irank[id] && ($3 "\t" $4) < (istatus[id] "\t" ititle[id]))) {
        irank[id] = rank; istatus[id] = $3; ititle[id] = $4
      }
      next
    }
    { print }
    END {
      for (id in irank) printf "INTENT\t%s\t%s\t%s\n", id, istatus[id], ititle[id]
      for (key in link)  printf "LINK\t%s\t%s\n", key, link[key]
    }
  '
}

# --- Labels ---------------------------------------------------------------------------------
#
# Read a resolved link set on stdin and print one record per file in the change set:
#
#   LABEL<TAB><path><TAB><declared|derived|absent>
#
# R7 lists declared, derived and absent as one vocabulary, but they are not three kinds of
# the same thing: the first two describe a *link* and the third describes a *file* that
# has none. So the label is computed per file, which is the granularity R3's orphan query
# and the artifact page both need — "which files have no intent behind them" is not a
# question about links.
#
# A file inherits the strongest confidence among its links. `absent` is emitted only here,
# by the join, over the complete set of adapter results; no adapter can claim it, because
# no adapter is in a position to know that every *other* adapter also found nothing.
linkset_labels() {
  local changeset_file="$1"

  if [ -z "$changeset_file" ] || [ ! -f "$changeset_file" ]; then
    echo "linkset-join: no such change set file: $changeset_file" >&2
    return 1
  fi

  LC_ALL=C awk -F'\t' -v cs="$changeset_file" '
    BEGIN {
      # Change-set FILE records are already sorted and deduplicated, so reading them in
      # order gives a deterministic output order without a second sort.
      while ((getline line < cs) > 0) {
        n = split(line, f, "\t")
        if (n >= 2 && f[1] == "FILE" && f[2] != "" && !(f[2] in seen)) {
          seen[f[2]] = 1
          order[++count] = f[2]
        }
      }
      close(cs)
    }
    $1 == "LINK" && ($2 in seen) {
      if ($4 == "declared") label[$2] = "declared"
      else if (label[$2] != "declared") label[$2] = "derived"
    }
    END {
      for (i = 1; i <= count; i++) {
        p = order[i]
        printf "LABEL\t%s\t%s\n", p, (p in label ? label[p] : "absent")
      }
    }
  '
}

# --- The join ---------------------------------------------------------------------------

# Resolve a change set to link-set records on stdout.
#   linkset_join <repo> <changeset-file>
linkset_join() {
  local repo="$1"
  local changeset_file="$2"

  if [ -z "$repo" ] || [ ! -d "$repo" ]; then
    echo "linkset-join: no such repository directory: $repo" >&2
    return 1
  fi

  if [ -z "$changeset_file" ] || [ ! -f "$changeset_file" ]; then
    echo "linkset-join: no such change set file: $changeset_file" >&2
    return 1
  fi

  local records="" name out rc offending foreign

  for name in $LINKSET_ADAPTERS; do
    out=$("${name}_link_changeset" "$repo" "$changeset_file" 2>/dev/null)
    rc=$?

    case "$rc" in
      2) continue ;;
      0) ;;
      *)
        echo "linkset-join: adapter '$name' failed on this change set" >&2
        return 1
        ;;
    esac

    [ -n "$out" ] || continue

    # A contract violation is reported against the adapter that committed it, never
    # filtered. Dropping bad records instead would leave a shorter link set and a longer
    # orphan list, which reads as a finding about the code rather than a bug in an
    # adapter.
    offending=$(printf '%s\n' "$out" | linkset_validate)
    if [ -n "$offending" ]; then
      echo "linkset-join: adapter '$name' emitted an invalid record: $(printf '%s' "$offending" | head -1)" >&2
      return 1
    fi

    foreign=$(printf '%s\n' "$out" | _linkset_foreign_paths "$changeset_file")
    if [ -n "$foreign" ]; then
      echo "linkset-join: adapter '$name' linked a file that is not in the change set: $(printf '%s' "$foreign" | head -1)" >&2
      return 1
    fi

    records="${records}${out}"$'\n'
  done

  # Zero adapters, or every adapter answering with nothing, is a complete answer: every
  # file in the change set is an orphan. Emitting nothing and succeeding is what R9's
  # degradation requirement rests on, so there is deliberately no emptiness check here —
  # the mirror-image of `changeset_resolve_intent`, which must have one.
  [ -n "$records" ] || return 0

  printf '%s\n' "$records" | grep -v '^$' | linkset_resolve_precedence | linkset_normalise
}
