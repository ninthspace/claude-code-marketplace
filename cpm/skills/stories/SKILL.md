---
name: cpm:stories
description: Break a plan or spec into tracked work items with dependencies. Reads planning docs and creates tasks in Claude Code's native task system using TaskCreate. Triggers on "/cpm:stories".
---

# Work Breakdown into Tasks

Turn a plan or spec into trackable work items using Claude Code's native task system (TaskCreate/TaskUpdate).

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

For each epic, break into implementable stories. Each story should have:
- A clear, actionable title (imperative form: "Add user login endpoint")
- A description with acceptance criteria
- An activeForm for progress display (present continuous: "Adding user login endpoint")

Present the stories to the user for each epic using AskUserQuestion. Refine before moving to the next epic.

**Update progress file now** — write the full `.cpm-progress.md` with Step 3 summary before continuing.

### Step 4: Create Tasks

Use TaskCreate to create all tasks in Claude Code's native system.

For each story:
```
TaskCreate:
  subject: "{Story title}"
  description: "{Description with acceptance criteria}\n\nStories doc: docs/stories/{nn}-story-{slug}.md\nStory: {N}"
  activeForm: "{Present continuous form}"
```

Include the path to the stories document and the story number in each task description so it can be found during implementation.

After creating each task, update the stories doc to record the assigned task ID in the `**Task ID**` field using the Edit tool. This maps document-level stories to runtime tasks.

**Update progress file now** — write the full `.cpm-progress.md` with Step 4 summary (story-to-task-ID mapping) before continuing.

### Step 5: Set Dependencies

Use TaskUpdate to set `addBlockedBy` relationships where tasks depend on others completing first. Map the story-level `**Blocked by**` references (e.g. `Story 1`) to the corresponding task IDs using the mapping from Step 4.

Common dependency patterns:
- Setup/infrastructure tasks block feature tasks
- Data model tasks block API tasks
- API tasks block UI tasks
- Core features block enhancement features

Only add dependencies that are genuinely blocking — don't over-constrain the task graph.

**Update progress file now** — write the full `.cpm-progress.md` with Step 5 summary (dependency map) before continuing.

### Step 6: Confirm

Present the full task tree to the user showing:
- All tasks grouped by epic
- Dependencies between tasks
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

---
```

Story numbers are sequential per document, starting at 1. They provide stable references within the doc that don't depend on Claude Code's task system. The `**Blocked by**` field references story numbers (e.g. `Story 1` or `Story 1, Story 2`).

The `**Task ID**` field starts as `—` and gets filled in during Step 4 when Claude Code tasks are created. This maps the document-level story to the runtime task.

Always produce both the document and the Claude Code tasks. After saving, tell the user the document path so they can reference it later.

When starting implementation of a task, read the stories document first to understand the full context: all epics, dependencies, acceptance criteria, and where the current task fits in the broader plan.

## State Management

Maintain `docs/plans/.cpm-progress.md` throughout the session for compaction resilience. This allows seamless continuation if context compaction fires mid-conversation.

**Create** the file before starting Step 1 (ensure `docs/plans/` exists). **Update** it after each step completes. **Delete** it after saving the final stories document.

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
{List of stories per epic — titles and brief descriptions}

### Step 4: Create Tasks
{Task IDs created and their corresponding story titles}

### Step 5: Set Dependencies
{Dependency map — which tasks block which}

{...include only completed steps...}

## Next Action
{What to ask or do next in the facilitation}
```

The "Completed Steps" section grows as steps complete. Stories state is more structured than discover/spec because it accumulates concrete artifacts — epic names, story titles, task IDs, and dependency maps that must survive compaction for the remaining steps to work.

The "Next Action" field tells the post-compaction context exactly where to pick up.

## Guidelines

- **Right-sized stories.** Each story should be completable in a single focused session. Not too big (vague), not too small (trivial).
- **Acceptance criteria matter.** Each story needs clear criteria so you know when it's done.
- **Don't over-decompose.** If a story is straightforward, it doesn't need sub-tasks. If it's complex, break it down further.
- **Dependencies should be minimal.** Prefer independent stories that can be worked in any order. Only add blockedBy where there's a genuine technical dependency.
- **Facilitate the grouping.** The user knows their domain better than you. Present a suggested structure and let them reshape it.
