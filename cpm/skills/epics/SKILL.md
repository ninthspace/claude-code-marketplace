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

### Template Hint (Startup)

After startup checks and before Step 1, display:

> Output format is fixed (used by downstream skills). Run `/cpm:templates preview epics` to see the format.

### ADR Discovery (Startup)

After the Template Hint and before Step 1, discover existing Architecture Decision Records:

1. **Glob** `docs/architecture/[0-9]*-adr-*.md`. If no files found or directory doesn't exist, skip silently.
2. If ADRs exist, read each one and note the architectural decisions and their dependencies. Report to the user: "Found {N} existing ADRs: {titles}. I'll reference these when breaking down architectural work into epics and stories."
3. During Step 2 (Identify Epics) and Step 3 (Break into Stories), use ADR context to inform epic grouping — e.g. if an ADR identifies separate concerns or bounded contexts, these may map naturally to epics. Reference specific ADRs in story descriptions when they constrain or inform the implementation approach.

**Graceful degradation**: If ADRs don't exist, epic breakdown works as before — deriving structure purely from the spec. The skill must work without `cpm:architect` having been run.

### Step 1: Read Source

Read and understand the source document. Summarise the key work areas to the user.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Step 1 summary before continuing.

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

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Step 2 summary (epic names, numbers, slugs, and output paths) before continuing.

### Step 3: Break into Stories

For each epic, break into **stories** — meaningful deliverables that represent a coherent unit of value. A story answers "what are we delivering?" not "what file are we editing?"

Each story should have:
- A clear, actionable title (imperative form: "Set up compaction hook infrastructure")
- Acceptance criteria that describe the deliverable outcome
- An activeForm for progress display (present continuous: "Setting up compaction hook infrastructure")
- **Spec traceability** (when input is a spec): Which functional requirements from the spec this story satisfies. Use the requirement text or a short label. This enables verification that the spec is fully covered across all epics — every must-have requirement should appear in at least one story.

**Test approach tag propagation** (when the input spec has a Testing Strategy section with tagged criteria):

1. Read the spec's Testing Strategy section — specifically the Acceptance Criteria Coverage table which maps requirements to criteria with `[tag]` annotations.
2. When writing story acceptance criteria, apply matching tags inline. For each acceptance criterion, append the appropriate tags from the spec's testing strategy: `[unit]`, `[integration]`, `[feature]`, `[manual]`, and `[tdd]`. Match by tracing the story's `**Satisfies**` field back to the spec requirement, then looking up that requirement's tag assignments. The `[tdd]` tag is a workflow mode tag (orthogonal to level tags) — propagate it alongside any level tag when present (e.g. `[tdd] [unit]`).
3. If a story's criteria don't map directly to a spec requirement's tagged criteria (e.g. the story introduces new criteria beyond the spec), propose a tag based on the criterion's nature and confirm with the user.
4. Tags appear at the end of the acceptance criteria line, e.g.: `- User can log in via OAuth [integration]` or `- Payment processor validates card [tdd] [integration]`

**Graceful degradation**: If the spec has no Testing Strategy section, no Acceptance Criteria Coverage table, or no tags, skip tag propagation entirely — write acceptance criteria without tags. The skill must work without `cpm:spec`'s enhanced Section 6 having been used.

**Stories vs tasks**: A story groups related implementation work under a single deliverable with shared acceptance criteria. If you find yourself writing a story title that describes a single file change or a single function — that's a task, not a story. Push it down to Step 3b.

Present the stories for each epic to the user using AskUserQuestion. Refine before moving to the next epic.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Step 3 summary (including which tags were propagated to which stories) before continuing.

### Step 3b: Identify Tasks within Stories

For each story, identify the **tasks** — concrete implementation steps needed to deliver the story. Each task should have:
- A clear, actionable title (imperative form: "Create hooks.json configuration")
- A dot-notation number linking it to its parent story (e.g. Task 1.1, 1.2, 1.3 for Story 1)
- An optional one-sentence **description** that scopes the task within its parent story — clarifying which acceptance criteria or concern the task addresses

**Task descriptions**: Descriptions help implementers understand task scope without a three-hop lookup (title → story criteria → spec), especially after context compaction or in a new session. Write a description when the task's scope isn't obvious from the title alone — e.g. when a story has multiple tasks that divide its acceptance criteria between them. Omit the description when the title is self-evident, such as single-task stories or tasks with unambiguous titles. This is a judgement call, not a mandatory field.

Tasks are the actual work items. They should be specific enough that an implementer knows exactly what to do.

Not every story needs multiple tasks. If a story is straightforward enough to be done in one step, a single task is fine. Don't decompose for the sake of it.

**Auto-generated testing tasks**: After identifying implementation tasks for a story, check whether any of the story's acceptance criteria carry `[unit]`, `[integration]`, or `[feature]` tags. If at least one automated test tag is present:

1. Auto-generate a testing task titled "Write tests for {story title}".
2. **Placement depends on `[tdd]`**:
   - If the story's acceptance criteria include `[tdd]`, place the testing task **before** all implementation tasks (as the first task in the story). This enables the TDD red-green-refactor workflow — tests are written first, then implementation makes them pass. The testing task gets dot-notation number `{story}.1`, and implementation tasks follow sequentially.
   - If the story does **not** carry `[tdd]`, place the testing task **after** all implementation tasks (as the last task in the story, before the verification gate that `cpm:do` will create). The testing task's dot-notation number follows the last implementation task (e.g. if implementation tasks are 1.1, 1.2, 1.3, the testing task is 1.4).
3. Give it a description: "Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`."

If **all** of a story's criteria are tagged `[manual]` (or have no tags), do **not** generate a testing task — there's nothing to automate.

**Graceful degradation**: If no tags were propagated during Step 3 (e.g. the spec had no testing strategy), skip testing task generation entirely.

Present the tasks for each story using AskUserQuestion. Refine before moving to the next story.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Step 3b summary before continuing.

### Step 3c: Integration Testing Story (when warranted)

After all implementation stories and their tasks are defined for an epic, assess whether the epic warrants a **dedicated integration testing story**. This is separate from per-story testing tasks (which test a single story's criteria) — an integration testing story verifies cross-story behaviour and integration points.

**When to generate**: Create an integration testing story when the epic has:
- Multiple stories with `[integration]` tagged criteria that interact with each other
- Cross-story data flows, API contracts, or event-driven interactions
- Stories that produce components which must work together as a system

**When to skip**: Skip if the epic has only 1-2 stories, no `[integration]` tags, or stories that are independent of each other.

**How to generate**:
1. Title: "Verify cross-story integration for {epic name}"
2. Story number: the next sequential number after the last implementation story
3. `**Blocked by**`: all implementation stories in the epic (comma-separated)
4. Acceptance criteria: specific cross-story integration points that need verification. These should describe observable behaviour that spans multiple stories — not just "everything works together." Confirm with the user via AskUserQuestion.
5. Tasks: typically a single task — "Write integration tests for {epic name}" — unless the integration points are complex enough to warrant separate tasks.

**Graceful degradation**: If no tags were propagated during Step 3, skip this step entirely.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Step 3c summary (integration story generated or skipped, with rationale) before continuing.

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
**Satisfies**: {spec requirement label(s) this story addresses — omit if no spec input}

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

Maintain `docs/plans/.cpm-progress-{session_id}.md` throughout the session for compaction resilience. This allows seamless continuation if context compaction fires mid-conversation.

**Path resolution**: All paths in this skill are relative to the current Claude Code session's working directory. When calling Write, Glob, Read, or any file tool, construct the absolute path by prepending the session's primary working directory. Never write to a different project's directory or reuse paths from other sessions.

**Session ID**: The `{session_id}` in the filename comes from `CPM_SESSION_ID` — a unique identifier for the current Claude Code session, injected into context by the CPM hooks on startup and after compaction. Use this value verbatim when constructing the progress file path. If `CPM_SESSION_ID` is not present in context (e.g. hooks not installed), fall back to `.cpm-progress.md` (no session suffix) for backwards compatibility.

**Resume adoption**: When a session is resumed (`--resume`), `CPM_SESSION_ID` changes to a new value while the old progress file remains on disk. The hooks inject all existing progress files into context on startup — if one matches this skill's `**Skill**:` field but has a different session ID in its filename, adopt it:
1. Read the old file's contents (already visible in context from hook injection).
2. Write a new file at `docs/plans/.cpm-progress-{current_session_id}.md` with the same contents.
3. After the Write confirms success, delete the old file: `rm docs/plans/.cpm-progress-{old_session_id}.md`.
Do not attempt adoption if `CPM_SESSION_ID` is absent from context — the fallback path handles that case.

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
{List of stories per epic — titles and acceptance criteria summaries. Include tag propagation status:
- Tags propagated from spec: yes/no/skipped (no testing strategy in spec)
- Per-story tags: Story 1 criteria tagged [unit] x2, [integration] x1; Story 2 criteria tagged [manual] x3; etc.}

### Step 3b: Identify Tasks within Stories
{List of tasks per story — titles and dot-notation numbers. Note which stories got auto-generated testing tasks.}

### Step 3c: Integration Testing Story
{Integration testing story generated or skipped, with rationale. If generated: story title, blocked-by list, acceptance criteria summary.}

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
- **Testing tasks are auto-generated, not manually created.** When story criteria carry `[unit]`, `[integration]`, or `[feature]` tags, Step 3b auto-generates a "Write tests" task. Don't add testing tasks manually — the automation ensures consistency. Stories with only `[manual]` criteria get no testing task.
- **`[tdd]` reverses testing task order.** When a story's criteria include `[tdd]`, the auto-generated testing task is placed *before* implementation tasks — enabling the red-green-refactor workflow where tests are written first. Stories without `[tdd]` retain the default order (testing task after implementation). Both modes can coexist in the same epic.
- **Integration testing stories are for cross-story verification.** They're distinct from per-story testing tasks. Only create them when the epic has genuine cross-story integration points — not as a default for every epic.
- **Facilitate the grouping.** The user knows their domain better than you. Present a suggested structure and let them reshape it.
