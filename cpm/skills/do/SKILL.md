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

### Template Hint (Startup)

After the Library Check and before task selection, display:

> Output format is fixed (used by downstream skills). Run `/cpm:templates preview do` to see the format.

### Test Runner Discovery (Startup)

After the Template Hint and before story hydration, discover the project's test runner command. This command is used by verification gates to execute tests when acceptance criteria carry automated test tags (`[unit]`, `[integration]`, `[feature]`).

**Discovery priority**:

1. **Library documents**: Check any library documents scoped to `do` (found during Library Check) for testing instructions. Look for explicit test commands, framework references, or testing conventions. If found, use the specified command.
2. **Project config files**: If no library document provides a test command, inspect project configuration files:
   - `composer.json` — check `scripts.test` (e.g. `composer test`, `./vendor/bin/pest`, `./vendor/bin/phpunit`)
   - `package.json` — check `scripts.test` (e.g. `npm test`, `npx jest`)
   - `Makefile` — check for a `test` target (e.g. `make test`)
   - `pyproject.toml` or `pytest.ini` — check for pytest configuration (e.g. `pytest`)
   - `Cargo.toml` — check for Rust project (e.g. `cargo test`)
3. **Ask the user**: If no test command is discoverable from steps 1-2, use AskUserQuestion to ask: "No test runner found automatically. What command runs your tests?" with options for common runners and a freeform option.

**Cache the result**: Store the discovered test command in the progress file (see State Management) as `**Test command**: {command}` or `**Test command**: none` if the user declines. This persists across all verification gates in the session — do not re-discover between tasks.

**Graceful degradation**: If no test runner is discoverable and the user chooses not to provide one, set `**Test command**: none`. Verification gates will fall back to the existing self-assessment approach and note that no test runner was available.

**Skip conditions**: If the epic doc has no acceptance criteria with `[unit]`, `[integration]`, or `[feature]` tags, skip test runner discovery entirely — it won't be needed.

### Framework Detection (Startup)

After Test Runner Discovery and before story hydration, detect the project's framework to enable framework-specific tooling (e.g. refactoring agents).

**Detection**:

1. **Laravel**: Check for an `artisan` file in the project root **and** `composer.json` containing `laravel/framework` in its `require` or `require-dev` dependencies. If both are present, the project is Laravel.
2. **Other frameworks**: No special detection needed at this stage. Additional frameworks can be added here as framework-specific tooling becomes available.

**Cache the result**: Store the detected framework in the progress file as `**Framework**: laravel` or `**Framework**: none`. This persists across the entire session — do not re-detect between tasks.

**Permission check**: If the framework is `laravel`, check whether the `laravel-simplifier:laravel-simplifier` agent is available by reviewing the session's tool permissions. The story refactoring pass (Step 5b) invokes this agent via the Task tool, which requires `Task(laravel-simplifier:laravel-simplifier)` in the user's permission allow list. If unsure whether it's pre-authorised, warn the user early: "Laravel detected — the story refactoring pass uses the `laravel-simplifier` agent. If you haven't already, add `Task(laravel-simplifier:laravel-simplifier)` to your permission allow list (in `.claude/settings.json` under `permissions.allow`) to avoid permission prompts that may not surface during the work loop." This is advisory — do not block startup on it.

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

**State tracking**: Before starting the first task, create the progress file (see State Management below). After the work loop finishes, delete the file.

> **HARD RULE — PROGRESS FILE UPDATE**: After completing EVERY task, you MUST call the Write tool on `docs/plans/.cpm-progress.md` BEFORE doing anything else. This is not optional. This is not deferrable. This has the same priority as saving a file after editing it. A task is NOT done until the progress file reflects it. Historically this step gets silently dropped when momentum is high — that is a bug, not an optimisation. If compaction fires and this file is stale, the user loses all session context with no recovery path.

For each task, follow these steps in order.

### 1. Load Context

- Call `TaskGet` to read the full task description. The description includes the `Epic doc:`, `Story:`, and `Task:` fields set during hydration.
- If an epic doc was resolved during Input, read it with the Read tool. Use the `Story:` and `Task:` fields from the task description to locate the matching entry — search for the `**Story**: {N}` or `**Task**: {N.M}` field that matches. For verification gate tasks, match the `##` story heading. For implementation tasks, match the `###` task heading. Note the parent story's acceptance criteria — for `###` tasks, look up to the nearest `##` story heading above the matched task. If the matched `###` task has a `**Description**:` field, read it — this scopes the task within its parent story and clarifies which acceptance criteria it addresses.
- **Determine task type**: Check the task description for `Type: verification`. If present, this is a story verification gate — the work in step 4 will be acceptance criteria checking, not implementation. If absent, this is a normal implementation task.
- **Determine workflow mode**: Scan the parent story's acceptance criteria for the `[tdd]` tag. If any criterion carries `[tdd]`, this story uses TDD workflow mode — record this for use in Step 4. If no `[tdd]` tag is found, the story uses the standard post-implementation workflow.
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

**If this is a verification gate** (`Type: verification` in the task description): Do not implement anything. Instead, read the parent story's acceptance criteria from the epic doc and verify each criterion against the current state of the codebase.

**Test execution in verification gates**: Scan the story's acceptance criteria for test approach tags (`[unit]`, `[integration]`, `[feature]`). If any automated tags are present and `**Test command**` in the progress file is not `none`:

1. Run the cached test command using the Bash tool.
2. If tests **pass**: report the pass and continue verification of remaining criteria (including `[manual]` ones via self-assessment).
3. If tests **fail**: report the failure output to the user via AskUserQuestion with options: "Fix the failing tests and re-run", "Continue anyway (mark as known issue)", or "Stop and investigate". Do not block the work loop — let the user decide.
4. If `**Test command**` is `none` or all criteria are tagged `[manual]`, use the existing self-assessment approach — inspect files, check outputs, and assess each criterion manually.

Proceed to step 5 with your assessment.

**If this is an implementation task in TDD mode** (no `Type: verification`, and the story carries `[tdd]` as determined in Step 1): Replace the standard implementation approach with the **red-green-refactor sub-loop**. This is the core TDD discipline — do not skip or compress these phases.

**Phase 1 — Red (write a failing test)**:
1. Derive a test from the parent story's acceptance criteria and the current task's description. Write a test file (or add test cases to an existing test file) that describes the expected behaviour.
2. Construct a **targeted test command** — run only the specific test file just written, not the full test suite. Derive the command from the cached test runner and the test file path (e.g. `pest tests/Feature/MyTest.php`, `jest path/to/test.spec.ts`, `pytest tests/test_my_feature.py`).
3. Run the targeted test. It **must fail** — this confirms the test is actually testing something that doesn't exist yet.
4. If the test **passes unexpectedly**: stop. Something is wrong — either the test isn't testing what you think, or the behaviour already exists. Use AskUserQuestion to present the situation: "Red phase: test passed unexpectedly. This means the expected behaviour may already exist, or the test isn't verifying the right thing." Options: "Investigate and fix the test", "Skip TDD for this task (fall back to standard workflow)", "Stop and discuss".

**Phase 2 — Green (minimum implementation)**:
1. Write the **minimum code** needed to make the failing test pass. Do not add extra features, handle edge cases not covered by the test, or refactor. Just make the test pass.
2. Run the targeted test command again. It **must pass**.
3. If the test **still fails**: the implementation isn't sufficient. Continue working on the implementation until the test passes. If stuck after a reasonable attempt, use AskUserQuestion: "Green phase: test still failing after implementation." Options: "Continue working on it", "Skip TDD for this task (fall back to standard workflow)", "Stop and investigate".

**Phase 3 — Refactor (clean up within task scope)**:
1. Review the code just written in Phases 1 and 2. Clean up: improve naming, extract methods, remove duplication, improve readability.
2. **Scope constraint**: Only refactor code touched by the current task. Do not restructure surrounding code, reorganise files, or make changes beyond the immediate scope. The refactor phase is about the code you just wrote, not the broader codebase.
3. Run the targeted test command again. It **must still pass** — refactoring must not change behaviour.
4. If the test **fails after refactoring**: you changed behaviour, not just structure. Undo the refactoring change that broke the test and try again.

Proceed to step 5 after the sub-loop completes.

**If this is an implementation task in standard mode** (no `Type: verification`, and the story does **not** carry `[tdd]`): Execute the task as described. This is the existing approach — writing code, creating files, running commands, whatever the task requires. Read the full task description and the parent story's acceptance criteria to understand the broader context. Work until the task is complete.

**ADR awareness** (both modes): Before starting implementation, check if this task touches architectural boundaries. **Glob** `docs/architecture/[0-9]*-adr-*.md` — if ADRs exist and the task involves structural decisions, data models, integration points, or deployment concerns, read the relevant ADRs for context. Let the architectural decisions guide implementation choices. If no ADRs exist, proceed normally.

### 5. Verify Acceptance Criteria

Before marking the task complete:

- Re-read the acceptance criteria from the epic doc (or from the task description if no epic doc).
- For each criterion, assess whether it's been met. The assessment method depends on the criterion's tag:
  - **`[unit]`, `[integration]`, `[feature]`**: If a test command is cached (`**Test command**` is not `none`), run it and use the pass/fail result as evidence. A passing test suite satisfies these criteria. A failing test suite means the criterion is not met — report the specific failures.
  - **`[manual]` or no tag**: Self-assess by inspecting the codebase, checking files, or reviewing outputs. This is the existing approach.
- If all criteria are met (by test results or self-assessment), proceed to step 6.
- If any criteria are **not** met, flag them to the user. List what's unmet and ask whether to continue working on them or mark the task as done anyway. Use AskUserQuestion for this gate.

### 5b. Story Refactoring Pass (verification gates only)

After the verification gate passes (all acceptance criteria met in Step 5), perform a focused refactoring pass on the code produced by the story. This step **only applies to verification gate tasks** — skip it for implementation tasks.

**Identify scope**: Review the tasks completed in this story (listed in the progress file's Completed Tasks section). Identify the files that were created or modified during the story's implementation tasks. These files — and only these files — are the refactoring target.

**Run the refactoring pass**:

- **Laravel project with `laravel-simplifier`**: If `**Framework**` in the progress file is `laravel`, use the Task tool with `subagent_type: "laravel-simplifier:laravel-simplifier"` to refactor the touched files. Pass the agent a prompt listing the files modified by this story and instruct it to simplify and refine for clarity, consistency, and maintainability. If the agent is not available in the current session (tool call fails), fall back to the self-directed approach below.
- **All other projects** (or fallback): Perform a self-directed refactoring review of the files touched by this story. Focus on: naming clarity, duplication removal, method extraction, readability improvements. Keep changes minimal — this is a polish pass, not a restructuring.

**Retest**: After refactoring, run the cached test command (if not `none`) to confirm nothing broke.

- If tests **pass**: proceed to Step 6.
- If tests **fail**: revert the refactoring changes that caused failures and proceed to Step 6 without them. Do not block the work loop on a failed refactoring pass.

**Scope constraint**: Start with the files touched by the current story, but look outward for consolidation opportunities — duplicate code, similar patterns, extraction candidates, and abstractions that span touched and non-touched code. If the story introduced logic that already exists elsewhere, merge it. If a pattern appears in both new and existing code, extract it. The refactoring may touch files beyond the story's direct scope when there's a clear consolidation or deduplication benefit. However, do not pursue unrelated refactoring — every change should connect back to the code the story produced.

**Skip conditions**: If the story had no implementation tasks (e.g. pure documentation or configuration), skip the refactoring pass — there's nothing to refactor.

### 6. Complete and Update State

> **THIS STEP HAS THREE PARTS. ALL THREE ARE MANDATORY. YOU MUST COMPLETE ALL THREE BEFORE MOVING TO STEP 7. THE THIRD PART (PROGRESS FILE) IS THE ONE THAT GETS DROPPED — DO NOT DROP IT.**

**Part A — Mark complete**:
- If epic doc integration is active, use the Edit tool to update the matched entry's status (whether `##` story or `###` task):
  - `old_string`: `**Status**: In Progress` (scoped near the matched heading)
  - `new_string`: `**Status**: Complete`
- Call `TaskUpdate` to set the task status to `completed`.

**Part B — Capture observations (retro)**:

> **THIS STEP IS MANDATORY FOR VERIFICATION GATES. DO NOT SKIP IT.**
>
> Every completed story must produce a `**Retro**:` field — this is the only input `/cpm:retro` has to work with. If no observations are captured, the retro skill has nothing to synthesise and the feedback loop between execution and planning is broken. A retro observation is not optional bookkeeping — it is the bridge between execution and learning.

**For verification gate tasks**: You MUST record an observation. Reflect on the story as a whole — all the tasks you just verified. Ask: "What's worth remembering about this story?" Pick the most fitting category below and write one sentence. If nothing went wrong, use `Smooth delivery` — that's valuable data too.

**For implementation tasks**: Observation is optional. If something noteworthy happened during this specific task, record it. Otherwise, skip Part B — the mandatory verification gate observation will cover the story.

Observation categories (use exactly one per observation):
- **Smooth delivery**: Story delivered as planned with no surprises — well-scoped and well-estimated
- **Scope surprise**: The story was larger or smaller than expected
- **Criteria gap**: Acceptance criteria missed something important that only became clear during implementation
- **Complexity underestimate**: The implementation was harder than expected due to technical factors
- **Codebase discovery**: Found something unexpected in the codebase (pattern, convention, limitation) that affected the work
- **Testing gap**: Tests revealed issues that acceptance criteria didn't anticipate, or criteria proved untestable with the available test infrastructure
- **Pattern worth reusing**: Discovered an approach, abstraction, or technique during implementation that should be applied elsewhere

Use the Edit tool to append a `**Retro**:` field to the completed story in the epic doc, immediately after the last existing field for that story (before the `---` separator). Format: `**Retro**: [{category}] {One-sentence observation}`

**Part C — Write progress file**:

> **YOU ARE ABOUT TO SKIP THIS. DO NOT SKIP THIS.**
>
> Call the Write tool on `docs/plans/.cpm-progress.md` RIGHT NOW. Not later. Not after the next task. NOW. Every time you have completed Part A, you must immediately do Part C. There is no scenario where skipping this is acceptable. A skipped progress file write is a data loss bug — the user loses their entire session if compaction fires.

The file must reflect:
- The task just completed (added to Completed Tasks section)
- The next action (which task to pick up next, or "work loop complete")
- The current tasks remaining count

**Step 6 is not complete until the Write tool call for `.cpm-progress.md` has returned. Do not call TaskList, TaskGet, Read, or any other tool until the Write has succeeded. The very next tool call after Part A's TaskUpdate (and Part B's Edit if applicable) MUST be the Write call for the progress file.**

### 7. Next Task

- Run the **Story Hydration** gating check: call `TaskList`. If no pending unblocked tasks exist, hydrate the next unblocked story from the epic doc (see Story Hydration above). This handles story-to-story transitions automatically.
- After hydration (or if tasks already existed), pick the next lowest-ID task that is `pending` and has no unresolved `blockedBy`.
- If one exists, go back to step 1 (Load Context) for the new task.
- If none exist (and hydration found no unblocked stories), the work loop is done — proceed to step 8.

### 8. Batch Summary (Loop Completion)

When the work loop finishes (no more pending unblocked tasks):

1. **Epic-level verification**: If the epic doc has a `**Source spec**:` field, read the referenced spec. Check whether the completed epic, taken as a whole, satisfies the spec's requirements that fall within this epic's scope. This is an integration-level check — individual story criteria may all pass while the epic as a whole misses something (e.g. a requirement that spans multiple stories, or an integration point between stories). Report the assessment to the user. If gaps are found, flag them — they may warrant additional work or a `cpm:pivot`. If no spec exists, skip this step.

2. **Check for observations**: Read the epic doc and scan for any `**Retro**:` fields across all completed stories. If none exist, skip the lessons step.

3. **Synthesise lessons**: If observations were captured, append a `## Lessons` section to the end of the epic doc using the Edit tool. Group observations by category:

```markdown
## Lessons

### Smooth Deliveries
- {observation from story N}

### Scope Surprises
- {observation from story N}

### Criteria Gaps
- {observation from story N}

### Complexity Underestimates
- {observation from story N}

### Codebase Discoveries
- {observation from story N}

### Testing Gaps
- {observation from story N}

### Patterns Worth Reusing
- {observation from story N}
```

Only include categories that have observations. Each bullet should reference which story it came from. The summary must be scannable in under 30 seconds — keep it tight.

4. **Report and stop**: Report a summary of what was completed across the work loop, and delete the progress file.

## Graceful Degradation

The skill should work even without an epic doc:

- **No epic doc resolved during Input**: Skip epic doc reads and status updates. Still do the work, still verify acceptance criteria from the task description.
- **Epic doc file doesn't exist or was deleted mid-loop**: Same — skip epic doc integration, work on the task directly.
- **Story heading not found in epic doc**: Log a note, skip status updates for that story, continue with the work.
- **Test command fails to execute** (command not found, timeout, permission error): Report the error to the user via AskUserQuestion. Do not retry automatically. Offer options: "Provide a different test command", "Continue without tests (self-assessment only)", "Stop and investigate". If the user provides a new command, update `**Test command**` in the progress file. Never block the work loop on a broken test command.
- **Test command returns failures** (tests run but some fail): This is not an error — it's information. Report which tests failed and let the user decide how to proceed (see Step 4 verification gate logic). The work loop continues regardless of the user's choice.
- **No test command cached** (`**Test command**: none`): All verification uses self-assessment. This is the default fallback and is always available.
- **No test command + `[tdd]` story**: If the story carries `[tdd]` but `**Test command**` is `none`, the TDD sub-loop cannot run (it requires test execution at every phase). Fall back to the standard post-implementation workflow for this story and warn the user: "TDD mode requires a test runner, but none is available. Falling back to standard workflow for this story." The warning should be visible — use AskUserQuestion to let the user either provide a test command or acknowledge the fallback.
- **`laravel-simplifier` agent not available**: If the project is Laravel but the `laravel-simplifier:laravel-simplifier` agent is not available in the current session (Task tool call fails, the subagent type is unrecognised, or the permission prompt is not approved), fall back to self-directed refactoring in Step 5b. Log a note: "laravel-simplifier not available, using self-directed refactoring." Do not block the work loop.

## State Management

Maintain `docs/plans/.cpm-progress.md` throughout the work loop for compaction resilience. This allows seamless continuation if context compaction fires mid-loop.

**Path resolution**: All paths in this skill are relative to the current Claude Code session's working directory. When calling Write, Glob, Read, or any file tool, construct the absolute path by prepending the session's primary working directory. Never write to a different project's directory or reuse paths from other sessions.

> **KNOWN FAILURE MODE**: The progress file update is the single most skipped instruction in this skill. It gets silently dropped when task momentum is high. Every time it is skipped, it creates a window where compaction would destroy the session with no recovery. Treat the Write call for this file with the same urgency as saving user code — it is not bookkeeping, it is the only thing standing between the user and total context loss.

**Create** the file before starting the first task. **Update** it after EVERY task completes. **Delete** it only after all output artifacts (epic doc updates, batch summary) have been confirmed written — never before.

Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale). Format:

```markdown
# CPM Session State

**Skill**: cpm:do
**Current task**: {task ID} — {task subject}
**Epic doc**: {path to epic doc, or "none"}
**Test command**: {discovered test command, or "none" if no runner found}
**Framework**: {detected framework, e.g. "laravel" or "none"}
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
- **`[tdd]` activates the red-green-refactor sub-loop.** When a story's acceptance criteria carry the `[tdd]` tag, Step 4 switches from standard implementation to a three-phase TDD loop: write a failing test (Red), write minimum code to pass (Green), clean up within task scope (Refactor). Each phase runs a targeted test — the specific test file, not the full suite. The full suite runs at the story verification gate. Stories without `[tdd]` use the standard post-implementation workflow unchanged. Both modes can coexist in the same epic.
- **Story refactoring pass polishes before moving on.** When a verification gate passes, Step 5b performs a refactoring pass starting from the files touched by the story — then retests. For Laravel projects, this uses the `laravel-simplifier` agent if available; for all other projects, it's a self-directed review. The pass starts with the story's code but looks outward for consolidation opportunities — deduplication, extraction, and abstraction across touched and existing code. If refactoring breaks tests, the changes are reverted.
