---
name: cpm:stories
description: Break a plan or spec into tracked work items with dependencies. Reads planning docs and creates stories with sub-tasks in Claude Code's native task system using TaskCreate. Triggers on "/cpm:stories".
---

# Work Breakdown into Stories & Tasks

Turn a plan or spec into a two-level structure: **stories** (meaningful deliverables with acceptance criteria) containing **tasks** (implementation steps). Both levels are tracked in Claude Code's native task system via TaskCreate.

## Input

Check for input in this order:

1. If `$ARGUMENTS` references a file path, read that file as the source.
2. If `$ARGUMENTS` contains a description, use that as the source.
3. Look for planning docs — check `docs/specifications/` first, then `docs/plans/`.
4. If nothing found, ask the user what work they want to break down.

## Process

**State tracking**: Before starting Step 1, create the progress file (see State Management below). Each step below ends with a mandatory progress file update — do not skip it. After saving the final stories doc, delete the file.

### Library Check (Startup)

Before Step 1, check the project library for reference documents:

1. **Glob** `docs/library/*.md`. If no files found or directory doesn't exist, skip silently and proceed to Step 1.
2. **Read front-matter** of each file found (the YAML block between `---` delimiters, typically the first ~10 lines). Filter to documents whose `scope` array includes `stories` or `all`.
3. **Report to user**: "Found {N} library documents relevant to work breakdown: {titles}. I'll reference these as context." If none match the scope filter, skip silently.
4. **Deep-read selectively** during story breakdown when a library document's content is relevant — e.g. reading architecture docs to inform epic grouping or dependency identification.

**Graceful degradation**: If any library document has malformed or missing front-matter, fall back to using the filename as context. Never block the stories process due to a malformed library document.

**Compaction resilience**: Include library scan results (files found, scope matches) in the progress file so post-compaction continuation doesn't re-scan.

### Step 1: Read Source

Read and understand the source document. Summarise the key work areas to the user.

**Update progress file now** — write the full `.cpm-progress.md` with Step 1 summary before continuing.

### Step 2: Identify Epics

Group the work into major areas (epics). Present the grouping to the user with AskUserQuestion and refine.

Keep epics practical:
- 2-5 epics for a small feature
- 5-10 for a larger project
- Don't create epics for the sake of it

**Update progress file now** — write the full `.cpm-progress.md` with Step 2 summary before continuing.

### Step 3: Break into Stories

For each epic, break into **stories** — meaningful deliverables that represent a coherent unit of value. A story answers "what are we delivering?" not "what file are we editing?"

Each story should have:
- A clear, actionable title (imperative form: "Set up compaction hook infrastructure")
- Acceptance criteria that describe the deliverable outcome
- An activeForm for progress display (present continuous: "Setting up compaction hook infrastructure")

**Stories vs tasks**: A story groups related implementation work under a single deliverable with shared acceptance criteria. If you find yourself writing a story title that describes a single file change or a single function — that's a task, not a story. Push it down to Step 3b.

Present the stories to the user for each epic using AskUserQuestion. Refine before moving to the next epic.

**Update progress file now** — write the full `.cpm-progress.md` with Step 3 summary before continuing.

### Step 3b: Identify Tasks within Stories

For each story, identify the **tasks** — concrete implementation steps needed to deliver the story. Each task should have:
- A clear, actionable title (imperative form: "Create hooks.json configuration")
- A dot-notation number linking it to its parent story (e.g. Task 1.1, 1.2, 1.3 for Story 1)
- An optional one-sentence **description** that scopes the task within its parent story — clarifying which acceptance criteria or concern the task addresses

**Task descriptions**: Descriptions help implementers understand task scope without a three-hop lookup (title → story criteria → spec), especially after context compaction or in a new session. Write a description when the task's scope isn't obvious from the title alone — e.g. when a story has multiple tasks that divide its acceptance criteria between them. Omit the description when the title is self-evident, such as single-task stories or tasks with unambiguous titles. This is a judgement call, not a mandatory field.

Tasks are the actual work items. They should be specific enough that an implementer knows exactly what to do.

Not every story needs multiple tasks. If a story is straightforward enough to be done in one step, a single task is fine. Don't decompose for the sake of it.

Present the tasks for each story using AskUserQuestion. Refine before moving to the next story.

**Update progress file now** — write the full `.cpm-progress.md` with Step 3b summary before continuing.

### Step 4: Create Tasks

Use TaskCreate to create all items in Claude Code's native system — both stories (as verification gates) and tasks (as implementation work).

**For each task** (implementation work):
```
TaskCreate:
  subject: "{Task title}"
  description: "{Task description from stories doc}\n\nStories doc: docs/stories/{nn}-story-{slug}.md\nStory: {N}\nTask: {N.M}"
  activeForm: "{Present continuous form}"
```

**For each story** (verification gate):
```
TaskCreate:
  subject: "Verify: {Story title}"
  description: "Verify acceptance criteria for Story {N}: {Story title}\n\n{List the acceptance criteria here}\n\nStories doc: docs/stories/{nn}-story-{slug}.md\nStory: {N}\nType: verification"
  activeForm: "Verifying: {Story title}"
```

**Order of creation**: Create all tasks for a story first, then the story's verification gate. This ensures sub-task IDs exist before the gate needs to reference them.

After creating each item, update the stories doc to record the assigned task ID in the relevant `**Task ID**` field using the Edit tool.

**Update progress file now** — write the full `.cpm-progress.md` with Step 4 summary (complete ID mapping: stories and tasks) before continuing.

### Step 5: Set Dependencies

Use TaskUpdate to set `addBlockedBy` relationships. Apply two rules:

**Rule 1 — Intra-story** (verification gate blocked by its own tasks):
For each story, set its verification gate task as `addBlockedBy` all of its sub-task IDs. This ensures the gate only fires after all implementation work is complete.

```
TaskUpdate(storyGateTaskId, addBlockedBy: [task1Id, task2Id, ...])
```

**Rule 2 — Cross-story** (dependent story's tasks blocked by upstream gate):
For each `**Blocked by**: Story N` declaration in the stories doc, set all sub-tasks of the dependent story as `addBlockedBy` the upstream story's verification gate task ID. This ensures a story's implementation work only begins after the upstream story is fully implemented AND verified.

```
TaskUpdate(eachDependentSubtaskId, addBlockedBy: [upstreamStoryGateTaskId])
```

Common dependency patterns:
- Setup/infrastructure stories block feature stories
- Data model stories block API stories
- Core feature stories block enhancement stories

Only add cross-story dependencies that are genuinely blocking — don't over-constrain the task graph.

**Update progress file now** — write the full `.cpm-progress.md` with Step 5 summary (dependency map) before continuing.

### Step 6: Confirm

Present the full task tree to the user showing:
- All stories and tasks grouped by epic
- Dependencies between stories (cross-story) and within stories (gate blocked by tasks)
- Suggested implementation order

Use AskUserQuestion for final confirmation.

## Output

Save the stories document to `docs/stories/{nn}-story-{slug}.md`. Create the `docs/stories/` directory if it doesn't exist.

- `{nn}` is a zero-padded auto-incrementing number. Use the Glob tool to list existing `docs/stories/[0-9]*-story-*.md` files, find the highest number, and increment by 1. If none exist, start at `01`.
- `{slug}` is derived from the spec or brief name.

```markdown
# Stories: {Title}

**Date**: {today's date}
**Source**: {link to spec or brief}

## Epic: {Epic Name}

### {Story Title}
**Story**: {N}
**Task ID**: —
**Status**: Pending
**Blocked by**: —

**Acceptance Criteria**:
- {criterion}
- {criterion}

#### {Task Title}
**Task**: {N.1}
**Description**: {One-sentence scope within parent story — which acceptance criteria or concern this task addresses}
**Task ID**: —
**Status**: Pending

#### {Task Title}
**Task**: {N.2}
**Description**: {One-sentence scope within parent story — which acceptance criteria or concern this task addresses}
**Task ID**: —
**Status**: Pending

---
```

**Story numbers** are sequential per document, starting at 1. They provide stable references within the doc that don't depend on Claude Code's task system. The `**Blocked by**` field references story numbers (e.g. `Story 1` or `Story 1, Story 2`).

**Task numbers** use dot notation: `{story number}.{task sequence}`. Task 1.1 is the first task of Story 1, Task 2.3 is the third task of Story 2.

The `**Task ID**` field starts as `—` on both stories and tasks, and gets filled in during Step 4 when Claude Code tasks are created. This maps document-level items to runtime tasks.

Always produce both the document and the Claude Code tasks. After saving, tell the user the document path so they can reference it later.

When starting implementation of a task, read the stories document first to understand the full context: all epics, stories, tasks, dependencies, acceptance criteria, and where the current task fits in the broader plan.

## State Management

Maintain `docs/plans/.cpm-progress.md` throughout the session for compaction resilience. This allows seamless continuation if context compaction fires mid-conversation.

**Create** the file before starting Step 1 (ensure `docs/plans/` exists). **Update** it after each step completes. **Delete** it only after the final stories document has been saved and confirmed written — never before. If compaction fires between deletion and a pending write, all session state is lost.

Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale). Format:

```markdown
# CPM Session State

**Skill**: cpm:stories
**Step**: {N} of 6 — {Step Name}
**Output target**: docs/stories/{nn}-story-{slug}.md
**Input source**: {path to spec or brief used as input}

## Completed Steps

### Step 1: Read Source
{Concise summary — what document was read, key work areas identified}

### Step 2: Identify Epics
{Concise summary — epic names and descriptions as confirmed by user}

### Step 3: Break into Stories
{List of stories per epic — titles and acceptance criteria summaries}

### Step 3b: Identify Tasks within Stories
{List of tasks per story — titles and dot-notation numbers}

### Step 4: Create Tasks
{Task IDs created for both stories (verification gates) and tasks (implementation), with mappings}

### Step 5: Set Dependencies
{Dependency map — intra-story (gate blocked by tasks) and cross-story (tasks blocked by upstream gate)}

{...include only completed steps...}

## Next Action
{What to ask or do next in the facilitation}
```

The "Completed Steps" section grows as steps complete. Stories state is more structured than discover/spec because it accumulates concrete artifacts — epic names, story titles, task titles, task IDs, and dependency maps that must survive compaction for the remaining steps to work.

The "Next Action" field tells the post-compaction context exactly where to pick up.

## Guidelines

- **Stories are deliverables, tasks are steps.** A story represents a meaningful outcome ("Set up compaction hooks"). Tasks are the implementation work to get there ("Create hooks.json", "Write pre-compact.sh"). If a story title sounds like a single file edit, it's probably a task.
- **Right-sized stories.** Each story should be completable in a focused session. Not too big (vague multi-day effort), not too small (a single trivial change). A story with 2-5 tasks is typical.
- **Acceptance criteria live on stories.** Tasks don't have their own acceptance criteria — they inherit meaning from their parent story. The story is done when its acceptance criteria pass, not necessarily when every task checkbox is ticked.
- **Don't over-decompose tasks.** Not every story needs multiple tasks. If the work is straightforward, one task is fine. The value of task-level breakdown is making complex stories manageable, not adding bureaucracy to simple ones.
- **Dependencies between stories, not tasks.** Use `**Blocked by**: Story N` to express story-level dependencies. Don't create cross-story task dependencies — if tasks in different stories are interdependent, the stories themselves should have the dependency.
- **Facilitate the grouping.** The user knows their domain better than you. Present a suggested structure and let them reshape it.
