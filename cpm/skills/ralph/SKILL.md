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

1. Check if the `/ralph-wiggum:ralph-loop` skill is available by scanning the session's skill list.
2. If not detected, warn the user: "Ralph Wiggum plugin not detected. The `/ralph-wiggum:ralph-loop` command may not be available. Install the plugin from the Claude Code marketplace or ensure it's configured." Use AskUserQuestion with options: "Continue anyway" or "Stop".

#### 1c. Permissions Check

Autonomous execution will stall if Claude Code prompts for tool approval mid-run. Check that common bash commands are pre-approved:

1. Read `~/.claude/settings.json` and look for a `permissions.allow` array.
2. Check for the presence of these baseline patterns: `Bash(find:*)`, `Bash(grep:*)`, `Bash(git:*)`, `Bash(bash:*)`, `Bash(php:*)`, `Bash(npm:*)`, `Bash(sed:*)`.
3. Also check for the ralph-wiggum setup script pattern: `Bash(\"/Users/...ralph-wiggum/scripts/setup-ralph-loop.sh\":*)` (with the quoted path — the unquoted variant does not match).
4. **If missing patterns are found**, warn the user:

   "**Permissions warning**: Your user settings (`~/.claude/settings.json`) are missing some bash permissions that autonomous execution needs. Without these, the Ralph loop will stall on tool approval prompts."

   List the missing patterns and use AskUserQuestion with options:
   - "Add them for me" — use the Edit tool to add the missing patterns to `~/.claude/settings.json` `permissions.allow` array
   - "I'll handle it" — continue without changes
   - "Stop" — abort

5. **If no permissions block exists at all**, offer to create one with the full set of recommended patterns.

#### 1d. Test Runner Discovery

Discover the project's test runner for inclusion in the generated prompt:

1. Check project config files (`composer.json`, `package.json`, `Makefile`, `pyproject.toml`, `Cargo.toml`) for test commands.
2. If found, report: "Discovered test runner: {command}. This will be referenced in the generated prompt."
3. If not found, note: "No test runner discovered. The generated prompt will instruct `/cpm:do` to discover one at runtime."

#### 1e. Resume Detection

Check for evidence of a previous Ralph run:

1. **Glob** `docs/plans/ralph-log-*.md` for existing execution logs.
2. If an execution log exists, read it and summarise the state: which epics completed, which are in progress, any skipped tasks.
3. Read the target epic docs' `**Status**:` fields to confirm the current state.
4. If a previous run is detected, present the state to the user with AskUserQuestion: "Found a previous Ralph run. {N} epics completed, {M} remaining. Resume from where it left off?" Options: "Resume" or "Start fresh (ignore previous state)".

### Step 2: Prompt Assembly

Assemble the ralph-loop command as a single, short, plain-text string. The prompt **must not** contain markdown formatting, code fences, backticks, XML tags, or any shell-special characters beyond basic punctuation. Keep it concise — the detailed behaviour comes from `/cpm:do` itself; the prompt only needs to steer autonomous decisions.

Build the prompt by interpolating into the template below:

- `{epic_count}` — number of epics
- `{epic_range}` — human-readable range (e.g. "5-7")
- `{epic_glob}` — glob pattern or explicit paths (e.g. `docs/epics/05-epic-*.md through 07-epic-*.md`)
- `{max_iterations}` — from arguments or default (50)
- `{story_filter_clause}` — if `--story-filter` was provided, append a clause like "Only work on stories 1-3." or "Skip story 4." If no filter, omit entirely.
- `{test_runner_clause}` — if a test runner was discovered, append "Use {command} to run tests." If not found, omit entirely.
- `{resume_clause}` — if resuming, append "This is a resumed run — skip completed work and pick up where the previous run left off." If fresh, omit entirely.

### Prompt Template

```
Run /cpm:do. Work through epics {epic_range} sequentially ({epic_glob}). When an epic completes and offers the next epic choice, always continue to the next epic. Do NOT use AskUserQuestion -- make autonomous decisions: fix test failures yourself, use inline planning instead of formal plan mode, keep working until acceptance criteria pass, skip a task after 3 consecutive failures. Commit after each completed story.{story_filter_clause}{test_runner_clause}{resume_clause} When all {epic_count} epics are complete, output ALL_EPICS_COMPLETE.
```

**CRITICAL — prompt hygiene rules:**
- The entire prompt is passed as a double-quoted argument to `/ralph-wiggum:ralph-loop`. It must be safe inside double quotes.
- No backticks, no markdown headers, no code fences, no XML/HTML tags.
- Use `ALL_EPICS_COMPLETE` as the plain text marker in the prompt — must match the `--completion-promise` value exactly.
- Use `--` instead of `—` for dashes in the prompt text.
- Keep the total prompt under 500 characters where possible.

### Step 3: Two-Phase Launch

#### 3a. Present (Dry-Run)

Display the assembled command to the user:

```
Here's the generated Ralph loop command:

/ralph-wiggum:ralph-loop "{assembled_prompt}" --completion-promise "ALL_EPICS_COMPLETE" --max-iterations {max_iterations}
```

If `--dry-run` was specified, stop here.

#### 3b. Confirm and Execute

Use AskUserQuestion: "Ready to launch the Ralph loop?" Options:
- "Launch it" — execute the command
- "Edit first" — let the user modify the prompt before launching
- "Save and exit" — save the command to a file for later use

If "Launch it": output the `/ralph-wiggum:ralph-loop` command for execution.
If "Edit first": present the prompt for the user to modify, then re-present.
If "Save and exit": write the command to `docs/plans/ralph-command-{timestamp}.md`.

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
