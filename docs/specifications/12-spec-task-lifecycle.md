# Spec: Task Lifecycle — Separate Planning from Execution

**Date**: 2026-02-11
**Brief**: Party mode discussion — task execution lifecycle issues in cpm:epics and cpm:do

## Problem Summary

The CPM plugin conflates planning artifacts (epic docs) with execution state (Claude Code tasks). `cpm:epics` prematurely registers every story and task in Claude Code's live task system during planning (Steps 4 and 5), even though those tasks won't be worked until a separate `cpm:do` invocation. Meanwhile, `cpm:do` doesn't build its own task list during execution and fails to reliably update the `.cpm-progress.md` file, leaving stale state on session abandonment or context compaction. The fix is to make epic docs the sole plan of record and have `cpm:do` own the full lifecycle of Claude Code tasks — creating them at execution time and maintaining progress state throughout.

## Functional Requirements

### Must Have
- Remove Step 4 (Create Tasks) from `cpm:epics` — no TaskCreate calls during planning
- Remove Step 5 (Set Dependencies) from `cpm:epics` — no TaskUpdate calls during planning
- Remove `**Task ID**` fields from the epic doc output template (both story and task level)
- Update Step 6 (Confirm) in `cpm:epics` to present the task tree using doc-level identifiers only (story numbers, task dot-notation)
- Add a hydration step in `cpm:do` that reads the epic doc and creates Claude Code tasks via TaskCreate
- Hydration is incremental (per-story) — only create tasks for the next unblocked story, not the entire epic
- Set up intra-story dependencies during hydration (verification gate blocked by its tasks) using the doc's structure
- Merge Step 6 (Mark Complete) and Step 7 (Update Progress File) in `cpm:do` into a single step — completion and state write happen together

### Should Have
- Scoped hydration — only hydrate tasks for the selected epic, never cross-epic
- Idempotent hydration — detect existing tasks from a previous partial run and skip re-creation

### Could Have
- Task ID backfill — after hydrating, write assigned Claude Code task IDs back into the epic doc for cross-reference

### Won't Have (this iteration)
- Changes to any other CPM skills (discover, spec, party, pivot, retro, archive, library)
- Cross-epic hydration (working multiple epics in a single `cpm:do` session)
- Migration tooling for existing epic docs that have Task IDs from the old flow

## Non-Functional Requirements

### Reliability
- The merged completion + progress-write step must ensure `.cpm-progress.md` is never stale if compaction fires mid-loop
- If the epic doc is missing or malformed, `cpm:do` still works on tasks using their descriptions alone (graceful degradation)
- A second invocation of `cpm:do` against the same epic/story must not create duplicate Claude Code tasks (idempotent hydration)

### Usability
- Hydration is automatic and transparent — no extra user prompts or confirmation gates
- The Claude Code task list only ever contains tasks for the current story being worked, not the full project backlog

## Architecture Decisions

### Per-Story Hydration
**Choice**: Hydrate one story at a time into Claude Code tasks
**Rationale**: A story is the natural unit of delivery — it has acceptance criteria, a verification gate, and a bounded set of tasks. Per-story hydration keeps the task list scoped to the current coherent unit of work and simplifies idempotency checking.
**Alternatives considered**: Full-epic hydration (simpler but pollutes the task list), per-task hydration (too granular, loses story-level structure)

### Remove Task ID Fields from Epic Docs
**Choice**: Remove `**Task ID**` fields from both story and task entries in the epic doc template
**Rationale**: Without Step 4 in `cpm:epics`, these fields would always read `—`. Story numbers (1, 2, 3) and task dot-notation (1.1, 1.2) are sufficient stable identifiers within the doc. `cpm:do` maintains its own internal mapping between doc identifiers and Claude Code task IDs during hydration.
**Alternatives considered**: Keep fields and have `cpm:do` backfill (adds write operations for marginal traceability), keep empty placeholders (dead fields are confusing)

### Merged Completion and Progress Write
**Choice**: Combine task completion (TaskUpdate) and progress file write (Write tool) into a single step in the `cpm:do` workflow
**Rationale**: The current separate Step 7 gets skipped in practice because the LLM's momentum carries it past bookkeeping to the next task. Making the progress write inseparable from the completion action ensures it happens.
**Alternatives considered**: Stronger wording on the separate step (already tried, doesn't work), pre-next-task checkpoint (adds another skippable step)

### Hydration as Gating Check
**Choice**: Hydration happens as a gating check before task selection — "Are there pending unblocked tasks? No → hydrate next story"
**Rationale**: This single mechanism covers both the initial work loop entry and story-to-story transitions. No need for duplicate hydration logic at two points in the workflow.
**Alternatives considered**: Explicit two-point hydration at loop start and after each gate (duplicates logic in the prompt)

## Scope

### In Scope
- Modify `cpm:epics` SKILL.md: remove Steps 4 and 5, remove `**Task ID**` from epic doc template, update Step 6 to use doc-level identifiers only
- Modify `cpm:do` SKILL.md: add per-story hydration as a gating check before task selection, merge Steps 6 and 7 into one step, renumber subsequent steps
- `cpm:do` hydration tolerates both old-format (with `**Task ID**` fields) and new-format (without) epic docs

### Out of Scope
- Changes to other CPM skills (discover, spec, party, pivot, retro, archive, library)
- Cross-epic hydration
- Migration or cleanup of existing epic docs
- Changes to the `.cpm-progress.md` format
- Changes to other steps in `cpm:do` beyond the merge

### Deferred
- Task ID backfill into epic docs after hydration
- Cleanup of Claude Code tasks after a story or epic completes
