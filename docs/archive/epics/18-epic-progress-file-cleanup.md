# Progress File Cleanup

**Source spec**: docs/specifications/21-spec-progress-file-cleanup.md
**Date**: 2026-02-22
**Status**: Complete
**Blocked by**: —

## Implement orphan detection with cleanup output
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: Orphan detection, No silent deletion, Concurrent session safety, Unified prompt format, Age-based visual hints, Per-file selection

**Acceptance Criteria**:
- Hook output includes orphan file details when files from other session IDs exist `[unit]`
- Hook output does NOT flag files matching the current session ID as orphans `[unit]`
- When no orphan files exist, no cleanup guidance is output `[unit]`
- Hook output presents file info for user decision — never includes auto-executing delete commands `[unit]`
- Output includes file paths so the LLM can act on user's deletion choice `[unit]`
- Each orphan file's output includes skill name, phase, and age `[unit]`
- Files from another active session are presented with the same info — user decides `[unit]`
- Orphan files and stale files use the same output structure `[unit]`
- Files older than 24h include an age indicator in the output `[unit]`
- Files younger than 24h include age but without a stale marker `[unit]`
- Each orphan file is listed as a separate block with its own file path `[unit]`

### Add session ID extraction from filenames and classify files
**Task**: 1.1
**Description**: Covers the core orphan detection criteria — extract session ID from each progress file's filename, compare against current `CPM_SESSION_ID`, and classify as current-session (inject as active state) vs. other-session (orphan candidate). Subsumes the existing stale detection into a broader classification.
**Status**: Complete

### Produce per-file orphan output blocks with metadata
**Task**: 1.2
**Description**: Covers the output formatting criteria — each orphan file listed as a separate block with skill name, phase, age, and file path. Age-based visual hints for files >24h. Consistent structure across orphan and stale classifications. Replaces the current `stale_files` accumulator with the new output format.
**Status**: Complete

### Write tests for orphan detection and cleanup output
**Task**: 1.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`. Extend existing `test-orphan-detection.sh` and/or `test-startup-hook.sh` suites using the `test-helpers.sh` framework and fixture helpers.
**Status**: Complete

**Retro**: [Codebase discovery] Editing the plugin cache instead of the repo source was caught by the user — led to creating a CLAUDE.md guardrail to prevent this in future sessions.

---

## Lessons

### Codebase Discoveries
- Story 1: Editing the plugin cache instead of the repo source was caught by the user — led to creating a CLAUDE.md guardrail to prevent this in future sessions. The cache at `~/.claude/plugins/cache/` mirrors the repo source but changes there aren't git-tracked and are overwritten on updates.
