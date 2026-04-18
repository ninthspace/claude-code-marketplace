# Namespace Rename

**Source spec**: docs/specifications/29-spec-opus-4-7-compatibility.md
**Date**: 2026-04-18
**Status**: Complete
**Blocked by**: —

## Rename namespace across plugin files
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: R12 — Namespace rename

**Acceptance Criteria**:

- Zero occurrences of `cpm:` remain in any `cpm2/skills/*/SKILL.md` file (grep verification) [manual]
- Zero occurrences of `cpm:` remain in `cpm2/README.md` and `cpm2/shared/skill-conventions.md` [manual]
- `cpm2/.claude-plugin/plugin.json` has `"name": "cpm2"` [manual]
- All `cpm2:` skill references in prose match actual skill names in the plugin [manual]

### Rename cpm: to cpm2: across all skill files and supporting docs
**Task**: 1.1
**Description**: Covers all 18 SKILL.md frontmatter `name:` fields and cross-references, plus README.md, shared/skill-conventions.md, and plugin.json `name` field. ~283 occurrences. Use `replace_all` per file.
**Status**: Complete

### Grep verification of namespace rename
**Task**: 1.2
**Description**: Confirm zero `cpm:` occurrences in any cpm2/ non-test file and spot-check that key cross-references (e.g. ralph → do, do → epics) resolve to valid cpm2: skill names.
**Status**: Complete
**Retro**: [Smooth delivery] Pure find-and-replace across 20 files with clean `replace_all` — no edge cases, no ambiguous matches, no collateral damage.

---

## Update and verify hook test suites
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: R12 — Namespace rename

**Acceptance Criteria**:

- Zero occurrences of `cpm:` in `cpm2/hooks/tests/*.sh` [manual]
- All hook test suites pass with `cpm2:` namespace [unit]

### Rename cpm: to cpm2: in hook test suites
**Task**: 2.1
**Description**: Update test-orphan-detection.sh (24 occurrences) and test-startup-hook.sh (16 occurrences).
**Status**: Complete

### Run hook test suites and verify all pass
**Task**: 2.2
**Description**: Execute `run-all-tests.sh` and confirm all 38 tests pass with the cpm2: namespace. This is the [unit] verification for R12.
**Status**: Complete
**Retro**: [Smooth delivery] Test suites passed on first run after rename — the `cpm:` pattern was cleanly isolated with no false positives or edge cases.

## Lessons

### Smooth Deliveries

- Story 1: Pure find-and-replace across 20 files with clean `replace_all` — no edge cases, no ambiguous matches, no collateral damage.
- Story 2: Test suites passed on first run after rename — the `cpm:` pattern was cleanly isolated with no false positives or edge cases.
