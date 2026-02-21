---
name: cpm:quick
description: Lightweight execution for small, well-defined changes. Bypasses the full CPM pipeline — accept a description, assess scope, confirm, execute, and produce a completion record. Use for changes that don't warrant discover/brief/spec/epics ceremony. Triggers on "/cpm:quick".
---

# Quick Execution

Execute small, well-defined changes with minimal ceremony. Accept a description, assess whether it's genuinely small, confirm the plan with the user, do the work, and write a completion record for traceability.

This is the lightweight alternative to the full pipeline (discover → brief → spec → epics → do). Use it when the change is clear, the scope is small, and the overhead of structured planning would exceed the value it provides.

## Input

Parse `$ARGUMENTS` to determine the change description:

1. If `$ARGUMENTS` contains a description (e.g. `/cpm:quick add a --verbose flag to the deploy script`), use that as the change description.
2. If `$ARGUMENTS` is a file path, read the file and use its contents as the change description.
3. If no arguments provided, ask the user: "What change do you want to make?" Use AskUserQuestion with a freeform text option.

The change description is the seed for everything that follows — scope assessment, acceptance criteria, and execution all derive from it.

## Process

**State tracking**: Before starting Step 1, create the progress file (see State Management below). Each step below ends with a mandatory progress file update — do not skip it. After saving the completion record, delete the file.

### Library Check (Startup)

Before Step 1, check the project library for reference documents:

1. **Glob** `docs/library/*.md`. If no files found or directory doesn't exist, skip silently and proceed to Step 1.
2. **Read front-matter** of each file found (the YAML block between `---` delimiters, typically the first ~10 lines). Filter to documents whose `scope` array includes `quick` or `all`.
3. **Report to user**: "Found {N} library documents relevant to quick execution: {titles}. I'll reference these as context." If none match the scope filter, skip silently.
4. **Deep-read selectively** during execution when a library document's content is relevant — e.g. reading coding standards before writing code.

**Graceful degradation**: If any library document has malformed or missing front-matter, fall back to using the filename as context. Never block execution due to a malformed library document.

**Compaction resilience**: Include library scan results (files found, scope matches) in the progress file so post-compaction continuation doesn't re-scan.

### Step 1: Scope Assessment

Explore the codebase to understand what the change involves, then assess whether it's appropriate for quick execution.

1. **Explore**: Use Glob, Grep, and Read tools to understand the change. Identify which files would be affected, what patterns exist, and whether there are hidden dependencies. Spend enough time to form a genuine opinion — a superficial scan isn't sufficient.

2. **Assess scope**: Based on your exploration, evaluate whether this change is a good fit for `/cpm:quick`. Consider:
   - **File count**: How many files need to change?
   - **Architectural impact**: Does this require new patterns, data model changes, or cross-cutting concerns?
   - **Dependencies**: Does this affect shared interfaces, APIs, or contracts?
   - **Risk**: Could this break existing behaviour in non-obvious ways?

   There are no hard thresholds. A 10-file change that follows an existing pattern is fine for quick execution. A 2-file change that introduces a new architectural pattern may not be.

3. **Report assessment**: Tell the user what you found. Be transparent about scope:
   - If the change looks appropriate for quick execution, say so and proceed to Step 2.
   - If the change appears too large or complex, explain **why** — which factors raised concern. Then offer escalation **once**:

   Use AskUserQuestion: "This looks like it might benefit from the full planning pipeline. Want to escalate?" with options:
   - **Escalate to `/cpm:discover`** — Start with problem discovery
   - **Escalate to `/cpm:spec`** — Jump to specification
   - **Escalate to `/cpm:epics`** — Jump to work breakdown
   - **Continue with `/cpm:quick`** — Proceed anyway

   If the user chooses to continue, honour their decision and proceed to Step 2. Do not raise the scope concern again.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Step 1 summary before continuing.

### Step 2: Propose and Confirm

Present a single concise proposal block for the user to confirm or adjust before any work begins.

Format the proposal as:

```
**Change**: {one-sentence summary of what will change}
**Files affected**:
- {path/to/file1} — {what changes}
- {path/to/file2} — {what changes}
**Acceptance criteria**:
- {criterion 1 — observable outcome}
- {criterion 2 — observable outcome}
```

Keep it tight — the proposal should be scannable in 10 seconds. Acceptance criteria should describe observable outcomes, not implementation steps. "Config file includes the new key" not "Edit the config file to add a key".

Use AskUserQuestion to confirm: "Ready to execute this change?" with options:
- **Execute** — Proceed with the change as described
- **Adjust** — Let me modify the scope or criteria

If the user adjusts, incorporate their feedback and re-present the proposal. Iterate until confirmed.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Step 2 summary (the confirmed proposal) before continuing.

### Step 3: Execute

Do the work. Create Claude Code tasks and implement the change directly.

1. **Create tasks**: Break the confirmed proposal into implementation tasks. Use TaskCreate for each:
   ```
   TaskCreate:
     subject: "{Task title — imperative form}"
     description: "{What this task covers from the acceptance criteria}"
     activeForm: "{Present continuous form}"
   ```

   Create as many tasks as the work needs — a single-file change gets one task, a multi-step change gets several. Don't over-decompose; don't under-decompose.

2. **Execute tasks sequentially**: For each task:
   - Call TaskUpdate to set status to `in_progress`.
   - Do the work — write code, edit files, create resources, whatever is needed. Use the full range of tools: Read, Edit, Write, Bash, Glob, Grep.
   - When the task is done, call TaskUpdate to set status to `completed`.

3. **Keep momentum**: Move through tasks efficiently. Don't over-explain between tasks. The proposal was already confirmed — now execute it.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Step 3 summary (tasks completed, files changed) before continuing.

### Step 4: Completion Record and Verification

After execution, verify acceptance criteria and write the completion record.

#### Verify Acceptance Criteria

Re-read the acceptance criteria from the confirmed proposal (Step 2). For each criterion, self-assess against the current state of the codebase:

- Inspect the relevant files using Read, Glob, or Grep to confirm each criterion is met.
- If all criteria are met, proceed to write the completion record.
- If any criteria are **not** met, flag them to the user. Use AskUserQuestion: "Some acceptance criteria are not met:" with the unmet items listed, and options:
  - **Fix now** — Continue working on the unmet criteria
  - **Record as-is** — Write the completion record noting the gaps
  - **Stop** — Don't write a completion record yet

If the user chooses "Fix now", address the gaps and re-verify. Iterate until criteria are met or the user decides to proceed.

#### Write Completion Record

Determine the record number and slug:

1. **Number** (`{nn}`): Glob `docs/quick/[0-9]*-quick-*.md` to find existing records. Extract the highest number and increment by 1. If no records exist, start at `01`. Zero-pad to 2 digits.
2. **Slug** (`{slug}`): Derive a kebab-case slug from the change description (e.g. "add verbose flag to deploy script" → `add-verbose-flag-deploy-script`). Keep it concise — 3-6 words.

Create the `docs/quick/` directory if it doesn't exist. Write the record using the Write tool:

```markdown
# {Title}

**Date**: {today's date}
**Status**: Complete

## Context

{1-3 sentences explaining what prompted this change and why it was done via quick execution}

## Acceptance Criteria

- {criterion 1} — {Met/Not met}
- {criterion 2} — {Met/Not met}

## Changes Made

- `{path/to/file}` — {what changed}
- `{path/to/file}` — {what changed}

## Verification

{Brief summary of how criteria were verified — what was inspected, what confirmed the change is correct}
```

Tell the user the record path after saving.

**Update progress file now** — write the full `.cpm-progress-{session_id}.md` with Step 4 summary, then delete the progress file. The session is complete.

## Output

Completion records are saved to `docs/quick/{nn}-quick-{slug}.md`. Create the `docs/quick/` directory if it doesn't exist.

## State Management

Maintain `docs/plans/.cpm-progress-{session_id}.md` throughout the session for compaction resilience. This allows seamless continuation if context compaction fires mid-execution.

**Path resolution**: All paths in this skill are relative to the current Claude Code session's working directory. When calling Write, Glob, Read, or any file tool, construct the absolute path by prepending the session's primary working directory. Never write to a different project's directory or reuse paths from other sessions.

**Session ID**: The `{session_id}` in the filename comes from `CPM_SESSION_ID` — a unique identifier for the current Claude Code session, injected into context by the CPM hooks on startup and after compaction. Use this value verbatim when constructing the progress file path. If `CPM_SESSION_ID` is not present in context (e.g. hooks not installed), fall back to `.cpm-progress.md` (no session suffix) for backwards compatibility.

**Resume adoption**: When a session is resumed (`--resume`), `CPM_SESSION_ID` changes to a new value while the old progress file remains on disk. The hooks inject all existing progress files into context on startup — if one matches this skill's `**Skill**:` field but has a different session ID in its filename, adopt it:
1. Read the old file's contents (already visible in context from hook injection).
2. Write a new file at `docs/plans/.cpm-progress-{current_session_id}.md` with the same contents.
3. After the Write confirms success, delete the old file: `rm docs/plans/.cpm-progress-{old_session_id}.md`.
Do not attempt adoption if `CPM_SESSION_ID` is absent from context — the fallback path handles that case.

**Create** the file before starting Step 1 (ensure `docs/plans/` exists). **Update** it after each step completes. **Delete** it only after the completion record has been saved and confirmed written — never before. If compaction fires between deletion and a pending write, all session state is lost.

Use the Write tool to write the full file each time (not Edit — the file is replaced wholesale). Format:

```markdown
# CPM Session State

**Skill**: cpm:quick
**Step**: {N} of 4 — {Step Name}
**Change description**: {the original change description}

## Library Check
{Files found, scope matches, or "No library documents found"}

## Completed Steps

### Step 1: Scope Assessment
{Summary — what was explored, scope assessment result, escalation offered/declined}

### Step 2: Propose and Confirm
{The confirmed proposal — change summary, files affected, acceptance criteria}

### Step 3: Execute
{Tasks completed, files changed}

### Step 4: Completion Record and Verification
{Verification outcome, record path}

{...include only completed steps...}

## Next Action
{What to do next}
```

## Guidelines

- **Fast by default.** The whole point of `/cpm:quick` is speed. Don't add ceremony. One confirmation, then execute.
- **Scope honesty.** If a change is too big for quick execution, say so — but only once. The user decides.
- **Traceability without overhead.** The completion record is the minimum artifact needed to know what happened and why.
- **Do the work.** This skill implements changes, not just plans them. Write code, edit files, run tests.
