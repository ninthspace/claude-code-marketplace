# CPM Status Skill

**Source spec**: docs/specifications/23-spec-cpm-status.md
**Date**: 2026-03-01
**Status**: Complete
**Blocked by**: —

## Write the `/cpm:status` SKILL.md
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: Artifact inventory scan, Git recent activity summary, Current state assessment, Recommended next steps, Ephemeral output

**Acceptance Criteria**:
- SKILL.md exists at `cpm/skills/status/SKILL.md` with valid YAML front-matter (`name: cpm:status`, description, trigger) `[manual]`
- Phase 1 instructions: Glob and read CPM artifacts across `docs/specifications/`, `docs/epics/`, `docs/discussions/`, `docs/retros/`, `docs/briefs/`, `docs/plans/`, reporting what exists with counts and completion status (e.g., "Epic 02: 4/6 stories complete") `[manual]`
- Phase 1 instructions: Handle missing directories silently (no errors for dirs that don't exist) `[manual]`
- Phase 2 instructions: Show recent commits grouped by category (code/docs/config), highlight commits that touched CPM artifacts `[manual]`
- Phase 3 instructions: Report current branch and uncommitted changes, show in-progress stories from epic docs `[manual]`
- Phase 3 instructions: Suggest concrete CPM commands based on project state with copy-pasteable commands `[manual]`
- Phase 3 instructions: On empty project, recommend starting skills (`/cpm:discover`, `/cpm:brief`); on completed project, recommend closing skills (`/cpm:retro`, `/cpm:archive`) `[manual]`
- Prints to stdout only — no files created or modified, no progress file, explicit "no state management" declaration `[manual]`
**Retro**: [Smooth delivery] Single-story prompt-only skill delivered in three clean tasks with no surprises — the discussion and spec front-loaded all decisions, leaving implementation straightforward.

### Create SKILL.md with front-matter and skill structure
**Task**: 1.1
**Description**: Set up `cpm/skills/status/SKILL.md` with YAML front-matter (name, description, trigger), top-level heading, purpose statement, Input section, explicit "No state management" declaration, and overall structure. Covers the front-matter/registration criterion and the ephemeral output/stateless declaration criterion.
**Status**: Complete

### Write Phase 1 — artifact inventory scan instructions
**Task**: 1.2
**Description**: Write the instructions for globbing and reading CPM artifacts across all doc directories, reporting counts and completion status, and handling missing directories silently. Covers the artifact inventory scan criteria (scan dirs with counts, epic completion status, missing dirs silent).
**Status**: Complete

### Write Phase 2 — git activity and Phase 3 — synthesis instructions
**Task**: 1.3
**Description**: Write instructions for git recent activity (commits grouped by category, CPM artifact highlights), current state (branch, uncommitted changes, in-progress stories), and recommended next steps (concrete commands, empty/mid-flight/complete state handling). Covers the remaining criteria.
**Status**: Complete

---

## Lessons

### Smooth Deliveries
- Story 1: Single-story prompt-only skill delivered in three clean tasks with no surprises — the discussion and spec front-loaded all decisions, leaving implementation straightforward.
