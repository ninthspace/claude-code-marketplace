---
name: cpm:do
description: Execute tasks from an epic doc. Picks the next unblocked task, reads context and acceptance criteria, does the work, verifies criteria, updates the epic doc, and loops until done — updating coverage matrices and generating a retro on completion. Triggers on "/cpm:do".
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
   d. If multiple epic files exist, use Grep to search for `**Status**:` across the matched files, then filter to epics that are not `Complete`/`Done` (`Done` reads as a synonym for `Complete`) and not retired (`Superseded` / `Withdrawn` — terminal, user-set statuses for work no longer needed; there is nothing to do on a retired epic). Use Grep and Read tools directly (Bash loops with shell variables lose context). If only one has remaining work, auto-select it. If multiple have remaining work, present the choices to the user with AskUserQuestion — show each epic's name and status.
   e. If all epics are `Complete` or retired (`Superseded` / `Withdrawn`), tell the user there's nothing to do.
3. If no epic docs exist, proceed without one (tasks still work via their descriptions).

The epic doc, once resolved, applies to the entire work loop. Parse it once and reuse the result across all tasks.

### Task Selection

1. If `$ARGUMENTS` includes a task ID (e.g. `3` or `#3`), start with that task.
2. Otherwise, run the **Story Hydration** gating check (see below). This ensures Claude Code tasks exist for the current story before selection.
3. Call `TaskList` and pick the lowest-ID task that is `pending` and has no unresolved `blockedBy`.
4. If no pending unblocked tasks exist after hydration, the work is done.

## Stale-Progress Check

Follow the shared **Stale-Progress Check** procedure (from the CPM Shared Skill Conventions loaded at session start).

## Retro Check

Before the work loop begins, run the **retro consumption gate** — a hard gate (defined here, local to `cpm:do`) that forces each relevant prior-epic lesson to be consciously applied, deferred, or judged not relevant before any work starts. This is `cpm:do`'s stronger form of retro consumption; the shared **Retro Awareness** procedure remains advisory for the other skills, and this skill overrides its Yes/No prompt with the disposition gate below.

1. **Find the lessons.** Glob `docs/retros/[0-9]*-retro-*.md`. If none exist or the directory is absent, skip the gate silently and start the loop. Otherwise select relevant observations **across all retros** per the shared **Retro Awareness** procedure (step 2): judge each observation by source/domain match against the epic being worked and by category, with recency only as a tiebreaker, capped to a handful — do **not** consume only the highest-prefix file. A relevant lesson from an older retro (e.g. a testing gap in the same feature area) must not be shadowed by a more recent, unrelated one. **Make the selection visible**: when you present the gate (step 3), name the source retro for each observation — its filename, `**Source**:`, and `**Date**:` — so *which* lessons are consumed (and from where) is explicit and a mis-selection is never silent.
2. **Select relevant observations.** Filter the selected cross-retro observations (from step 1) to the categories this skill acts on (see **Retro incorporation** below); observations outside those categories are not gated.
3. **Gate on disposition, not acknowledgement.** Present each relevant observation **verbatim, with its category** (rendered in the message body per the **Gate Presentation** convention), and require a disposition for *each one* via `AskUserQuestion` — never a single blanket confirmation. The three dispositions are all **per-run**: each records a breadcrumb on this epic (step 4) and **none** mutate the source retro, so a lesson set aside here is re-judged on the next run.
   - **Applied** — state *how* it changes this run (which task exploration or criterion it informs).
   - **Deferred** — give a one-line *reason* it isn't being applied now.
   - **Not relevant here** — the lesson is still valid but doesn't bear on *this* work; say why. This is a **local** judgement about fit, not a verdict on the lesson's truth — it is per-run and reversible, and never retires the lesson at its source.
   A lone "acknowledge" or "continue" response does **not** satisfy the gate — each observation gets its own disposition.

   **Retiring a spent lesson in-cycle (deliberate, rare).** If, while disposing of an observation, you can *guarantee* its usefulness has permanently passed — e.g. you just deleted the module it warned about — you may retire it durably without leaving the flow. This is **not** a fourth peer option, and it is never the default: it is a deliberate, separately-confirmed action, offered only on explicit request for the observation in hand. Confirm via a dedicated `AskUserQuestion` ("Retire this lesson at its source? This removes it from **all** future runs.") and require a typed **reason**. Only on that confirmation does it write the durable retirement marker (step 5). Durable retirement's normal home is the deliberate `/cpm:retro retire` review pass — reserve this in-cycle path for the rare can't-miss case. Record it as the **Obsolete** disposition in steps 4–5.
4. **Record the trace.** For each disposition, append a breadcrumb to the epic doc being worked (the epic resolved in Input), in its top-level metadata block (below the epic's `**Blocked by**` field):
   `**Retro applied**: {nn} · {category} · {disposition} — {note}`
   where `{nn}` is the source retro's number, `{category}` the observation category, `{disposition}` one of Applied / Deferred / Not relevant here / Obsolete (Obsolete only via the deliberately-confirmed in-cycle retire above), and `{note}` the how/reason/why from step 3. This makes how each prior lesson was handled auditable by the next reader, `cpm:status`, and the next retro.
5. **Retire obsolete lessons at the source (durable).** For each observation given the **Obsolete** disposition via the deliberately-confirmed in-cycle retire (step 3), append a retirement marker to that observation's bullet in its **source retro file** per the shared **Retro Retirement** convention — `**Retired {YYYY-MM-DD}**: {reason}`, using the typed *reason* from the confirmation. The bullet stays in place; the marker makes the shared **Retro Awareness** selection skip it in all future runs. The step-4 breadcrumb records the decision for *this* run; this source marker makes it durable across runs. **Applied**, **Deferred**, and **Not relevant here** dispositions never write to the source retro — only the gated **Obsolete** retire does.

**Autonomous mode (e.g. `cpm:ralph`)**: When the run is autonomous — no human is present to choose dispositions — the gate **does not block**. Rather than deferring everything, it **branches by observation category** — and this split is the single source of truth, so `cpm:ralph` references it rather than maintaining its own list:

- **Safe categories — auto-apply.** **Codebase discoveries** and **Patterns worth reusing** are low-ambiguity and additive, so apply them autonomously and carry each into the run as active context (see *What "apply" means autonomously* below for the exact breadcrumb and semantics).
- **Judgement-heavy categories — defer.** **Scope surprises**, **Criteria gaps**, **Complexity underestimates**, and **Testing gaps** each imply a re-planning or scope call a human must own, so **never auto-apply** them — defer each with `**Retro applied**: {nn} · {category} · deferred (autonomous run, unreviewed)` (the step 4 format).
- **Smooth deliveries** is informational — nothing to apply or defer.

Surface the full list of **both** the auto-applied and the deferred-unreviewed observations in the batch/run summary (Step 8 item 4) so a human can review them after the loop. Degrade to these logged dispositions — never wait for input.

**What "apply" means autonomously**: applying a safe-category lesson means carrying its observation into the work loop as an explicit constraint or piece of context for the tasks ahead — the same lens an *Applied* disposition gets in an interactive run. It **must NOT** trigger autonomous re-planning, story re-scoping, or any edit to the epic or spec; a lesson that seems to demand that belongs to a judgement-heavy category and is deferred, not applied. Record each auto-application with `**Retro applied**: {nn} · {category} · applied (autonomous, safe-category) — {what it did}` (the step-4 format, with an `applied (autonomous, safe-category)` disposition in place of the interactive Applied/Deferred/Not relevant here/Obsolete set). **Never auto-retire** under autonomous mode — retirement stays a deliberate human action, so the **Obsolete** disposition and its source-retro marker are unavailable to an autonomous run.

Once every relevant observation has a disposition, **start the loop**, carrying each *Applied* disposition into the run as active context — a lens on every task per the incorporation guidance below, not a one-off.

**Retro incorporation** (this skill — which categories matter and what changes):
- **Complexity underestimates**: Inform per-task exploration (Step 1, Load Context) — when exploring a task, look for the complexity drivers past tasks underestimated (concurrency, edge cases, data shapes).
- **Codebase discoveries**: Inform per-task exploration — surfaced patterns and limitations are checked first before re-discovering them.
- **Testing gaps**: Inform Step 4 (Verify Acceptance Criteria) — past untestable criteria patterns are flagged early so the user can refine criteria before implementation, not after.
- **Patterns worth reusing**: Inform Step 4 implementation — apply the surfaced pattern when its conditions match the current task.

## Library Check

Follow the shared **Library Check** procedure with scope keyword `do`. Deep-read selectively during task execution when a library document's content directly affects the current task — e.g. coding standards before writing code, or architecture docs before structural decisions.

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

**Cache the result**: Store the discovered test command in the progress file (see State Management) as `**Test command**: {command}` or `**Test command**: none` if the user declines. Reuse the cached command for all verification gates in the session.

**Graceful degradation**: If no test runner is discoverable and the user chooses not to provide one, set `**Test command**: none`. Verification gates will fall back to the existing self-assessment approach and note that no test runner was available.

**Skip conditions**: If the epic doc has no acceptance criteria with `[unit]`, `[integration]`, or `[feature]` tags, skip test runner discovery entirely — it won't be needed.

### Framework Detection (Startup)

After Test Runner Discovery and before story hydration, detect the project's framework to enable framework-specific tooling (e.g. refactoring agents).

**Detection**:

1. **Laravel**: Check for an `artisan` file in the project root **and** `composer.json` containing `laravel/framework` in its `require` or `require-dev` dependencies. If both are present, the project is Laravel.
2. **Other frameworks**: No special detection needed at this stage. Additional frameworks can be added here as framework-specific tooling becomes available.

**Cache the result**: Store the detected framework in the progress file as `**Framework**: laravel` or `**Framework**: none`. Reuse the cached value for the entire session.

**Permission check**: If the framework is `laravel`, check whether the `laravel-simplifier:laravel-simplifier` agent is available by reviewing the session's tool permissions. The story refactoring pass (Step 5b) invokes this agent via the Task tool, which requires `Task(laravel-simplifier:laravel-simplifier)` in the user's permission allow list. If unsure whether it's pre-authorised, warn the user early: "Laravel detected — the story refactoring pass uses the `laravel-simplifier` agent. If you haven't already, add `Task(laravel-simplifier:laravel-simplifier)` to your permission allow list (in `.claude/settings.json` under `permissions.allow`) to avoid permission prompts that may not surface during the work loop." This is advisory — proceed with startup regardless.

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
   - A story is unblocked when its `**Blocked by**` field is either `—` (no dependencies) or all referenced stories have `**Status**: Complete` (or `Done`, which reads the same). A referenced `Superseded` / `Withdrawn` epic never satisfies the dependency — that work will not be done — so the story stays blocked.
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

**State tracking**: Create the progress file before the first task and update it after each task completes. See State Management below for the format and rationale. Delete the file once the work loop finishes.

### Termination

- **Success**: No pending unblocked tasks remain after the Story Hydration check in Step 7 — proceed to Batch Summary (Step 8).
- **Blocker**: A task requires an external dependency that cannot be resolved in this session (missing API access, awaiting another team's output, infrastructure not available). Use AskUserQuestion to confirm the blocker with the user, then skip the task and continue to the next unblocked task. If no unblocked tasks remain, proceed to Batch Summary with the blocker noted.
- **Ambiguity**: Acceptance criteria cannot be evaluated — the requirement is unclear, contradictory, or untestable with available tools. Use AskUserQuestion to surface the specific criterion text and ask the user to clarify. If resolved, continue. If unresolvable, treat as a blocker — skip the task and continue to the next.

For each task, follow these steps in order.

### 1. Load Context

- Call `TaskGet` to read the full task description. The description includes the `Epic doc:`, `Story:`, and `Task:` fields set during hydration.
- If an epic doc was resolved during Input, read it with the Read tool. Use the `Story:` and `Task:` fields from the task description to locate the matching entry — search for the `**Story**: {N}` or `**Task**: {N.M}` field that matches. For verification gate tasks, match the `##` story heading. For implementation tasks, match the `###` task heading. Note the parent story's acceptance criteria — for `###` tasks, look up to the nearest `##` story heading above the matched task. If the matched `###` task has a `**Description**:` field, read it — this scopes the task within its parent story and clarifies which acceptance criteria it addresses.
- **Coverage matrix**: Check for a companion coverage matrix alongside the epic doc. Derive the coverage path from the epic path by replacing `-epic-` with `-coverage-` in the filename. This works for both legacy flat epics (`docs/epics/15-epic-foo.md` → `docs/epics/15-coverage-foo.md`) and new two-part epics (`docs/epics/28-01-epic-foo.md` → `docs/epics/28-01-coverage-foo.md`) via the same rule — no shape detection or branching required. If the coverage matrix exists, read it — it provides side-by-side verbatim text from the source spec and the story's acceptance criteria. This gives you requirement-level traceability: the spec's exact wording for each requirement this epic covers, so you can verify implementation against the spec's intent, not just the story's paraphrase.
- **Drift detection**: If a coverage matrix was loaded and any of its rows have `✓` in the Verified column, compare the "Story Criterion (verbatim)" text in those verified rows against the corresponding acceptance criteria in the epic doc. If the text differs — indicating the epic doc was modified after verification — flag the mismatch to the user: "Coverage matrix drift detected: Story {N} criterion text has changed since verification. The `✓` marker may be stale." This catches out-of-band edits that bypassed `/cpm:pivot`'s invalidation logic. If no verified rows exist or no coverage matrix is present, skip this check.
- **Determine task type**: Check the task description for `Type: verification`. If present, this is a story verification gate — the work in step 4 will be acceptance criteria checking, not implementation. If absent, this is a normal implementation task.
- **Determine workflow mode**: Scan the parent story's acceptance criteria for the `[tdd]` tag. If any criterion carries `[tdd]`, this story uses TDD workflow mode — record this for use in Step 4. If no `[tdd]` tag is found, the story uses the standard post-implementation workflow.
- **Determine planning mode**: Check whether the parent story's `##` heading contains a `[plan]` tag (e.g. `## Set up OAuth provider integration [plan]`). If `[plan]` is present, this story uses formal plan mode in Step 3 — but the plan covers the whole story and fires **once per story, not once per task**. Also check the progress file's `**Planned stories**:` line: if this story's number already appears there, its plan is approved and Step 3 will skip straight to implementation. If `[plan]` is absent, Step 3 uses inline planning (the default). Record both the tag and the already-planned state for use in Step 3.
- If no epic doc is available, proceed without epic doc integration — the task still gets done.

### 2. Update Status to In Progress

- Call `TaskUpdate` to set the task status to `in_progress`.
- If epic doc integration is active, use the Edit tool to update the matched entry's status. The entry may be a `##` story or a `###` task — locate the correct `**Status**: Pending` field near the matched heading:
  - `old_string`: `**Status**: Pending` (scoped near the matched heading)
  - `new_string`: `**Status**: In Progress`
- **Preserve any note tail.** A status may carry a human note after a delimiter — `**Status**: Pending — waiting on API keys`. Match only the **status token** (`**Status**: Pending`), never the whole line, so the ` — waiting on API keys` tail is left untouched (the result becomes `**Status**: In Progress — waiting on API keys`). Do not widen `old_string` to swallow the tail, and never rewrite or drop a note you did not author.

### 3. Plan (when warranted)

Before jumping into implementation, assess whether this task warrants a planning step. The planning approach depends on whether the parent story carries a `[plan]` tag (detected in Step 1).

**Default: Inline planning (no `[plan]` tag)**

For most tasks, plan inline — explore the codebase, output a brief plan as text, and proceed directly to Step 4. No mode switch, no user approval gate, no loop disruption.

For complex, critical, or sensitive tasks: explore the codebase using Read, Glob, and Grep, then output a brief plan covering order of operations, implementation decisions, and risk flags. Then proceed to Step 4.

Skip planning entirely for straightforward tasks — config changes, documentation updates, simple additions to existing patterns.

**Formal plan mode (`[plan]` tag present) — once per story**

The `[plan]` tag lives on the story, so the plan covers the whole story and formal plan mode fires **once per story, not once per task**. Which case applies depends on whether the story has already been planned in this run (the `**Planned stories**:` check from Step 1):

- **Story not yet planned** (its number is absent from `**Planned stories**:` — typically the first task of the story): enter `EnterPlanMode`, explore the codebase, and design the approach **for the entire story** — sequence all of its tasks and call out implementation decisions and risks across them, not just the current task. Get user approval before writing any code, then exit plan mode. Record the story as planned by adding its number to the progress file's `**Planned stories**:` line (written at the next Step 6 Part C). Then proceed to Step 4 for the current task.
- **Story already planned** (its number appears in `**Planned stories**:`): do **not** re-enter plan mode — the approved story plan already governs this task. Proceed directly to Step 4. Add a brief one- or two-line inline note only if this specific task needs a wrinkle the story-level plan did not cover.

Use formal plan mode for stories where the enforcement benefit (physically prevented from writing code while planning) and the approval gate (user reviews before implementation begins) justify the loop interruption. The `[plan]` tag is applied by `cpm:epics` to stories that touch architecture, security, or multi-system integration.

**Note**: Formal plan mode creates an interaction boundary that pauses the task loop. After exiting plan mode and completing the task, you MUST continue the task loop — proceed to Step 5, then Step 6, then Step 7 (next task). The plan mode interaction is NOT a stopping point, and it does not repeat for the remaining tasks in the same story.

**Keep execution plans concise** (both modes). The epic doc already defines *what* to build — stories, tasks, acceptance criteria, and description fields provide the specification. Your plan should only add what the epic doc doesn't say:

1. **Order of operations** — which files to create/modify and in what sequence
2. **Implementation decisions** — choices not already captured in the epic (e.g. which design pattern, which library API to use)
3. **Risk flags** — edge cases or complications you've spotted during exploration

Include only what the epic doc omits: order of operations, implementation decisions, and risk flags. Acceptance criteria, test cases implied by tags, and file content details belong to the implementation phase. A bulleted list of 5-15 lines is the target. Context is finite; every token spent on the plan is a token unavailable for implementation.

### 4. Do the Work

**If this is a verification gate** (`Type: verification` in the task description): Read the parent story's acceptance criteria from the epic doc and verify each criterion against the current state of the codebase. The gate's purpose is assessment only — all implementation happens in prior tasks.

**Test execution in verification gates**: For criteria tagged `[unit]`, `[integration]`, or `[feature]`, run the cached test command and use pass/fail as evidence — a failing test means the criterion is not met. For `[manual]` or untagged criteria, self-assess by inspecting the codebase. If `**Test command**` is `none`, all verification uses self-assessment.

**Stalled verification**: If a fix-and-recheck cycle fails to reduce the count of unmet criteria after a fix attempt, stop cycling and use AskUserQuestion: "Verification not converging — {N} criteria still unmet." Options: "Continue trying", "Mark unmet criteria as known issues and proceed", "Stop the work loop".

Proceed to step 5 with your assessment.

**If this is an implementation task in TDD mode** (no `Type: verification`, and the story carries `[tdd]` as determined in Step 1): Replace the standard implementation approach with the **red-green-refactor sub-loop**. This is the core TDD discipline — execute all three phases in sequence, each producing a distinct outcome.

> **Intentionally preserved**: The three-phase structure below is a behavioural lock that enforces test-before-implementation ordering — it is not instructional verbosity. Compressing it risks losing the ordering guarantee that is the whole point of TDD mode.

**Phase 1 — Red (write a failing test)**:
1. Derive a test from the parent story's acceptance criteria and the current task's description. Write a test file (or add test cases to an existing test file) that describes the expected behaviour.
2. Construct a **targeted test command** — run only the specific test file just written, not the full test suite. Derive the command from the cached test runner and the test file path (e.g. `pest tests/Feature/MyTest.php`, `jest path/to/test.spec.ts`, `pytest tests/test_my_feature.py`).
3. Run the targeted test. It **must fail** — this confirms the test is actually testing something that doesn't exist yet.
4. If the test **passes unexpectedly**: stop. Something is wrong — either the test isn't testing what you think, or the behaviour already exists. Use AskUserQuestion to present the situation: "Red phase: test passed unexpectedly. This means the expected behaviour may already exist, or the test isn't verifying the right thing." Options: "Investigate and fix the test", "Skip TDD for this task (fall back to standard workflow)", "Stop and discuss".

**Phase 2 — Green (minimum implementation)**:
1. Write the **minimum code** needed to make the failing test pass — only what the failing test requires. Extra features, uncovered edge cases, and refactoring belong to later phases.
2. Run the targeted test command again. It **must pass**.
3. If the test **still fails**: the implementation isn't sufficient. Continue working on the implementation until the test passes. If stuck after a reasonable attempt, use AskUserQuestion: "Green phase: test still failing after implementation." Options: "Continue working on it", "Skip TDD for this task (fall back to standard workflow)", "Stop and investigate".

**Phase 3 — Refactor (clean up within task scope)**:
1. Review the code just written in Phases 1 and 2. Clean up: improve naming, extract methods, remove duplication, improve readability.
2. **Scope constraint**: Limit refactoring to code touched by the current task. Restructuring, file reorganisation, and broader changes belong to the story-level refactoring pass (Step 5b).
3. Run the targeted test command again. It **must still pass** — refactoring must not change behaviour.
4. If the test **fails after refactoring**: you changed behaviour, not just structure. Undo the refactoring change that broke the test and try again.

Proceed to step 5 after the sub-loop completes.

**If this is an implementation task in standard mode** (no `Type: verification`, and the story does **not** carry `[tdd]`): Execute the task as described. This is the existing approach — writing code, creating files, running commands, whatever the task requires. Read the full task description and the parent story's acceptance criteria to understand the broader context. Work until the task is complete.

**ADR awareness** (both modes): Before starting implementation, check if this task touches architectural boundaries. **Glob** `docs/architecture/[0-9]*-adr-*.md` — if ADRs exist and the task involves structural decisions, data models, integration points, or deployment concerns, read the relevant ADRs for context. Let the architectural decisions guide implementation choices. If no ADRs exist, proceed normally.

**Companion-asset awareness** (both modes): A task's acceptance criterion may reference an HTML **companion asset** — a relative path to `docs/{type}/assets/{nn}-{slug}-{label}.html` (a UI mockup or diagram a `spec`/`architect` artifact generated; see the shared **HTML Output** convention). When it does, open the asset and treat it as a **visual design target**: build the implementation to *match what it shows*. You must **NOT** parse the companion HTML to extract requirements, structure, or values — the Markdown acceptance criteria are the only machine-readable source of truth. The asset informs *appearance*, not *requirements*: read it the way a developer reads a mockup, not the way a parser reads data.

### 5. Verify Acceptance Criteria

Before marking the task complete:

- Re-read the acceptance criteria from the epic doc (or from the task description if no epic doc).
- For each criterion, assess whether it's been met. The assessment method depends on the criterion's tag:
  - **`[unit]`, `[integration]`, `[feature]`**: If a test command is cached (`**Test command**` is not `none`), run it and use the pass/fail result as evidence. A passing test suite satisfies these criteria. A failing test suite means the criterion is not met — report the specific failures.
  - **`[manual]` or no tag**: Self-assess by inspecting the codebase, checking files, or reviewing outputs. This is the existing approach.
- If all criteria are met (by test results or self-assessment), proceed to step 6.
- If any criteria are **not** met, flag them to the user. List what's unmet and ask whether to continue working on them or mark the task as Complete anyway. Use AskUserQuestion for this gate.

**Coverage matrix proof recording** (verification gates only): When a verification gate passes (all criteria met), update the companion coverage matrix to record proof. Check for the companion coverage matrix alongside the epic doc — derive its path via the `-epic- → -coverage-` substitution rule described in Step 1 (which works for both legacy flat and new two-part epic shapes). If it exists:

1. Read the coverage matrix and identify rows where the "Covered by" column matches the current story (e.g. `Story {N}`).
2. For each matching row, use the Edit tool to replace the empty Verified cell with `✓`. The edit targets the specific row's trailing `| |` (empty Verified cell) and replaces it with `| ✓ |`.
3. Only update rows matching the current story — rows for other stories must remain untouched.

If the coverage matrix file doesn't exist, log a note ("No coverage matrix found — skipping proof recording") and continue. Proof recording is additive and must always allow task execution to proceed. If an Edit call fails (e.g. the row text doesn't match the expected pattern), flag the failure to the user via AskUserQuestion with options: "Continue without recording proof for this row" or "Stop and investigate" — every failed write must be surfaced.

### 5b. Story Refactoring Pass (every completed story)

When a story's verification gate task runs — the story-completion point — perform a focused refactoring pass on the code the story produced. This pass fires **once per story, in both interactive and autonomous modes** (it lives in `cpm:do`, so `cpm:ralph` inherits it). It is invoked at the verification-gate task because that is where a story finishes, but it is **no longer gated on the verification *result***: a story whose criteria were unmet-but-continued still earns its pass. Each completed story receives **exactly one** refactoring pass — never two, never zero (subject to the preconditions below). It still runs only at the verification-gate task, never on individual implementation tasks — that is what keeps it to one pass per story.

**Preconditions** — run the pass only when **all** of these hold; if any fails, skip the pass and record the skip with its reason in the per-story simplifier-outcome line (Step 6 Part C), never silently:

- **The story completed.** It was not marked Blocked, left stuck, or skipped past the autonomous stuck threshold. Never refactor the partial, possibly-broken code of a story that did not finish.
- **The story touched code.** At least one implementation task created or modified a code file. A story with no implementation tasks (pure documentation or configuration) has nothing to refactor — skip it and log `skipped — no code touched`.
- **A cached test command exists** (`**Test command**` is not `none`). The retest below is the only thing that catches a refactor that changed behaviour; with no test command there is no safety net, so do **not** refactor untested code blind — skip the pass and log `skipped — no test command to verify against`.

**Identify scope**: Review the tasks completed in this story (listed in the progress file's Completed Tasks section). Identify the files that were created or modified during the story's implementation tasks. These files — and only these files — are the refactoring target.

**Run the refactoring pass**:

- **Laravel project with `laravel-simplifier`**: If `**Framework**` in the progress file is `laravel`, use the Task tool with `subagent_type: "laravel-simplifier:laravel-simplifier"` to refactor the touched files. Pass the agent a prompt listing the files modified by this story and instruct it to simplify and refine for clarity, consistency, and maintainability. If the agent is not available in the current session (tool call fails), fall back to the self-directed approach below.
- **All other projects** (or fallback): Perform a self-directed refactoring review of the files touched by this story. Focus on: naming clarity, duplication removal, method extraction, readability improvements. Keep changes minimal — this is a polish pass, not a restructuring.

**Retest**: After refactoring, run the cached test command (guaranteed present by the preconditions) to confirm nothing broke.

- If tests **pass**: proceed to Step 6.
- If tests **fail**: revert the refactoring changes that caused failures and proceed to Step 6 without them. The work loop always continues past a failed refactoring pass.

**Scope constraint**: Start with the files touched by the current story, but look outward for consolidation opportunities — duplicate code, similar patterns, extraction candidates, and abstractions that span touched and non-touched code. If the story introduced logic that already exists elsewhere, merge it. If a pattern appears in both new and existing code, extract it. The refactoring may touch files beyond the story's direct scope when there's a clear consolidation or deduplication benefit. Every change must connect back to the code the story produced — unrelated refactoring is out of scope.

### 6. Complete and Update State

This step has three parts: mark complete, capture an observation, and write the progress file. All three run on every task.

**Part A — Mark complete**:
- If epic doc integration is active, use the Edit tool to update the matched entry's status (whether `##` story or `###` task):
  - `old_string`: `**Status**: In Progress` (scoped near the matched heading)
  - `new_string`: `**Status**: Complete`
- **Preserve any note tail** (as in Step 2): match only the `**Status**: In Progress` token, not the whole line, so a trailing ` — note` survives the transition (`**Status**: In Progress — folded into Story 10` → `**Status**: Complete — folded into Story 10`). Never widen the match to consume or rewrite a human note.
- Call `TaskUpdate` to set the task status to `completed`.

**Part B — Capture observations (retro)**:

Every completed story produces a `**Retro**:` field — this is the only input `/cpm:retro` has to work with. Without an observation, the retro skill has nothing to synthesise.

**For verification gate tasks**: Record an observation. Reflect on the story as a whole — all the tasks you just verified. Ask: "What's worth remembering about this story?" Pick the most fitting category below and write one sentence. If nothing went wrong, use `Smooth delivery` — that's valuable data too.

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

**Signal capture (retro triggers)**: Independently of the observation above, watch for *retro-trigger signals* during the loop — these decide whether the end-of-epic retro is generated (Step 8). A signal fires when any of these occur while working a task: a verification gate resolved fail-then-continue (criteria unmet but the user chose to proceed), a `[tdd]` story needed more than one red cycle, a test command returned failures, a story was marked Blocked or stuck, or an `**Inline change**` breadcrumb was recorded. When a signal fires during a task, record it in the progress file's `**Retro signals**:` line (Part C) — append the trigger as it happens; never re-judge it later. The set accumulates across the whole epic. (The epic-level spec gap is the one trigger that surfaces after the loop, at Step 8 — it is added to the set there.)

**Part C — Write progress file**:

Call the Write tool on `docs/plans/.cpm-progress-{session_id}.md` immediately after Part A (and Part B's Edit, if applicable). This must be the very next tool call — before any reads, task queries, or other operations.

The file must reflect:
- The task just completed (added to Completed Tasks section)
- The next action (which task to pick up next, or "work loop complete")
- The current tasks remaining count
- The `**Planned stories**:` line — carry forward any story numbers already listed, and add the current story's number if its `[plan]` plan was approved during this task (Step 3). This is what stops formal plan mode from re-firing for the story's remaining tasks.
- The `**Retro signals**:` line — carry forward signals already recorded, and append any retro-trigger signal that fired during this task (see Part B's *Signal capture*). This accumulating set is what Step 8 reads to decide whether retro generation is mandatory.
- The `**Simplifier outcomes**:` line — carry forward outcomes already recorded, and when this task is a verification gate whose Step 5b refactoring pass just ran, was skipped, fell back, or was reverted, append that story's outcome (e.g. `Story 2: skipped (no test command)`). This accumulating set is what the Step 8 run summary reads to report, per story, what the simplifier pass did.

Once the progress file is written, go straight to Step 7. Finishing a task — or a whole story, or making a commit — is **not** a checkpoint: do not summarise what you just did, do not announce progress, and do not pause to ask whether or how to proceed (in any wording). The next iteration begins silently. The only stops are the explicit gates this skill names (see Step 7 and the **No unauthorised checkpoints** guideline).

### 7. Next Task

**Loop without prompting.** Step 7 is silent — no user gate, no announcement, no "ready for the next one?" check-in. If a task exists, return to Step 1. If none does, proceed to Step 8. The transition between tasks (and between stories, via Story Hydration) happens without user input. In particular, never close a task or story by pausing to ask whether or how to proceed. The wording varies endlessly — "Would you like to continue, stop, or commit?", "Shall I move on?", "Want me to keep going?", "Ready for the next one?" — so it is the *intent* that is forbidden, not any fixed phrase: any prompt that halts the loop for permission to continue, in any wording and whether via `AskUserQuestion` or plain text, is an unauthorised checkpoint. Completing a unit of work is never permission to pause. See the **No unauthorised checkpoints** and **Forbidden phrasings** entries in Guidelines.

- Run the **Story Hydration** gating check: call `TaskList`. If no pending unblocked tasks exist, hydrate the next unblocked story from the epic doc (see Story Hydration above). This handles story-to-story transitions automatically.
- After hydration (or if tasks already existed), pick the next lowest-ID task that is `pending` and has no unresolved `blockedBy`.
- If one exists, go back to step 1 (Load Context) for the new task.
- If none exist (and hydration found no unblocked stories), the work loop is done — proceed to step 8.

### 8. Batch Summary (Loop Completion)

When the work loop finishes (no more pending unblocked tasks):

1. **Epic-level verification**: If the epic doc has a `**Source spec**:` field, read the referenced spec. Also read the epic's coverage matrix if it exists (derive its path from the epic doc via the `-epic- → -coverage-` substitution rule, which works for both legacy flat and new two-part epic shapes) — the matrix provides the side-by-side verbatim spec text vs story criteria, making it straightforward to verify each requirement was implemented with the spec's specificity intact. Check whether the completed epic, taken as a whole, satisfies the spec's requirements that fall within this epic's scope. This is an integration-level check — individual story criteria may all pass while the epic as a whole misses something (e.g. a requirement that spans multiple stories, or an integration point between stories). Report the assessment to the user. If gaps are found, flag them — they may warrant additional work or a `cpm:pivot`. If no spec exists, skip this step.

   **Epic-level proof recording**: After the epic-level verification passes (no gaps found), update the coverage matrix to mark any remaining unverified rows with `✓`. These are rows that passed story-level verification but may not have been marked during Step 5 (e.g. requirements that span multiple stories, or rows that only became fully verified at the integration level). If the epic-level check identified gaps, do **not** mark those gap-flagged rows — they represent unproven requirements. If no coverage matrix exists, skip this step.

2. **Gather observations and the retro-trigger flag set**: Read the epic doc and collect all `**Retro**:` fields across completed stories — these are the observations. Then read the progress file's `**Retro signals**:` line — the retro-trigger flag set accumulated during the loop (Step 6 Part B, *Signal capture*). Add the **epic-level spec gap** to the flag set if the epic-level verification in item 1 found one.

3. **Generate the retro (mandatory when signals fired)**: Decide generation from the flag set, not from a judgement call:

   - **If the flag set is non-empty** (any retro-trigger signal fired, or an epic-level spec gap was found): retro generation is **mandatory**. Follow the shared **Retro Synthesis** procedure (in the CPM Shared Skill Conventions), passing the observations gathered in item 2, the epic's story outcomes, and the epic doc path as the source. The procedure groups, synthesises, and writes `docs/retros/{nn}-retro-{slug}.md`, returning the path. This **is** the batch synthesis — do **not** also write a separate `## Lessons` section into the epic doc; the retro file is the single synthesis artifact, produced by the one synthesis implementation shared with `/cpm:retro`.
   - **If the flag set is empty** (no retro-trigger signal fired and no epic-level spec gap): auto-skip is permitted — do not write a retro file. **Log the skip and its reason** in the batch summary (item 4), e.g. "Retro auto-skipped — clean epic, no retro signals fired." The skip is **never silent**: a skipped retro is always reported with its reason, so the absence of a retro file is a visible, explained decision rather than an oversight. (Note: any `**Retro**:` observations still live on their stories in the epic doc; a manual `/cpm:retro` run can still synthesise them later.)

4. **Report**: Report a summary of what was completed across the work loop. If a coverage matrix exists, include a **verification summary** — the count of verified rows (those with `✓`) vs. total rows in the matrix (e.g. "Coverage matrix: 9/9 requirements verified" or "Coverage matrix: 7/9 requirements verified — 2 unverified rows remain"). Always include the **retro outcome**: either the path of the generated retro file, or — when generation was auto-skipped — the explicit skip reason (per item 3). Never omit this line; a clean-epic skip must be stated, not silent. Always include a **simplifier summary** — read the progress file's `**Simplifier outcomes**:` line and report, per story, what the Step 5b refactoring pass did (ran / skipped + reason / reverted / self-directed fallback), so a story whose pass was skipped is visible rather than silent. Under an **autonomous run**, also surface the consumption-gate dispositions as **two clearly separated lists**: the **auto-applied** safe-category lessons (every `applied (autonomous, safe-category)` breadcrumb) presented **prominently for review** — these changed the run with no human in the loop — and, separately, the **deferred-unreviewed** observations (every `deferred (autonomous run, unreviewed)` breadcrumb) for post-loop review. Keep the two lists distinct; never fold applied into deferred. Both use the existing `**Retro applied**:` field format, so `cpm:status` and `cpm:retro` continue to parse them unchanged.

5. **Next epic check**: After reporting, decide whether to look for more work:
   a. **If the epic was specified explicitly** (a file path was passed via `$ARGUMENTS`, not auto-discovered): the user asked for this specific epic. Delete the progress file and stop.
   b. **If the epic was auto-discovered** (resolved via smart discovery, not an explicit path): check if other epics are available to work on:
      i. **Glob** `docs/epics/*-epic-*.md` to find all epic files.
      ii. Use Grep to search for `**Status**:` across the matched files, then filter to epics that are not `Complete`/`Done` and not retired (`Superseded` / `Withdrawn`) (excluding the epic just finished). Use Grep and Read tools directly (Bash loops with shell variables lose context).
      iii. If **no remaining epics** have work: delete the progress file and stop.
      iv. If **one or more epics** have remaining work: present the choice using AskUserQuestion — "Epic {name} is complete. What would you like to do?" with options:
         - **Continue to {next epic name}** — auto-select the next epic by number order and start a new work loop (re-run Input resolution, the **Retro Check** consumption gate, Library Check, Test Runner Discovery, Framework Detection, and Story Hydration for the new epic). Re-running the Retro Check per epic is load-bearing: it re-globs `docs/retros/` so this epic consumes any retro written by an earlier epic **in the same run** — without it, mid-run lessons are never seen.
         - **Stop here** — delete the progress file and end the session
         If multiple epics have remaining work, show the lowest-numbered one as the "Continue to..." option.

## Graceful Degradation

Every scenario below specifies an explicit action sequence ending with a visible result. No silent fallbacks.

- **No epic doc resolved during Input** → **Action**: Skip epic doc reads and status updates. Execute tasks using their Claude Code task descriptions as the sole specification. **Result**: Report to the user at loop start: "No epic doc — working from task descriptions only."

- **Epic doc file missing or deleted mid-loop** → **Action**: Detect the missing file on the next Read attempt. Switch to task-description-only mode for the remainder of the loop. **Result**: Report to the user: "Epic doc not found at {path} — continuing without epic doc integration."

- **Story heading not found in epic doc** → **Action**: Skip status updates for that story. Continue executing the task using its Claude Code task description. **Result**: Report to the user: "Story {N} heading not found in epic doc — skipping status updates for this story."

- **Test command fails to execute** (command not found, timeout, permission error) → **Action**: Use AskUserQuestion with options: "Provide a different test command", "Continue without tests (self-assessment only)", "Stop and investigate". If the user provides a new command, update `**Test command**` in the progress file. **Result**: The user's choice is recorded and the work loop continues with the selected approach.

- **Test command returns failures** (tests run but some fail) → **Action**: Report the specific test failures to the user via AskUserQuestion with options per Step 4 verification gate logic. **Result**: The user decides how to proceed — fix, skip, or stop. The work loop continues regardless of the choice made.

- **No test command cached** (`**Test command**: none`) → **Action**: Use self-assessment for all verification — inspect files, check outputs, and assess each criterion against the codebase. **Result**: Verification gate reports assessment results inline with each criterion's pass/fail status.

- **No test command + `[tdd]` story** → **Action**: The TDD sub-loop requires test execution at every phase. Use AskUserQuestion: "TDD mode requires a test runner, but none is available." Options: "Provide a test command now", "Fall back to standard workflow for this story". If the user provides a command, update `**Test command**` in the progress file and proceed with TDD. **Result**: If fallback chosen, report: "Using standard workflow for Story {N} (TDD unavailable)." If command provided, proceed with TDD normally.

- **`laravel-simplifier` agent not available** → **Action**: Use self-directed refactoring in Step 5b — review touched files for naming clarity, duplication, and readability. **Result**: Report to the user: "laravel-simplifier not available — using self-directed refactoring for this story."

## State Management

Follow the shared **Progress File Management** procedure.

**Lifecycle**:
- **Create**: before starting the first task.
- **Update**: after each task completes.
- **Delete**: only after confirming all output artifacts (epic doc updates, batch summary) are written.

**Format**:

```markdown
# CPM Session State

**Skill**: cpm:do
**Current task**: {task ID} — {task subject}
**Epic doc**: {path to epic doc, or "none"}
**Test command**: {discovered test command, or "none" if no runner found}
**Framework**: {detected framework, e.g. "laravel" or "none"}
**Tasks remaining**: {count of pending unblocked tasks}
**Planned stories**: {comma-separated numbers of [plan] stories whose plan has been approved this run, or "none"}
**Retro signals**: {comma-separated retro-trigger signals fired so far this epic (e.g. "Story 3 fail-then-continue, test failures"), or "none"}
**Simplifier outcomes**: {comma-separated per-story Step 5b outcomes recorded so far this epic — each one of "Story {N}: ran", "Story {N}: ran (self-directed fallback)", "Story {N}: reverted (tests broke)", "Story {N}: skipped (no code touched)", "Story {N}: skipped (no test command)", or "Story {N}: skipped (story not completed)"; "none" before any story finishes}

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
- **Minimal change, scoped to the task.** Implement what the task and its acceptance criteria call for — no speculative abstractions, extra configuration, or features beyond the stated scope. When a smaller change satisfies the criteria, prefer it; breadth can be added later when a real need appears.
- **Solve generally, not to the test.** Write code that addresses the underlying requirement across the full range of valid inputs, rather than special-casing the specific examples a test happens to check. Tests confirm the general solution holds — they are evidence, not the specification to hard-code against.
- **Acceptance criteria gate completion.** Only mark a task Complete when all acceptance criteria are met, or the user explicitly approves.
- **Keep momentum, but not at the cost of correctness.** Move through tasks efficiently with minimal explanation between them. Always run verification and take care with edits. Follow the shared Implementation Guidelines: use the Edit tool file-by-file (no bulk `sed`/`perl`), and prefer clarity and correctness over speed.
- **No unauthorised checkpoints.** The work loop only stops at the gates explicitly listed in this skill — verification failures, unmet criteria, stalled cycles, TDD edge cases, blockers, ambiguous criteria, coverage matrix write failures, and the epic-end gate at Step 8. Everything else is forward motion: task-to-task transitions, story-to-story transitions, and the post-completion summary are all silent. Do not invent additional check-ins. Do not narrate progress between tasks. Do not pause to ask permission to proceed.
- **Forbidden phrasings.** Never pause the loop to ask the user whether or how to proceed between tasks or stories — regardless of how the prompt is worded, how many options it offers, or whether it uses `AskUserQuestion` or plain text. It is the *category* that is banned, not a fixed list of phrases; the wording varies endlessly. Illustrative, non-exhaustive examples: "Would you like to continue, stop, or commit?", "continue / stop / commit", "Should I commit before continuing?", "Would you like me to proceed to the next story?", "Shall I move on?", "Want me to keep going?", "Ready for the next task?". This holds at every task and story boundary, and immediately after a commit — none is a checkpoint. Commits, if needed, are part of the task itself or are handled outside this skill (see **Version control stays with the user**) — the skill never solicits permission for the next iteration of its own loop. If you find yourself about to write any such prompt, return to Step 7 instead.
- **Version control stays with the user.** Do not commit, stage, branch, or push on your own initiative — leave the working tree as edited files for the user to commit outside the loop. See the shared **Version control stays with the user** guideline. The only exceptions are a task whose acceptance criteria explicitly require a git action, an instruction from the user, or a wrapper like `cpm:ralph` that mandates commits.
- **Surface change moments explicitly.** When a change-worthy situation appears mid-task — a criterion that contradicts reality, a story whose scope is wrong, a missing requirement that affects multiple stories, a wording bug — invoke the shared **Change Type Decision** procedure. Present an `AskUserQuestion` gate with the four labelled options (Inline edit / Pivot the upstream artefact / Retro observation only / Pivot + retro). Do not silently edit a criterion mid-task; do not silently defer the question to verification. Surface it now.
  - **If the user chooses Inline edit**: apply the Edit immediately to the affected story or task in the epic doc, then record `**Inline change**: {one-line summary of what changed} ({YYYY-MM-DD})` on the story (alongside any existing `**Retro**:` field) using a second Edit. The breadcrumb is mandatory — silent inline edits violate the convention.
  - **If the user chooses Pivot**: stop the work loop, save the progress file, and tell the user to run `/cpm:pivot {path-to-affected-artefact}`. Resume the work loop after the pivot completes (a fresh `/cpm:do` invocation will pick up where this one left off via the progress file).
  - **If the user chooses Retro observation only**: capture the observation in the story's `**Retro**:` field at task completion (Step 6 Part B), no other action.
  - **If the user chooses Pivot + retro**: do both — stop for pivot, then capture the retro observation when the work loop resumes.
- **One task at a time.** Complete each task fully before starting the next.
- **`[tdd]` activates the red-green-refactor sub-loop.** When a story's acceptance criteria carry the `[tdd]` tag, Step 4 switches from standard implementation to a three-phase TDD loop: write a failing test (Red), write minimum code to pass (Green), clean up within task scope (Refactor). Each phase runs a targeted test — the specific test file, not the full suite. The full suite runs at the story verification gate. Stories without `[tdd]` use the standard post-implementation workflow unchanged. Both modes can coexist in the same epic.
- **Story refactoring pass polishes before moving on.** When a verification gate passes, Step 5b performs a refactoring pass starting from the files touched by the story — then retests. For Laravel projects, this uses the `laravel-simplifier` agent if available; for all other projects, it's a self-directed review. The pass starts with the story's code but looks outward for consolidation opportunities — deduplication, extraction, and abstraction across touched and existing code. If refactoring breaks tests, the changes are reverted.
