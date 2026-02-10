# Stories: CPM Task Execution (cpm:do)

**Date**: 2026-02-10
**Source**: docs/specifications/cpm-task-execution.md

## Epic: Skill Implementation

### Write cpm:do SKILL.md core workflow
**Status**: Complete
**Blocked by**: —

**Acceptance Criteria**:
- SKILL.md has correct frontmatter (name: cpm:do, description, triggers)
- Task selection works: auto-pick lowest unblocked ID, optional task ID override
- Stories doc is read before starting each task
- Status updates happen: Pending → In Progress (on start), In Progress → Complete (on finish)
- Acceptance criteria are checked before marking complete
- Work loop continues to next task after each completion
- Loop stops when no unblocked pending tasks remain
- Graceful degradation when stories doc is missing

---

### Add compaction resilience to cpm:do
**Status**: Complete
**Blocked by**: #1

**Acceptance Criteria**:
- State Management section added to SKILL.md
- State file created before first task in the loop
- State file updated after each task completes
- State file deleted when the work loop finishes
- State includes completed task summaries with AC status
- Post-compaction continuation is seamless (state has enough detail)

---

## Epic: Plugin Packaging

### Register cpm:do skill and update plugin metadata
**Status**: Complete
**Blocked by**: #1, #2

**Acceptance Criteria**:
- `/cpm:do` is listed in available skills
- plugin.json version is bumped
- README documents the new skill with usage examples
- README shows the full CPM workflow: discover → spec → stories → do

---

## Implementation Order

1. **#1** core SKILL.md — the foundation everything else builds on
2. **#2** compaction resilience — adds state tracking to the skill
3. **#3** packaging — final step once all features are in place
