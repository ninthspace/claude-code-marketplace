#!/bin/bash
# test-audit-skill.sh — Structural tests for the cpm2:audit skill
#
# Aggregates the [unit] structural assertions for the audit skill.
# Story 1 (Epic 31-01) — scaffold: file existence and frontmatter.
# Subsequent stories add: plugin manifests, deliverable header SHA,
# deliverable structure, citation format, scale values, no-padding,
# scoped consistency, effort aggregates, library wrapper path.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SKILL_FILE="$REPO_ROOT/cpm2/skills/audit/SKILL.md"

echo "Testing: cpm2:audit skill"
echo "========================="

# --- Skill scaffold (Story 1) ---

test_start "SKILL.md exists at cpm2/skills/audit/SKILL.md"
if [ -f "$SKILL_FILE" ]; then
  test_pass
else
  test_fail "File not found: $SKILL_FILE"
fi

test_start "Frontmatter contains 'name: cpm2:audit'"
if [ -f "$SKILL_FILE" ]; then
  FRONTMATTER=$(awk '/^---$/{c++; next} c==1' "$SKILL_FILE")
  assert_contains "$FRONTMATTER" "name: cpm2:audit"
else
  test_fail "SKILL.md missing — cannot inspect frontmatter"
fi

test_start "Frontmatter description references the /cpm2:audit trigger"
if [ -f "$SKILL_FILE" ]; then
  FRONTMATTER=$(awk '/^---$/{c++; next} c==1' "$SKILL_FILE")
  assert_contains "$FRONTMATTER" "/cpm2:audit"
else
  test_fail "SKILL.md missing — cannot inspect frontmatter"
fi

test_summary
