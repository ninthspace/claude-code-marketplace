#!/bin/bash
# test-ralph-supported-version.sh — the supported ralph-loop version is stated in four
# places and they must agree.
#
# `/cpm:ralph` depends on a Stop hook CPM does not ship. Three plugins provide one and all
# three work, but only `ralph-loop@ninthspace-ralph` at or above a given version has the
# behaviours CPM's own documentation describes. That version is therefore a fact about an
# external dependency, written wherever a reader might look for it — and a fact repeated in
# four documents is a fact that drifts.
#
# --- What has an oracle here ------------------------------------------------------------
#
# The version is **extracted** from each site and the set is required to have exactly one
# member. Nothing here spells the version out: a suite that named it would be a fifth site
# to update, and `test-version-agreement.sh` already forbids pinning a version literal in a
# test. So raising the minimum in one document fails this suite until it is raised in all,
# and no edit to this file is needed when it moves.
#
# The controls matter more than usual. "All four agree" is satisfied by four sites that each
# say nothing, so each extraction is separately asserted non-empty first.
#
# --- What this suite does not test -------------------------------------------------------
#
# That the installed plugin actually is that version. It cannot: a registered Stop hook
# exposes no version to a skill, which is the reason the minimum is stated rather than
# enforced, and why step 1c gates on a behavioural probe instead. The must-NOT below fences
# that — the skill must not claim to check a version it has no way to read.
#
# Usage: bash cpm/hooks/tests/test-ralph-supported-version.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

REPO="$SCRIPT_DIR/../../.."
RALPH_SKILL="$REPO/cpm/skills/ralph/SKILL.md"
CPM_README="$REPO/cpm/README.md"
ROOT_README="$REPO/README.md"
MAINT="$REPO/docs/maintenance/README.md"

# The plugin coordinate is the anchor, not the version: it is stable, and pinning it is what
# lets the version stay unpinned.
PLUGIN='ralph-loop@ninthspace-ralph'

echo "Testing: the supported ralph-loop version agrees across every site"
echo "=================================================================="

# Every site states it as "<coordinate> ... <x.y.z>" on one line, in prose or a table cell.
# Extracted rather than matched against a literal, so this suite survives the next bump.
stated_version() { # <file>
  grep -oE "${PLUGIN}[^0-9]{0,40}[0-9]+\.[0-9]+\.[0-9]+" "$1" \
    | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -u
}

FOUND=""
for pair in "ralph/SKILL.md:$RALPH_SKILL" "cpm/README.md:$CPM_README" \
            "README.md:$ROOT_README" "docs/maintenance/README.md:$MAINT"; do
  label="${pair%%:*}"; file="${pair#*:}"

  test_start "control: $label is readable"
  assert_equals "yes" "$( [ -r "$file" ] && echo yes || echo no )"

  V=$(stated_version "$file")

  # Non-empty first: "they all agree" is trivially true of four sites that say nothing.
  test_start "$label states a supported version for $PLUGIN"
  assert_equals "non-empty" "$( [ -n "$V" ] && echo non-empty || echo empty )"

  # And one value per site: a document carrying two is already inconsistent with itself, and
  # would otherwise be reconciled away by the set comparison below.
  test_start "and states exactly one"
  assert_equals "1" "$(printf '%s\n' "$V" | grep -c .)"

  FOUND="$FOUND$V
"
done

test_start "all four sites state the same version"
DISTINCT=$(printf '%s' "$FOUND" | grep -E '^[0-9]' | sort -u)
if [ "$(printf '%s\n' "$DISTINCT" | grep -c .)" -eq 1 ]; then
  test_pass
else
  test_fail "sites disagree: $(printf '%s' "$DISTINCT" | tr '\n' ' ')"
fi

# --- The gate is the probe, not the version ---------------------------------------------

test_start "the skill says the version is stated rather than checked"
assert_contains "$(cat "$RALPH_SKILL")" "stated, never checked"

# The must-NOT. A skill that claimed to verify a version would be describing a check it has
# no way to perform, and the failure would be silent — it would simply never fire.
test_start "and does not claim to read the installed plugin's version"
SKILL_TEXT=$(cat "$RALPH_SKILL")
if printf '%s' "$SKILL_TEXT" | grep -qiE 'check (the )?(installed )?plugin.{0,20}version|verify.{0,20}plugin version'; then
  test_fail "the skill describes a version check it cannot perform"
else
  test_pass
fi

# The control for the must-NOT: the probe it defers to is really named there, so "no version
# check" is not being satisfied by a step that gates on nothing at all.
test_start "control: step 1c still gates on the behavioural probe"
assert_contains "$SKILL_TEXT" "ralph-hook-probe.sh"

# --- The maintenance record lists the sites it claims to coordinate ----------------------

test_start "the maintenance record names every site that states the version"
MAINT_TEXT=$(cat "$MAINT")
MISSING=""
for site in "README.md" "cpm/README.md" "cpm/skills/ralph/SKILL.md"; do
  printf '%s' "$MAINT_TEXT" | grep -qF "$site" || MISSING="$MISSING $site"
done
assert_empty "$MISSING"

test_summary
