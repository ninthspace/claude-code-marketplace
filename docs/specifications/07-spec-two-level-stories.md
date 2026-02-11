# Spec: Two-Level Story Model for CPM

**Date**: 2026-02-11
**Brief**: Party mode discussion — "stories are actually tasks"

## Problem Summary

CPM's `cpm:stories` skill produces a flat list of items labelled "stories" that are actually task-level granularity — "Write pre-compact.sh", "Create hooks.json". Each maps 1:1 to a Claude Code task via TaskCreate. There's no intermediate layer between epics and individual work items, so stories lack meaningful acceptance criteria and the task list gets flooded with fine-grained items. A two-level model is needed where stories represent coherent deliverables and contain sub-tasks as implementation steps.

## Functional Requirements

### Must Have
- Two-level stories doc format: Epic → Story (###) → Task (####) with dot-notation numbering (Story 1, Tasks 1.1, 1.2, 1.3)
- TaskCreate for both stories and sub-tasks — stories are verification gates, sub-tasks are implementation work
- Story verification gate tasks are `blockedBy` their own sub-tasks, so they only fire after implementation is complete
- Cross-story dependencies declared as `**Blocked by**: Story N` in the doc, translated to sub-tasks of the dependent story being `blockedBy` the upstream story's verification gate task
- cpm:stories Step 3 produces real stories — meaningful deliverables with acceptance criteria, not individual implementation steps
- cpm:stories Step 3b (new) identifies sub-tasks within each story through user facilitation
- cpm:stories Step 4 creates TaskCreate calls for both levels, recording Task IDs in the doc
- cpm:stories Step 5 applies two dependency rules: intra-story (gate blockedBy sub-tasks) and cross-story (sub-tasks blockedBy upstream gate)
- Both story and task entries in the doc have `**Task ID**` and `**Status**` fields

### Should Have
- cpm:do reports sub-task progress when completing items

### Could Have
- cpm:do can add new sub-tasks discovered during implementation

### Won't Have (this iteration)
- Sub-task dependencies within a story
- Sub-task metadata (sizing, time estimates, priority)
- Migration of existing stories docs to the new format

## Non-Functional Requirements

### Usability
- Stories doc must remain scannable — the additional nesting level should not make docs harder to read at a glance
- The distinction between story tasks (verification gates) and sub-tasks (implementation work) must be obvious from the task description
- Dot-notation numbering must be unambiguous: `1.1` always means "first sub-task of Story 1"

## Architecture Decisions

### Stories Doc Format
**Choice**: Stories at `###` heading level, tasks at `####`, within `##` epics. Both levels carry `**Task ID**` and `**Status**` fields. Stories additionally have `**Acceptance Criteria**` and `**Blocked by**`.
**Rationale**: Follows the existing markdown heading hierarchy naturally. Keeps task metadata minimal (number, ID, status only) to maintain scannability.
**Alternatives considered**: Tasks as checkbox lists (rejected — unreliable for tracking, can't carry Task IDs), tasks as a separate section outside stories (rejected — loses the grouping context).

### TaskCreate Description Conventions
**Choice**: Sub-task descriptions include `Stories doc:`, `Story:`, and `Task:` reference fields. Story verification gate descriptions include `Type: verification` marker.
**Rationale**: The description is the only link between Claude Code's task system and the stories doc. A structured suffix lets `cpm:do` navigate to the right place. The `Type: verification` marker distinguishes AC-checking work from implementation work.
**Alternatives considered**: Using task subject prefixes like `[verify]` (rejected — clutters the task list display), using metadata in TaskCreate (rejected — not supported by the tool).

### Dependency Translation
**Choice**: Two-rule system. Rule 1 (intra-story): each story's verification gate task is `addBlockedBy` all its sub-task IDs. Rule 2 (cross-story): if Story B is `**Blocked by**: Story A`, then all of Story B's sub-tasks are `addBlockedBy` Story A's verification gate task ID.
**Rationale**: Uses Claude Code's native `blockedBy` mechanism to orchestrate execution order. Story B's work can't begin until Story A is fully implemented AND verified. No custom orchestration logic needed in `cpm:do`.
**Alternatives considered**: Blocking only story-to-story without flowing through to sub-tasks (rejected — `cpm:do` picks from TaskList which shows sub-tasks, so they need to be properly blocked).

## Scope

### In Scope
- `cpm:stories` SKILL.md: Revise Step 3, add Step 3b, update Steps 4 and 5, update output template, update guidelines
- `cpm:do` SKILL.md: Update Load Context (step 1) to handle `####` task headings, update status marking (steps 2/6) for task-level headings, add `Type: verification` awareness for story gate tasks
- Stories doc output template: New two-level format
- Guidelines: Add guidance distinguishing story-level vs task-level granularity

### Out of Scope
- Migration of existing `docs/stories/` files
- Changes to other CPM skills (discover, spec, party, retro, pivot, library)
- Plugin manifest or version bump
- Sub-task dependencies within a story

### Deferred
- `cpm:do` dynamically adding sub-tasks during implementation
- Richer story-level metadata (story points, priority labels)
