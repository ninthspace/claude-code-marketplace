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
AUDITS_DIR="$REPO_ROOT/docs/audits"

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

# --- Severity and effort scales (Epic 31-04 Story 4) ---

test_start "Audit findings rows use Severity in {Critical, High, Medium, Low}"
if [ -d "$AUDITS_DIR" ]; then
  shopt -s nullglob 2>/dev/null
  AUDIT_FILES=("$AUDITS_DIR"/*-audit-*.md)
  if [ ${#AUDIT_FILES[@]} -eq 0 ]; then
    test_pass
  else
    BAD=""
    for f in "${AUDIT_FILES[@]}"; do
      while IFS= read -r row; do
        SEVERITY=$(echo "$row" | awk -F'|' '{gsub(/^ +| +$/, "", $5); print $5}')
        [ -z "$SEVERITY" ] && continue
        case "$SEVERITY" in
          Critical|High|Medium|Low) ;;
          *) BAD="$BAD\n$(basename "$f"): bad severity '$SEVERITY'" ;;
        esac
      done < <(extract_findings_rows "$f")
    done
    if [ -z "$BAD" ]; then
      test_pass
    else
      test_fail "$(printf '%b' "$BAD")"
    fi
  fi
else
  test_pass
fi

test_start "Audit findings rows use Effort in {S, M, L}"
if [ -d "$AUDITS_DIR" ]; then
  shopt -s nullglob 2>/dev/null
  AUDIT_FILES=("$AUDITS_DIR"/*-audit-*.md)
  if [ ${#AUDIT_FILES[@]} -eq 0 ]; then
    test_pass
  else
    BAD=""
    for f in "${AUDIT_FILES[@]}"; do
      while IFS= read -r row; do
        EFFORT=$(echo "$row" | awk -F'|' '{gsub(/^ +| +$/, "", $6); print $6}')
        [ -z "$EFFORT" ] && continue
        case "$EFFORT" in
          S|M|L) ;;
          *) BAD="$BAD\n$(basename "$f"): bad effort '$EFFORT'" ;;
        esac
      done < <(extract_findings_rows "$f")
    done
    if [ -z "$BAD" ]; then
      test_pass
    else
      test_fail "$(printf '%b' "$BAD")"
    fi
  fi
else
  test_pass
fi

# --- No-padding rule (Epic 31-04 Story 5) ---

test_start "Audit deliverables do not contain padding placeholders"
if [ -d "$AUDITS_DIR" ]; then
  shopt -s nullglob 2>/dev/null
  AUDIT_FILES=("$AUDITS_DIR"/*-audit-*.md)
  if [ ${#AUDIT_FILES[@]} -eq 0 ]; then
    test_pass
  else
    BAD=""
    for f in "${AUDIT_FILES[@]}"; do
      if grep -qiE '(Nothing material|N/A — no findings|Empty section|No findings to report)' "$f"; then
        BAD="$BAD\n$(basename "$f"): contains padding placeholder"
      fi
    done
    if [ -z "$BAD" ]; then
      test_pass
    else
      test_fail "$(printf '%b' "$BAD")"
    fi
  fi
else
  test_pass
fi

# --- Scoped audit consistency (Epic 31-04 Story 6) ---

test_start "Audit deliverables record **Scope** in the header"
if [ -d "$AUDITS_DIR" ]; then
  shopt -s nullglob 2>/dev/null
  AUDIT_FILES=("$AUDITS_DIR"/*-audit-*.md)
  if [ ${#AUDIT_FILES[@]} -eq 0 ]; then
    test_pass
  else
    BAD=""
    for f in "${AUDIT_FILES[@]}"; do
      grep -qE '^\*\*Scope\*\*:' "$f" || BAD="$BAD\n$(basename "$f"): missing **Scope** header"
    done
    if [ -z "$BAD" ]; then
      test_pass
    else
      test_fail "$(printf '%b' "$BAD")"
    fi
  fi
else
  test_pass
fi

# --- Effort aggregates (Epic 31-04 Story 7) ---

test_start "Audit executive summaries include an effort aggregate line"
if [ -d "$AUDITS_DIR" ]; then
  shopt -s nullglob 2>/dev/null
  AUDIT_FILES=("$AUDITS_DIR"/*-audit-*.md)
  if [ ${#AUDIT_FILES[@]} -eq 0 ]; then
    test_pass
  else
    BAD=""
    for f in "${AUDIT_FILES[@]}"; do
      # Extract the executive-summary section (between ## Executive Summary and the next ##)
      EXEC=$(awk '/^## Executive Summary/{flag=1; next} /^## /{flag=0} flag' "$f")
      # Allow variants like "Effort: S×12" or "Effort: S×12, M×7" or with all three
      if ! echo "$EXEC" | grep -qE 'Effort: S×[0-9]+(, M×[0-9]+)?(, L×[0-9]+)?'; then
        BAD="$BAD\n$(basename "$f"): executive summary missing 'Effort: …' aggregate line"
      fi
    done
    if [ -z "$BAD" ]; then
      test_pass
    else
      test_fail "$(printf '%b' "$BAD")"
    fi
  fi
else
  test_pass
fi

# --- Citation format (Epic 31-04 Story 3) ---

extract_findings_rows() {
  awk '
    /^\| ID \| Category \| Citation \| Severity \| Effort \| Description \| Recommendation \|/ {in_table=1; getline; next}
    in_table && /^$/ {in_table=0}
    in_table && /^\| F-/ {print}
  ' "$1"
}

test_start "Audit findings rows have citations matching file:line[ (symbol)]"
if [ -d "$AUDITS_DIR" ]; then
  shopt -s nullglob 2>/dev/null
  AUDIT_FILES=("$AUDITS_DIR"/*-audit-*.md)
  if [ ${#AUDIT_FILES[@]} -eq 0 ]; then
    test_pass
  else
    BAD=""
    for f in "${AUDIT_FILES[@]}"; do
      while IFS= read -r row; do
        # Citation is the third pipe-delimited cell (after ID, Category)
        CITATION=$(echo "$row" | awk -F'|' '{gsub(/^ +| +$/, "", $4); print $4}')
        [ -z "$CITATION" ] && continue
        if ! echo "$CITATION" | grep -qE '^`?[^[:space:]:]+:[0-9]+( \([^)]+\))?`?$'; then
          BAD="$BAD\n$(basename "$f"): bad citation '$CITATION'"
        fi
      done < <(extract_findings_rows "$f")
    done
    if [ -z "$BAD" ]; then
      test_pass
    else
      test_fail "$(printf '%b' "$BAD")"
    fi
  fi
else
  test_pass
fi

test_start "Audit findings rows do not contain obvious secret patterns"
if [ -d "$AUDITS_DIR" ]; then
  shopt -s nullglob 2>/dev/null
  AUDIT_FILES=("$AUDITS_DIR"/*-audit-*.md)
  if [ ${#AUDIT_FILES[@]} -eq 0 ]; then
    test_pass
  else
    BAD=""
    for f in "${AUDIT_FILES[@]}"; do
      # Check finding rows for common secret prefixes that would indicate a quoted value
      if grep -qE '(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|xox[abprs]-[A-Za-z0-9-]{10,})' "$f"; then
        BAD="$BAD\n$(basename "$f"): contains a recognised secret token pattern"
      fi
    done
    if [ -z "$BAD" ]; then
      test_pass
    else
      test_fail "$(printf '%b' "$BAD")"
    fi
  fi
else
  test_pass
fi

# --- Deliverable structure (Epic 31-04 Story 2) ---

REQUIRED_SECTIONS=(
  "## Executive Summary"
  "## Architectural Mental Model"
  "## Findings"
  "## Top 5 Priorities"
  "## Quick Wins"
  "## Things that look bad but are actually fine"
  "## Open Questions"
)

test_start "SKILL.md documents all seven required deliverable sections"
if [ -f "$SKILL_FILE" ]; then
  MISSING=""
  for SECTION in "${REQUIRED_SECTIONS[@]}"; do
    grep -qF -- "$SECTION" "$SKILL_FILE" || MISSING="$MISSING\n  $SECTION"
  done
  if [ -z "$MISSING" ]; then
    test_pass
  else
    test_fail "$(printf 'Missing in SKILL.md: %b' "$MISSING")"
  fi
else
  test_fail "SKILL.md missing"
fi

test_start "Each audit deliverable contains all required sections"
if [ -d "$AUDITS_DIR" ]; then
  shopt -s nullglob 2>/dev/null
  AUDIT_FILES=("$AUDITS_DIR"/*-audit-*.md)
  if [ ${#AUDIT_FILES[@]} -eq 0 ]; then
    test_pass
  else
    BAD=""
    for f in "${AUDIT_FILES[@]}"; do
      for SECTION in "${REQUIRED_SECTIONS[@]}"; do
        grep -qF -- "$SECTION" "$f" || BAD="$BAD\n$(basename "$f"): missing '$SECTION'"
      done
    done
    if [ -z "$BAD" ]; then
      test_pass
    else
      test_fail "$(printf '%b' "$BAD")"
    fi
  fi
else
  test_pass
fi

test_start "Audit findings tables use the documented column headers"
if [ -d "$AUDITS_DIR" ]; then
  shopt -s nullglob 2>/dev/null
  AUDIT_FILES=("$AUDITS_DIR"/*-audit-*.md)
  if [ ${#AUDIT_FILES[@]} -eq 0 ]; then
    test_pass
  else
    EXPECTED='| ID | Category | Citation | Severity | Effort | Description | Recommendation |'
    BAD=""
    for f in "${AUDIT_FILES[@]}"; do
      grep -qF -- "$EXPECTED" "$f" || BAD="$BAD\n$(basename "$f"): missing the documented column header row"
    done
    if [ -z "$BAD" ]; then
      test_pass
    else
      test_fail "$(printf '%b' "$BAD")"
    fi
  fi
else
  test_pass
fi

# --- Numbered deliverable path (Epic 31-04 Story 1) ---

test_start "Audit deliverables follow docs/audits/{nn}-audit-{slug}.md shape"
if [ -d "$AUDITS_DIR" ]; then
  shopt -s nullglob 2>/dev/null
  AUDIT_FILES=("$AUDITS_DIR"/*.md)
  if [ ${#AUDIT_FILES[@]} -eq 0 ]; then
    test_pass
  else
    BAD=""
    for f in "${AUDIT_FILES[@]}"; do
      BASE=$(basename "$f")
      if ! echo "$BASE" | grep -qE '^[0-9]+-audit-[a-z0-9-]+\.md$'; then
        BAD="$BAD\n$BASE: not in {nn}-audit-{slug}.md shape"
      fi
    done
    if [ -z "$BAD" ]; then
      test_pass
    else
      test_fail "$(printf '%b' "$BAD")"
    fi
  fi
else
  test_pass
fi

test_start "Audit deliverable numbers are unique (no overwrites)"
if [ -d "$AUDITS_DIR" ]; then
  shopt -s nullglob 2>/dev/null
  AUDIT_FILES=("$AUDITS_DIR"/[0-9]*-audit-*.md)
  if [ ${#AUDIT_FILES[@]} -le 1 ]; then
    test_pass
  else
    NUMS=""
    for f in "${AUDIT_FILES[@]}"; do
      NUM=$(basename "$f" | sed -E 's/^([0-9]+)-audit-.*$/\1/')
      NUMS="$NUMS $NUM"
    done
    DUPES=$(echo $NUMS | tr ' ' '\n' | sort | uniq -d)
    if [ -z "$DUPES" ]; then
      test_pass
    else
      test_fail "Duplicate audit numbers: $DUPES"
    fi
  fi
else
  test_pass
fi

# --- Commit SHA capture (Story 31-02 Story 1) ---

test_start "SKILL.md documents the **Audited at** header field"
if [ -f "$SKILL_FILE" ]; then
  assert_contains "$(cat "$SKILL_FILE")" "**Audited at**:"
else
  test_fail "SKILL.md missing"
fi

test_start "Each audit deliverable header has a 40-char hex SHA after **Audited at**:"
if [ -d "$AUDITS_DIR" ]; then
  shopt -s nullglob 2>/dev/null
  AUDIT_FILES=("$AUDITS_DIR"/*-audit-*.md)
  if [ ${#AUDIT_FILES[@]} -eq 0 ]; then
    # Vacuously pass — skill not yet run on this repo
    test_pass
  else
    BAD=""
    for f in "${AUDIT_FILES[@]}"; do
      LINE=$(grep -m1 '^\*\*Audited at\*\*:' "$f")
      if [ -z "$LINE" ]; then
        BAD="$BAD\n$f: missing **Audited at** line"
        continue
      fi
      VALUE=$(echo "$LINE" | sed -E 's/^\*\*Audited at\*\*:[[:space:]]*//')
      # Allow either a 40-char hex SHA or the documented git-unavailable fallback
      if echo "$VALUE" | grep -qE '^[0-9a-f]{40}$'; then
        :
      elif [ "$VALUE" = "not a git repository" ]; then
        :
      else
        BAD="$BAD\n$f: '$VALUE' is neither a 40-char hex SHA nor 'not a git repository'"
      fi
    done
    if [ -z "$BAD" ]; then
      test_pass
    else
      test_fail "$(printf '%b' "$BAD")"
    fi
  fi
else
  # No audits dir yet — vacuously pass
  test_pass
fi

test_summary
