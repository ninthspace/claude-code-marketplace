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
PLUGIN_MANIFEST="$REPO_ROOT/cpm2/.claude-plugin/plugin.json"
MARKETPLACE_MANIFEST="$REPO_ROOT/.claude-plugin/marketplace.json"

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

# --- Plugin manifests (Story 2) ---

test_start "cpm2/.claude-plugin/plugin.json has version 0.1.0"
if [ -f "$PLUGIN_MANIFEST" ]; then
  VERSION=$(awk -F'"' '/"version"[[:space:]]*:/ {print $4; exit}' "$PLUGIN_MANIFEST")
  assert_equals "0.1.0" "$VERSION"
else
  test_fail "plugin.json missing at $PLUGIN_MANIFEST"
fi

test_start "cpm2/.claude-plugin/plugin.json keywords contain 'audit'"
if [ -f "$PLUGIN_MANIFEST" ]; then
  assert_contains "$(cat "$PLUGIN_MANIFEST")" '"audit"'
else
  test_fail "plugin.json missing"
fi

test_start ".claude-plugin/marketplace.json cpm2 entry has version 0.1.0"
if [ -f "$MARKETPLACE_MANIFEST" ]; then
  CPM2_BLOCK=$(awk '/"name": "cpm2"/,/\]/' "$MARKETPLACE_MANIFEST")
  CPM2_VERSION=$(echo "$CPM2_BLOCK" | awk -F'"' '/"version"[[:space:]]*:/ {print $4; exit}')
  assert_equals "0.1.0" "$CPM2_VERSION"
else
  test_fail "marketplace.json missing"
fi

test_start ".claude-plugin/marketplace.json cpm2 keywords contain 'audit'"
if [ -f "$MARKETPLACE_MANIFEST" ]; then
  CPM2_BLOCK=$(awk '/"name": "cpm2"/,/\]/' "$MARKETPLACE_MANIFEST")
  assert_contains "$CPM2_BLOCK" '"audit"'
else
  test_fail "marketplace.json missing"
fi

test_summary
