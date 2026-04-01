---
name: cpm:ralph
description: Autonomous multi-epic execution via the Ralph Wiggum plugin. Discovers epics, generates a Ralph-compatible prompt that wraps /cpm:do with autonomous behaviour overrides, validates prerequisites, and launches the loop. Triggers on "/cpm:ralph".
---

# Autonomous Multi-Epic Execution

Generate and launch a Ralph Wiggum loop that wraps `/cpm:do` for autonomous, unsupervised multi-epic execution. The skill discovers epics, validates prerequisites, assembles a self-contained prompt with autonomous behaviour overrides, and presents it for review before launching.

## Input

Parse `$ARGUMENTS` for:

1. **Epic paths** — one or more explicit paths (e.g. `docs/epics/23-epic-*.md docs/epics/24-epic-*.md`) or a range (e.g. `23 through 26`).
2. **`--max-iterations N`** — maximum Ralph loop iterations (default: 50).
3. **`--story-filter`** — include/exclude specific stories (e.g. `--story-filter "1-3"` or `--story-filter "!4"`).
4. **`--dry-run`** — generate and display the prompt without launching.

If no epic paths are provided, auto-discover all incomplete epics (see Process Step 1).

## Process

### Step 1: Pre-flight Validation

Before generating the prompt, validate all prerequisites.

#### 1a. Epic Discovery

If explicit epic paths were provided in arguments, resolve them (expand globs). Otherwise, auto-discover:

1. **Glob** `docs/epics/*-epic-*.md` to find all epic files.
2. Read each file's `**Status**:` field. Filter to epics that are not `Complete`.
3. If no incomplete epics found, report to the user and stop: "No incomplete epics found. Nothing to run."
4. Present the discovered epics and confirm with AskUserQuestion.

For range-style references (e.g. `23 through 26`), expand to matching files: `docs/epics/23-epic-*.md`, `docs/epics/24-epic-*.md`, etc.

#### 1b. Ralph Wiggum Plugin Detection

Check whether the Ralph Wiggum plugin is available in the current session:

1. Check if the `/ralph-loop:ralph-loop` skill is available by scanning the session's skill list.
2. If not detected, warn the user: "Ralph Wiggum plugin not detected. The `/ralph-loop:ralph-loop` command may not be available. Install the plugin from the Claude Code marketplace or ensure it's configured." Use AskUserQuestion with options: "Continue anyway" or "Stop".

#### 1c. Test Runner Discovery

Discover the project's test runner for inclusion in the generated prompt:

1. Check project config files (`composer.json`, `package.json`, `Makefile`, `pyproject.toml`, `Cargo.toml`) for test commands.
2. If found, report: "Discovered test runner: {command}. This will be referenced in the generated prompt."
3. If not found, note: "No test runner discovered. The generated prompt will instruct `/cpm:do` to discover one at runtime."

#### 1d. Resume Detection

Check for evidence of a previous Ralph run:

1. **Glob** `docs/plans/ralph-log-*.md` for existing execution logs.
2. If an execution log exists, read it and summarise the state: which epics completed, which are in progress, any skipped tasks.
3. Read the target epic docs' `**Status**:` fields to confirm the current state.
4. If a previous run is detected, present the state to the user with AskUserQuestion: "Found a previous Ralph run. {N} epics completed, {M} remaining. Resume from where it left off?" Options: "Resume" or "Start fresh (ignore previous state)".

### Step 2: Prompt Assembly

Assemble the Ralph prompt using the template (see Prompt Template below). Interpolate:

- `{epic_list}` — the resolved epic doc paths, space-separated
- `{max_iterations}` — from arguments or default (50)
- `{completion_promise}` — fixed: `ALL_EPICS_COMPLETE`
- `{stuck_threshold}` — fixed: 3 consecutive failures
- `{log_file}` — `docs/plans/ralph-log-{timestamp}.md` (or the existing log file if resuming)
- `{story_filter}` — from `--story-filter` argument, formatted as a "Story Filter" section in the prompt (e.g. "Only work on stories 1-3" or "Skip story 4"). If no filter provided, this slot is empty (no section generated).
- `{resume_context}` — if resuming, instructions to skip completed work; otherwise empty
- `{test_runner_hint}` — if a test runner was discovered, include it; otherwise empty

### Step 3: Two-Phase Launch

#### 3a. Present (Dry-Run)

Display the assembled `/ralph-loop:ralph-loop` command to the user:

```
Here's the generated Ralph loop command:

/ralph-loop:ralph-loop "{assembled_prompt}" --completion-promise "ALL_EPICS_COMPLETE" --max-iterations {max_iterations}
```

If `--dry-run` was specified, stop here.

#### 3b. Confirm and Execute

Use AskUserQuestion: "Ready to launch the Ralph loop?" Options:
- "Launch it" — execute the command
- "Edit first" — let the user modify the prompt before launching
- "Save and exit" — save the command to a file for later use

If "Launch it": output the `/ralph-loop:ralph-loop` command for execution.
If "Edit first": present the prompt text for the user to modify, then re-assemble and re-present.
If "Save and exit": write the command to `docs/plans/ralph-command-{timestamp}.md`.

## Prompt Template

The following template is interpolated with values from Step 2. This is the prompt that Ralph feeds to Claude on each iteration.

```
Run /cpm:do. Work through the following epics sequentially: {epic_list}.

{resume_context}

## Autonomous Behaviour

Do NOT use AskUserQuestion — make all decisions autonomously:

- **Test failures**: Fix failing tests yourself. Read the error output, diagnose the issue, and implement a fix. If a test fails 3 times on the same issue, skip that task and log it.
- **Unmet acceptance criteria**: Re-attempt the work. Read the criteria carefully, check what's missing, and implement it. Do not ask for guidance.
- **Epic selection (multiple epics)**: When an epic completes and offers the next epic choice, always continue to the next epic in the list.
- **Plan mode**: Use inline planning instead of formal plan mode. Do not enter EnterPlanMode.
- **Verification gate failures**: If criteria are not met after implementation, continue working on them rather than asking.
- **Test runner not found**: Proceed with self-assessment for verification.
- **Coverage matrix errors**: Continue without recording proof for that row.

## Multi-Epic Transitions

When one epic completes, automatically continue to the next epic in the list. Do not stop between epics. The epic list is: {epic_list}.

## Stuck Detection

If the same task fails verification {stuck_threshold} times consecutively:
1. Log the failure in the execution log with details of what was attempted.
2. Skip the task and mark it as skipped in the execution log.
3. Continue to the next task.

Do not get stuck in an infinite retry loop on a single task.

## Execution Log

Maintain an append-only execution log at `{log_file}`. After each significant action, append an entry:

```markdown
## [{timestamp}] {action_type}
**Epic**: {epic name}
**Story**: {story number} — {story title}
**Task**: {task number} — {task title}
**Result**: {pass/fail/skip}
**Details**: {brief description of what happened}
```

Action types: `task_start`, `task_complete`, `task_skip`, `verification_pass`, `verification_fail`, `epic_complete`, `error`.

Never overwrite or truncate the log. Always append.

## Commits

Commit after each completed story using a descriptive message. Do not batch commits across stories.

{story_filter}

{test_runner_hint}

## Iteration Awareness

On each iteration, read the epic doc status fields and execution log to understand what has already been completed. Do not redo completed work. Pick up from where the previous iteration left off.

## Completion

When ALL epics in the list are complete, output:
<promise>ALL_EPICS_COMPLETE</promise>

If max iterations are reached before completion, output a summary of what was completed and what remains.
```

## State Management

Maintain `docs/plans/.cpm-progress-{session_id}.md` during the pre-flight phase for compaction resilience.

**Path resolution**: All paths are relative to the current Claude Code session's working directory.

**Session ID**: Use `CPM_SESSION_ID` from context. Fall back to `.cpm-progress.md` if not present.

**Resume adoption**: Follow the standard CPM resume adoption procedure — if an old progress file matches this skill's `**Skill**:` field but has a different session ID, adopt it.

**Create** before Step 1. **Delete** after the Ralph loop is launched (or after dry-run output is presented).

Use the Write tool to write the full file each time. Format:

```markdown
# CPM Session State

**Skill**: cpm:ralph
**Step**: {N} — {Step Name}
**Epic list**: {resolved epic paths}
**Max iterations**: {value}

## Pre-flight Results
- Epics found: {count} ({list})
- Ralph plugin: {detected/not detected}
- Test runner: {command or "none"}
- Resume: {yes — resuming from log {path} / no — fresh run}

## Next Action
{What to do next}
```

**Delete** the progress file after the Ralph loop is launched or after dry-run output. Also delete `docs/plans/.cpm-compact-summary-{session_id}.md` if it exists.

## Maintenance Coupling

> **This section documents the dependency between `cpm:ralph` and `cpm:do`.** Changes to `cpm:do`'s interaction gates may require updates to this skill's prompt template.

The prompt template's "Autonomous Behaviour" section overrides the following `AskUserQuestion` locations in `cpm:do`:

| `cpm:do` Location | Gate Purpose | Prompt Override |
|---|---|---|
| Input — Epic Doc (multiple epics) | Ask user which epic to work on | Auto-select from the epic list in order |
| Test Runner Discovery | Ask user for test command | Proceed with self-assessment |
| Step 4 — Verification gate test failure | Ask user: fix, continue, or stop | Fix automatically; skip after stuck threshold |
| Step 4 — TDD Red phase unexpected pass | Ask user: investigate, skip TDD, or stop | Investigate and fix the test |
| Step 4 — TDD Green phase still failing | Ask user: continue, skip TDD, or stop | Continue working on implementation |
| Step 5 — Unmet acceptance criteria | Ask user: continue working or mark complete | Continue working; skip after stuck threshold |
| Step 5 — Coverage matrix edit failure | Ask user: continue or stop | Continue without recording proof |
| Step 8 — Next epic check | Ask user: continue to next epic or stop | Always continue to next epic |
| Graceful Degradation — Test command fails | Ask user: new command, continue, or stop | Continue without tests |
| Graceful Degradation — No test + TDD | Ask user: provide runner or acknowledge | Fall back to standard workflow |

**When to update**: If `cpm:do` adds, removes, or changes an `AskUserQuestion` gate, review the prompt template's Autonomous Behaviour section and this table. A new gate that isn't overridden will cause the Ralph loop to pause and wait for user input — defeating the purpose of autonomous execution.

## Guidelines

- **Facilitate the setup, automate the execution.** The skill's interactive phase is pre-flight and launch confirmation. Once Ralph starts, everything is autonomous.
- **Deterministic prompts.** Same epics + same config = same prompt. No randomness.
- **Fail fast on pre-flight.** If prerequisites aren't met, tell the user immediately — don't generate a prompt that will fail.
- **Dry-run is the default first step.** Always show the user what will run before running it.
- **The execution log is the audit trail.** It survives across Ralph iterations and is the primary post-run artifact for the user to review.
