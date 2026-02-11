# Stories: Epic Hierarchy for CPM

**Date**: 2026-02-11
**Source**: docs/specifications/11-spec-epic-hierarchy.md

## Epic: Core Skill Rewrite

### Rewrite cpm:epics SKILL.md
**Story**: 1
**Task ID**: 5
**Status**: Pending
**Blocked by**: —

**Acceptance Criteria**:
- SKILL.md exists at `cpm/skills/epics/SKILL.md` with frontmatter name `cpm:epics`
- Skill produces epic docs at `docs/epics/{nn}-epic-{slug}.md`
- Can produce multiple epic files from a single spec (1:many)
- Epic doc format uses `#` epic, `##` story, `###` task with local numbering
- Cross-epic dependency convention: `**Blocked by**: Epic {nn}-epic-{slug}`
- Epic-level `**Status**:` field and `**Source spec**:` back-reference in output template
- State management follows `.cpm-progress.md` pattern with `docs/epics/` paths

#### Write SKILL.md frontmatter and process skeleton
**Task**: 1.1
**Description**: Sets up the file with `cpm:epics` name, description, input handling, and step structure following CPM skill patterns
**Task ID**: 1
**Status**: Complete

#### Implement epic identification and 1:many workflow
**Task**: 1.2
**Description**: Covers Step 2 (identify epics from spec) and the loop that produces multiple epic files from a single spec
**Task ID**: 2
**Status**: Complete

#### Write epic doc output template
**Task**: 1.3
**Description**: The new `#`/`##`/`###` format with cross-epic deps, status, source spec back-reference, and local numbering
**Task ID**: 3
**Status**: Complete

#### Update state management for epics
**Task**: 1.4
**Description**: Progress file references `docs/epics/` paths and handles multi-file output tracking
**Task ID**: 4
**Status**: Complete

---

### Rename skill directory
**Story**: 2
**Task ID**: 7
**Status**: Pending
**Blocked by**: Story 1

**Acceptance Criteria**:
- `cpm/skills/epics/` directory exists with `SKILL.md`
- `cpm/skills/stories/` directory no longer exists
- No broken references within the epics skill itself

#### Move directory and verify
**Task**: 2.1
**Task ID**: 6
**Status**: Complete

---

## Epic: cpm:do Updates

### Update cpm:do for epic doc format
**Story**: 3
**Task ID**: 10
**Status**: Pending
**Blocked by**: Story 1

**Acceptance Criteria**:
- `cpm:do` references `docs/epics/` instead of `docs/stories/`
- Heading matching uses `##` for stories and `###` for tasks (shifted from `###`/`####`)
- `Type: verification` detection and all existing cpm:do behaviour preserved
- Glob patterns updated to `docs/epics/*-epic-*.md`

#### Update path references and glob patterns
**Task**: 3.1
**Description**: Changes `docs/stories/` to `docs/epics/` and `*-story-*` to `*-epic-*` throughout cpm:do SKILL.md
**Task ID**: 8
**Status**: Complete

#### Update heading-level matching
**Task**: 3.2
**Description**: Shifts story matching from `###` to `##` and task matching from `####` to `###` in Load Context and status update steps
**Task ID**: 9
**Status**: Complete

---

### Implement smart epic discovery
**Story**: 4
**Task ID**: 12
**Status**: Pending
**Blocked by**: Story 3

**Acceptance Criteria**:
- Explicit file path argument still takes precedence
- When multiple epic files exist, scans TaskList for unblocked tasks per epic
- Auto-selects if only one epic has unblocked work
- Presents a choice when multiple epics have unblocked tasks
- Works gracefully when no epic files exist (falls back to task descriptions)

#### Implement smart epic discovery logic
**Task**: 4.1
**Description**: Scan epic files, check TaskList for unblocked tasks per epic, auto-select or ask the user when there's a genuine choice
**Task ID**: 11
**Status**: Complete

---

## Epic: Cascade & Documentation

### Update supporting skills
**Story**: 5
**Task ID**: 15
**Status**: Pending
**Blocked by**: Story 1

**Acceptance Criteria**:
- `cpm/skills/archive/SKILL.md` scans `docs/epics/` with updated staleness heuristics for epic format
- `cpm/skills/retro/SKILL.md` references `docs/epics/`
- `cpm/skills/pivot/SKILL.md` references `docs/epics/`
- `cpm/skills/spec/SKILL.md` suggests `/cpm:epics` as next step
- `cpm/skills/party/SKILL.md` offers `/cpm:epics` in pipeline handoff
- No remaining references to `docs/stories/` or `cpm:stories` in any of these five files

#### Update cpm:archive
**Task**: 5.1
**Description**: Updates scan paths, glob patterns, and staleness heuristics for the epic doc format
**Task ID**: 13
**Status**: Complete

#### Update cpm:retro, cpm:pivot, cpm:spec, and cpm:party
**Task**: 5.2
**Description**: Path and name reference changes across four skills — replacing docs/stories/ with docs/epics/ and cpm:stories with cpm:epics
**Task ID**: 14
**Status**: Complete

---

### Update README
**Story**: 6
**Task ID**: 17
**Status**: Pending
**Blocked by**: Story 5

**Acceptance Criteria**:
- Pipeline diagram shows `discover → spec → epics → do`
- File tree shows `cpm/skills/epics/` instead of `cpm/skills/stories/`
- All mentions of `cpm:stories` replaced with `cpm:epics`
- All mentions of `docs/stories/` replaced with `docs/epics/`
- Skill descriptions reflect epic-based output

#### Update README
**Task**: 6.1
**Task ID**: 16
**Status**: Complete

---
