# Spec: CPM Task Execution (cpm:do)

**Date**: 2026-02-10
**Brief**: User-described problem — stories docs and acceptance criteria go stale after task creation

## Problem Summary

The CPM stories skill creates stories documents with acceptance criteria and Claude Code tasks, but once tasks are implemented nothing ties the work back to the stories document. Story statuses stay "Pending" forever and acceptance criteria aren't verified. The gap is in task execution workflow — a new `cpm:do` skill closes the loop.

## Functional Requirements

### Must Have
- Read the stories doc for full context and acceptance criteria before starting each task
- Update the stories doc status from "Pending"/"In Progress" to "Complete" when a task is finished
- Check acceptance criteria from the stories doc before marking a task complete
- Loop after completing a task — auto-pick the next unblocked pending task and continue until none remain

### Should Have
- Update the stories doc status to "In Progress" when a task is started
- Flag unmet acceptance criteria to the user before completing (rather than silently marking done)

### Could Have
- Brief evidence summary of how each acceptance criterion was met

### Won't Have (this iteration)
- Automated test generation from acceptance criteria
- Dashboard or progress reporting tool
- Changes to how the stories skill creates the initial document

## Non-Functional Requirements

### Reliability
- If the stories doc can't be found (path missing, file deleted), the skill still works on the task — just without stories doc integration
- Stories doc edits are safe — targeted status line replacement only, no risk of rewriting the file

### Usability
- Zero friction — `/cpm:do` with no arguments picks the next task and starts working
- Acceptance criteria check feels like a natural wrap-up, not a bureaucratic gate

## Architecture Decisions

### Skill Structure
**Choice**: New prompt-only skill at `cpm/skills/do/SKILL.md`
**Rationale**: Same pattern as discover, spec, and stories. No scripts needed — the skill prompt instructs Claude on the full workflow.
**Alternatives considered**: Adding to stories SKILL.md (conflates creation with execution); hook-based approach (over-engineered for what's fundamentally a workflow prompt)

### Task Selection
**Choice**: `TaskList` → lowest-ID unblocked pending task, with optional task ID override via argument
**Rationale**: Lowest ID preserves the natural implementation order from the stories skill. Override lets users target specific tasks when needed.
**Alternatives considered**: User always specifies (too much friction for a work loop); priority-based selection (no priority system exists)

### Work Loop
**Choice**: After completing a task, call `TaskList` again, pick the next unblocked pending task, and continue until none remain
**Rationale**: The user invokes `/cpm:do` once and walks away (or watches). No need to re-invoke per task. Stops naturally when the backlog is empty.
**Alternatives considered**: One-shot per invocation (user said they want continuous execution)

### Stories Doc Updates
**Choice**: `Edit` tool for targeted string replacement — `**Status**: Pending` → `**Status**: In Progress` → `**Status**: Complete`, matched by the story's title heading
**Rationale**: Surgical edit, not a file rewrite. The story title in the stories doc matches the task subject, providing a reliable anchor.
**Alternatives considered**: Rewriting the full file (risky, could corrupt other sections); regex-based approach (unnecessary complexity)

### Acceptance Criteria Verification
**Choice**: Self-assess each criterion before marking a task complete; flag unmet criteria to the user
**Rationale**: The criteria are already in the stories doc. Reading and checking them is natural. Flagging rather than blocking keeps it practical.
**Alternatives considered**: Automated testing (out of scope); user manually confirms each criterion (too much friction)

### Compaction Resilience
**Choice**: Same `docs/plans/.cpm-progress.md` pattern as other CPM skills
**Rationale**: Proven pattern, consistent across the plugin. Especially important here since the work loop could be long-running.
**Alternatives considered**: No state tracking (unacceptable for long loops); separate state file per skill (unnecessary — skills run sequentially, `**Skill**` field acts as ownership marker)

## Scope

### In Scope
- New `cpm:do` skill (`cpm/skills/do/SKILL.md`)
- Task selection (auto-pick lowest unblocked ID + optional override)
- Work loop (continue until no unblocked pending tasks remain)
- Stories doc status updates (Pending → In Progress → Complete)
- Acceptance criteria verification before task completion
- Compaction resilience via `.cpm-progress.md`
- Plugin registration (skill description for discovery)

### Out of Scope
- Changes to the stories skill's document creation
- Automated test generation from acceptance criteria
- Dashboard, reporting, or progress visualization
- Modifying how other CPM skills work

### Deferred
- Evidence summaries (how each criterion was met)
- Handling tasks without a stories doc reference (standalone TaskCreate usage outside CPM)
