---
name: cpm:do
description: Execute tasks from a stories doc. Picks the next unblocked task, reads context and acceptance criteria, does the work, verifies criteria, updates the stories doc, and loops until done. Triggers on "/cpm:do".
---

# Task Execution

Work through tasks created by `cpm:stories`. For each task: read context, do the work, verify acceptance criteria, update the stories doc, and move on to the next.

## Input

Resolve the stories doc first, then select a task.

### Stories Doc

1. If `$ARGUMENTS` is a file path (e.g. `docs/stories/01-story-task-execution.md`), use that as the stories doc.
2. If no path given, look for the most recent `docs/stories/*-story-*.md` file and ask the user to confirm.
3. If no stories docs exist, proceed without one (tasks still work via their descriptions).

The stories doc, once resolved, applies to the entire work loop — don't re-parse it from each task.

### Task Selection

1. If `$ARGUMENTS` includes a task ID (e.g. `3` or `#3`), start with that task.
2. Otherwise, call `TaskList` and pick the lowest-ID task that is `pending` and has no unresolved `blockedBy`.
3. If no pending unblocked tasks exist, tell the user there's nothing to do.

## Library Check

After resolving the stories doc and before starting the per-task workflow, check the project library for reference documents:

1. **Glob** `docs/library/*.md`. If no files found or directory doesn't exist, skip silently.
2. **Read front-matter** of each file found (the YAML block between `---` delimiters, typically the first ~10 lines). Filter to documents whose `scope` array includes `do` or `all`.
3. **Report to user**: "Found {N} library documents relevant to task execution: {titles}. I'll reference these during implementation." If none match the scope filter, skip silently.
4. **Deep-read selectively** during task execution (step 4 of the per-task workflow) when a library document's content is directly relevant to the current task — e.g. reading coding standards before writing code, or architecture docs before making structural decisions.

**Graceful degradation**: If any library document has malformed or missing front-matter, fall back to using the filename as context. Never block task execution due to a malformed library document.

**Compaction resilience**: Include library scan results (files found, scope matches) in the progress file. These results persist across the entire task loop — do not re-scan between tasks. Only re-scan if the progress file is missing (post-compaction recovery).

## Per-Task Workflow

**State tracking**: Before starting the first task, create the progress file (see State Management below). Step 7 of each task cycle writes the update — do not skip it. After the work loop finishes, delete the file.

For each task, follow these steps in order.

### 1. Load Context

- Call `TaskGet` to read the full task description.
- If a stories doc was resolved during Input, read it with the Read tool. Locate the story by searching for the `**Task ID**: {id}` field that matches the current task ID. If no Task ID match is found, fall back to matching the task subject to a story heading (`### {subject}`). Note its acceptance criteria.
- If no stories doc is available, proceed without stories doc integration — the task still gets done.

### 2. Update Status to In Progress

- Call `TaskUpdate` to set the task status to `in_progress`.
- If stories doc integration is active, use the Edit tool to update the story's status:
  - `old_string`: `**Status**: Pending` (scoped near the matched story heading)
  - `new_string`: `**Status**: In Progress`

### 3. Plan (when warranted)

Before jumping into implementation, assess whether this task warrants entering plan mode (`EnterPlanMode`). Use plan mode when any of these apply:

- **Complex**: The task touches multiple files, requires architectural decisions, or has several moving parts
- **Critical**: The task is core infrastructure that other tasks depend on
- **Sensitive**: The task involves personal data, financial data, authentication, or other security-sensitive areas

Skip plan mode for straightforward tasks — config changes, documentation updates, simple additions to existing patterns.

When using plan mode: explore the codebase, design the approach, and get user approval before writing any code. Then exit plan mode and proceed to step 4.

### 4. Do the Work

Execute the task as described. This is the actual implementation — writing code, creating files, running commands, whatever the task requires.

Read the full task description and acceptance criteria to understand what "done" looks like. Work until all criteria are met.

### 5. Verify Acceptance Criteria

Before marking the task complete:

- Re-read the acceptance criteria from the stories doc (or from the task description if no stories doc).
- Self-assess each criterion. For each one, determine whether it's been met.
- If all criteria are met, proceed to step 6.
- If any criteria are **not** met, flag them to the user. List what's unmet and ask whether to continue working on them or mark the task as done anyway. Use AskUserQuestion for this gate.

### 6. Mark Complete

- If stories doc integration is active, use the Edit tool to update the story's status:
  - `old_string`: `**Status**: In Progress`
  - `new_string`: `**Status**: Complete`
- Call `TaskUpdate` to set the task status to `completed`.

### 6.5. Capture Observations (Retro)

After marking the task complete, self-assess whether anything **noteworthy** happened during this task. This is a quality gate — only record an observation when something surprising, unexpected, or valuable was learned. Most tasks will have nothing to record, and that's fine.

**Noteworthy-only gate**: Ask yourself: "Did anything happen during this task that would change how I'd plan similar work in the future?" If no, skip this step entirely. Do not prompt the user.

**Observation categories** (use exactly one per observation):
- **Scope surprise**: The task was larger or smaller than the story suggested
- **Criteria gap**: Acceptance criteria missed something important that only became clear during implementation
- **Complexity underestimate**: The implementation was harder than expected due to technical factors
- **Codebase discovery**: Found something unexpected in the codebase (pattern, convention, limitation) that affected the work

**Recording**: If something is noteworthy, use the Edit tool to append a `**Retro**:` field to the completed story in the stories doc, immediately after the last existing field for that story (before the `---` separator). Format:

```
**Retro**: [{category}] {One-sentence observation}
```

Example:
```
**Retro**: [Criteria gap] Acceptance criteria didn't mention error handling for missing config files, which was the bulk of the work
```

**Graceful degradation**: If no stories doc is available, or the story heading can't be found, skip this step silently — never block the work loop for observation capture.

### 7. Update Progress File

**This step is mandatory after every task.** Write the full `.cpm-progress.md` file using the Write tool (see State Management below for format). The file must reflect:
- The task just completed (added to Completed Tasks section)
- The next action (which task to pick up next, or "work loop complete")
- The current tasks remaining count

This is the primary compaction resilience mechanism. If compaction fires between tasks, this file is what gets re-injected to restore context.

### 8. Next Task

- Call `TaskList` to check for remaining work.
- Pick the next lowest-ID task that is `pending` and has no unresolved `blockedBy`.
- If one exists, go back to step 1 (Load Context) for the new task.
- If none exist, the work loop is done — proceed to step 9.

### 9. Batch Summary (Loop Completion)

When the work loop finishes (no more pending unblocked tasks):

1. **Check for observations**: Read the stories doc and scan for any `**Retro**:` fields across all completed stories. If none exist, skip the rest of this step — no lessons section needed.

2. **Synthesise lessons**: If observations were captured, append a `## Lessons` section to the end of the stories doc using the Edit tool. Group observations by category:

```markdown
## Lessons

### Scope Surprises
- {observation from story N}

### Criteria Gaps
- {observation from story N}

### Complexity Underestimates
- {observation from story N}

### Codebase Discoveries
- {observation from story N}
```

Only include categories that have observations. Each bullet should reference which story it came from. The summary must be scannable in under 30 seconds — keep it tight.

3. **Report and stop**: Report a summary of what was completed across the work loop, then delete the progress file.

## Graceful Degradation

The skill should work even without a stories doc:

- **No stories doc resolved during Input**: Skip stories doc reads and status updates. Still do the work, still verify acceptance criteria from the task description.
- **Stories doc file doesn't exist or was deleted mid-loop**: Same — skip stories doc integration, work on the task directly.
- **Story heading not found in stories doc**: Log a note, skip status updates for that story, continue with the work.

## State Management

Maintain `docs/plans/.cpm-progress.md` throughout the work loop for compaction resilience. This allows seamless continuation if context compaction fires mid-loop.

**Create** the file before starting the first task. **Update** it after each task completes. **Delete** it after the work loop finishes (no more tasks).

Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale). Format:

```markdown
# CPM Session State

**Skill**: cpm:do
**Current task**: {task ID} — {task subject}
**Stories doc**: {path to stories doc, or "none"}
**Tasks remaining**: {count of pending unblocked tasks}

## Completed Tasks

### Task {ID}: {Subject}
{Brief summary — what was done, which acceptance criteria were met/flagged}

### Task {ID}: {Subject}
{...continue for each completed task...}

## Next Action
{What to do next — e.g. "Pick up Task #4: Add validation endpoint" or "Work loop complete, delete state file"}
```

The "Completed Tasks" section grows as tasks complete. Each summary should capture what was implemented and the acceptance criteria outcome — enough for seamless continuation, not a detailed log.

The "Next Action" field tells the post-compaction context exactly where to pick up.

## Guidelines

- **Do the work.** This skill doesn't just plan — it implements. Write code, create files, run tests, whatever the task requires.
- **Acceptance criteria are the definition of done.** Don't mark a task complete if criteria aren't met unless the user explicitly approves.
- **Keep momentum.** Move through tasks efficiently. Don't over-explain between tasks — just pick up the next one and go.
- **One task at a time.** Complete each task fully before starting the next. Don't interleave work across tasks.
