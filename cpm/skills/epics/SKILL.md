---
name: cpm:epics
description: Break a spec into epic documents with stories and tasks. Reads a specification and produces multiple epic docs, each containing stories with sub-tasks. Triggers on "/cpm:epics".
---

# Work Breakdown into Epics

Turn a specification into a set of **epic documents** — each representing a major work area containing **stories** (meaningful deliverables with acceptance criteria) and **tasks** (implementation steps). Epic documents are the plan of record — task creation in Claude Code's native system happens later during execution via `cpm:do`.

## Input

Check for input in this order:

1. If `$ARGUMENTS` references a file path, read that file as the source.
2. If `$ARGUMENTS` contains a description, use that as the source.
3. Look for planning docs — check `docs/specifications/` first, then `docs/plans/`.
4. If nothing found, ask the user what work they want to break down.

## Process

**State tracking**: Before starting Step 1, create the progress file (see State Management below). Each step below ends with a mandatory progress file update — do not skip it. After saving the final epic docs, delete the file.

### Library Check (Startup)

Before Step 1, check the project library for reference documents:

1. **Glob** `docs/library/*.md`. If no files found or directory doesn't exist, skip silently and proceed to Step 1.
2. **Read front-matter** of each file found (the YAML block between `---` delimiters, typically the first ~10 lines). Filter to documents whose `scope` array includes `epics` or `all`.
3. **Report to user**: "Found {N} library documents relevant to work breakdown: {titles}. I'll reference these as context." If none match the scope filter, skip silently.
4. **Deep-read selectively** during epic breakdown when a library document's content is relevant — e.g. reading architecture docs to inform epic grouping or dependency identification.

**Graceful degradation**: If any library document has malformed or missing front-matter, fall back to using the filename as context. Never block the epics process due to a malformed library document.

**Compaction resilience**: Include library scan results (files found, scope matches) in the progress file so post-compaction continuation doesn't re-scan.

### Step 1: Read Source

Read and understand the source document. Summarise the key work areas to the user.

**Update progress file now** — write the full `.cpm-progress.md` with Step 1 summary before continuing.

### Step 2: Identify Epics

Analyse the source to identify major work areas. Each epic will become its own document at `docs/epics/{nn}-epic-{slug}.md`.

For each epic, determine:
- **Name**: A concise label for the work area (e.g. "Authentication System", "API Layer")
- **Number** (`{nn}`): Zero-padded sequential number starting at `01`. Use the Glob tool to list existing `docs/epics/[0-9]*-epic-*.md` files, find the highest number, and continue from there. If none exist, start at `01`.
- **Slug** (`{slug}`): Kebab-case derived from the epic name (e.g. "authentication-system", "api-layer")
- **Summary**: One-sentence description of what this epic covers

Present the epic grouping to the user with AskUserQuestion and refine. Include the proposed filenames so the user can see the full output plan.

Keep epics practical:
- 2-5 epics for a small feature
- 5-10 for a larger project
- Don't create epics for the sake of it

**Production loop**: After epics are confirmed, Steps 3 and 3b iterate per epic — break each epic into stories, then each story into tasks, before moving to the next epic. Save each epic document after its stories and tasks are finalised (before moving to the next epic). This means epic docs are written incrementally, not all at once at the end.

**Update progress file now** — write the full `.cpm-progress.md` with Step 2 summary (epic names, numbers, slugs, and output paths) before continuing.

### Step 3: Break into Stories

For each epic, break into **stories** — meaningful deliverables that represent a coherent unit of value. A story answers "what are we delivering?" not "what file are we editing?"

Each story should have:
- A clear, actionable title (imperative form: "Set up compaction hook infrastructure")
- Acceptance criteria that describe the deliverable outcome
- An activeForm for progress display (present continuous: "Setting up compaction hook infrastructure")

**Stories vs tasks**: A story groups related implementation work under a single deliverable with shared acceptance criteria. If you find yourself writing a story title that describes a single file change or a single function — that's a task, not a story. Push it down to Step 3b.

Present the stories for each epic to the user using AskUserQuestion. Refine before moving to the next epic.

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

### Step 4: Confirm

Present the full task tree to the user showing:
- All epics with their stories and tasks (using story numbers and task dot-notation)
- Dependencies between epics (cross-epic) and between stories (cross-story)
- Suggested implementation order

Use AskUserQuestion for final confirmation.

## Output

Save each epic document to `docs/epics/{nn}-epic-{slug}.md`. Create the `docs/epics/` directory if it doesn't exist.

- `{nn}` is the zero-padded number assigned during Step 2.
- `{slug}` is the kebab-case name derived from the epic name.

```markdown
# {Epic Name}

**Source spec**: {path to spec}
**Date**: {today's date}
**Status**: Pending
**Blocked by**: —

## {Story Title}
**Story**: {N}
**Status**: Pending
**Blocked by**: —

**Acceptance Criteria**:
- {criterion}
- {criterion}

### {Task Title}
**Task**: {N.1}
**Description**: {One-sentence scope within parent story — which acceptance criteria or concern this task addresses}
**Status**: Pending

### {Task Title}
**Task**: {N.2}
**Description**: {One-sentence scope within parent story — which acceptance criteria or concern this task addresses}
**Status**: Pending

---
```

**Epic-level metadata**:
- `**Source spec**`: Back-reference to the specification that produced this epic. Enables traceability from implementation back to requirements.
- `**Status**`: Derived from stories — `Pending` when no stories are started, `In Progress` when any story is in progress, `Complete` when all stories are complete.
- `**Blocked by**`: Cross-epic dependency. References another epic by its filename slug (e.g. `Epic 01-epic-setup`). Leave as `—` when the epic has no upstream dependencies. Multiple dependencies are comma-separated (e.g. `Epic 01-epic-setup, Epic 02-epic-data-model`).

**Story numbers** are sequential per epic document, starting at 1. They provide stable references within the doc that don't depend on Claude Code's task system. The `**Blocked by**` field on stories references story numbers for intra-epic deps (e.g. `Story 1` or `Story 1, Story 2`).

**Task numbers** use dot notation: `{story number}.{task sequence}`. Task 1.1 is the first task of Story 1, Task 2.3 is the third task of Story 2.

After saving each epic doc, tell the user the document path so they can reference it later.

When starting implementation of a task, read the relevant epic document first to understand the full context: all stories, tasks, dependencies, acceptance criteria, and where the current task fits in the broader plan.

## State Management

Maintain `docs/plans/.cpm-progress.md` throughout the session for compaction resilience. This allows seamless continuation if context compaction fires mid-conversation.

**Path resolution**: All paths in this skill are relative to the current Claude Code session's working directory. When calling Write, Glob, Read, or any file tool, construct the absolute path by prepending the session's primary working directory. Never write to a different project's directory or reuse paths from other sessions.

**Create** the file before starting Step 1 (ensure `docs/plans/` exists). **Update** it after each step completes. **Delete** it only after the final epic documents have been saved and confirmed written — never before. If compaction fires between deletion and a pending write, all session state is lost.

Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale). Format:

```markdown
# CPM Session State

**Skill**: cpm:epics
**Step**: {N} of 4 — {Step Name}
**Input source**: {path to spec or brief used as input}

## Epic Files

| # | Slug | Path | Status |
|---|------|------|--------|
| 01 | {slug} | docs/epics/01-epic-{slug}.md | {Pending/Written} |
| 02 | {slug} | docs/epics/02-epic-{slug}.md | {Pending/Written} |

## Completed Steps

### Step 1: Read Source
{Concise summary — what document was read, key work areas identified}

### Step 2: Identify Epics
{Epic names, numbers, slugs, and output paths as confirmed by user}

### Step 3: Break into Stories
{List of stories per epic — titles and acceptance criteria summaries}

### Step 3b: Identify Tasks within Stories
{List of tasks per story — titles and dot-notation numbers}

{...include only completed steps...}

## Next Action
{What to ask or do next in the facilitation}
```

The "Epic Files" table tracks which epic documents have been written. Mark each as "Written" after saving it during the production loop in Steps 3/3b. This enables post-compaction recovery to know which files exist and which still need to be produced.

The "Completed Steps" section grows as steps complete. Epic state is more structured than other skills because it accumulates concrete artifacts — epic names, story titles, task titles, and dependency declarations that must survive compaction for the remaining steps to work.

The "Next Action" field tells the post-compaction context exactly where to pick up.

## Guidelines

- **Epics are work areas, stories are deliverables, tasks are steps.** An epic represents a major area of work ("Authentication System"). Stories within it represent meaningful outcomes ("Set up OAuth provider integration"). Tasks are the implementation work to get there ("Create OAuth callback handler", "Write token refresh logic"). If an epic has only one story, it's probably not an epic.
- **Right-sized stories.** Each story should be completable in a focused session. Not too big (vague multi-day effort), not too small (a single trivial change). A story with 2-5 tasks is typical.
- **Acceptance criteria live on stories.** Tasks don't have their own acceptance criteria — they inherit meaning from their parent story. The story is done when its acceptance criteria pass, not necessarily when every task checkbox is ticked.
- **Don't over-decompose tasks.** Not every story needs multiple tasks. If the work is straightforward, one task is fine. The value of task-level breakdown is making complex stories manageable, not adding bureaucracy to simple ones.
- **Dependencies between stories or epics, not tasks.** Use `**Blocked by**: Story N` for intra-epic story dependencies. Use `**Blocked by**: Epic {nn}-epic-{slug}` for cross-epic dependencies. Don't create cross-story task dependencies — if tasks in different stories are interdependent, the stories themselves should have the dependency.
- **One epic, one document.** Each epic produces its own markdown file. This keeps documents focused and allows parallel work on independent epics.
- **Facilitate the grouping.** The user knows their domain better than you. Present a suggested structure and let them reshape it.
