---
name: cpm2:epics
description: Break a spec into epic documents with stories and tasks. Reads a specification and produces multiple epic docs, each containing stories with sub-tasks. Triggers on "/cpm2:epics".
---

# Work Breakdown into Epics

Turn a specification into a set of **epic documents** — each representing a major work area containing **stories** (meaningful deliverables with acceptance criteria) and **tasks** (implementation steps). Epic documents are the plan of record — task creation in Claude Code's native system happens later during execution via `cpm2:do`.

## Input

Check for input in this order:

1. If `$ARGUMENTS` references a file path, read that file as the source.
2. If `$ARGUMENTS` contains a description, use that as the source.
3. Look for planning docs — check `docs/specifications/` first, then `docs/plans/`.
4. If nothing found, ask the user what work they want to break down.

## Process

**State tracking**: Create the progress file before Step 1 and update it after each step completes. See State Management below for the format and rationale. Delete the file once the final epic docs have been saved.

### Termination

- **Success**: The user confirms the final task tree in Step 4 — save the epic documents and finish.
- **Blocker**: The user identifies a spec gap, missing requirement, or dependency that cannot be resolved in this session. Note the gap, save the epic documents with what's confirmed, and flag the gap for resolution via `cpm2:pivot` or a spec update.
- **Ambiguity**: The user is uncertain about epic grouping, story scope, or task breakdown after one clarification round. Present a recommended structure with rationale. If the user still cannot decide, use the recommended default and note the decision as provisional — it can be revised before `cpm2:do` begins execution.

**Facilitation depth**: Each presentation-and-refine gate (Step 2 epics, Step 3 stories, Step 3b tasks) converges in 1-2 rounds of AskUserQuestion. When the user approves, move on. Step 3d coverage matrix and Step 4 confirmation are single-pass gates — present once, refine once if needed, then proceed.

### Library Check (Startup)

Follow the shared **Library Check** procedure with scope keyword `epics`. Deep-read selectively during Step 2 epic grouping when architecture or coding-standards docs affect epic boundaries or dependency identification.

### Template Hint (Startup)

After startup checks and before Step 1, display:

> Output format is fixed (used by downstream skills). Run `/cpm2:templates preview epics` to see the format.

### ADR Discovery (Startup)

After the Template Hint and before Step 1, discover existing Architecture Decision Records:

1. **Glob** `docs/architecture/[0-9]*-adr-*.md`. If no files found or directory doesn't exist, skip silently.
2. If ADRs exist, read each one and note the architectural decisions and their dependencies. Report to the user: "Found {N} existing ADRs: {titles}. I'll reference these when breaking down architectural work into epics and stories."
3. During Step 2 (Identify Epics) and Step 3 (Break into Stories), use ADR context to inform epic grouping — e.g. if an ADR identifies separate concerns or bounded contexts, these may map naturally to epics. Reference specific ADRs in story descriptions when they constrain or inform the implementation approach.

**Graceful degradation**: If ADRs are absent, epic breakdown works as before — deriving structure purely from the spec. The skill works with or without `cpm2:architect` having been run.

### Step 1: Read Source

Read and understand the source document. Summarise the key work areas to the user.

### Step 2: Identify Epics

Analyse the source to identify major work areas. Each epic will become its own document at `docs/epics/{parent}-{seq}-epic-{slug}.md`. See the **Epic Filename Convention** subsection below for the parent-extraction and sub-number rules.

For each epic, determine:
- **Name**: A concise label for the work area (e.g. "Authentication System", "API Layer")
- **Filename prefix** (`{parent}-{seq}`): Assigned per the **Epic Filename Convention** subsection below — `{parent}` comes from the source spec number (or `00` for orphans), `{seq}` increments within that parent.
- **Slug** (`{slug}`): Kebab-case derived from the epic name (e.g. "authentication-system", "api-layer")
- **Summary**: One-sentence description of what this epic covers

Present the epic grouping to the user with AskUserQuestion and refine. Include the proposed filenames so the user can see the full output plan.

Keep epics practical:
- 2-5 epics for a small feature
- 5-10 for a larger project
- Only create an epic when the work genuinely warrants one

### Epic Filename Convention

Epic documents use a **two-part numeric prefix**: `{parent}-{seq}-epic-{slug}.md`. This makes the parent spec discoverable at the filename level — a reader scanning `ls docs/epics/` can identify an epic's source without opening the file.

> **Transition note**: Epics created before the numbering update used flat `{nn}-epic-{slug}.md`. New epics use parent-scoped `{parent}-{seq}-epic-{slug}.md`. Both shapes coexist permanently — old epics are not migrated. Readers must handle both shapes; writers produce only the two-part shape.

**Parent extraction**:

- **Spec-linked epics** (the default — input is a spec): `{parent}` is the numeric prefix of the source spec's filename. For example, input `docs/specifications/28-spec-foo.md` yields `{parent} = 28`, producing `28-01-epic-foo.md`, `28-02-epic-bar.md`, and so on.
- **Orphan epics** (input is a brief, discussion, description, or bare prompt — no parent spec): `{parent}` is the literal string `00`. Orphan epics are written as `00-{seq}-epic-{slug}.md`. Every new epic produced by this skill uses the two-part shape.

**Sub-number assignment** (`{seq}`):

Assign `{seq}` per parent using the shared Numbering procedure — glob both `docs/epics/{parent}-[0-9]*-epic-*.md` and `docs/archive/epics/{parent}-[0-9]*-epic-*.md`, extract the second numeric field from each match, parse as integer (always integer comparison, never lexical), take `max + 1` across the union. If both sets are empty, start at `01`. Format using the shared Numbering width rule. Flat-shape files (e.g. `15-epic-consult-skill-core.md`) are naturally excluded from the scoped glob.

Sub-numbers are **identifiers**, not ordinals — gaps from deleted sub-numbers are preserved (the max-lookup skips them), keeping cross-references stable.

**General epic listings**: Operations that enumerate *all* epics (for dependency resolution, batch status checks, cross-epic references) must use the general glob `docs/epics/[0-9]*-epic-*.md`, which matches both flat and two-part shapes. Only the sub-number assignment above uses the scoped glob. Always use the general glob for listings — narrowing to the two-part shape would hide legacy epics from readers.

**Production loop**: After epics are confirmed, Steps 3, 3b, 3c, and 3d iterate per epic — break each epic into stories, then tasks, then assess integration testing, then verify requirement coverage. Save each epic document and its coverage matrix after they are finalised (before moving to the next epic). This means epic docs are written incrementally, not all at once at the end.

*Progress note: capture epic names, numbers, slugs, and output paths in the Step 2 summary.*

### Step 3: Break into Stories

For each epic, break into **stories** — meaningful deliverables that represent a coherent unit of value. A story answers "what are we delivering?" not "what file are we editing?"

Each story should have:
- A clear, actionable title (imperative form: "Set up compaction hook infrastructure")
- Acceptance criteria that describe the deliverable outcome
- An activeForm for progress display (present continuous: "Setting up compaction hook infrastructure")
- **Spec traceability** (when input is a spec): Which functional requirements from the spec this story satisfies. Use the requirement text or a short label. This enables verification that the spec is fully covered across all epics — every must-have requirement should appear in at least one story.

**Acceptance criteria fidelity** (when input is a spec): When deriving acceptance criteria from a spec, use the spec's language verbatim where it provides specific thresholds, values, or behaviours. Use the spec's language verbatim — preserve thresholds, values, and behaviours exactly. If the spec says "concurrent session limit of 3 per user", the story criterion says "concurrent session limit of 3 per user". The spec's specificity must survive intact into the stories.

**Testability standard**: Each acceptance criterion must be **testable as written** — it describes a specific, observable, verifiable outcome. Flag any criterion that relies on subjective judgement or cannot be verified through code, tests, or inspection. Criteria that fail this standard must be rewritten before the story is finalised.

Examples:
- **Fails**: "Users can log in" — no observable outcome defined
- **Passes**: "User with valid credentials receives a 200 response with a session token and is redirected to /dashboard"
- **Fails**: "Error handling works correctly" — subjective and unverifiable
- **Passes**: "Invalid OAuth token returns 401 with error body `{\"error\": \"invalid_token\"}` and no session is created"

**Test approach tag propagation** (when the input spec has a Testing Strategy section with tagged criteria):

1. Read the spec's Testing Strategy section — specifically the Acceptance Criteria Coverage table which maps requirements to criteria with `[tag]` annotations.
2. When writing story acceptance criteria, apply matching tags inline. For each acceptance criterion, append the appropriate tags from the spec's testing strategy: `[unit]`, `[integration]`, `[feature]`, `[manual]`, and `[tdd]`. Match by tracing the story's `**Satisfies**` field back to the spec requirement, then looking up that requirement's tag assignments. The `[tdd]` tag is a workflow mode tag (orthogonal to level tags) — propagate it alongside any level tag when present (e.g. `[tdd] [unit]`).
3. If a story's criteria go beyond a spec requirement's tagged criteria (e.g. the story introduces new criteria beyond the spec), propose a tag based on the criterion's nature and confirm with the user.
4. Tags appear at the end of the acceptance criteria line, e.g.: `- User can log in via OAuth [integration]` or `- Payment processor validates card [tdd] [integration]`

**Graceful degradation**: If the spec has no Testing Strategy section, no Acceptance Criteria Coverage table, or no tags, skip tag propagation entirely — write acceptance criteria without tags. The skill must work without `cpm2:spec`'s enhanced Section 6 having been used.

**Must-NOT clause propagation** (when the input spec has `must NOT` lines from Section 6b):

1. Read the spec's Acceptance Criteria Coverage table for `must NOT` lines paired with positive criteria.
2. When writing story acceptance criteria, include the `must NOT` lines alongside their paired positive criteria. Preserve the spec's wording verbatim — these are defensive boundaries, not suggestions.
3. If a story's criteria go beyond the spec (new criteria without spec-originating must-NOTs), assess whether must-NOT clauses are warranted based on the story's domain (see below).

**Must-NOT clause suggestion** (when the spec has no must-NOT lines, or for criteria without them):

When a story touches any of these domains, propose `must NOT` clauses for the user to confirm:
- **Security**: authentication, authorization, session management, credential handling
- **Data integrity**: database writes, financial calculations, user data mutations
- **External systems**: API calls, webhook handling, third-party integrations

Propose 1-2 must-NOT clauses per relevant criterion. Present them via AskUserQuestion alongside the story's acceptance criteria for the user to accept, modify, or reject. If the user rejects all proposed must-NOTs, proceed without them — must-NOT clauses are advisory, not mandatory.

**Graceful degradation**: If the spec has no must-NOT lines and the story does not touch security, data integrity, or external systems, skip must-NOT suggestion entirely.

**`[plan]` tag suggestion**: After defining a story's acceptance criteria, assess whether it warrants formal plan mode during execution. The `[plan]` tag forces an EnterPlanMode pause before implementation — it's a workflow lock, not a signal that the story is hard. Append `[plan]` to the story's `##` heading (e.g. `## Set up OAuth provider integration [plan]`) when the story involves:

- **Data model changes**: New or modified database schemas, entity relationships, or data structures that affect persistence
- **API contract changes**: New or modified public APIs, webhook schemas, or inter-service contracts where the design needs upfront agreement
- **Cross-system integration**: Coordination across multiple external systems, APIs, or services where the interaction design needs upfront thought

These are the default assignment categories. The user can also add `[plan]` manually to any story they want gated — these categories are defaults, not restrictions. Stories that follow existing patterns, are fully specified by their acceptance criteria, or are straightforward config/documentation changes use inline planning (the default in `cpm2:do`).

**Stories vs tasks**: A story groups related implementation work under a single deliverable with shared acceptance criteria. If you find yourself writing a story title that describes a single file change or a single function — that's a task, not a story. Push it down to Step 3b.

Present the stories for each epic to the user using AskUserQuestion. Refine before moving to the next epic.

*Progress note: record which tags were propagated to which stories in the Step 3 summary.*

### Step 3b: Identify Tasks within Stories

For each story, identify the **tasks** — concrete implementation steps needed to deliver the story. Each task should have:
- A clear, actionable title (imperative form: "Create hooks.json configuration")
- A dot-notation number linking it to its parent story (e.g. Task 1.1, 1.2, 1.3 for Story 1)
- A one-sentence **description** that scopes the task within its parent story — which acceptance criteria or concern this task addresses

**Task descriptions**: Write a description for every task in stories with multiple tasks. Descriptions eliminate the three-hop lookup (title → story criteria → spec) by anchoring each task to the acceptance criteria it addresses — e.g. "Covers the error handling criteria for roster loading" or "Produces the interface that Task 2.3 consumes." For single-task stories, omit the description when the title is self-evident — but when in doubt, write one.

Descriptions should state **scope boundaries**, not implementation steps. Good descriptions reference criteria, relationships, or constraints; bad descriptions prescribe how to build it.

- Good: "Add roster loading section — project override (`docs/agents/roster.yaml`) then plugin default (`../../agents/roster.yaml`), error if neither found. Present selected agent to the user."
- Good: "Addresses the error handling path, not the happy path — covers criteria 3 and 4."
- Bad: "Edit SKILL.md line 45 to add a YAML parsing block with error handling."
- Bad: "Create a function called loadRoster() that reads the file and returns an array."

Tasks are the actual work items. They should be specific enough that an implementer knows exactly what to do.

A single task per story is fine when the work is straightforward. Decompose only when it makes complex stories manageable.

**Auto-generated testing tasks**: After identifying implementation tasks for a story, check whether any of the story's acceptance criteria carry `[unit]`, `[integration]`, or `[feature]` tags. If at least one automated test tag is present:

1. Auto-generate a testing task titled "Write tests for {story title}".
2. **Placement depends on `[tdd]`**:
   - If the story's acceptance criteria include `[tdd]`, place the testing task **before** all implementation tasks (as the first task in the story). This enables the TDD red-green-refactor workflow — tests are written first, then implementation makes them pass. The testing task gets dot-notation number `{story}.1`, and implementation tasks follow sequentially.
   - If the story does **not** carry `[tdd]`, place the testing task **after** all implementation tasks (as the last task in the story, before the verification gate that `cpm2:do` will create). The testing task's dot-notation number follows the last implementation task (e.g. if implementation tasks are 1.1, 1.2, 1.3, the testing task is 1.4).
3. Give it a description: "Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`."

If **all** of a story's criteria are tagged `[manual]` (or have no tags), do **not** generate a testing task — there's nothing to automate.

**Graceful degradation**: If no tags were propagated during Step 3 (e.g. the spec had no testing strategy), skip testing task generation entirely.

Present the tasks for each story using AskUserQuestion. Refine before moving to the next story.

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

*Progress note: capture whether an integration story was generated or skipped, with the rationale, in the Step 3c summary.*

### Step 3d: Requirement Coverage Matrix (when input is a spec)

After stories, tasks, and integration testing are defined for the current epic, verify that the spec requirements this epic claims to satisfy are properly covered. This runs per-epic as part of the production loop (after Step 3c, before saving the epic doc and moving to the next epic).

The coverage matrix is **procedural, not evaluative**. Your job is to extract and present verbatim text from both the spec and the stories so the user can judge fidelity. Present the side-by-side text and let the human judge fidelity — the assessment is theirs to make.

1. **Identify which spec requirements this epic covers.** Scan the epic's stories' `**Satisfies**` fields to find all referenced spec requirements.
2. **Read the source spec's requirement text.** For each referenced requirement, extract the number, label, and the specific text that defines thresholds, values, or behaviours. Quote from the **requirements section**, not the testing strategy table (these can differ — the requirements text is authoritative).
3. **Build a side-by-side coverage table.** For each referenced requirement, quote both the spec's requirement text and the matching story acceptance criterion text **verbatim** — preserve the exact wording on both sides.

If the spec's Testing Strategy section includes test approach tags, add a **Spec Test Approach** column showing the tag(s) from the spec's Acceptance Criteria Coverage table. This lets the user verify tag propagation in the same view.

Present the coverage matrix to the user:

```
| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | {requirement label} | {exact text from spec requirements section} | {exact criterion text from story} | Story {N} | `[tag]` | |
```

The "Verified" column is empty for all rows at creation time — it is populated later by `/cpm2:do` during verification gates.

Where a single spec requirement maps to multiple story criteria, include one row per criterion so each mapping is independently visible.

If the user identifies a fidelity problem (story criterion is weaker than or contradicts spec text), update the affected story's acceptance criteria in the epic doc before proceeding.

**Persist the matrix**: After the user confirms, save the coverage matrix as `docs/epics/{parent}-{seq}-coverage-{slug}.md` — using the same two-part prefix and slug as the epic it covers (see Output section). Save the epic doc and coverage matrix together before moving to the next epic.

**Regeneration awareness**: Before saving, check whether a coverage matrix file already exists at the target path (e.g. from a previous `/cpm2:epics` run). If an existing matrix is found and contains `✓` markers in the Verified column, the new matrix must clear verification for any rows whose "Story Criterion (verbatim)" text has changed — replace `✓` with empty for those rows. Rows whose criterion text is unchanged retain their `✓` status. If the existing matrix has no `✓` markers, or if no existing matrix is found, save the new matrix directly.

**Graceful degradation**: If the input is not a spec (e.g. a brief or description without structured requirements), skip this step — there's no requirement list to verify against.

*Progress note: capture the matrix presentation, any fidelity issues identified and corrected, and user confirmation in the Step 3d summary.*

### Step 4: Confirm

**Cross-epic gap check** (when input is a spec): Before presenting the task tree, read all per-epic coverage matrices produced in Step 3d. Compare the union of covered requirements against the spec's full "Must Have" list. Any must-have requirement that doesn't appear in any coverage matrix is a **GAP** — flag it to the user. Gaps must be resolved (add to an existing epic, create a new story, or defer with justification) before proceeding. Should-have requirements not covered are warnings, not blockers.

Present the full task tree to the user showing:
- All epics with their stories and tasks (using story numbers and task dot-notation)
- Dependencies between epics (cross-epic) and between stories (cross-story)
- Suggested implementation order
- Cross-epic gap check result (all must-haves covered, or list unresolved gaps)

Use AskUserQuestion for final confirmation.

## Output

Save each epic document to `docs/epics/{parent}-{seq}-epic-{slug}.md`. Create the `docs/epics/` directory if it doesn't exist.

- `{parent}-{seq}` is the two-part numeric prefix assigned during Step 2 — see the Epic Filename Convention subsection.
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
**Description**: {Scope within parent story — which acceptance criteria this task covers, or what constraint/boundary it addresses}
**Status**: Pending

### {Task Title}
**Task**: {N.2}
**Description**: {Scope within parent story — which acceptance criteria this task covers, or what constraint/boundary it addresses}
**Status**: Pending

---
```

**Epic-level metadata**:
- `**Source spec**`: Back-reference to the specification that produced this epic. Enables traceability from implementation back to requirements.
- `**Status**`: Derived from stories — `Pending` when no stories are started, `In Progress` when any story is in progress, `Complete` when all stories are complete.
- `**Blocked by**`: Cross-epic dependency. References another epic by its filename prefix (e.g. `Epic 28-01-epic-setup` for new two-part epics or `Epic 15-epic-data-model` for legacy flat epics — both shapes are valid). Leave as `—` when the epic has no upstream dependencies. Multiple dependencies are comma-separated (e.g. `Epic 28-01-epic-setup, Epic 15-epic-data-model`).

**Story numbers** are sequential per epic document, starting at 1. They provide stable references within the doc, independent of Claude Code's task system. The `**Blocked by**` field on stories references story numbers for intra-epic deps (e.g. `Story 1` or `Story 1, Story 2`).

**Task numbers** use dot notation: `{story number}.{task sequence}`. Task 1.1 is the first task of Story 1, Task 2.3 is the third task of Story 2.

After saving each epic doc, tell the user the document path so they can reference it later.

### Coverage Matrix Artifacts

Each epic gets a companion coverage matrix file saved alongside it during the production loop (Step 3d). The file uses the same two-part prefix and slug as its epic: `docs/epics/{parent}-{seq}-coverage-{slug}.md`. For legacy flat-shape epics, the coverage file retains the flat shape it was created with (`docs/epics/{nn}-coverage-{slug}.md`); both shapes coexist in the directory.

```markdown
# Coverage Matrix: {Epic Name}

**Source spec**: {path to spec}
**Epic**: {path to epic doc}
**Date**: {today's date}

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| {rows from confirmed Step 3d matrix for this epic} |
```

Save each coverage matrix at the same time as its epic doc. Tell the user both file paths together.

When starting implementation of a task, read the relevant epic document first to understand the full context: all stories, tasks, dependencies, acceptance criteria, and where the current task fits in the broader plan. Also read the epic's coverage matrix when available — its path follows the epic doc's own shape (`docs/epics/{parent}-{seq}-coverage-{slug}.md` for new two-part epics, or `docs/epics/{nn}-coverage-{slug}.md` for legacy flat epics). It provides requirement-level traceability that connects each task back to the spec.

## State Management

Maintain `docs/plans/.cpm-progress-{session_id}.md` throughout the session for compaction resilience. This allows seamless continuation if context compaction fires mid-conversation.

**Path resolution**: All paths in this skill are relative to the current Claude Code session's working directory. When calling Write, Glob, Read, or any file tool, construct the absolute path by prepending the session's primary working directory. Always write to the current session's working directory only — cross-project or cross-session writes corrupt state.

**Session ID**: The `{session_id}` in the filename comes from `CPM_SESSION_ID` — a unique identifier for the current Claude Code session, injected into context by the CPM hooks on startup and after compaction. Use this value verbatim when constructing the progress file path. If `CPM_SESSION_ID` is not present in context (e.g. hooks not installed), fall back to `.cpm-progress.md` (no session suffix) for backwards compatibility.

**Resume adoption**: When a session is resumed (`--resume`) or context is cleared (`/clear`), `CPM_SESSION_ID` changes to a new value while the old progress file remains on disk. The hooks inject all existing progress files into context — if one matches this skill's `**Skill**:` field but has a different session ID in its filename, adopt it:
1. Read the old file's contents (already visible in context from hook injection).
2. Write a new file at `docs/plans/.cpm-progress-{current_session_id}.md` with the same contents.
3. After the Write confirms success, delete the old file: `rm docs/plans/.cpm-progress-{old_session_id}.md`.
Adoption requires `CPM_SESSION_ID` in context. When absent, the fallback path (unsuffixed filename) handles that case.

**Create** the file before starting Step 1 (ensure `docs/plans/` exists). **Update** it after each step completes. **Delete** it only after confirming the final epic documents are saved and written. If compaction fires between deletion and a pending write, all session state is lost.

**Also delete** `docs/plans/.cpm-compact-summary-{session_id}.md` if it exists — this companion file is written by the PostCompact hook and should be cleaned up alongside the progress file.

Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale). Format:

```markdown
# CPM Session State

**Skill**: cpm2:epics
**Step**: {N} of 4 — {Step Name}
**Input source**: {path to spec or brief used as input}

## Epic Files

| # | Slug | Path | Status |
|---|------|------|--------|
| 28-01 | {slug} | docs/epics/28-01-epic-{slug}.md | {Pending/Written} |
| 28-02 | {slug} | docs/epics/28-02-epic-{slug}.md | {Pending/Written} |

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

### Step 3d: Requirement Coverage Matrix
{Per-epic: coverage matrix presented to user — requirements this epic covers, fidelity issues identified and corrected. Matrix saved to docs/epics/{parent}-{seq}-coverage-{slug}.md.}

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
- **Acceptance criteria live on stories.** Tasks inherit meaning from their parent story — acceptance criteria belong at the story level. The story is done when its acceptance criteria pass, not necessarily when every task checkbox is ticked.
- **Right-size task decomposition.** A single task per story is fine when the work is straightforward. The value of task-level breakdown is making complex stories manageable, not adding bureaucracy to simple ones.
- **Dependencies between stories or epics, not tasks.** Use `**Blocked by**: Story N` for intra-epic story dependencies. Use `**Blocked by**: Epic {filename-prefix}-epic-{slug}` for cross-epic dependencies — e.g. `Epic 28-01-epic-foo` for new two-part epics, or `Epic 15-epic-bar` for legacy flat epics (both shapes are valid). Keep dependencies at the story level — if tasks in different stories are interdependent, the stories themselves should carry the dependency.
- **One epic, one document.** Each epic produces its own markdown file. This keeps documents focused and allows parallel work on independent epics.
- **Testing tasks are auto-generated, not manually created.** When story criteria carry `[unit]`, `[integration]`, or `[feature]` tags, Step 3b auto-generates a "Write tests" task. Let the automation handle testing tasks — it ensures consistency. Stories with only `[manual]` criteria get no testing task.
- **`[tdd]` reverses testing task order.** When a story's criteria include `[tdd]`, the auto-generated testing task is placed *before* implementation tasks — enabling the red-green-refactor workflow where tests are written first. Stories without `[tdd]` retain the default order (testing task after implementation). Both modes can coexist in the same epic.
- **`[plan]` opts into formal plan mode.** When a story heading carries `[plan]`, `cpm2:do` enters formal plan mode (EnterPlanMode/ExitPlanMode) for that story's tasks — enforcing read-only exploration and user approval before implementation. Without `[plan]`, `cpm2:do` uses inline planning (brief text plan, then straight to implementation) which keeps the task loop uninterrupted. Suggest `[plan]` for stories involving architectural decisions, security-sensitive areas, or multi-system integration. Most stories work well with inline planning.
- **Integration testing stories are for cross-story verification.** They're distinct from per-story testing tasks. Create them only when the epic has genuine cross-story integration points.
- **Coverage matrix is procedural, not evaluative.** Step 3d runs per-epic and quotes spec text and story criterion text side-by-side — verbatim, not summarised. Your job is extraction and presentation; the user judges fidelity. Leave "exact" vs "partial" judgement to the human — they make that call by reading the two columns. Each matrix is saved as `docs/epics/{parent}-{seq}-coverage-{slug}.md` alongside its epic. Step 4 then runs a cross-epic gap check to catch requirements that no epic covers.
- **Facilitate the grouping.** The user knows their domain better than you. Present a suggested structure and let them reshape it.
