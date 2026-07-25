#!/bin/bash
# link-adapter-cpm.sh — The CPM link adapter
#
# Spec 42 AD2: "**CPM is one adapter among several**, not the substrate." It implements
# the contract in `linkset-join.sh`; register it with `linkset_register cpm`.
#
# It reads epic documents and coverage matrices — the artifacts `cpm:epics` writes — and
# turns them into intent records. It is the only adapter in this iteration that carries
# **verification claims**, which is what makes R4's unbacked-claims query answerable at
# all: "intent records marked done or verified with no test naming them" needs a channel
# that records a claim, and git has none.
#
# --- What it reads and what it claims ---------------------------------------------
#
#   an epic doc in a commit, linked to its own record  →  declared
#   other files in that same commit                    →  derived   (co-commit)
#
# **Co-commit is the strongest derived signal** (AD2), and it works here for a specific
# reason: `cpm:do` updates planning documents in the same working tree as the code, so a
# story's status change and the code that earned it land in one commit. That is a fact
# about how CPM operates, not a general property of repositories, which is why this
# signal lives in the CPM adapter rather than the git-native one.
#
# **An epic doc is declared against its own record because it *is* that record.** No
# inference is involved: the file at `docs/epics/42-02-epic-*.md` is the epic `42-02`.
# Every other file in the commit is derived, because "committed together" is evidence and
# not a statement.
#
# --- Time-window derivation is not implemented, and that is the point --------------
#
# AD2 rejects it explicitly: "Inferring a link from a commit falling inside an intent
# record's active window does not survive contact with reality... every epic, every
# verification block and every commit in spec 41's five-epic chain carries the same date,
# because `cpm:do` executes a whole chain in one sitting. That is the normal case, not an
# anomaly."
#
# Nothing here reads a commit date, an epic `**Date**:` field, or a file mtime. The
# consequence is deliberate and worth stating plainly: a commit that changes code and a
# *separate* commit that updates the epic doc are not linked, however close together they
# landed. Derived resolution is **bounded by commit granularity** (AD2), and the honest
# failure is an orphan rather than a plausible-looking link.
#
# --- Intent ID shapes -----------------------------------------------------------------
#
#   epic 42-02          an epic document
#   story 42-02.3       a story within it
#   spec 42 R7          a requirement named in a story's `**Satisfies**` field
#
# These match the selector vocabulary spec 42 R1 uses (`epic 41-03`, `story 41-03.2`) and
# the reference form the spec's own example header comment uses ("spec 41 R4, AD4"). That
# is not cosmetic: intent IDs share one unprefixed namespace across adapters, so a commit
# trailer reading `Refs: epic 42-02` resolves to the *same* record this adapter builds
# from the document, and Story 4's precedence can then prefer the declared marker over
# the derived one. Requirement IDs carry their spec number because `R7` alone would
# collide between specs.

LINK_ADAPTER_CPM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! declare -f linkset_emit_link >/dev/null 2>&1; then
  # shellcheck source=./linkset.sh
  source "$LINK_ADAPTER_CPM_DIR/linkset.sh"
fi

# Matches both epic filename shapes. `cpm:epics` writes the two-part form
# (`42-02-epic-slug.md`), and flat legacy epics (`15-epic-slug.md`) coexist permanently
# rather than being migrated, so an adapter that recognised only the current shape would
# silently report every older epic's work as orphaned.
CPM_EPIC_DOC_PATTERN='^docs/epics/[0-9]+(-[0-9]+)?-epic-.*\.md$'

# A coverage matrix belongs to its epic as plainly as the epic document does — its
# filename names the epic and its `**Epic**:` field names the file. So it is part of the
# record, not evidence about it: linking it `derived` by co-commit would understate a
# relationship that needs no inference, and would put a planning artifact in the same
# confidence class as the code it was committed beside.
CPM_COVERAGE_DOC_PATTERN='^docs/epics/[0-9]+(-[0-9]+)?-coverage-.*\.md$'
CPM_RECORD_DOC_PATTERN='^docs/epics/[0-9]+(-[0-9]+)?-(epic|coverage)-.*\.md$'

# Derive the epic number from an epic or coverage doc path:
# `docs/epics/42-02-epic-foo.md` → `42-02`, and likewise for `-coverage-`.
_cpm_epic_number() {
  basename "$1" | sed -nE 's/^([0-9]+(-[0-9]+)?)-(epic|coverage)-.*\.md$/\1/p'
}

# The coverage matrix that accompanies an epic doc, by the documented rule: replace
# `-epic-` with `-coverage-` in the filename. Prints nothing if there is none — a matrix
# is optional, and its absence costs criteria, not intent records.
_cpm_coverage_path() {
  local doc="$1"
  local candidate="${doc%/*}/$(basename "$doc" | sed 's/-epic-/-coverage-/')"
  [ -f "$candidate" ] && printf '%s\n' "$candidate"
}

# Map a CPM `**Status**:` value onto the link-set vocabulary. Anything that is not
# explicitly finished is `open`; nothing here guesses at `unknown`, because an epic doc
# always states a status even when that status is "Pending".
_cpm_status() {
  case "$1" in
    Complete | complete | Done | done) echo "done" ;;
    "") echo "unknown" ;;
    *) echo "open" ;;
  esac
}

# Emit INTENT records (and CRITERION records, if a coverage matrix is present) for one
# epic document. Reads the file; writes link-set records on stdout.
_cpm_doc_records() {
  local doc="$1"
  local epic_num="$2"

  local spec_no epic_title epic_status
  spec_no=$(sed -nE 's/^\*\*Source spec\*\*:.*specifications\/([0-9]+)-.*/\1/p' "$doc" | head -1)
  epic_title=$(sed -nE '1s/^# (.*)$/\1/p' "$doc")
  epic_status=$(sed -nE 's/^\*\*Status\*\*: (.*)$/\1/p' "$doc" | head -1)

  linkset_emit_intent "epic $epic_num" "$(_cpm_status "$epic_status")" "${epic_title:-epic $epic_num}"

  # One line per story: number, status, satisfies, title. Emitted on the next `##` or at
  # EOF rather than on any single field, because the metadata block's field order is not
  # guaranteed and `**Satisfies**` is optional.
  local stories
  stories=$(awk '
    function flush() {
      if (story != "") printf "%s\t%s\t%s\t%s\n", story, status, satisfies, title
      story = ""; status = ""; satisfies = ""; title = ""
    }
    /^## / {
      flush()
      title = $0
      sub(/^## /, "", title)
      sub(/[ ]+\[[a-z]+\][ ]*$/, "", title)
      next
    }
    /^\*\*Story\*\*: / { story = $0; sub(/^\*\*Story\*\*: /, "", story); next }
    /^\*\*Status\*\*: / { if (title != "") { status = $0; sub(/^\*\*Status\*\*: /, "", status) } next }
    /^\*\*Satisfies\*\*: / { satisfies = $0; sub(/^\*\*Satisfies\*\*: /, "", satisfies); next }
    END { flush() }
  ' "$doc")

  local line num status satisfies title req
  while IFS=$'\t' read -r num status satisfies title; do
    [ -n "$num" ] || continue
    linkset_emit_intent "story $epic_num.$num" "$(_cpm_status "$status")" "$title"

    # `**Satisfies**` names the spec requirements a story delivers. Each becomes an intent
    # record of its own, so provenance can be asked at requirement level — which is the
    # level the spec's own gap queries are stated in.
    [ -n "$satisfies" ] && [ -n "$spec_no" ] || continue
    printf '%s\n' "$satisfies" | tr ',' '\n' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' \
      | sed -E 's/[[:space:]]*\(.*\)$//' | grep -E '^[A-Z]+[0-9]+$' \
      | while IFS= read -r req; do
          [ -n "$req" ] && linkset_emit_intent "spec $spec_no $req" "unknown" "$req"
        done
  done <<EOF
$stories
EOF

  local matrix
  matrix=$(_cpm_coverage_path "$doc")
  [ -n "$matrix" ] || return 0

  # The coverage matrix is where a *verification claim* lives, and it is the reason this
  # adapter exists. Story status says the work is finished; the matrix says the criterion
  # was verified. R4 asks about the second, never the first — a story marked Complete
  # over an unverified row is exactly the gap the query is for.
  awk -F'|' -v epic="$epic_num" '
    NF > 6 && $2 ~ /^[ ]*[0-9]+[ ]*$/ {
      crit = $5; story = $6; verified = $8
      gsub(/^[ ]+|[ ]+$/, "", crit)
      gsub(/^[ ]+|[ ]+$/, "", story)
      gsub(/^[ ]+|[ ]+$/, "", verified)
      sub(/^Story[ ]+/, "", story)
      if (story ~ /^[0-9]+$/ && crit != "")
        printf "CRITERION\tstory %s.%s\t%s\t%s\n", epic, story, (verified == "✓" ? "verified" : "unverified"), crit
    }
  ' "$matrix"
}

# The optional capability companion to the contract. See gap-queries.sh.
#
# `criteria` says this adapter can carry verification claims, which is what makes spec 42
# R4 answerable through it. It is the only adapter in this iteration that can say so —
# git records why a change happened and never whether it was checked — and R4's must-NOT
# exists precisely so that "no unbacked claims" is never printed by a configuration where
# no adapter could have found one.
#
# Saying so is not the same as being able to answer here. An adapter that declines a
# repository (`exit 2`, no `docs/epics/`) cannot answer it whatever it declares, which is
# why `gap_r4_answerability` runs the capable adapters rather than trusting this alone.
cpm_link_capabilities() {
  printf 'criteria\n'
}

# The contract. See linkset-join.sh.
cpm_link_changeset() {
  local repo="$1"
  local changeset_file="$2"

  [ -n "$repo" ] && [ -d "$repo" ] || return 1
  [ -n "$changeset_file" ] && [ -f "$changeset_file" ] || return 1

  git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 || return 2

  # No epic documents means CPM is not a channel in this repository. Exit 2 rather than
  # an empty exit 0: R4 must be able to tell "no unbacked claims" from "nothing here can
  # tell you about claims", and this is the adapter that distinction exists for.
  [ -d "$repo/docs/epics" ] || return 2

  local known
  known=$(changeset_files < "$changeset_file" | LC_ALL=C sort -u | grep -v '^$')
  [ -n "$known" ] || return 0

  local commits
  commits=$(changeset_commits < "$changeset_file" | grep -v '^$')
  [ -n "$commits" ] || return 0

  local sha commit_files docs others doc epic_num ids id path
  while IFS= read -r sha; do
    [ -n "$sha" ] || continue

    commit_files=$(git -C "$repo" diff-tree --no-commit-id --name-only -r --root "$sha" 2>/dev/null \
      | LC_ALL=C sort -u | grep -v '^$')
    [ -n "$commit_files" ] || continue

    docs=$(printf '%s\n' "$commit_files" | grep -E "$CPM_EPIC_DOC_PATTERN")
    [ -n "$docs" ] || continue

    # Every file this commit touched that is also in the change set. Split into the epic
    # docs themselves (declared against their own record) and everything else (derived by
    # co-commit).
    local in_set
    in_set=$(LC_ALL=C comm -12 <(printf '%s\n' "$commit_files") <(printf '%s\n' "$known"))
    [ -n "$in_set" ] || continue

    others=$(printf '%s\n' "$in_set" | grep -Ev "$CPM_RECORD_DOC_PATTERN")

    ids=""
    while IFS= read -r doc; do
      [ -n "$doc" ] || continue
      [ -f "$repo/$doc" ] || continue

      epic_num=$(_cpm_epic_number "$doc")
      [ -n "$epic_num" ] || continue

      local doc_records
      doc_records=$(_cpm_doc_records "$repo/$doc" "$epic_num")
      printf '%s\n' "$doc_records"

      # The document is the record: no inference, so declared. Only when the document is
      # itself part of the change set — a commit may touch an epic doc that a narrower
      # selector excluded, and the contract forbids linking a file outside the set.
      if printf '%s\n' "$in_set" | grep -qxF -- "$doc"; then
        linkset_emit_link "$doc" "epic $epic_num" "declared"
      fi

      ids="${ids}$(printf '%s\n' "$doc_records" | linkset_intent_ids)"$'\n'
    done <<EOF
$docs
EOF

    ids=$(printf '%s\n' "$ids" | LC_ALL=C sort -u | grep -v '^$')

    # Coverage matrices are declared against their own epic, for the reason
    # CPM_COVERAGE_DOC_PATTERN gives. Emitted after the document loop and only for an
    # epic whose record was actually built: a commit may carry a matrix whose epic
    # document it did not touch, and a link to a record that is not in the output is a
    # dangling reference the artifact page would render as a blank.
    local cover cover_num
    while IFS= read -r cover; do
      [ -n "$cover" ] || continue
      cover_num=$(_cpm_epic_number "$cover")
      [ -n "$cover_num" ] || continue
      printf '%s\n' "$ids" | grep -qxF -- "epic $cover_num" \
        && linkset_emit_link "$cover" "epic $cover_num" "declared"
    done <<EOF
$(printf '%s\n' "$in_set" | grep -E "$CPM_COVERAGE_DOC_PATTERN")
EOF

    [ -n "$others" ] || continue
    while IFS= read -r id; do
      [ -n "$id" ] || continue
      while IFS= read -r path; do
        [ -n "$path" ] || continue
        linkset_emit_link "$path" "$id" "derived"
      done <<EOF
$others
EOF
    done <<EOF
$ids
EOF
  done <<EOF
$commits
EOF

  return 0
}
