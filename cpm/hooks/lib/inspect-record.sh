#!/bin/bash
# inspect-record.sh — The deterministic JSON record the join emits
#
# Spec 42 R6: "The join emits a deterministic JSON document, committed alongside the work,
# **which is the record**. Diffable and greppable." AD4 states the consequence: the
# published page is regenerated from this file and treated as disposable, never the other
# way round, because "putting the only copy of provenance data inside a published page
# places a record somewhere `grep` cannot reach".
#
# Everything upstream of this file lives in a shell and dies with it. This is where it is
# written down, and Epic 42-03's gap queries and Epic 42-05's page both read what is
# written here rather than re-deriving it.
#
# --- The schema -------------------------------------------------------------------
#
# {
#   "schema": "cpm.inspect/1",
#   "selector": "epic 42-01",
#   "adapters": ["cpm", "gitnative"],
#   "changeset": { "commits": [...], "files": [...] },
#   "intents": [ { "id", "status", "title", "criteria": [ { "state", "text" } ] } ],
#   "links":   [ { "file", "intent", "confidence" } ],
#   "files":   [ { "path", "label" } ]
# }
#
# Keys appear in that order, and every array has a fixed order — but not the same one,
# and the difference is deliberate. `changeset.commits` keeps git's rev-list order,
# newest first, because that order is information: it is the sequence the work happened
# in, and sorting forty-character hex strings alphabetically would destroy it to no
# purpose. Every other array is sorted under LC_ALL=C, inherited from `linkset_normalise`
# and `changeset.sh`. What R6 requires is that two runs agree, not that everything is
# alphabetical, and both orders deliver that.
#
# **There is no timestamp and no run identifier.** Both are the obvious things to put in a
# record, and either would make two runs over the same repository state differ — which is
# the criterion, and what the deferred run-to-run delta rests on. Git already records when
# the file was committed, and by whom.
#
# **`links` and `files` are separate arrays on purpose.** `links` is the join's *data*;
# `files` carries the confidence *labels*. AD3 requires that the model-driven review
# "consumes the join's **data**, never its **labels**", and keeping them apart makes that
# boundary something a reader of the document can see rather than a rule someone has to
# remember while writing the review.
#
# **`schema` is a version string** because two later epics read this file. A consumer that
# can name the version it understands makes a future change cheap instead of silent.
#
# --- Why this is hand-rolled rather than piped through jq ---------------------------
#
# Every hook in this plugin is bash, awk and sed with no external dependency. A join that
# died on a machine without `jq` would fail in exactly the place R9 says it must not, and
# the Offline Integrity requirement's "only local git and local files" is easier to hold
# to with no third binary in the path. `jq` earns its place in the *tests* instead, where
# being an independent implementation of the parser is the entire point.

INSPECT_RECORD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! declare -f linkset_labels >/dev/null 2>&1; then
  # shellcheck source=./linkset-join.sh
  source "$INSPECT_RECORD_DIR/linkset-join.sh"
fi

INSPECT_SCHEMA_VERSION="cpm.inspect/1"

# The directory the record is written to, relative to the repository root. Fixed rather
# than configurable: R6 says the record is committed alongside the work, and a
# configurable location is a location that ends up in someone's scratch directory.
INSPECT_RECORD_DIR_REL="docs/inspect"

# Turn a selector into a filename stem: lowercase, runs of non-alphanumerics collapsed to
# a single `-`, leading and trailing `-` trimmed.
#
#   epic 42-01     → epic-42-01
#   --since abc123 → since-abc123
#
# One file per selector, overwritten in place, which is what makes the deferred
# "delta between two runs of the same selector" an ordinary `git diff` rather than a
# comparison someone has to construct.
inspect_slug() {
  printf '%s' "$1" \
    | LC_ALL=C tr '[:upper:]' '[:lower:]' \
    | LC_ALL=C sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

# Read a resolved link set on stdin; write the JSON record to stdout.
#   inspect_json <repo> <changeset-file> <selector>
inspect_json() {
  local repo="$1"
  local changeset_file="$2"
  local selector="$3"

  if [ -z "$repo" ] || [ ! -d "$repo" ]; then
    echo "inspect-record: no such repository directory: $repo" >&2
    return 1
  fi

  if [ -z "$changeset_file" ] || [ ! -f "$changeset_file" ]; then
    echo "inspect-record: no such change set file: $changeset_file" >&2
    return 1
  fi

  local records
  records=$(cat)

  # Labels are computed here rather than expected on stdin so that a caller cannot emit a
  # record whose `files` array disagrees with its `links` array.
  local labels
  labels=$(printf '%s\n' "$records" | linkset_labels "$changeset_file") || return 1

  # Multi-line values reach awk through files, and single-line ones through the
  # environment. Neither goes through `-v`: BSD awk rejects an embedded newline outright,
  # and it expands backslash escapes in the value, so a selector naming a Windows path or
  # a regex would arrive quietly altered. ENVIRON is passed through verbatim.
  local tmp_labels tmp_adapters
  tmp_labels=$(mktemp) || return 1
  tmp_adapters=$(mktemp) || { rm -f "$tmp_labels"; return 1; }

  printf '%s\n' "$labels" > "$tmp_labels"
  linkset_adapters | LC_ALL=C sort > "$tmp_adapters"

  INSPECT_SCHEMA="$INSPECT_SCHEMA_VERSION" \
  INSPECT_SELECTOR="$selector" \
  LC_ALL=C awk -F'\t' \
    -v labels_file="$tmp_labels" \
    -v adapters_file="$tmp_adapters" \
    -v changeset_file="$changeset_file" '
    # JSON string escaping. Backslash first — escaping quotes before backslashes would
    # then escape the backslashes this function just added. Tabs and newlines cannot
    # reach here (they are the record delimiters upstream), but they are handled anyway:
    # the cost is two lines and the failure mode is a document that parses as something
    # other than what was meant.
    function jstr(s) {
      gsub(/\\/, "\\\\", s)
      gsub(/"/, "\\\"", s)
      gsub(/\t/, "\\t", s)
      gsub(/\r/, "\\r", s)
      gsub(/\n/, "\\n", s)
      gsub(/\010/, "\\b", s)
      gsub(/\014/, "\\f", s)
      return "\"" s "\""
    }

    function emit_array(name, arr, n, indent,    i) {
      if (n == 0) { printf "%s\"%s\": [],\n", indent, name; return }
      printf "%s\"%s\": [\n", indent, name
      for (i = 1; i <= n; i++)
        printf "%s  %s%s\n", indent, jstr(arr[i]), (i < n ? "," : "")
      printf "%s],\n", indent
    }

    BEGIN {
      schema = ENVIRON["INSPECT_SCHEMA"]
      selector = ENVIRON["INSPECT_SELECTOR"]

      while ((getline line < changeset_file) > 0) {
        n = split(line, f, "\t")
        if (n < 2) continue
        if (f[1] == "COMMIT") commits[++ncommits] = f[2]
        else if (f[1] == "FILE") csfiles[++ncsfiles] = f[2]
      }
      close(changeset_file)

      while ((getline line < adapters_file) > 0)
        if (line != "") adapter_list[++nadapters] = line
      close(adapters_file)

      while ((getline line < labels_file) > 0)
        if (line != "") label_lines[++nlabels] = line
      close(labels_file)
    }

    $1 == "INTENT"    { intent_id[++nintents] = $2; intent_status[nintents] = $3; intent_title[nintents] = $4; next }
    $1 == "CRITERION" { crit_intent[++ncrits] = $2;  crit_state[ncrits] = $3;      crit_text[ncrits] = $4;      next }
    $1 == "LINK"      { link_file[++nlinks] = $2;    link_intent[nlinks] = $3;     link_conf[nlinks] = $4;      next }

    END {
      printf "{\n"
      printf "  \"schema\": %s,\n", jstr(schema)
      printf "  \"selector\": %s,\n", jstr(selector)

      emit_array("adapters", adapter_list, nadapters, "  ")

      printf "  \"changeset\": {\n"
      emit_array("commits", commits, ncommits, "    ")
      # No trailing comma on the last member of an object, so files is emitted by hand.
      if (ncsfiles == 0) printf "    \"files\": []\n"
      else {
        printf "    \"files\": [\n"
        for (i = 1; i <= ncsfiles; i++)
          printf "      %s%s\n", jstr(csfiles[i]), (i < ncsfiles ? "," : "")
        printf "    ]\n"
      }
      printf "  },\n"

      # Intents carry their criteria nested, because a criterion belongs to exactly one
      # intent record and R4 asks about the pair, never about a criterion alone.
      printf "  \"intents\": ["
      if (nintents == 0) printf "],\n"
      else {
        printf "\n"
        for (i = 1; i <= nintents; i++) {
          printf "    {\n"
          printf "      \"id\": %s,\n", jstr(intent_id[i])
          printf "      \"status\": %s,\n", jstr(intent_status[i])
          printf "      \"title\": %s,\n", jstr(intent_title[i])
          matched = 0
          for (c = 1; c <= ncrits; c++) if (crit_intent[c] == intent_id[i]) matched++
          if (matched == 0) printf "      \"criteria\": []\n"
          else {
            printf "      \"criteria\": [\n"
            seen = 0
            for (c = 1; c <= ncrits; c++) {
              if (crit_intent[c] != intent_id[i]) continue
              seen++
              printf "        { \"state\": %s, \"text\": %s }%s\n", \
                jstr(crit_state[c]), jstr(crit_text[c]), (seen < matched ? "," : "")
            }
            printf "      ]\n"
          }
          printf "    }%s\n", (i < nintents ? "," : "")
        }
        printf "  ],\n"
      }

      printf "  \"links\": ["
      if (nlinks == 0) printf "],\n"
      else {
        printf "\n"
        for (i = 1; i <= nlinks; i++)
          printf "    { \"file\": %s, \"intent\": %s, \"confidence\": %s }%s\n", \
            jstr(link_file[i]), jstr(link_intent[i]), jstr(link_conf[i]), (i < nlinks ? "," : "")
        printf "  ],\n"
      }

      printf "  \"files\": ["
      if (nlabels == 0) printf "]\n"
      else {
        printf "\n"
        for (i = 1; i <= nlabels; i++) {
          split(label_lines[i], lf, "\t")
          printf "    { \"path\": %s, \"label\": %s }%s\n", \
            jstr(lf[2]), jstr(lf[3]), (i < nlabels ? "," : "")
        }
        printf "  ]\n"
      }

      printf "}\n"
    }
  ' <<EOF
$records
EOF

  local rc=$?
  rm -f "$tmp_labels" "$tmp_adapters"
  return $rc
}

# Read a resolved link set on stdin; write the record into the repository and print the
# path it was written to, relative to the repository root.
#   inspect_write <repo> <changeset-file> <selector>
inspect_write() {
  local repo="$1"
  local changeset_file="$2"
  local selector="$3"

  local slug
  slug=$(inspect_slug "$selector")
  if [ -z "$slug" ]; then
    echo "inspect-record: selector yields no usable filename: $selector" >&2
    return 1
  fi

  # The slug is computed, never accepted, and `inspect_slug` collapses `/` and `.` along
  # with every other non-alphanumeric — so a traversing selector cannot produce a
  # traversing path. Re-checked here anyway rather than trusted, because this function
  # ends in a write and the criterion is specifically that the record lands in the
  # repository and not somewhere else.
  case "$slug" in
    *..* | */* )
      echo "inspect-record: refusing a filename that escapes $INSPECT_RECORD_DIR_REL: $slug" >&2
      return 1
      ;;
  esac

  local dir="$repo/$INSPECT_RECORD_DIR_REL"
  mkdir -p "$dir" || return 1

  local rel="$INSPECT_RECORD_DIR_REL/$slug.json"
  inspect_json "$repo" "$changeset_file" "$selector" > "$repo/$rel" || return 1

  printf '%s\n' "$rel"
}
