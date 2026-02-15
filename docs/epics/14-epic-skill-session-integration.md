# Skill Session ID Integration

**Source spec**: docs/specifications/17-spec-parallel-sessions.md
**Date**: 2026-02-15
**Status**: Pending
**Blocked by**: Epic 13-epic-session-hooks

## Update State Management sections for session-scoped filenames
**Story**: 1
**Status**: Pending
**Blocked by**: —
**Satisfies**: Req 1 (Session-scoped progress files), Req 6 (SKILL.md updates)

**Acceptance Criteria**:
- All 14 SKILL.md files reference `CPM_SESSION_ID` in their State Management section `[manual]`
- Progress file path uses `.cpm-progress-{session_id}.md` pattern consistently across all skills `[manual]`
- Skills write to session-scoped path instead of shared `.cpm-progress.md` `[manual]`
- Two concurrent skills in the same project produce separate progress files `[manual]`

### Update State Management in core pipeline skills
**Task**: 1.1
**Description**: Update `discover`, `brief`, `architect`, `spec`, `epics` SKILL.md files to use `CPM_SESSION_ID` in the progress file path.
**Status**: Pending

### Update State Management in execution and review skills
**Task**: 1.2
**Description**: Update `do`, `review`, `retro`, `pivot` SKILL.md files. These have more complex state patterns (e.g., `do` tracks test commands, frameworks, task counts).
**Status**: Pending

### Update State Management in auxiliary skills
**Task**: 1.3
**Description**: Update `party`, `present`, `archive`, `library`, `templates` SKILL.md files. Verify whether `templates` needs a progress file; skip if not.
**Status**: Pending

---

## Add session ID adoption for resume scenario
**Story**: 2
**Status**: Pending
**Blocked by**: Story 1
**Satisfies**: Req 5 (Session ID adoption on resume)

**Acceptance Criteria**:
- All 14 SKILL.md files include resume adoption instructions `[manual]`
- On resume, skill creates new progress file with current session ID `[manual]`
- Old progress file (previous session ID) is deleted after new file confirmed written `[manual]`

### Draft the resume adoption paragraph
**Task**: 2.1
**Description**: Write the standard instruction text that tells Claude how to detect a mismatched session ID, create a new file with the current ID, and delete the old one atomically.
**Status**: Pending

### Add resume adoption to all 14 SKILL.md files
**Task**: 2.2
**Description**: Insert the resume adoption paragraph into each skill's State Management section after the progress file path instructions.
**Status**: Pending
