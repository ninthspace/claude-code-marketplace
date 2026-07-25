#!/bin/bash
# inspect-run.sh — The whole deterministic half of /cpm:inspect, in one call
#
# Spec 42 R9 and Epic 42-05 Story 3: "a single invocation resolves a selector, runs the
# join, answers both gap queries, produces findings, and emits JSON — in one pass".
#
# Everything the tool does except the findings is deterministic, and this is where it is
# sequenced. Sourcing five libraries and calling them in the right order with the right
# intermediate files is not a judgement — it is a procedure, and a procedure carried in
# prose is one the next reader can perform slightly differently without anything saying so.
#
# --- What is deliberately *not* here -------------------------------------------------
#
# **The findings.** R5's review reads code and forms an opinion, which is the one part of
# `/cpm:inspect` that genuinely needs a model. `inspect_run` prepares everything that pass
# needs — the payload it reads, the order it should read in, the budget it must stay inside
# — and stops. Emitting a finding is not something this file could do, and pretending
# otherwise would put an empty findings list into a record that reads as "nothing found".
#
# **Publishing.** Separately confirmed by requirement, and never part of a run.
#
# --- Which adapters run -------------------------------------------------------------------
#
# Two registries, because the two directions are separate contracts. `INSPECT_LINK_ADAPTERS`
# names the reverse channels (files → intent) the join consumes; `INSPECT_INTENT_ADAPTERS`
# names the forward ones (intent → commits) resolution consumes. Each defaults to what this
# plugin ships, and each is registered only if its function is actually defined, so a caller
# that did not source an adapter gets a run without that channel rather than an error — R7's
# supported zero-channel state rather than a misconfiguration.
#
# The manifest reports which ones ran, and that line is the point of it. An adapter that
# found nothing and an adapter that never ran produce the identical empty result, and the
# manifest is the only place they can be told apart — the same distinction R4 draws between
# "none found" and "not answerable", borrowed here because it is the same mistake.
#
# Intent adapters are registered before resolution and link adapters after it, which is not
# a style choice: a git-anchored selector never consults an intent adapter, and registering
# one must not be able to change what `--since HEAD~2` resolves to.
#
# --- Output ------------------------------------------------------------------------------
#
# A manifest on stdout, one `KEY<TAB>value` per line. The artifacts themselves are files,
# because the payload and the link set are both too large to thread through a variable and
# every downstream function takes a path anyway:
#
#   SELECTOR<TAB><selector>
#   DIRECTION<TAB>git|intent
#   ADAPTER<TAB><name>              link adapters; zero or more, in registration order
#   INTENT_ADAPTER<TAB><name>       intent adapters; likewise
#   COMMITS<TAB><n>
#   FILES<TAB><n>
#   CHANGESET<TAB><path>
#   LINKSET<TAB><path>
#   GAPS<TAB><path>
#   SELECTION<TAB><path>
#   PAYLOAD<TAB><path>
#   RECORD<TAB><path>               relative to the repository root

INSPECT_RUN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Sourced one at a time rather than through a loop, matching every other library here. The
# order matters in one place: `gap-queries.sh` must be in scope before `review_select` runs,
# because that is how it discovers whether it can prioritise orphans.
if ! declare -f inspect_resolve >/dev/null 2>&1; then
  # shellcheck source=./inspect-resolve.sh
  source "$INSPECT_RUN_DIR/inspect-resolve.sh"
fi

if ! declare -f linkset_register >/dev/null 2>&1; then
  # shellcheck source=./linkset.sh
  source "$INSPECT_RUN_DIR/linkset.sh"
fi

if ! declare -f linkset_join >/dev/null 2>&1; then
  # shellcheck source=./linkset-join.sh
  source "$INSPECT_RUN_DIR/linkset-join.sh"
fi

if ! declare -f gap_report >/dev/null 2>&1; then
  # shellcheck source=./gap-queries.sh
  source "$INSPECT_RUN_DIR/gap-queries.sh"
fi

if ! declare -f review_select >/dev/null 2>&1; then
  # shellcheck source=./review.sh
  source "$INSPECT_RUN_DIR/review.sh"
fi

if ! declare -f inspect_write >/dev/null 2>&1; then
  # shellcheck source=./inspect-record.sh
  source "$INSPECT_RUN_DIR/inspect-record.sh"
fi

# `-` rather than `:-`, so a caller that sets this to the empty string gets a run with no
# link adapters at all rather than silently getting the default back. That is R7's
# zero-channel state asked for deliberately, and it should be reachable.
INSPECT_LINK_ADAPTERS="${INSPECT_LINK_ADAPTERS-gitnative cpm}"
INSPECT_INTENT_ADAPTERS="${INSPECT_INTENT_ADAPTERS-cpm}"

# Run the deterministic pipeline.
#   inspect_run <repo> <work-dir> <budget> <selector>...
inspect_run() {
  local repo="$1"
  local work="$2"
  local budget="$3"
  shift 3

  if [ -z "$repo" ] || [ ! -d "$repo" ]; then
    echo "inspect-run: no such repository directory: $repo" >&2
    return 1
  fi

  if [ -z "$work" ]; then
    echo "inspect-run: no working directory given" >&2
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "inspect-run: no selector given" >&2
    return 1
  fi

  mkdir -p "$work" || return 1

  local selector="$*"
  local changeset="$work/changeset"
  local linkset="$work/linkset"
  local gaps="$work/gaps"
  local selection="$work/selection"
  local payload="$work/payload"

  # 1 — resolve. Failures here are R1's and are already reported with the selector echoed
  # back, so the exit status is passed through rather than re-described.
  changeset_intent_reset
  local intent_registered=""
  local name
  for name in $INSPECT_INTENT_ADAPTERS; do
    if declare -f "${name}_intent_commits" >/dev/null 2>&1; then
      changeset_intent_register "$name" || return 1
      intent_registered="${intent_registered}${intent_registered:+ }$name"
    fi
  done

  local direction
  direction=$(inspect_selector_direction "$repo" "$@") || return 1
  inspect_resolve "$repo" "$@" > "$changeset" || return 1

  # 2 — join. Registration is rebuilt from scratch each run so a second call in the same
  # shell cannot inherit whatever the first one left registered.
  linkset_reset
  local registered=""
  for name in $INSPECT_LINK_ADAPTERS; do
    if declare -f "${name}_link_changeset" >/dev/null 2>&1; then
      linkset_register "$name" || return 1
      registered="${registered}${registered:+ }$name"
    fi
  done

  linkset_join "$repo" "$changeset" > "$linkset" || return 1

  # 3 — the gap queries. `gap_report` answers R3 from the link set and R4 from the
  # repository, and reports R4 as unanswerable rather than clean when no channel carries
  # claims.
  gap_report "$repo" "$changeset" < "$linkset" > "$gaps" || return 1

  # 4 — the review's inputs, not the review. `review_select` needs the gap queries to
  # prioritise orphans, and they are in scope here because this file sourced them.
  review_select "$changeset" "$budget" < "$linkset" > "$selection" || return 1
  review_payload "$changeset" < "$linkset" > "$payload" || return 1

  # 5 — the record. Written last, so a run that fails earlier leaves no record claiming to
  # describe it.
  local record
  record=$(inspect_write "$repo" "$changeset" "$selector" < "$linkset") || return 1

  printf 'SELECTOR\t%s\n' "$selector"
  printf 'DIRECTION\t%s\n' "$direction"
  for name in $registered; do printf 'ADAPTER\t%s\n' "$name"; done
  for name in $intent_registered; do printf 'INTENT_ADAPTER\t%s\n' "$name"; done
  printf 'COMMITS\t%s\n' "$(changeset_commits < "$changeset" | grep -c '[^[:space:]]')"
  printf 'FILES\t%s\n' "$(changeset_files < "$changeset" | grep -c '[^[:space:]]')"
  printf 'CHANGESET\t%s\n' "$changeset"
  printf 'LINKSET\t%s\n' "$linkset"
  printf 'GAPS\t%s\n' "$gaps"
  printf 'SELECTION\t%s\n' "$selection"
  printf 'PAYLOAD\t%s\n' "$payload"
  printf 'RECORD\t%s\n' "$record"
}
