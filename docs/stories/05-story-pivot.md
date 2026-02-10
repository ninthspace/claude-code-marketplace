# Stories: cpm:pivot — Course Correction

**Date**: 2026-02-10
**Source**: docs/specifications/05-spec-pivot.md

## Epic: Core Pivot Skill

### Create cpm:pivot SKILL.md skeleton
**Story**: 1
**Task ID**: 1
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- SKILL.md created with frontmatter (name, description, triggers)
- Input resolution documented (file path from args, or artefact selection)
- Core workflow documented: select → read → edit → summarise
- State management section for compaction resilience
- Graceful exit if no planning documents found

---

### Build artefact chain discovery
**Story**: 2
**Task ID**: 2
**Status**: Complete
**Blocked by**: Story 1

**Acceptance Criteria**:
- Globs all three planning directories
- Reads back-reference fields to build dependency chain
- Falls back to slug matching when references missing
- Handles partial chains (spec without brief, stories without spec)
- Presents discovered chain to user for selection
- Accepts direct file path from $ARGUMENTS to skip selection

---

### Implement surgical amendment workflow
**Story**: 3
**Task ID**: 3
**Status**: Complete
**Blocked by**: Story 1

**Acceptance Criteria**:
- Selected document read and presented to user
- User describes changes in natural language; Claude applies via Edit tool
- Change summary presented after edits (what changed, downstream implications)
- Edits saved to disk immediately
- State management via .cpm-progress.md throughout

---

## Epic: Cascade & Impact

### Implement cascading update facilitation
**Story**: 4
**Task ID**: 4
**Status**: Complete
**Blocked by**: Story 2, Story 3

**Acceptance Criteria**:
- Walks downstream documents in dependency order
- Identifies affected sections by comparing against upstream changes
- Proposes updates with clear rationale for each
- AskUserQuestion gates each downstream change (approve/modify/skip)
- Already-saved upstream edits preserved if cascade fails midway
- Skipped gracefully if no downstream documents exist

---

### Implement task impact flagging
**Story**: 5
**Task ID**: 5
**Status**: Complete
**Blocked by**: Story 4

**Acceptance Criteria**:
- Matches affected stories to tasks via task ID or subject matching
- Presents list of potentially affected tasks to user
- No automatic task modification
- Skipped gracefully if no tasks exist or stories doc wasn't changed

---

## Epic: Plugin Registration

### Register cpm:pivot in plugin manifest
**Story**: 6
**Task ID**: 6
**Status**: Complete
**Blocked by**: Story 1

**Acceptance Criteria**:
- Skill registered in plugin.json with name, description, and trigger
- /cpm:pivot invocable from Claude Code
