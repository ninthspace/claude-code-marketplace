#!/bin/bash
# test-progress-path-stated.sh — every skill that keeps a progress file can name the file.
#
# --- The failure this covers --------------------------------------------------------
#
# An autonomous `cpm:epics` wrote its progress file to `docs/plans/cpm-session-state-epics.md`.
# The convention is `docs/plans/.cpm-progress-{session_id}.md`: no leading dot in what it wrote,
# no session ID, wrong stem. `progress-classify.sh` globs `.cpm-progress-*.md`, so the file
# matched nothing — invisible to `/cpm:clean`, to the Stale-Progress Check, and to compaction
# recovery, while sitting in the repository as a visible untracked file waiting to be committed.
#
# It was not a slip. `epics/SKILL.md` said only *follow the shared procedure*, and the filename
# lives at byte 13,963 of `skill-conventions.md` — well past the point the SessionStart payload
# stops being inlined. The agent had a pointer to a procedure it could not read, and invented a
# plausible name from the one thing it could see: the format template, whose H1 is
# `# CPM Session State`. Every field *inside* the file was correct, because the format half
# lives in the SKILL.md and was followed exactly. Only the path half was missing.
#
# So the rule is that a skill states the path itself. A pointer is worth nothing when the target
# does not load.
#
# --- Which assertions are oracles ---------------------------------------------------
#
# **The correspondence is.** The glob is read out of `progress-classify.sh` and the path out of
# each skill, independently, and a filename built from the skill's own words is tested against
# the classifier's own pattern. Neither side is pinned to the other, so renaming the convention
# in both places stays green while renaming it in one fails.
#
# **The discriminating control is the name that actually happened.** A test that only checks
# "the real path matches the real glob" passes for a glob matching everything. Asserting that
# `cpm-session-state-epics.md` does *not* match is what shows the check can tell a good name
# from a plausible one.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

SKILLS_DIR="$SCRIPT_DIR/../../skills"
CLASSIFY="$SCRIPT_DIR/../lib/progress-classify.sh"

echo "Testing that every progress-file skill states the path it must write"

# The pattern the classifier iterates, lifted from the loop itself rather than from its comments
# — a comment can describe a glob the code stopped using.
GLOB=$(sed -n 's|^for f in "\$STATE_DIR"/\(\.cpm-progress[^;]*\); do$|\1|p' "$CLASSIFY" | head -1)

test_start "control: the classifier glob could be read from its own loop"
assert_equals "non-empty" "$( [ -n "$GLOB" ] && echo non-empty || echo empty )"

# --- The correspondence -------------------------------------------------------------
#
# Each skill deferring to the shared procedure must carry the path in its own file. The check
# is not "the string appears" but "a filename built from what this skill says would be found":
# the stated template has its placeholder filled with a session ID, and the result is matched
# against the classifier's glob using the shell's own pattern matching — the same matcher the
# classifier itself relies on.

matches_glob() {
  local name="$1"
  # shellcheck disable=SC2254
  case "$name" in
    $GLOB) return 0 ;;
    *)     return 1 ;;
  esac
}

# Whatever path this skill states, not the path it ought to state. Grepping for the correct
# literal would make the glob check below unreachable: the only string that could satisfy the
# presence test would already be the right one, so "states a path" and "states a findable path"
# would be the same assertion wearing two names, and a skill naming something plausible and
# wrong would report as naming nothing.
#
# The deferral line is preferred because that is where a reader looking up the procedure lands.
# Skills that state the path elsewhere in their own file fall back to the first one there —
# still in context when the skill loads, which is the property that matters.
# Three sources, narrowing only as far as it has to. `docs/plans/` also holds the documents
# skills write for the user, so a file-wide search for the first path there can land on a
# worked example — which is why the middle branch asks for a progress-shaped name before the
# last one accepts anything. The last branch exists so a skill naming nothing progress-shaped
# reports a wrong path rather than dropping out of the check entirely.
stated_path() {
  local f="$1" p
  p=$(grep 'Progress File Management' "$f" | grep -o 'docs/plans/[A-Za-z0-9._{}-]*\.md' | head -1)
  [ -n "$p" ] && { printf '%s' "$p"; return; }
  p=$(grep -o 'docs/plans/[A-Za-z0-9._{}-]*progress[A-Za-z0-9._{}-]*\.md' "$f" | head -1)
  [ -n "$p" ] && { printf '%s' "$p"; return; }
  grep -o 'docs/plans/[A-Za-z0-9._{}-]*\.md' "$f" | head -1
}

DEFERRING=()
MISSING=()
BAD=()

for f in "$SKILLS_DIR"/*/SKILL.md; do
  skill=$(basename "$(dirname "$f")")
  grep -q 'Progress File Management' "$f" || continue
  DEFERRING+=("$skill")

  stated=$(stated_path "$f")
  if [ -z "$stated" ]; then
    MISSING+=("$skill")
    continue
  fi

  # Fill the placeholder the way a run would, then ask whether the classifier would find it.
  name="${stated##*/}"
  name="${name/\{session_id\}/34e1eabd-0000-4000-8000-000000000000}"
  matches_glob "$name" || BAD+=("$skill")
done

test_start "control: skills deferring to the shared procedure were found"
assert_equals "yes" "$( [ "${#DEFERRING[@]}" -ge 10 ] && echo yes || echo no )"

test_start "every skill that keeps a progress file states the path in its own file"
assert_empty "$(printf '%s\n' "${MISSING[@]+"${MISSING[@]}"}")"

test_start "and the path each one states is a path the classifier would find"
assert_empty "$(printf '%s\n' "${BAD[@]+"${BAD[@]}"}")"

# --- The discriminating control ------------------------------------------------------
#
# The name the field test actually produced. Every property of it is individually plausible and
# the whole is unfindable, which is why "looks like a progress file" is not the check.

test_start "must NOT match the name an autonomous run invented"
if matches_glob "cpm-session-state-epics.md"; then
  test_fail "the glob matched cpm-session-state-epics.md, so it cannot tell a good name from a plausible one"
else
  test_pass
fi

# Each property on its own, so a failure says which one carries the weight rather than only
# that the whole differed.
test_start "must NOT match the same name given the leading dot but the wrong stem"
if matches_glob ".cpm-session-state-epics.md"; then
  test_fail "the stem is not load-bearing in this glob"
else
  test_pass
fi

test_start "must NOT match the right stem with no leading dot"
if matches_glob "cpm-progress-34e1eabd.md"; then
  test_fail "the leading dot is not load-bearing in this glob"
else
  test_pass
fi

# The positive control for all three: the convention itself must match, or the assertions above
# would pass for a glob that matches nothing at all.
test_start "control: the conventional name does match"
if matches_glob ".cpm-progress-34e1eabd.md"; then
  test_pass
else
  test_fail "the glob rejects the convention it exists to find"
fi

# --- The fallback, and a seam it does not cross ---------------------------------------
#
# `CPM_SESSION_ID` is absent when the hooks are not installed, and the shared procedure names
# `.cpm-progress.md` as the fallback for that case. That name does **not** satisfy the
# classifier glob, which requires a hyphen and a session ID after the stem.
#
# That is consistent rather than broken: `CPM_SESSION_ID` is injected by the same hooks whose
# absence selects the fallback, so a run writing the fallback name is a run in which nothing is
# classifying anything. It is pinned here because the two halves are stated in different files
# and neither mentions the other — widening the glob to `.cpm-progress*.md` would make the
# fallback discoverable and is the kind of change worth making deliberately rather than as a
# side effect of a wildcard edit.

test_start "the session-less fallback sits outside the classifier glob, as the convention implies"
if matches_glob ".cpm-progress.md"; then
  test_fail "the fallback is now matched by the glob — intended, or a wildcard widened by accident?"
else
  test_pass
fi

test_summary
