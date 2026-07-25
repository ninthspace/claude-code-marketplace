#!/bin/bash
# inspect-project.sh — The projection the published page is composed from
#
# Spec 42 R8 and AD4: the page is "a disposable projection over" the JSON record, "never
# the other way round", because "putting the only copy of provenance data inside a
# published page places a record somewhere `grep` cannot reach".
#
# --- Why this is a projection and not a page ----------------------------------------
#
# The shared **Artifact Publishing** convention composes pages through `artifact-design`,
# so nothing here emits HTML: a shell-templated page would sidestep that convention, and
# the resulting page would be this file's design rather than a designed one.
#
# What this file produces is the **complete set of facts the page may state**, read from
# the JSON and from nothing else. That makes AD4 a property of the pipeline rather than a
# rule the composer is asked to remember: a page composed from this output cannot contain
# source content, because source content never enters it. `inspect_projection` opens one
# file — the record — and never the repository it describes.
#
# --- Coupling to the writer, declared ------------------------------------------------
#
# This is a reader for exactly the layout `inspect_json` writes: fixed key order, fixed
# indentation, one object per line for links and files. That is a real coupling and it is
# deliberate — a general JSON parser in awk would be a great deal of code standing between
# two functions in the same plugin, and the round-trip test (write a record, project it,
# compare against the link set it came from) is what keeps the pair honest. A change to
# the writer's layout is expected to break this reader loudly.
#
# --- Record format -------------------------------------------------------------------
#
#   SCHEMA<TAB><version>
#   SELECTOR<TAB><selector>
#   ADAPTER<TAB><name>
#   COUNT<TAB>commits<TAB><n>
#   COUNT<TAB>files<TAB><n>
#   COMMIT<TAB><sha>
#   FILE<TAB><path><TAB><label>
#   LINK<TAB><path><TAB><intent-id><TAB><confidence>
#   INTENT<TAB><id><TAB><status><TAB><title>
#   CRITERION<TAB><intent-id><TAB><state><TAB><text>
#   ORPHAN<TAB><path>
#
# `ORPHAN` is derived here rather than carried in the record, because R3's answer is
# exactly "the files labelled absent" and re-deriving it at compose time would be a second
# implementation of a query that already has one.
#
# **Order is not part of the format.** Records come out in the record's own key order, with
# the derived ones (`COUNT`, `COMMIT`, `ORPHAN`) appended at the end because they are only
# complete once the whole document has been read. Filter by type; never read by position.
#
# `FILE` carries the *labelled* file set, which is the record's top-level `files` array and
# not its `changeset.files`. The two hold the same paths — the labels are computed over the
# change set — so the change set's copy is counted rather than emitted twice.

INSPECT_PROJECT_TAB=$(printf '\t')

# Read a JSON record; write projection records to stdout.
#   inspect_projection <json-file>
inspect_projection() {
  local json_file="$1"

  if [ -z "$json_file" ] || [ ! -f "$json_file" ]; then
    echo "inspect-project: no such record: $json_file" >&2
    return 1
  fi

  LC_ALL=C awk '
    # Every quoted string on a line, in order, unescaped. Scanned character by character
    # rather than matched, because a value containing `", ` — which criterion text
    # routinely does — defeats any split on the punctuation between fields.
    function qstrings(line, out,    i, n, c, inq, esc, cur, k) {
      n = length(line); inq = 0; esc = 0; cur = ""; k = 0
      for (i = 1; i <= n; i++) {
        c = substr(line, i, 1)
        if (!inq) { if (c == "\"") { inq = 1; cur = "" } ; continue }
        if (esc) {
          if (c == "n") cur = cur "\n"
          else if (c == "t") cur = cur "\t"
          else if (c == "r") cur = cur "\r"
          else if (c == "b") cur = cur sprintf("%c", 8)
          else if (c == "f") cur = cur sprintf("%c", 12)
          else cur = cur c          # covers \" and \\, which are their own literal
          esc = 0
          continue
        }
        if (c == "\\") { esc = 1; continue }
        if (c == "\"") { out[++k] = cur; inq = 0; continue }
        cur = cur c
      }
      return k
    }

    # Section is decided by the key that opened the array *and* its indentation: `files`
    # appears twice in the record, nested under `changeset` at four spaces and at top
    # level at two, and a reader keying on the name alone would merge them.
    /^  "schema":/    { qstrings($0, q); printf "SCHEMA\t%s\n", q[2]; next }
    /^  "selector":/  { qstrings($0, q); printf "SELECTOR\t%s\n", q[2]; next }

    /^  "adapters": \[\],?$/ { section = ""; next }
    /^  "adapters": \[$/     { section = "adapters"; next }
    /^    "commits": \[\],?$/ { section = ""; next }
    /^    "commits": \[$/     { section = "commits"; next }
    /^    "files": \[\],?$/   { section = ""; next }
    /^    "files": \[$/       { section = "csfiles"; next }
    /^  "intents": \[\],?$/   { section = ""; next }
    /^  "intents": \[$/       { section = "intents"; next }
    /^  "links": \[\],?$/     { section = ""; next }
    /^  "links": \[$/         { section = "links"; next }
    /^  "files": \[\],?$/     { section = ""; next }
    /^  "files": \[$/         { section = "files"; next }

    /^  \],?$/ { section = ""; next }
    /^    \],?$/ { if (section == "commits" || section == "csfiles") section = ""; next }

    section == "adapters" { qstrings($0, q); printf "ADAPTER\t%s\n", q[1]; next }
    section == "commits"  { qstrings($0, q); commits[++ncommits] = q[1]; next }
    section == "csfiles"  { ncsfiles++; next }

    section == "links" {
      # { "file": …, "intent": …, "confidence": … } — keys and values alternate.
      if (qstrings($0, q) >= 6) printf "LINK\t%s\t%s\t%s\n", q[2], q[4], q[6]
      next
    }

    section == "files" {
      if (qstrings($0, q) >= 4) {
        printf "FILE\t%s\t%s\n", q[2], q[4]
        if (q[4] == "absent") orphans[++norphans] = q[2]
      }
      next
    }

    section == "intents" {
      if ($0 ~ /^      "id":/)     { qstrings($0, q); cur_intent = q[2]; cur_status = ""; cur_title = ""; next }
      if ($0 ~ /^      "status":/) { qstrings($0, q); cur_status = q[2]; next }
      if ($0 ~ /^      "title":/)  {
        qstrings($0, q); cur_title = q[2]
        printf "INTENT\t%s\t%s\t%s\n", cur_intent, cur_status, cur_title
        next
      }
      # { "state": …, "text": … }, nested inside the intent that owns it.
      if ($0 ~ /^        \{ "state":/) {
        if (qstrings($0, q) >= 4) printf "CRITERION\t%s\t%s\t%s\n", cur_intent, q[2], q[4]
        next
      }
      next
    }

    END {
      printf "COUNT\tcommits\t%d\n", ncommits + 0
      printf "COUNT\tfiles\t%d\n", ncsfiles + 0
      for (i = 1; i <= ncommits; i++) printf "COMMIT\t%s\n", commits[i]
      for (i = 1; i <= norphans; i++) printf "ORPHAN\t%s\n", orphans[i]
    }
  ' "$json_file"
}

# Where the page fragment is built before publishing.
#   inspect_artifact_path <slug>
#
# A pure function of the selector, so every publish of the same run builds to the same path
# and redeploys to the same artifact rather than minting a second one. That is a
# within-session guarantee: a later session has to pass the recorded URL as well, which is
# what the sidecar below exists to make findable. The shared convention's scratch path
# carries a `{nn}` sequence number; `/cpm:inspect` has none — its records are keyed by
# selector, one file per selector overwritten in place — so the slug is the identity here
# and a number would have to be invented to fill the slot, defeating the point.
inspect_artifact_path() {
  local slug="$1"

  if [ -z "$slug" ]; then
    echo "inspect-project: no slug given" >&2
    return 1
  fi

  printf 'docs/plans/inspect-artifact-%s.html\n' "$slug"
}

# Where the backlink lives.
#   inspect_sidecar_path <slug>
#
# A sidecar rather than a field in the record, because the record is byte-deterministic by
# requirement (R6) and a published URL is not: writing one into it would make two runs of
# the same selector differ for a reason that has nothing to do with the work, and the delta
# between runs is the whole point of keeping one file per selector. The sidecar sits beside
# the record so the relationship still reads from the source end, which is what the
# `**Artifacts**:` invariant is for.
inspect_sidecar_path() {
  local slug="$1"

  if [ -z "$slug" ]; then
    echo "inspect-project: no slug given" >&2
    return 1
  fi

  printf 'docs/inspect/%s.artifacts.md\n' "$slug"
}

# Write the backlink sidecar and print its path, relative to the repository root.
#   inspect_sidecar_write <repo> <slug> <url>
inspect_sidecar_write() {
  local repo="$1"
  local slug="$2"
  local url="$3"

  if [ -z "$repo" ] || [ ! -d "$repo" ]; then
    echo "inspect-project: no such repository directory: $repo" >&2
    return 1
  fi

  # An empty URL is refused rather than written as an empty field. A backlink that names
  # no page is worse than none: it reads as "this was published" to everything that greps
  # for the field, and the register would be the only place the absence showed.
  if [ -z "$url" ]; then
    echo "inspect-project: refusing to write a backlink with no URL" >&2
    return 1
  fi

  local rel
  rel=$(inspect_sidecar_path "$slug") || return 1

  mkdir -p "$repo/docs/inspect" || return 1

  {
    printf '# Published artifacts for `%s`\n\n' "$slug"
    printf '**Source**: `docs/inspect/%s.json`\n' "$slug"
    printf '**Artifacts**: %s\n' "$url"
  } > "$repo/$rel" || return 1

  printf '%s\n' "$rel"
}

# One row for the register in `docs/artifacts/index.md`, in the column order that file
# already uses. Emitted rather than appended: the register is `cpm:artifact`'s file and
# this story does not change that skill, so the row is produced here and written there by
# the shared procedure.
#   inspect_register_row <url> <name> <date> <source> <why>
inspect_register_row() {
  local url="$1" name="$2" date="$3" source="$4" why="$5"

  if [ -z "$url" ] || [ -z "$name" ] || [ -z "$date" ] || [ -z "$source" ] || [ -z "$why" ]; then
    echo "inspect-project: a register row needs a URL, a name, a date, a source and a reason" >&2
    return 1
  fi

  printf '| %s | %s | %s | `%s` | %s |\n' "$name" "$url" "$date" "$source" "$why"
}
