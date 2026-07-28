#!/bin/bash
# test-inspect-skill.sh — Structural tests for the cpm:inspect skill.
#
# These back Epic 42-05 Story 1's second, third and fifth acceptance criteria (spec 42
# AD1, and the spec's Out of Scope entry "Any change to `/cpm:audit`").
#
# --- What this suite does NOT test -------------------------------------------------------
#
# **Whether either description is any good.** "Leads with its subject, not its verb" is a
# property of prose, and the only oracle for it is a reader. What is checked below is the
# *convention* AD1 settles on — subject, then timing, then the rest — and that the two
# skills' subjects differ. A description could satisfy every assertion here and still be
# unhelpful; the gate read is what covers that, not this file.
#
# **Whether the skill works.** Nothing here invokes anything. The one library the skill
# calls, `changeset-resolve.sh`, has its own suite; everything else the skill does is a
# reading, which no assertion can stand in for.
#
# --- Two pinned literals, deliberately -----------------------------------------------------
#
# The opening clauses are compared against literal strings. Ordinarily a pinned expected
# value is a snapshot wearing an invariant's clothes, but here the string *is* the contract:
# AD1 names the subjects ("code, after execution", "plans, before execution") and a test
# deriving them from the file it is checking would assert nothing at all.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
INSPECT_SKILL="$REPO_ROOT/cpm/skills/inspect/SKILL.md"
REVIEW_SKILL="$REPO_ROOT/cpm/skills/review/SKILL.md"
AUDIT_SKILL="$REPO_ROOT/cpm/skills/audit/SKILL.md"

# The `description:` line from a skill's frontmatter.
skill_description() {
  awk '/^---$/ { c++; next } c == 1' "$1" | sed -n 's/^description: //p'
}

# Everything before the em dash that separates subject from body.
description_subject() {
  skill_description "$1" | awk -F' — ' '{ print $1 }'
}

echo "Testing: cpm:inspect skill assembly"
echo "==================================="

# --- Scaffold ------------------------------------------------------------------------------

test_start "SKILL.md exists at cpm/skills/inspect/SKILL.md"
if [ -f "$INSPECT_SKILL" ]; then
  test_pass
else
  test_fail "File not found: $INSPECT_SKILL"
fi

test_start "frontmatter names the skill"
assert_contains "$(awk '/^---$/ { c++; next } c == 1' "$INSPECT_SKILL")" "name: inspect"

test_start "the description declares the /cpm:inspect trigger"
assert_contains "$(skill_description "$INSPECT_SKILL")" '/cpm:inspect'

# --- Criterion: each description leads with its subject ---------------------------------------

test_start "cpm:inspect's description leads with its subject — code, after execution"
assert_equals "Code, after execution" "$(description_subject "$INSPECT_SKILL")"

test_start "cpm:review's description leads with its subject — plans, before execution"
assert_equals "Plans, before execution" "$(description_subject "$REVIEW_SKILL")"

# The assertion the criterion actually turns on. Both descriptions could open in the agreed
# shape and still name the same subject, which is precisely the collision AD1 exists to
# prevent — "a naming collision users can fall into permanently".
test_start "the two subjects differ, which is the collision AD1 is about"
INSPECT_SUBJECT=$(description_subject "$INSPECT_SKILL")
REVIEW_SUBJECT=$(description_subject "$REVIEW_SKILL")
if [ -z "$INSPECT_SUBJECT" ] || [ -z "$REVIEW_SUBJECT" ]; then
  test_fail "Positive control failed: a subject was empty, so 'they differ' proves nothing"
elif [ "$INSPECT_SUBJECT" = "$REVIEW_SUBJECT" ]; then
  test_fail "Both skills claim the same subject: $INSPECT_SUBJECT"
else
  test_pass
fi

# The amendment was meant to prefix `review`'s description, not rewrite it. A replacement
# would satisfy every assertion above while quietly discarding what the skill does.
# The amendment prefixes rather than replaces, so the original sentence continues after the
# em dash and its first word is now lower case. That is the whole diff.
test_start "cpm:review's existing description survived the amendment"
assert_contains "$(skill_description "$REVIEW_SKILL")" \
  "adversarial review of epic docs and stories."

# Both subjects have the same shape — `<subject>, <timing> execution` — so the same
# extraction is applied to each. Reading them out of different fields would let one skill
# drift out of the shape without the test noticing.
test_start "each description states the timing that distinguishes the pair"
assert_equals "after|before" \
  "$(printf '%s' "$INSPECT_SUBJECT" | awk '{ print $2 }')|$(printf '%s' "$REVIEW_SUBJECT" | awk '{ print $2 }')"

# --- Criterion (must NOT): /cpm:audit is not modified -------------------------------------------
#
# A before-and-after content comparison, not a grep that happens to find nothing.
#
# **What is compared is the story, not the file.** The criterion is that introducing
# `/cpm:inspect` left `/cpm:audit` alone, which is a fact about one change. Comparing the
# working tree against the commit before inspect appeared asserts something stronger and
# untrue: that `cpm/skills/audit/` never changes again. Every later edit to audit — a shared
# convention restated, a path spelled out, anything at all — would fail a criterion it has
# nothing to do with, and the failure would name this story, which did not cause it.
#
# So once inspect is committed the comparison is the commit that added it against its parent:
# exactly the change that could have violated the must-NOT, and a fact that stays true no
# matter what happens to audit afterwards. While inspect is still uncommitted there is no such
# commit, and the live comparison is the working tree against HEAD.

git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1
IN_GIT=$?

STORY_DIFF=()
BASELINE=""
if [ "$IN_GIT" -eq 0 ]; then
  FIRST_ADD=$(git -C "$REPO_ROOT" log --diff-filter=A --format=%H -- cpm/skills/inspect/SKILL.md | tail -1)
  if [ -n "$FIRST_ADD" ] && git -C "$REPO_ROOT" rev-parse --verify -q "${FIRST_ADD}^" >/dev/null; then
    BASELINE="${FIRST_ADD}"
    STORY_DIFF=("${FIRST_ADD}^" "$FIRST_ADD")
  else
    BASELINE="HEAD"
    STORY_DIFF=("HEAD")
  fi
fi

test_start "a baseline to compare against exists"
if [ -n "$BASELINE" ]; then
  test_pass
else
  test_fail "Not a git repository — this criterion is a content comparison and cannot run"
fi

test_start "the change that introduced /cpm:inspect left cpm/skills/audit/ untouched"
if [ -z "$BASELINE" ]; then
  test_fail "No baseline"
else
  assert_empty "$(git -C "$REPO_ROOT" diff --name-only "${STORY_DIFF[@]}" -- cpm/skills/audit/)"
fi

# The control for the assertion above. A comparison whose two sides are the same tree reports
# every path as unchanged, so "audit is unchanged" would pass while proving nothing; this is
# what turns that into a visible failure. The two skills the story *did* change must show as
# changed across the same range, by the same command.
test_start "the comparison is live — the skills this story changed do show as changed"
if [ -z "$BASELINE" ]; then
  test_fail "No baseline"
else
  CHANGED=$(git -C "$REPO_ROOT" diff --name-only "${STORY_DIFF[@]}" \
    -- cpm/skills/review/SKILL.md cpm/skills/inspect/SKILL.md)
  if [ -z "$CHANGED" ]; then
    test_fail "The range ${STORY_DIFF[*]} shows no change to review or inspect, so 'audit is unchanged' proves nothing"
  else
    test_pass
  fi
fi

test_start "cpm:audit's description is untouched and still leads with its own subject"
assert_contains "$(skill_description "$AUDIT_SKILL")" "Codebase audit skill."

test_summary
