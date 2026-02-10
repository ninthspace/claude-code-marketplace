# Stories: cpm:retro — Lightweight Retrospective

**Date**: 2026-02-10
**Source**: docs/specifications/04-spec-retro.md

## Epic: Inline Capture in cpm:do

### Add per-task observation capture to cpm:do (step 6.5)
**Story**: 1
**Task ID**: 1
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- Step 6.5 documented in SKILL.md with clear instructions for noteworthy-only gate
- Observation categories defined (scope surprise, criteria gap, complexity underestimate, codebase discovery)
- Graceful degradation: if stories doc unavailable, skip without error
- Observations written immediately to disk via Edit tool

---

### Add batch summary to cpm:do loop completion
**Story**: 2
**Task ID**: 2
**Status**: Complete
**Blocked by**: Story 1

**Acceptance Criteria**:
- Lessons section appended to stories doc on loop completion
- Observations grouped by category
- Summary scannable in under 30 seconds
- Skipped if no observations were captured during the batch

---

## Epic: Standalone cpm:retro Skill

### Create cpm:retro SKILL.md
**Story**: 3
**Task ID**: 3
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- SKILL.md created with input resolution (file path, or auto-detect most recent stories doc)
- Reads and synthesises observations from stories doc
- Writes retro file to docs/retros/ with auto-incrementing number
- Categorised summary (grouped by observation type)
- State management for compaction resilience
- Works even if no **Retro**: fields exist (produces summary from stories doc status alone)

---

### Add pipeline handoff from cpm:retro
**Story**: 4
**Task ID**: 4
**Status**: Complete
**Blocked by**: Story 3

**Acceptance Criteria**:
- AskUserQuestion offers discover/spec/stories/exit options
- Retro file path passed as context to chosen next skill
- "Just exit" option available

---

### Register cpm:retro in plugin manifest
**Story**: 5
**Task ID**: 5
**Status**: Complete
**Blocked by**: Story 3

**Acceptance Criteria**:
- Skill registered in plugin.json with name, description, and trigger
- /cpm:retro invocable from Claude Code

---

## Epic: Feed-Forward Integration

### Add retro file check to cpm:discover startup
**Story**: 6
**Task ID**: 6
**Status**: Complete
**Blocked by**: Story 3

**Acceptance Criteria**:
- Discover checks docs/retros/ for recent files during input resolution
- If retro file found, presents it to user and asks whether to incorporate
- Existing discover flow unaffected if no retro files exist

---

### Add retro file check to cpm:spec startup
**Story**: 7
**Task ID**: 7
**Status**: Complete
**Blocked by**: Story 3

**Acceptance Criteria**:
- Spec checks docs/retros/ for recent files during input resolution
- If retro file found, offers to incorporate as additional context
- Existing spec flow unaffected if no retro files exist
