# Stories: CPM Archive Skill

**Date**: 2026-02-11
**Source**: docs/specifications/10-spec-archive.md

## Epic: SKILL.md Implementation

### Write the archive skill SKILL.md
**Story**: 1
**Task ID**: 6
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- SKILL.md exists at `cpm/skills/archive/SKILL.md` with correct frontmatter
- Skill scans `docs/plans/`, `docs/specifications/`, `docs/stories/`, `docs/retros/` for candidates
- Documents are grouped into artifact chains by slug extraction
- Four staleness heuristics are implemented (stories complete, orphaned plan, completed retro, spec fully implemented)
- User selects candidates via AskUserQuestion (individual, all, skip)
- Dry-run summary is presented before any moves
- Files are moved to `docs/archive/{subdirectory}/` preserving mirrored structure
- Per-file success/failure is reported if a move fails mid-chain
- State management via `.cpm-progress.md` follows CPM compaction resilience pattern
- `docs/library/` is explicitly excluded from scanning

#### Write SKILL.md frontmatter and skeleton structure
**Task**: 1.1
**Description**: Sets up the file with name, description, input handling, and section headings following CPM skill patterns
**Task ID**: 1
**Status**: Complete

#### Implement scanning, slug extraction, and chain grouping logic
**Task**: 1.2
**Description**: Covers Glob-based scanning of four docs directories, slug parsing from filenames, and grouping documents into artifact chains
**Task ID**: 2
**Status**: Complete

#### Implement staleness heuristics
**Task**: 1.3
**Description**: Defines the four staleness signals: stories complete, orphaned plan, completed retro, spec fully implemented
**Task ID**: 3
**Status**: Complete

#### Implement user presentation, selection, and archive execution flow
**Task**: 1.4
**Description**: Covers dry-run summary, AskUserQuestion selection gates, Bash mv commands, mirrored directory creation, and per-file error reporting
**Task ID**: 4
**Status**: Complete

#### Add state management for compaction resilience
**Task**: 1.5
**Description**: Adds .cpm-progress.md create/update/delete lifecycle following CPM patterns
**Task ID**: 5
**Status**: Complete

---

## Epic: Plugin Integration

### Register archive skill and update documentation
**Story**: 2
**Task ID**: 8
**Status**: Complete
**Blocked by**: Story 1

**Acceptance Criteria**:
- Skill is accessible via `/cpm:archive`
- README includes `/cpm:archive` in the skill list, pipeline diagram, and "What's Included" tree
- README description matches the skill's actual behavior

#### Create skill directory and update README
**Task**: 2.1
**Description**: Ensures cpm/skills/archive/ directory exists with SKILL.md and adds /cpm:archive to README skill list, pipeline diagram, and file tree
**Task ID**: 7
**Status**: Complete
