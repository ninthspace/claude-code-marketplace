# /cpm:clean Command

**Source spec**: docs/specifications/38-spec-stale-progress-prompt-and-cpm-clean.md
**Date**: 2026-07-08
**Status**: Pending
**Blocked by**: Epic 38-01-epic-classifier-and-hooks

## Author the `/cpm:clean` skill
**Story**: 1
**Status**: Pending
**Blocked by**: —
**Satisfies**: FR5, FR6, FR8, AD4

**Acceptance Criteria**:

- `/cpm:clean` is invokable via `cpm/skills/clean/SKILL.md` with correct frontmatter (name, description, trigger), discoverable like other CPM skills [manual] — justification: skill-prose, verified by invocation + review
- Lists all `.cpm-progress-*.md` and `.cpm-compact-summary-*.md` files with age and session label (via the classifier's list-all mode) [manual]
- Compact-summary companion files are listed alongside their progress file [manual]
- Deletes only files the user explicitly names [manual]
- must NOT delete any file the user did not name [manual]
- must NOT apply a staleness filter or sentinel — exhaustive, on-demand listing every time [manual]

### Create `cpm/skills/clean/SKILL.md`
**Task**: 1.1
**Description**: Author the one-shot skill — frontmatter (name, description, trigger `/cpm:clean`); body lists all `.cpm-progress-*.md` + `.cpm-compact-summary-*.md` via the classifier's list-all mode with age + session labels, groups companions with their progress file, deletes only user-named files, applies no sentinel/staleness filter, and requires confirmation. Covers all Story 1 criteria.
**Status**: Pending

---

## Version bump & documentation
**Story**: 2
**Status**: Pending
**Blocked by**: Story 1
**Satisfies**: AD4

**Acceptance Criteria**:

- `cpm/plugin.json` version is bumped for the new skill [manual]
- `cpm/README.md` documents `/cpm:clean` and the new non-blocking safety-net behaviour (3-day staleness, parallel-session awareness, no more BLOCKING) [manual]

### Bump `cpm/plugin.json` version
**Task**: 2.1
**Description**: Increment the plugin version for the new `/cpm:clean` skill, per the repo's versioning convention.
**Status**: Pending

### Update `cpm/README.md`
**Task**: 2.2
**Description**: Document `/cpm:clean` and the new non-blocking cleanup behaviour (3-day staleness, parallel-session awareness, BLOCKING removed). Covers the README criterion.
**Status**: Pending

---
