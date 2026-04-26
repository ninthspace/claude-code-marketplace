# Skill Scaffolding & Plugin Registration

**Source spec**: docs/specifications/31-spec-cpm2-audit-skill.md
**Date**: 2026-04-25
**Status**: Pending
**Blocked by**: —

## Create cpm2:audit skill scaffold
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: #1 (trigger and argument parsing), #2 (cpm2 plumbing)

**Acceptance Criteria**:

- File exists at `cpm2/skills/audit/SKILL.md` `[unit]`
- Frontmatter contains `name: cpm2:audit` `[unit]`
- Frontmatter description states the skill triggers on `/cpm2:audit` `[unit]`
- Skill recognises `/cpm2:audit` and parses optional argument as scope hint `[manual]`
- Skill references shared procedures (Library Check with scope `audit`, Retro Awareness, Progress File Management) per the cpm2 conventions `[manual]`

### Create skill directory and SKILL.md scaffold
**Task**: 1.1
**Description**: Create the `cpm2/skills/audit/` directory and `SKILL.md` file with proper YAML frontmatter (name, description). Covers the file-existence and frontmatter criteria.
**Status**: Complete

### Add Input section with trigger and argument parsing
**Task**: 1.2
**Description**: Document the `/cpm2:audit` trigger and parse `$ARGUMENTS` as an optional scope hint, following the existing cpm2 input-parsing pattern (e.g. `cpm2:quick`). Covers the scope-hint parsing criterion.
**Status**: Complete

### Add Process skeleton with shared procedure references
**Task**: 1.3
**Description**: Add the Process section with calls to Library Check (scope `audit`), Retro Awareness, and Progress File Management — referencing the shared procedures in `cpm2/shared/skill-conventions.md` rather than re-implementing them. Covers the cpm2-plumbing criterion.
**Status**: Complete

### Write tests for cpm2:audit skill scaffold
**Task**: 1.4
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`: file existence at expected path, frontmatter contains `name: cpm2:audit`, description references `/cpm2:audit` trigger.
**Status**: Complete

**Retro**: [Criteria gap] Epic 31-06 Task 1.1 specifies the test file as `test_audit_skill.sh` (underscores), but the existing runner globs `test-*.sh` — the underscore form would never be discovered. Used `test-audit-skill.sh` to match the runner; flag for `cpm2:pivot` when reaching Epic 31-06.

---

## Bump plugin version and register skill
**Story**: 2
**Status**: Complete
**Blocked by**: —
**Satisfies**: #19 (plugin manifest registration)

**Acceptance Criteria**:

- `cpm2/.claude-plugin/plugin.json` version is `0.1.0` `[unit]`
- `.claude-plugin/marketplace.json` cpm2 entry version is `0.1.0` `[unit]`
- Both manifests include `audit` keyword in their keyword arrays `[unit]`

### Bump version in cpm2/.claude-plugin/plugin.json
**Task**: 2.1
**Description**: Update the `version` field from `0.0.2` to `0.1.0`. Add `audit` to the `keywords` array. Covers the plugin.json criteria.
**Status**: Complete

### Bump version in .claude-plugin/marketplace.json
**Task**: 2.2
**Description**: Locate the `cpm2` entry in the root `marketplace.json` `plugins` array; update its `version` from `0.0.2` to `0.1.0`; add `audit` to its `keywords` array. Covers the marketplace.json criteria.
**Status**: Complete

### Write tests for plugin version bump
**Task**: 2.3
**Description**: Write automated tests asserting both manifests have `version: "0.1.0"` for the cpm2 plugin and that both `keywords` arrays include `"audit"`.
**Status**: Complete

**Retro**: [Pattern worth reusing] `awk -F'"' '/"key"[[:space:]]*:/ {print $4; exit}'` cleanly extracts JSON string values in BSD-compatible bash; reusable wherever cpm2 hook tests need to assert on manifest fields without bringing in `jq`.

---
