---
name: cpm:do
description: Execute tasks from an epic doc. Picks the next unblocked task, reads context and acceptance criteria, does the work, verifies criteria, updates the epic doc, and loops until done. Triggers on "/cpm:do".
---

# Task Execution

Work through stories and tasks defined in epic documents produced by `cpm:epics`. Hydrates one story at a time into Claude Code's task system, then for each task: read context, do the work, verify acceptance criteria, update the epic doc, and move on to the next.

## Input

Resolve the epic doc first, then select a task.

### Epic Doc

1. If `$ARGUMENTS` is a file path (e.g. `docs/epics/01-epic-setup.md`), use that as the epic doc.
2. If no path given, run smart discovery:
   a. **Glob** `docs/epics/*-epic-*.md` to find all epic files.
   b. If no epic files found, proceed without one (tasks still work via their descriptions).
   c. If only one epic file exists, use it — no need to ask.
   d. If multiple epic files exist, read each file's `**Status**:` field (top-level, near the `#` heading). Filter to epics that are not `Complete`. If only one has remaining work, auto-select it. If multiple have remaining work, present the choices to the user with AskUserQuestion — show each epic's name and status.
   e. If all epics are `Complete`, tell the user there's nothing to do.
3. If no epic docs exist, proceed without one (tasks still work via their descriptions).

The epic doc, once resolved, applies to the entire work loop — don't re-parse it from each task.

### Task Selection

1. If `$ARGUMENTS` includes a task ID (e.g. `3` or `#3`), start with that task.
2. Otherwise, run the **Story Hydration** gating check (see below). This ensures Claude Code tasks exist for the current story before selection.
3. Call `TaskList` and pick the lowest-ID task that is `pending` and has no unresolved `blockedBy`.
4. If no pending unblocked tasks exist after hydration, the work is done.

## Library Check

After resolving the epic doc and before starting the per-task workflow, check the project library for reference documents:

1. **Glob** `docs/library/*.md`. If no files found or directory doesn't exist, skip silently.
2. **Read front-matter** of each file found (the YAML block between `---` delimiters, typically the first ~10 lines). Filter to documents whose `scope` array includes `do` or `all`.
3. **Report to user**: "Found {N} library documents relevant to task execution: {titles}. I'll reference these during implementation." If none match the scope filter, skip silently.
4. **Deep-read selectively** during task execution (step 4 of the per-task workflow) when a library document's content is directly relevant to the current task — e.g. reading coding standards before writing code, or architecture docs before making structural decisions.

**Graceful degradation**: If any library document has malformed or missing front-matter, fall back to using the filename as context. Never block task execution due to a malformed library document.

**Compaction resilience**: Include library scan results (files found, scope matches) in the progress file. These results persist across the entire task loop — do not re-scan between tasks. Only re-scan if the progress file is missing (post-compaction recovery).

## Story Hydration

When `cpm:do` needs work and no pending unblocked Claude Code tasks exist, it hydrates the next story from the epic doc into Claude Code's task system. This is the bridge between planning artifacts (epic docs) and execution state (Claude Code tasks).

### When to Hydrate

Hydration fires as a **gating check before task selection**:

1. Call `TaskList`. If there are pending unblocked tasks, skip hydration — proceed directly to task selection.
2. If no pending unblocked tasks exist, hydrate the next story (see below).
3. If hydration finds no unblocked stories remaining, the work loop is done.

This single mechanism covers both the initial work loop entry and story-to-story transitions.

### How to Hydrate

When hydration is triggered:

1. **Read the epic doc** using the Read tool. Parse all `##` story headings and their metadata fields (`**Story**:`, `**Status**:`, `**Blocked by**:`).

2. **Identify the next unblocked story**:
   - A story is unblocked when its `**Blocked by**` field is either `—` (no dependencies) or all referenced stories have `**Status**: Complete`.
   - Among unblocked stories, pick the lowest-numbered one with `**Status**: Pending`.
   - If no unblocked pending stories remain, the epic is done — proceed to batch summary.

3. **Check for existing tasks** (idempotency): Call `TaskList` and scan task descriptions for entries that reference the same epic doc path and story number (e.g. `Epic doc: {path}` and `Story: {N}`). If matching tasks already exist — from a previous partial run or interrupted session — skip creation and use the existing tasks. Proceed directly to step 6 (task selection).

4. **Create Claude Code tasks** for the selected story:
   - For each `###` task heading within the story, call TaskCreate:
     ```
     TaskCreate:
       subject: "{Task title from ### heading}"
       description: "{**Description** field if present, otherwise task title}\n\nEpic doc: {epic doc path}\nStory: {N}\nTask: {N.M}"
       activeForm: "{Present continuous form of the task title}"
     ```
   - After all tasks, create the story's verification gate:
     ```
     TaskCreate:
       subject: "Verify: {Story title}"
       description: "Verify acceptance criteria for Story {N}: {Story title}\n\n{List the acceptance criteria}\n\nEpic doc: {epic doc path}\nStory: {N}\nType: verification"
       activeForm: "Verifying: {Story title}"
     ```

5. **Set intra-story dependencies**: Call TaskUpdate on the verification gate task with `addBlockedBy` set to all the task IDs just created. This ensures the gate only fires after all implementation work is complete.

6. **Proceed to task selection** — the newly created tasks are now available for the work loop to pick up.

### Format Tolerance

The hydration parser must tolerate both:
- **Old-format** epic docs (with `**Task ID**: —` fields present) — ignore these fields
- **New-format** epic docs (without `**Task ID**` fields) — the default going forward

Parse stories and tasks by their heading structure (`##` for stories, `###` for tasks within stories) and metadata fields (`**Story**:`, `**Task**:`, `**Status**:`, `**Blocked by**:`, `**Description**:`). Ignore any unrecognised fields.

## Per-Task Workflow

**State tracking**: Before starting the first task, create the progress file (see State Management below). Step 6 Part C of each task cycle writes the progress update as part of the completion step. After the work loop finishes, delete the file.

For each task, follow these steps in order.

### 1. Load Context

- Call `TaskGet` to read the full task description. The description includes the `Epic doc:`, `Story:`, and `Task:` fields set during hydration.
- If an epic doc was resolved during Input, read it with the Read tool. Use the `Story:` and `Task:` fields from the task description to locate the matching entry — search for the `**Story**: {N}` or `**Task**: {N.M}` field that matches. For verification gate tasks, match the `##` story heading. For implementation tasks, match the `###` task heading. Note the parent story's acceptance criteria — for `###` tasks, look up to the nearest `##` story heading above the matched task. If the matched `###` task has a `**Description**:` field, read it — this scopes the task within its parent story and clarifies which acceptance criteria it addresses.
- **Determine task type**: Check the task description for `Type: verification`. If present, this is a story verification gate — the work in step 4 will be acceptance criteria checking, not implementation. If absent, this is a normal implementation task.
- If no epic doc is available, proceed without epic doc integration — the task still gets done.

### 2. Update Status to In Progress

- Call `TaskUpdate` to set the task status to `in_progress`.
- If epic doc integration is active, use the Edit tool to update the matched entry's status. The entry may be a `##` story or a `###` task — locate the correct `**Status**: Pending` field near the matched heading:
  - `old_string`: `**Status**: Pending` (scoped near the matched heading)
  - `new_string`: `**Status**: In Progress`

### 3. Plan (when warranted)

Before jumping into implementation, assess whether this task warrants entering plan mode (`EnterPlanMode`). Use plan mode when any of these apply:

- **Complex**: The task touches multiple files, requires architectural decisions, or has several moving parts
- **Critical**: The task is core infrastructure that other tasks depend on
- **Sensitive**: The task involves personal data, financial data, authentication, or other security-sensitive areas

Skip plan mode for straightforward tasks — config changes, documentation updates, simple additions to existing patterns.

When using plan mode: explore the codebase, design the approach, and get user approval before writing any code. Then exit plan mode and proceed to step 4.

### 4. Do the Work

**If this is a verification gate** (`Type: verification` in the task description): Do not implement anything. Instead, read the parent story's acceptance criteria from the epic doc and verify each criterion against the current state of the codebase. Check files, run tests, or inspect outputs as needed to confirm each criterion is met. Proceed to step 5 with your assessment.

**If this is an implementation task** (no `Type: verification`): Execute the task as described. This is the actual implementation — writing code, creating files, running commands, whatever the task requires. Read the full task description and the parent story's acceptance criteria to understand the broader context. Work until the task is complete.

### 5. Verify Acceptance Criteria

Before marking the task complete:

- Re-read the acceptance criteria from the epic doc (or from the task description if no epic doc).
- Self-assess each criterion. For each one, determine whether it's been met.
- If all criteria are met, proceed to step 6.
- If any criteria are **not** met, flag them to the user. List what's unmet and ask whether to continue working on them or mark the task as done anyway. Use AskUserQuestion for this gate.

### 6. Complete and Update State

This step combines task completion, observation capture, and progress file update into a single operation. Do all three parts before moving to the next task.

**Part A — Mark complete**:
- If epic doc integration is active, use the Edit tool to update the matched entry's status (whether `##` story or `###` task):
  - `old_string`: `**Status**: In Progress` (scoped near the matched heading)
  - `new_string`: `**Status**: Complete`
- Call `TaskUpdate` to set the task status to `completed`.

**Part B — Capture observations (retro)**:
Self-assess whether anything **noteworthy** happened during this task. Only record an observation when something surprising, unexpected, or valuable was learned. Most tasks will have nothing to record, and that's fine.

Ask yourself: "Did anything happen during this task that would change how I'd plan similar work in the future?" If no, skip Part B.

Observation categories (use exactly one per observation):
- **Scope surprise**: The task was larger or smaller than the story suggested
- **Criteria gap**: Acceptance criteria missed something important that only became clear during implementation
- **Complexity underestimate**: The implementation was harder than expected due to technical factors
- **Codebase discovery**: Found something unexpected in the codebase (pattern, convention, limitation) that affected the work

If noteworthy, use the Edit tool to append a `**Retro**:` field to the completed story in the epic doc, immediately after the last existing field for that story (before the `---` separator). Format: `**Retro**: [{category}] {One-sentence observation}`

**Part C — Update progress file**:
Write the full `.cpm-progress.md` file using the Write tool (see State Management below for format). The file must reflect:
- The task just completed (added to Completed Tasks section)
- The next action (which task to pick up next, or "work loop complete")
- The current tasks remaining count

This is the primary compaction resilience mechanism. If compaction fires between tasks, this file is what gets re-injected to restore context.

### 7. Next Task

- Run the **Story Hydration** gating check: call `TaskList`. If no pending unblocked tasks exist, hydrate the next unblocked story from the epic doc (see Story Hydration above). This handles story-to-story transitions automatically.
- After hydration (or if tasks already existed), pick the next lowest-ID task that is `pending` and has no unresolved `blockedBy`.
- If one exists, go back to step 1 (Load Context) for the new task.
- If none exist (and hydration found no unblocked stories), the work loop is done — proceed to step 8.

### 8. Batch Summary (Loop Completion)

When the work loop finishes (no more pending unblocked tasks):

1. **Check for observations**: Read the epic doc and scan for any `**Retro**:` fields across all completed stories. If none exist, skip the rest of this step — no lessons section needed.

2. **Synthesise lessons**: If observations were captured, append a `## Lessons` section to the end of the epic doc using the Edit tool. Group observations by category:

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

3. **Report and stop**: Report a summary of what was completed across the work loop, and delete the progress file.

## Graceful Degradation

The skill should work even without an epic doc:

- **No epic doc resolved during Input**: Skip epic doc reads and status updates. Still do the work, still verify acceptance criteria from the task description.
- **Epic doc file doesn't exist or was deleted mid-loop**: Same — skip epic doc integration, work on the task directly.
- **Story heading not found in epic doc**: Log a note, skip status updates for that story, continue with the work.

## State Management

Maintain `docs/plans/.cpm-progress.md` throughout the work loop for compaction resilience. This allows seamless continuation if context compaction fires mid-loop.

**Create** the file before starting the first task. **Update** it after each task completes. **Delete** it only after all output artifacts (epic doc updates, batch summary) have been confirmed written — never before. If compaction fires between deletion and a pending write, all session state is lost.

Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale). Format:

```markdown
# CPM Session State

**Skill**: cpm:do
**Current task**: {task ID} — {task subject}
**Epic doc**: {path to epic doc, or "none"}
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
