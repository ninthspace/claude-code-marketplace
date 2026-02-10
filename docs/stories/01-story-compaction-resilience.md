# Stories: CPM Compaction Resilience

**Date**: 2026-02-10
**Source**: docs/specifications/cpm-compaction-resilience.md

## Epic: Hook Infrastructure & Packaging

### Create hooks.json configuration
**Status**: Pending
**Blocked by**: —

**Acceptance Criteria**:
- `cpm/hooks/hooks.json` is valid JSON matching Claude Code's hook schema
- Configures PreCompact, SessionStart (compact), and SessionStart (startup/resume) hooks
- All hooks point to scripts via `${CLAUDE_PLUGIN_ROOT}`
- SessionStart compact uses matcher "compact"; startup/resume uses appropriate matcher

---

### Write pre-compact.sh hook script
**Status**: Pending
**Blocked by**: #1

**Acceptance Criteria**:
- Script is executable (chmod +x)
- Exits cleanly (0) when no state file exists at `$CLAUDE_PROJECT_DIR/docs/plans/.cpm-progress.md`
- Outputs summary guidance when state file exists (skill name, current phase)
- Completes well within 60-second timeout

---

### Write session-start-compact.sh hook script
**Status**: Pending
**Blocked by**: #1

**Acceptance Criteria**:
- Script is executable
- Exits cleanly when no state file exists
- Cats the full state file contents to stdout when it exists
- No transformation or filtering — direct injection into post-compaction context

---

### Write session-start.sh hook script
**Status**: Pending
**Blocked by**: #1

**Acceptance Criteria**:
- Script is executable
- Exits cleanly when no state file exists
- Cats the full state file plus a note indicating this is from a previous session
- The note prompts Claude to ask the user whether to continue or discard

---

### Update plugin.json and README
**Status**: Pending
**Blocked by**: #6, #7, #8

**Acceptance Criteria**:
- Version bumped to 1.1.0 in plugin.json
- README documents the compaction resilience feature and hooks/ directory
- README explains the state file mechanism and lifecycle
- README explains user-facing behaviour (seamless continuation, session resume offer)

---

## Epic: Skill State Writing

### Add state writing to discover SKILL.md
**Status**: Pending
**Blocked by**: #3

**Acceptance Criteria**:
- State file created when discover starts
- State file updated after each of the 6 phases (Why, Who, Current State, Success Criteria, Constraints, Summary)
- Completed phase summaries capture user's decisions (not a transcript)
- State file deleted after the final brief is saved
- Skill works identically from the user's perspective (state writing is invisible)

---

### Add state writing to spec SKILL.md
**Status**: Pending
**Blocked by**: #3

**Acceptance Criteria**:
- State file created when spec starts
- State file updated after each of the 6 sections (Problem Recap, Functional Reqs, Non-Functional Reqs, Architecture Decisions, Scope Boundary, Review)
- Completed section summaries capture requirements, decisions, and priorities
- State file deleted after the final spec is saved
- Skill works identically from the user's perspective

---

### Add state writing to stories SKILL.md
**Status**: Pending
**Blocked by**: #3

**Acceptance Criteria**:
- State file created when stories starts
- State file updated after each of the 6 steps (Read Source, Identify Epics, Break into Stories, Create Tasks, Set Dependencies, Confirm)
- Completed step summaries include epic names, story titles, and task IDs
- State file deleted after the final stories doc is saved
- Skill works identically from the user's perspective

---

## Implementation Order

1. **#1** hooks.json — sets up the hook configuration
2. **#2, #3, #4** hook scripts — can be done in parallel after #1
3. **#6, #7, #8** skill updates — can be done in parallel after #3
4. **#5** packaging — final step once all features are in place
